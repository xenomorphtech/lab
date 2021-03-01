defmodule Lab.Python do
  def start() do
    path = Path.join([:code.priv_dir(:lab)])

    {:ok, pid} = :python.start([
      {:python, 'python3'},
      {:python_path, to_charlist(path)}
    ])

    pid
  end

  def call(pid, m, f, a \\ []) do
    :python.call(pid, m, f, a)
  end

  def cast(pid, message) do
    :python.cast(pid, message)
  end

  def stop(pid) do
    :python.stop(pid)
  end
end
