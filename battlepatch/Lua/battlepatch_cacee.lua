--bpatch stuff starts at line 239

--spawns objects in a circle (copy and paste from cacee.pk3 teehee)
local caceecircle = function(mobj, mobjtype, amount, ns, zoffset, scale, keepmom, color, vertical, vertangle)
	local i = 0	while i < amount
		local fa = i*(ANGLE_180/(amount/2))
		local mo = P_SpawnMobjFromMobj(mobj,0,0,zoffset,mobjtype)
		if mo and mo.valid then
			local height = mo.height
			mo.scale = scale
			mo.target = mobj
			if mobj.eflags&MFE_VERTICALFLIP then
				mo.z = $-(mo.height-height)
			end
			if mobjtype == MT_MINECARTSPARK then
				mo.fuse = TICRATE
			end
			if color then
				mo.color = color
				mo.colorized = true
			end
			if mo.type == MT_THOK then
				mo.colorized = false
				mo.fuse = mo.tics
			end
			if vertical then
				mo.momz = FixedMul(sin(fa),ns)
				P_InstaThrust(mo, vertangle+ANGLE_90,
				FixedMul(cos(fa),ns))
			else
				mo.momx = FixedMul(sin(fa),ns)
				mo.momy = FixedMul(cos(fa),ns)
			end
			if keepmom then
				mo.momx = $+mobj.momx
				mo.momy = $+mobj.momy
				mo.momz = $+mobj.momz
			end
		end
		i = $+1
	end
end

local getinputangle = function(player)
	if (player.pflags & PF_ANALOGMODE) then
		local inputangle = R_PointToAngle2(0, 0, player.cmd.forwardmove*FRACUNIT, -player.cmd.sidemove*FRACUNIT)
		inputangle = $ + (player.cmd.angleturn << FRACBITS)
		return inputangle
	else
		return player.mo and player.mo.angle or player.drawangle
	end
end

local DoPunch = function(player, forcedtype) -- (copy and paste from cacee.pk3 teehee)
	local mo = player.mo
	local angle = getinputangle(player)
	local lockon = P_LookForEnemies(player, false, false)
	local lockonvalid = lockon and lockon.valid
	local speed = FixedHypot(mo.momx, mo.momy)
	local slammed = player.caceepunch == 4
	
	player.drawangle = angle
	player.caceeuppertimer = 0
	
	if forcedtype then
		player.caceepunch = forcedtype
	elseif player.caceepunch <= 0 or player.caceepunch >= 3 then
		player.caceepunch = 1
	else
		player.caceepunch = $+1
	end
	S_StartSound(mo, sfx_cepun1+player.caceepunch-1)
	
	if player.gotflagdebuff then
		player.caceethrust = speed
	elseif (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT and lockonvalid
	and not P_IsObjectOnGround(mo) and not forcedtype
	and not player.gotflag and not player.gotcrystal
	then
		player.pflags = $|PF_THOKKED|PF_SHIELDABILITY
		mo.target = lockon
		mo.tracer = lockon
		mo.angle = R_PointToAngle2(mo.x, mo.y, lockon.x, lockon.y)
		S_StartSound(mo, sfx_s3k40)
		player.homing = 3*TICRATE
	elseif abs(player.cmd.forwardmove) <= 25 and abs(player.cmd.sidemove) <= 25 then
		player.caceethrust = min(max(10*mo.scale,speed),40*mo.scale)
	else
		local oldthrust = player.caceethrust
		
		if P_IsObjectOnGround(mo) then
			player.caceethrust = max(34*mo.scale + 6*player.caceepunch*mo.scale, speed)
		else
			player.caceethrust = max(37*mo.scale, speed) + 3*mo.scale
		end
		
		if slammed then player.caceethrust = max($, oldthrust) end
		
		if (player.powers[pw_shield] & SH_NOSTACK) == SH_FLAMEAURA
		or player.solchar and player.solchar.istransformed
		then
			if (player.powers[pw_shield] & SH_NOSTACK) == SH_FLAMEAURA then
				player.pflags = $|PF_SHIELDABILITY
			end
			player.caceethrust = $ + 6*mo.scale
			S_StartSound(mo, sfx_s3k43)
		end
		
		if lockonvalid and player.caceehoming
		and not (CBW_Battle and lockon.type == MT_TARGETDUMMY)
		and abs((mo.z+mo.height/2)-(lockon.z+lockon.height/2)) <= mo.height*(P_IsObjectOnGround(mo) and 1 or 2)
		then
			angle = R_PointToAngle2(mo.x,mo.y,lockon.x,lockon.y)
			
			if player.caceecamera then
				mo.angle = angle
			end
			
			if not P_IsObjectOnGround(mo) then
				local z = mo.z + mo.height/2
				if (mo.eflags & MFE_VERTICALFLIP) then z = $-FixedMul(mo.height, mo.scale) end
				mo.momz = (lockon.z + lockon.momz - z) / max((P_AproxDistance(lockon.x + lockon.momx - mo.x, lockon.y + lockon.momy - mo.y)/max(player.caceethrust,1)),1)
				mo.momz = max(min($, mo.scale*16), mo.scale*-16)
			end
		end
	end
	
	if player.powers[pw_pushing] then
		player.caceethrust = $/2
	end
	if CBW_Battle and CBW_Battle.BattleGametype() then
		player.caceethrust = min($, 53*mo.scale) --Ugh, Battle nerfs.
	end
	
	if not player.gotflagdebuff then
		P_InstaThrust(mo, angle, player.caceethrust)
	end
	if mo.eflags&MFE_UNDERWATER then
		mo.momx = $*2/3 mo.momy = $*2/3
	end
	
	if not P_IsObjectOnGround(mo) and mo.momz*P_MobjFlip(mo) < 0 then
		mo.momz = $/2
	end
	
	local one = 3
	local two = 4
	if player.caceethrust < 40*mo.scale then
		one = 6
		two = 7
	end
	
	if abs(player.cmd.angleturn<<16 - angle) > ANGLE_90 then
		player.camerascale = skins["cacee"].camerascale*one/two
	else
		player.camerascale = skins["cacee"].camerascale*two/one
	end
	
	player.powers[pw_noautobrake] = max($, 5)
	player.skidtime = 0
	player.charflags = $|SF_NOSKID|SF_NOSPEEDADJUST
	player.pflags = $|PF_FULLSTASIS|PF_DRILLING&~PF_SPINNING
	if SF_CANBUSTWALLS then
		player.charflags = $|SF_CANBUSTWALLS
	else
		player.charability = CA_GLIDEANDCLIMB
	end
	
	mo.state = S_PLAY_STND
	mo.state = S_PLAY_MELEE
	mo.tics = $+1
	
	if player.caceepunch >= 3 then
		if P_IsObjectOnGround(mo) then
			player.pflags = $|PF_JUMPED
		end
		
		mo.z = $+P_MobjFlip(mo)
		mo.momz = abs(P_GetMobjGravity(mo)*8)*P_MobjFlip(mo)
		mo.eflags = $&~MFE_JUSTHITFLOOR
		mo.state = S_PLAY_GLIDE
		caceecircle(mo, MT_DUST, 16, 8*mo.scale, 0, mo.scale, false, 0, false, player.drawangle)
		
		if CBW_Battle and CBW_Battle.BattleGametype() then
			--nothing
		elseif (player.powers[pw_shield] & SH_NOSTACK) == SH_BUBBLEWRAP then
			player.pflags = $|PF_SHIELDABILITY
		elseif (player.powers[pw_shield] & SH_NOSTACK) == SH_ELEMENTAL then
			S_StartSound(mo, sfx_s3k43)
			player.pflags = $|PF_SHIELDABILITY
		end
	elseif player.caceepunch == 2 then
		mo.state = S_PLAY_FIRE
		mo.tics = $+1
	end
	
	player.panim = PA_DASH
end

local DoUpper = function(player) -- (copy and paste from cacee.pk3 teehee)
	local mo = player.mo

	player.pflags = $&~PF_JUMPED
	P_DoJump(player, false)
	player.caceeupperspeed = FixedHypot(mo.momx, mo.momy)
	player.caceeuppermomz = mo.momz
	player.caceeupperangle = player.drawangle
	player.caceeuppertimer = UPPERTIME
	player.caceemultihits = 0
	
	mo.momx = 0
	mo.momy = 0
	mo.momz = 0
	
	if player.caceepunch then
		player.caceepunch = 0
		player.camerascale = skins["cacee"].camerascale
	end
	player.pflags = $|PF_THOKKED|PF_FULLSTASIS|PF_DRILLING&~PF_STARTJUMP&~PF_SPINNING
	player.charflags = $|SF_NOSPEEDADJUST
	if SF_CANBUSTWALLS then
		player.charflags = $|SF_CANBUSTWALLS
	else
		player.charability = CA_GLIDEANDCLIMB
	end
	
	S_StartSound(mo, sfx_ceuppr)
	if P_RandomChance(FRACUNIT/70) then S_StartSound(mo, sfx_ceshok) end
	if player.solchar and player.solchar.istransformed then
		S_StartSound(mo, sfx_s3k48)
	end
	
	caceecircle(mo, MT_DUST, 16, 16*mo.scale, 0, mo.scale, false, 0, false, player.drawangle)
	mo.state = S_PLAY_STND
	mo.state = S_PLAY_TWINSPIN
	player.panim = PA_DASH
end

local PUNCHCOOLDOWN = 1 --frames. only counts down after punch anim is over to prevent free combos
local COMBOWINDOW = TICRATE/2 --amount of frames cacee has to do her next punches after connecting one

local caceebattle = function(player)
	--battlemod cacee check
	if not (CBW_Battle
	and player.mo
	and player.mo.valid
	and player.mo.skin == "cacee")
	then
		return
	end
	--prevent punch for certain cases
	local didntjump = (not (P_IsObjectOnGround(player.mo)))
	and (player.panim == PA_IDLE
	or player.panim == PA_WALK
	or player.panim == PA_RUN
	)
	local sprung = (not (player.pflags&PF_JUMPED))
	and (player.panim == PA_SPRING
	or player.panim == PA_FALL
	)

	--punch timer (positive = can't punch, negative = can punch & immunity to positive punch timer)
	player.bpatchcaceepunch = $ or 0
	if player.bpatchcaceepunch > 0 then
		player.bpatchcaceepunch = $-1
	elseif player.bpatchcaceepunch < 0 then
		player.bpatchcaceepunch = $+1
	end
	if player.caceepunch and not(player.bpatchcaceepunch < 0) then
		player.bpatchcaceepunch = PUNCHCOOLDOWN
	end
	if player.mo.pushtics then
		player.bpatchcaceepunch = -COMBOWINDOW
	end

	if (didntjump
	or sprung
	or player.tumble
	or player.skidtime
	or player.bpatchsupercaceepunch
	or player.bpatchcaceepunch > 0)
	and not (player.bpatchcaceepunch < 0)
	then
		player.pflags = $|PF_SPINDOWN
	end
end
addHook("PlayerThink", caceebattle)

local spikerush = function(mo,doaction)
	local player = mo.player
	player.actiontext = "Spike Rush"
	player.actionrings = 10

	if player.bpatchsupercaceepunch then
		local gravflip = (mo.flags2 & MF2_OBJECTFLIP or mo.player.powers[pw_gravityboots])
		if (gravflip and mo.momz > mo.scale*4) or (mo.momz < -mo.scale*4 and not gravflip)
		then
			DoPunch(player, 3)
			player.bpatchsupercaceepunch = false
		elseif P_PlayerInPain(player) or player.tumble or not (player.pflags & PF_JUMPED) then
			player.bpatchsupercaceepunch = false
		end
	end
	if player.bpatchsupercaceepunch or player.caceepunch >= 3 then
		player.actiontext2 = "\130"+$
		player.actionrings = 0
		return
	end
	if doaction == 1 then
		DoUpper(player)
		player.bpatchsupercaceepunch = true
		CBW_Battle.PayRings(player, player.actionrings)
		CBW_Battle.ApplyCooldown(player, 5 * TICRATE)
	end
end

local caceeloaded = false
local caceeload = function()
	if CBW_Battle and CBW_Battle.SkinVars and CBW_Battle.SkinVars["cacee"] and not caceeloaded then
		CBW_Battle.SkinVars["cacee"].special = spikerush
		caceeloaded = true
	end
end
addHook("ThinkFrame", caceeload)