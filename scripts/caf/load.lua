local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local vfs = require('openmw.vfs')
local storage = require('openmw.storage')
local core = require('openmw.core')
local json = require('scripts.lib.json')

local function loadConfigFiles()
   local configData = {}
   for fileName in vfs.pathsWithPrefix("scripts/caf/configs") do
      local file = vfs.open(fileName)
      if file ~= nil then
         configData[file.fileName] = file:read("*all")
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

return {
   engineHandlers = {
      onContentFilesLoaded = function()
         local configData = loadConfigFiles()
         local parsedConfigData = parseConfigFiles(configData)
         local configSection = storage.globalSection("CAF_ConfigData")
         for k, v in pairs(parsedConfigData) do
            configSection:set(k, v)
            print(k)
         end
         core.sendGlobalEvent("saveConfigData", parsedConfigData)
      end,
   },
}
