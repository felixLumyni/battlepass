--- prevent surges from having properties while in spectator
local buh = function(p)
	if p.spectator and p.stt then
		p.stt.eleccharging = 0 --max 105
		p.stt.fullcharge = false
		p.stt.homer = false
		p.stt.cancelhomer = 0
		p.stt.voltjump = 0
		p.stt.voltdash = 0
		p.stt.supercharge = 0
		p.stt.voltframe = A
		p.stt.trailframe = A
		p.stt.newcharge = false
		p.stt.egirl = false
		p.stt.battlehoming = 0
		p.stt.killaura = false
	end
end
addHook("PlayerThink", buh)