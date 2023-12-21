local rage = function(mo,doaction)
	local player = mo.player
	player.actiontext = "Rage"
	player.actionrings = 10

	if (mo.padoru and mo.padoru.angery) then
		player.actiontext = "\130"+$
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
			CBW_Battle.SetPriority(player,2+padoruing,2,nil,nil,nil,"angery attack")
		elseif player.mo.state == S_PLAY_PADORU or padoruing then
			CBW_Battle.SetPriority(player,2,1,nil,nil,nil,"speed dash attack")
		end
	end
end

local minaurusaid = false
local padorubattle = function(player)
	--for your sanity
	if skins["padoru"] and player.padoru_urusai == nil and not player.battlepatch_padorued then
		player.padoru_stophop = true
		player.padoru_urusai = true
		player.battlepatch_padorued = true
	end

	--battlemod padoru check
	if not (CBW_Battle
	and player.mo
	and player.mo.valid
	and player.mo.skin == "padoru")
	then
		return
	elseif server and not minaurusaid then
		--i hate local vars, so we gotta do this workaround
		COM_BufInsertText(player, "padoru_mina_urusai 1")
		minaurusaid = true
	end

	if player.mo.temprage then
		player.mo.temprage = max(0, $-1)
		--vfx
		if not(player.mo.padorughost and player.mo.padorughost.valid) then
			player.mo.padorughost = P_SpawnGhostMobj(player.mo) --i like your cut
			player.mo.padorughost.colorized = true
			player.mo.padorughost.blendmode = AST_COPY
			player.mo.padorughost.fuse = -1
			player.mo.padorughost.scale = $*10/9
			player.mo.padorughost.target = player.mo
			player.mo.padorughost.dispoffset = -1
			player.mo.padorughost.padorughost = true
		end
		--disable if dmgd or tumbld
		if P_PlayerInPain(player) or player.tumble or player.gotflagdebuff then
			player.mo.temprage = 0
		end
		--sprites are handled by padoru.wad
		player.mo.padoru.angery = true
		player.actionstate = true
		--ran out of temprage, disable everything
		if not player.mo.temprage then
			player.mo.padoru.angery = false
			player.actionstate = false
			if player.mo.padorughost and player.mo.padorughost.valid then
				P_RemoveMobj(player.mo.padorughost)
			end
		end
	end
end
addHook("PlayerThink", padorubattle)

local ghostchase = function(mo)
	if (mo.padorughost and mo and mo.valid and mo.target) then
		A_CapeChase(mo, 0, 0)
		mo.state = mo.target.state
		mo.frame = mo.target.frame
	end
end
addHook("MobjThinker", ghostchase, MT_GHOST)

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