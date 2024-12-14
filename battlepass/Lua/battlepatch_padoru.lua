local FR_DURATION = 5 * TICRATE
local FR_STRONGAFTER = 1 * TICRATE
local FR_COOLDOWN = FR_DURATION * 2

local rage = function(mo,doaction)
	local player = mo.player
	player.actiontext = "Festive Rage"
	player.actionrings = 10

	if (mo.padoru and mo.padoru.angery) then
		player.actiontext = "\130"+$
		player.actionrings = 0
		return
	end
	if doaction == 1 and CBW_Battle.CanDoAction(player) and not player.intangible then
		mo.temprage = FR_DURATION
		CBW_Battle.PayRings(player, player.actionrings)
		CBW_Battle.ApplyCooldown(player, FR_COOLDOWN)
	end
end

local padorupriority = function(player)
	local mo = player.mo
	if (mo and mo.padoru) then
		local padoruing = (mo.state == S_PLAY_PADORU)
		if (player.speed > 55*mo.scale) then --speed check used by the original padoru wad
			padoruing = true
		end
		local angering = 0
		if mo.temprage and mo.temprage > FR_DURATION-FR_STRONGAFTER then
			angering = 1
		elseif mo.padoru.angery then
			angering = 2
		end
		if angering then
			CBW_Battle.SetPriority(player,angering,angering,nil,nil,nil,"angery attack")
		elseif padoruing then
			CBW_Battle.SetPriority(player,2,1,nil,nil,nil,"speed dash attack")
		end
	end
end

local minaurusaid = false
local padorubattle = function(player)
	--for your sanity
	if skins["padoru"] and player.padoru_urusai == nil and not player.battlepatch_padorued then
		--player.padoru_stophop = true
		player.padoru_urusai = true
		player.battlepatch_padorued = true
	end

	local mo = player.mo
	if mo and mo.temprage then
		mo.temprage = max(0, $-1)
		--vfx
		if mo.temprage < FR_DURATION-FR_STRONGAFTER and not(mo.padorughost and mo.padorughost.valid) then
			mo.padorughost = P_SpawnGhostMobj(player.mo)
			mo.padorughost.colorized = true
			mo.padorughost.fuse = -1
			mo.padorughost.scale = $*10/9
			mo.padorughost.target = player.mo
			mo.padorughost.dispoffset = -1
			mo.padorughost.padorughost = true
		end
		--disable if dmgd or tumbld
		if P_PlayerInPain(player) or player.tumble or player.gotflagdebuff then
			mo.temprage = 0
		end
		--physics. sprites are handled by padoru.wad
		mo.padoru.angery = true
		player.actionstate = true
		player.normalspeed = skins["padoru"].normalspeed*3/4
		--ran out of temprage, disable everything
		if not mo.temprage then
			mo.padoru.angery = false
			player.actionstate = false
			if mo.padorughost and mo.padorughost.valid then
				P_RemoveMobj(mo.padorughost)
			end
			player.normalspeed = skins["padoru"].normalspeed
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
	if skins["padoru"] and CBW_Battle and not padoruloaded then
		padoruloaded = true
		CBW_Battle.SkinVars["padoru"] = {
			weight = 50,
			special = rage,
			func_priority_ext = padorupriority
		}
	end
end
addHook("ThinkFrame", padoruload)

local padorunoises = CV_RegisterVar({
	name = "padoru_noises",
	defaultvalue = "Off",
	PossibleValue = CV_OnOff
})

local noises = {
	-- { "sfx_padieu", sfx_thok }, -- not being detected. whatever.
	-- { "sfx_pahurt", sfx_thok }, -- not being detected. whatever.
	{ "sfx_padumu", sfx_s3k62 },
	{ "sfx_padomo", 0 }
}

local filterpadorunoises = function()
	if not skins["padoru"] then return end
	
	for p in players.iterate do
		local mo = p.mo
		if not (mo and mo.valid and mo.padoru) then continue end

		if S_SoundPlaying(mo, sfx_padoru) and (consoleplayer.padoru_urusai) then
			S_StopSoundByID(mo, sfx_padoru)
		end

		if CV_FindVar("padoru_noises").value then return end
		 
		for _, noise in ipairs(noises) do
			if noise and S_SoundPlaying(mo, _G[noise[1]]) then
				S_StopSoundByID(mo, _G[noise[1]])
				if noise[2] != 0 then
					S_StartSound(mo, noise[2])
				end
			end
		end
	end
end
addHook("PostThinkFrame", filterpadorunoises)