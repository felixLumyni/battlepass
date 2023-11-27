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
			return
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
			--sound cue
			if (player.cmd.buttons & BT_JUMP)
			and not (player.buttonhistory & BT_JUMP)
			then
				S_StartSound(player.mo, sfx_s3k94)
			end
			--disable jump
			player.cmd.buttons = $&~BT_JUMP
			player.jana.jumpdown = false
		end
	end
end
addHook("PreThinkFrame",janawallexhaust)

local janapriority = function(player)
	if player.jana and player.jana.diving then
		CBW_Battle.SetPriority(player,1,0,"stomp",2,2,"dive attack")
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
	end
end
addHook("ThinkFrame", janaload)

addHook("MobjSpawn",function(mo)
	mo.hit_sound = sfx_hit02
	mo.blockable = 1
	mo.block_stun = 4
	mo.block_hthrust = 3
	mo.block_vthrust = 2
end, MT_JANA_SMALLSABERBEAM)

addHook("MobjSpawn",function(mo)
	mo.hit_sound = sfx_hit02
	mo.blockable = 2
	mo.block_stun = 35
	mo.block_hthrust = 12
	mo.block_vthrust = 3
end, MT_JANA_LARGESABERBEAM)

--remove piercing to prevent crashing the game on bashables
addHook("MobjRemoved", function(mo)
	if mo.tracer then
		P_RemoveMobj(mo.tracer)
		mo.tracer = nil
	end
end, MT_JANA_LARGESABERBEAM_HITBOX)