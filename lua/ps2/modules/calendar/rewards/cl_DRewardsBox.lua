local PANEL = {}

function PANEL:Init( )
	self:SetText( "" )
	self.day = 0

	self.label = vgui.Create( "DLabel", self )
	self.label:Dock( FILL )
	self.label:DockMargin( 10, 10, 10, 10 )
	self.label:SetFont( self:GetSkin().SmallTitleFont )
	self.label:SetContentAlignment( 3 )

	self.label2 = vgui.Create( "DLabel", self )
	self.label2:Dock( FILL )
	self.label2:DockMargin( 10, 10, 10, 10 )
	self.label2:SetFont( self:GetSkin().TextFont )
	self.label2:SetContentAlignment( 5 )
	self.label2:SetColor( Color( 0, 255,  0 ) )
	self.label2:SetText( "CLAIMED" )
	self.label2:SetVisible( false )

	hook.Add( "Rewards_UpdateInfo", self, function( self, uses )
		self:SetOpened( uses[tonumber(self.day)] )
	end )

	hook.Add( "PS2_OnSettingsUpdate", self, function( self )
		self:Update( )
	end )
end

function PANEL:SetOpened( opened )
	self.opened = opened
	self:Update( )
end

function PANEL:SetDay( day )
	self.day = day
	self.label:SetText( day )
	self:Update( )
end

function PANEL:Update( )
	self.label2:SetVisible( self.opened )
end

function PANEL:Paint( w, h )
	local color
	if self.opened then
		color = Color( 0, 255, 0 )
		self:SetColor( color )
		self.label2:SetVisible( true )
		self.label2:SetText( "CLAIMED" )
		self.label2:SetColor( color )
	elseif self.Hovered or self:IsChildHovered( 3 ) then
		color = self:GetSkin( ).Highlight
	elseif self.day < RewardsView:getInstance( ):GetStreak( ) then
		color = self:GetSkin( ).ButtonColor
		self:SetColor( color )
		self.label2:SetVisible( true )
		self.label2:SetText( "EXPIRED" )
		self.label2:SetColor( color )
	elseif self.day == RewardsView:getInstance( ):GetStreak( ) then
		color = self:GetSkin( ).BrightPanel
		self:SetColor( color )
		self.label2:SetVisible( true )
		self.label2:SetColor( color )
		self.label2:SetText( "Click to Claim" )
	else
		color = self:GetSkin( ).BrightPanel
		self:SetColor( color )
		self.label2:SetVisible( false )
	end

	self.label:SetColor( color )
	surface.SetDrawColor( color )

	surface.DrawOutlinedRect( 0, 0, w, h )
end

function PANEL:DoClick( )
	if self.opened then
		return
	end

	if self.day < RewardsView:getInstance( ):GetStreak( ) then
		return Derma_Message( "Sorry, but that day is already over :(", "Try Again" )
	end

	if self.day != RewardsView:getInstance( ):GetStreak( ) then
		return Derma_Message( "You're not at that day yet", "Try Again" )
	end

	RewardsView:getInstance( ):ClaimDay( )
	:Fail( function( err )
		Pointshop2View:getInstance( ):displayError( err )
	end )
end

vgui.Register( "DRewardsBox", PANEL, "DButton" )
