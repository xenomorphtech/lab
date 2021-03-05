defmodule Lab.MixProject do
  use Mix.Project

  def project do
    [
      app: :lab,
      version: "0.1.0",
      elixir: "~> 1.11.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs",
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssl],
      mod: {Lab, []}
    ]
  end

  defp aliases do
    [
      compile: ["compile", "dialyzer --ignore-exit-status --format dialyxir"],
      compile2: ["compile"],
      plt: ["dialyzer --force-check"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:erlport, "~> 0.10.0"},
      {:matrex, "~> 0.6"},

      # our utilities
      {:dialyxir, git: "https://github.com/xenomorphtech/dialyxir", only: [:dev], runtime: false},

      #for slaythespire
      {:java_erlang, git: "https://github.com/fredlund/JavaErlang"},

      #utils
      #{:mnesia_kv, git: "https://github.com/xenomorphtech/mnesia_kv.git"},
      #{:comsat, git: "https://github.com/vans163/ComSat.git"},
      {:exjsx, "~> 4.0.0"},
      #{:stargate, git: "https://github.com/vans163/stargate.git"},
    ]
  end
end
