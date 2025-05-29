local _, ns = ...

-- Get localization table
local L = ns.L or {}

-- Ensure critical strings exist with fallbacks
L["Clicker"] = L["Clicker"] or "Clicker"
L["Enhanced click functionality with customizable textures for unit frames"] = L["Enhanced click functionality with customizable textures for unit frames"]
  or "Enhanced click functionality with customizable textures for unit frames"
L["General Settings"] = L["General Settings"] or "General Settings"
L["Clicker Settings"] = L["Clicker Settings"] or "Clicker Settings"

local Clicker = {}
Clicker.__index = Clicker
ns.Clicker = Clicker

-- Module metadata
Clicker.name = L["Clicker"] or "Clicker"
Clicker.id = "clicker"
Clicker.description = L["Enhanced click functionality with customizable textures for unit frames"]
  or "Enhanced click functionality with customizable textures for unit frames"
Clicker.version = "2.0"

-- Constants
local FRAME_LEVEL = 4
local FRAME_STRATA = "MEDIUM"
local TEXTURE_PATH = "Interface/AddOns/CellAdditions/Media/Textures/"

-- Default settings
local DEFAULT_SETTINGS = {
  enabled = true,
  width = 100,
  height = 150,
  useCustomSize = false,
  offsetX = 0,
  offsetY = 0,
  debug = false,
  textureEnabled = false,
  selectedTexture = "none",
  textureAlpha = 0.8,
  textureBlendMode = "BLEND",
  ninesliceSettings = {
    borderWidth = 16,
    borderHeight = 16,
    textureWidth = 64,
    textureHeight = 64,
    forceNineslice = false, -- Debug option to force nineslice on all textures
  },
}

local Utils = {}

function Utils:Debug(msg)
  if ns.Debug then
    ns.Debug("[Clicker] " .. tostring(msg))
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

local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager:New()
  local instance = setmetatable({}, self)
  instance.settings = nil
  return instance
end

function SettingsManager:Initialize()
  CellAdditionsDB = CellAdditionsDB or {}

  if not CellAdditionsDB.clickerSettings then
    CellAdditionsDB.clickerSettings = Utils:DeepCopy(DEFAULT_SETTINGS)
    Utils:Debug("Created default clicker settings")
  else
    Utils:MergeDefaults(CellAdditionsDB.clickerSettings, DEFAULT_SETTINGS)
    Utils:Debug("Merged default settings with existing")
  end

  self.settings = CellAdditionsDB.clickerSettings
  Utils:Debug("Settings manager initialized")
end

function SettingsManager:Get(key) return self.settings[key] end

function SettingsManager:Set(key, value) self.settings[key] = value end

function SettingsManager:GetAll() return self.settings end

local TextureManager = {}
TextureManager.__index = TextureManager

function TextureManager:New()
  local instance = setmetatable({}, self)
  instance.availableTextures = {}
  instance.scanned = false
  return instance
end

function TextureManager:LoadUserTextures()
  -- Check if user textures were registered from the Lua file
  local userTextures = _G.CellAdditions_PendingTextures or {}

  -- Clear the global to avoid duplicates
  _G.CellAdditions_PendingTextures = nil

  Utils:Debug("Loaded " .. #userTextures .. " textures from TextureList.lua")
  for i, texture in ipairs(userTextures) do
    Utils:Debug("  " .. i .. ": " .. texture)
  end

  return userTextures
end

function TextureManager:ScanTextures()
  if self.scanned then
    return self.availableTextures
  end

  -- Always include "none" option first
  self.availableTextures = {
    { id = "none", name = "No Texture", file = nil },
  }

  -- Get user-registered textures from the simple list
  local userTextures = self:LoadUserTextures()

  -- Add each texture from the list
  for _, filename in ipairs(userTextures) do
    -- Extract base name from filename (remove extension)
    local baseName = filename:match("^(.+)%..+$") or filename
    local displayName = baseName:gsub("^%l", string.upper):gsub("_", " "):gsub("%-", " ")

    table.insert(self.availableTextures, {
      id = baseName,
      name = displayName,
      file = filename,
    })
    Utils:Debug("Added texture: " .. filename .. " -> " .. displayName)
  end

  self.scanned = true
  Utils:Debug("Texture scan complete: " .. (#self.availableTextures - 1) .. " textures loaded")

  return self.availableTextures
end

function TextureManager:GetTexturePath(textureId)
  local textures = self:ScanTextures()

  for _, texture in ipairs(textures) do
    if texture.id == textureId then
      local fullPath = texture.file and (TEXTURE_PATH .. texture.file) or nil
      Utils:Debug("GetTexturePath for " .. textureId .. ": " .. tostring(fullPath))
      return fullPath
    end
  end
  Utils:Debug("GetTexturePath: No texture found for id " .. textureId)
  return nil
end

function TextureManager:IsNinesliceTexture(textureId)
  -- Determine if this texture should use nineslice based on name patterns
  -- Nineslice is best for textures that have borders/decorative edges
  local nineslicePatterns = { 
    "nineslice", "9slice", "border", "frame", "button", "panel", "window", "dialog", "box"
  }
  
  local name = textureId:lower()
  for _, pattern in ipairs(nineslicePatterns) do
    if name:find(pattern) then
      return true
    end
  end
  
  -- Simple patterns that work better with regular stretching
  local stretchPatterns = { "bar", "health", "mana", "line", "stripe", "simple" }
  for _, pattern in ipairs(stretchPatterns) do
    if name:find(pattern) then
      return false
    end
  end
  
  -- Default to false unless explicitly detected as nineslice
  return false
end

function TextureManager:CreateNinesliceFrame(parent, textureId, settings)
  if not settings.textureEnabled or textureId == "none" then
    return nil
  end

  local texturePath = self:GetTexturePath(textureId)
  if not texturePath then
    return nil
  end

  -- Create container frame
  local containerFrame = CreateFrame("Frame", nil, parent)
  containerFrame:SetAllPoints(parent)
  containerFrame:SetFrameLevel(parent:GetFrameLevel() + 2)

  -- Get nineslice configuration from settings
  local sliceConfig = Utils:DeepCopy(settings.ninesliceSettings or {
    borderWidth = 16,
    borderHeight = 16,
    textureWidth = 64,
    textureHeight = 64,
  })

  -- Calculate texture coordinates for 9 sections
  local cfg = sliceConfig
  local leftEdge = cfg.borderWidth / cfg.textureWidth
  local rightEdge = (cfg.textureWidth - cfg.borderWidth) / cfg.textureWidth
  local topEdge = cfg.borderHeight / cfg.textureHeight
  local bottomEdge = (cfg.textureHeight - cfg.borderHeight) / cfg.textureHeight
  
  -- Debug coordinate calculation
  Utils:Debug(string.format("Nineslice coords - Left: %.3f, Right: %.3f, Top: %.3f, Bottom: %.3f", 
    leftEdge, rightEdge, topEdge, bottomEdge))

  -- Create 9 texture pieces following proper nineslice principles
  local pieces = {}
  
  -- CORNERS (fixed size, never scale)
  -- Top-left corner
  pieces.topLeft = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.topLeft:SetTexture(texturePath)
  pieces.topLeft:SetTexCoord(0, leftEdge, 0, topEdge)
  
  -- Top-right corner
  pieces.topRight = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.topRight:SetTexture(texturePath)
  pieces.topRight:SetTexCoord(rightEdge, 1, 0, topEdge)
  
  -- Bottom-left corner
  pieces.bottomLeft = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.bottomLeft:SetTexture(texturePath)
  pieces.bottomLeft:SetTexCoord(0, leftEdge, bottomEdge, 1)
  
  -- Bottom-right corner
  pieces.bottomRight = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.bottomRight:SetTexture(texturePath)
  pieces.bottomRight:SetTexCoord(rightEdge, 1, bottomEdge, 1)
  
  -- EDGES (scale in one direction only)
  -- Top edge (scales horizontally)
  pieces.topEdge = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.topEdge:SetTexture(texturePath)
  pieces.topEdge:SetTexCoord(leftEdge, rightEdge, 0, topEdge)
  
  -- Bottom edge (scales horizontally)
  pieces.bottomEdge = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.bottomEdge:SetTexture(texturePath)
  pieces.bottomEdge:SetTexCoord(leftEdge, rightEdge, bottomEdge, 1)
  
  -- Left edge (scales vertically)
  pieces.leftEdge = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.leftEdge:SetTexture(texturePath)
  pieces.leftEdge:SetTexCoord(0, leftEdge, topEdge, bottomEdge)
  
  -- Right edge (scales vertically)
  pieces.rightEdge = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.rightEdge:SetTexture(texturePath)
  pieces.rightEdge:SetTexCoord(rightEdge, 1, topEdge, bottomEdge)
  
  -- CENTER (the actual content - scales in both directions)
  -- This should show the complete finished texture, not just a portion
  pieces.center = containerFrame:CreateTexture(nil, "OVERLAY")
  pieces.center:SetTexture(texturePath)
  -- Show the full texture for the center piece (complete content)
  pieces.center:SetTexCoord(0, 1, 0, 1)

  -- Apply alpha and blend mode to all pieces
  for _, piece in pairs(pieces) do
    piece:SetAlpha(settings.textureAlpha or 0.8)
    piece:SetBlendMode(settings.textureBlendMode or "BLEND")
  end

  -- Position the pieces
  self:LayoutNineslicePieces(containerFrame, pieces, cfg)

  containerFrame.pieces = pieces
  containerFrame.sliceConfig = cfg
  containerFrame:Show()

  Utils:Debug("Created nineslice texture frame: " .. textureId)
  return containerFrame
end

function TextureManager:LayoutNineslicePieces(container, pieces, config)
  local width = container:GetWidth()
  local height = container:GetHeight()
  local borderW = config.borderWidth
  local borderH = config.borderHeight

  -- Ensure minimum size
  if width < borderW * 2 then width = borderW * 2 end
  if height < borderH * 2 then height = borderH * 2 end

  -- Position corners (fixed size)
  pieces.topLeft:SetSize(borderW, borderH)
  pieces.topLeft:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)

  pieces.topRight:SetSize(borderW, borderH)
  pieces.topRight:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)

  pieces.bottomLeft:SetSize(borderW, borderH)
  pieces.bottomLeft:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)

  pieces.bottomRight:SetSize(borderW, borderH)
  pieces.bottomRight:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)

  -- Position edges (stretch in one direction)
  pieces.topEdge:SetHeight(borderH)
  pieces.topEdge:SetPoint("TOPLEFT", pieces.topLeft, "TOPRIGHT", 0, 0)
  pieces.topEdge:SetPoint("TOPRIGHT", pieces.topRight, "TOPLEFT", 0, 0)

  pieces.bottomEdge:SetHeight(borderH)
  pieces.bottomEdge:SetPoint("BOTTOMLEFT", pieces.bottomLeft, "BOTTOMRIGHT", 0, 0)
  pieces.bottomEdge:SetPoint("BOTTOMRIGHT", pieces.bottomRight, "BOTTOMLEFT", 0, 0)

  pieces.leftEdge:SetWidth(borderW)
  pieces.leftEdge:SetPoint("TOPLEFT", pieces.topLeft, "BOTTOMLEFT", 0, 0)
  pieces.leftEdge:SetPoint("BOTTOMLEFT", pieces.bottomLeft, "TOPLEFT", 0, 0)

  pieces.rightEdge:SetWidth(borderW)
  pieces.rightEdge:SetPoint("TOPRIGHT", pieces.topRight, "BOTTOMRIGHT", 0, 0)
  pieces.rightEdge:SetPoint("BOTTOMRIGHT", pieces.bottomRight, "TOPRIGHT", 0, 0)

  -- Position center (stretch in both directions)
  pieces.center:SetPoint("TOPLEFT", pieces.topLeft, "BOTTOMRIGHT", 0, 0)
  pieces.center:SetPoint("BOTTOMRIGHT", pieces.bottomRight, "TOPLEFT", 0, 0)
end

function TextureManager:CreateTextureFrame(parent, textureId, settings)
  if not settings.textureEnabled or textureId == "none" then
    return nil
  end

  -- Check if this texture should use nineslice
  if self:IsNinesliceTexture(textureId) or (settings.ninesliceSettings and settings.ninesliceSettings.forceNineslice) then
    return self:CreateNinesliceFrame(parent, textureId, settings)
  end

  -- Fall back to simple texture for non-nineslice textures
  local texturePath = self:GetTexturePath(textureId)
  if not texturePath then
    return nil
  end

  local textureFrame = CreateFrame("Frame", nil, parent)
  textureFrame:SetAllPoints(parent)
  textureFrame:SetFrameLevel(parent:GetFrameLevel() + 2)

  local texture = textureFrame:CreateTexture(nil, "OVERLAY")
  texture:SetAllPoints(textureFrame)
  texture:SetTexture(texturePath)
  texture:SetAlpha(settings.textureAlpha or 0.8)
  texture:SetBlendMode(settings.textureBlendMode or "BLEND")

  textureFrame.texture = texture
  textureFrame:Show()

  Utils:Debug("Created simple texture frame: " .. textureId)
  return textureFrame
end

function TextureManager:UpdateTexture(textureFrame, textureId, settings)
  if not textureFrame then
    return
  end

  if not settings.textureEnabled or textureId == "none" then
    textureFrame:Hide()
    return
  end

  -- Handle nineslice textures
  if textureFrame.pieces then
    -- Update nineslice pieces
    for _, piece in pairs(textureFrame.pieces) do
      piece:SetAlpha(settings.textureAlpha or 0.8)
      piece:SetBlendMode(settings.textureBlendMode or "BLEND")
    end
    
    -- Re-layout if frame size changed
    if textureFrame.sliceConfig then
      self:LayoutNineslicePieces(textureFrame, textureFrame.pieces, textureFrame.sliceConfig)
    end
    
    textureFrame:Show()
    Utils:Debug("Updated nineslice texture: " .. textureId)
    return
  end

  -- Handle simple textures
  if textureFrame.texture then
    local texturePath = self:GetTexturePath(textureId)
    if texturePath then
      textureFrame.texture:SetTexture(texturePath)
      textureFrame.texture:SetAlpha(settings.textureAlpha or 0.8)
      textureFrame.texture:SetBlendMode(settings.textureBlendMode or "BLEND")
      textureFrame:Show()
      Utils:Debug("Updated simple texture: " .. textureId)
    else
      textureFrame:Hide()
    end
  end
end

function TextureManager:GetAvailableTextures() return self:ScanTextures() end

function TextureManager:RescanTextures()
  self.scanned = false
  self.availableTextures = {}
  return self:ScanTextures()
end

local FrameManager = {}
FrameManager.__index = FrameManager

function FrameManager:New(settingsManager, textureManager)
  local instance = setmetatable({}, self)
  instance.settingsManager = settingsManager
  instance.textureManager = textureManager
  instance.activeFrames = {}
  instance.frameCounter = 0
  return instance
end

function FrameManager:CreateClickerFrame(unitButton)
  if not unitButton or type(unitButton.IsVisible) ~= "function" or not unitButton:IsVisible() then
    return nil
  end

  local settings = self.settingsManager:GetAll()
  self.frameCounter = self.frameCounter + 1

  -- Create hitbox frame (invisible)
  local hitboxName = "CellClicker_Hitbox_" .. self.frameCounter
  local hitbox = CreateFrame("Button", hitboxName, unitButton, "SecureActionButtonTemplate")
  hitbox:SetFrameStrata(FRAME_STRATA)
  hitbox:SetFrameLevel(FRAME_LEVEL)

  -- Configure position and size
  self:ConfigureFrameLayout(hitbox, unitButton, settings)

  -- Create texture frame if enabled
  Utils:Debug(
    "Attempting to create texture frame - textureEnabled: "
      .. tostring(settings.textureEnabled)
      .. ", selectedTexture: "
      .. tostring(settings.selectedTexture)
  )
  local textureFrame = self.textureManager:CreateTextureFrame(hitbox, settings.selectedTexture, settings)

  if textureFrame then
    Utils:Debug("Texture frame created and attached to hitbox")
  else
    Utils:Debug("No texture frame created")
  end

  -- Create debug overlay
  local debugOverlay = self:CreateDebugOverlay(unitButton, settings.debug)

  -- Configure secure attributes
  self:ConfigureSecureAttributes(hitbox, unitButton)

  -- Store components
  local clickerData = {
    hitbox = hitbox,
    textureFrame = textureFrame,
    debugOverlay = debugOverlay,
    unitButton = unitButton,
    name = hitboxName,
  }

  self.activeFrames[hitboxName] = clickerData

  Utils:Debug("Created clicker frame: " .. hitboxName)
  return clickerData
end

function FrameManager:ConfigureFrameLayout(frame, unitButton, settings)
  frame:ClearAllPoints()
  frame:EnableMouse(true)
  frame:RegisterForClicks("AnyDown", "AnyUp")

  if settings.useCustomSize then
    frame:SetSize(settings.width, settings.height)
    frame:SetPoint("CENTER", unitButton, "CENTER", settings.offsetX, settings.offsetY)
  else
    local pad = 15
    frame:SetPoint("TOPLEFT", unitButton, "TOPLEFT", -pad + settings.offsetX, pad + settings.offsetY)
    frame:SetPoint("BOTTOMRIGHT", unitButton, "BOTTOMRIGHT", pad + settings.offsetX, -pad + settings.offsetY)
  end
end

function FrameManager:CreateDebugOverlay(unitButton, debugEnabled)
  -- Create debug overlay that matches the healthbar size
  local healthBar = unitButton.widgets and unitButton.widgets.healthBar
  if not healthBar then
    return nil
  end

  local overlay = healthBar:CreateTexture(nil, "OVERLAY", nil, 7)
  overlay:SetAllPoints(healthBar)
  overlay:SetTexture("Interface\\Buttons\\WHITE8X8")
  overlay:SetVertexColor(0, 1, 0, 0.3)
  overlay:SetShown(debugEnabled)
  return overlay
end

function FrameManager:ConfigureSecureAttributes(hitbox, unitButton)
  local unitID = unitButton.unitid or unitButton.unit or unitButton:GetAttribute("unit")
  if not unitID then
    Utils:Debug("No unit ID found for clicker")
    return
  end

  -- Create secure unit button
  local unitClickButton = CreateFrame("Button", nil, hitbox, "SecureUnitButtonTemplate")
  unitClickButton:SetAllPoints(hitbox)
  unitClickButton:EnableMouse(true)
  unitClickButton:SetAttribute("unit", unitID)
  unitClickButton:RegisterForClicks("AnyUp")
  unitClickButton:SetAttribute("*type1", "target")
  unitClickButton:SetAttribute("*type2", "togglemenu")
  unitClickButton:SetAttribute("useparent-unit", true)
  unitClickButton:SetAttribute("*unitframe", "true")
  unitClickButton:SetAttribute("*unithasmenu", "true")

  hitbox.unitButton = unitClickButton
end

function FrameManager:UpdateAllFrames()
  local settings = self.settingsManager:GetAll()

  for name, clickerData in pairs(self.activeFrames) do
    if clickerData.hitbox and clickerData.hitbox:IsValid() then
      -- Update layout
      self:ConfigureFrameLayout(clickerData.hitbox, clickerData.unitButton, settings)

      -- Update texture
      if clickerData.textureFrame then
        self.textureManager:UpdateTexture(clickerData.textureFrame, settings.selectedTexture, settings)
      end

      -- Update debug overlay
      if clickerData.debugOverlay then
        clickerData.debugOverlay:SetShown(settings.debug)
      end
    else
      -- Clean up invalid frame
      self.activeFrames[name] = nil
    end
  end

  Utils:Debug("Updated " .. self:GetActiveFrameCount() .. " clicker frames")
end

function FrameManager:CleanupAllFrames()
  for name, clickerData in pairs(self.activeFrames) do
    if clickerData.hitbox then
      clickerData.hitbox:SetParent(nil)
      clickerData.hitbox:Hide()
    end
  end

  -- Clear global references
  for name, _ in pairs(_G) do
    if type(name) == "string" and name:match("^CellClicker_") then
      _G[name] = nil
    end
  end

  self.activeFrames = {}
  Utils:Debug("Cleaned up all clicker frames")
end

function FrameManager:GetActiveFrameCount()
  local count = 0
  for _ in pairs(self.activeFrames) do
    count = count + 1
  end
  return count
end

local LayoutManager = {}
LayoutManager.__index = LayoutManager

function LayoutManager:New(frameManager, settingsManager)
  local instance = setmetatable({}, self)
  instance.frameManager = frameManager
  instance.settingsManager = settingsManager
  return instance
end

function LayoutManager:UpdateLayout()
  if not self.settingsManager:Get("enabled") then
    self.frameManager:CleanupAllFrames()
    Utils:Debug("Clicker disabled, removed all frames")
    return
  end

  local Cell = ns.Cell or _G.Cell
  if not Cell or not _G.CUF or not _G.CUF.unitButtons then
    Utils:Debug("Required components not available for layout")
    return
  end

  -- Clean up existing frames first
  self.frameManager:CleanupAllFrames()

  -- Create new frames for visible unit buttons
  local unitButtons = _G.CUF.unitButtons
  local frameCount = 0

  for _, unitButton in pairs(unitButtons) do
    frameCount = frameCount + self:ProcessUnitButton(unitButton)
  end

  Utils:Debug("Layout complete: " .. frameCount .. " clicker frames created")
end

function LayoutManager:ProcessUnitButton(unitButton)
  local frameCount = 0

  if not unitButton then
    return frameCount
  end

  -- Check if this is a single frame or a table of frames
  if type(unitButton) == "table" and not unitButton.IsVisible then
    -- This is a table containing multiple frames (like boss frames)
    Utils:Debug("Processing nested frame table with " .. self:CountTable(unitButton) .. " frames")
    for frameKey, frame in pairs(unitButton) do
      if self:IsValidFrame(frame) then
        local clickerData = self.frameManager:CreateClickerFrame(frame)
        if clickerData then
          frameCount = frameCount + 1
          Utils:Debug("Created clicker for nested frame: " .. tostring(frameKey))
        end
      end
    end
  else
    -- This is a single frame
    if self:IsValidFrame(unitButton) then
      local clickerData = self.frameManager:CreateClickerFrame(unitButton)
      if clickerData then
        frameCount = frameCount + 1
        local frameName = unitButton:GetName() or "Unknown"
        Utils:Debug("Created clicker for single frame: " .. frameName)
      end
    end
  end

  return frameCount
end

function LayoutManager:CountTable(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

function LayoutManager:IsValidFrame(frame)
  return frame
    and type(frame.IsVisible) == "function"
    and frame:IsVisible()
    and frame.widgets
    and frame.widgets.healthBar
end

local UIManager = {}
UIManager.__index = UIManager

function UIManager:New(settingsManager, textureManager)
  local instance = setmetatable({}, self)
  instance.settingsManager = settingsManager
  instance.textureManager = textureManager
  return instance
end

function UIManager:CreateSettings(parent, enableCheckbox)
  local Cell = ns.Cell or _G.Cell
  if not Cell then
    Utils:Debug("Cell not available for settings UI")
    return
  end

  local content = parent

  -- Settings header
  local settingsHeader = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
  settingsHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -25)
  settingsHeader:SetText(L["Clicker Settings"] or "Clicker Settings")

  -- Create sections
  self:CreateGeneralSettings(content, settingsHeader)
  self:CreatePositionSettings(content)
  self:CreateTextureSettings(content)
  self:CreateNinesliceSettings(content)
  self:CreateAdvancedSettings(content)

  -- Calculate and set proper content height
  local totalHeight = 550 -- Base height for all the content (increased for nineslice settings)
  content:SetHeight(totalHeight)

  -- Update scroll frame if it exists
  if content.GetParent and content:GetParent().scrollFrame then
    local scrollFrame = content:GetParent().scrollFrame
    scrollFrame:UpdateScrollChildRect()

    -- Hide scrollbar if content fits
    local contentHeight = content:GetHeight()
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
end

function UIManager:CreateGeneralSettings(parent, anchor)
  local Cell = ns.Cell or _G.Cell
  local settings = self.settingsManager:GetAll()

  -- Section header
  local sectionHeader = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  sectionHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -20)
  sectionHeader:SetText(L["General Settings"] or "General Settings")

  -- Custom size checkbox
  local customSizeCheckbox = Cell.CreateCheckButton(parent, L["Use Custom Size"] or "Use Custom Size", function(checked)
    self.settingsManager:Set("useCustomSize", checked)
    self:UpdateWidgetStates()
    self:TriggerLayoutUpdate()
  end)
  customSizeCheckbox:SetPoint("TOPLEFT", sectionHeader, "BOTTOMLEFT", 5, -15)
  customSizeCheckbox:SetChecked(settings.useCustomSize)

  -- Width slider
  local widthLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  widthLabel:SetPoint("TOPLEFT", customSizeCheckbox, "BOTTOMLEFT", 0, -20)
  widthLabel:SetText(L["Width"] or "Width")

  local widthValue = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  widthValue:SetPoint("LEFT", widthLabel, "RIGHT", 50, 0)
  widthValue:SetText(tostring(settings.width))

  local widthSlider = Cell.CreateSlider("", parent, 20, 500, 180, 1)
  widthSlider:SetPoint("TOPLEFT", widthLabel, "BOTTOMLEFT", 0, -5)
  widthSlider:SetValue(settings.width)
  widthSlider:SetEnabled(settings.useCustomSize)
  widthSlider.afterValueChangedFn = function(value)
    local newValue = math.floor(value)
    self.settingsManager:Set("width", newValue)
    widthValue:SetText(tostring(newValue))
    self:TriggerLayoutUpdate()
  end

  -- Height slider
  local heightLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  heightLabel:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -25)
  heightLabel:SetText(L["Height"] or "Height")

  local heightValue = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  heightValue:SetPoint("LEFT", heightLabel, "RIGHT", 45, 0)
  heightValue:SetText(tostring(settings.height))

  local heightSlider = Cell.CreateSlider("", parent, 20, 500, 180, 1)
  heightSlider:SetPoint("TOPLEFT", heightLabel, "BOTTOMLEFT", 0, -5)
  heightSlider:SetValue(settings.height)
  heightSlider:SetEnabled(settings.useCustomSize)
  heightSlider.afterValueChangedFn = function(value)
    local newValue = math.floor(value)
    self.settingsManager:Set("height", newValue)
    heightValue:SetText(tostring(newValue))
    self:TriggerLayoutUpdate()
  end

  -- Store references for widget state updates
  self.widthSlider = widthSlider
  self.heightSlider = heightSlider
  self.lastAnchor = heightSlider
end

function UIManager:CreatePositionSettings(parent)
  local Cell = ns.Cell or _G.Cell
  local settings = self.settingsManager:GetAll()

  -- Section header
  local sectionHeader = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  sectionHeader:SetPoint("TOPLEFT", self.lastAnchor, "BOTTOMLEFT", 0, -35)
  sectionHeader:SetText("Position Settings")

  -- X Offset
  local xOffsetLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  xOffsetLabel:SetPoint("TOPLEFT", sectionHeader, "BOTTOMLEFT", 5, -15)
  xOffsetLabel:SetText("X Offset")

  local xOffsetValue = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  xOffsetValue:SetPoint("LEFT", xOffsetLabel, "RIGHT", 30, 0)
  xOffsetValue:SetText(tostring(settings.offsetX))

  local xOffsetSlider = Cell.CreateSlider("", parent, -50, 50, 180, 1)
  xOffsetSlider:SetPoint("TOPLEFT", xOffsetLabel, "BOTTOMLEFT", 0, -5)
  xOffsetSlider:SetValue(settings.offsetX)
  xOffsetSlider.afterValueChangedFn = function(value)
    local newValue = math.floor(value)
    self.settingsManager:Set("offsetX", newValue)
    xOffsetValue:SetText(tostring(newValue))
    self:TriggerLayoutUpdate()
  end

  -- Y Offset
  local yOffsetLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  yOffsetLabel:SetPoint("TOPLEFT", xOffsetSlider, "BOTTOMLEFT", 0, -25)
  yOffsetLabel:SetText("Y Offset")

  local yOffsetValue = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  yOffsetValue:SetPoint("LEFT", yOffsetLabel, "RIGHT", 30, 0)
  yOffsetValue:SetText(tostring(settings.offsetY))

  local yOffsetSlider = Cell.CreateSlider("", parent, -50, 50, 180, 1)
  yOffsetSlider:SetPoint("TOPLEFT", yOffsetLabel, "BOTTOMLEFT", 0, -5)
  yOffsetSlider:SetValue(settings.offsetY)
  yOffsetSlider.afterValueChangedFn = function(value)
    local newValue = math.floor(value)
    self.settingsManager:Set("offsetY", newValue)
    yOffsetValue:SetText(tostring(newValue))
    self:TriggerLayoutUpdate()
  end

  self.lastAnchor = yOffsetSlider
end

function UIManager:CreateTextureSettings(parent)
  local Cell = ns.Cell or _G.Cell
  local settings = self.settingsManager:GetAll()

  -- Section header
  local sectionHeader = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  sectionHeader:SetPoint("TOPLEFT", self.lastAnchor, "BOTTOMLEFT", 0, -35)
  sectionHeader:SetText("Texture Settings")

  -- Enable texture checkbox
  local textureCheckbox = Cell.CreateCheckButton(parent, "Enable Texture Overlay", function(checked)
    self.settingsManager:Set("textureEnabled", checked)
    Utils:Debug("[CellAdditions] Texture enabled: " .. tostring(checked)) -- Visible to user
    self:UpdateTextureWidgetStates()
    self:TriggerLayoutUpdate()
  end)
  textureCheckbox:SetPoint("TOPLEFT", sectionHeader, "BOTTOMLEFT", 5, -15)
  textureCheckbox:SetChecked(settings.textureEnabled)

  -- Texture dropdown
  local textureLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  textureLabel:SetPoint("TOPLEFT", textureCheckbox, "BOTTOMLEFT", 0, -20)
  textureLabel:SetText("Texture:")

  local textureDropdown = Cell.CreateDropdown(parent, 120)
  textureDropdown:SetPoint("LEFT", textureLabel, "RIGHT", 10, 0)

  -- Populate dropdown initially
  self:PopulateTextureDropdown(textureDropdown)
  textureDropdown:SetSelectedValue(settings.selectedTexture)
  textureDropdown:SetEnabled(settings.textureEnabled)

  -- Alpha slider
  local alphaLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  alphaLabel:SetPoint("TOPLEFT", textureLabel, "BOTTOMLEFT", 0, -35)
  alphaLabel:SetText("Texture Alpha")

  local alphaValue = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  alphaValue:SetPoint("LEFT", alphaLabel, "RIGHT", 20, 0)
  alphaValue:SetText(string.format("%.1f", settings.textureAlpha))

  local alphaSlider = Cell.CreateSlider("", parent, 0.1, 1.0, 180, 0.1)
  alphaSlider:SetPoint("TOPLEFT", alphaLabel, "BOTTOMLEFT", 0, -5)
  alphaSlider:SetValue(settings.textureAlpha)
  alphaSlider:SetEnabled(settings.textureEnabled)
  alphaSlider.afterValueChangedFn = function(value)
    self.settingsManager:Set("textureAlpha", value)
    alphaValue:SetText(string.format("%.1f", value))
    self:TriggerLayoutUpdate()
  end

  -- Store references
  self.textureDropdown = textureDropdown
  self.alphaSlider = alphaSlider
  self.lastAnchor = alphaSlider
end

function UIManager:CreateNinesliceSettings(parent)
  local Cell = ns.Cell or _G.Cell
  local settings = self.settingsManager:GetAll()

  -- Section header
  local sectionHeader = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  sectionHeader:SetPoint("TOPLEFT", self.lastAnchor, "BOTTOMLEFT", 0, -35)
  sectionHeader:SetText("Nineslice Settings")

  -- Border Width
  local borderWidthLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  borderWidthLabel:SetPoint("TOPLEFT", sectionHeader, "BOTTOMLEFT", 5, -15)
  borderWidthLabel:SetText("Border Width")

  local borderWidthValue = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  borderWidthValue:SetPoint("LEFT", borderWidthLabel, "RIGHT", 30, 0)
  borderWidthValue:SetText(tostring(settings.ninesliceSettings.borderWidth))

  local borderWidthSlider = Cell.CreateSlider("", parent, 1, 32, 180, 1)
  borderWidthSlider:SetPoint("TOPLEFT", borderWidthLabel, "BOTTOMLEFT", 0, -5)
  borderWidthSlider:SetValue(settings.ninesliceSettings.borderWidth)
  borderWidthSlider.afterValueChangedFn = function(value)
    local newValue = math.floor(value)
    self.settingsManager.settings.ninesliceSettings.borderWidth = newValue
    borderWidthValue:SetText(tostring(newValue))
    self:TriggerLayoutUpdate()
  end

  -- Border Height
  local borderHeightLabel = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  borderHeightLabel:SetPoint("TOPLEFT", borderWidthSlider, "BOTTOMLEFT", 0, -25)
  borderHeightLabel:SetText("Border Height")

  local borderHeightValue = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  borderHeightValue:SetPoint("LEFT", borderHeightLabel, "RIGHT", 30, 0)
  borderHeightValue:SetText(tostring(settings.ninesliceSettings.borderHeight))

  local borderHeightSlider = Cell.CreateSlider("", parent, 1, 32, 180, 1)
  borderHeightSlider:SetPoint("TOPLEFT", borderHeightLabel, "BOTTOMLEFT", 0, -5)
  borderHeightSlider:SetValue(settings.ninesliceSettings.borderHeight)
  borderHeightSlider.afterValueChangedFn = function(value)
    local newValue = math.floor(value)
    self.settingsManager.settings.ninesliceSettings.borderHeight = newValue
    borderHeightValue:SetText(tostring(newValue))
    self:TriggerLayoutUpdate()
  end

  -- Force Nineslice checkbox (for testing)
  local forceNinesliceCheckbox = Cell.CreateCheckButton(parent, "Force Nineslice (Debug)", function(checked)
    self.settingsManager.settings.ninesliceSettings.forceNineslice = checked
    self:TriggerLayoutUpdate()
  end)
  forceNinesliceCheckbox:SetPoint("TOPLEFT", borderHeightSlider, "BOTTOMLEFT", 0, -25)
  forceNinesliceCheckbox:SetChecked(settings.ninesliceSettings.forceNineslice)

  self.lastAnchor = forceNinesliceCheckbox
end

function UIManager:CreateAdvancedSettings(parent)
  local Cell = ns.Cell or _G.Cell
  local settings = self.settingsManager:GetAll()

  -- Section header
  local sectionHeader = parent:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  sectionHeader:SetPoint("TOPLEFT", self.lastAnchor, "BOTTOMLEFT", 0, -35)
  sectionHeader:SetText("Advanced Settings")

  -- Debug checkbox
  local debugCheckbox = Cell.CreateCheckButton(parent, "Show Debug Overlay", function(checked)
    self.settingsManager:Set("debug", checked)
    self:TriggerLayoutUpdate()
  end)
  debugCheckbox:SetPoint("TOPLEFT", sectionHeader, "BOTTOMLEFT", 5, -15)
  debugCheckbox:SetChecked(settings.debug)
end

function UIManager:UpdateWidgetStates()
  local useCustomSize = self.settingsManager:Get("useCustomSize")
  if self.widthSlider then
    self.widthSlider:SetEnabled(useCustomSize)
  end
  if self.heightSlider then
    self.heightSlider:SetEnabled(useCustomSize)
  end
end

function UIManager:UpdateTextureWidgetStates()
  local textureEnabled = self.settingsManager:Get("textureEnabled")
  if self.textureDropdown then
    self.textureDropdown:SetEnabled(textureEnabled)
  end
  if self.refreshButton then
    self.refreshButton:SetEnabled(textureEnabled)
  end
  if self.alphaSlider then
    self.alphaSlider:SetEnabled(textureEnabled)
  end
end

function UIManager:PopulateTextureDropdown(dropdown)
  local textureItems = {}
  for _, texture in ipairs(self.textureManager:GetAvailableTextures()) do
    table.insert(textureItems, {
      text = texture.name,
      value = texture.id,
      onClick = function()
        self.settingsManager:Set("selectedTexture", texture.id)
        Utils:Debug("[CellAdditions] Selected texture: " .. texture.id) -- Visible to user
        self:TriggerLayoutUpdate()
      end,
    })
  end
  dropdown:SetItems(textureItems)
end

function UIManager:RefreshTextureDropdown(dropdown)
  -- Force rescan of textures
  local newTextures = self.textureManager:RescanTextures()

  -- Repopulate dropdown
  self:PopulateTextureDropdown(dropdown)

  -- Update selected value if it still exists
  local currentSelection = self.settingsManager:Get("selectedTexture")
  local stillExists = false
  for _, texture in ipairs(newTextures) do
    if texture.id == currentSelection then
      stillExists = true
      break
    end
  end

  if not stillExists then
    -- Reset to "none" if current texture no longer exists
    self.settingsManager:Set("selectedTexture", "none")
    currentSelection = "none"
  end

  dropdown:SetSelectedValue(currentSelection)

  print("[CellAdditions] Texture list refreshed: " .. (#newTextures - 1) .. " textures found")
end

function UIManager:TriggerLayoutUpdate()
  C_Timer.After(0.1, function()
    if ns.Clicker and ns.Clicker.layoutManager then
      ns.Clicker.layoutManager:UpdateLayout()
    end
  end)
end

function Clicker:New()
  local instance = setmetatable({}, self)

  -- Initialize managers
  instance.settingsManager = SettingsManager:New()
  instance.textureManager = TextureManager:New()
  instance.frameManager = FrameManager:New(instance.settingsManager, instance.textureManager)
  instance.layoutManager = LayoutManager:New(instance.frameManager, instance.settingsManager)
  instance.uiManager = UIManager:New(instance.settingsManager, instance.textureManager)

  instance.initialized = false
  return instance
end

function Clicker:Initialize()
  if self.initialized then
    return
  end

  -- Initialize settings
  self.settingsManager:Initialize()

  -- Check if module is enabled
  if not self.settingsManager:Get("enabled") then
    Utils:Debug("Clicker module disabled in settings")
    return
  end

  -- Register Cell callbacks
  self:RegisterCallbacks()

  -- Register WoW events
  self:RegisterEvents()

  self.initialized = true
  Utils:Debug("Clicker module initialized successfully")

  -- Apply settings immediately after initialization
  if self.layoutManager then
    Utils:Debug("Applying saved texture settings on initialization")
    self.layoutManager:UpdateLayout()
  end
end

function Clicker:RegisterCallbacks()
  local Cell = ns.Cell or _G.Cell
  if not Cell or not Cell.RegisterCallback then
    Utils:Debug("Cell callbacks not available")
    return
  end

  local callbacks = {
    "Cell_Init",
    "Cell_UnitButtonCreated",
    "Cell_RaidFrame_Update",
    "Cell_PartyFrame_Update",
    "Cell_SoloFrame_Update",
    "Cell_Group_Moved",
    "Cell_Group_Updated",
    "Cell_Layout_Updated",
  }

  for _, callbackName in ipairs(callbacks) do
    Cell:RegisterCallback(callbackName, function()
      C_Timer.After(0.1, function() self.layoutManager:UpdateLayout() end)
    end)
  end

  Utils:Debug("Registered Cell callbacks")
end

function Clicker:RegisterEvents()
  local eventFrame = CreateFrame("Frame")
  local events = {
    "PLAYER_TARGET_CHANGED",
    "GROUP_ROSTER_UPDATE",
    "PLAYER_ENTERING_WORLD",
  }

  for _, event in ipairs(events) do
    eventFrame:RegisterEvent(event)
  end

  eventFrame:SetScript("OnEvent", function()
    C_Timer.After(0.1, function() self.layoutManager:UpdateLayout() end)
  end)

  Utils:Debug("Registered WoW events")
end

function Clicker:SetEnabled(enabled)
  if not CellAdditionsDB then
    Utils:Debug("Database not available")
    return
  end

  local wasEnabled = self.settingsManager:Get("enabled")
  self.settingsManager:Set("enabled", enabled)

  print("[CellAdditions] Clicker module " .. (enabled and "enabled" or "disabled"))

  if enabled and not wasEnabled then
    self:Initialize()
    C_Timer.After(0.1, function() self.layoutManager:UpdateLayout() end)
  elseif not enabled and wasEnabled then
    self.frameManager:CleanupAllFrames()
  end
end

function Clicker:CreateSettings(parent, enableCheckbox) self.uiManager:CreateSettings(parent, enableCheckbox) end

-- Create singleton instance
local clickerInstance = Clicker:New()

-- Export to namespace
ns.Clicker = clickerInstance
ns.addon = ns.addon or {}
ns.addon.Clicker = clickerInstance

-- Export the class for direct access if needed
ns.ClickerClass = Clicker

-- Register module
C_Timer.After(0, function()
  if ns.RegisterModule then
    ns.RegisterModule(clickerInstance)
    Utils:Debug("Clicker module registered with module system")
  else
    Utils:Debug("Module system not available for registration")
  end
end)

-- Ensure textures are applied when Cell is fully ready
local function EnsureTexturesApplied()
  if clickerInstance.initialized and clickerInstance.layoutManager then
    local settings = clickerInstance.settingsManager:GetAll()
    if settings.textureEnabled and settings.selectedTexture ~= "none" then
      Utils:Debug("Re-applying textures after Cell ready: " .. settings.selectedTexture)
      clickerInstance.layoutManager:UpdateLayout()
    end
  end
end

-- Single trigger to ensure textures show up
C_Timer.After(0.2, EnsureTexturesApplied)

-- CUF integration
if _G.CUF then
  _G.CUF:RegisterCallback("UpdateLayout", "CellAdditions_Clicker_UpdateLayout", function()
    if clickerInstance.layoutManager then
      clickerInstance.layoutManager:UpdateLayout()
    end
  end)
end
