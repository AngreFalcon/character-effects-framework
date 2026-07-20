local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local core = require("openmw.core")
local world = require("openmw.world")
local storage = require("openmw.storage")
local vfs = require('openmw.vfs')
local json = require('scripts.lib.json')

local function syncMWVars(actor)
   if actor ~= nil then
      local localScript = world.mwscript.getLocalScript(actor, nil)
      if localScript ~= nil then
         local varTable = storage.globalSection(actor.id)
         varTable:setLifeTime(storage.LIFE_TIME.GameSession)
         for k, v in pairs((localScript.variables)) do
            varTable:set(k, v)
         end
      end
   end
end

local function loadConfigFiles()
   local configData = {}
   local configPath = "/scripts/caf/configs/"
   for fileName in vfs.pathsWithPrefix(configPath) do
      local file = vfs.open(fileName)
      if file ~= nil then

         local configId = string.match(file.fileName, "([^/\\]+)%..+$")
         configData[configId] = file:read("*all")
      end
   end
   return configData
end

local function parseConfigFiles(configData)
   local parsedConfigData = {}
   for k, v in pairs(configData) do
      parsedConfigData[k] = json.decode(v)
   end
   return parsedConfigData
end

local function storeConfigFiles(parsedConfigData)
   local configSection = storage.globalSection("CAF_ConfigData")
   configSection:setLifeTime(storage.LIFE_TIME.GameSession)
   configSection:reset({})
   for k, v in pairs(parsedConfigData) do
      configSection:set(k, v)
   end
end

return {
   engineHandlers = {
      onInit = function()
         local configData = loadConfigFiles()
         local parsedConfigData = parseConfigFiles(configData)
         storeConfigFiles(parsedConfigData)
      end,
      onActorActive = function(actor)
         syncMWVars(actor)
      end,
      onUpdate = function()
         for i = 1, #world.activeActors do
            syncMWVars(world.activeActors[i])
         end
      end,
   },
}
