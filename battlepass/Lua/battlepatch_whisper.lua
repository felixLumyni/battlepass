states[freeslot("S_RELOAD")] = {
	sprite = freeslot("SPR_RELO"),
	frame = FF_TRANS30,
	tics = 8,
	nexstate = S_NULL
}

sfxinfo[freeslot("sfx_lstsht")].caption = "Last shot"
sfxinfo[freeslot("sfx_noammo")].caption = "No ammo"
sfxinfo[freeslot("sfx_rlstrt")].caption = "Reloading..."
sfxinfo[freeslot("sfx_rlfnsh")].caption = "Reload finished"

-- No fun allowed (by default)
local funny = false

local function setFunny(value)
	funny = value
	--print("Funny is now " + value)
	if skins["whisper"] == nil then
		--print("WARNING: Whisper has not been loaded yet")
		return
	end
	if _G.silv_TKextra == nil then 
		--print("WARNING: Silver has not been loaded yet") 
		return
	end
	if not silv_TKextra[MT_WHISPER_LASER] then 
		silv_TKextra[MT_WHISPER_LASER] = {}
	end
	if not silv_TKextra[MT_WHISPER_ROCKET] then 
		silv_TKextra[MT_WHISPER_ROCKET] = {}
	end
	-- This kinda reads like "no grab is not funny"
	-- makes it hilarious lmfao
	silv_TKextra[MT_WHISPER_LASER].nograb = not funny
	-- Destroy rocket on grab
	silv_TKextra[MT_WHISPER_ROCKET] = {
		grabf = function(mo)
		    P_KillMobj(mo)
	    end
	}
end

addHook("MapLoad", function()
	setFunny(funny)
end)

addHook("NetVars", function(net)
	funny = net(funny)
	setFunny(funny)
end)

CV_RegisterVar({
	name = "wrsft_enabled",
	defaultValue = 1,
	flags = CV_CALL | CV_NETVAR,
	PossibleValue = CV_OnOff,
	func = function(cv)
		setFunny(cv.value == 0)
	end
})

-- functions taken from whisper's battle lua
local WhisperFunction = function(player)
    if player.powers[pw_super] or player.powers[pw_invulnerability] then
        CBW_Battle.SetPriority(player,0,99,nil,0,0,"protected")
        if player.mo.state == S_PLAY_MELEE then
            CBW_Battle.SetPriority(player,0,99,"amy_melee",2,99,"blue cube hammer")
        end
    elseif player.mo.state == S_PLAY_GLIDE then
        CBW_Battle.SetPriority(player,0,0,"tails_fly",0,3,"umbrella")
    elseif player.mo.state == S_PLAY_MELEE then 
        CBW_Battle.SetPriority(player,0,0,"amy_melee",2,0,"blue cube hammer")
    else
        CBW_Battle.SetPriority(player,0,0,nil,0,0,"defenseless")
    end
end

local WhisperExhaust = function(player)
    if player.whisperfloat or player.secondjump == 1 then
        if not player.prevhover then
            player.exhaustmeter = max(0,$-FRACUNIT/20)
        end
        player.prevhover = true
        local maxtime = 3*TICRATE
        player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
        if player.exhaustmeter <= 0 then
            player.secondjump = 0
            player.whisperfloat = 0
            player.glidetime = 42
            if player.mo.state == S_PLAY_GLIDE then
                player.mo.state = S_PLAY_TWINSPIN
            end
        end
        return true
    else
        player.prevhover = false
    end
end

-- more battlemod tweaks by lumy
CV_RegisterVar({"whisperbattle_maxammo", 20, CV_NETVAR|CV_SHOWMODIF, {MIN = 1, MAX = 255}})
CV_RegisterVar({"whisperbattle_rocketcost", 6, CV_NETVAR|CV_SHOWMODIF, {MIN = 1, MAX = 255}})
CV_RegisterVar({"whisperbattle_lasercost", 1, CV_NETVAR|CV_SHOWMODIF, {MIN = 1, MAX = 255}})
CV_RegisterVar({"whisperbattle_hammercost", 2, CV_NETVAR|CV_SHOWMODIF, {MIN = 1, MAX = 255}})
CV_RegisterVar({"whisperbattle_sawcost", 3, CV_NETVAR|CV_SHOWMODIF, {MIN = 1, MAX = 255}})

local reload = function(mo, doaction)
    local reloadtime = TICRATE*3/2
    local maxammo = CV_FindVar("whisperbattle_maxammo").value
	local player = mo.player
    if player.whisperammo == nil then
        player.whisperammo = maxammo
    end
    local color = S_SoundPlaying(mo, sfx_noammo) and "\143" or ""
    player.actiontext = color+"Reload ("..player.whisperammo.."/"..maxammo..")"
	player.actionrings = maxammo
    if doaction == 1 then
        if player.rings >= player.actionrings and not player.actioncooldown then
            player.whisperammo = maxammo
            CBW_Battle.PayRings(player, player.actionrings)
            CBW_Battle.ApplyCooldown(player, reloadtime)
            S_StartSound(mo, sfx_rlstrt, player)
        elseif not player.actioncooldown then --not enough rings
            player.whisperammo = min(maxammo, $ + maxammo/2)
            CBW_Battle.PayRings(player, player.actionrings)
            CBW_Battle.ApplyCooldown(player, reloadtime)
            S_StartSound(mo, sfx_rlstrt, player)
        end
    end
    if (player.actioncooldown) then
        player.normalspeed = skins[mo.skin].normalspeed/2
        mo.whisperspeedpenalty = true
        if not (player.reloadobj and player.reloadobj.valid) then
            local reload = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_THOK) 
		    reload.state = S_RELOAD
		    player.reloadobj = reload
        else
            P_MoveOrigin(player.reloadobj, mo.x, mo.y, mo.z)
            player.reloadobj.tics = player.actioncooldown
            player.reloadobj.fuse = player.reloadobj.tics
            player.reloadobj.rollangle = $-ANG10
        end
    elseif (mo.whisperspeedpenalty) then
        if player.reloadobj and player.reloadobj.valid then
            P_RemoveMobj(player.reloadobj)
        end
        S_StartSound(mo, sfx_rlfnsh, player)
        player.normalspeed = skins[mo.skin].normalspeed
        mo.whisperspeedpenalty = false
    end
end

local payammo = function(player, amount)
    player.whisperammo = $ - amount
    player.whisperammomove = 5
    if player.whisperammo == 0 then
        S_StartSound(player.mo, sfx_lstsht, player)
    end
end

local whisperammothinker = function() --laser and rocket
    local lasercost = CV_FindVar("whisperbattle_lasercost").value
    local rocketcost = CV_FindVar("whisperbattle_rocketcost").value
    for p in players.iterate do
        local WHISPERSTARTLAG = 7 --taken from whisper's main.lua
        local WHISPERCHARGE = TICRATE*7/10 --^ same thing
        if p.whisperammo == nil then
            p.whisperammo = CV_FindVar("whisperbattle_maxammo").value
        end
        if p.whisperammomove then
            p.whisperammomove = max($-1, 0)
        end
        --for future failed saw/hammer attempts
        if p.mo and p.mo.skin == "whisper" then
            p.mo.whispermomx = p.mo.momx
            p.mo.whispermomy = p.mo.momy
            p.mo.whispermomz = p.mo.momz
            p.mo.whisperangle = p.drawangle
        end
        --gun (orange rocket or cyan laser)
        if not (p.cmd.buttons & BT_SPIN) and p.whispercharge and p.whispercharge >= WHISPERSTARTLAG then
            --jammed
            if p.actioncooldown then
                p.whispercharge = 0
                continue --dont try to use ammo!!!!
            end
            --must have tried to fire
            local preammo = p.whisperammo or 0
            p.whisperammo = $ or 0
            if p.whispercharge >= WHISPERCHARGE then
                payammo(p, rocketcost)
            else
                payammo(p, lasercost)
            end
            --ammo went in the negatives, so not enough ammo. cancel the attempt
            if p.whisperammo < 0 then
                p.whisperammo = preammo
                p.whispercharge = 0
                S_StartSound(p.mo,sfx_noammo,p)
            end
        end
        --hi
    end
end
addHook("PreThinkFrame", whisperammothinker)

local whisperstatethinker = function() --spike and hammer
    local hammercost = CV_FindVar("whisperbattle_hammercost").value
    local sawcost = CV_FindVar("whisperbattle_sawcost").value
    for p in players.iterate do
        --pink saw
        if p.whispersaw and p.whispersaw.valid and not p.whispersaw.ammotrigger then
            p.whispersaw.ammotrigger = true
            if p.whisperammo >= sawcost and not p.actioncooldown then
                payammo(p, sawcost)
            else
                P_RemoveMobj(p.whispersaw)
                S_StopSoundByID(p.mo, mobjinfo[MT_WHISPER_SAW].seesound)
                if not p.actioncooldown then S_StartSound(p.mo, sfx_noammo, p) end
                p.whispersaw = nil
                p.mo.momx = p.mo.whispermomx
                p.mo.momy = p.mo.whispermomy
                p.mo.momz = p.mo.whispermomz
            end
        end
        --blue hammer
        if p.whisperhammer and p.whisperhammer.valid and not p.whisperhammer.ammotrigger then
            p.whisperhammer.ammotrigger = true
            if p.whisperammo >= hammercost and not p.actioncooldown then
                payammo(p, hammercost)
            else
                P_RemoveMobj(p.whisperhammer)
                S_StopSoundByID(p.mo, sfx_wscub3)
                if not p.actioncooldown then S_StartSound(p.mo, sfx_noammo, p) end
                p.whisperhammer = nil
                p.mo.momx = p.mo.whispermomx
                p.mo.momy = p.mo.whispermomy
                p.mo.momz = p.mo.whispermomz
                p.drawangle = p.mo.whisperangle
                p.mo.state = p.mo.momz * P_MobjFlip(p.mo) > 0 and S_PLAY_SPRING or S_PLAY_FALL
            end
        end
        --hi
    end
end
addHook("PostThinkFrame", whisperstatethinker) --a lil hacky, but its so it doesnt look weird

local whisperbattleloaded = false
local loadwhisperbattle = function()
    if CBW_Battle and skins["whisper"] and not whisperbattleloaded then
        CBW_Battle.SkinVars["whisper"] = {
            flags = SKINVARS_GUARD,
            weight = 90,
            guard_frame = 0,
            func_exhaust = WhisperExhaust,
            func_priority_ext = WhisperFunction,
            special = reload,
            shields = 0
        }
        whisperbattleloaded = true
        --projectile names
        mobjinfo[MT_WHISPER_LASER].name = "cyan laser"
        mobjinfo[MT_WHISPER_ROCKET].name = "orange rocket"
        mobjinfo[MT_WHISPER_SAW].name = "pink saw"
    end
    for p in players.iterate do
        if p.scorepenalty then
            --player blasted themselves
            local penalty = (p.playerstate == PST_LIVE) and 50 or 100
            p.score = max(0,$-penalty)
            if p.preservescore then p.preservescore = max(0,$-penalty) end
            if p.ctfteam == 1 then redscore = max(0,$-penalty) end
            if p.ctfteam == 2 then bluescore = max(0,$-penalty) end
            p.scorepenalty = false
        end
        local mincubetime = TICRATE/2
        local maxcubetime = 3*TICRATE
        if p.mo and p.mo.whispercubed then
            p.whispercubetime = not($ == nil) and $+1 or 0
            if p.whispercubetime == maxcubetime-TICRATE then
                S_StartSound(nil, sfx_dwnind, p)
            elseif p.whispercubetime >= maxcubetime then
                WhisperUnCube(p.mo)
                P_DamageMobj(p.mo, nil)
            end
            if p.whispercubetime < mincubetime then
                p.pflags = $|PF_JUMPDOWN
            end
        else
            p.whispercubetime = 0
        end
    end
end
addHook("PostThinkFrame", loadwhisperbattle)

local whisperbattlespawn = function(player)
    player.whisperammo = CV_FindVar("whisperbattle_maxammo").value
end
addHook("PlayerSpawn", whisperbattlespawn)

--whispers cant parry their own blast radius lol
addHook("ShouldDamage", function(mo, mobj)
    if not (skins["whisper"]) then
        return
    end
    if mobj and mobj.type == MT_WHISPER_ROCKET and (mobj.flags2 & MF2_EXPLOSION)
    and mobj.target == mo and mo.player then
        if CBW_Battle and CBW_Battle.VersionNumber >= 10 then
            mo.player.guard = -1
        else --support v9
            mo.player.guard = 0
            mo.player.guardtics = 0
        end
        mo.player.airdodge = -1
        mo.player.intangible = false
        mo.player.scorepenalty = true
        return true
	end
end, MT_PLAYER)

local whisperbruh = function(flag, mo)
    if not(mo.player and mo.skin and mo.skin == "whisper") then return end
    if flag.type == MT_REDFLAG and mo.player.ctfteam == 1 then return end
    if flag.type == MT_BLUEFLAG and mo.player.ctfteam == 2 then return end
    if mo.state == S_PLAY_GLIDE or mo.state == S_PLAY_MELEE then
        mo.momx = $/2
        mo.momy = $/2
        mo.state = S_PLAY_SPRING
    end
end
addHook("TouchSpecial", whisperbruh, MT_REDFLAG)
addHook("TouchSpecial", whisperbruh, MT_BLUEFLAG)

local sawparry = function(target, inflictor, source, damage, damagetype)
	--battlemod whisper check
	if not (skins["whisper"] and CBW_Battle
	and inflictor
	and inflictor.valid
	and inflictor.type == S_WHISPER_SAW
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
addHook("ShouldDamage",sawparry,MT_PLAYER)

local function safeFreeslot(...)
    for _, item in ipairs({...}) do
        if rawget(_G, item) == nil then
            freeslot(item)
        end
    end
end

safeFreeslot("MT_WHISPER_LASER")

addHook("MobjMoveBlocked", function(mobj, thing)
    if mobj.bounced then
        P_KillMobj(mobj)
    else
        mobj.bounced = true
    end
end, MT_WHISPER_LASER)

local ammohud = function(v, player, cam)
    if not (player.mo and player.mo.skin == "whisper") then
        return
    end
    local c = hudinfo[HUD_LIVES].x
    local r = hudinfo[HUD_LIVES].y + (player.whisperammomove or 0)
    if cam.chase then
        c = $ + 64
        r = $ - 8
    else
        r = $ - 32
    end
    local a = v.cachePatch("WMETER")
    local z = V_HUDTRANS | V_PERPLAYER | V_SNAPTOLEFT | V_SNAPTOBOTTOM
    local y = v.getColormap(TC_DEFAULT, player.whisperguncolor)
    v.draw(c, r, a, z, y)
    local maxammo = CV_FindVar("whisperbattle_maxammo").value
    for i=1, maxammo do
        local cc = (c+26) + ((i-1)*5)
        local rr = r + 4
        local aa = v.cachePatch("WAMMO")
        local zz = z
        if S_SoundPlaying(player.mo,  sfx_noammo) then
            zz = ($ &~ V_HUDTRANS) | V_HUDTRANSHALF
        end
        local yy = v.getColormap(TC_DEFAULT, (player.whisperammo >= i and player.whisperguncolor or SKINCOLOR_CARBON))
        v.draw(cc, rr, aa, zz, yy)
    end
end
hud.add(ammohud, "game")