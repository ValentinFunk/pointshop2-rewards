local PANEL = {}

function PANEL:Init( )
	self:SetSkin( Pointshop2.Config.DermaSkin )
	self:SetSize( 512, 570 )
	self:MakePopup( )
	self:Center( )
	self:SetTitle( "Rewards Configurator" )

    self.infoPanel = vgui.Create( "DInfoPanel", self )
	self.infoPanel:Dock( TOP )
	self.infoPanel:SetInfo( "Daily Rewards", "Players can claim rewards daily for logging on. Within a week rewards can be configured to get bigger so players are even more motivated to join your server daily." )
	self.infoPanel:DockMargin( 0, 0, 0, 10 )

	self.itemPicker = vgui.Create( "DCalendarItemPicker", self )
    self.itemPicker:InitDays( Pointshop2.Rewards.DAYS_TRACKED )
	self.itemPicker:Dock( FILL )

	self.saveButton = vgui.Create( "DButton", self )
	self.saveButton:SetText( "Save" )
	self.saveButton:SetSize( 80, 25 )
	self.saveButton:PerformLayout( )
	self.saveButton:Paint( 10, 10 )
	self.saveButton:Dock( BOTTOM )
	function self.saveButton.DoClick( )
		self.settings["DailyRewards.Items"] = self.itemPicker:GetSaveData( )

		for i = 1, Pointshop2.Rewards.DAYS_TRACKED do
			if not self.settings["DailyRewards.Items"][i] then
				return Derma_Message( "Please set a reward for each day. Day " .. i .. " is missing a reward.", "Error" )
			end
		end

		Pointshop2View:getInstance( ):saveSettings( self.mod, "Shared", self.settings )
		self:Close( )
	end
end

function PANEL:SetModule( mod )
	self.mod = mod
end

function PANEL:SetData( data )
	self.settings = data

	self.itemPicker:LoadSaveData( self.settings["DailyRewards.Items"] )
end

vgui.Register( "DRewardsConfigurator", PANEL, "DFrame" )
