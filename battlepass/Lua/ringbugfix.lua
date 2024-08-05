--shoutouts to: envch and SMS Alfredo
addHook("ShouldDamage", function(targ, inf, src, dmg, dmgtype)
	if not CBW_Battle then
		return --srb2 would cry because CBW_Battle.MyTeam is nil
	end
	if CBW_Battle.VersionNumber and CBW_Battle.VersionNumber >= 10 then
		return --v10 has this fix natively
	end
    if targ and targ.valid and targ.player
    and src and src.valid and src.player
    and CBW_Battle.MyTeam(targ.player, src.player)
        return false --don't try to give rings to ur teammate via missile
    end
end, MT_PLAYER)