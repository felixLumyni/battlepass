if CBW_Battle and chaotix and chaotix.Heavy then --Only try to modify if we're certain Bomb is loaded

    local heavy = chaotix.Heavy
    local B = CBW_Battle

    local applyFlip = function(mo1, mo2)
        if mo1.eflags & MFE_VERTICALFLIP then
            mo2.eflags = $|MFE_VERTICALFLIP
        else
            mo2.eflags = $ & ~MFE_VERTICALFLIP
        end
        
        if mo1.flags2 & MF2_OBJECTFLIP then
            mo2.flags2 = $|MF2_OBJECTFLIP
        else
            mo2.flags2 = $ & ~MF2_OBJECTFLIP
        end
    end

    local height_divisor = 3

    local overlayZ = function(mo, overlaytype, flip)
        if flip --if we're flipped, our z position for the overlay should be close to middle of the player's sprite
            return (mo.z-FixedMul(mobjinfo[overlaytype].height, mo.scale+mo.scale/2)+(mo.height))+(mo.height/height_divisor) --but that's not very simple
            --(playerZPosition-(overlayHeight*1.5xPlayerScale)+PlayerHeight+(thirdOfPlayerHeight))
            --This shifts the original positioning downwards, so it aligns correctly with our player if we're gravflipped
        else --if we're not flipped, our z position for the overlay should be close to middle of the player's sprite
            return (mo.z)-(mo.height/height_divisor) --...and it's very simple
            --playerZPosition-thirdOfPlayerHeight
        end
    end
    

    local isheavy = function(player)
        return (player and player.mo and player.mo.valid and player.mo.skin == heavy.SKIN)
    end

    local heavy_enemysiren = freeslot("sfx_hvsie")
    local heavy_allysiren = freeslot("sfx_hvsit")
    local heavysiren_vol = 125
    
    sfxinfo[heavy_enemysiren].caption = "\x82".."TITANIUM STARTUP".."\x80"
    sfxinfo[heavy_allysiren].caption = "Titanium startup"

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

    local powSpawnDisable_Think = function(player)
        local st_pow = (player.mo.state == S_HEAVY_POW_START)
        if B.PreRoundWait() then
            if player.mo.heavyvars then
                player.mo.heavyvars.pow = nil
            end
            if st_pow then
                player.mo.state = S_PLAY_STND
            end         
        end
    end


    --Give titanium tumble stun break (Code from ChaotixChars, 5_Heavy/heavy_battle.lua)

    local Titanium_Collide_new = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
        if not (plr[n1] and plr[n1].heavymarker and atk[n1] <= def[n2])
            return false
        end
        if (hurt != 1 and n1 == 1) or (hurt != -1 and n1 == 2)
            if not (plr[n2] and plr[n2].heavymarker)
                --Anything special we want to do here?
            end
            if plr[n2]
                B.DoPlayerTumble(plr[n2], 35, angle[n1], mo[n1].scale*3, true, false) --Last arg changed from true to false
            end
            P_InstaThrust(mo[n2], angle[n2], mo[n1].scale * 5)
            B.ZLaunch(mo[n2], 7 * mo[n2].scale, false)
            return true
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

    local TITANIUM_STARTUP = TICRATE/2

    local state_titaniumstartup = 13 --lucky number


    local heavySirens_Think = function(player)
        if player.actionstate == state_titaniumstartup then
    
            if not(S_SoundPlaying(player.mo, heavy_enemysiren) or S_SoundPlaying(player.mo, heavy_allysiren)) then
                teamSound(player.mo, player, heavy_allysiren, heavy_enemysiren, heavysiren_vol, false)
            end


        else
            if S_SoundPlaying(player.mo, heavy_enemysiren) then
                S_StopSoundByID(player.mo, heavy_enemysiren)
            end

            if S_SoundPlaying(player.mo, heavy_allysiren) then
                S_StopSoundByID(player.mo, heavy_allysiren)
            end


        end
    end


    --Write into Skinvars

    local loaded = false

    addHook("ThinkFrame", do
        --Main Player Hook
        for player in players.iterate
            if isheavy(player) then
                powSpawnDisable_Think(player)
                heavySirens_Think(player)
            end
        end
        --Main Player Hook end


        --SkinVar Overwriting
        if loaded then --Only write once
            return
        end

        if not(rawget(B.SkinVars, heavy.SKIN)) then --Only write if ChaotixChars has already written
            return
        end 

        --Give titanium a startup state
        local titaniumSpecial = B.SkinVars[heavy.SKIN].special

        local titaniumWithStartup = function(mo, doaction)
            local player = mo.player

            if mo.heavypatch_titanium then
                player.canguard = false
                if player.actionstate == 0 then
                    titaniumSpecial(mo, 1)
                    mo.heavypatch_titanium = nil
                    --player.rings = $+15
                end
                return
            end

            if (player.rings < 15) then
                titaniumSpecial(mo, 0)
                return
            end

            if (player.actionstate ~= state_titaniumstartup) then
                titaniumSpecial(mo, 0)
            end
            if (doaction == 1) and (player.actionstate == 0) then
                player.actionstate = state_titaniumstartup
                player.actiontime = TITANIUM_STARTUP
                mo.heavypatch_ghost = P_SpawnMobjFromMobj(mo, 0,0,0, MT_MECHANIXFGHOST)
                mo.heavypatch_ghost.frame = 0
                mo.heavypatch_ghost.fuse = TITANIUM_STARTUP
                mo.heavypatch_ghost.scale = 2*mo.scale
                mo.heavypatch_ghost.destscale = mo.scale
                mo.heavypatch_ghost.scalespeed = FRACUNIT/TITANIUM_STARTUP
                --B.PayRings(player)
            end

            if (player.actionstate == state_titaniumstartup) then

                if mo.heavypatch_ghost and mo.heavypatch_ghost.valid then
                    mo.heavypatch_ghost.skin = mo.skin
                    mo.heavypatch_ghost.color = mo.color
                    mo.heavypatch_ghost.colorized = true
                    mo.heavypatch_ghost.renderflags = RF_FULLBRIGHT
                    mo.heavypatch_ghost.blendmode = AST_ADD
                    mo.heavypatch_ghost.sprite = mo.sprite
                    mo.heavypatch_ghost.sprite2 = mo.sprite2
                    mo.heavypatch_ghost.frame = mo.frame
                    mo.heavypatch_ghost.angle = player.drawangle
                    P_MoveOrigin(mo.heavypatch_ghost, mo.x, mo.y, ((mo.flags2 & MF2_OBJECTFLIP) and mo.z+mo.height) or mo.z)
                end
                    
                if (player.actiontime > 1) then
                    player.actiontime = $-1
                    player.action2text = "Startup "..G_TicsToSeconds(player.actiontime).."."..G_TicsToCentiseconds(player.actiontime)
                end

                player.actiontext = "Titanium"
                player.actionrings = 15
                player.actionsuper = true
                if mo.state >= S_HEAVY_POW_START and mo.state <= S_HEAVY_POW_END
                    player.canguard = false
                end
                
                
                if (player.actiontime == 1) then
                    mo.heavypatch_titanium = true
                    player.actionstate = 0
                    player.canguard = false
                end
            end
        end
        
        B.SkinVars[heavy.SKIN].func_collide = Titanium_Collide_new
        B.SkinVars[heavy.SKIN].special = titaniumWithStartup
        --SkinVar overwriting end
    end)

end