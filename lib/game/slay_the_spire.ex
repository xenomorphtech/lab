defmodule SlayTheSpire do
    @gamejar "6661e72999ce8b0e2b6f62809e8b2737-patched.jar" #2020-12-13 md5sum

    def init() do
        File.rm_rf("./priv/slay_the_spire/tmpdir")
        File.mkdir_p!("./priv/slay_the_spire/tmpdir")
        File.cp_r!("./priv/slay_the_spire/config/info.displayconfig", "./priv/slay_the_spire/tmpdir/info.displayconfig")
        File.cp_r!("./priv/slay_the_spire/config/betaPreferences2", "./priv/slay_the_spire/tmpdir/betaPreferences")
        File.cp_r!("./priv/slay_the_spire/config/saves", "./priv/slay_the_spire/tmpdir/saves")
        File.cd!("./priv/slay_the_spire/tmpdir")

        #{:ok, jvm} = :java.start_node([{:add_to_java_classpath,['./priv/slay_the_spire/#{@gamejar}']}])
        {:ok, jvm} = :java.start_node([{:add_to_java_classpath,['../#{@gamejar}']}])
        Process.sleep(2000)
        :java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :main, [])
        #:java.call_static(jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :main_silent, [])
        Process.sleep(8_000)
        %{
            jvm: jvm,
            current_state: nil,
            action_space: nil,
            observation_space: nil
        }
    end

    def reset(ex_gym, seed \\ 1) do
        :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :startDungeon, [seed])
        Process.sleep(1_000)
        ex_gym
    end

    def observe(ex_gym) do
        :java.string_to_list(:java.call_static(ex_gym.jvm, :'com.megacrit.cardcrawl.desktop.DesktopLauncher', :state, []))
        |> :unicode.characters_to_binary()
        |> JSX.decode!(labels: :atom)
    end

    def observe_basic(ex_gym) do
        %{fight: %{monsters: monsters, turn: turn}, game: game, player: player} = observe(ex_gym)

        monsters = Enum.map(monsters, & Map.drop(&1, [:intentBaseDmg]))
        player = Map.take(player, [:class, :block, :hp, :hpMax, :gold, :energy, :energyMax, :hand, :isDead, :powers])
        %{fight: %{monsters: monsters, turn: turn}, game: game, player: player}
    end

    def observe_combat(ex_gym) do
        map = observe(ex_gym)
    end

    def action_setCurrMapNode(ex_gym, x, y) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :setCurrMapNode2, [x,y])
        Process.sleep(100)
    end

    def action_playCard(ex_gym, card_idx, target_idx \\ nil) do
        if !target_idx do
            :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [card_idx])
        else
            :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :playCard, [card_idx, target_idx])
        end
    end

    def action_endTurn(ex_gym) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :endTurn, [])
    end

    def action_waitScreenChange(ex_gym) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :waitScreenChange, [])
        Process.sleep(100)
    end

    def action_claimReward(ex_gym, reward_idx) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :claimReward, [reward_idx])
    end

    def action_claimCardReward(ex_gym, reward_idx, card_idx) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.DesktopLauncher', :claimCardReward, [reward_idx, card_idx])
    end

    #this test on normal client seed==1 the first 4 mobs should be idential along with all card indexes
    #5th mob on normal client should be mushrooms
    def test_hardcoded_onlymobs() do
        sts = SlayTheSpire.init()
        start_time = :os.system_time(1000)
        sts = SlayTheSpire.reset(sts, 1)
        #SlayTheSpire.observe_basic(sts)

        #fight 1 burb
        SlayTheSpire.action_setCurrMapNode(sts, 3, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_playCard(sts, 1, 0)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        SlayTheSpire.action_claimReward(sts, 0)

        #fight 2 dinosaur
        SlayTheSpire.action_setCurrMapNode(sts, 4, 1)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 4, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        SlayTheSpire.action_claimReward(sts, 0)

        #fight 3 slimex2
        SlayTheSpire.action_setCurrMapNode(sts, 4, 2)
        SlayTheSpire.action_playCard(sts, 4, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 0, 1)
        SlayTheSpire.action_playCard(sts, 0, 1)
        SlayTheSpire.action_playCard(sts, 0, 1)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 3, 1)
        SlayTheSpire.action_playCard(sts, 2, 1)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        SlayTheSpire.action_claimReward(sts, 0)

        #fight 4 snailx2
        SlayTheSpire.action_setCurrMapNode(sts, 5, 3)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 3, 1)
        SlayTheSpire.action_playCard(sts, 3, 1)
        SlayTheSpire.action_playCard(sts, 2)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 1, 1)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        SlayTheSpire.action_claimReward(sts, 0)

        #fight 5 dinosaur
        SlayTheSpire.action_setCurrMapNode(sts, 6, 4)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_playCard(sts, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_claimReward(sts, 0)

        :os.system_time(1000) - start_time
    end
end
