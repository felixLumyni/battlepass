if CBW_Battle and chaotix and chaotix.Heavy then --Only try to modify if we're certain Bomb is loaded

    local heavy = chaotix.Heavy
    local B = CBW_Battle

    local isheavy = function(player)
        return (player and player.mo and player.mo.valid and player.mo.skin == heavy.SKIN)
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

    --Write into Skinvars

    local loaded = false

    addHook("ThinkFrame", do
        --Main Player Hook
        for player in players.iterate
            if isheavy(player) then
                powSpawnDisable_Think(player)
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
        
        B.SkinVars[heavy.SKIN].func_collide = Titanium_Collide_new
        --SkinVar overwriting end
    end)

end