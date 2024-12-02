local B = CBW_Battle

if (B.VersionNumber < 10) and not(V9_INPUTPATCH) then --This is already a thing in v10

    B.GetInputAngle = function(player)
        local mo = player.mo
        if not mo
            mo = player.truemo
        end
        
        if mo and mo.valid
            if (mo.flags2&MF2_TWOD or twodlevel)
                return mo.angle
            end
            local fw = player.realforwardmove
            local sw = player.realsidemove
            -- 	local pang = player.cmd.angleturn << 16//is this netsafe?
            local analog = player.pflags&PF_ANALOGMODE
    
            local pang = mo.angle
    
            if fw == 0 and sw == 0 then
                return pang
            end
    
            if analog
                pang = player.realangleturn<<FRACBITS
            end
    
            local c0, s0 = cos(pang), sin(pang)
    
    
            local rx, ry = fw*c0 + sw*s0, fw*s0 - sw*c0
            local retangle = R_PointToAngle2(0, 0, rx, ry)
            return retangle
        end
    end
    
    local B_InputControl_old = B.InputControl

    B.InputControl = function(player) --Record inputs eaten by Stasis
        player.realbuttons = player.cmd.buttons
        player.realsidemove = player.cmd.sidemove
        player.realforwardmove = player.cmd.forwardmove
        player.realangleturn = player.cmd.angleturn
        B_InputControl_old(player)
    end
    
    rawset(_G, "V9_INPUTPATCH", true)

end
