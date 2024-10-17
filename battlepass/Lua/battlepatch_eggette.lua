local function safeFreeslot(...)
    for _, item in ipairs({...}) do
        if rawget(_G, item) == nil then
            freeslot(item)
        end
    end
end

safeFreeslot("MT_EGGS_TAILSDOLL") -- Gotta love addon load order

-- NOTE: If porting this to eggette, please use MobjSpawn instead
addHook("MobjThinker",function(mo)
	if (not mo.eggettefixed) and mo.tracer and mo.tracer.valid then
		mo.scale = mo.tracer.scale
		mo.eggettefixed = true
	end
end, MT_EGGS_TAILSDOLL)