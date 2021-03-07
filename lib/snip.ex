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

    def solve_sts_qbasic() do
        t = Lab.Trainer.QBasic.init(SlayTheSpire)
        t = Lab.Trainer.QBasic.train(t, 10)
    end

    def sts() do
        sts = SlayTheSpire.init()
        sts = SlayTheSpire.reset(sts)
        SlayTheSpire.observe_basic(sts)
        SlayTheSpire.observe(sts)
        :java.string_to_list(:java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :state, []))
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [0,0])
        IO.puts :java.string_to_list(:java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :state, []))
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :endTurn, [])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :claimReward, [0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :claimCardReward, [0,1])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :showMap, [])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :setCurrMapNode, [3,0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :setCurrMapNode2, [3,0])

        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [2,0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [1,0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [1,0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [1,0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :endTurn, [])

        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [4,0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :endTurn, [])

        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :claimReward, [0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :claimReward, [0])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :claimCardReward, [0,1])
        :java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :setCurrMapNode2, [4,1])

        IO.puts :java.string_to_list(:java.call_static(sts.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :call_state, []))


        {:ok, jvm} = :java.start_node()
        {:ok, jvm} = :java.start_node([{:add_to_java_classpath,['/home/user/project/ann/desktop-1.0/']}])
        {:ok, jvm} = :java.start_node([{:add_to_java_classpath,['/home/user/project/ann/slay_the_spire/game/desktop-1.0.jar']}])
        {:ok, jvm} = :java.start_node([{:add_to_java_classpath,['./priv/slay_the_spire/6661e72999ce8b0e2b6f62809e8b2737-patched.jar']}])
        {:ok, jvm} = :java.start_node([{:add_to_java_classpath,['./priv/slay_the_spire/6661e72999ce8b0e2b6f62809e8b2737.jar']}])


        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :main, [])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :main_silent, [])


        lwjgl = :java.new(jvm,:'com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration',[])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :loadSettings, [lwjgl])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :main, [])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :restartDungeon, [])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :exitDungeon, [])

        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [0])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [0,0])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :endTurn, [])

        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :startDungeon, [1])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.core.CardCrawlGame', :startOver, [])


        :java.string_to_list(:java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :state, []))
        :java.getClassName(:java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :state2, []))

        :java.call(sts,:'com.megacrit.cardcrawl.desktop.DesktopLauncher.loadSettings', [lwjgl])


        sts = :java.new(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher',[[]])

        str = :java.new(jvm,:'java.lang.String',[])
        str = :java.new(jvm,:'java.lang.Array',[])

        wtf = :java.new(jvm,:'java.lang.String',[:java.list_to_array(jvm,'Hello World!',:string)])
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher',:main,[wtf])


        sts = :java.new(jvm,:'com.megacrit.cardcrawl.core.CardCrawlGame',['/home/user/project/ann/slay_the_spire/game/betaPreferences'])

        :java.get_static(jvm,:'java.lang.System',:err)
        :java.get_static(jvm,:'com.megacrit.cardcrawl.core.CardCrawlGame',:startOver)

        sts = :java.new(jvm,:'com.megacrit.cardcrawl.core.CardCrawlGame',[''])
        :java.call(jvm,:'com.megacrit.cardcrawl.core.CardCrawlGame.reloadPrefs',[])


        int10 = :java.new(jvm,:'java.lang.String',[])
        string10 = :java.call(int10,:toString,[])
    end
end
