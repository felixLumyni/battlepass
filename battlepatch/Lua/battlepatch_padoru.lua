local rage = function(mo,doaction)
	local player = mo.player
	player.actiontext = "Rage"
	player.actionrings = 10

	if (mo.padoru and mo.padoru.angery) then
		player.actiontext2 = "\130Rage"
		player.actionrings = 0
		return
	end
	if doaction == 1 then
		mo.temprage = TICRATE * 5
		CBW_Battle.PayRings(player, player.actionrings)
		CBW_Battle.ApplyCooldown(player, 10 * TICRATE)
	end
end

local padorupriority = function(player)
	if player.mo and player.mo.padoru then
		local padoruing = 0
		if player.speed > 55*player.mo.scale then --speed check used by the original padoru wad
			padoruing = $ + 1
		end
		if player.mo.padoru.angery then
			CBW_Battle.SetPriority(player,2+padoruing,2,nil,2,2,"angery attack")
		elseif player.mo.state == S_PLAY_PADORU or padoruing then
			CBW_Battle.SetPriority(player,2,1,nil,2,1,"padoru attack")
		end
	end
end

local padorubattle = function(player)
	--for your sanity
	if skins["padoru"] and player.padoru_urusai == nil and not player.battlepatch_padorued then
		COM_BufInsertText(player, "padoru_stophop 1")
		COM_BufInsertText(player, "padoru_urusai 1")
		player.battlepatch_padorued = true
	end

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