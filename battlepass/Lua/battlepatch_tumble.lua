
if CBW_Battle and (CBW_Battle.VersionNumber < 10) then

    local B = CBW_Battle
    
    local DoPlayerTumble_old = B.DoPlayerTumble

    CBW_Battle.DoPlayerTumble = function(player, time, angle, thrust, force, nostunbreak)
        player.dashmode = 0
        player.powers[pw_strong] = 0
        DoPlayerTumble_old(player, time, angle, thrust, force, nostunbreak)
    end

end