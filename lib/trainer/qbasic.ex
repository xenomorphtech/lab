defmodule Lab.Trainer.QBasic do
  @moduledoc """
  This module describes an entire training process,
  basic Q learning

  Q <- Q + a(Q' - Q)
  <=> Q <- (1-a)Q + a(Q')
  """

  def init(env_name) when is_binary(env_name) do
    gym = Lab.Gym.init()
    gym = Lab.Gym.make(gym, env_name)
    gym = Map.put(gym, :module, Lab.Gym)
    init_1(gym)
  end

  def init(module) when is_atom(module) do
    gym = module.init()
    gym = Map.put(gym, :module, module)
    init_1(gym)
  end

  defp init_1(gym) do
    qtable = Lab.Trainer.QTable.init()

     %{
       gym: gym,
       qtable: qtable,
       trajectory: [],
       rewards: [],
       params: %{alpha: 0.1, gamma: 0.99}
     }
  end

  def train(t, 0), do: t
  def train(t, num_episodes) do
    gym = t.gym.module.reset(t.gym)
    t = Map.put(t, :gym, gym)

    t
    |> initialize_trajectory()
    |> run_episode(false)
    |> log_stats()
    |> train(num_episodes - 1)
  end

  defp run_episode(t, true), do: t
  defp run_episode(t, false) do
    random_action = Enum.random(t.gym.module.actions(t.gym))
    {gym_next, exp = %{done: done, reward: reward}} = t.gym.module.step(t.gym, random_action)

    cur_q_val = Lab.Trainer.QTable.get(t.qtable, t.gym.observable_state, random_action)
    q_next_max = Lab.Trainer.QTable.next_max(t.qtable, gym_next.observable_state)

    next_q_val = (1 - t.params.alpha) * cur_q_val + t.params.alpha * (reward + t.params.gamma * q_next_max)
    qtable = Lab.Trainer.QTable.set(t.qtable, t.gym.observable_state, random_action, next_q_val)

    t = Map.put(t, :gym, gym_next)
    t = Map.put(t, :qtable, qtable)
    t = %{t | trajectory: [exp | t.trajectory]}
    run_episode(t, done)
  end

  def test(t, 0), do: t
  def test(t, num_tests) do
    gym = t.gym.module.reset(t.gym)
    t = Map.put(t, :gym, gym)

    t
    |> initialize_trajectory()
    |> run_test(false)
    |> log_stats()
    |> test(num_tests - 1)
  end

  def run_test(t, true), do: t
  def run_test(t, false) do
      next_action = Lab.Trainer.QTable.next_max_action(t.qtable, t.gym.observable_state)
      {gym_next, exp = %{done: done, reward: reward}} = t.gym.module.step(t.gym, next_action)
      t = Map.put(t, :gym, gym_next)
      t = %{t | trajectory: [exp | t.trajectory]}
      run_test(t, done)
  end

  defp initialize_trajectory(t), do: %{t | trajectory: []}

  defp log_stats(t) do
    reward_sum = t.trajectory |> Enum.map(& &1.reward) |> Enum.sum()
    t = %{t | rewards: [reward_sum | t.rewards]}
    k = 100
    IO.puts("Reward: " <> to_string((t.rewards |> Enum.take(k) |> Enum.sum()) / k))
    # Gyx.Qstorage.QGenServer.print_q_matrix()
    t
  end
end
