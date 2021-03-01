defmodule Snip do
    def test() do
        gym = Lab.Gym.init()

        frozen = Lab.Game.FrozenLake.init()
        Lab.Game.FrozenLake.render(frozen)
        {frozen, _} = Lab.Game.FrozenLake.act(frozen, :right)
        {frozen, _} = Lab.Game.FrozenLake.act(frozen, :down)
    end

    def gym_game() do
        gym = Lab.Gym.init()
        gym = Lab.Gym.make(gym, "FrozenLake-v0")
    end

    def run() do
        t = Lab.Trainer.Sarsa.init(Lab.Game.FrozenLake)
        Lab.Trainer.Sarsa.train(t, 10000)

        t = Lab.Trainer.QBasic.init(Lab.Game.FrozenLake)
        t = Lab.Trainer.QBasic.train(t, 10000)
        t = Lab.Trainer.QBasic.test(t, 1)
    end

    def solve_frozen_lake() do
        t = Lab.Trainer.QBasic.init(Lab.Game.FrozenLake)
        t = Lab.Trainer.QBasic.train(t, 10000)
        t = Lab.Trainer.QBasic.test(t, 10)
    end
end
