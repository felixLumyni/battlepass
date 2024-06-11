local function inputangle(player) 
	if (twodlevel or player.mo.flags2 & MF2_TWOD) then
		return player.mo.angle
	else
		return (player.cmd.angleturn<<16 + R_PointToAngle2(0, 0, player.cmd.forwardmove*FRACUNIT, -player.cmd.sidemove*FRACUNIT))
	end
end	
local dojanadash = function(p)
	p.jana.dashing = 14
	p.jana.killspin = true
	if not P_IsObjectOnGround(p.mo) then
		if p.mo.momz*P_MobjFlip(p.mo) < 0 then
			p.mo.momz = 0
		end
		p.mo.state = S_PLAY_DASH
	end
	if p.normalspeed > skins[p.mo.skin].normalspeed+skins[p.mo.skin].normalspeed/2 then
		P_InstaThrust(p.mo, inputangle(p), FixedMul(p.normalspeed, p.mo.scale))
	else
		P_InstaThrust(p.mo, inputangle(p), FixedMul(skins[p.mo.skin].normalspeed + skins[p.mo.skin].normalspeed/2, p.mo.scale))
	end
	S_StartSound(p.mo, sfx_jadash)
	p.pflags = $ | PF_SPINNING --hacky solution to dumb friction bs
	p.drawangle = inputangle(p)
	p.jana.controllock = 0
	--p.pflags = $ & ~ PF_JUMPSTASIS
end

local dashanddive = function(mo,doaction)
	local player = mo.player
	player.actiontext = "Dash"
	player.actionrings = 5

	if player.jana and player.jana.dashing then
		player.actionrings = 0
		player.actiontext = "\130Dash"
		return
	end
	if player.jana.diving or P_IsObjectInGoop(mo) then
		player.actionrings = 0
		player.actiontext = "\130Dive"
		return
	end
	
	if P_IsObjectOnGround(mo) then
		if doaction == 1 then
			CBW_Battle.PayRings(player)
			CBW_Battle.ApplyCooldown(player,2*TICRATE)
			dojanadash(player)
		end
	else
		player.actiontext = "Dive"
		player.actionrings = 10
		if doaction == 1 then
			CBW_Battle.PayRings(player)
			CBW_Battle.ApplyCooldown(player,3*TICRATE)
			player.divebuffer = 2
		end
	end
end

local janabattle = function(player)
	--battlemod jana check
	if not (CBW_Battle
	and player.mo
	and player.mo.valid
	and player.mo.skin == "jana")
	then
		return
	end
	
	local jes = player.janaEnergySaber
	if (player.guard) or
	(player.airdodge > 1 and player.airdodge < TICRATE*2/5) then
		if jes and jes.chargeTime >= 3*TICRATE/2 and P_IsObjectOnGround(player.mo) then
		elseif jes and jes.chargeTime then
		player.mo.state = S_PLAY_FALL
		jes.chargeTime = 0
		end
	end
	
	--prevent triggering dash through the usual means
	player.janatapdash = 2
	player.jana.c1down = true
	--same thing but for the dive
	if P_IsObjectOnGround(player.mo)
	or player.divebuffer
	then
		player.jana.walltouch = max($,0)
	elseif player.mo.state == S_PLAY_JANA_MONKEFLIP 
	and not player.jana.diving
	then
		player.jana.walltouch = -1
	end
	if player.jana.doublejumped
	and not (player.divebuffer)
	then
		player.jana.diving = false
		S_StopSoundByID(player.mo, sfx_rekjmp)
	elseif player.divebuffer then
		--player.pflags = $&~PF_JUMPDOWN
		--player.cmd.buttons = BT_JUMP
		player.jana.diving = true
		player.jana.divemomz = 6*FRACUNIT
		player.divebuffer = $-1
	end
	--no conflicting with battlemod's ledgegrab
	player.ledgegrabcooldown = 2
end
addHook("PlayerThink",janabattle)

local janawallexhaust = function()
	for player in players.iterate do
		if not (player.jana and player.mo and player.mo.skin == "jana") then
			continue
		end
		if player.jana.dashing != 0 then
			player.actioncooldown = max(TICRATE,$)
		end
		--walljump exhaust
		if player.jana.walltouch and player.jana.walltouch > 0 then
			player.exhaustmeter = max(1,$-(FRACUNIT/128))
			player.jana.walltouched = true
		elseif player.jana.walltouched then
			player.exhaustmeter = max(1,$-(FRACUNIT/4))
			player.jana.walltouched = false
		end
		--fully exhausted
		if (player.exhaustmeter<=1 or (player.gotflagdebuff and player.jana.walltouch)) then
			if player.deadtimer > 0 then // prevent not respawning soft lock
			return end
			--sound cue
			if (player.cmd.buttons & BT_JUMP)
			and not (player.buttonhistory & BT_JUMP)
			then
				S_StartSound(player.mo, sfx_s3k94)
			end
			--disable jump
			player.cmd.buttons = $&~BT_JUMP
			player.jana.jumpdown = false
			// player.actioncooldown = min(TICRATE,$+1)
		end
	end
end
addHook("PreThinkFrame",janawallexhaust)

local janapriority = function(player)
 local mo = player.mo
 local jes = player.janaEnergySaber
	if player.jana and player.jana.diving then
		CBW_Battle.SetPriority(player,1,1,"stomp",2,2,"dive attack")
	end
	if mo.state == S_JANA_DASHATTACK then
		CBW_Battle.SetPriority(player,1,1,"knuckles_glide",1,2,"dash slash")
	end
	if mo.state == S_JANA_COMBOATTACK1 or mo.state == S_JANA_COMBOATTACK2 then
		CBW_Battle.SetPriority(player,0,0,"knuckles_glide",0,0,"quick slash")
	end
	if mo.state == S_JANA_AIRATTACK or mo.state == S_JANA_COMBOATTACK3 then
		CBW_Battle.SetPriority(player,0,0,"knuckles_glide",1,0,"heavy slash")
	end
end

local janacollide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if (plr[n1] and plr[n1].jana and plr[n1].jana.diving)
		plr[n1].jana.diving = false
		plr[n1].pflags = $ &~ PF_THOKKED
		S_StopSoundByID(mo[n1], sfx_rekjmp)
		P_SetObjectMomZ(mo[n1], -21 * mo[n1].scale, false)
	end
end

local janaloaded = false
local janaload = function()
	if CBW_Battle and skins["jana"] and not janaloaded then
		janaloaded = true
		CBW_Battle.SkinVars["jana"] = {
			weight = 110,
			special = dashanddive,
			func_priority_ext = janapriority,
			func_collide = janacollide,
			guard_frame = 1
		}
		mobjinfo[MT_JANA_SMALLSABERBEAM].name = "saber beam"
		mobjinfo[MT_JANA_SABERHITBOX].name = "saber"
		mobjinfo[MT_JANA_LARGESABERBEAM_HITBOX].name = "large saber beam"
		mobjinfo[MT_JANA_LASER].name = "rekkohua"
		mobjinfo[MT_JANA_LASER_FIRE].name = "rekkohua"
	end
end
addHook("ThinkFrame", janaload)

addHook("MobjSpawn",function(mo)
	mo.hit_sound = sfx_hit02
	mo.blockable = 1
	mo.block_stun = 2 //4
	mo.block_hthrust = 3
	mo.block_vthrust = 2
end, MT_JANA_SMALLSABERBEAM)

addHook("MobjSpawn",function(mo)
	mo.hit_sound = sfx_hit02
	mo.blockable = 1 //2
	mo.block_stun = 25 //35
	mo.block_hthrust = 12
	mo.block_vthrust = 3
end, MT_JANA_LARGESABERBEAM_HITBOX)

addHook("MobjThinker",function(mo) // fail safe to prevent her from keeping a charge after just using one
	if not(mo.valid) then
		return
	end
	if not mo.setonce and mo.target and mo.target.valid then
		local jes = mo.target.player.janaEnergySaber
		jes.chargeTime = 0
		mo.setonce = true
	end
end, MT_JANA_LARGESABERBEAM_HITBOX)

addHook("MobjSpawn",function(mo)
	mo.flags = $|MF_SOLID // we need this if we want her to cut up weak projectiles
end, MT_JANA_SABERHITBOX)

addHook("ShouldDamage", function(pmo, inflictor, source, damage, damagetype) // small beams can only damage players that are in tumble
	local B = CBW_Battle
	if not B then return end
	if not inflictor or not inflictor.valid then return end
	if inflictor.type != MT_JANA_SMALLSABERBEAM then return end
	if not source return false end
	if  pmo.player and pmo.state == S_PLAY_PAIN then return end // let it damage players if they are already in tumble
	if pmo.player and source and source.valid and source.player and not(B.MyTeam(source.player,pmo.player)) and not P_PlayerInPain(pmo.player) then
		local vulnerable = B.PlayerCanBeDamaged(pmo.player)

		if pmo.player.guard > 0 then 
		return end
		if inflictor.valid and vulnerable and pmo.player.battle_def < inflictor.blockable then
			pmo.pushtics = 1  
			local pushangle = R_PointToAngle2(source.x, source.y, pmo.x, pmo.y)
			B.DoPlayerTumble(pmo.player, 11, pushangle, inflictor.scale*5, true)
			pmo.player.powers[pw_flashing] = 1
			P_SetObjectMomZ(pmo, 4*FRACUNIT, true) // we need this otherwise she will lose credit
			pmo.pushed = source
			B.PlayerCreditPusher(pmo.player,source)
			inflictor.flags = $&~MF_MISSILE
			return false
		end
	end
end,MT_PLAYER)

--remove piercing to prevent crashing the game on bashables
addHook("MobjRemoved", function(mo)
	if mo.tracer then
		P_RemoveMobj(mo.tracer)
		mo.tracer = nil
	end
end, MT_JANA_LARGESABERBEAM_HITBOX)

local function BattleSaberHitboxCollide(hitbox, item) // adding hooks so sword hitbox can effect players
	if not hitbox.valid
	or not item.valid
	or hitbox.z > item.z + item.height
	or item.z > hitbox.z + hitbox.height
		return false
	end
	
	local B = CBW_Battle
	if not B then return false end
		
	local blockable = 1
	local mo = hitbox.target
	
	if mo.frame <= 256 or mo.frame == 259 then // dont hit durring the srartup...or end lag?
	return false end
	
	local pushtime = 1 
	if mo.state == S_JANA_DASHATTACK then
		pushtime = TICRATE/3 // this makes it so dash slash can hit twice if timed right
	end
	
	// clash with other jenna swords
	if mo.pushtics == 0 and item.type == MT_JANA_SABERHITBOX and item.target.frame > 256
	and not (B.MyTeam(mo.player,item.target.player)) then
		local recoil1 = FixedHypot(item.target.momx, item.target.momy)/-3
		local recoil2 = FixedHypot(mo.momx, mo.momy)/-3
		local recoilangle1 = R_PointToAngle2(mo.x, mo.y, item.x, item.y)
		local recoilangle2 = R_PointToAngle2(item.x, item.y, mo.x, mo.y)
		local xpos = (hitbox.x+item.x)/2
		local ypos = (hitbox.y+item.y)/2
		local tar = item.target
		P_SpawnGhostMobj(mo)
		P_SpawnGhostMobj(tar)
		B.DoPlayerFlinch(mo.player, TICRATE/3, recoilangle1, -5*mo.scale, true)
		B.DoPlayerFlinch(tar.player, TICRATE/3, recoilangle2, -5*tar.scale, true)
		P_Thrust(mo, recoilangle1, 2*mo.scale+recoil1)
		P_Thrust(tar, recoilangle2, 2*tar.scale+recoil2)
		mo.pushtics = 1
		tar.pushtics = 1
		B.PlayerCreditPusher(mo.player,tar)
		B.PlayerCreditPusher(tar.player,mo)
		local effect1 = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_WATERZAP)
		P_SetOrigin(effect1, xpos, ypos, effect1.z)
		effect1.destscale = hitbox.scale*2
		effect1.sprite = SPR_JETF
		effect1.fuse = $*2
		S_StartSound(mo, sfx_cdfm78)
		S_StartSound(tar, sfx_cdfm78)
		return false
	end
	
	if item.flags&(MF_MISSILE) and item.blockable == 1 and not (B.MyTeam(mo.player,item.target.player)) then  
		P_KillMobj(item, hitbox, hitbox, 0)
		local recoil = FixedHypot(item.momx, item.momy)/-5
		local recoilangle = R_PointToAngle2(mo.x, mo.y, item.x, item.y)
		local blockstun = item.block_stun*3
		if mo.state != S_JANA_DASHATTACK then
			P_SpawnGhostMobj(mo)
			B.DoPlayerFlinch(mo.player, blockstun, recoilangle, -3*mo.scale, true)
		end
		local effect = P_SpawnMobjFromMobj(item, 0, 0, 0, MT_WATERZAP)
		effect.destscale = hitbox.scale*2
		effect.sprite = SPR_JETF
		effect.fuse = $*2
		B.PlayerCreditPusher(mo.player,item.target)
		P_Thrust(mo, recoilangle, 2*mo.scale+recoil)
		item.momx = 0
		item.momy = 0
		item.flags = $|MF_NOCLIP|MF_NOCLIPTHING&~MF_SPECIAL&~MF_MISSILE
		S_StartSound(item, sfx_cdfm78)
		return false
	end
	
	if not item.player then
	return false end
	
	if item.health <= 0 or item == mo or (B.MyTeam(mo.player,item.player)) then
	return false end
	
	if item.player.battle_def >= blockable and (item.pushtics == 0 or item.state == S_PLAY_PAIN) and not item.player.powers[pw_flashing] then
			item.pushtics = pushtime 
			mo.pushtics = pushtime
			local launchspeed = FixedHypot(mo.momx, mo.momy)/-3
			local pushangle = R_PointToAngle2(item.x, item.y, mo.x, mo.y)
			B.DoPlayerFlinch(item.player, TICRATE/2, pushangle, -5*mo.scale, true)
			P_Thrust(item, pushangle, (-2*mo.scale+launchspeed))
			//item.player.powers[pw_flashing] = 1
			P_SetObjectMomZ(item, 1*FRACUNIT, true)
			item.pushed = mo
			B.PlayerCreditPusher(item.player,mo)
			B.PlayerCreditPusher(mo.player,item.target)
			mo.momx = item.momx/-2
			mo.momy = item.momy/-2
			P_Thrust(mo, pushangle, 4*mo.scale+launchspeed)
			S_StartSound(item, sfx_cdfm78)
			mo.player.powers[pw_nocontrol] = 12
			local effect = P_SpawnMobjFromMobj(item, 0, 0, 0, MT_WATERZAP)
			effect.destscale = hitbox.scale*2
			effect.sprite = SPR_JETF
			effect.fuse = $*2
	elseif item.pushtics == 0 and not item.player.powers[pw_flashing] then
		P_DamageMobj(item, mo, mo)
		if not item.player.guard then
			S_StartSound(item, sfx_hit02)
			local hiteffect = P_SpawnMobjFromMobj(item, 0, 0, 0, MT_THOK)
			hiteffect.state = S_BCEBOOM
			hiteffect.colorized = true
			hiteffect.color = SKINCOLOR_ICY
		end
	end
	return false

end

addHook("MobjCollide", BattleSaberHitboxCollide, MT_JANA_SABERHITBOX)
addHook("MobjMoveCollide", BattleSaberHitboxCollide, MT_JANA_SABERHITBOX)
