defmodule Lab.Trainer.AgentSarsa do
  @moduledoc """
  This agent implements SARSA, it takes into account the current
  state, action, reward (s<sub>t</sub>, a<sub>t</sub>, r<sub>t</sub>)
  and on policy estimates for the best next action a<sub>t+1</sub> and state s<sub>t+1</sub>.
  <br/>The Q update is given by:
  ![sarsa](https://wikimedia.org/api/rest_v1/media/math/render/svg/4ea76ebe74645baff9d5a67c83eac1daff812d79)
  <br/>
  """

  def init(qtable\\nil, params \\ %{learning_rate: 0.8, gamma: 0.9, epsilon: 0.8, epsilon_min: 0.1}) do
    qtable = qtable || Lab.Trainer.QTable.init()

     %{
       q: qtable,
       learning_rate: params.learning_rate,
       gamma: params.gamma,
       epsilon: params.epsilon,
       epsilon_min: params.epsilon_min
     }
  end

  def td_learn(agent, _sarsa = {s, a, r, ss, aa}) do
      predict = Lab.Trainer.QTable.q_get(agent.q, s, a)
      target = r + agent.gamma * Lab.Trainer.QTable.q_get(agent.q, ss, aa)
      expected_return = predict + agent.learning_rate * (target - predict)
      qtable = Lab.Trainer.QTable.q_set(agent.q, s, a, expected_return)
      {Map.put(agent, :q, qtable), expected_return}
  end

  def act_epsilon_greedy(agent, environment_state) do
    {:ok, random_action} = Gyx.Core.Spaces.sample(environment_state.action_space)
    max_action = case Lab.Trainer.QTable.get_max_action(agent.q, environment_state.current_state) do
        %{action: action} -> action
        _ -> random_action
    end

    case :rand.uniform() < 1 - agent.epsilon do
        true -> max_action
        false -> random_action
    end
  end

  def act_greedy(agent, environment_state) do
    Lab.Trainer.QTable.get_max_action(agent.q, environment_state.current_state)
  end
end
