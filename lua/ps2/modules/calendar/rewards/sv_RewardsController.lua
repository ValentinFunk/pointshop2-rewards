RewardsController = class( "RewardsController" )
RewardsController:include( BaseController )

function RewardsController:canDoAction( ply, action )
	if action == "ClaimDay" then
		return Promise.Resolve( )
	end
	return Promise.Reject( )
end

local running = { }
hook.Add( "PlayerDisconnected", "RewardsController:handleDisconnected", function( ply )
	running[ply] = false
end )
function RewardsController:ClaimDay( ply )
	return Promise.Resolve()
	:Then( function( )
		if ply._RewardsLock then
			return Promise.Reject( 'Player already has a pending claim' )
		end

		ply._RewardsLock = true
		return WhenAllFinished{
		  Pointshop2.PlayerJoins.static.getCurrentStreak( ply, Pointshop2.Rewards.DAYS_TRACKED ),
		  Pointshop2.RewardUses.getLastest( ply, 1 )
		}
	end )
	:Then( function( streak, latestUses )
		if #latestUses > 0 and os.date( "%x", latestUses[#latestUses].date ) == os.date( "%x", system.SteamTime() ) then
			return Promise.Reject( "You have already claimed the reward!" )
		end

		if not ply:PS2_HasInventorySpace( 1 ) then
			return Promise.Reject( "Your inventory is full. Please free a slot" )
		end

		local factory = Pointshop2.Rewards.GetFactoryForStreak( streak )
		if not factory then
			KLogf( 2, "Rewards are not configured properly! Please set a reward for each day!" )
			return Promise.Reject( "Invalid Factory - has the reward system been configured?" )
		end

		return factory:CreateItem( true )
	end )
	:Then( function( item )
		local price = item.class:GetBuyPrice( ply )
		item.purchaseData = {
			time = os.time( ),
			origin = "Rewards"
		}
		if price.points then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "points"
		elseif price.premiumPoints then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "premiumPoints"
		else
			item.purchaseData.amount = 0
			item.purchaseData.currency = "points"
		end

		local use = Pointshop2.RewardUses:new( )
		use.player = ply.kPlayerId

		local transaction = Pointshop2.DB.Transaction()
		transaction:begin()
		transaction:add(use:getSaveSql())
		transaction:add(item:getSaveSql()) -- Create Item
		return transaction:commit():Then(function()
			if Pointshop2.DB.CONNECTED_TO_MYSQL then
				return Pointshop2.DB.DoQuery( "SELECT LAST_INSERT_ID() as id" )
			else
				return Pointshop2.DB.DoQuery( "SELECT last_insert_rowid() as id" )
			end
		end ):Then( function( id )
			print("id", id)
			item.id = tonumber(id[1].id)
			return item
		end):Then( Promise.Resolve, function( err )
			LibK.GLib.Error( "Pointshop2Controller:internalBuyItem - Error running sql " + tostring( err ) )
			return Pointshop2.DB.DoQuery( "ROLLBACK" ):Then( function( )
				return Promise.Reject( "Error!" )
			end )
		end )
	end )
	:Then( function( item )
		return ply.PS2_Inventory:addItem( item )
		:Then( function( )
			KLogf( 4, "Player %s used Rewards got item %s", ply:Nick( ), item:GetPrintName( ) or item.class.PrintName )
			item:OnPurchased( )
			Pointshop2Controller:getInstance( ):startView( "Pointshop2View", "displayItemAddedNotify", ply, item )
			return item
		end )
	end )
	:Then( function( )
		self:SendPlayerInfo( ply )
	end )
	:Always( function( )
		ply._RewardsLock = false
	end )
end

function RewardsController:SendPlayerInfo( ply )
	return WhenAllFinished{
		Pointshop2.PlayerJoins.static.getCurrentStreak( ply, Pointshop2.Rewards.DAYS_TRACKED ),
		Pointshop2.RewardUses.getLastest( ply, Pointshop2.Rewards.DAYS_TRACKED )
	}
	:Then( function( streak, rewardUses )
		-- Filter uses to return only relevant ones as map.
		local map = {}

		-- Get start of day of the first day of the streak
		local startDate = os.date( "*t", os.time( ) - ( streak - 1 ) * 3600 * 24 )
		startDate.hour = 0
		startDate.min = 0
		startDate.sec = 0
		startDate = os.time( startDate )

		for k, use in ipairs( rewardUses ) do
			use.date = tonumber( use.date )
			if use.date < startDate then
				continue
			end

			local day = LibK.ConvertTimeUnits( use.date - startDate, "seconds", "days" )
			day = math.floor( day ) + 1 -- 0 Day difference means first day
			map[day] = true
		end

		-- Send to player
		self:startView( "RewardsView", "ReceiveInfo", ply, streak, map )
	end )
end
Pointshop2.BootstrappedPromise:Then( function( )
	for k, v in pairs( player.GetAll( ) ) do
		RewardsController:getInstance( ):SendPlayerInfo( v )
	end
end )

-- Reset streak after fullfilled
function RewardsController:resetRunningStreak( ply ) 
	return Pointshop2.PlayerJoins.static.getCurrentStreak( ply, Pointshop2.Rewards.DAYS_TRACKED + 1 )
	:Then(function(countJoined) 
		if countJoined != Pointshop2.Rewards.DAYS_TRACKED + 1 then
			return
		end
		KLogf(4, "got stream of count %i, resetting", countJoined)

		-- Remove all but the current day
		local timePart
		if Pointshop2.DB.CONNECTED_TO_MYSQL then
            timePart = "NOW() - INTERVAL 1 MINUTE"
        else
            timePart = "datetime('now', '-1 minute')"
        end
		KLogf(4, "Reset where date  < %s", timePart)
		return Pointshop2.PlayerJoins.removeDbEntries("WHERE joinedTime <= " .. timePart .. " AND playerId = " .. ply.kPlayerId)
	end)
end

function RewardsController:PlayerJoined( ply )
	Pointshop2.DatabaseConnectedPromise:Done( function( ) -- Avoid errors if database not connected
		local join = Pointshop2.PlayerJoins:new( )
		join.playerId = ply.kPlayerId
		return join:save():Then( function( join )
			return self:resetRunningStreak( ply )
		end )
		:Then(function() 
			return Promise.Delay( 1 ) -- Delay sending stuff to avoid net issues
		end )
		:Then( function( )
			self:SendPlayerInfo( ply )
		end )
	end )
end

hook.Add( "LibK_PlayerInitialSpawn", "RewardsController_SendPlayerInfo", function( ply )
	RewardsController:getInstance( ):PlayerJoined( ply )
end )

-- Create artificial joins when a player is online over two periods
local lastCheck = os.date( "%x" )
function RewardsController:handleArtificialPlayerJoins( )
    local today = os.date( "%x" )
    if today != lastCheck then
        --date changed, force a join entry for all active players
        for k, v in pairs( player.GetAll( ) ) do
            local join = Pointshop2.PlayerJoins:new( )
            join.playerId = v.kPlayerId
            join:save( )
			:Then( function( ) 
				self:resetRunningStreak( v )
			end )
            :Then( function( )
                self:SendPlayerInfo( v )
            end )
        end
    end

    lastCheck = os.date("%x" )
end
timer.Create( "Pointshop2: RewardsController.handleArtificialPlayerJoins", 60, 0, function( )
	RewardsController:getInstance( ):handleArtificialPlayerJoins( )
end )
