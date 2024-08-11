//--------------we need to have our own copy of skipcraftlist so we can prevent skip from selecting custom boxs
//List of monitors
local b_skipcraftlist = {
	[0] = MT_PITY_BOX,
	MT_EGGMAN_BOX,
	MT_SNEAKERS_BOX,
	MT_FORCE_BOX,
	MT_ATTRACT_BOX,
	MT_BUBBLEWRAP_BOX,
	MT_MYSTERY_BOX,
	MT_ARMAGEDDON_BOX,
	MT_ELEMENTAL_BOX,
	MT_INVULN_BOX,
	MT_FLAMEAURA_BOX,
	MT_WHIRLWIND_BOX,
	MT_THUNDERCOIN_BOX,
	MT_SKIPSUPERBOX,
}
local skiptotalcraft = #b_skipcraftlist

//---------------------------------------------------------------------//

local spawnscrap = function(target)
	local scrap = P_SpawnMobjFromMobj(target,0,0,0,MT_SKIPMETALSCRAP)
	if scrap and scrap.valid then
		scrap.shadowscale = FRACUNIT/2
		scrap.reactiontime = scrap.scale
			
		--Change the color
		if target.color then
			scrap.color = target.color
		else
			scrap.color = SKINCOLOR_CLOUDY
		end
			
		scrap.cusval = scrap.color
			
		--Do the movement
		P_SetObjectMomZ(scrap, FRACUNIT*10, true)
		P_InstaThrust(scrap, FixedAngle(360*P_RandomFixed()), 10*P_RandomFixed())
		scrap.rollangle = FixedAngle(360*P_RandomFixed())

		--Big scraps
		if P_RandomChance(FRACUNIT/3) then
			scrap.threshold = 2
			if P_RandomChance(FRACUNIT/3) then
				scrap.scale = $*3/2
				scrap.shadowscale = $*2/3
				scrap.frame = 0
			else
				scrap.height = $*2
				scrap.radius = $*2
				scrap.shadowscale = $/2
				scrap.frame = P_RandomRange(5,6)
			end
			
		--Small scraps
		else
			scrap.threshold = 1
			scrap.scale = $*3/2
			scrap.shadowscale = $/2
			scrap.frame = P_RandomRange(1,4)
		end
	end
end
local exchange = function(mo,doaction)
	local cooldown = TICRATE
	local player = mo.player
	player.actiontext = "Exchange"
	player.actionrings = 5
	player.exchanging = $ or 0

	if not (player.rings >= player.actionrings) then
		player.actiontext = "Not enough Rings!"
	end
	if (player.rings >= player.actionrings)
	and P_IsObjectOnGround(mo)
	and doaction
	then
		player.powers[pw_nocontrol] = max($,1)
		player.actiontext = "\130Exchanging..."
		if player.mo.state != S_PLAY_CRFT then
			player.mo.state = S_PLAY_CRFT
		end
		if player.exchanging >= cooldown
		and player.exchanging%cooldown == 0
		then
			if (player.rings == player.actionrings) then --warning sfx
				CBW_Battle.PayRings(player,player.actionrings+1)
			else
				CBW_Battle.PayRings(player,player.actionrings)
			end
			spawnscrap(mo)
		end
		player.exchanging = $+1
	elseif player.mo.state == S_PLAY_CRFT
	and not mo.skipmenu
	then
		player.mo.state = S_PLAY_SKIPCANCEL
		player.exchanging = 0
	end
end

local fx = function(mo)
	for n = 0, 16 do
		local dust = P_SpawnMobj(mo.x,mo.y,mo.z,MT_DUST)
		if dust and dust.valid then
			P_InstaThrust(dust,mo.angle+ANGLE_22h*n,mo.scale*36)
		end
	end
end

--i had to remake guard action for skip because he keeps dropping his scraps on parry auughghh
--same thing as battlemod's standard guard trigger, but returns false in the end
local BRUH = function(target, inflictor, source, damage, damagetype)
	if target.player.guard == 1 and inflictor and inflictor.valid then
		local B = CBW_Battle
		S_StartSound(target,sfx_cdpcm9)
		S_StartSound(target,sfx_s259)
		target.player.guard = 2
		target.player.guardtics = 9
		B.ControlThrust(target,FRACUNIT/2)
		--Do graphical effects
		local sh = P_SpawnMobjFromMobj(target,0,0,0,MT_BATTLESHIELD)
		sh.target = target
		fx(target)
		P_SpawnMobjFromMobj(inflictor,0,0,0,MT_EXPLODE)
		--Affect source
		if source and source.valid and source.health and source.player and source.player.powers[pw_flashing] then
			source.player.powers[pw_flashing] = 0
			local nega = P_SpawnMobjFromMobj(source,0,0,0,MT_NEGASHIELD)
			nega.target = source
		end
		--Affect attacker
		if inflictor.player then
			if inflictor.player.powers[pw_invulnerability] then
				inflictor.player.powers[pw_invulnerability] = 0
				P_RestoreMusic(inflictor.player)
			end	
			local angle = R_PointToAngle2(target.x-target.momx,target.y-target.momy,inflictor.x-inflictor.momx,inflictor.y-inflictor.momy)
			local thrust = FRACUNIT*10
			if twodlevel then thrust = B.TwoDFactor($) end
			P_SetObjectMomZ(inflictor,thrust)
			B.DoPlayerTumble(inflictor.player, 70, angle, inflictor.scale*3, true)
		else
			P_DamageMobj(inflictor,target,target)
		end
		return false
	end
end

local skippriority = function(player)
	if player.mo and player.mo.state == S_PLAY_SKIPDIVE then
		CBW_Battle.SetPriority(player,1,0,"amy_melee",1,1,"pounce attack")
	end
end

local skipbattle = function(player)
	--battlemod skip check
	if not (CBW_Battle
	and player.mo
	and player.mo.valid
	and player.mo.skin == "skip")
	then
		player.wasntskip = true
		return
	end
	
	if player.skipselection != nil then // no selecting custom monitors 
		if player.righttapping and player.skipselection > skiptotalcraft then
			player.skipselection = 0
		elseif player.lefttapping and player.skipselection > skiptotalcraft then
			player.skipselection = 13 // wrap around to super transform box
		end
	end
	
	// taunts only trigger if custom button 1 is held
	if P_IsObjectOnGround(player.mo) and player.skiptosstapping then
		if (player.cmd.buttons & BT_CUSTOM1) then else
		player.skipsmug = false
		P_RestoreMusic(player)
		player.mo.skipcrouching = true
		player.mo.state = S_PLAY_SKIPCROUCH
		end
	end
	
	--no cheese
	if player.wasntskip then
		player.skipscrap = 0
		player.wasntskip = false
	end

	--sick guard frames
	if player.guardtics
	and player.guardtics > 0
	and player.mo.state == S_PLAY_STND
	and not player.powers[pw_flashing]
	then
		player.mo.sprite2 = SPR2_SKID
		player.mo.frame = 0
		--battlemod...
		player.hadguardtics = player.guardtics
		player.mo.flags2 = $&~MF2_DONTDRAW
		local g = P_SpawnGhostMobj(player.mo)
		g.tics = 2
		g.blendmode = 0
		g.momx = player.mo.momx
		g.momy = player.mo.momy
		g.momz = player.mo.momz
		g.shadowscale = player.mo.scale
		g.shieldscale = player.mo.scale --doesn't work T_T
		player.mo.flags2 = $|MF2_DONTDRAW|MF2_SHIELD
	elseif player.hadguardtics then
		player.mo.flags2 = $&~MF2_DONTDRAW
		player.hadguardtics = 0
	end

	--flagholder stuff
	if player.gotflagdebuff then
		--no crafting
		player.jumptapping = false
		player.mo.skipmenu = false

		--no conflicting with battlemod's ledgegrab
		player.ledgegrabcooldown = 2

		--dive speed cap
		if player.mo.state == S_PLAY_SKIPDIVE then
			local speed = FixedHypot(player.mo.momx,player.mo.momy)
			local mult = 2 and player.powers[pw_sneakers] or 1
			local maxspeed = FixedMul(player.mo.scale,player.normalspeed)*mult
			if speed > maxspeed then
				local dir = R_PointToAngle2(0,0,player.mo.momx,player.mo.momy)
				P_InstaThrust(player.mo,dir,player.normalspeed)
			end
			if player.mo.momz > 0 then
				P_SetObjectMomZ(player.mo, -gravity, true)
			end
				
		--fix being able to move in unexpected cases
		elseif player.mo.state == S_PLAY_SKIPCROUCH
		or player.mo.state == S_PLAY_CRFT
		then
			player.powers[pw_nocontrol] = max($,1)
		end
	end

	--i am a clown
	if player.skipscrapreset then
		player.skipscrap = 0
		player.skipscrapreset = false
	end
	--lol lmao
	player.armachargeup = 0
	S_StopSoundByID(player.mo,sfx_s3kc4s)
end
addHook("PlayerThink",skipbattle)

local skiploaded = false
local skipload = function()
	if skins["skip"] and CBW_Battle and not skiploaded then
		skiploaded = true
		CBW_Battle.SkinVars["skip"] = {
			weight = 75,
			special = exchange,
			func_priority_ext = skippriority,
			func_guard_trigger = BRUH
		}
	end
end
addHook("ThinkFrame", skipload)

local skipbattle2 = function(mo)
	--player in competitive gametype in battlemod check
	if not (CBW_Battle and mo.player)
	or (gametyperules&GTR_FRIENDLY and not modeattacking)
	then
		return
	end
		
	--reset scraps to 0 on death (5 because dropping gears looks cool)
	mo.player.skipscrap = $ and max($, 5) or 0
end
addHook("MobjDeath", skipbattle2, MT_PLAYER)

local skipbattle3 = function(player)
	--competitive gametype in battlemod check
	if not CBW_Battle
	or (gametyperules&GTR_FRIENDLY and not modeattacking)
	then
		return
	end
		
	--reset scraps to 0
	player.skipscrapreset = true --dw i also hate this
end
addHook("PlayerSpawn", skipbattle3)

local skipbattle4 = function()
	for player in players.iterate do
		--battlemod skip check
		if not (CBW_Battle
		and player.mo
		and player.mo.valid
		and player.mo.skin == "skip")
		then
			return
		end
		-- prevent shield dive abils with flag
		if player.gotflagdebuff and player.powers[pw_shield] then
			player.mo.battlepatch_storeshield = player.powers[pw_shield]
			player.powers[pw_shield] = SH_PITY
		end
	end
end
addHook("PreThinkFrame", skipbattle4)

local skipbattle5 = function()
	for player in players.iterate do
		if player.mo and player.mo.battlepatch_storeshield then
			if not P_PlayerInPain(player) then -- gotta love bandaid fixes, right guys?? haha...
				player.powers[pw_shield] = player.mo.battlepatch_storeshield
			end
			player.mo.battlepatch_storeshield = nil
			--P_SpawnShieldOrb(player) -- LOOKS UGLY
		end
	end
end
addHook("PostThinkFrame", skipbattle5)
