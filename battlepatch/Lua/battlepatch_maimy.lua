--[[
IF MERGING THIS SCRIPT WITH MAIMY'S PK3, DON'T USE THE STUPID FUNCTION BELOW
you could, but you only really need to update/refresh her function "maimybattle",
which is commented in this lua for this reason
thank :) ~lumy
]]
local stupid = function(target, inflictor)
	if not (skins["maimy"] and CBW_Battle
	and inflictor
	and inflictor.valid
	and inflictor.type == MT_MAIMY_MACE_HURTBOX
	and inflictor.target)
		return
	end

	--teammate check
	if CBW_Battle.MyTeam(target.player, inflictor.target.player) and not CV_FindVar("friendlyfire").value then
		return false
	end
end
addHook("MobjCollide",stupid,MT_PLAYER)

--[[
local maimybattle = function(target, inflictor, source, damage, damagetype)
	--battlemod maimy check
	if not (skins["maimy"] and CBW_Battle
	and inflictor
	and inflictor.valid
	and inflictor.type == MT_MAIMY_MACE_HURTBOX
	and inflictor.target)
		return
	end

	--teammate check
	if CBW_Battle.MyTeam(target.player, inflictor.target.player) and not CV_FindVar("friendlyfire").value then
		return false
	end

	--parrying the mace triggers parry for its player
	CBW_Battle.GuardFunc.Parry(target, inflictor.target, source, damage, damagetype)
end
addHook("ShouldDamage",maimybattle,MT_PLAYER)
]]

local maimybattle2 = function()
	for player in players.iterate do
		--maimy check
		if not (player.mo and player.mo.skin == "maimy") then
			continue
		end
		--placing this here in case the addon is loaded before maimy
		mobjinfo[MT_MAIMY_MACE_HURTBOX].radius = 22*FRACUNIT
		--prevent using jump during shield abilities
		if player.pflags & PF_SHIELDABILITY then
			player.cmd.buttons = $&~BT_JUMP
		end
		--actionstate cancel
		if player.actiontime and CBW_Battle.PlayerButtonPressed(player,player.battleconfig_guard,true) then
			player.actiontime = 0
		end
	end
end
addHook("PreThinkFrame", maimybattle2)

-- TL;DR OF EVERYTHING BELOW THIS LINE: Adding the charge dash bm ability
-- Some of these functions already exist in maimy's pk3 but I also had to write them here, gotta love local vars

local MAIMY_BATTLE_SPECIAL_COOLDOWN = 4*TICRATE
local MAIMY_BATTLE_SPECIAL_RING_COST = 10 
local MAIMY_BATTLE_SPECIAL_LENGTH = 2*TICRATE
local MAIMY_BATTLE_SPECIAL_SOUND_TIME = 10

local abilityAngle = function(player)
	if (player.pflags & PF_ANALOGMODE) then
		local inputangle = R_PointToAngle2(0, 0, player.cmd.forwardmove*FRACUNIT, -player.cmd.sidemove*FRACUNIT)
		inputangle = $ + (player.cmd.angleturn << FRACBITS)
		return inputangle
	else
		return player.mo and player.mo.angle or player.drawangle
	end
end

local function IsValid(a)
	if a ~= nil then return a.valid end
	return false
end

local function MaimyCanSpin(player)
	return 
	not IsValid(player.maimyMace) and 
	not P_PlayerInPain(player) and 
	not P_SuperReady(player) and 
	player.exiting == 0 
end

local function MaimyMaceSpinEnd(player)
	if IsValid(player.maimyMace) then
		player.maimyMace.state = S_NULL
		player.mo.state = S_PLAY_FALL
	end
	player.charflags = $ | SF_DASHMODE
	player.normalspeed = skins[player.mo.skin].normalspeed
end

local function MaimyDoMaceSpin(player)
	local playerMo = player.mo
	-- reverbal: replaced MaimyCanSwing with MaimyCanSpin
	if IsValid(playerMo) and MaimyCanSpin(player) then
		player.panim = PA_ABILITY2
		playerMo.state = S_PLAY_MAIMY_MELEE_SPIN
		player.charflags = $ & ~SF_DASHMODE
		player.normalspeed = (skins[playerMo.skin].normalspeed)/4
		local maceMT, hurtboxMT
		if player.powers[pw_super] > 0 then
			maceMT = MT_MAIMY_SUPER_MACE
			hurtboxMT = MT_MAIMY_SUPER_MACE_HURTBOX
		else
			maceMT = MT_MAIMY_MACE
			hurtboxMT = MT_MAIMY_MACE_HURTBOX
		end
		player.maimyMace = P_SpawnMobjFromMobj(playerMo,0,0,0,maceMT)
		player.maimyMace.target = playerMo
		player.maimyMace.movedir = 0
		if player.powers[pw_super] > 0 then
			P_SetMobjStateNF(player.maimyMace, S_MAIMY_SUPER_MACE_SPIN)
		else
			P_SetMobjStateNF(player.maimyMace, S_MAIMY_MACE_SPIN)
		end
		local maimyMaceHurtbox = P_SpawnMobjFromMobj(playerMo,0,0,0,hurtboxMT)
		maimyMaceHurtbox.target = playerMo
		maimyMaceHurtbox.tracer = player.maimyMace
		maimyMaceHurtbox.scale = 0
		for i=1,states[S_MAIMY_RING].var1 do
			local ring = P_SpawnMobj(0,0,0,MT_MAIMY_RING)
			if player.powers[pw_super] > 0 then
				P_SetMobjStateNF(ring, S_MAIMY_SUPER_RING)
			end
			ring.target = player.maimyMace
			ring.tracer = playerMo
			ring.movecount = i
		end
		if not P_IsObjectOnGround(playerMo) then
			local FRACUNIT10 = FRACUNIT*10
			P_SetObjectMomZ(playerMo,FixedMul(FRACUNIT10*P_MobjFlip(playerMo),playerMo.scale))
		end
	end
end

local newmaimyspecial = function(mo, doaction)
	local player = mo.player
	player.actiontext = (player.mo.state == S_MAIMY_CHARGE) and "Charge dash" or "Mace spin"
	player.actionrings = MAIMY_BATTLE_SPECIAL_RING_COST

	if doaction == 1 and (player.mo.state == S_MAIMY_CHARGE) and player.maimy then
		CBW_Battle.PayRings(player, player.actionrings)
		CBW_Battle.ApplyCooldown(player, 2 * TICRATE)
		mo.state = S_PLAY_ROLL
		player.pflags = $ &~ PF_NOJUMPDAMAGE
		player.pflags = $ &~ PF_STARTJUMP
		local vspd = (mo.eflags & MFE_UNDERWATER) and player.maimy.rocketcharge/2 or player.maimy.rocketcharge
		local hspd = max(player.speed/2, player.maimy.rocketcharge*mo.scale*4/5)
		--P_SetObjectMomZ(mo, vspd*(FRACUNIT/2 + FRACUNIT/5)/2, false)
		P_SetObjectMomZ(mo, (mo.eflags & MFE_UNDERWATER) and mo.scale*4 or mo.scale*8, false)
		P_InstaThrust(mo, abilityAngle(mo.player), hspd)
		S_StartSound(mo, sfx_cdfm62)
		player.dashmode = $+player.maimy.rocketcharge or player.maimy.rocketcharge
		player.maimy.rocketcharge = 0
		player.maimy.blastoff = true
	elseif player.actionstate > 0 and (player.actiontime <= 0 or not IsValid(player.maimyMace)) then
		MaimyMaceSpinEnd(player)
		CBW_Battle.ApplyCooldown(player,MAIMY_BATTLE_SPECIAL_COOLDOWN)
		player.actionstate = 0
	elseif player.actionstate == 0 and IsValid(player.maimyMace) and player.maimyMace.state == S_MAIMY_MACE_SPIN then
		MaimyMaceSpinEnd(player)
		CBW_Battle.ApplyCooldown(player,MAIMY_BATTLE_SPECIAL_COOLDOWN)
	elseif IsValid(player.maimyMace) then
		player.canguard = false
		player.actiontime = max($ - 1, 0)
	elseif doaction == 1 and (CBW_Battle.CanDoAction(player)) and MaimyCanSpin(player) then
		CBW_Battle.PayRings(player)
		player.actiontime = MAIMY_BATTLE_SPECIAL_LENGTH
		player.actionstate = 1
		MaimyDoMaceSpin(player)
	end
end

local maimyloaded = false
local maimyload = function()
	if CBW_Battle and CBW_Battle.SkinVars and CBW_Battle.SkinVars["maimy"] and not maimyloaded then
		CBW_Battle.SkinVars["maimy"].special = newmaimyspecial
		maimyloaded = true
	end
end
addHook("ThinkFrame", maimyload)