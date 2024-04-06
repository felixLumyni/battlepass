freeslot("sfx_howl", "sfx_dispel")

local totemobj = MT_BIGGARGOYLE

local shadowtotem = function(mo, doaction)
	local player = mo.player
	local duration = TICRATE*9
	local cooldown = TICRATE*10
	player.actiontext = "Shadow Totem"
	player.actionrings = 20

	if not P_IsObjectOnGround(mo) then
		cooldown = TICRATE * 3
		player.actiontext = player.darkascent and "\130" or ""
		player.actiontext = player.glidetime%2 and $+"Dark Descent" or $+"Dark Ascent"
		player.actionrings = player.darkascent and 0 or 8
		if player.darkascent then return end
	end

	if doaction == 1 and P_IsObjectOnGround(mo) then
		local totem = P_SpawnMobjFromMobj(mo,0,0,0,totemobj)
		if totem and totem.valid then
			CBW_Battle.PayRings(player, player.actionrings)
			CBW_Battle.ApplyCooldown(player, cooldown)
			totem.tics = duration
			totem.istotem = true
			totem.colorized = true
			totem.color = mo.color
			totem.angle = mo.angle
			totem.ctfteam = player.ctfteam
			totem.tracer = mo
			totem.flags = $ &~ MF_PUSHABLE
			totem.momz = totem.scale*12
			local s = totem.scale
			totem.scale = 1
			totem.destscale = s
			totem.scalespeed = FRACUNIT/8
			if AST_SUBTRACT then
				totem.blendmode = AST_SUBTRACT
			end
		else
			S_StartSound(mo, sfx_lose, player)
		end
	elseif doaction == 1 then
		CBW_Battle.PayRings(player, player.actionrings)
		CBW_Battle.ApplyCooldown(player, cooldown)
		player.darkascent = 1
	end
end

local willoloaded = false
local willoload = function()
	if CBW_Battle and skins["willo"] and not willoloaded then
		CBW_Battle.SkinVars["willo"] = {
		weight = 95,
		special = shadowtotem
	}
	end
end
addHook("ThinkFrame", willoload)

local willoparticles = function(mo)
	local radius = mo.radius*2/FRACUNIT
	for i = 1, 4 do
		local thok = P_SpawnMobjFromMobj(mo,
		radius*(P_RandomFixed()-(FRACUNIT/2)),
		radius*(P_RandomFixed()-(FRACUNIT/2)),
		(radius*(P_RandomFixed()-(FRACUNIT/2)))+(mo.height/2*P_MobjFlip(mo)),
		MT_THOK)
		thok.color = mo.color
		if AST_SUBTRACT then
			thok.blendmode = AST_SUBTRACT
		end
		thok.skin = "willo"
		thok.sprite = SPR_PLAY
		thok.sprite2 = SPR2_TALA
		thok.angle = mo.angle
		thok.destscale = thok.scale
		thok.scale = $/4
		thok.destscale = 1
		thok.scalespeed = thok.scale/8
		thok.tics = $-P_RandomKey(4)
		thok.fuse = 0
		thok.frame = 0
		thok.momx = mo.momx*2/3-mo.momx
		thok.momy = mo.momy*2/3-mo.momy
		thok.momz = mo.momz + mo.scale*4*P_MobjFlip(mo)
		thok.z = $ - mo.momz
		thok.z = $-mo.scale*4*P_MobjFlip(mo)
		P_XYMovement(thok)
		P_ZMovement(thok)
		P_SetScale(thok, thok.scale-thok.scalespeed)
		thok.momx = $+mo.momx
		thok.momy = $+mo.momy
	end
end

local shadowtotemthinker = function(mo)
	if not mo.istotem then return end

	if mo.tics % (3*TICRATE) == 0 then
		S_StartSound(nil, sfx_howl, mo.tracer.player)
		for p in players.iterate do
			if not ((p.mo and p.mo == mo.tracer) or (p.ctfteam and p.ctfteam == mo.ctfteam)) then
				S_StartSound(nil, sfx_howl, p)
				p.willoblind = TICRATE*3
			end
		end
	end

	willoparticles(mo)
end
addHook("MobjThinker", shadowtotemthinker, totemobj)

local totemdamage = function(target, inflictor, source)
	if not target.istotem then return end

	if not target and target.valid then
		return
	end
	if (source and source.ctfteam and source.ctfteam == target.ctfteam)
	or (target.tracer == source)
	then
		return false
	end
	if inflictor.player then
		if P_PlayerCanDamage(inflictor.player, target) or inflictor.player.battle_atk then
			inflictor.momx = $*-1
			inflictor.momz = $*-1
			inflictor.momy = $*-1
		else
			return
		end
	end
	P_RemoveMobj(target)
end
addHook("ShouldDamage", totemdamage, totemobj)

local totemcollide = function(mo1, mo2)
	if not mo1.istotem then return end

	if (mo2.ctfteam and mo1.ctfteam == mo2.ctfteam)
	or (mo2 == mo1.tracer)
	then
		return false
	elseif mo2.player or mo2.flags & MF_MISSILE then
		totemdamage(mo1, mo2, mo2)
	end
end
addHook("MobjCollide", totemcollide, totemobj)
addHook("MobjMoveCollide", totemcollide, totemobj)

local totemremoved = function(mo)
	if not mo.istotem then return end
	mo.istotem = false

	local circle = P_SpawnMobjFromMobj(mo, 0, 0, mo.scale * 24, MT_THOK)
	circle.sprite = SPR_STAB
	circle.frame =  TR_TRANS50|_G["A"]
	circle.angle = mo.angle + ANGLE_90
	circle.fuse = 7
	circle.scale = mo.scale / 3
	circle.destscale = 10*mo.scale
	circle.colorized = true
	circle.color = mo.color
	S_StartSound(nil, sfx_dispel)
end
addHook("MobjRemoved", totemremoved, totemobj)

local willobattle = function(player)
	player.willoblindintensity = $ or 0
	if player.willoblind then
		player.willoblind = $-1
		player.willoblindintensity = min(36,$+1)
	else
		if leveltime % 2 == 0 then player.willoblindintensity = max(0,$-1) end
	end
	--willo on battlemod check
	if not (CBW_Battle and player.mo and player.mo.skin == "willo")
	then
		player.darkascent = nil
		return
	end
	--main ability stuff (lower vertical thrust if not using dark ascent)
	if player.mo.eflags & MFE_SPRUNG then
		player.willowasindash = false
	end
	local tolerance = player.mo.scale*4	
	if player.mo.momz > tolerance then
		if player.willodashtime then
			player.mo.momz = player.darkascent and $ or $/2
			if player.darkascent and player.darkascent > 0 then
				S_StartSound(player.mo, sfx_s22e)
				S_StartSoundAtVolume(player.mo, sfx_s3k82, 180)
			end
			player.darkascent = $ and -1 or $
		elseif player.willowasindash then
			player.mo.momz = player.darkascent and $ or $*2/3
		end
	end
	if player.darkascent and player.darkascent > 0 then
		willoparticles(player.mo)
		if P_IsObjectOnGround(player.mo) and (player.willodashtime or player.willowasindash) then
			player.darkascent = 0
			--ring of fire
			if player.willowasindash then
				S_StartSound(player.mo, sfx_s22e)
				S_StartSoundAtVolume(player.mo, sfx_s3k82, 180)
				local m = 20
				for n = 0, m do
					local fire = P_SPMAngle(player.mo,MT_SPINFIRE,0,0)
					if fire and fire.valid then
						fire.flags = $ & ~MF_NOGRAVITY
						CBW_Battle.InstaThrustZAim(fire,(360/m)*n*ANG1,ANGLE_45*P_MobjFlip(player.mo),player.mo.scale * 7)
						fire.fuse = 4 * TICRATE
						fire.target = player.mo
						fire.colorized = true
						fire.color = player.mo.color
						if AST_SUBTRACT then
							fire.blendmode = AST_SUBTRACT
						end
					end
				end
			end
		end
	elseif player.darkascent and player.darkascent < 0 and P_IsObjectOnGround(player.mo) then
		player.darkascent = 0
	end
end
addHook("PlayerThink", willobattle)

local darkness = function(v, player, cam)
	local patch = v.cachePatch("VIGNETT")
	local flags = V_SNAPTOLEFT|V_SNAPTOTOP
	local colormap = v.getColormap(TC_DEFAULT, SKINCOLOR_BLACK)
	local opacity = 0
	if player.willoblind or player.willoblindintensity then
		if player.willoblindintensity then
			--i am so hecking lazy i know
			if player.willoblindintensity < 35 then opacity = V_10TRANS end
			if player.willoblindintensity < 32 then opacity = V_20TRANS end
			if player.willoblindintensity < 28 then opacity = V_30TRANS end
			if player.willoblindintensity < 24 then opacity = V_40TRANS end
			if player.willoblindintensity < 20 then opacity = V_50TRANS end
			if player.willoblindintensity < 16 then opacity = V_60TRANS end
			if player.willoblindintensity < 12 then opacity = V_70TRANS end
			if player.willoblindintensity < 8 then opacity = V_80TRANS end
			if player.willoblindintensity < 4 then opacity = V_90TRANS end
		end
		if (v.height() == 1200) or (v.height() == 800) or (v.height() == 400) or (v.height() == 200) then
			v.drawScaled(0, -40*FRACUNIT, 65355, patch, flags|opacity, colormap)
		elseif (v.height() == 1080) then
			v.drawScaled(0, -40*FRACUNIT, 82033, patch, flags|opacity, colormap)
		else --720?
			v.drawScaled(0, -40*FRACUNIT, 98032, patch, flags|opacity, colormap)
		end
	end
end
hud.add(darkness, "game")