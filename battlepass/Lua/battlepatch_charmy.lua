if CBW_Battle and chaotix and chaotix.charmy then --Only try to modify if we're certain Bomb is loaded

    local charmy = chaotix.charmy
    local B = CBW_Battle

    local function CanSpindash(player)
    
        return (player.speed < FixedMul(5<<FRACBITS, player.mo.scale))
        and not(player.mo.momz) and P_IsObjectOnGround(player.mo)
        and not(gamestate == GS_LEVEL and player.mo and player.mo.health > 0
            and (abs(player.rmomx) >= FixedMul(FRACUNIT/2, player.mo.scale)
                or abs(player.rmomy) >= FixedMul(FRACUNIT/2, player.mo.scale)
                or abs(player.mo.momz) >= FixedMul(FRACUNIT/2, player.mo.scale)
                or player.climbing or player.powers[pw_tailsfly]
                or (player.pflags & PF_JUMPED)))
    end

    local ischarmy = function(player)
        return (player and player.mo and player.mo.valid and player.mo.skin == charmy.SKIN)
    end

    local stillStingerDash_PreThink = function(player)
        local flagholding = (player.gotflagdebuff)
        local canfusedash = (CanSpindash(player) or player.skidtime or (player.pflags & PF_STARTDASH))

        if canfusedash and player.mo.charmypatch_spin and not(player.cmd.buttons & BT_SPIN) then
            player.mo.charmypatch_spin = nil
        end

        if (not(canfusedash) and flagholding) or player.mo.charmypatch_spin then
            if (player.cmd.buttons & BT_SPIN) and not(player.mo.charmypatch_spin) then
                player.mo.charmypatch_spin = true
            end
            player.cmd.buttons = $ & ~(BT_SPIN)
        end
    end

    addHook("PreThinkFrame", do
        for player in players.iterate
            if ischarmy(player) then
                stillStingerDash_PreThink(player)
            end
        end
    end)

end