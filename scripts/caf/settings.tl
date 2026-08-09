local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local cafConfigData = storage.globalSection("CAF_ConfigData"):asTable()
local cafConfigs: { string } = {}
for _, fileContents in pairs(cafConfigData) do
    for configName in pairs(fileContents as { string: any }) do
        cafConfigs[#cafConfigs + 1] = configName
    end
end

local function genConfigToggles(fileName: string): I.Settings.SettingOptions
    local settings: I.Settings.SettingOptions = {}
    settings.renderer = "multiselect"
    settings.description = "Toggle configs from file: " .. fileName
    settings.name = "Config Toggle - " .. fileName
    settings.key = "configToggle" .. fileName
    settings.default = {}
    settings.argument = {}
    (settings.argument as { string: any }).keys = {}
    for configName in pairs(cafConfigData[fileName] as { string: any }) do
        (settings.default as { string: boolean })[configName] = true
        (settings.argument as { string: { string } }).keys[#(settings.argument as { string: { string } }).keys + 1] = configName
    end
    return settings
end

local function getToggleSettings(): { I.Settings.SettingOptions }
    local settingsList: { I.Settings.SettingOptions } = {}
    for fileName in pairs(cafConfigData as { string: any }) do
        settingsList[#settingsList + 1] = genConfigToggles(fileName)
    end
    return settingsList
end

I.Settings.registerGroup {
    key = 'SettingsCharacterAppearanceFrameworkConfigs',
    l10n = 'SettingsCharacterAppearanceFrameworkConfigs',
    page = 'CharacterAppearanceFrameworkPage',
    name = 'Character Appearance Framework Settings',
    description = 'Settings related to Character Appearance Framework',
    permanentStorage = false,
    settings = getToggleSettings(),
}

I.Settings.registerGroup {
    key = 'SettingsGeneralCharacterAppearanceFramework',
    l10n = 'SettingsGeneralCharacterAppearanceFramework',
    page = 'CharacterAppearanceFrameworkPage',
    name = 'Character Appearance Framework General Settings',
    description = 'Settings related to Character Appearance Framework',
    permanentStorage = false,
    settings = {
		{
			renderer = "number",
			name = "Update Detail",
			key = "cafTickDelay",
			description = "The tickrate for Character Appearance Framework.",
			default = 0.2,
			argument = {
				min = 0.05,
				max = 10,
			}
		},
	} as {I.Settings.SettingOptions},
}