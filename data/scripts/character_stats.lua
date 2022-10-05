local statIndexByName = {
  ["strength"] = CHARSTAT_STRENGTH,
  ["intelligence"] = CHARSTAT_INTELLIGENCE,
  ["dexterity"] = CHARSTAT_DEXTERITY,
  ["vitality"] = CHARSTAT_VITALITY,
  ["spirit"] = CHARSTAT_SPIRIT,
  ["wisdom"] = CHARSTAT_WISDOM
}

local statNameByIndex = {
  [CHARSTAT_STRENGTH] = "strength",
  [CHARSTAT_INTELLIGENCE] = "intelligence",
  [CHARSTAT_DEXTERITY] = "dexterity",
  [CHARSTAT_VITALITY] = "vitality",
  [CHARSTAT_SPIRIT] = "spirit",
  [CHARSTAT_WISDOM] = "wisdom"
}

-- this is VISUAL ONLY for the client, to change actual values, you have to edit sources
local valuePerStat = {
  [CHARSTAT_STRENGTH] = 1,
  [CHARSTAT_INTELLIGENCE] = 1,
  [CHARSTAT_DEXTERITY] = 1,
  [CHARSTAT_VITALITY] = 1,
  [CHARSTAT_SPIRIT] = 1,
  [CHARSTAT_WISDOM] = 1
}

-- max points that player can add to single stat
local maxValues = {
  [CHARSTAT_STRENGTH] = 20,
  [CHARSTAT_INTELLIGENCE] = 20,
  [CHARSTAT_DEXTERITY] = 30,
  [CHARSTAT_VITALITY] = 25,
  [CHARSTAT_SPIRIT] = 25,
  [CHARSTAT_WISDOM] = 30
}

-- +1 point at X level
local StatsConfig = {
  levels = {
    25,
    50,
    75,
    100,
    125,
    150,
    175,
    200,
    225,
    250,
    275,
    300,
    325,
    350,
    375,
    400,
    425,
    450,
    475,
    500,
    550,
    600,
    650,
    700,
    750,
    800,
    850,
    900,
    950,
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000
  }
}

local LoginEvent = CreatureEvent("CharacterStatsLogin")

function LoginEvent.onLogin(player)
  player:registerEvent("CharacterStatsExtended")
  player:registerEvent("CharacterStatsAdvance")
  player:updateCharacterStats()
  return true
end

local AdvanceEvent = CreatureEvent("CharacterStatsAdvance")

function AdvanceEvent.onAdvance(player, skill, oldLevel, newLevel)
  if skill ~= SKILL_LEVEL or newLevel <= oldLevel then
    return true
  end

  for i = 1, #StatsConfig.levels do
    local level = StatsConfig.levels[i]
    if newLevel >= level and player:getStorageValue(PlayerStorageKeys.characterStatsLevel) < i then
      player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have gained a new stat point.")
      player:addStatsPoints(1)
      player:setStorageValue(PlayerStorageKeys.characterStatsLevel, i)
    end
  end

  return true
end

local ExtendedEvent = CreatureEvent("CharacterStatsExtended")

function ExtendedEvent.onExtendedOpcode(player, opcode, buffer)
  if opcode == ExtendedOPCodes.CODE_CHARSTATS then
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

    if action == "add" then
      addStat(player, data)
    elseif action == "remove" then
      removeStat(player, data)
    elseif action == "reset" then
      resetStats(player)
    end
  end
end

function addStat(player, data)
  if player:getStatsPoints() <= 0 then
    return
  end
  local statId = statIndexByName[data]
  if player:getCharacterStat(statId) >= maxValues[statId] then
    return
  end
  player:addCharacterStat(statId, 1)
  player:addStatsPoints(-1, true)

  player:updateCharacterStats()
end

function removeStat(player, data)
  local statId = statIndexByName[data]
  if player:getCharacterStat(statId) <= 0 then
    return
  end
  player:addCharacterStat(statId, -1)
  player:addStatsPoints(1, true)

  player:updateCharacterStats()
end

function resetStats(player)
  for i = CHARSTAT_FIRST, CHARSTAT_LAST do
    local points = player:getStorageValue(PlayerStorageKeys.characterStatsPoints + i + 1)
    if points > 0 then
      player:setStorageValue(PlayerStorageKeys.characterStatsPoints + i + 1, -1)
      player:addStatsPoints(points, true)
    end
  end

  for i = CHARSTAT_FIRST, CHARSTAT_LAST do
    local points = player:getCharacterStat(i)
    player:setCharacterStat(i, 0)
    player:addStatsPoints(points, true)
  end

  player:updateCharacterStats()
end

function Player:updateCharacterStats()
  local stats = {}
  for i = CHARSTAT_FIRST, CHARSTAT_LAST do
    stats[statNameByIndex[i]] = {
      points = self:getCharacterStat(i),
      value = valuePerStat[i] * self:getCharacterStat(i)
    }
  end

  local data = {
    points = self:getStatsPoints(),
    stats = stats
  }

  self:sendExtendedOpcode(ExtendedOPCodes.CODE_CHARSTATS, json.encode({action = "update", data = data}))
end

function Player:addStatsPoints(points, silent)
  local val = self:getStorageValue(PlayerStorageKeys.characterStatsPoints)
  if val == -1 then
    val = 0
  end
  self:setStorageValue(PlayerStorageKeys.characterStatsPoints, val + points)

  if not silent then
    self:updateCharacterStats()
  end
end

function Player:getStatsPoints()
  local val = self:getStorageValue(PlayerStorageKeys.characterStatsPoints)
  if val == -1 then
    val = 0
  end

  return val
end

LoginEvent:type("login")
LoginEvent:register()
AdvanceEvent:type("advance")
AdvanceEvent:register()
ExtendedEvent:type("extendedopcode")
ExtendedEvent:register()
