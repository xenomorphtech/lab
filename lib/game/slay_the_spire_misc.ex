defmodule SlayTheSpireMisc do
    def intent(intent) do
        case intent do
            "ATTACK" -> 0
            "ATTACK_BUFF" -> 1
            "ATTACK_DEBUFF" -> 2
            "ATTACK_DEFEND" -> 3
            "BUFF" -> 4
            "DEBUFF" -> 5
            "STRONG_DEBUFF" -> 6
            "DEBUG" -> 7
            "DEFEND" -> 8
            "DEFEND_DEBUFF" -> 9
            "DEFEND_BUFF" -> 10
            "ESCAPE" -> 11
            "MAGIC" -> 12
            "NONE" -> 13
            "SLEEP" -> 14
            "STUN" -> 15
            "UNKNOWN" -> 16
        end
    end

    def card_type(type) do
        case type do
            "ATTACK" -> 0
            "SKILL" -> 1
            "POWER" -> 2
            "STATUS" -> 3
            "CURSE" -> 4
        end
    end

    def card_rarity(type) do
        case type do
            "BASIC" -> 0
            "SPECIAL" -> 1
            "COMMON" -> 2
            "UNCOMMON" -> 3
            "RARE" -> 4
            "CURSE" -> 5
        end
    end

    def enemy_type(type) do
        case type do
            "NORMAL" -> 0
            "ELITE" -> 1
            "BOSS" -> 2
        end
    end
end
