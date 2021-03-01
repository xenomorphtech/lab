defmodule Lab.Gym do
  @moduledoc """
  This module is an API for accessing
  Python OpenAI Gym methods
  """

  def init() do
    python_session = Lab.Python.start()

     %{
       python: python_session,
       env: nil,
       current_state: nil,
       action_space: nil,
       observation_space: nil
     }
  end

  def make(ex_gym, environment_name) do
    {env, initial_state, action_space, observation_space} =
      Lab.Python.call(
        ex_gym.python,
        :gym_interface,
        :make,
        [environment_name]
      )

     %{ex_gym |
       env: env,
       current_state: initial_state,
       action_space: Gyx.Gym.Utils.gyx_space(action_space),
       observation_space: Gyx.Gym.Utils.gyx_space(observation_space)
     }
  end

  def act(ex_gym, action) do
    {next_env, {gym_state, reward, done, info}} =
      Lab.Python.call(
        ex_gym.python,
        :gym_interface,
        :step,
        [ex_gym.env, action]
      )

    experience = %{reward: reward, done: done, info: info}
    {%{ex_gym | env: next_env, current_state: gym_state}, experience}
  end

  def reset(ex_gym) do
    {env, initial_state, action_space, observation_space} =
      Lab.Python.call(ex_gym.python, :gym_interface, :reset, [ex_gym.env])

    %{ex_gym |
        env: env,
        current_state: initial_state,
        action_space: Gyx.Gym.Utils.gyx_space(action_space),
        observation_space: Gyx.Gym.Utils.gyx_space(observation_space)
    }
  end

  def render(ex_gym, :python) do
    Lab.Python.call(ex_gym.python, :gym_interface, :render, [ex_gym.env])
  end

  def render(ex_gym, :terminal, args \\ %{scale: 0.5}) do
    Lab.Python.call(ex_gym.python, :gym_interface, :getScreenRGB2, [ex_gym.env])
    |> Matrex.new()
    |> Matrex.resize(args.scale)
    |> Matrex.heatmap(:color8)
    |> (fn _ -> :ok end).()
  end

  def get_rgb(ex_gym) do
    Lab.Python.call(ex_gym.python, :gym_interface, :getScreenRGB2, [ex_gym.env])
    |> Matrex.new()
  end

  def get_rgb_full(ex_gym) do
    Lab.Python.call(ex_gym.python, :gym_interface, :getScreenRGB3, [ex_gym.env])
    |> List.to_tuple()
  end

  def observe(ex_gym) do
      ex_gym.current_state
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
end
