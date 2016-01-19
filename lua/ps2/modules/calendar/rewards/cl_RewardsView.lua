RewardsView = class( "RewardsView" )
RewardsView:include( BaseView )
RewardsView.static.controller = "RewardsController"

function RewardsView:ClaimDay( )
	return self:controllerTransaction( "ClaimDay" )
end

function RewardsView:GetUses( )
	return self.uses or {}
end

function RewardsView:GetStreak( )
	return self.streak or 1
end

function RewardsView:ReceiveInfo( streak, uses )
	self.uses = uses
	self.streak = streak
	hook.Run( "Rewards_UpdateInfo", uses )
end
