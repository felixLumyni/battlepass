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
