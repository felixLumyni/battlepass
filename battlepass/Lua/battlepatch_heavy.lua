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

    addHook("ThinkFrame", do
        for player in players.iterate
            if isheavy(player) then
                powSpawnDisable_Think(player)
            end
        end
    end)

end