
--Mari0shi here!

if CBW_Battle and chaotix and chaotix.bomb then --Only try to modify if we're certain Bomb is loaded
    
    local bomb = chaotix.bomb
    local B = CBW_Battle

    bomb.VolatileDamageTics = TICRATE/3 --This constant determines the lingering time of Bomb's explosions | Originally TICRATE*2/3
    bomb.ExplodeRange = FRACUNIT*115 --This constant determines the range of Bomb's explosions | Originally FRACUNIT*128

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


    local isbomb = function(player)
        return (player and player.mo and player.mo.valid and player.mo.skin == bomb.SKIN)
    end


    local bomb_constantfdjblock = CV_RegisterVar({
        name = "bomb_fdjblock",
        defaultvalue = "On",
        value = 1,
        flags = CV_NETVAR|CV_CALL,
        PossibleValue = CV_OnOff,
        func = function(cv)
            if cv.value
                print("Bomb will now be unable to jump with Fuse Dash.")
            else
                print("Bomb will now only be able to jump with Fuse Dash when he's not flagholding.")
            end
        end
    })

    local fuseDashJumpless_PostThink = function(player)
        local flagholding = (player.gotflagdebuff)
        local startjump = (player.pflags & PF_STARTJUMP)
        local thokked = (player.pflags & PF_THOKKED)
        local justairdodged = (player.airdodge == -1)
        local spinning = (player.pflags & PF_SPINNING)
        local st_jump = (player.mo.state == S_PLAY_JUMP)
        local st_fall = (player.mo.state == S_PLAY_FALL)
        local st_topspin = ((player.mo.state == S_BOMB_TOPSPIN) or (player.mo.state == S_BOMB_TOPSPIN_FAST))
        local st_fuseshot = (player.mo.bomb_thokked & bomb.ThokkedFlags["FUSESHOT"])
        local st_fusedash = (player.mo.bomb_thokked & bomb.ThokkedFlags["FUSEDASH"])
        local fdjblock = (bomb_constantfdjblock.value == 1)

        if spinning and st_fusedash then
            player.mo.bombpatch_fusedashjump = true
        elseif not(st_topspin) then
            player.mo.bombpatch_fusedashjump = false
        end

        local fusedashjump = player.mo.bombpatch_fusedashjump


        if startjump and (flagholding or fdjblock) then
            if not(st_fuseshot) then
                player.mo.bomb_fusedash = false
            end
            player.pflags = $ & ~PF_SPINNING
            S_StopSoundByID(player.mo, sfx_sc0a5h)
            if not(thokked or justairdodged or st_fuseshot or st_fusedash) then
                if not(st_jump or st_fall or st_fusedash or fusedashjump) then
                    player.mo.state = S_PLAY_JUMP
                end
            end
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
    local SetTopSpinState_old = bomb.SetTopSpinState

    bomb.SetTopSpinState = function(player)
        if not(isbomb(player)) then
            return
        end
        SetTopSpinState_old(player) --Execute normally
    end


    local stillSpinDash_PreThink = function(player)
        local flagholding = (player.gotflagdebuff)
        local canfusedash = (CanSpindash(player) or player.skidtime or (player.pflags & PF_STARTDASH))

        if canfusedash and player.mo.bombpatch_spin and not(player.cmd.buttons & BT_SPIN) then
            player.mo.bombpatch_spin = nil
        end

        if (not(canfusedash) and flagholding) or player.mo.bombpatch_spin then
            if (player.cmd.buttons & BT_SPIN) and not(player.mo.bombpatch_spin) then
                player.mo.bombpatch_spin = true
            end
            player.cmd.buttons = $ & ~(BT_SPIN)
        end
    end

    local fuseDashJumpless_PreThink = function(player)
        local flagholding = (player.gotflagdebuff)
        local fdjblock = (bomb_constantfdjblock.value == 1)
        if flagholding or fdjblock then
            if player.mo.bomb_fusedash then
                player.cmd.buttons = $ & ~(BT_JUMP)
            end
        end
    end

    local cupcakeSpawnDisable_Think = function(player)
        local st_cupcake = (player.mo.state == S_BOMB_CUPCAKE)
        if B.PreRoundWait() then
            player.bomb_cupcake = nil
            if st_cupcake then
                player.mo.state = S_PLAY_STND
            end         
        end
    end


    addHook("PostThinkFrame", do
        for player in players.iterate
            if isbomb(player) then
                fuseDashJumpless_PostThink(player)
            end
        end
    end)

    addHook("ThinkFrame", do
        for player in players.iterate
            if isbomb(player) then
                volatilePause_Think(player)
                cupcakeSpawnDisable_Think(player)
            end
        end
    end)

    addHook("PreThinkFrame", do
        for player in players.iterate
            if isbomb(player) then
                stillSpinDash_PreThink(player)
                fuseDashJumpless_PreThink(player)
            end
        end
    end)
end