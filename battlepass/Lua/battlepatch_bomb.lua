
--Mari0shi here!

if CBW_Battle and chaotix and chaotix.bomb then --Only try to modify if we're certain Bomb is loaded
    
    local bomb = chaotix.bomb
    local B = CBW_Battle

    bomb.ExplodeTics = TICRATE*1/4 --This constant determines how long Bomb's explosions last | Originally TICRATE*2/3
    bomb.ExplodeRange = FRACUNIT*115 --This constant determines the range of Bomb's explosions | Originally FRACUNIT*128

    local SpinSpecial_old = bomb.SpinSpecial --Clone his SpinSpecial function


    local isbomb = function(player)
        return (player and player.mo and player.mo.valid and player.mo.skin == bomb.SKIN)
    end

    local jumpCheck_PostThink = function(player)

        local flagholding = (player.gotflagdebuff)
        local jumped = (player.pflags & PF_STARTJUMP)

        if flagholding and jumped then
            player.mo.bomb_fusedash = false
            player.pflags = $ & ~PF_SPINNING
            S_StopSoundByID(player.mo, sfx_sc0a5h)
            player.mo.state = S_PLAY_JUMP
        end --Try to cancel out fusedash if you manage to jump-spin it while flagholding
    end

    local volatilePause_Think = function(player)

        local st_volatile = (player.mo.bomb_volatile == bomb.VolatileFlags["MELTDOWN"])
        local zoomtube = (player.powers[pw_carry] == CR_ZOOMTUBE)

        if zoomtube and st_volatile then
            player.actiontime = $+1 --Stop his timer from decreasing by increasing it back
        end
    end

    local B_GotFlagStats_old = B.GotFlagStats

    B.GotFlagStats = function(player)
        local skin = skins[player.mo.skin]
        if (player.gotflag or player.gotcrystal) and player.gotflagdebuff == false then
            if isbomb(player) then
                local speedlimit = skin.normalspeed*4/5
			    player.mo.momx = max(min($,speedlimit),-speedlimit)
                player.mo.momy = max(min($,speedlimit),-speedlimit)
                player.maxdash = skin.maxdash*4/6
            end
        end
        B_GotFlagStats_old(player)
    end


    --Fix issue where characters like Mario & Luigi get forced into roll
    local SetTopSpinState_old = chaotix.bomb.SetTopSpinState

    bomb.SetTopSpinState = function(p)
        if not(isbomb(p)) then
            return
        end
        SetTopSpinState_old(p) --Execute normally
    end

    addHook("PostThinkFrame", do
        for player in players.iterate
            if isbomb(player) then
                jumpCheck_PostThink(player)
            end
        end
    end)

    addHook("ThinkFrame", do
        for player in players.iterate
            if isbomb(player) then
                volatilePause_Think(player)
            end
        end
    end)
end