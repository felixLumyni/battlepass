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

local abilityAngle = function(player)
	if (player.pflags & PF_ANALOGMODE) then
		local inputangle = R_PointToAngle2(0, 0, player.cmd.forwardmove*FRACUNIT, -player.cmd.sidemove*FRACUNIT)
		inputangle = $ + (player.cmd.angleturn << FRACBITS)
		return inputangle
	else
		return player.mo and player.mo.angle or player.drawangle
	end
end

local newmaimyspecial = function(mo, doaction)
	local player = mo.player
	player.actiontext = "Charge dash"
	player.actionrings = 10
	local speed = min(mo.scale*28, player.speed)

	if doaction == 1 and player.maimy then
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
		player.maimy.rocketcharge = 0
		player.maimy.blastoff = true
	end
end

local guh = function(n1,n2,plr,mo,atk,def,weight,hurt,pain)
	if plr[n2].guardtics > 0 then
		return
	end
	if mo[n1].skin == "maimy" and plr[n1].dashmode >= 3*TICRATE then
		CBW_Battle.DoPlayerTumble(plr[n2], TICRATE, mo[n1].angle, plr[n1].speed, true)
	end
end

local maimyloaded = false
local maimyload = function()
	if CBW_Battle and CBW_Battle.SkinVars and CBW_Battle.SkinVars["maimy"] and not maimyloaded then
		if CBW_Battle.SkinVars["maimy"].special then
			rawset(_G, "oldmaimyspecial", CBW_Battle.SkinVars["maimy"].special)
		else
			assert("https://www.youtube.com/watch?v=tDPW5CYFhT8")
		end
		CBW_Battle.SkinVars["maimy"].func_postcollide = guh
		maimyloaded = true
	end
end
addHook("ThinkFrame", maimyload)

local maimyspecialthinker = function(player)
	--battlemod cacee check
	if not (CBW_Battle
	and oldmaimyspecial
	and player.mo
	and player.mo.valid
	and player.mo.skin == "maimy")
	then
		return
	end

	--switch specials
	CBW_Battle.SkinVars["maimy"].special = (player.mo.state == S_MAIMY_CHARGE) and newmaimyspecial or oldmaimyspecial
end
addHook("PlayerThink", maimyspecialthinker)