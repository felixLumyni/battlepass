COM_AddCommand("discord", function(player, scale)
    CONS_Printf(player, "\x8C"+(discord_link or "No discord invite available."))
end)