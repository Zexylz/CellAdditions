local _, ns = ...

-- Get localization table
local L = ns.L or {}

-- Ensure critical strings exist with fallbacks
L["Shadow"] = L["Shadow"] or "Shadow"
L["Add dynamic shadow effects to Cell unit frames and bars"] = L["Add dynamic shadow effects to Cell unit frames and bars"]
  or "Add dynamic shadow effects to Cell unit frames and bars"
L["Enable Shadow"] = L["Enable Shadow"] or "Enable Shadow"
L["Shadow Size"] = L["Shadow Size"] or "Shadow Size"
L["Cell"] = L["Cell"] or "Cell"
L["Solo Frame"] = L["Solo Frame"] or "Solo Frame"
L["Party Frames"] = L["Party Frames"] or "Party Frames"
L["Raid Frames"] = L["Raid Frames"] or "Raid Frames"
L["Player Frame"] = L["Player Frame"] or "Player Frame"
L["Target Frame"] = L["Target Frame"] or "Target Frame"
L["Target's Target Frame"] = L["Target's Target Frame"] or "Target's Target Frame"
L["Focus Frame"] = L["Focus Frame"] or "Focus Frame"
L["Pet Frame"] = L["Pet Frame"] or "Pet Frame"

-- ============================================================================
-- Shadow Module - Advanced OOP Implementation
-- ============================================================================

local Shadow = {}
Shadow.__index = Shadow
ns.Shadow = Shadow

-- Module metadata
Shadow.name = L["Shadow"] or "Shadow"
Shadow.id = "Shadow"
Shadow.description = L["Add dynamic shadow effects to Cell unit frames and bars"]
  or "Add dynamic shadow effects to Cell unit frames and bars"
Shadow.version = "1.0"

-- Constants
local SHADOW_TEXTURE = "Interface/AddOns/CellAdditions/Media/glowTex.tga"
local FRAME_STRATA = "BACKGROUND"
local SHADOW_INSET_MULTIPLIER = 1.2
local SHADOW_SIZE_MULTIPLIER = 1.5
local MIN_ALPHA = 0.7

-- Default settings
local DEFAULT_SETTINGS = {
  enabled = true,
  shadowSize = 5,

  -- Frame type configurations
  frameTypes = {
    solo = {
      enabled = true,
      color = { 0.7, 0.9, 0.3, 1 },
    },
    party = {
      enabled = true,
      color = { 0.7, 0.9, 0.3, 1 },
    },
    raid = {
      enabled = false,
      color = { 0.9, 0.7, 0.3, 1 },
    },
  },

  -- Unit frame configurations
  unitFrames = {
    Player = {
      enabled = true,
      healthColor = { 0.7, 0.9, 0.3, 1 },
      powerColor = { 0.9, 0.7, 0.3, 1 },
    },
    Target = {
      enabled = true,
      healthColor = { 0.9, 0.7, 0.3, 1 },
      powerColor = { 0.9, 0.5, 0.3, 1 },
    },
    TargetTarget = {
      enabled = false,
      healthColor = { 0.9, 0.3, 0.5, 1 },
      powerColor = { 0.9, 0.3, 0.5, 1 },
    },
    Focus = {
      enabled = true,
      healthColor = { 0.7, 0.3, 0.7, 1 },
      powerColor = { 0.5, 0.3, 0.7, 1 },
    },
    Pet = {
      enabled = false,
      healthColor = { 0.5, 0.3, 0.7, 1 },
      powerColor = { 0.5, 0.3, 0.7, 1 },
    },
  },
}

-- Frame detection patterns
local FRAME_PATTERNS = {
  solo = {
    "CellSoloFramePlayer",
    "CellSoloFrame",
  },
  party = {
    "CellPartyFrameHeaderUnitButton%d",
  },
  raid = {
    "CellRaidFrameHeader%dUnitButton%d",
  },
  unitframes = {
    Player = { "CUF_Player", "CellUnitFramePlayer" },
    Target = { "CUF_Target", "TargetFrame", "CellUnitFrameTarget", "CellTargetFrame", "Cell_TargetFrame" },
    TargetTarget = { "CUF_TargetTarget", "TargetFrameToT" },
    Focus = { "CUF_Focus", "FocusFrame", "CellUnitFrameFocus", "CellFocusFrame", "Cell_FocusFrame" },
    Pet = { "CUF_Pet", "PetFrame", "CellUnitFramePet", "CellPetFrame", "Cell_PetFrame" },
  },
}

-- ============================================================================
-- Utility Functions
-- ============================================================================

local Utils = {}

function Utils:Debug(msg)
  if ns.Debug then
    ns.Debug("[Shadow] " .. tostring(msg))
  end
end

function Utils:DeepCopy(orig)
  local copy
  if type(orig) == "table" then
    copy = {}
    for k, v in pairs(orig) do
      copy[k] = self:DeepCopy(v)
    end
  else
    copy = orig
  end
  return copy
end

function Utils:MergeDefaults(settings, defaults)
  for key, value in pairs(defaults) do
    if settings[key] == nil then
      settings[key] = value
    elseif type(value) == "table" and type(settings[key]) == "table" then
      self:MergeDefaults(settings[key], value)
    end
  end
end

function Utils:IsFrameValid(frame)
  return frame and type(frame.IsVisible) == "function" and frame:IsVisible() and frame:GetAlpha() > 0
end

-- ============================================================================
-- Settings Manager
-- ============================================================================

local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager:New()
  local instance = setmetatable({}, self)
  instance.settings = nil
  return instance
end

function SettingsManager:Initialize()
  CellAdditionsDB = CellAdditionsDB or {}

  if not CellAdditionsDB.shadowSettings then
    CellAdditionsDB.shadowSettings = Utils:DeepCopy(DEFAULT_SETTINGS)
    Utils:Debug("Created default shadow settings")
  else
    Utils:MergeDefaults(CellAdditionsDB.shadowSettings, DEFAULT_SETTINGS)
    Utils:Debug("Merged default settings with existing")
  end

  self.settings = CellAdditionsDB.shadowSettings
  Utils:Debug("Settings manager initialized")
end

function SettingsManager:Get(key) return self.settings[key] end

function SettingsManager:Set(key, value) self.settings[key] = value end

function SettingsManager:GetAll() return self.settings end

function SettingsManager:GetFrameTypeSettings(frameType) return self.settings.frameTypes[frameType] end

function SettingsManager:GetUnitFrameSettings(unitType) return self.settings.unitFrames[unitType] end

-- ============================================================================
-- Shadow Object
-- ============================================================================

local ShadowObject = {}
ShadowObject.__index = ShadowObject

function ShadowObject:New(frame, frameType, shadowType)
  local instance = setmetatable({}, self)
  instance.frame = frame
  instance.frameType = frameType
  instance.shadowType = shadowType or "default"
  instance.shadowFrame = nil
  instance.lastUpdate = 0
  return instance
end

function ShadowObject:Create()
  if self.shadowFrame or not self.frame then
    return false
  end

  -- Create shadow frame
  local shadowFrame = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
  shadowFrame:SetFrameStrata(FRAME_STRATA)

  -- Set frame level safely
  local frameLevel = 0
  pcall(function() frameLevel = math.max(0, self.frame:GetFrameLevel() - 1) end)
  shadowFrame:SetFrameLevel(frameLevel)

  self.shadowFrame = shadowFrame
  Utils:Debug("Created shadow for " .. (self.frame:GetName() or "unnamed"))
  return true
end

function ShadowObject:Update(size, color)
  if not self.shadowFrame or not color then
    return false
  end

  local effectiveSize = size * SHADOW_SIZE_MULTIPLIER
  local insetSize = effectiveSize * SHADOW_INSET_MULTIPLIER

  -- Position shadow
  self.shadowFrame:ClearAllPoints()
  self.shadowFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -effectiveSize, effectiveSize)
  self.shadowFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", effectiveSize, -effectiveSize)

  -- Configure backdrop
  self.shadowFrame:SetBackdrop({
    edgeFile = SHADOW_TEXTURE,
    edgeSize = effectiveSize,
    insets = {
      left = insetSize,
      right = insetSize,
      top = insetSize,
      bottom = insetSize,
    },
  })

  -- Apply color with minimum alpha
  local alpha = math.max(MIN_ALPHA, color[4] or 1)
  self.shadowFrame:SetBackdropColor(0, 0, 0, 0)
  self.shadowFrame:SetBackdropBorderColor(color[1], color[2], color[3], alpha)

  self.lastUpdate = GetTime()
  return true
end

function ShadowObject:Show()
  if self.shadowFrame then
    self.shadowFrame:Show()
  end
end

function ShadowObject:Hide()
  if self.shadowFrame then
    self.shadowFrame:Hide()
  end
end

function ShadowObject:Destroy()
  if self.shadowFrame then
    self.shadowFrame:Hide()
    self.shadowFrame:SetParent(nil)
    self.shadowFrame = nil
  end
end

-- ============================================================================
-- Shadow Manager
-- ============================================================================

local ShadowManager = {}
ShadowManager.__index = ShadowManager

function ShadowManager:New(settingsManager)
  local instance = setmetatable({}, self)
  instance.settingsManager = settingsManager
  instance.shadowObjects = setmetatable({}, { __mode = "k" }) -- weak table
  instance.lastScan = 0
  instance.scanInterval = 0.5
  return instance
end

function ShadowManager:CreateShadow(frame, frameType, shadowType)
  if not Utils:IsFrameValid(frame) or self.shadowObjects[frame] then
    return nil
  end

  local shadowObj = ShadowObject:New(frame, frameType, shadowType)
  if shadowObj:Create() then
    self.shadowObjects[frame] = shadowObj
    Utils:Debug("Shadow created for " .. frameType .. " frame")
    return shadowObj
  end

  return nil
end

function ShadowManager:UpdateShadow(frame, color)
  local shadowObj = self.shadowObjects[frame]
  if not shadowObj then
    return false
  end

  local settings = self.settingsManager:GetAll()
  return shadowObj:Update(settings.shadowSize, color)
end

function ShadowManager:UpdateAllShadows()
  local settings = self.settingsManager:GetAll()

  if not settings.enabled then
    self:HideAllShadows()
    return
  end

  for frame, shadowObj in pairs(self.shadowObjects) do
    if Utils:IsFrameValid(frame) then
      local color = self:GetShadowColor(shadowObj.frameType, shadowObj.shadowType)
      local shouldShow = self:ShouldShowShadow(shadowObj.frameType)

      if shouldShow and color then
        shadowObj:Update(settings.shadowSize, color)
        shadowObj:Show()
      else
        shadowObj:Hide()
      end
    else
      shadowObj:Destroy()
      self.shadowObjects[frame] = nil
    end
  end
end

function ShadowManager:GetShadowColor(frameType, shadowType)
  local settings = self.settingsManager:GetAll()

  -- Unit frames have specific color handling
  if settings.unitFrames[frameType] then
    local unitSettings = settings.unitFrames[frameType]
    if shadowType == "power" then
      return unitSettings.powerColor
    else
      return unitSettings.healthColor
    end
  end

  -- Frame type colors
  if settings.frameTypes[frameType] then
    return settings.frameTypes[frameType].color
  end

  -- Default color
  return { 0, 0, 0, 1 }
end

function ShadowManager:ShouldShowShadow(frameType)
  local settings = self.settingsManager:GetAll()

  -- Check unit frames
  if settings.unitFrames[frameType] then
    return settings.unitFrames[frameType].enabled
  end

  -- Check frame types
  if settings.frameTypes[frameType] then
    return settings.frameTypes[frameType].enabled
  end

  return false
end

function ShadowManager:HideAllShadows()
  for frame, shadowObj in pairs(self.shadowObjects) do
    shadowObj:Hide()
  end
end

function ShadowManager:DestroyAllShadows()
  for frame, shadowObj in pairs(self.shadowObjects) do
    shadowObj:Destroy()
  end
  self.shadowObjects = setmetatable({}, { __mode = "k" })
end

function ShadowManager:GetActiveCount()
  local count = 0
  for _ in pairs(self.shadowObjects) do
    count = count + 1
  end
  return count
end

-- ============================================================================
-- Frame Scanner
-- ============================================================================

local FrameScanner = {}
FrameScanner.__index = FrameScanner

function FrameScanner:New(shadowManager, settingsManager)
  local instance = setmetatable({}, self)
  instance.shadowManager = shadowManager
  instance.settingsManager = settingsManager
  return instance
end

function FrameScanner:ScanAllFrames()
  local settings = self.settingsManager:GetAll()

  if not settings.enabled then
    return
  end

  -- Scan unit frames
  for unitType, patterns in pairs(FRAME_PATTERNS.unitframes) do
    if settings.unitFrames[unitType] and settings.unitFrames[unitType].enabled then
      self:ScanUnitFrames(unitType, patterns)
    end
  end

  -- Scan group frames
  if settings.frameTypes.solo.enabled then
    self:ScanGroupFrames("solo", FRAME_PATTERNS.solo)
  end

  if settings.frameTypes.party.enabled then
    self:ScanGroupFrames("party", FRAME_PATTERNS.party)
  end

  if settings.frameTypes.raid.enabled then
    self:ScanGroupFrames("raid", FRAME_PATTERNS.raid)
  end
end

function FrameScanner:ScanUnitFrames(unitType, patterns)
  Utils:Debug("Scanning for " .. unitType .. " frames...")

  for _, pattern in ipairs(patterns) do
    local frame = _G[pattern]
    Utils:Debug("Checking pattern '" .. pattern .. "': " .. (frame and "FOUND" or "NOT FOUND"))
    if Utils:IsFrameValid(frame) then
      Utils:Debug("Creating shadow for " .. unitType .. " frame: " .. pattern)
      self.shadowManager:CreateShadow(frame, unitType, "health")

      -- Look for health/power bars
      local healthBar = self:FindChildFrame(frame, "HealthBar")
      if healthBar then
        self.shadowManager:CreateShadow(healthBar, unitType, "health")
      end

      -- Only create power bar shadow if power bar actually exists and is visible
      local powerBar = self:FindChildFrame(frame, "PowerBar")
      if powerBar and Utils:IsFrameValid(powerBar) then
        self.shadowManager:CreateShadow(powerBar, unitType, "power")
      end
    elseif frame then
      Utils:Debug("Frame exists but not valid (hidden/transparent): " .. pattern)
    end
  end
end

function FrameScanner:ScanGroupFrames(frameType, patterns)
  for _, pattern in ipairs(patterns) do
    if pattern:find("%%d") then
      -- Pattern with numbers - scan ranges
      if frameType == "party" then
        for i = 1, 5 do
          local frameName = pattern:gsub("%%d", i)
          local frame = _G[frameName]
          if Utils:IsFrameValid(frame) then
            self.shadowManager:CreateShadow(frame, frameType)
          end
        end
      elseif frameType == "raid" then
        for i = 1, 8 do
          for j = 1, 5 do
            local frameName = pattern:gsub("%%d", i, 1):gsub("%%d", j, 1)
            local frame = _G[frameName]
            if Utils:IsFrameValid(frame) then
              self.shadowManager:CreateShadow(frame, frameType)
            end
          end
        end
      end
    else
      -- Direct frame name
      local frame = _G[pattern]
      if Utils:IsFrameValid(frame) then
        self.shadowManager:CreateShadow(frame, frameType)
      end
    end
  end
end

function FrameScanner:FindChildFrame(parent, namePattern)
  if not parent then
    return nil
  end

  for _, child in pairs({ parent:GetChildren() }) do
    local name = child:GetName()
    if name and name:find(namePattern) then
      return child
    end
  end

  return nil
end

-- ============================================================================
-- UI Manager
-- ============================================================================

local UIManager = {}
UIManager.__index = UIManager

function UIManager:New(settingsManager, shadowManager)
  local instance = setmetatable({}, self)
  instance.settingsManager = settingsManager
  instance.shadowManager = shadowManager
  return instance
end

function UIManager:CreateSettings(parent)
  local Cell = ns.Cell or _G.Cell
  if not Cell then
    Utils:Debug("Cell not available for settings UI")
    return
  end

  local container = parent
  local settings = self.settingsManager:GetAll()

  -- Create sections without separators
  local lastElement = self:CreateGeneralSettings(container, settings)
  lastElement = self:CreateFrameTypeSettings(container, settings, lastElement)
  self:CreateUnitFrameSettings(container, settings, lastElement)

  -- Calculate and set proper content height
  local totalHeight = 400 -- Base height for all the content
  container:SetHeight(totalHeight)

  -- Update scroll frame if it exists
  if container.GetParent and container:GetParent().scrollFrame then
    local scrollFrame = container:GetParent().scrollFrame
    scrollFrame:UpdateScrollChildRect()

    -- Hide scrollbar if content fits
    local contentHeight = container:GetHeight()
    local visibleHeight = scrollFrame:GetHeight()
    if contentHeight <= visibleHeight then
      if scrollFrame.scrollBar then
        scrollFrame.scrollBar:Hide()
      end
    else
      if scrollFrame.scrollBar then
        scrollFrame.scrollBar:Show()
      end
    end
  end

  return container
end

function UIManager:CreateGeneralSettings(parent, settings)
  local Cell = ns.Cell or _G.Cell

  -- Main enable checkbox
  local enableCB = Cell.CreateCheckButton(parent, L["Enable Shadow"] or "Enable Shadow", function(checked)
    self.settingsManager:Set("enabled", checked)
    self:TriggerShadowUpdate()
  end)
  enableCB:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -10)
  enableCB:SetChecked(settings.enabled)

  -- Shadow size slider
  local sizeLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  sizeLabel:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 0, -15)
  sizeLabel:SetText(L["Shadow Size"] or "Shadow Size")

  local sizeSlider = Cell.CreateSlider("", parent, 1, 15, 240, 1)
  sizeSlider:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -2)
  sizeSlider:SetValue(settings.shadowSize)

  sizeSlider.afterValueChangedFn = function(value)
    local newValue = math.floor(value)
    self.settingsManager:Set("shadowSize", newValue)
    self:TriggerShadowUpdate()
  end

  -- Add some spacing after the slider by creating an invisible spacer
  local spacer = parent:CreateTexture(nil, "ARTWORK")
  spacer:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -15)
  spacer:SetSize(1, 1)
  spacer:SetColorTexture(0, 0, 0, 0)

  return spacer
end

function UIManager:CreateFrameTypeSettings(parent, settings, anchor)
  local Cell = ns.Cell or _G.Cell

  -- Section header
  local header = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
  header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
  header:SetText(L["Cell"] or "Cell")

  -- Add underline under the header text
  local accentColor = Cell.GetAccentColorTable and Cell.GetAccentColorTable() or { 1, 1, 1 }
  local underline = parent:CreateTexture(nil, "ARTWORK")
  underline:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.6)
  local textWidth = header:GetStringWidth()
  underline:SetSize(textWidth, 1)
  underline:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)

  local lastElement = header

  local frameTypes = {
    { key = "solo", name = L["Solo Frame"] or "Solo Frame" },
    { key = "party", name = L["Party Frames"] or "Party Frames" },
    { key = "raid", name = L["Raid Frames"] or "Raid Frames" },
  }

  for _, frameType in ipairs(frameTypes) do
    local typeSettings = settings.frameTypes[frameType.key]

    -- Checkbox
    local cb = Cell.CreateCheckButton(parent, frameType.name, function(checked)
      typeSettings.enabled = checked
      self:TriggerShadowUpdate()
    end)
    cb:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -10)
    cb:SetChecked(typeSettings.enabled)

    -- Color picker - positioned to fit within bounds
    local colorPicker = Cell.CreateColorPicker(parent, "", true, function(r, g, b, a)
      typeSettings.color = { r, g, b, a }
      self:TriggerShadowUpdate()
    end)
    colorPicker:SetPoint("TOPLEFT", cb, "TOPLEFT", 225, 1)
    local color = typeSettings.color
    colorPicker:SetColor(color[1], color[2], color[3], color[4])

    lastElement = cb
  end

  return lastElement
end

function UIManager:CreateUnitFrameSettings(parent, settings, anchor)
  local Cell = ns.Cell or _G.Cell

  -- Section header with extra padding
  local header = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
  header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -20)
  header:SetText(L["Cell - Unit Frames"] or "Cell- Unit Frames")

  -- Add underline under the header text
  local accentColor = Cell.GetAccentColorTable and Cell.GetAccentColorTable() or { 1, 1, 1 }
  local underline = parent:CreateTexture(nil, "ARTWORK")
  underline:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.6)
  local textWidth = header:GetStringWidth()
  underline:SetSize(textWidth, 1)
  underline:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)

  local lastElement = header

  local unitFrames = {
    { key = "Player", name = L["Player Frame"] or "Player Frame" },
    { key = "Target", name = L["Target Frame"] or "Target Frame" },
    { key = "TargetTarget", name = L["Target's Target Frame"] or "Target's Target Frame" },
    { key = "Focus", name = L["Focus Frame"] or "Focus Frame" },
    { key = "Pet", name = L["Pet Frame"] or "Pet Frame" },
  }

  -- Store references to first row color pickers for header positioning
  local firstHealthPicker = nil
  local firstPowerPicker = nil

  for i, unitFrame in ipairs(unitFrames) do
    local unitSettings = settings.unitFrames[unitFrame.key]

    -- Checkbox
    local cb = Cell.CreateCheckButton(parent, unitFrame.name, function(checked)
      unitSettings.enabled = checked
      self:TriggerShadowUpdate()
    end)
    cb:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -10)
    cb:SetChecked(unitSettings.enabled)

    -- Health color picker - centered under HB header
    local healthPicker = Cell.CreateColorPicker(parent, "", true, function(r, g, b, a)
      unitSettings.healthColor = { r, g, b, a }
      self:TriggerShadowUpdate()
    end)
    healthPicker:SetPoint("TOPLEFT", cb, "TOPLEFT", 220, 1)
    local healthColor = unitSettings.healthColor
    healthPicker:SetColor(healthColor[1], healthColor[2], healthColor[3], healthColor[4])

    -- Power color picker - always show but only applies if power bar exists
    local powerPicker = Cell.CreateColorPicker(parent, "", true, function(r, g, b, a)
      unitSettings.powerColor = { r, g, b, a }
      self:TriggerShadowUpdate()
    end)
    powerPicker:SetPoint("TOPLEFT", cb, "TOPLEFT", 247, 1)
    local powerColor = unitSettings.powerColor
    powerPicker:SetColor(powerColor[1], powerColor[2], powerColor[3], powerColor[4])

    -- Store first row pickers for header positioning
    if i == 1 then
      firstHealthPicker = healthPicker
      firstPowerPicker = powerPicker
    end

    lastElement = cb
  end

  -- Create column headers anchored to the first row's color pickers
  if firstHealthPicker and firstPowerPicker then
    -- Create interactive button frames instead of font strings for better mouse handling
    local hbFrame = CreateFrame("Button", nil, parent)
    hbFrame:SetSize(20, 16)
    hbFrame:SetPoint("BOTTOM", firstHealthPicker, "TOP", 0, 5)
    
    local hbLabel = hbFrame:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    hbLabel:SetPoint("CENTER", hbFrame, "CENTER", 0, 0)
    hbLabel:SetText("HB")
    hbLabel:SetJustifyH("CENTER")

    local pbFrame = CreateFrame("Button", nil, parent)
    pbFrame:SetSize(20, 16)
    pbFrame:SetPoint("BOTTOM", firstPowerPicker, "TOP", 0, 5)
    
    local pbLabel = pbFrame:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    pbLabel:SetPoint("CENTER", pbFrame, "CENTER", 0, 0)
    pbLabel:SetText("PB")
    pbLabel:SetJustifyH("CENTER")

    -- Add tooltips to explain what HB and PB mean
    if ns.Tooltip then
      ns.Tooltip:Attach(hbFrame, "Health Bar")
      ns.Tooltip:Attach(pbFrame, "Power Bar")
    end

    -- Add vertical separator between color picker columns
    local verticalSeparator = parent:CreateTexture(nil, "ARTWORK")
    verticalSeparator:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.7)
    verticalSeparator:SetSize(1, 130)
    verticalSeparator:SetPoint("TOP", hbLabel, "BOTTOM", 14, 12)
  end

  return lastElement
end

function UIManager:TriggerShadowUpdate()
    if ns.Shadow and ns.Shadow.shadowManager then
      ns.Shadow.shadowManager:UpdateAllShadows()
    end
end

-- ============================================================================
-- Main Shadow Class
-- ============================================================================

function Shadow:New()
  local instance = setmetatable({}, self)

  -- Initialize managers
  instance.settingsManager = SettingsManager:New()
  instance.shadowManager = ShadowManager:New(instance.settingsManager)
  instance.frameScanner = FrameScanner:New(instance.shadowManager, instance.settingsManager)
  instance.uiManager = UIManager:New(instance.settingsManager, instance.shadowManager)

  instance.initialized = false
  instance.eventFrame = nil
  return instance
end

function Shadow:Initialize()
  if self.initialized then
    return
  end

  -- Initialize settings
  self.settingsManager:Initialize()

  -- Check if module is enabled
  if not self.settingsManager:Get("enabled") then
    Utils:Debug("Shadow module disabled in settings")
    return
  end

  -- Register events
  self:RegisterEvents()

  -- Register Cell callbacks
  self:RegisterCallbacks()

  self.initialized = true
  Utils:Debug("Shadow module initialized successfully")

  -- Initial scan (immediate)
  self:Update()
end

function Shadow:RegisterEvents()
  self.eventFrame = CreateFrame("Frame")
  local events = {
    "PLAYER_ENTERING_WORLD",
    "GROUP_ROSTER_UPDATE",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_FOCUS_CHANGED",
  }

  for _, event in ipairs(events) do
    self.eventFrame:RegisterEvent(event)
  end

  self.eventFrame:SetScript("OnEvent", function(_, event)
    -- Add small delay for target/focus changes to allow frames to be created
    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
      C_Timer.After(0.1, function() self:Update() end)
    else
      -- Immediate update for other events
      self:Update()
    end
  end)

  Utils:Debug("Registered WoW events")
end

function Shadow:RegisterCallbacks()
  local Cell = ns.Cell or _G.Cell
  if not Cell or not Cell.RegisterCallback then
    Utils:Debug("Cell callbacks not available")
    return
  end

  local callbacks = {
    "Cell_UnitButtonCreated",
    "Cell_Layout_Updated",
    "Cell_Group_Updated",
  }

  for _, callbackName in ipairs(callbacks) do
    Cell:RegisterCallback(callbackName, function() self:Update() end)
  end

  Utils:Debug("Registered Cell callbacks")
end

function Shadow:Update()
  if not self.initialized or not self.settingsManager:Get("enabled") then
    return
  end

  -- Scan for new frames
  self.frameScanner:ScanAllFrames()

  -- Update all shadows
  self.shadowManager:UpdateAllShadows()

  Utils:Debug("Shadow update complete: " .. self.shadowManager:GetActiveCount() .. " shadows active")
end

function Shadow:SetEnabled(enabled)
  if not CellAdditionsDB then
    Utils:Debug("Database not available")
    return
  end

  local wasEnabled = self.settingsManager:Get("enabled")
  self.settingsManager:Set("enabled", enabled)

  Utils:Debug("Shadow module " .. (enabled and "enabled" or "disabled"))

  if enabled and not wasEnabled then
    self:Initialize()
    self:Update()
  elseif not enabled and wasEnabled then
    self.shadowManager:DestroyAllShadows()
  end
end

function Shadow:CreateSettings(parent) return self.uiManager:CreateSettings(parent) end

-- ============================================================================
-- Module Registration
-- ============================================================================

-- Create singleton instance
local shadowInstance = Shadow:New()

-- Export to namespace
ns.Shadow = shadowInstance
ns.addon = ns.addon or {}
ns.addon.Shadow = shadowInstance

-- Export the class for direct access if needed
ns.ShadowClass = Shadow

-- Register module (immediate)
  if ns.RegisterModule then
    ns.RegisterModule(shadowInstance)
    Utils:Debug("Shadow module registered with module system")
  else
    Utils:Debug("Module system not available for registration")
  end
