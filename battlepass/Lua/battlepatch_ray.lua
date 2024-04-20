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

local glidefix2 = function(player)
	--bm ray check
	local mo = player.mo
	if not(CBW_Battle and mo and mo.valid and mo.skin == "ray") then
		return
	end
	--glide cancel timer
	if mo.state == S_PLAY_GLIDE then
		mo.rayglidefix = TICRATE/2
	else
		mo.rayglidefix = $ and $-1 or 0
	end
end
addHook("PlayerThink", glidefix2)