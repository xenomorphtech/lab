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
            state: nil,
            observable_state: <<>>,
            module: SlayTheSpire,
        }
    end

    def observable_state(ex_gym) do
        if ex_gym.state.game.roomPhase == "COMBAT" do
            hasBash = if Enum.find(ex_gym.state.player.hand, & &1.id == "Bash" && &1.hasEnoughEnergy), do: 1, else: 0
            hasStrike = if Enum.find(ex_gym.state.player.hand, & &1.id == "Strike_R" && &1.hasEnoughEnergy), do: 1, else: 0
            hasDefend = if Enum.find(ex_gym.state.player.hand, & &1.id == "Defend_R" && &1.hasEnoughEnergy), do: 1, else: 0
            mob1Type = 0
            mob1Alive = if hd(ex_gym.state.fight.monsters).isDeadOrEscaped, do: 0, else: 1
            mob1IsAttack = if hd(ex_gym.state.fight.monsters).intentDmg == -1, do: 0, else: 1
            <<hasBash, hasStrike, hasDefend, mob1Type, mob1Alive, mob1IsAttack>>
        else
            ""
        end
    end

    def reward(oldState, newState) do
        won_fight = if !oldState.fight[:won] and !!newState.fight[:won], do: 1.0, else: 0.0
        #newState.player.damageReceivedThisCombat

        hp_delta = (oldState.player.hp - newState.player.hp) * -0.05
        dead = if newState.player.isDead, do: -10.0, else: 0.0
        reward = won_fight + hp_delta + dead

        %{reward: reward, done: newState.game.floor == 3 || newState.player.isDead}
    end

    def reset(ex_gym, seed \\ 1) do
        :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :startDungeon, [seed])
        Process.sleep(1_000)
        ex_gym = Map.put(ex_gym, :state, observe(ex_gym))
        Map.put(ex_gym, :observable_state, "")
    end

    def step(ex_gym, action) do
        act(ex_gym, action)
    end

    def act(ex_gym, action) do
        oldState = ex_gym.state
        case action do
            %{action: :use_card, cost: cost, id: id, target_index: mob_idx} ->
                card = Enum.find(ex_gym.state.player.hand, & &1.id == id && &1.costNow == cost)
                action_playCard(ex_gym, card.index, mob_idx)
            %{action: :use_card, cost: cost, id: id} ->
                card = Enum.find(ex_gym.state.player.hand, & &1.id == id && &1.costNow == cost)
                action_playCard(ex_gym, card.index)

            %{action: :use_card, card_index: idx, target_index: mob_idx} ->
                action_playCard(ex_gym, idx, mob_idx)
            %{action: :use_card, card_index: idx} ->
                action_playCard(ex_gym, idx)
            %{action: :end_turn} ->
                action_endTurn(ex_gym)
            %{action: :next_floor, x: x, y: y} ->
                action_setCurrMapNode(ex_gym, x, y)
            %{action: :claim_reward, index: index} ->
                action_claimReward(ex_gym, index)
            %{action: :claim_card_reward, index: index, card_index: card_index} ->
                action_claimCardReward(ex_gym, index, card_index)
            %{action: :skip_reward, index: index} ->
                action_skipReward(ex_gym, index)
        end
        newState = observe(ex_gym)

        experience = reward(oldState, newState)
        ex_gym = Map.put(ex_gym, :state, newState)
        ex_gym = Map.put(ex_gym, :observable_state, observable_state(ex_gym))
        {ex_gym, experience}
    end

    def observe(ex_gym) do
        :java.string_to_list(:java.call_static(ex_gym.jvm, :'com.megacrit.cardcrawl.desktop.ApiObj', :state, []))
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

    def observe_floats(ex_gym) do
        map = observe(ex_gym)
    end

    def actions(ex_gym) do
        state = %{player: %{hand: hand}, fight: %{monsters: monsters}, game: game = %{screen: screen}} = observe(ex_gym)
        actions = cond do
            game.roomPhase == "COMBAT" ->
                hand = Enum.filter(hand, & &1.hasEnoughEnergy)
                Enum.map(hand, fn(card)->
                    if card.target in ["ENEMY", "SELF_AND_ENEMY"] do #only spot_weakness has SELF_AND_ENEMY
                        Enum.map(monsters, fn(monster)->
                            if !monster.isDeadOrEscaped do
                                #%{action: :use_card, card_index: card.index, target_index: monster.index}
                                %{action: :use_card, id: card.id, cost: card.costNow, target_index: monster.index}
                            end
                        end)
                    else
                        #%{action: :use_card, card_index: card.index}
                        %{action: :use_card, id: card.id, cost: card.costNow}
                    end
                end)
                |> List.flatten()
                |> Enum.uniq_by(& {&1.id, &1.cost, &1[:target_index]})
                |> List.insert_at(-1, %{action: :end_turn})

            state.screenType == "COMBAT_REWARD" and length(screen.rewards) > 0 ->
                Enum.find_value(screen.rewards, fn(reward)->
                    cond do
                        reward.type == "GOLD" -> %{action: :claim_reward, index: reward.index}
                        reward.type == "POTION" and length(state.player.potions) < state.player.potionSlots ->
                            %{action: :claim_reward, index: reward.index}
                            #%{action: :claim_reward, id: reward.id}
                        reward.type == "POTION" ->
                            #swap_potion_for_another skip for now
                            #%{action: :claim_reward, index: reward.index}
                            %{action: :skip_reward, index: reward.index}
                        reward.type == "CARD" ->
                            Enum.map(reward.cards, fn(card)->
                                %{action: :claim_card_reward, index: reward.index, card_index: card.index}
                            end) ++ [%{action: :skip_reward, index: reward.index}]
                            %{action: :skip_reward, index: reward.index}
                        true -> nil
                    end
                end)

            state.screenType in ["COMBAT_REWARD", "MAP"] ->
                #fix this for forked path
                if game.map.curY == -1 do
                    cur_node = Enum.find(game.map.nodes, & &1.srcY == 0)
                    %{action: :next_floor, x: cur_node.srcX, y: cur_node.srcY}
                else
                    cur_node = Enum.find(game.map.nodes, & &1.srcX == game.map.curX && &1.srcY == game.map.curY)
                    %{action: :next_floor, x: cur_node.dstX, y: cur_node.dstY}
                end
        end

        actions
        |> List.wrap()
        |> List.flatten()
        |> Enum.filter(& &1)
    end

    def observations(ex_gym) do

    end

    def action_setCurrMapNode(ex_gym, x, y) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :setCurrMapNode2, [x,y])
        Process.sleep(100)
    end

    def action_playCard(ex_gym, card_idx, target_idx \\ nil) do
        if !target_idx do
            :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :playCard, [card_idx])
        else
            :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :playCard, [card_idx, target_idx])
        end
        Process.sleep(20)
    end

    def action_endTurn(ex_gym) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :endTurn, [])
        Process.sleep(100)
    end

    def action_waitScreenChange(ex_gym) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :waitScreenChange, [])
        Process.sleep(100)
    end

    def action_skipReward(ex_gym, reward_idx) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :skipReward, [reward_idx])
        Process.sleep(100)
    end

    def action_claimReward(ex_gym, reward_idx) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :claimReward, [reward_idx])
        Process.sleep(100)
    end

    def action_claimCardReward(ex_gym, reward_idx, card_idx) do
        :void = :java.call_static(ex_gym.jvm,:'com.megacrit.cardcrawl.desktop.ApiObj', :claimCardReward, [reward_idx, card_idx])
        Process.sleep(100)
    end

    def test_gym_basic() do
        sts = SlayTheSpire.init()

        sts = SlayTheSpire.reset(sts, 1)
        [act = %{action: :next_floor, x: 3, y: 0}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)

        [
          %{action: :use_card, cost: 1, id: "Strike_R", target_index: 0},
          act = %{action: :use_card, cost: 2, id: "Bash", target_index: 0},
          %{action: :use_card, cost: 1, id: "Defend_R"},
          %{action: :end_turn}
        ] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :use_card, cost: 1, id: "Strike_R"} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :end_turn}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)

        [_, act = %{action: :use_card, card_index: 1, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [_, act = %{action: :use_card, card_index: 1, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [_, act = %{action: :use_card, card_index: 1, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :end_turn}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: r}} = SlayTheSpire.step(sts, act)
        true = r == -0.3

        [_, _, act = %{action: :use_card, card_index: 2, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :use_card, card_index: 0, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: r}} = SlayTheSpire.step(sts, act)
        true = r == 1.3

        [act = %{action: :claim_reward, index: 0}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :skip_reward, index: 0}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)

        [%{action: :next_floor, x: 4, y: 1}] = SlayTheSpire.actions(sts)
    end

    def test_gym() do
        sts = SlayTheSpire.init()

        sts = SlayTheSpire.reset(sts, 1)
        [act = %{action: :next_floor, x: 3, y: 0}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)

        [
          %{action: :use_card, card_index: 0, target_index: 0},
          %{action: :use_card, card_index: 1, target_index: 0},
          act = %{action: :use_card, card_index: 2, target_index: 0} | _
        ] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :use_card, card_index: 0, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :end_turn}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)

        [_, act = %{action: :use_card, card_index: 1, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [_, act = %{action: :use_card, card_index: 1, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [_, act = %{action: :use_card, card_index: 1, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :end_turn}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: r}} = SlayTheSpire.step(sts, act)
        true = r == -0.3

        [_, _, act = %{action: :use_card, card_index: 2, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :use_card, card_index: 0, target_index: 0} | _] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: r}} = SlayTheSpire.step(sts, act)
        true = r == 1.3

        [act = %{action: :claim_reward, index: 0}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)
        [act = %{action: :skip_reward, index: 0}] = SlayTheSpire.actions(sts)
        {sts, %{done: false, reward: 0.0}} = SlayTheSpire.step(sts, act)

        [%{action: :next_floor, x: 4, y: 1}] = SlayTheSpire.actions(sts)
    end

    #this test on normal client seed==1 the first 4 mobs should be idential along with all card indexes
    #5th mob on normal client should be mushrooms
    def test_hardcoded_onlymobs_nocards() do
        sts = SlayTheSpire.init()
        test_hardcoded_onlymobs_nocards_1(sts, 1)
    end
    def test_hardcoded_onlymobs_nocards_1(sts, times \\ 1) do
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
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_skipReward(sts, 0)
        %{game: %{screen: %{rewards: []}}} = SlayTheSpire.observe(sts)


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
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_skipReward(sts, 0)
        %{game: %{screen: %{rewards: []}}} = SlayTheSpire.observe(sts)

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
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_skipReward(sts, 0)
        %{game: %{screen: %{rewards: []}}} = SlayTheSpire.observe(sts)

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
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_skipReward(sts, 0)
        %{game: %{screen: %{rewards: []}}} = SlayTheSpire.observe(sts)

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
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_skipReward(sts, 0)
        %{game: %{screen: %{rewards: []}}} = SlayTheSpire.observe(sts)

        #fight 6 burb
        SlayTheSpire.action_setCurrMapNode(sts, 5, 5)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 4, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_claimReward(sts, 0)

        #fight 7 slime2x
        SlayTheSpire.action_setCurrMapNode(sts, 5, 6)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_playCard(sts, 1)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 2, 1)
        SlayTheSpire.action_playCard(sts, 2, 1)
        SlayTheSpire.action_playCard(sts, 2, 1)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 1, 1)
        SlayTheSpire.action_playCard(sts, 1, 1)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)
        SlayTheSpire.action_claimReward(sts, 0)

        #fight 8 dinosuar
        SlayTheSpire.action_setCurrMapNode(sts, 4, 7)
        SlayTheSpire.action_playCard(sts, 3, 0)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_playCard(sts, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 4, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 4, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)

        #fight 9 treasureroom
        SlayTheSpire.action_setCurrMapNode(sts, 3, 8)
        %{currMapNodeRoomType: "TreasureRoom"} = SlayTheSpire.observe(sts)
        SlayTheSpire.action_claimReward(sts, 0)

        #fight 10 burb
        SlayTheSpire.action_setCurrMapNode(sts, 3, 9)
        SlayTheSpire.action_playCard(sts, 1, 0)
        SlayTheSpire.action_playCard(sts, 0, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 0)
        SlayTheSpire.action_endTurn(sts)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        SlayTheSpire.action_playCard(sts, 2, 0)
        %{fight: %{won: true}} = SlayTheSpire.observe(sts)
        Process.sleep(100)
        SlayTheSpire.action_claimReward(sts, 0)

        %{player: %{gold: 233, potions: potions}} = SlayTheSpire.observe(sts)
        true = length(potions) == 3

        if times > 0 do
            test_hardcoded_onlymobs_nocards_1(sts, times-1)
        else
            :os.system_time(1000) - start_time
        end
    end
end
