local LoginEvent = CreatureEvent("InspectLogin")

function LoginEvent.onLogin(player)
  player:registerEvent("InspectExtended")
  return true
end

local ExtendedEvent = CreatureEvent("InspectExtended")

function ExtendedEvent.onExtendedOpcode(player, opcode, buffer)
  if opcode == ExtendedOPCodes.CODE_INSPECT then
    local status, json_data =
      pcall(
      function()
        return json.decode(buffer)
      end
    )
    if not status then
      return
    end

    local action = json_data.action
    local data = json_data.data

    if action == "inspect" then
      inspectPlayer(player, data)
    end
  end
end

function inspectPlayer(player, targetName)
  local target = Player(targetName)
  if target then
    local stats = {}
    stats.name = target:getName()
    local guild = target:getGuild()
    stats.guild = guild and guild:getName() or "None"
    stats.vocation = target:getVocation():getName()
    stats.health = target:getHealth()
    stats.maxHealth = target:getMaxHealth()
    stats.mana = target:getMana()
    stats.maxMana = target:getMaxMana()
    stats.level = target:getLevel()
    stats.exp = target:getExperience()
    stats.skills = {}
    for i = SKILL_FIST, SKILL_FISHING do
      local totalSkill = target:getEffectiveSkillLevel(i)
      local baseSkill = target:getSkillLevel(i)
      local skillPercent = target:getSkillPercent(i)
      local bonus = totalSkill - baseSkill
      stats.skills[i + 1] = {
        total = totalSkill,
        bonus = bonus,
        percent = skillPercent
      }
    end
    local baseMagic = target:getBaseMagicLevel()
    local totalMagic = target:getMagicLevel()
    stats.skills[#stats.skills + 1] = {
      total = totalMagic,
      bonus = totalMagic - baseMagic,
      percent = target:getMagicLevelPercent()
    }
    player:sendExtendedOpcode(ExtendedOPCodes.CODE_INSPECT, json.encode({action = "stats", data = stats}))

    for slot = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
      local item = target:getSlotItem(slot)
      if slot ~= CONST_SLOT_NECKLACE and item then
        player:sendExtendedOpcode(ExtendedOPCodes.CODE_INSPECT, json.encode({action = "item", data = {slot = slot, item = item:getId()}}))
      else
        player:sendExtendedOpcode(ExtendedOPCodes.CODE_INSPECT, json.encode({action = "item", data = {slot = slot}}))
      end
    end
  end
end

LoginEvent:type("login")
LoginEvent:register()
ExtendedEvent:type("extendedopcode")
ExtendedEvent:register()
