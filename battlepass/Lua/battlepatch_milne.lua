local LANCETIME = TICRATE/2
local LANCECHARGETIME = TICRATE/6
local startcrystallance = function(player)
	S_StopSoundByID(player.mo, sfx_crythr)
	S_StartSound(player.mo, sfx_mllnc1)
	player.crystallance = LANCETIME+LANCECHARGETIME
	player.mo.angle = player.mo.angle
	player.drawangle = player.mo.angle
	player.pflags = $&~PF_STARTJUMP
	player.milnespringtime = 0
	
	local time = LANCECHARGETIME*3/2
	local i = 0 while i < 16 do
		local explode = P_SpawnMobjFromMobj(player.mo,
		P_ReturnThrustX(nil, player.mo.angle, -4*skins[player.mo.skin].radius),
		P_ReturnThrustY(nil, player.mo.angle, -4*skins[player.mo.skin].radius),
		player.height/2,MT_SHATTERCRYSTAL)
		if explode and explode.valid then
			explode.flags = $|MF_NOGRAVITY
			explode.scale = player.mo.destscale*3/2
			explode.fuse = time
			explode.angle = (ANGLE_22h*i)+ANGLE_180
			explode.rollangle = FixedAngle(P_RandomKey(360)*FRACUNIT)
			explode.threshold = P_RandomKey(2)
			P_InstaThrust(explode,explode.angle,16*FRACUNIT)
			explode.momz = explode.momx+(P_GetMobjGravity(explode)*-4)
			P_InstaThrust(explode, player.mo.angle+ANGLE_90,explode.momy)
			
			//The unique stuff
			P_SetOrigin(explode, explode.x+explode.momx*time,
			explode.y+explode.momy*time, explode.z+explode.momz*time)
			explode.momx = $*-1
			explode.momy = $*-1
			explode.momz = $*-1
		end
		i = $+1
	end
end

local crystallance = function(mo,doaction)
	local player = mo.player
	player.actiontext = "Crystal Lance"
	player.actionrings = 10

	if player.crystallance then
		player.actionrings = 0
		player.actiontext = "\130Crystal Lance"
		return
	end
	if doaction == 1 then
		CBW_Battle.PayRings(player)
		CBW_Battle.ApplyCooldown(player,2*TICRATE)
		startcrystallance(player)
	end
end
local function GarbagePriority3(player)
	if player.mo.state == S_PLAY_SPINDASH then
		CBW_Battle.SetPriority(player,1,1,nil,1,1,"twister thok attack")
	end
end

local milnebattle = function(player)
	--battlemod milne check
	if not (CBW_Battle
	and player.mo
	and player.mo.valid
	and player.mo.skin == "milne")
	then
		return
	end
	--prevent triggering crystallance through the usual means
	player.milne1tapping = false
	player.milne1tapready = false
	if player.weapondelay then
		player.pflags = $|PF_SPINDOWN
	end
	--uncling on exhaust
	if not player.exhaustmeter then
		player.climbing = 0
	end
end
addHook("PlayerThink",milnebattle)

local milneloaded = false
local milneload = function()
	if CBW_Battle and skins["milne"] and not milneloaded then
		milneloaded = true
		CBW_Battle.SkinVars["milne"] = {
			weight = 115,
			func_priority_ext = GarbagePriority3,
			special = crystallance
		}
	end
end
addHook("ThinkFrame", milneload)

addHook("MobjSpawn",function(mo)
	mo.hit_sound = sfx_shattr
	mo.blockable = 1
	mo.block_stun = 4
	mo.block_sound = sfx_shattr
	mo.block_hthrust = 2
	mo.block_vthrust = 1
end, MT_THROWNCRYSTAL)