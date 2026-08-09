local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local cafConfigData = storage.globalSection("CAF_ConfigData"):asTable()
local cafConfigs = {}
for _, fileContents in pairs(cafConfigData) do
   for configName in pairs(fileContents) do
      cafConfigs[#cafConfigs + 1] = configName
   end
end

local function genConfigToggles(fileName)
   local settings = {}
   settings.renderer = "multiselect"
   settings.description = "Toggle configs from file: " .. fileName
   settings.name = "Config Toggle - " .. fileName
   settings.key = "configToggle" .. fileName
   settings.default = {}
   settings.argument = {};
   (settings.argument).keys = {}
   for configName in pairs(cafConfigData[fileName]) do
      (settings.default)[configName] = true;
      (settings.argument).keys[#(settings.argument).keys + 1] = configName
   end
   return settings
end

local function getToggleSettings()
   local settingsList = {}
   for fileName in pairs(cafConfigData) do
      settingsList[#settingsList + 1] = genConfigToggles(fileName)
   end
   return settingsList
end

I.Settings.registerGroup({
   key = 'SettingsCharacterAppearanceFrameworkConfigs',
   l10n = 'SettingsCharacterAppearanceFrameworkConfigs',
   page = 'CharacterAppearanceFrameworkPage',
   name = 'Character Appearance Framework Settings',
   description = 'Settings related to Character Appearance Framework',
   permanentStorage = false,
   settings = getToggleSettings(),
})

I.Settings.registerGroup({
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
         },
      },
   },
})
