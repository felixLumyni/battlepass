local GLIDE_LAUNCH = freeslot("sfx_kxgl1")
local GLIDE_ACTIVE = freeslot("sfx_kxgl2")
local SKIN = "knuckles"
local selfisenemy = false

if not(sfx_nullba) then
    sfxinfo[freeslot("sfx_nullba")].caption = "/" --Generic Mute SFX with no caption
end

sfxinfo[GLIDE_LAUNCH].caption = "/"
sfxinfo[GLIDE_ACTIVE].caption = "\x82".."GLIDING".."\x80"


local B = CBW_Battle

local teamSound = B.teamSound or function(source, player, soundteam, soundenemy, vol, selfisenemy)
	for otherplayer in players.iterate do
		if player and otherplayer and B.MyTeam(player, otherplayer)
			and not (selfisenemy and source and source.player and source.player == player)
		then
			S_StartSoundAtVolume(source, soundteam, vol, otherplayer)
		else
			S_StartSoundAtVolume(source, soundenemy, vol, otherplayer)
		end
	end
end

local isKnux = function(player)
    return player and player.mo and player.mo.valid and player.mo.skin == SKIN
end

addHook("PlayerThink", function(player)
    if not(isKnux(player)) then
        return
    end

    local gliding = (player.pflags & PF_GLIDING)
    local glidelaunch = (gliding and (player.glidetime < 1))

    if gliding then
        if glidelaunch then
            teamSound(player.mo, player, sfx_nullba, GLIDE_LAUNCH, 255, selfisenemy)
        end
        if not(S_SoundPlaying(player.mo, GLIDE_ACTIVE)) then
            teamSound(player.mo, player, sfx_nullba, GLIDE_ACTIVE, 255, selfisenemy)
        end
    else
        S_StopSoundByID(player.mo, GLIDE_ACTIVE)
        S_StopSoundByID(player.mo, GLIDE_ACTIVE)
    end
end)