defmodule Lab.Game.FrozenLake do
  @moduledoc """
  This module implements the FrozenLake-v0
  environment according to
  OpenAI implementation: https://gym.openai.com/envs/FrozenLake-v0/
  """

  @actions %{0 => :left, 1 => :down, 2 => :right, 3 => :up}

  @maps %{
    "4x4" => [
      "SFFF",
      "FHFH",
      "FFFH",
      "HFFG"
    ],
    "8x8" => [
      "SFFFFFFF",
      "FFFFFFFF",
      "FFFHFFFF",
      "FFFFFHFF",
      "FFFHFFFF",
      "FHHFFFHF",
      "FHFFHFHF",
      "FFFHFFFG"
    ]
  }

  def init(map_name \\ "4x4") do
    map = @maps[map_name]

     %{
       env: %{
         map: map,
         row: 0,
         col: 0,
         nrow: length(map),
         ncol: String.length(List.first(map)),
       },
       state: 0,
       observable_state: 0,
       action_space: %Lab.Struct.Discrete{n: 4},
       observation_space: %Lab.Struct.Discrete{n: 16}
     }
  end

  def actions(ex_gym) do
    0..(ex_gym.action_space.n-1)
  end

  def render(ex_gym) do
    printEnv(ex_gym.env.map, ex_gym.env.row, ex_gym.env.col)
    %{position: %{row: ex_gym.env.row, col: ex_gym.env.col}}
  end

  def reset(ex_gym) do
    %{ex_gym | state: 0, observable_state: 0, env: %{ex_gym.env | row: 0, col: 0}}
  end

  def act(ex_gym, action) do
    env = rwo_col_step(ex_gym.env, action)
    current_tile = get_position(env.map, env.row, env.col)

    ex_gym = %{ex_gym | state: env_state_transformer(env), observable_state: env_state_transformer(env),  env: env}
    experience = %{
      reward: if(current_tile == "G", do: 1.0, else: 0.0),
      done: (current_tile in ["H", "G"]),
      info: %{}
    }
    {ex_gym, experience}
  end

  def observe(ex_gym) do
      ex_gym.state
  end

  def step(ex_gym, action) do
    case check(ex_gym, action) do
        %{result: :invalid_action} -> %{result: :invalid_action}
        %{result: :ok} -> act(ex_gym, action)
    end
  end

  def check(ex_gym, action) do
    case Gyx.Core.Spaces.contains?(ex_gym.action_space, action) do
      false -> %{result: :invalid_action}
      _ -> %{result: :ok}
    end
  end

  defp get_position(map, row, col) do
    Enum.at(String.graphemes(Enum.at(map, row)), col)
  end

  def env_state_transformer(env), do: env.row * 4 + env.col

  defp rwo_col_step(env, action) do
    case @actions[action] do
      :left -> %{env | col: max(env.col - 1, 0)}
      :down -> %{env | row: min(env.row + 1, env.nrow - 1)}
      :right -> %{env | col: min(env.col + 1, env.ncol - 1)}
      :up -> %{env | row: max(env.row - 1, 0)}
      _ -> env
    end
  end

  defp printEnv([], _, _), do: :ok

  defp printEnv([h | t], row, col) do
    printEnvLine(h, col, row == 0)
    printEnv(t, row - 1, col)
  end

  defp printEnvLine(string_line, agent_position, mark) do
    chars_line = String.graphemes(string_line)

    m =
      if mark,
        do:
          IO.ANSI.format_fragment(
            [:light_magenta, :italic, chars_line |> Enum.at(agent_position)],
            true
          ),
        else: [Enum.at(chars_line, agent_position)]

    p =
      IO.ANSI.format_fragment(
        [:light_blue, :italic, chars_line |> Enum.take(agent_position) |> List.to_string()],
        true
      )

    q =
      IO.ANSI.format_fragment(
        [
          :light_blue,
          :italic,
          chars_line |> Enum.take(agent_position - length(chars_line) + 1) |> List.to_string()
        ],
        true
      )

    (p ++ m ++ q)
    |> IO.puts()
  end
end
