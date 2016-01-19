Pointshop2.RewardUses = class( "RewardUses" )
Pointshop2.RewardUses.static.DB = "Pointshop2"

Pointshop2.RewardUses.static.model = {
	tableName = "ps2_rewarduses",
	fields = {
		player = "optKey",
		date = "createdTime",
	}
}

Pointshop2.RewardUses:include( DatabaseModel )

function Pointshop2.RewardUses.static.getLastest( ply, periodInDays )
	return Promise.Resolve( )
	:Then( function( )
		if Pointshop2.DB.CONNECTED_TO_MYSQL then
			return Pointshop2.RewardUses.getDbEntries( Format( "WHERE player = %i AND date >= NOW() - INTERVAL %i DAY ORDER BY date DESC", ply.kPlayerId, periodInDays ) )
		else
			return Pointshop2.RewardUses.getDbEntries( Format( "WHERE player = %i AND date >= datetime('now', '-%i days') ORDER BY date DESC", ply.kPlayerId, periodInDays ) )
		end
	end )
end
