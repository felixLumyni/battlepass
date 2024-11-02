local function safeFreeslot(...)
    for _, item in ipairs({...}) do
        if rawget(_G, item) == nil then
            freeslot(item)
        end
    end
end

safeFreeslot("MT_CRAWLAMISSILE", "MT_JETJAWMISSILE") -- Gotta love addon load order

local function badnik_goop(mobj) -- ty metakimi (i modified it a bit to add effects)
    if mobj.time > 270 then
        local explode = P_SpawnMobjFromMobj(mobj,0,0,0,MT_EXPLODE)
        S_StartSound(explode, sfx_s3k3d)
        P_RemoveMobj(mobj)
    end
end

for n = MT_CRAWLAMISSILE,MT_JETJAWMISSILE
    addHook("MobjThinker",badnik_goop,n)
end