if not trip then return end

local B = CBW_Battle

local SKIN = "trip"

local isTrip = function(player)
    return (player and player.mo and player.mo.valid and player.mo.skin == tostring(SKIN))
end


--Fix Fireball Charge in Automatic Playstyle
local B_InputControl_old = B.InputControl

B.InputControl = function(player)
    B_InputControl_old(player)
    if not(isTrip(player)) then
        return
    end

    local automatic = (player.pflags & (PF_DIRECTIONCHAR|PF_ANALOGMODE))

    if not(automatic) then
        return
    end

    if not(player.actionstate) then
        return
    end


    if not(P_IsObjectOnGround(player.mo)) then
        return
    end

    player.cmd.forwardmove = player.realforwardmove
    player.cmd.sidemove = player.realsidemove 
    player.drawangle = player.thinkmoveangle
    --Unlock controls no matter what, just for this
end
