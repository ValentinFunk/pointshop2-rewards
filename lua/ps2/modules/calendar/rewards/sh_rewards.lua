Pointshop2.Rewards = {}

Pointshop2.Rewards.DAYS_TRACKED = 7

function Pointshop2.Rewards.GetFactoryForStreak( streak )
  local info = Pointshop2.GetSetting( "Daily Rewards / Advent Calendar", "DailyRewards.Items" )[streak]
	if not info then
		return
	end

	local factoryClass = getClass( info.factoryClassName )
	if not factoryClass then
		return
	end

	local factory = factoryClass:new( )
	factory.settings = info.factorySettings

	return factory
end

hook.Add( "PS2_ModulesLoaded", "RewardsDLC", function( )
	local MODULE = Pointshop2.GetModule( "Daily Rewards / Advent Calendar" )

	table.insert( MODULE.SettingButtons, {
		label = "Reward Items",
		icon = "pointshop2/small43.png",
		control = "DRewardsConfigurator"
	} )

	MODULE.Settings.Shared.DailyRewards = {
		info = {
			isManualSetting = true, --Ignored by AutoAddSettingsTable
		},
		Items = {
			type = "table",
			value = { }
		}
	}
end )
