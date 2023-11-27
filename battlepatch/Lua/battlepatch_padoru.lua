local rage = function(mo,doaction)
	local player = mo.player
	player.actiontext = "Rage"
	player.actionrings = 10

	if (mo.padoru and mo.padoru.angery) then
		player.actiontext2 = "\130Rage"
		player.actionrings = 0
		return
	end
	if doaction then
		mo.temprage = TICRATE * 5
		CBW_Battle.PayRings(player, player.actionrings)
		CBW_Battle.ApplyCooldown(player, 10 * TICRATE)
	end
end

local padorupriority = function(player)
	if player.mo and player.mo.padoru and player.mo.padoru.angery then
		CBW_Battle.SetPriority(player,2,2,nil,2,2,"angery attack")
	end
end

local padorubattle = function(player)
	--battlemod padoru check
	if not (CBW_Battle
	and player.mo
	and player.mo.valid
	and player.mo.skin == "padoru")
	then
		return
	end

	if player.mo.temprage then
		player.mo.temprage = max(0, $-1)
		player.mo.padoru.angery = true
		if not player.mo.temprage then
			player.mo.padoru.angery = false
		end
	end
end
addHook("PlayerThink", padorubattle)

local padoruloaded = false
local padoruload = function()
	if CBW_Battle and skins["padoru"] and not padoruloaded then
		padoruloaded = true
		CBW_Battle.SkinVars["padoru"] = {
			weight = 50,
			special = rage,
			func_priority_ext = padorupriority
		}
	end
end
addHook("ThinkFrame", padoruload)