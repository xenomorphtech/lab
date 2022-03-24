defmodule XRay do
  require Axon
  import Nx.Defn
  alias Evision, as: OpenCV

  def go() do
    #224
    width = 224
    height = 224

    model = 
    Axon.input({nil, 1, width, height})
    |> Axon.conv(16, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(16, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.dropout(rate: 0.2)
    |> Axon.conv(32, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(32, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.dropout(rate: 0.2)
    |> Axon.conv(64, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(64, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.dropout(rate: 0.2)
    |> Axon.conv(128, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(128, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.dropout(rate: 0.2)
    |> Axon.conv(256, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(256, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.dropout(rate: 0.2)
    |> Axon.flatten()
    |> Axon.dense(1024, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.dropout(rate: 0.5)
    |> Axon.dense(512, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.dropout(rate: 0.4)
    |> Axon.dense(256, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.dropout(rate: 0.3)
    |> Axon.dense(64, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.dropout(rate: 0.2)
    |> Axon.dense(2, activation: :softmax)

    model2 =
    Axon.input({nil, width * height})
    |> Axon.dense(1024, activation: :relu)
    |> Axon.dense(2, activation: :softmax)

    model3 = 
    Axon.input({nil, 1, width, height})
    |> Axon.conv(16, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(16, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    #|> Axon.separable_conv2d(32, kernel_size: {3, 3}, padding: :same, activation: :relu)
    #|> Axon.separable_conv2d(32, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(32, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(32, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    #|> Axon.separable_conv2d(64, kernel_size: {3, 3}, padding: :same, activation: :relu)
    #|> Axon.separable_conv2d(64, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(64, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(64, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    #|> Axon.separable_conv2d(128, kernel_size: {3, 3}, padding: :same, activation: :relu)
    #|> Axon.separable_conv2d(128, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(128, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(128, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.dropout(rate: 0.2)
    #|> Axon.separable_conv2d(256, kernel_size: {3, 3}, padding: :same, activation: :relu)
    #|> Axon.separable_conv2d(256, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(256, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.conv(256, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.dropout(rate: 0.2)
    |> Axon.flatten()
    |> Axon.dense(512, activation: :relu)
    |> Axon.dropout(rate: 0.7)
    |> Axon.dense(128, activation: :relu)
    |> Axon.dropout(rate: 0.5)
    |> Axon.dense(64, activation: :relu)
    |> Axon.dropout(rate: 0.3)
    |> Axon.dense(2, activation: :sigmoid)

    #95%
    model95 = 
    Axon.input({nil, 1, width, height})
    |> Axon.conv(32, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.conv(64, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.conv(256, kernel_size: {3, 3}, padding: :same, activation: :relu)
    |> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    |> Axon.flatten()
    #|> Axon.dense(1024, activation: :relu)
    |> Axon.dense(512, activation: :relu)
    |> Axon.dense(2, activation: :sigmoid)

    #model = 
    #Axon.input({nil, 1, width, height})
    #|> Axon.conv(64, kernel_size: {3, 3}, padding: :same, activation: :relu)
    #|> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    #|> Axon.conv(32, kernel_size: {3, 3}, padding: :same, activation: :relu)
    #|> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    #|> Axon.conv(16, kernel_size: {3, 3}, padding: :same, activation: :relu)
    #|> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    #|> Axon.conv(8, kernel_size: {3, 3}, padding: :same, activation: :relu)
    #|> Axon.max_pool(kernel_size: {2, 2}, padding: :same)
    #|> Axon.flatten()
    #|> Axon.dense(1024, activation: :relu)
    #|> Axon.dropout(rate: 0.4)
    #|> Axon.dense(2, activation: :softmax)

    img_stream = ImageDataGenerator.stream(%{
        path: "priv/chest_xray/train/",
        class_map: %{"NORMAL": 0, "PNEUMONIA": 1},
        log: false,
        cache: true,
        open_flags: OpenCV.cv_IMREAD_GRAYSCALE,
        width: width,
        height: height,
        clahe: 5,
        rescale: 255,
        batch_ahead: 12,
        batch_size: 32, #327  16 653
        batch_count: 8,
        #shape: {nil, 128*128},
        shape: {nil, 1, width, height},
        rotation_range: -100..100,
        shear_range: -100..100,
        width_shift_range: -100..100,
        height_shift_range: -100..100,
        horizontal_flip: true
    })

    test_stream = ImageDataGenerator.stream(%{
        path: "priv/chest_xray/test/",
        class_map: %{"NORMAL": 0, "PNEUMONIA": 1},
        cache: true,
        open_flags: OpenCV.cv_IMREAD_GRAYSCALE,
        width: width,
        height: height,
        clahe: 5,
        rescale: 255,
        batch_size: 999999,
        batch_ahead: 1,
        #shape: {nil, 128*128},
        shape: {nil, 1, width, height},
    })

    x_test = nil
    y_test = nil
    [{x_test, y_test}] = Enum.map(test_stream, & &1)

    epochs = 300

    fn_epoch = fn(s)->
        #:halt_epoch, :halt_loop, or :continue
        result = Axon.predict(model, s.step_state.model_state, x_test, compiler: EXLA)
        result = result
        |> Nx.argmax(axis: 1)
        |> Nx.reshape({Nx.axis_size(x_test, 0), 1})
        |> Nx.equal(Nx.tensor(Enum.to_list(0..1)))

        acc = Axon.Metrics.accuracy(y_test, result)
        error = Axon.Metrics.mean_absolute_error(y_test, result)
        IO.inspect {Nx.to_number(acc), Nx.to_number(error)}

        {:continue, s}
    end

    fn_v = fn(t)-> Float.round(Nx.to_number(t), 4) end
    fn_stats = fn(m)->
        val = m["validation_0"]
        acc = fn_v.(m["accuracy"])
        loss = fn_v.(m["loss"])
        p = fn_v.(m["precision"])
        r = fn_v.(m["recall"])
        val_acc = fn_v.(val["accuracy"])
        val_loss = fn_v.(val["loss"])
        val_p = fn_v.(val["precision"])
        val_r = fn_v.(val["recall"])
        "acc: #{acc} loss: #{loss} p: #{p} r: #{r} | val_acc: #{val_acc} val_loss: #{val_loss} val_p: #{val_p} val_r: #{val_r}"
    end

    pid = :erlang.spawn(fn()->
        wtf = fn(recur)->
            receive do
                x -> 
                    IO.inspect(x)
                    recur.(recur)
            end
        end
        wtf.(wtf)
    end)

    fn_epoch2 = fn(s)->
        send(pid, s.metrics)
        #IO.puts(fn_stats.(s.metrics))
        #handler_metadata = s.handler_metadata || %{}
        #s = Map.put(s, :handler_metadata, handler_metadata)
        {:continue, s}
    end

    trained_model = model
    #|> Axon.Loop.trainer(:binary_cross_entropy, Axon.Optimizers.adam(0.001))
    |> Axon.Loop.trainer(:categorical_cross_entropy, Axon.Optimizers.adam(0.001))
    #|> Axon.Loop.trainer(:categorical_cross_entropy, Axon.Optimizers.adamw(0.1))
    |> Axon.Loop.metric(:accuracy)
    |> Axon.Loop.metric(:recall)
    |> Axon.Loop.metric(:precision)
    |> Axon.Loop.validate(model, [{x_test, y_test}])
    #|> Axon.Loop.handle(:epoch_completed, fn_epoch)
    #|> Axon.Loop.handle(:epoch_completed, fn_epoch2)
    |> Axon.Loop.run(img_stream, epochs: epochs, compiler: EXLA)

    #trained_model_binary = :erlang.term_to_binary(trained_model)
    #:ok = File.write!("priv/xray-pneumonia/model_trained", trained_model_binary)
    #model_binary = :erlang.term_to_binary(model)
    #:ok = File.write!("priv/xray-pneumonia/model", model_binary)
  end
end