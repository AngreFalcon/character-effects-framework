local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local cefConfigData = storage.globalSection("CEF_ConfigData"):asTable()
local cafConfigs: { string } = {}
for _, fileContents in pairs(cefConfigData) do
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
    for configName in pairs(cefConfigData[fileName] as { string: any }) do
        (settings.default as { string: boolean })[configName] = true
        (settings.argument as { string: { string } }).keys[#(settings.argument as { string: { string } }).keys + 1] = configName
    end
    return settings
end

local function getToggleSettings(): { I.Settings.SettingOptions }
    local settingsList: { I.Settings.SettingOptions } = {}
    for fileName in pairs(cefConfigData as { string: any }) do
        settingsList[#settingsList + 1] = genConfigToggles(fileName)
    end
    return settingsList
end

I.Settings.registerGroup {
    key = 'SettingsCharacterEffectsFrameworkConfigs',
    l10n = 'SettingsCharacterEffectsFrameworkConfigs',
    page = 'CharacterEffectsFrameworkPage',
    name = 'Character Effects Framework Settings',
    description = 'These settings allow you to toggle on/off configurations in-game, and are organized by the file they originate from.',
    permanentStorage = false,
    settings = getToggleSettings(),
}

I.Settings.registerGroup {
    key = 'SettingsGeneralCharacterEffectsFramework',
    l10n = 'SettingsGeneralCharacterEffectsFramework',
    page = 'CharacterEffectsFrameworkPage',
    name = 'Character Effects Framework General Settings',
    description = 'Settings related to Character Effects Framework',
    permanentStorage = false,
    settings = {
		{
			renderer = "number",
			name = "Tick Rate",
			key = "cefTickDelay",
			description = "The tickrate in seconds for Character Effects Framework. Lower values may affect performance in NPC-heavy areas.",
			default = 0.2,
			argument = {
				min = 0.05,
				max = 10,
			}
		},
	} as {I.Settings.SettingOptions},
}