Pointshop2.PlayerJoins = class( "PlayerJoinStreak" )
Pointshop2.PlayerJoins.static.DB = "Pointshop2"

Pointshop2.PlayerJoins.static.model = {
	tableName = "ps2_plyjoinstreak",
	fields = {
		playerId = "optKey",
        joinedTime = "createdTime"
	}
}

Pointshop2.PlayerJoins:include( DatabaseModel )

-- Check last week's joins and find out how many are in the correct order to calculate streak
-- streak means how many days the player has been online for consecutively within the period specified
function Pointshop2.PlayerJoins.static.getCurrentStreak( ply, periodInDays )
    return Promise.Resolve( )
    :Then( function( )
        local timePart
        if Pointshop2.DB.CONNECTED_TO_MYSQL then
            timePart = "NOW() - INTERVAL " .. periodInDays .. " DAY"
        else
            timePart = "datetime('now', '-" .. periodInDays .. "days')"
        end
        return Pointshop2.PlayerJoins.getDbEntries( Format( "WHERE playerId = %i AND joinedTime >= %s ORDER BY joinedTime DESC", ply.kPlayerId, timePart ) )
    end )
    :Then( function( joins )
        local streak = 1
        local expected, previous

        for k, v in ipairs( joins ) do
            if k == 1 then
                expected = os.date( "%x", v.joinedTime - 24 * 3600 )
				previous = os.date( "%x", v.joinedTime )
                continue
            end

			-- Possibility of multiple joins per day
			local current = os.date("%x", v.joinedTime )
			if previous == current then
				continue
			end
			previous = current

			-- Check if logged in on day before current
            if current == expected then
                streak = streak + 1
                expected = os.date( "%x", v.joinedTime - 24 * 3600 )
            else
                break
            end
        end

        return streak
    end )
end
