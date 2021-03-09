defmodule Lab.Trainer.QTable do
  def init() do
    %{actions: %{}, table: %{}}
  end

  def get_q(qtable) do
      qtable.table
  end

  def get_q_matrix(qtable) do
    map_to_matrix(qtable.table, Kernel.map_size(qtable.actions))
  end

  def print_q_matrix(qtable) do
    map_to_matrix(qtable.table, Kernel.map_size(qtable.actions))
    |> Matrex.heatmap(:color8)
    |> (fn _ -> :ok end).()
  end

  def get(qtable, env_state, action) do
    expected_reward = qtable.table[inspect(env_state)][action]
    expected_reward || 0.0
  end

  def set(qtable, env_state, action, value) do
    k_state = inspect(env_state)

    qtable = put_in(qtable, [:actions, action], 1)
    qtable = put_in(qtable, [:table, k_state], Map.put(qtable.table[k_state]||%{}, action, value))
    qtable
  end

  def next_max(qtable, env_state) do
    q_state = qtable.table[inspect(env_state)] || %{}
    Enum.max(q_state |> Enum.map(& elem(&1,1)), fn()-> 0.0 end)
  end

  def next_max_action(qtable, env_state) do
    q_state = qtable.table[inspect(env_state)] || %{}
    {action,_} = Enum.max_by(q_state, & elem(&1,1), fn()-> {0,0} end)
    action
  end

  def get_max_action(qtable, env_state) do
    (qtable.table[inspect(env_state)] || %{})
    |> Enum.sort_by(fn {_, v} -> v end, &>=/2)
    |> List.first()
    |> case do
        nil -> %{result: :environment_state_not_observed}
        {action, _} -> %{result: :ok, action: action}
    end
  end

  defp map_to_matrix(_, actions_size) when actions_size < 2 do
    Matrex.new([[0, 0], [0, 0]])
  end

  defp map_to_matrix(map_state_value_table, actions_size) do
    map_state_value_table
    |> Map.values()
    |> Enum.map(fn vs -> Map.values(vs) end)
    |> Enum.filter(&(length(&1) == actions_size))
    |> (fn l ->
          if length(l) < actions_size do
            [[0, 0], [0, 0]]
          else
            l
          end
        end).()
    |> Matrex.new()
  end
end
