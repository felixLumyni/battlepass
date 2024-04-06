freeslot("sfx_ceupr2") --the only freeslot. also bpatch stuff starts at line 260

local function caceecircle(mobj, mobjtype, amount, ns, zoffset, scale, keepmom, color, vertical, vertangle, amount2)
	local i = 0	while i < amount
		local fa = amount2 and i*(ANGLE_180/(amount2/2)) or i*(ANGLE_180/(amount/2))
		local fa2 = amount2 and fa-mobj.angle+ANGLE_90+ANGLE_22h or fa --this is very hacky but whatever ~lumy
		local mo = P_SpawnMobjFromMobj(mobj,0,0,zoffset,mobjtype)
		if mo and mo.valid
			local height = mo.height
			mo.scale = scale
			mo.target = mobj
			if mobj.eflags&MFE_VERTICALFLIP
				mo.z = $-(mo.height-height)
			end
			if mobjtype == MT_MINECARTSPARK
				mo.fuse = TICRATE
			end
			if color
				mo.color = color
				mo.colorized = true
			end
			if mo.type == MT_THOK
				mo.colorized = false
				mo.fuse = mo.tics
			end
			if vertical
				mo.momz = FixedMul(sin(fa2),ns)
				P_InstaThrust(mo, vertangle+ANGLE_90,
				FixedMul(cos(fa),ns))
			else
				mo.momx = FixedMul(sin(fa2),ns)
				mo.momy = FixedMul(cos(fa2),ns)
			end
			if keepmom
				mo.momx = $+mobj.momx
				mo.momy = $+mobj.momy
				mo.momz = $+mobj.momz
			end
		end
		i = $+1
	end
end

local function getinputangle(player, uppercut)
	if player.mo.flags2 & MF2_TWOD or twodlevel
	or player.caceeinputangle == nil
	or (not (player.pflags&PF_ANALOGMODE)
	and (not (player.cmd.forwardmove or player.cmd.sidemove)
	or (player.caceecamera and ((not uppercut and player.caceecamera != 2)
	or (uppercut and player.caceecamera >= 2))) ))
		return player.mo.angle
	elseif player.pflags&PF_ANALOGMODE
	and player.caceecamera and ((not uppercut and player.caceecamera != 2)
	or (uppercut and player.caceecamera >= 2))
		return player.cmd.angleturn<<16
	else
		return player.caceeinputangle
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

local DoUpper = function(player, special) -- (branched from cacee.pk3 teehee)
	local mo = player.mo

	player.pflags = $&~PF_JUMPED
	local floored = P_IsObjectOnGround(mo) or mo.eflags & MFE_JUSTHITFLOOR
	P_DoJump(player, false)
	player.caceeupperspeed = FixedHypot(mo.momx, mo.momy)
	if floored then
		player.caceeuppermomz = mo.momz
	else
		player.caceeuppermomz = (player.pflags & PF_THOKKED) and mo.momz/2 or mo.momz
	end
	if special then
		S_StartSound(mo, sfx_ceupr2)
		player.caceeuppermomz = (player.cmd.buttons & BT_JUMP) and $ or $*2 --idk why this is necessary
		player.bpatchcaceestartjump = true
		player.pflags = $ &~ (PF_STARTJUMP|PF_JUMPDOWN)
	else
		S_StartSound(mo, sfx_ceuppr)
	end
	local minspeed = (mo.eflags&MFE_UNDERWATER) and mo.scale*4 or mo.scale*8
	player.caceeuppermomz = max($, minspeed)
	player.caceeupperangle = player.drawangle
	player.caceeuppertimer = 10
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

	if P_RandomChance(FRACUNIT/70) then S_StartSound(mo, sfx_ceshok) end
	if player.solchar and player.solchar.istransformed then
		S_StartSound(mo, sfx_s3k48)
	end
	
	caceecircle(mo, MT_DUST, 16, 16*mo.scale, 0, mo.scale, false, 0, false, player.drawangle)
	mo.state = S_PLAY_STND
	mo.state = S_PLAY_TWINSPIN
	player.panim = PA_DASH
end

--finally
local PUNCHCOOLDOWN = 1 --frames. only counts down after punch anim is over to prevent free combos
local COMBOWINDOW = TICRATE --amount of frames cacee has to do her next punches after connecting one

local caceebattle = function(player)
	--battlemod cacee check
	if not (CBW_Battle
	and player.mo
	and player.mo.valid
	and player.mo.skin == "cacee")
	then
		return
	end

	--variables for preventing punch in certain cases
	local didntjump = (not (P_IsObjectOnGround(player.mo)))
	and (player.panim == PA_IDLE
	or player.panim == PA_WALK
	or player.panim == PA_RUN
	)
	local sprung = (not (player.pflags&PF_JUMPED))
	and (player.panim == PA_SPRING
	or player.panim == PA_FALL
	)
	local floored = (P_IsObjectOnGround(player.mo) or player.mo.eflags & MFE_JUSTHITFLOOR) and not (player.mo.state == S_PLAY_TWINSPIN)

	--reset some vars
	if floored then
		player.mo.bpatchcaceetumblepunch = false
		player.bpatchcaceeairpunched = false
	end
	
	--cancel special upper's momentum with the special button instead of the jump button
	if player.bpatchcaceestartjump then
		player.pflags = $ &~ PF_STARTJUMP
		local rising = false
		local falling = false
		local leniency = player.mo.scale*6
		if P_MobjFlip(player.mo) > 0 then
			rising = player.mo.momz > 0
			falling = player.mo.momz < -leniency
		else
			rising = player.mo.momz < 0
			falling = player.mo.momz > leniency
		end
		if floored or (rising and not (player.cmd.buttons & player.battleconfig_special)) then
			player.mo.momz = $/2
			player.bpatchcaceestartjump = false
		elseif falling then
			player.bpatchcaceestartjump = false
			print(player.mo.momz/FRACUNIT)
		end
	end

	--punch timer (positive = can't punch, negative = can punch & immunity to positive punch timer)
	player.bpatchcaceepunch = $ or 0
	if player.bpatchcaceepunch > 0 then --and P_IsObjectOnGround(player.mo) then
		player.bpatchcaceepunch = $-1
	elseif player.bpatchcaceepunch < 0 then
		player.bpatchcaceepunch = $+1
	end
	if player.caceepunch and not(player.bpatchcaceepunch < 0) then
		if player.caceepunch >= 2 then
			player.bpatchcaceepunch = PUNCHCOOLDOWN
		end
		if player.mo.pushtics then
			player.bpatchcaceepunch = -COMBOWINDOW
		end
	end

	--upper hit also restores punch!
	if player.mo.state == S_PLAY_TWINSPIN and player.mo.pushtics then
		player.bpatchcaceepunch = $ and min(0,$) or 0
		player.bpatchcaceeairpunched = false
	end

	if player.caceepunch then
		--hold spin button yay
		player.pflags = $ &~ PF_SPINDOWN
		--first punch is slower
		if player.caceepunch == 1 then
			local speed = FixedHypot(player.mo.momx, player.mo.momy)
			player.caceethrust = min(max(10*player.mo.scale,speed),20*player.mo.scale)
		end
		--limit air punch
		if player.mo.tics > 3 and not (P_IsObjectOnGround(player.mo) or player.bpatchcaceepunch) then
			player.bpatchcaceeairpunched = true
		end
	end

	--whiffed superjump
	local floored2 = (P_IsObjectOnGround(player.mo) or player.mo.eflags & MFE_JUSTHITFLOOR) and not (player.mo.state == S_PLAY_TWINSPIN)
	if player.mo.bpatchsupercaceepunch and (floored2 or P_PlayerInPain(player) or player.tumble or player.airdodge > 0) then
		player.mo.bpatchsupercaceepunch = 0
		S_StartSound(player.mo, sfx_kc65)
	end

	--idk why this is necessary
	if player.mo.state == S_PLAY_MELEE_LANDING then
		player.pflags = $|PF_JUMPDOWN
	end

	if (didntjump
	or sprung
	or player.tumble
	or player.skidtime
	or player.mo.bpatchsupercaceepunch
	or player.bpatchcaceepunch > 0
	or player.bpatchcaceeairpunched)
	and not (player.bpatchcaceepunch < 0)
	then
		player.pflags = $|PF_SPINDOWN
	end
end
addHook("PlayerThink", caceebattle)

local spikecombo = function(mo, doaction)
	local player = mo.player
	player.actiontext = "Spike Combo"
	player.actionrings = 10
	
	if mo.bpatchsupercaceepunch then
		local thatsitimpunching = (mo.eflags&MFE_UNDERWATER) and mo.scale*2 or mo.scale*4
		local gravflip = (mo.flags2 & MF2_OBJECTFLIP or mo.player.powers[pw_gravityboots])
		if (gravflip and mo.momz > thatsitimpunching) or (mo.momz < -thatsitimpunching and not gravflip)
		then
			DoPunch(player, 3)
			mo.bpatchcaceetumblepunch = true
			mo.bpatchsupercaceepunch = false
		elseif P_PlayerInPain(player) or player.tumble then
			mo.bpatchsupercaceepunch = false
		end
	end
	if mo.bpatchsupercaceepunch or player.caceepunch >= 3 then
		player.actiontext2 = "\130"+$
		player.actionrings = 0
		return
	end
	if doaction == 1 then
		DoUpper(player, true)
		mo.bpatchsupercaceepunch = true
		CBW_Battle.PayRings(player, player.actionrings)
		CBW_Battle.ApplyCooldown(player, 5 * TICRATE)
	end
end

local guh = function(n1,n2,plr,mo,atk,def,weight,hurt,pain)
	if (not plr[n2]) or plr[n2].guardtics > 0 then
		return
	end
	if mo[n1].bpatchcaceetumblepunch then
		mo[n2].state = S_PLAY_FALL
		local thrust = mo[n1].scale * 69/5
		CBW_Battle.DoPlayerTumble(plr[n2], TICRATE, mo[n1].angle, thrust, true)
		P_Thrust(mo[n2], mo[n1].angle, mo[n1].scale * 69/6)
		P_SetObjectMomZ(mo[n2], thrust, false)
	elseif plr[n1].caceepunch == 2 and not hurt then
		local thrust = mo[n1].scale * 69/12
		CBW_Battle.DoPlayerFlinch(plr[n2], TICRATE/2, mo[n1].angle, thrust, false)
		P_Thrust(mo[n2], mo[n1].angle, mo[n1].scale * 69/12)
	end
end

local caceeloaded = false
local caceeload = function()
	if CBW_Battle and CBW_Battle.SkinVars and CBW_Battle.SkinVars["cacee"] and not caceeloaded then

		local function GarbagePriority5(player) --modified from cacee to have min. 1 defense all around
			if player.caceepunch == 3 then -- Punch Combo Finisher.
				CBW_Battle.SetPriority(player, 1, 1, "cacee_punch", 2, 1, "Spike Rush finisher")
			elseif player.caceepunch then -- Punch Combo.
				CBW_Battle.SetPriority(player, 1, 1, "cacee_punch", 1, 1, "Spike Rush combo")
			elseif player.mo.state == S_PLAY_TWINSPIN then -- SHORYUKEN.
				CBW_Battle.SetPriority(player, 1, 1, "tails_fly", 2, 2, "Rising Upper")
			end
			
			if (not player.battle_atk and not player.battle_def and not player.tumble
			and player.battle_sfunc == "can_damage" and not P_PlayerInPain(player)
			and (player.panim < PA_PAIN or (player.panim >= PA_JUMP or player.panim <= PA_FALL)))
			or player.caceepunch >= 4 -- Don't touch the cactus, man. Unless you can handle the prickling.
			then
				CBW_Battle.SetPriority(player, 0, 0, "cacee_spikey", 1, 0, "spikey cactus body")
			end
		end

		CBW_Battle.SkinVars["cacee"].special = spikecombo
		CBW_Battle.SkinVars["cacee"].func_priority_ext = GarbagePriority5
		CBW_Battle.SkinVars["cacee"].func_postcollide = guh
		caceeloaded = true
	end
end
addHook("ThinkFrame", caceeload)

local lol = function(mo)
	if mo.target and mo.target.bpatchsupercaceepunch then
		mo.color = SKINCOLOR_SUPERGOLD2
	end
end
addHook("MobjThinker", lol, MT_GHOST)