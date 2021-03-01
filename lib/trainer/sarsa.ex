defmodule Lab.Trainer.Sarsa do
  @moduledoc """
  This module describes an entire training process,
  tune accordingly to your particular environment and agent
  """

  @agent_module Lab.Trainer.AgentSarsa

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

  def init_1(gym) do
    qtable = Lab.Trainer.QTable.init()
    agent = @agent_module.init(qtable)

     %{
       gym: gym,
       agent: agent,
       trajectory: [],
       rewards: []
     }
  end

  def train(trainer, episodes) do
    trainer(trainer, episodes)
  end

  defp trainer(t, 0), do: t

  defp trainer(t, num_episodes) do
    gym = t.gym.module.reset(t.gym)
    t = Map.put(t, :gym, gym)

    t
    |> initialize_trajectory()
    # |> IO.inspect(label: "Trajectory initialized")
    |> run_episode(false)
    # |> IO.inspect(label: "Episode finished")
    |> log_stats()
    |> trainer(num_episodes - 1)
  end

  defp run_episode(t, true), do: t

  defp run_episode(t, false) do
    next_action = @agent_module.act_epsilon_greedy(t.agent, %{
        current_state: t.gym.current_state,
        action_space: t.gym.action_space
    })

    {gym_next, exp = %{done: done, reward: r}} = t.gym.module.step(t.gym, next_action)
    if r >= 1.0 do
        IO.inspect r
    end

    aa = @agent_module.act_epsilon_greedy(t.agent, %{
        current_state: gym_next.current_state,
        action_space: t.gym.action_space
    })

    {agent, _expected_return} = @agent_module.td_learn(t.agent, {t.gym.current_state, next_action, r, gym_next.current_state, aa})

    t = Map.put(t, :gym, gym_next)
    t = Map.put(t, :agent, agent)
    t = %{t | trajectory: [exp | t.trajectory]}
    run_episode(t, done)
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
