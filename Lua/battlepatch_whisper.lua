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
	silv_TKextra[MT_WHISPER_ROCKET] =	{
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
    if player.mo.state == S_PLAY_MELEE then 
        CBW_Battle.SetPriority(player,1,0,"amy_melee",2,3,"blue cube hammer")
     end	
     if player.mo.state == S_PLAY_GLIDE then 
        CBW_Battle.SetPriority(player,0,0,"tails_fly",0,2,nil)
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
    player.actiontext = "Reload ("..player.whisperammo.."/"..maxammo..")"
	player.actionrings = maxammo
    if doaction == 1 then
        if player.rings >= player.actionrings and not player.actioncooldown then
            player.whisperammo = maxammo
            CBW_Battle.PayRings(player, player.actionrings)
            CBW_Battle.ApplyCooldown(player, reloadtime)
        elseif not player.actioncooldown then --not enough rings
            player.whisperammo = min(maxammo, $ + maxammo/2)
            CBW_Battle.PayRings(player, player.actionrings)
            CBW_Battle.ApplyCooldown(player, reloadtime)
        end
    end
end

local whisperammothinker = function()
    for p in players.iterate do
        local WHISPERSTARTLAG = 7 --taken from whisper's main.lua
        local WHISPERCHARGE = TICRATE*7/10 --^ same thing
        if p.whisperammo == nil then
            p.whisperammo = CV_FindVar("whisperbattle_maxammo").value
        end
        local rocketcost = CV_FindVar("whisperbattle_rocketcost").value
        local lasercost = CV_FindVar("whisperbattle_lasercost").value
        local hammercost = CV_FindVar("whisperbattle_hammercost").value
        local sawcost = CV_FindVar("whisperbattle_sawcost").value
        --pink saw
        if p.whispersaw and p.whispersaw.valid and not p.whispersaw.ammotrigger then
            p.whispersaw.ammotrigger = true
            if p.whisperammo >= sawcost and not p.actioncooldown then
                p.whisperammo = $-sawcost
            else
                P_RemoveMobj(p.whispersaw)
                S_StopSoundByID(p.mo, mobjinfo[MT_WHISPER_SAW].seesound)
                if not p.actioncooldown then S_StartSound(p.mo, sfx_noring, p) end
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
                p.whisperammo = $-hammercost
            else
                P_RemoveMobj(p.whisperhammer)
                S_StopSoundByID(p.mo, sfx_wscub3)
                if not p.actioncooldown then S_StartSound(p.mo, sfx_noring, p) end
                p.whisperhammer = nil
                p.mo.momx = p.mo.whispermomx
                p.mo.momy = p.mo.whispermomy
                p.mo.momz = p.mo.whispermomz
                p.mo.angle = p.mo.whisperangle
                p.mo.state = S_PLAY_SPRING
            end
        end
        --for future failed saw/hammer attempts
        if p.mo and p.mo.skin == "whisper" then
            p.mo.whispermomx = p.mo.momx
            p.mo.whispermomy = p.mo.momy
            p.mo.whispermomz = p.mo.momz
            p.mo.whisperangle = p.mo.angle
        end
        --gun (orange rocket or cyan laser)
        if not (p.cmd.buttons & BT_SPIN) and p.whispercharge and p.whispercharge >= WHISPERSTARTLAG then
            --jammed
            if p.actioncooldown then
                p.whispercharge = 0
                return --dont try to use ammo!!!!
            end
            --must have tried to fire
            local preammo = p.whisperammo or 0
            p.whisperammo = $ or 0
            if p.whispercharge >= WHISPERCHARGE then
                p.whisperammo = $-rocketcost
            else
                p.whisperammo = $-lasercost
            end
            --ammo went in the negatives, so not enough ammo. cancel the attempt
            if p.whisperammo < 0 then
                p.whisperammo = preammo
                p.whispercharge = 0
                S_StartSound(p.mo,sfx_noring,p)
            end
        end
    end
end
addHook("PreThinkFrame", whisperammothinker)

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
addHook("ThinkFrame", loadwhisperbattle)

local whisperbattlespawn = function(player)
    player.whisperammo = CV_FindVar("whisperbattle_maxammo").value
end
addHook("PlayerSpawn", whisperbattlespawn)

--whispers cant parry their own blast radius lol
addHook("ShouldDamage", function(mo, mobj)
	if mobj and mobj.type == MT_WHISPER_ROCKET and (mobj.flags2 & MF2_EXPLOSION)
    and mobj.target == mo and mo.player then
        mo.player.guard = 0
        mo.player.guardtics = 0
        mo.player.airdodge = -1
        mo.player.intangible = false
        mo.player.scorepenalty = true
        return true
	end
end)

--projectile names
mobjinfo[MT_WHISPER_LASER].name = "cyan laser"
mobjinfo[MT_WHISPER_ROCKET].name = "orange rocket"
mobjinfo[MT_WHISPER_SAW].name = "pink saw"

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
addHook("TouchSpecial",whisperbruh,MT_REDFLAG)
addHook("TouchSpecial",whisperbruh,MT_BLUEFLAG)