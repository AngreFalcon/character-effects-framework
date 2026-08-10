local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local cefConfigData = storage.globalSection("CEF_ConfigData"):asTable()
local cafConfigs = {}
for _, fileContents in pairs(cefConfigData) do
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
   for configName in pairs(cefConfigData[fileName]) do
      (settings.default)[configName] = true;
      (settings.argument).keys[#(settings.argument).keys + 1] = configName
   end
   return settings
end

local function getToggleSettings()
   local settingsList = {}
   for fileName in pairs(cefConfigData) do
      settingsList[#settingsList + 1] = genConfigToggles(fileName)
   end
   return settingsList
end

I.Settings.registerGroup({
   key = 'SettingsCharacterEffectsFrameworkConfigs',
   l10n = 'SettingsCharacterEffectsFrameworkConfigs',
   page = 'CharacterEffectsFrameworkPage',
   name = 'Character Effects Framework Settings',
   description = 'Settings related to Character Effects Framework',
   permanentStorage = false,
   settings = getToggleSettings(),
})

I.Settings.registerGroup({
   key = 'SettingsGeneralCharacterEffectsFramework',
   l10n = 'SettingsGeneralCharacterEffectsFramework',
   page = 'CharacterEffectsFrameworkPage',
   name = 'Character Effects Framework General Settings',
   description = 'Settings related to Character Effects Framework',
   permanentStorage = false,
   settings = {
      {
         renderer = "number",
         name = "Update Detail",
         key = "cefTickDelay",
         description = "The tickrate for Character Effects Framework.",
         default = 0.2,
         argument = {
            min = 0.05,
            max = 10,
         },
      },
   },
})
