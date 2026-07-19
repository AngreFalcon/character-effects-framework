local core = require('openmw.core')
local types = require('openmw.types')
local anim = require('openmw.animation')
local this = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
--local configFiles = require('scripts.caf.load')

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
	werewolf: boolean
	dead: boolean
	mwvars: { string: Range }
	dynStats: { string: Range }
	attributes: { string: Range }
	skills: { string: Range }
	equipmentslot: { string: boolean }
	classes: { string: boolean }
	guilds: { string: Guild }
end

local interface Config
	conditions: { Condition }
	mesh: string
	node: string
	duration: number
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

local configs: { string: Config } = {
	taper: Config = {
		conditions: { Condition } = {
			{
				--charId: { string } = { "safl-shies" }, -- implemented
				race: { string } = { "argonian" }, -- implemented
				--level: Range = { min = 0, max = 100 }, -- implemented
				isMale: boolean = true, -- implemented
				--[[werewolf: boolean = false, -- implemented
				dead: boolean = false, -- implemented
				mwvars: { string: Range } = { -- implemented
					companion = { min = 1, max = 1, },
					arousal = { min = 100, max = 100, }, -- this range is only true if arousal is 100 exactly
					stinky = { min = 0, max = 100, }, -- this range is only true is stinky is between 0 and 100 (inclusive)
				},
				dynStats: { string: Range } = { -- implemented
					health = { min = 0.5, max = 1, percent = true },
					fatigue = { min = 100, max = 10, percent = false }, -- this range excludes all values between 10 and 100, meaning the condition is only true if fatigue is greater than 99 or less then 11
				},
				attributes: { string: Range } = { -- implemented
					speed = { min = 0, max = 100  },
				},
				skills: { string: Range } = { -- implemented
					acrobatics = { min = 0, max = 100  },
				},--]]
				equipmentslot: { string: boolean } = { -- implemented
					["pants"] = false,
					["robe"] = false,
					["skirt"] = false,
				},
				--[[classes: { string: boolean } = { -- implemented
					["thief"] = false, -- any thieves are excluded
					["assassin"] = true, -- 
				},
				guilds: { string: Guild } = { -- implemented
					["morag tong"] = {
						rank = { min = 1, max = 10 },
						reputation = { min = 1, max = 10 },
					},
					["mages guild"] = {
						rank = { min = 1, max = 10 },
						reputation = { min = 1, max = 10 },
					},
				},--]]
			},
		},
		mesh: string = 'Meshes/bat/shiestaper.nif',
		node: string = "groin",
		duration: number = -1,
	},
	sheath: Config = {
		conditions = {
			{
				race = { "khajiit" },
			},
		},
		mesh = 'Meshes/bat/shiestaper.nif',
		node = "groin",
		duration = -1,
	},
}

local function compareRange(value: number, r: Range, valueMax?: number): boolean
	if not r.percent then
		if ((r.min > r.max) and (value < r.min) and (value > r.max)) or ((value < r.min) or (value > r.max)) then
			return false
		end
	elseif valueMax ~= nil and valueMax ~= 0 then
		local ratio = value / valueMax
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

local function checkCharId(condId: {string}): boolean
	local charId = types.NPC.record(this.object as types.Actor).id
	for i = 1, #condId do
		if charId == condId[i] then
			return true
		end
	end
	return false
end

local function checkRace(condRace: {string}): boolean
	local actorRace = types.NPC.record(this.object as types.Actor).race
	for i = 1, #condRace do
		if actorRace == condRace[i] then
			return true
		end
	end
	return false
end

local function checkLevel(level: Range): boolean
	local actorLevel = types.Actor.stats.level(this.object)
	return compareRange(actorLevel.current, level) == false
end

local function checkSex(condSex: boolean): boolean
	return types.NPC.record(this.object as types.Actor).isMale == condSex
end

local function checkWerewolf(condWerewolf: boolean): boolean
	return types.NPC.isWerewolf(this.object) == condWerewolf
end

local function checkDead(condDead: boolean): boolean
	return types.Actor.isDead(this.object) == condDead
end

local function checkMWVars(mwvars: { string: Range }): boolean
	local varTable = storage.globalSection(this.object.id)
	if varTable == nil then
		return false
	end
	for k, range in pairs(mwvars) do
		local value = varTable:get(k)
		if value == nil or compareRange(value as integer, range, range.maxValue) == false then
			return false
		end
	end
	return true
end

local function checkDynStats(dynStats: { string: Range }): boolean
	for k, range in pairs(dynStats) do
		local getStat = DYNAMIC_STATS[k];
		local dynStat = getStat and getStat(this.object)
		if dynStat == nil or compareRange(dynStat.current, range, dynStat.base + dynStat.modifier) == false then
			return false
		end
	end
	return true
end

local function checkAttributes(attributes: { string: Range }): boolean
	for k, range in pairs(attributes) do
		local getAttr = ATTRIBUTES[k]
		local attr = getAttr and getAttr(this.object)
		if attr == nil or compareRange(attr.modified, range, attr.base + attr.modifier) == false then
			return false
		end
	end
	return true
end

local function checkSkills(skills: { string: Range }): boolean
	for k, range in pairs(skills) do
		local getSkill = SKILLS[k]
		local skill = getSkill and getSkill(this.object)
		if skill == nil or compareRange(skill.modified, range, skill.base + skill.modifier) == false then
			return false
		end
	end
	return true
end

local function checkEquipmentSlots(equipSlots: { string: boolean }): boolean
	for k, v in pairs(equipSlots) do
		local equipped = types.Actor.getEquipment(this.object, EQUIP_SLOTS[string.lower(k)])
		if (equipped == nil and v == true) or (equipped ~= nil and v == false) then
			return false
		end
	end
	return true
end

local function checkClass(classes: { string: boolean }): boolean
	local class = types.NPC.record(this.object).class
	return classes[string.lower(class)]
end

local function checkGuilds(guilds: { string: Guild }): boolean
	local actorGuilds: { string: boolean }
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

local CONDITIONS <const>: { string: function(any) } = {
	charId = checkCharId,
	race = checkRace,
	level = checkLevel,
	isMale = checkSex,
	werewolf = checkWerewolf,
	dead = checkDead,
	mwvars = checkMWVars,
	dynStats = checkDynStats,
	attributes = checkAttributes,
	skills = checkSkills,
	equipmentslot = checkEquipmentSlots,
	classes = checkClass,
	guilds = checkGuilds,
}

local function checkEffectConditions()
	for effectId, effect in pairs(configs) do
		local conditions = effect.conditions
		for i = 1, #conditions do
			for k, v in pairs(CONDITIONS) do
				local condition = (conditions[i] as {string: any})[k]
				if condition ~= nil and v(condition) == false then
					removeCosmetic(effectId)
					return
				end
			end
		end
		applyCosmetic(effectId, effect.node, effect.mesh)
	end
end

return {
   	engineHandlers = {
      	onActive = function()
			time.runRepeatedly(checkEffectConditions, 0.2 * time.second, {})
		end,
   	},
	eventHandlers = {}
}