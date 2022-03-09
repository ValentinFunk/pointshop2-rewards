local PANEL = {}
local text = [[Log on for consecutive days to get your daily rewards! Click on your current streak's box to receive the reward.
The day count resets if you miss being online on a day or have claimed all rewards.

Current logon streak: "]]
function PANEL:Init( )
	self:SetSkin( Pointshop2.Config.DermaSkin )
    self.infoPanel = vgui.Create( "DInfoPanel", self )
	self.infoPanel:Dock( TOP )
	self.infoPanel:SetInfo( "Daily Rewards", text .. RewardsView:getInstance( ):GetStreak( ) )
	self.infoPanel:DockMargin( 10, 10, 10, 10 )
    hook.Add( "Rewards_UpdateInfo", self.infoPanel, function( self, uses )
		self:SetInfo( "Daily Rewards", text .. RewardsView:getInstance( ):GetStreak( ) )
	end )

    local container = vgui.Create( "DPanel", self )
    container:DockMargin( 10, 0, 10, 10 )
    container:DockPadding( 10, 10, 10, 10 )
    container:Dock( FILL )
    -- Center child horizontally
    function container:PerformLayout( )
        self:GetChildren()[1]:SizeToChildren( false, true )
    end
    container:SetTall( 144 )
    Derma_Hook( container, "Paint", "Paint", "InnerPanel" )

    self.grid = vgui.Create( "DFixedGrid", container )
	self.grid:SetGutter( 10 )
	self.grid:SetColumnCount( 7 )
    self.grid.AutoTilesize = true
    self.grid:Dock( TOP )

    for i = 1, Pointshop2.Rewards.DAYS_TRACKED do
        local box = self.grid:Add( "DRewardsBox" )
        box:SetDay( i )
        if RewardsView:getInstance().uses then
            box:SetOpened( RewardsView:getInstance().uses[i] )
        end
    end
end

function PANEL:Paint( w, h )

end

vgui.Register( "DRewardsPanel", PANEL, "DPanel" )
Pointshop2:AddInventoryPanel( "Daily Rewards", "pointshop2/person25.png", "DRewardsPanel" )
