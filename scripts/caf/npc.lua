local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local core = require('openmw.core')
local types = require('openmw.types')
local anim = require('openmw.animation')
local this = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local nearby = require('openmw.nearby')

local realTime = core.getRealTime()
local elapsedTime = 0
local timerDelay = (0.1 * time.second)
local configData = {}





































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

local CONDITIONS = {
   { "charId",
   function(condId)
      local charId = types.NPC.record(this.object).id
      for i = 1, #condId do
         if charId == condId[i] then
            return true
         end
      end
      return false
   end,
   },

   { "race",
   function(race)
      local actorRace = types.NPC.record(this.object).race
      for i = 1, #race do
         if actorRace == race[i] then
            return true
         end
      end
      return false
   end,
   },

   { "level",
   function(level)
      local actorLevel = types.Actor.stats.level(this.object)
      return compareRange(actorLevel.current, level)
   end,
   },

   { "isMale",
   function(isMale)
      return types.NPC.record(this.object).isMale == isMale
   end,
   },

   { "isWerewolf",
   function(isWerewolf)
      return types.NPC.isWerewolf(this.object) == isWerewolf
   end,
   },

   { "isDead",
   function(isDead)
      return types.Actor.isDead(this.object) == isDead
   end,
   },

   { "mwvars",
   function(mwvars)
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
   end,
   },

   { "dynStats",
   function(dynStats)
      for k, range in pairs(dynStats) do
         local getStat = DYNAMIC_STATS[k];
         local dynStat = getStat and getStat(this.object)
         if dynStat == nil or compareRange(dynStat.current, range, dynStat.base + dynStat.modifier) == false then
            return false
         end
      end
      return true
   end,
   },

   { "attributes",
   function(attributes)
      for k, range in pairs(attributes) do
         local getAttr = ATTRIBUTES[k]
         local attr = getAttr and getAttr(this.object)
         if attr == nil or compareRange(attr.modified, range, attr.base + attr.modifier) == false then
            return false
         end
      end
      return true
   end,
   },

   { "skills",
   function(skills)
      for k, range in pairs(skills) do
         local getSkill = SKILLS[k]
         local skill = getSkill and getSkill(this.object)
         if skill == nil or compareRange(skill.modified, range, skill.base + skill.modifier) == false then
            return false
         end
      end
      return true
   end,
   },

   { "equipment",
   function(equipment)
      for k, v in pairs(equipment) do
         local equipped = types.Actor.getEquipment(this.object, EQUIP_SLOTS[string.lower(k)])
         if (equipped == nil and v == true) or (equipped ~= nil and v == false) then
            return false
         end
      end
      return true
   end,
   },

   { "classes",
   function(classes)
      local class = types.NPC.record(this.object).class
      return classes[string.lower(class)]
   end,
   },

   { "guilds",
   function(guilds)
      local actorGuilds = {}
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
   end,
   },
}

local function checkEffectConditions()
   for _, contents in pairs(configData) do
      for effectId, effect in pairs(contents) do
         local conditions = effect.conditions
         for _, v1 in ipairs(conditions) do
            for _, v2 in ipairs(CONDITIONS) do
               local condition = (v1)[v2[1]]
               if condition ~= nil and v2[2](condition) == false then
                  removeCosmetic(effectId)
                  return
               end
            end
         end
         applyCosmetic(effectId, effect.node, effect.mesh)
      end
   end
end

local function checkNearby()
   for _, v in ipairs(nearby.players) do
      if v ~= nil and types.Actor.isInActorsProcessingRange(v) == true then
         checkEffectConditions()
         break
      end
   end
end

return {
   engineHandlers = {
      onInit = function()
         configData = storage.globalSection("CAF_ConfigData"):asTable()
      end,
      onActive = function()
         time.runRepeatedly(checkNearby, timerDelay, {})
      end,
      onUpdate = function()
         if core.isWorldPaused() and ((realTime - elapsedTime) >= (timerDelay)) then
            checkNearby()
            elapsedTime = realTime
         end
         realTime = core.getRealTime()
      end,
   },
}
