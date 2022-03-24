defmodule ImageDataGenerator do
    alias Evision, as: OpenCV

    def stream(args) do
        path = args.path
        class_map = args.class_map
        width = args.width
        height = args.height
        shape = args.shape
        cache = args[:cache]
        batch_ahead = args[:batch_ahead] || 6
        open_flags = args[:open_flags]
        rescale = args[:rescale]
        horizontal_flip = args[:horizontal_flip]
        vertical_flip = args[:vertical_flip]
        width_shift_range = args[:width_shift_range]
        height_shift_range = args[:height_shift_range]
        shear_range = args[:shear_range]
        zoom_range = args[:zoom_range]
        brightness_range = args[:brightness_range]
        rotation_range = args[:rotation_range]
        batch_size = args[:batch_size] || 1
        batch_count = args[:batch_count] || 8
        clahe = args[:clahe]
        log = args[:log]

        cacheable_args = Map.take(args, [:path, :class_map, :width, :height, :open_flags])
        train = :persistent_term.get({:cache_idg, cacheable_args}, nil)
        train = cond do
            !!train && !!cache -> train
            true ->
                train_set = Enum.reduce(class_map, [], fn({name, value}, acc)->
                    files = Path.wildcard("#{path}/#{name}/*")
                    files = Enum.map(files, fn(path)->
                        img = OpenCV.imread!(path, flags: open_flags)
                        img = OpenCV.resize!(img, [width, height])
                        img = if clahe do
                            c = OpenCV.createCLAHE!(clahe)
                            OpenCV.CLAHE.apply!(c, img)
                        else img end
                        bin = OpenCV.Mat.to_binary!(img)
                        %{path: path, onehot: value, bin: bin}
                    end)
                    acc ++ files
                end)
                cache && :persistent_term.put(:cache_train, train_set)
                train_set
        end
        
        batch_size = if batch_size > length(train) do
            length(train)
        else batch_size end

        args = Map.merge(args, %{
            batch_size: batch_size,
            batch_count: batch_count,
            batch_ahead: batch_ahead,
            shape: shape
        })

        stream_1(train, args)
    end

    def stream_1(train_set, args) do
        {:ok, pid} = GenServer.start(ImageDataGeneratorProc, [self(), train_set, args])
        Stream.resource(
          fn ->
            pid
          end,
          fn pid ->
            GenServer.call(pid, :next, 30_000)
          end,
          fn _pid -> 
            #GenServer.stop(pid, :normal)
          end
        )
    end

    def close(pid) do
        GenServer.stop(pid, :normal)
    end

    def prepare_nx(slice_len, img_batch, label_batch, args) do
        [_ | shape] = :erlang.tuple_to_list(args.shape)
        shape = :erlang.list_to_tuple([slice_len | shape])

        x_train = img_batch
        |> Nx.from_binary({:u, 8})
        |> Nx.reshape(shape)
        #TODO: case do in pipe dont compile with defn
        x_train = if args[:rescale] do
            Nx.divide(x_train, args.rescale)
        else x_train end

        y_train = label_batch
        |> Nx.from_binary({:u, 8})
        |> Nx.reshape({slice_len, 1})
        |> Nx.equal(Nx.tensor(Enum.to_list(0..1)))

        x_train = Nx.to_batched_list(x_train, args.batch_size)
        y_train = Nx.to_batched_list(y_train, args.batch_size)
        Enum.zip(x_train, y_train)
    end

    def transform(bin, args) do
        img = OpenCV.Mat.from_binary!(bin, {:u, 8}, args.width, args.height, 1)

        img = if !!args[:horizontal_flip] and :rand.uniform(2) == 1 do
            OpenCV.flip!(img, 1)
        else img end

        img = if !!args[:vertical_flip] and :rand.uniform(2) == 1 do
            OpenCV.flip!(img, 0)
        else img end

        img = if args[:width_shift_range] do
            factor = Enum.random(args.width_shift_range) / 1000
            opencv_shift_width(img, factor)
        else img end

        img = if args[:height_shift_range] do
            factor = Enum.random(args.height_shift_range) / 1000
            opencv_shift_height(img, factor)
        else img end

        img = if args[:shear_range] do
            factor = Enum.random(args.shear_range) / 1000
            opencv_shear(img, factor)
        else img end

        img = if args[:rotation_range] do
            factor = Enum.random(args.rotation_range) / 10
            opencv_rotate(img, factor)
        else img end

        #todo zoom
        #todo brightness

        OpenCV.Mat.to_binary!(img)
    end

    def opencv_shift_width(img, factor) do
        {width, height} = OpenCV.Mat.shape!(img)
        to_shift = trunc(Float.round(width * factor))
        m = Evision.Nx.to_mat!(Nx.tensor([[1,0,to_shift],[0,1,0]], type: {:f, 32}))
        Evision.warpAffine!(img, m, [width, height])
    end

    def opencv_shift_height(img, factor) do
        {width, height} = OpenCV.Mat.shape!(img)
        to_shift = trunc(Float.round(width * factor))
        m = Evision.Nx.to_mat!(Nx.tensor([[1,0,0],[0,1,to_shift]], type: {:f, 32}))
        Evision.warpAffine!(img, m, [width, height])
    end

    def opencv_shear(img, factor) do
        {width, height} = OpenCV.Mat.shape!(img)
        mh = trunc(Float.round(factor*width))
        m = Evision.Nx.to_mat!(Nx.tensor([[1,0,0],[-1*factor,1,mh]], type: {:f, 32}))
        Evision.warpAffine!(img, m, [width, height])
    end

    def opencv_rotate(img, factor) do
        {width, height} = OpenCV.Mat.shape!(img)
        cx = trunc(Float.round(width/2))
        cy = trunc(Float.round(height/2))
        m = Evision.getRotationMatrix2D!([cx, cy], factor, 1.0)
        Evision.warpAffine!(img, m, [width, height])
    end

    def opencv_zoom(img, factor) do
        #img = OpenCV.Mat.from_binary!(hd(train).bin, {:u,8},128,128,1)

        factor = 1.0 + factor
        {width, height} = OpenCV.Mat.shape!(img)
        new_width = trunc(width * factor)
        new_height = trunc(height * factor)
        img2 = OpenCV.resize!(img, [new_width, new_height])

        # Original: 529x550
        # Zoomed: 794x825 


        #translation_matrix = np.float32([ [1,0,70], [0,1,110] ])   
        #img_translation = cv2.warpAffine(img, translation_matrix, (num_cols, num_rows))

        #height, width = img.shape[:2]
        #zoomed = zoom(img, 1.5)
    end
end

defmodule ImageDataGeneratorProc do
    use GenServer

    @impl true
    def init([parent, train_set, args]) do
        :erlang.monitor(:process, parent)
        train_set = Enum.shuffle(train_set)
        idx_max = trunc(Float.ceil(length(train_set) / (args.batch_size*args.batch_count)))
        s = %{parent: parent,
            train_set: train_set, args: args, 
            batches_queued: 0, batch_ahead: args.batch_ahead,
            idx: 0, idx_max: idx_max,
            epoch: 0,
            idx_cur: 0,
            idx_total: 0,
            batches: %{}
        }
        :erlang.send_after(0, self(), :tick)
        {:ok, s}
    end

    @impl true
    def handle_call(:next, _from, s=%{idx: idx, idx_max: idx}) do
        s = Map.merge(s, %{idx: 0, epoch: s.epoch+1})
        {:reply, {:halt, self()}, s}
    end
    def handle_call(:next, from, s) do
        cond do
            Kernel.map_size(s.batches) == 0 ->
                s.args[:log] && IO.puts("#{:os.system_time(1000)}: batcher too slow.. #{s.idx_cur}/#{s.idx_total}")
                s = Map.put(s, :waiter, from)
                {:noreply, s}
            true ->
                [key|_] = Map.keys(s.batches)
                {batch, s} = pop_in(s, [:batches, key])
                s = put_in(s, [:idx], s.idx+1)
                s = put_in(s, [:idx_cur], s.idx_cur+1)
                {:reply, {batch, self()}, s}
        end
    end

    @impl true
    def handle_info(:tick, s) do
        :erlang.send_after(10, self(), :tick)
        delta = (s.batch_ahead - s.batches_queued) - (s.idx_total - s.idx_cur)
        if delta > 0 do
            s.args[:log] && IO.puts("#{:os.system_time(1000)}: making batch #{s.idx_cur}/#{s.idx_total}")

            s = if rem(s.idx_total, s.idx_max) == 0 do
                train_set = Enum.shuffle(s.train_set)
                Map.merge(s, %{train_set: train_set})
            else
                s
            end

            queue_next_batch(s)

            s = put_in(s, [:idx_total], s.idx_total+1)
            s = put_in(s, [:batches_queued], s.batches_queued+1)
            {:noreply, s}
        else
            {:noreply, s}
        end
    end

    def handle_info({:batch_ready, batch}, s) do
        s.args[:log] && IO.puts("#{:os.system_time(1000)}: ready batch #{batch.idx}, took #{batch.took}")
        s = put_in(s, [:batches_queued], s.batches_queued-1)
        cond do
            s[:waiter] ->
                :gen_server.reply(s.waiter, {batch.result, self()})
                {_, s} = pop_in(s, [:waiter])
                s = put_in(s, [:idx], s.idx+1)
                s = put_in(s, [:idx_cur], s.idx_cur+1)
                {:noreply, s}
            true ->
                s = put_in(s, [:batches, batch.idx], batch.result)
                {:noreply, s}
        end
    end

    def handle_info({:DOWN, _MonitorRef, :process, pid, _Info}, s=%{parent: pid}) do
        {:stop, :normal, s}
    end

    def queue_next_batch(s) do
        me = self()
        :erlang.spawn(fn()->
            start_time = :os.system_time(1000)

            batch = generate_next_batch(s)

            end_time = :os.system_time(1000)
            took = end_time - start_time

            batch = %{
                result: batch, idx: s.idx_total,
                start_time: start_time, end_time: end_time, took: took
            }

            send(me, {:batch_ready, batch})
        end)
    end

    def generate_next_batch(s) do
        args = s.args
        idx = rem(s.idx_total, s.idx_max)
        train_set = s.train_set
        offset = idx * args.batch_size * args.batch_count

        slice = Enum.slice(train_set, offset, args.batch_size * args.batch_count)
        {img_batch, label_batch} = Enum.reduce(slice, {"", ""},
            fn(%{bin: bin, onehot: onehot}, {img_batch, label_batch}) ->
                bin = ImageDataGenerator.transform(bin, args)
                {img_batch <> bin, label_batch <> <<onehot::8>>}
            end
        )
        #IO.inspect {length(slice), s.idx, s.idx_cur, s.idx_total, s.idx_max}
        ImageDataGenerator.prepare_nx(length(slice), img_batch, label_batch, args)
    end
end