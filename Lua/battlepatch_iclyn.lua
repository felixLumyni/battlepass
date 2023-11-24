freeslot(
	"MT_SNOWBALL",
	"S_SNOWBALL",
	"SPR_SNBL"
)

mobjinfo[MT_SNOWBALL] = {
	name = "snowball",
	spawnstate = S_SNOWBALL,
	deathstate = S_NULL,
	deathsound = sfx_thok,
	spawnhealth = 1000,
	speed = 24*FRACUNIT,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_MISSILE,
}

states[S_SNOWBALL] = {
	sprite = SPR_SNBL,
	frame = A,
	tics = -1,
	--action = 0,
	--var1 = 0,
	--var2 = 0,
	nextstate = S_NULL,
}

-- SPECIAL behavior for Iclyn's ext. abilities projectile.
local function SnowballDamage(pmo, snowball, snowballpmo)
	-- Don't execute if the victim, inflictor and source aren't valid.
	if not (snowball and snowball.valid) then return end
	if not (pmo and pmo.valid) then return end
	if not (snowballpmo and snowballpmo.valid) then return end
	
	-- Locals for the snowball projectiles' physics.
	local angletosnowball = R_PointToAngle2(pmo.x, pmo.y, snowball.x, snowball.y)
	local snowballspeedang = R_PointToAngle2(0, 0, snowball.momx, snowball.momy)
	local snowballxyspeed = R_PointToDist2(0, 0, snowball.momx, snowball.momy) / 8
	local snowballzspeed = snowball.momz / 8
	local xythrust = 12
	local zthrust = FRACUNIT * 8
	local stun = S_PLAY_STUN
	local B = CBW_Battle -- BattleMod!
	
	-- Call this for interactions with projectile owner's opponent.
	local function DoSnowballHit()
		if B then B.PlayerCreditPusher(pmo.player, snowballpmo) end
		if pmo.player.battle_def then -- Defense.
			B.ResetPlayerProperties(pmo.player, false, false)
			S_StartSound(pmo, sfx_s3k44)
			
			if P_IsObjectOnGround(pmo) then
				P_InstaThrust(pmo, snowballspeedang, snowball.scale * xythrust + snowballxyspeed)
				pmo.state = S_PLAY_SKID
			else
				xythrust = 5
				
				pmo.momz = $/2
				P_SetObjectMomZ(pmo, zthrust + snowballzspeed / CBW_Battle.WaterFactor(pmo), true)
				P_InstaThrust(pmo, snowballspeedang, snowball.scale * xythrust + snowballxyspeed)
				pmo.state = S_PLAY_FALL
			end
			
			-- Do uncurling/skidding.
			local time = xythrust
			local angle = R_PointToAngle2(0, 0, pmo.momx, pmo.momy)
			local recoilthrust = R_PointToDist2(0, 0, pmo.momx, pmo.momy)
			B.DoPlayerFlinch(pmo.player, xythrust, angle, recoilthrust)
		else -- Vulnerable.
			S_StartSound(pmo, sfx_s3k56)
			
			if pmo.state == stun then return end -- Do NOT permit additional hits if opponent is stunned.
			
			if P_IsObjectOnGround(pmo) then
				P_InstaThrust(pmo, snowballspeedang, xythrust * snowball.scale + snowballxyspeed)
				pmo.state = S_PLAY_SKID
				pmo.player.skidtime = xythrust
			else
				xythrust = 5
				
				pmo.momz = $/2
				P_InstaThrust(pmo, snowballspeedang, xythrust * snowball.scale + snowballxyspeed)
				P_SetObjectMomZ(pmo, zthrust + snowballzspeed / CBW_Battle.WaterFactor(pmo), false)
				pmo.state = S_PLAY_STUN
			end
			
			snowballxyspeed = $ / FRACUNIT
			
			pmo.player.powers[pw_nocontrol] = xythrust + snowballxyspeed
			pmo.player.pflags = $ & ~(PF_JUMPED|PF_THOKKED|PF_SPINNING)
			pmo.player.drawangle = angletosnowball
		end
	end
	
	-- Relegate this hook to interactions with players.
	if not(pmo and pmo.valid) then return end -- No mobj.
	if not(pmo.player) then return end -- This mobj isn't a player.	
	if not(snowball and snowball.valid and snowball.type == MT_SNOWBALL) then return end -- It MUST be a snowball and MUST exist.
	if not(snowball.flags&MF_MISSILE) then return end -- Snowball is dead.
	if not(snowballpmo and snowballpmo.type == MT_PLAYER) then return end -- Owner must be a player.
	
	-- Players.
	if not CBW_Battle.MyTeam(snowballpmo.player, pmo.player) then
		DoSnowballHit()
		return false
	end
	return nil
end

-- Spin tap ability.
local function DoSnowball(mo,doaction)
	-- Locals.
	local p = mo.player
	local basezspeed = 4 * p.mo.scale
	local zspeed = p.mo.momz/5

	-- Behaviour.
	p.actiontext = "Throw Snowball"
	p.actionrings = 1
	local cooldown = p.rings and TICRATE/5 or TICRATE

	if doaction == 1 then
		local snowball = P_SPMAngle(p.mo, MT_SNOWBALL, p.mo.angle)
		if snowball and snowball.valid then
			snowball.colorized = true
			snowball.color = SKINCOLOR_WHITE
			P_SetObjectMomZ(snowball, basezspeed + zspeed)
			snowball.momx = $*2+mo.momx
			snowball.momy = $*2+mo.momy
			snowball.scale = $*2
		end
		S_StartSound(p.mo, sfx_thok)
		CBW_Battle.PayRings(p)
		CBW_Battle.ApplyCooldown(p,cooldown)
	end
end

local iclynloaded = false
local iclynload = function()
	if CBW_Battle and skins["iclyn"] and not iclynloaded then
		iclynloaded = true
		CBW_Battle.SkinVars["iclyn"] = {
			weight = 80,
			special = DoSnowball
		}
	end
end

-- Hook it up.
addHook("PlayerThink", iclynload)
addHook("ShouldDamage", SnowballDamage, MT_PLAYER)