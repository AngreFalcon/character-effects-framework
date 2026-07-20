local core = require("openmw.core")
local world = require("openmw.world")
local storage = require("openmw.storage")
local vfs = require('openmw.vfs')
local json = require('scripts.lib.json')

local function syncMWVars(actor: core.GameObject) -- Get the current state of all local mwscript variables associated with the provided actor
	if actor ~= nil then
		local localScript: world.MWScript = world.mwscript.getLocalScript(actor, nil)
		if localScript ~= nil then
            local varTable = storage.globalSection(actor.id)
			varTable:setLifeTime(storage.LIFE_TIME.GameSession as storage.LifeTime)
            for k, v in pairs((localScript.variables as {string: number})) do
                varTable:set(k, v)
			end
		end
	end
end

local function loadConfigFiles(): { string: string }
	local configData: { string: string } = {}
	local configPath = "/scripts/caf/configs/"
	local configExtension = ".json"
	for fileName in vfs.pathsWithPrefix(configPath) do
		local file = vfs.open(fileName as string)
		if file ~= nil then
			print(file.fileName)
			local configId = string.match(file.fileName, "([^/\\]+)%..+$")
			--local configId = string.sub(file.fileName, (#configPath), (#file.fileName - #configExtension))
			configData[configId] = file:read("*all")
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

local function storeConfigFiles(parsedConfigData: { string: any })
	local configSection = storage.globalSection("CAF_ConfigData")
	configSection:setLifeTime(storage.LIFE_TIME.GameSession as storage.LifeTime)
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
      	onActorActive = function(actor: core.GameObject) 
         	syncMWVars(actor)
      	end,
		onUpdate = function()
			for i = 1, #world.activeActors do
				syncMWVars(world.activeActors[i])
			end
		end
   	},
}

