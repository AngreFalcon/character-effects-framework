local vfs = require('openmw.vfs')
local storage = require('openmw.storage')
local core = require('openmw.core')
local json = require('scripts.lib.json')

local function loadConfigFiles(): { string: string}
	local configData: { string: string } = {}
	for fileName in vfs.pathsWithPrefix("scripts/caf/configs") do
		local file = vfs.open(fileName as string)
		if file ~= nil then
			configData[file.fileName] = file:read("*all")
		end
	end
	return configData
end

local function parseConfigFiles(configData: { string: string}): { string: any }
	local parsedConfigData: { string: any } = {}
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
      	end
   	},
}
