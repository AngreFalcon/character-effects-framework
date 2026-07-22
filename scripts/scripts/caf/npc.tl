local core = require('openmw.core')
local types = require('openmw.types')
local anim = require('openmw.animation')
local this = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local nearby = require('openmw.nearby')

local realTime: number = core.getRealTime()
local elapsedTime: number = 0
local timerDelay <const>: number = (0.1 * time.second)
local configData: storage.StorageSection
local varsTable: storage.StorageSection

local interface Range 
	min: number
	max: number
	percent: boolean
	maxValue: number
end

local interface Guild
	rank: Range
	reputation: Range
end

local interface Condition
	charId: { string }
	race: { string }
	level: Range
	isMale: boolean
	isWerewolf: boolean
	isDead: boolean
	vars: { string: Range }
	dynStats: { string: Range }
	attributes: { string: Range }
	skills: { string: Range }
	equipment: { string: boolean }
	classes: { string: boolean }
	guilds: { string: Guild }
	effects: { string }
end

local interface Config
	conditions: { Condition }
	mesh: string
	node: string
end

local DYNAMIC_STATS <const>: { string: function(core.GameObject): types.DynamicStat } = {
	["health"] = types.Actor.stats.dynamic.health,
	["fatigue"] = types.Actor.stats.dynamic.fatigue,
	["magicka"] = types.Actor.stats.dynamic.magicka,
}

local ATTRIBUTES <const>: { string: function(core.GameObject): types.AttributeStat } = {
	["agility"] = types.Actor.stats.attributes.agility,
	["endurance"] = types.Actor.stats.attributes.endurance,
	["intelligence"] = types.Actor.stats.attributes.intelligence,
	["luck"] = types.Actor.stats.attributes.luck,
	["personality"] = types.Actor.stats.attributes.personality,
	["speed"] = types.Actor.stats.attributes.speed,
	["strength"] = types.Actor.stats.attributes.strength,
	["willpower"] = types.Actor.stats.attributes.willpower,
}

local SKILLS <const>: { string: function(core.GameObject): types.SkillStat } = {
	["acrobatics"] = types.NPC.stats.skills.acrobatics,
	["alchemy"] = types.NPC.stats.skills.alchemy,
	["alteration"] = types.NPC.stats.skills.alteration,
	["armorer"] = types.NPC.stats.skills.armorer,
	["athletics"] = types.NPC.stats.skills.athletics,
	["axe"] = types.NPC.stats.skills.axe,
	["block"] = types.NPC.stats.skills.block,
	["bluntweapon"] = types.NPC.stats.skills.bluntweapon,
	["conjuration"] = types.NPC.stats.skills.conjuration,
	["destruction"] = types.NPC.stats.skills.destruction,
	["enchant"] = types.NPC.stats.skills.enchant,
	["handtohand"] = types.NPC.stats.skills.handtohand,
	["heavyarmor"] = types.NPC.stats.skills.heavyarmor,
	["illusion"] = types.NPC.stats.skills.illusion,
	["lightarmor"] = types.NPC.stats.skills.lightarmor,
	["longblade"] = types.NPC.stats.skills.longblade,
	["marksman"] = types.NPC.stats.skills.marksman,
	["mediumarmor"] = types.NPC.stats.skills.mediumarmor,
	["mercantile"] = types.NPC.stats.skills.mercantile,
	["mysticism"] = types.NPC.stats.skills.mysticism,
	["restoration"] = types.NPC.stats.skills.restoration,
	["security"] = types.NPC.stats.skills.security,
	["shortblade"] = types.NPC.stats.skills.shortblade,
	["sneak"] = types.NPC.stats.skills.sneak,
	["spear"] = types.NPC.stats.skills.spear,
	["speechcraft"] = types.NPC.stats.skills.speechcraft,
	["unarmored"] = types.NPC.stats.skills.unarmored,
}

local EQUIP_SLOTS <const>: { string: number } = {
	["helmet"] = 0,
	["cuirass"] = 1,
	["greaves"] = 2,
	["leftpauldron"] = 3,
	["rightpauldron"] = 4,
	["leftgauntlet"] = 5,
	["rightgauntlet"] = 6,
	["boots"] = 7,
	["shirt"] = 8,
	["pants"] = 9,
	["skirt"] = 10,
	["robe"] = 11,
	["leftring"] = 12,
	["rightring"] = 13,
	["amulet"] = 14,
	["belt"] = 15,
	["carriedright"] = 16,
	["carriedleft"] = 17,
	["ammunition"] = 18,
}

local function compareRange(value: number, r: Range, valueMax?: number): boolean
	if not r.percent then
		if ((r.min > r.max) and (value < r.min) and (value > r.max)) or ((value < r.min) or (value > r.max)) then
			return false
		end
	elseif valueMax ~= nil and valueMax ~= 0 then
		local ratio = (value / valueMax * 100)
		if ((r.min > r.max) and (ratio < r.min) and (ratio > r.max)) or ((ratio < r.min) or (ratio > r.max)) then
			return false
		end
	else
		return false
	end
	return true
end

local function applyCosmetic(effectID: string, node: string, mesh: string)
	anim.addVfx(this as core.GameObject, mesh, {
    	loop = true,
    	boneName = node,
		vfxId = effectID,
		useAmbientLight = false,
  	})
end

local function removeCosmetic(effectID: string)
	anim.removeVfx(this as core.GameObject, effectID)
end

local CONDITIONS <const>: { { string, function(any) } } = {
	{ "charId",
		function(condId: {string}): boolean
			local charId = types.NPC.record(this.object as types.Actor).id
			for i = 1, #condId do
				if charId == condId[i] then
					return true
				end
			end
			return false
		end
	},

	{ "race",
		function(race: {string}): boolean
			local actorRace = types.NPC.record(this.object as types.Actor).race
			for i = 1, #race do
				if actorRace == race[i] then
					return true
				end
			end
			return false
		end
	},

	{ "level", 
		function(level: Range): boolean
			local actorLevel = types.Actor.stats.level(this.object)
			return compareRange(actorLevel.current, level)
		end
	},

	{ "isMale",
		function(isMale: boolean): boolean
			return types.NPC.record(this.object as types.Actor).isMale == isMale
		end
	},

	{ "isWerewolf",
		function(isWerewolf: boolean): boolean
			return types.NPC.isWerewolf(this.object) == isWerewolf
		end
	},

	{ "isDead",
		function(isDead: boolean): boolean
			return types.Actor.isDead(this.object) == isDead
		end
	},

	{ "vars",
		function(vars: { string: Range }): boolean
			if varsTable == nil then
				return false
			end
			for k, range in pairs(vars) do
				local value = varsTable:get(k)
				if value == nil or compareRange(value as integer, range, range.maxValue) == false then
					return false
				end
			end
			return true
		end
	},

	{ "dynStats",
		function(dynStats: { string: Range }): boolean
			for k, range in pairs(dynStats) do
				local getStat = DYNAMIC_STATS[k];
				local dynStat = getStat and getStat(this.object)
				if dynStat == nil or compareRange(dynStat.current, range, dynStat.base + dynStat.modifier) == false then
					return false
				end
			end
			return true
		end
	},

	{ "attributes",
		function(attributes: { string: Range }): boolean
			for k, range in pairs(attributes) do
				local getAttr = ATTRIBUTES[k]
				local attr = getAttr and getAttr(this.object)
				if attr == nil or compareRange(attr.modified, range, attr.base + attr.modifier) == false then
					return false
				end
			end
			return true
		end
	},

	{ "skills",
		function(skills: { string: Range }): boolean
			for k, range in pairs(skills) do
				local getSkill = SKILLS[k]
				local skill = getSkill and getSkill(this.object)
				if skill == nil or compareRange(skill.modified, range, skill.base + skill.modifier) == false then
					return false
				end
			end
			return true
		end
	},

	{ "equipment",
		function(equipment: { string: boolean }): boolean
			for k, v in pairs(equipment) do
				local equipped = types.Actor.getEquipment(this.object, EQUIP_SLOTS[string.lower(k)])
				if (equipped == nil and v == true) or (equipped ~= nil and v == false) then
					return false
				end
			end
			return true
		end
	},

	{ "classes",
		function(classes: { string: boolean }): boolean
			local class = types.NPC.record(this.object).class
			return classes[string.lower(class)]
		end
	},

	{ "guilds",
		function(guilds: { string: Guild }): boolean
			local actorGuilds: { string: boolean } = {}
			for _, v in ipairs(types.NPC.getFactions(this.object)) do
				actorGuilds[v] = true
			end
			for k, v in pairs(guilds) do
				if actorGuilds[k] == nil then
					return false
				else
					local rank = types.NPC.getFactionRank(this.object, k)
					if v.rank and compareRange(rank, v.rank) == false then
						return false
					end
					local reputation = types.NPC.getFactionReputation(this.object, k)
					if v.reputation and compareRange(reputation, v.reputation) == false then
						return false
					end
				end
			end
			return true
		end
	},
}

local function checkEffectConditions(effectId: string, effect: Config)
	for _, v1 in ipairs(effect.conditions) do
		for _, v2 in ipairs(CONDITIONS) do
			local condition = (v1 as { string: any })[v2[1]]
			if condition ~= nil and v2[2](condition) == false then
				removeCosmetic(effectId)
				return
			end
		end
	end
	applyCosmetic(effectId, effect.node, effect.mesh)
end

local function loopThroughEffects()
	for _, contents in pairs(configData:asTable()) do
		for effectId, effect in pairs(contents as { string: Config }) do
			checkEffectConditions(effectId, effect)
		end
	end
end

local function checkNearby()
	for _, v in ipairs(nearby.players) do
		if v ~= nil and types.Actor.isInActorsProcessingRange(v) == true then
			loopThroughEffects()
			break
		end
	end
end

return {
   	engineHandlers = {
		onActive = function()
			configData = storage.globalSection("CAF_ConfigData")
			varsTable = storage.globalSection(this.object.id)
			time.runRepeatedly(checkNearby, timerDelay, {})
		end,
		onUpdate = function()
			if core.isWorldPaused() and((realTime - elapsedTime) >= (timerDelay)) then
				checkNearby()
				elapsedTime = realTime
			end
			realTime = core.getRealTime()
		end,
   	},
}