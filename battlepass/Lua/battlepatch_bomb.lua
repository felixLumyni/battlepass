
--Mari0shi here!

if CBW_Battle and chaotix and chaotix.bomb then --Only try to modify if we're certain Bomb is loaded
    
    local bomb = chaotix.bomb
    local B = CBW_Battle

    local bomb_enemysiren = freeslot("sfx_bmsie")
    local bomb_allysiren = freeslot("sfx_bmsit")
    local bombsiren_vol = 125

    local bomb_startupenemysiren = freeslot("sfx_bmste")
    local bomb_startupallysiren = freeslot("sfx_bmstt")
    local bombstartupsiren_vol = 125
    
    sfxinfo[bomb_startupenemysiren].caption = "\x82".."VOLATILE STARTUP".."\x80"
    sfxinfo[bomb_startupallysiren].caption = "Volatile startup"
    
    sfxinfo[bomb_enemysiren].caption = "\x82".."VOLATILE BOMB".."\x80"
    sfxinfo[bomb_allysiren].caption = "/"

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

    
    local teamSound = B.teamSound or function(source, player, soundteam, soundenemy, vol, selfisenemy)
        for otherplayer in players.iterate do
            if player and otherplayer and B.MyTeam(player, otherplayer)
                and not (selfisenemy and source and source.player and source.player == player)
            then
                S_StartSoundAtVolume(source, soundteam, vol, otherplayer)
            else
                S_StartSoundAtVolume(source, soundenemy, vol, otherplayer)
            end
        end
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
                print("Bomb will now only be able to jump with Fuse Dash when he's ".."\x82".."not".."\x80".." flagholding.")
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

    local bombSirens_Think = function(player)
        if player.mo.bomb_volatile then

            if not(S_SoundPlaying(player.mo, bomb_enemysiren) or S_SoundPlaying(player.mo, bomb_allysiren)) then
                teamSound(player.mo, player, bomb_allysiren, bomb_enemysiren, bombsiren_vol, false)
            end


        else
            if S_SoundPlaying(player.mo, bomb_enemysiren) then
                S_StopSoundByID(player.mo, bomb_enemysiren)
            end

            if S_SoundPlaying(player.mo, bomb_allysiren) then
                S_StopSoundByID(player.mo, bomb_allysiren)
            end


        end
    end

    if not(rawget(_G, "MT_MECHANIXFGHOST")) then
        mobjinfo[freeslot("MT_MECHANIXFGHOST")] = {
            doomednum = -1,
            spawnstate = S_INVISIBLE,
            radius = FRACUNIT,
            height = FRACUNIT,
            dispoffset = mobjinfo[MT_PLAYER].dispoffset-1, --Behind player
            flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY --Intangible
        }
    end

    local VOLATILE_STARTUP = TICRATE/2

    local state_volatilestartup = 13 --lucky number

    local bombStartupSirens_Think = function(player)
        if player.actionstate == state_volatilestartup then
    
            if not(S_SoundPlaying(player.mo, bomb_startupenemysiren) or S_SoundPlaying(player.mo, bomb_startupallysiren)) then
                teamSound(player.mo, player, bomb_startupallysiren, bomb_startupenemysiren, bombstartupsiren_vol, false)
            end


        else
            if S_SoundPlaying(player.mo, bomb_startupenemysiren) then
                S_StopSoundByID(player.mo, bomb_startupenemysiren)
            end

            if S_SoundPlaying(player.mo, bomb_startupallysiren) then
                S_StopSoundByID(player.mo, bomb_startupallysiren)
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

    local loaded = false

    addHook("ThinkFrame", do
        for player in players.iterate
            if isbomb(player) then
                volatilePause_Think(player)
                cupcakeSpawnDisable_Think(player)
                bombSirens_Think(player)
                bombStartupSirens_Think(player)
            end
        end

         --Main Player Hook end


        --SkinVar Overwriting
        if loaded then --Only write once
            return
        end

        if not(rawget(B.SkinVars, bomb.SKIN)) then --Only write if ChaotixChars has already written
            return
        end 

        --Give volatile a startup state
        local volatileSpecial = B.SkinVars[bomb.SKIN].special

        local volatileWithStartup = function(mo, doaction)
            local player = mo.player

            if player.tumble or P_PlayerInPain(player) then
                if mo.bombpatch_ghost and mo.bombpatch_ghost.valid then
                    P_RemoveMobj(mo.bombpatch_ghost)
                    mo.bombpatch_ghost = nil
                end
                player.actionstate = 0
                mo.bombpatch_titanium = nil
                B.ApplyCooldown(player, bomb.MeltdownCooldown)
            end

            if mo.bombpatch_volatile then
                player.canguard = false
                if player.actionstate == 0 then
                    volatileSpecial(mo, 1)
                    mo.bombpatch_volatile = nil
                    --player.rings = $+15
                end
                return
            end

            if (player.rings < bomb.MeltdownCost) then
                volatileSpecial(mo, 0)
                return
            end

            if (player.actionstate ~= state_volatilestartup) then
                volatileSpecial(mo, 0)
            end
            if (doaction == 1) and (player.actionstate == 0) then
                player.actionstate = state_volatilestartup
                player.actiontime = VOLATILE_STARTUP
                mo.bombpatch_ghost = P_SpawnMobjFromMobj(mo, 0,0,0, MT_MECHANIXFGHOST)
                mo.bombpatch_ghost.frame = 0
                mo.bombpatch_ghost.fuse = VOLATILE_STARTUP
                mo.bombpatch_ghost.scale = 2*mo.scale
                mo.bombpatch_ghost.destscale = mo.scale
                mo.bombpatch_ghost.scalespeed = FRACUNIT/VOLATILE_STARTUP
                --B.PayRings(player)
            end

            if (player.actionstate == state_volatilestartup) then

                if mo.bombpatch_ghost and mo.bombpatch_ghost.valid then
                    mo.bombpatch_ghost.skin = mo.skin
                    mo.bombpatch_ghost.color = mo.color
                    mo.bombpatch_ghost.colorized = true
                    mo.bombpatch_ghost.renderflags = RF_FULLBRIGHT
                    mo.bombpatch_ghost.blendmode = AST_ADD
                    mo.bombpatch_ghost.sprite = mo.sprite
                    mo.bombpatch_ghost.sprite2 = mo.sprite2
                    mo.bombpatch_ghost.frame = mo.frame
                    mo.bombpatch_ghost.angle = player.drawangle
                    mo.bombpatch_ghost.spritexscale = mo.spritexscale
                    mo.bombpatch_ghost.spriteyscale = mo.spriteyscale
                    mo.bombpatch_ghost.spritexoffset = mo.spritexoffset
                    mo.bombpatch_ghost.spriteyoffset = mo.spriteyoffset
                    P_MoveOrigin(mo.bombpatch_ghost, mo.x, mo.y, ((mo.flags2 & MF2_OBJECTFLIP) and mo.z+mo.height) or mo.z)
                end
                    
                if (player.actiontime > 1) then
                    player.actiontime = $-1
                    player.action2text = "Startup "..G_TicsToSeconds(player.actiontime).."."..G_TicsToCentiseconds(player.actiontime)
                end

                player.actiontext = "Volatile"
                player.actionrings = bomb.MeltdownCost
                player.actionsuper = true
                if player.bomb_cupcake
			        player.canguard = false
		        end
                
                
                if (player.actiontime == 1) then
                    mo.bombpatch_volatile = true
                    player.actionstate = 0
                    player.canguard = false
                end
            end
        end
        
        B.SkinVars[bomb.SKIN].func_collide = Volatile_Collide_new
        B.SkinVars[bomb.SKIN].special = volatileWithStartup
        --SkinVar overwriting end
        loaded = true
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