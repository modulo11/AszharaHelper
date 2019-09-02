AszharaHelper = LibStub("AceAddon-3.0"):NewAddon("AszharaHelper", "AceEvent-3.0", "AceTimer-3.0")

function AszharaHelper:OnInitialize()
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterEvent("ENCOUNTER_START")
  self:RegisterEvent("ENCOUNTER_END")

  self.enabled = false

  self.raid = {}
  self.markedPlayers = {}
  self.decrees = {
    -- For debugging
    -- [295842] = true, -- Null Barrier
    -- [178740] = true, -- Immolation Aura
  
    [299249] = true, -- Suffer!
    [299251] = true, -- Obey!
  
    [299254] = true, -- Stand Together!
    [299255] = true, -- Stand Alone!
  
    [299253] = true, -- Stay!
    [299252] = true -- March!
  }

  self.casted = false

  self.sufferAloneMarkerCount = 0
  self.sufferTogetherMarkerCount = 0
  self.stayStandAloneMarkerCount = 0
  self.stayStandTogetherMarkerCount = 0
end

function AszharaHelper:OnEnable()
  -- Called when the addon is enabled
end

function AszharaHelper:OnDisable()
  -- Called when the addon is disabled
end

function AszharaHelper:ENCOUNTER_START(event, ...)
  local encounterID, encounterName, difficultyID, groupSize = ...
  
  -- Queen Azshara
  if encounterID == 2299 then
    self:Print("Event: " .. encounterName .. " started")
    self.enabled = true
    self:ResetDecrees()
  end
end

function AszharaHelper:ENCOUNTER_END(event, ...)
  local encounterID, encounterName, difficultyID, groupSize, success = ...
  
  -- Queen Azshara
  if encounterID == 2299 then
    self:Print("Event: " .. encounterName .. " ended")
    self.enabled = false
    self:ResetDecrees()
  end
end

function AszharaHelper:COMBAT_LOG_EVENT_UNFILTERED(event)
  if self.enabled then
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, auraType = CombatLogGetCurrentEventInfo()

    -- Queen Azshara: Queen's Decree
    if subevent == "SPELL_CAST_SUCCESS" and auraType == 299250 then
      self:ScheduleTimer("EvaluateDecrees", 1)
      self.casted = true
    end

    if subevent == "SPELL_AURA_APPLIED" then
      if self.decrees[auraType] then
        self:addSufferingPlayer(destName, auraType)
      end
    elseif subevent == "SPELL_AURA_REMOVED" then
      if self.decrees[auraType] then
      end
    end
  end
end

function AszharaHelper:addSufferingPlayer(player, spell)
  if self.casted == false then
    self:ScheduleTimer("EvaluateDecrees", 1)
    self.casted = true
  end

  if self.raid[player] == nil then
    table.insert(self.raid, player)
    self.raid[player] = {}
  end

  if self.raid[player][spell] == nil then
    self.raid[player][spell] = {}
  end

  table.insert(self.raid[player][spell], true)
end

function AszharaHelper:dump()
  for _, player in ipairs(self.raid) do
    local decrees = {}
    for decree, _ in pairs(self.raid[player]) do
      local decreeName = GetSpellInfo(decree)
      table.insert(decrees, decreeName)
    end
    self:Print("Player: ".. player .. " suffering from: " .. table.concat(decrees, ", "))
  end
end

function AszharaHelper:EvaluateDecrees()
  self:Print("Evaluating decrees ...")
  self:dump()

  for _, player in ipairs(self.raid) do
    local decrees = self.raid[player]
    
    -- Debugging Null Barrier + Immolation Aura
    --[[
    if decrees[295842] and decrees[178740] then
      self:Print("### WHISPER ###")
      self.sufferTogetherMarkerCount = self.sufferTogetherMarkerCount + 1
      table.insert(self.markedPlayers, player)

      if self.sufferTogetherMarkerCount >= 1 and self.sufferTogetherMarkerCount <= 2 then
        SendChatMessage("Go soak TOGETHER", "WHISPER", nil, player);
        SetRaidTarget(player, self.sufferTogetherMarkerCount + 3);
      end

      if self.sufferTogetherMarkerCount > 2 and self.sufferTogetherMarkerCount % 2 == 0 then
        SendChatMessage("Go soak TOGETHER with: {triangle}", "WHISPER", nil, player);
      else
        SendChatMessage("Go soak TOGETHER with: {moon}", "WHISPER", nil, player);
      end
    end
    --]]

    -- March! + Stand Alone!
    if decrees[299252] and decrees[299255] then
      SendChatMessage("Walk ALONE at the corner of the room", "WHISPER", nil, player);      
    end

    -- Suffer! + Stand Alone!
    -- Marker: Star, Circle, Diamond - 1, 2, 3
    if decrees[299249] and decrees[299255] then
      self.sufferAloneMarkerCount = self.sufferAloneMarkerCount + 1
      table.insert(self.markedPlayers, player)

      SendChatMessage("Go soak ALONE", "WHISPER", nil, player);

      if self.sufferAloneMarkerCount >= 1 and self.sufferAloneMarkerCount <= 3 then
        SetRaidTarget(player, self.sufferAloneMarkerCount);
      end
    end

    -- Suffer! + Stand Together!
    -- Marker: Triangle, Moon - 4, 5
    if decrees[299249] and decrees[299254] then
      self.sufferTogetherMarkerCount = self.sufferTogetherMarkerCount + 1
      table.insert(self.markedPlayers, player)

      if self.sufferTogetherMarkerCount >= 1 and self.sufferTogetherMarkerCount <= 2 then
        SendChatMessage("Go soak", "WHISPER", nil, player);
        SetRaidTarget(player, self.sufferTogetherMarkerCount + 3);
      end

      if self.sufferTogetherMarkerCount > 2 and self.sufferTogetherMarkerCount % 2 == 0 then
        SendChatMessage("Go soak TOGETHER with: {triangle}", "WHISPER", nil, player);
      else
        SendChatMessage("Go soak TOGETHER with: {moon}", "WHISPER", nil, player);
      end
    end

    -- Stay! + Stand Alone!
    -- Marker: Cross  - 7
    if decrees[299253] and decrees[299255] then
      table.insert(self.markedPlayers, player)
      SendChatMessage("Just stand still", "WHISPER", nil, player);
      SetRaidTarget(player, 7);
    end

    -- Stay! + Stand Together!
    -- Marker: Skull - 8
    if decrees[299253] and decrees[299254] then
      table.insert(self.markedPlayers, player)
      SendChatMessage("Stick to someone and stand still", "WHISPER", nil, player);
      SetRaidTarget(player, 8);
    end
  end

  self:ScheduleTimer("ResetDecrees", 15)
end

function AszharaHelper:ResetDecrees()
  self:Print("Resetting decrees ...")

  for i,v in ipairs(self.markedPlayers) do
    SetRaidTarget(v, 0);
  end

  self.raid = {}
  self.markedPlayers = {}

  self.casted = false

  self.sufferAloneMarkerCount = 0
  self.sufferTogetherMarkerCount = 0
  self.stayStandAloneMarkerCount = 0
  self.stayStandTogetherMarkerCount = 0
end
