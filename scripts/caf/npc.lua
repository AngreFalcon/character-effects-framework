local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local core = require('openmw.core')
local types = require('openmw.types')
local anim = require('openmw.animation')
local this = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')





































local CONDITIONS = {}

local DYNAMIC_STATS = {
   ["health"] = types.Actor.stats.dynamic.health,
   ["fatigue"] = types.Actor.stats.dynamic.fatigue,
   ["magicka"] = types.Actor.stats.dynamic.magicka,
}

local ATTRIBUTES = {
   ["agility"] = types.Actor.stats.attributes.agility,
   ["endurance"] = types.Actor.stats.attributes.endurance,
   ["intelligence"] = types.Actor.stats.attributes.intelligence,
   ["luck"] = types.Actor.stats.attributes.luck,
   ["personality"] = types.Actor.stats.attributes.personality,
   ["speed"] = types.Actor.stats.attributes.speed,
   ["strength"] = types.Actor.stats.attributes.strength,
   ["willpower"] = types.Actor.stats.attributes.willpower,
}

local SKILLS = {
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

local EQUIP_SLOTS = {
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

local configs = {
   taper = {
      conditions = {
         {

            race = { "argonian" },

            isMale = true,

















            equipmentslot = {
               ["pants"] = false,
               ["robe"] = false,
               ["skirt"] = false,
            },














         },
      },
      mesh = 'Meshes/bat/shiestaper.nif',
      node = "groin",
      duration = -1,
   },
   sheath = {
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

local function compareRange(value, r, valueMax)
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

local function applyCosmetic(effectID, node, mesh)
   anim.addVfx(this, mesh, {
      loop = true,
      boneName = node,
      vfxId = effectID,
      useAmbientLight = false,
   })
end

local function removeCosmetic(effectID)
   anim.removeVfx(this, effectID)
end

local function checkCharId(condId)
   local charId = types.NPC.record(this.object).id
   for i = 1, #condId do
      if charId == condId[i] then
         return true
      end
   end
   return false
end
CONDITIONS["charId"] = checkCharId

local function checkRace(condRace)
   local actorRace = types.NPC.record(this.object).race
   for i = 1, #condRace do
      if actorRace == condRace[i] then
         return true
      end
   end
   return false
end
CONDITIONS["race"] = checkRace

local function checkLevel(level)
   local actorLevel = types.Actor.stats.level(this.object)
   return compareRange(actorLevel.current, level) == false
end
CONDITIONS["level"] = checkLevel

local function checkSex(condSex)
   return types.NPC.record(this.object).isMale == condSex
end
CONDITIONS["isMale"] = checkSex

local function checkWerewolf(condWerewolf)
   return types.NPC.isWerewolf(this.object) == condWerewolf
end
CONDITIONS["werewolf"] = checkWerewolf

local function checkDead(condDead)
   return types.Actor.isDead(this.object) == condDead
end
CONDITIONS["dead"] = checkDead

local function checkMWVars(mwvars)
   local varTable = storage.globalSection(this.object.id)
   if varTable == nil then
      return false
   end
   for k, range in pairs(mwvars) do
      local value = varTable:get(k)
      if value == nil or compareRange(value, range, range.maxValue) == false then
         return false
      end
   end
   return true
end
CONDITIONS["mwvars"] = checkMWVars

local function checkDynStats(dynStats)
   for k, range in pairs(dynStats) do
      local getStat = DYNAMIC_STATS[k];
      local dynStat = getStat and getStat(this.object)
      if dynStat == nil or compareRange(dynStat.current, range, dynStat.base + dynStat.modifier) == false then
         return false
      end
   end
   return true
end
CONDITIONS["dynStats"] = checkDynStats

local function checkAttributes(attributes)
   for k, range in pairs(attributes) do
      local getAttr = ATTRIBUTES[k]
      local attr = getAttr and getAttr(this.object)
      if attr == nil or compareRange(attr.modified, range, attr.base + attr.modifier) == false then
         return false
      end
   end
   return true
end
CONDITIONS["attributes"] = checkAttributes

local function checkSkills(skills)
   for k, range in pairs(skills) do
      local getSkill = SKILLS[k]
      local skill = getSkill and getSkill(this.object)
      if skill == nil or compareRange(skill.modified, range, skill.base + skill.modifier) == false then
         return false
      end
   end
   return true
end
CONDITIONS["skills"] = checkSkills

local function checkEquipmentSlots(equipSlots)
   for k, v in pairs(equipSlots) do
      local equipped = types.Actor.getEquipment(this.object, EQUIP_SLOTS[string.lower(k)])
      if (equipped == nil and v == true) or (equipped ~= nil and v == false) then
         return false
      end
   end
   return true
end
CONDITIONS["equipmentslot"] = checkEquipmentSlots

local function checkClass(classes)
   local class = types.NPC.record(this.object).class
   return classes[string.lower(class)]
end
CONDITIONS["classes"] = checkClass

local function checkGuilds(guilds)
   local actorGuilds
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
CONDITIONS["guilds"] = checkGuilds

















local function checkEffectConditions()
   for effectId, effect in pairs(configs) do
      local conditions = effect.conditions
      for i = 1, #conditions do
         for k, v in pairs(CONDITIONS) do
            local condition = (conditions[i])[k]
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
   eventHandlers = {},
}
