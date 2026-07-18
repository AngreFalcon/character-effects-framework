local core = require('openmw.core')
local types = require('openmw.types')
local anim = require('openmw.animation')
local this = require('openmw.self')
local storage = require('openmw.storage')

local interface Range 
	min: number
	max: number
	percent: boolean
	maxValue: number
end

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

local argonianTaper = {
	conditions = {
		{
			race = { "argonian" }, -- complete
			level = { min = 0, max = 100 }, -- complete
			isMale = true, -- complete
			werewolf = false, -- complete
			dead = false, -- complete
			mwvars = { -- complete
				companion = { min = 1, max = 1, },
				--arousal = { min = 100, max = 100, }, -- this range is only true if arousal is 100 exactly
				--stinky = { min = 0, max = 100, }, -- this range is only true is stinky is between 0 and 100 (inclusive)
			},
			dynStats = { -- complete
				health = { min = 0.5, max = 1, percent = true },
				--fatigue = { min = 100, max = 10, percent = false }, -- this range excludes all values between 10 and 100, meaning the condition is only true if fatigue is greater than 99 or less then 11
			},
			attributes = { -- complete
				speed = { min = 0, max = 100  },
			},
			skills = { -- complete
				acrobatics = { min = 0, max = 100  },
			},
			equipmentslot = { -- complete
				["pants"] = false,
				["robe"] = false,
				["skirt"] = false,
			},
			classes = { -- complete
				["thief"] = false, -- any thieves are excluded
				["assassin"] = true, -- 
			}
		},
	},
	mesh = 'Meshes/bat/shiestaper.nif',
	node = "groin",
	duration = -1,
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
		if dynStat and compareRange(dynStat.current, range, dynStat.base + dynStat.modifier) == false then
			return false
		end
	end
	return true
end

local function checkAttributes(attributes: { string: Range }): boolean
	for k, range in pairs(attributes) do
		local getAttr = ATTRIBUTES[k]
		local attr = getAttr and getAttr(this.object)
		if attr and compareRange(attr.modified, range, attr.base + attr.modifier) == false then
			return false
		end
	end
	return true
end

local function checkSkills(skills: { string: Range }): boolean
	for k, range in pairs(skills) do
		local getSkill = SKILLS[k]
		local skill = getSkill and getSkill(this.object)
		if skill and compareRange(skill.modified, range, skill.base + skill.modifier) == false then
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
	if (classes[string.lower(class)] == false) then
		return false
	end
	return true
end

local function checkEffectConditions()
	local conditions = argonianTaper.conditions
	local effectID = "taper"

	for i = 1, #conditions do
		if conditions[i].race ~= nil and checkRace(conditions[i].race) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].level ~= nil and checkLevel(conditions[i].level) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].isMale ~= nil and checkSex(conditions[i].isMale) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].werewolf ~= nil and checkWerewolf(conditions[i].werewolf) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].dead ~= nil and checkDead(conditions[i].dead) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].mwvars ~= nil and checkMWVars(conditions[i].mwvars) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].dynStats ~= nil and checkDynStats(conditions[i].dynStats) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].attributes ~= nil and checkAttributes(conditions[i].attributes) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].skills ~= nil and checkSkills(conditions[i].skills) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].equipmentslot ~= nil and checkEquipmentSlots(conditions[i].equipmentslot) == false then
			removeCosmetic(effectID)
			return
		end
		if conditions[i].classes ~= nil and checkClass(conditions[i].classes) == false then
			removeCosmetic(effectID)
			return
		end
	end
	applyCosmetic(effectID, argonianTaper.node, argonianTaper.mesh)
end

return {
   	engineHandlers = {
      	onActive = function()
			checkEffectConditions()
		end,
		onUpdate = checkEffectConditions,
   	},
	eventHandlers = {}
}