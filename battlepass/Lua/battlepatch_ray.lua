
local B = CBW_Battle

local glidefix = function(flag, toucher)
	local player = toucher.player
	if player and toucher.rayglidefix then
		--cap horizontal momentum to player's max speed
		local count = 0
		for i=1, 100 do
			if FixedHypot(toucher.momx, toucher.momy) <= player.normalspeed then break end
			local speedangle = R_PointToAngle2(0, 0, toucher.momx, toucher.momy) 
			P_Thrust(toucher, speedangle, -toucher.scale)
			count = i
		end
		--cap vertical momentum to player's jump height
		local jumpheight = FixedMul(player.jumpfactor, toucher.scale)
		toucher.momz = (P_MobjFlip(toucher) > 0) and min($,jumpheight) or max($,-jumpheight)
	end
end
addHook("TouchSpecial", glidefix, MT_REDFLAG)
addHook("TouchSpecial", glidefix, MT_BLUEFLAG)

local isray = function(player)
	return (player and player.mo and player.mo.valid and player.mo.skin == "ray")
end

local glidefix2 = function(player)
	--glide cancel timer
	if player.mo.state == S_PLAY_GLIDE then
		player.mo.rayglidefix = TICRATE/2
	else
		player.mo.rayglidefix = $ and $-1 or 0
	end
end

local ray_defFix = function(player)
	local st_burst = 3
	local machTornado_Finished = (player.actionstate == st_burst)
	local hasSpinDefense = (player.powers[pw_strong] & (STR_ANIM|STR_ATTACK|STR_WALL|STR_CEILING))

	if hasSpinDefense and (machTornado_Finished) then
		player.powers[pw_strong] = $ & ~(STR_ANIM|STR_ATTACK|STR_WALL|STR_CEILING) --Remove spin defense
	end
end

addHook("PlayerThink", function(player)
	if not(isray(player)) then
		return
	end

	glidefix2(player)

	if not(B) then
		return
	end

	ray_defFix(player)
end)
