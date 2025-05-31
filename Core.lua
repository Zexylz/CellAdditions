local addonName, ns = ...

local CellAdditions = {}
CellAdditions.__index = CellAdditions
ns.CellAdditions = CellAdditions

-- Initialize addon namespace for modules
ns.addon = CellAdditions

-- Get localization table
local L = ns.L or {}

-- Ensure critical strings exist with fallbacks
L["Version"] = L["Version"] or "Version"
L["Features"] = L["Features"] or "Features"
L["Settings"] = L["Settings"] or "Settings"
L["Enable"] = L["Enable"] or "Enable"

local ADDON_VERSION = "1.0"
local FRAME_STRATA = "HIGH"
local ACCENT_COLOR_ALPHA = 0.7

-- Default settings structure
local DEFAULT_SETTINGS = {
  enabled = true,
  shadowEnabled = true,
  clickerEnabled = true,
  debug = false,
  currentTab = "raidTools",
  shadowSize = 4,
  shadowColor = { r = 0, g = 0, b = 0, a = 1 },
  shadowBars = {
    healthBar = false,
    powerBar = false,
  },
  useStandaloneCellShadow = false,
  usePartyButtonShadow = false,
  useRaidButtonShadow = false,
  shadowQuality = 3,
  shadowOffsetX = 0,
  shadowOffsetY = 0,
  shadowConfig = {
    enableShadow = true,
    shadowSize = 5,
    partyFrames = true,
    raidFrames = false,
    unitFrames = {
      Player = true,
      Target = false,
      TargetTarget = false,
      Focus = false,
      Pet = false,
    },
  },
}

local Utils = {}

function Utils:Debug(msg)
  if CellAdditionsDB and CellAdditionsDB.debug then
    local frame = DEFAULT_CHAT_FRAME or ChatFrame1
    if frame then
      frame:AddMessage("|cff00ff00[CellAdditions]|r " .. tostring(msg))
    else
      print("|cff00ff00[CellAdditions]|r " .. tostring(msg))
    end
  end
end

function Utils:DeepCopy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy

  if orig_type == "table" then
    if copies[orig] then
      copy = copies[orig]
    else
      copy = {}
      copies[orig] = copy
      for orig_key, orig_value in next, orig, nil do
        copy[self:DeepCopy(orig_key, copies)] = self:DeepCopy(orig_value, copies)
      end
      setmetatable(copy, self:DeepCopy(getmetatable(orig), copies))
    end
  else
    copy = orig
  end

  return copy
end

function Utils:MergeTable(dest, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dest[k]) == "table" then
      self:MergeTable(dest[k], v)
    else
      dest[k] = v
    end
  end
end

ns.Utils = Utils

local ModuleSystem = {}
ModuleSystem.__index = ModuleSystem

function ModuleSystem:New()
  local instance = setmetatable({}, self)
  instance.modules = {}
  instance.features = {}
  return instance
end

function ModuleSystem:RegisterModule(module)
  if not module or not module.id or not module.name then
    Utils:Debug("Failed to register module: missing required properties")
    return false
  end

  self.modules[module.id] = module

  -- Add to features list for UI
  table.insert(self.features, {
    name = module.name,
    id = module.id,
    description = module.description,
  })

  Utils:Debug("Registered module: " .. module.name)
  return true
end

function ModuleSystem:GetModule(id) return self.modules[id] end

function ModuleSystem:InitializeModules()
  Utils:Debug("Initializing all modules...")

  for id, module in pairs(self.modules) do
    if type(module.Initialize) == "function" then
      local success, err = pcall(module.Initialize, module)
      if not success then
        Utils:Debug("Failed to initialize module " .. id .. ": " .. tostring(err))
      else
        Utils:Debug("Initialized module: " .. id)
      end
    end
  end

  -- Sort features alphabetically
  table.sort(self.features, function(a, b) return a.name < b.name end)
end

local DatabaseManager = {}
DatabaseManager.__index = DatabaseManager

function DatabaseManager:New() return setmetatable({}, self) end

function DatabaseManager:Initialize()
  if not CellAdditionsDB then
    CellAdditionsDB = Utils:DeepCopy(DEFAULT_SETTINGS)
    Utils:Debug("Created default database")
  else
    -- Ensure all fields exist
    Utils:MergeTable(CellAdditionsDB, DEFAULT_SETTINGS)
    Utils:Debug("Updated existing database with missing fields")
  end
end

function DatabaseManager:Get(key) return CellAdditionsDB[key] end

function DatabaseManager:Set(key, value) CellAdditionsDB[key] = value end

local UIManager = {}
UIManager.__index = UIManager

function UIManager:New()
  local instance = setmetatable({}, self)
  instance.frames = {}
  instance.buttons = {}
  instance.selectedFeature = 1
  return instance
end

function UIManager:CreateMainPanel()
  local Cell = _G.Cell
  if not Cell then
    return
  end

  -- Create main panel with initial size - will be resized dynamically
  local panel = Cell.CreateFrame("CellAdditionsPanel", _G.UIParent, 400, 500)
  panel:SetPoint("CENTER")
  panel:SetFrameStrata(FRAME_STRATA)
  panel:Hide()

  -- Create list pane
  local listPane = Cell.CreateTitledPane(panel, L["Features"], 120, 500)
  listPane:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, -5)

  -- Create list frame
  local listFrame = Cell.CreateFrame("CellAdditionsTab_ListFrame", listPane)
  -- Anchor directly to the title with proper spacing
  if listPane.title then
    listFrame:SetPoint("TOPLEFT", listPane.title, "BOTTOMLEFT", 0, -10)
  else
    listFrame:SetPoint("TOPLEFT", listPane, 0, -25)
  end
  listFrame:SetPoint("BOTTOMRIGHT", listPane, 0, 5)
  listFrame:Show()

  -- Create scroll frame
  Cell.CreateScrollFrame(listFrame)
  listFrame.scrollFrame:SetScrollStep(19)

  -- Create settings pane
  local settingsPane = Cell.CreateTitledPane(panel, L["Settings"], 265, 400)
  settingsPane:SetPoint("TOPLEFT", listPane, "TOPRIGHT", 5, 0)
  settingsPane:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 5)

  -- Create settings frame
  local settingsFrame = Cell.CreateFrame("CellAdditionsTab_SettingsFrame", settingsPane, 10, 10, true)
  -- Anchor directly to the title with proper spacing
  if settingsPane.title then
    settingsFrame:SetPoint("TOPLEFT", settingsPane.title, "BOTTOMLEFT", 0, -10)
  else
    settingsFrame:SetPoint("TOPLEFT", settingsPane, 0, -25)
  end
  settingsFrame:SetPoint("BOTTOMRIGHT", settingsPane)
  settingsFrame:Show()

  -- Create scroll frame for settings
  Cell.CreateScrollFrame(settingsFrame)
  settingsFrame.scrollFrame:SetScrollStep(19)

  -- Add version text
  local versionText = panel:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  versionText:SetText(L["Version"] .. ": " .. ADDON_VERSION)
  local accentColor = self:GetAccentColor()
  versionText:SetTextColor(accentColor[1], accentColor[2], accentColor[3], ACCENT_COLOR_ALPHA)
  versionText:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 10)

  -- Store references
  self.frames.panel = panel
  self.frames.listFrame = listFrame
  self.frames.settingsFrame = settingsFrame
  self.frames.listPane = listPane
  self.frames.settingsPane = settingsPane

  -- Store in Cell for compatibility
  Cell.frames.additionsPanel = panel

  return panel
end

function UIManager:GetAccentColor()
  local Cell = _G.Cell
  if Cell and Cell.GetAccentColorTable then
    return Cell.GetAccentColorTable()
  end
  return { 1, 1, 1 }
end

function UIManager:LoadFeatureList(features)
  local Cell = _G.Cell
  if not Cell then
    return
  end

  -- Clear existing buttons
  for _, button in ipairs(self.buttons) do
    button:Hide()
  end
  wipe(self.buttons)

  local scrollContent = self.frames.listFrame.scrollFrame.content

  -- Create buttons for each feature
  for i, feature in ipairs(features) do
    local button = Cell.CreateButton(scrollContent, feature.name, "transparent-accent", { 115, 25 })

    -- Configure button text
    local fontString = button:GetFontString()
    fontString:ClearAllPoints()
    fontString:SetPoint("LEFT", button, "LEFT", 10, 0)
    fontString:SetJustifyH("LEFT")

    -- Position button
    if i == 1 then
      button:SetPoint("TOPLEFT")
      button:SetPoint("TOPRIGHT")
    else
      button:SetPoint("TOPLEFT", self.buttons[i - 1], "BOTTOMLEFT")
      button:SetPoint("TOPRIGHT", self.buttons[i - 1], "BOTTOMRIGHT")
    end

    -- Store data
    button.feature = feature
    button.index = i

    -- Create custom selected overlay texture
    button.selectedOverlay = button:CreateTexture(nil, "BACKGROUND")
    button.selectedOverlay:SetAllPoints(button)
    local accentColor = self:GetAccentColor()
    -- Use Cell's standard alpha for selected states
    button.selectedOverlay:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.7)
    button.selectedOverlay:Hide()

    -- Click handler
    button:SetScript("OnClick", function() self:SelectFeature(i) end)

    self.buttons[i] = button
  end

  -- Update content height
  scrollContent:SetHeight(#features * 25)

  -- Select first feature
  if #features > 0 then
    self:SelectFeature(1)
  end
end

function UIManager:SelectFeature(index)
  self.selectedFeature = index

  -- Update button states with selected highlighting
  for i, button in ipairs(self.buttons) do
    if i == index then
      -- Selected state: show overlay and set pushed state
      button.selectedOverlay:Show()
      button:SetButtonState("PUSHED", true)
    else
      -- Unselected state: hide overlay and reset to normal
      button.selectedOverlay:Hide()
      button:SetButtonState("NORMAL")
    end
  end

  -- Show settings for selected feature
  self:ShowFeatureSettings(index)
end

function UIManager:ResizePanelForFeature(featureId)
  if not self.frames.panel then
    return
  end

  -- Define content sizes for different features
  local featureSizes = {
    Shadow = { width = 400, height = 380 }, -- Compact size for Shadow
    clicker = { width = 450, height = 520 }, -- Larger size for Clicker
  }

  -- Get size for current feature or use default
  local size = featureSizes[featureId] or { width = 400, height = 450 }

  -- Resize main panel
  self.frames.panel:SetSize(size.width, size.height)

  -- Update settings pane height to match
  local settingsPaneHeight = size.height - 40 -- Account for padding
  self.frames.settingsPane:SetHeight(settingsPaneHeight)

  Utils:Debug("Resized panel for " .. featureId .. ": " .. size.width .. "x" .. size.height)
end

function UIManager:ShowFeatureSettings(index)
  local moduleSystem = ns.moduleSystem
  local features = moduleSystem.features

  if not features[index] then
    return
  end

  local feature = features[index]
  local module = moduleSystem:GetModule(feature.id)

  if not module then
    return
  end

  -- Resize panel based on the selected feature
  self:ResizePanelForFeature(module.id)

  -- Clear existing content
  local content = self.frames.settingsFrame.scrollFrame.content
  content:SetHeight(1)

  for _, child in pairs({ content:GetChildren() }) do
    child:Hide()
  end

  for _, region in pairs({ content:GetRegions() }) do
    region:Hide()
  end

  -- Handle Shadow module specially
  if module.id == "Shadow" and module.CreateSettings then
    module:CreateSettings(content)
    return
  end

  -- Handle Clicker module specially to use Cell's checkbox
  if module.id == "clicker" and module.CreateSettings then
    -- Create Cell-style enable checkbox for Clicker
    local Cell = _G.Cell
    if Cell then
      local enableCb = Cell.CreateCheckButton(content, L["Enable"] .. " " .. module.name, function(checked)
        if module.SetEnabled then
          module:SetEnabled(checked)
        else
          -- Use the correct Clicker settings location
          if not CellAdditionsDB.clickerSettings then
            CellAdditionsDB.clickerSettings = {}
          end
          CellAdditionsDB.clickerSettings.enabled = checked
        end
      end)
      enableCb:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -10)

      -- Set initial checked state from correct location
      local isEnabled = true -- default
      if CellAdditionsDB.clickerSettings then
        isEnabled = CellAdditionsDB.clickerSettings.enabled
        if isEnabled == nil then
          isEnabled = true
        end
      end
      enableCb:SetChecked(isEnabled)

      -- Let module add additional settings
      module:CreateSettings(content, enableCb)
      return
    end
  end

  local enableCb = _G.CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
  enableCb:SetSize(24, 24)
  enableCb:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -10)

  enableCb.text = enableCb:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  enableCb.text:SetText(L["Enable"] .. " " .. module.name)
  enableCb.text:SetPoint("LEFT", enableCb, "RIGHT", 2, 0)

  local enabledProperty = module.id .. "Enabled"
  local isEnabled = CellAdditionsDB[enabledProperty]
  if isEnabled == nil then
    isEnabled = true
  end
  enableCb:SetChecked(isEnabled)

  enableCb:SetScript("OnClick", function(cb)
    if module.SetEnabled then
      module:SetEnabled(cb:GetChecked())
    else
      CellAdditionsDB[enabledProperty] = cb:GetChecked()
    end
  end)

  if module.CreateSettings then
    module:CreateSettings(content, enableCb)
  end
end

local CellIntegration = {}
CellIntegration.__index = CellIntegration

function CellIntegration:New()
  return setmetatable({
    customMenu = nil,
    originalUtilitiesBtn = nil,
    replacementBtn = nil,
    hookedTabCallbacks = {},
    tabCallbacksRegistered = false,
  }, self)
end

function CellIntegration:CreateUtilitiesMenu(parent)
  local Cell = _G.Cell
  if not Cell then
    return
  end

  local menu = _G.CreateFrame("Frame", nil, parent, "BackdropTemplate")
  Cell.StylizeFrame(menu, { 0.1, 0.1, 0.1, 0.9 }, { 0, 0, 0, 1 })
  menu:SetPoint("TOPLEFT", parent, "TOPRIGHT", 1, 0)
  menu:Hide()

  -- Menu items
  local menuItems = {
    { text = L["Raid Tools"], id = "raidTools" },
    { text = L["Spell Request"], id = "spellRequest" },
    { text = L["Dispel Request"], id = "dispelRequest" },
    { text = L["Quick Assist"], id = "quickAssist" },
    { text = L["Quick Cast"], id = "quickCast" },
    { text = L["Additions"], id = "additions" },
  }

  -- Calculate width based on longest text (matching Cell's method)
  local dummyText = menu:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  local maxWidth = 0
  for _, item in ipairs(menuItems) do
    dummyText:SetText(item.text)
    local textWidth = dummyText:GetStringWidth()
    if textWidth > maxWidth then
      maxWidth = textWidth
    end
  end
  local width = math.ceil(maxWidth + 13) -- Use Cell's exact padding of +13

  -- Create buttons
  local buttons = {}
  local itemCount = Cell.isRetail and 6 or 3

  -- Store buttons on menu for updating
  menu.buttons = {}

  for i = 1, itemCount do
    local item = menuItems[i]
    local btn = Cell.CreateButton(menu, item.text, "transparent-accent", { 20, 20 }, true)
    btn.id = item.id

    if i == 1 then
      btn:SetPoint("TOPLEFT")
      btn:SetPoint("TOPRIGHT")
    else
      btn:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT")
      btn:SetPoint("TOPRIGHT", buttons[i - 1], "BOTTOMRIGHT")
    end

    -- Create custom selected overlay texture (same as feature buttons)
    btn.selectedOverlay = btn:CreateTexture(nil, "BACKGROUND")
    btn.selectedOverlay:SetAllPoints(btn)
    local accentColor = Cell.GetAccentColorTable and Cell.GetAccentColorTable() or { 1, 1, 1 }
    btn.selectedOverlay:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.7) -- Cell's standard
    btn.selectedOverlay:Hide()

    btn:SetScript("OnClick", function()
      self:HandleMenuClick(item.id)
      menu:Hide()
    end)

    buttons[i] = btn
    menu.buttons[item.id] = btn
  end

  -- Size the menu
  menu:SetSize(width, 20 * itemCount)

  -- Function to update selected state
  menu.UpdateSelection = function()
    local currentTab = CellAdditionsDB.currentTab or "raidTools"
    for id, button in pairs(menu.buttons) do
      if id == currentTab then
        -- Selected state: show overlay and set pushed state (same as feature buttons)
        button.selectedOverlay:Show()
        button:SetButtonState("PUSHED", true)
      else
        -- Normal state: hide overlay and reset to normal (same as feature buttons)
        button.selectedOverlay:Hide()
        button:SetButtonState("NORMAL")
      end
    end
  end

  return menu
end

function CellIntegration:HandleMenuClick(itemId)
  local Cell = _G.Cell
  if not Cell then
    return
  end

  CellAdditionsDB.currentTab = itemId

  -- Update menu selection state if menu exists
  if self.customMenu and self.customMenu.UpdateSelection then
    self.customMenu.UpdateSelection()
  end

  if itemId == "additions" then
    if Cell.funcs.ShowOptionsFrame then
      Cell.funcs.ShowOptionsFrame()
    end

    C_Timer.After(0.1, function()
      if Cell.funcs.ShowUtilitiesTab then
        Cell.funcs.ShowUtilitiesTab()
        Cell.Fire("CellAdditions_ShowAdditionsPanel")
      end
    end)
  else
    -- Handle other utilities
    self:ShowUtility(itemId)
  end
end

function CellIntegration:ShowUtility(utilityId)
  local Cell = _G.Cell
  if not Cell or not Cell.frames then
    return
  end

  -- Click the utilities button
  for _, child in pairs({ Cell.frames.optionsFrame:GetChildren() }) do
    if child:IsObjectType("Button") and child.id == "utilities" then
      if child:GetScript("OnClick") then
        child:GetScript("OnClick")(child)
      end
      break
    end
  end

  -- Show the specific utility
  C_Timer.After(0.1, function()
    local listFrame = self:GetUtilityListFrame()
    if listFrame and listFrame.buttons and listFrame.buttons[utilityId] then
      listFrame.buttons[utilityId]:Click()
    end
  end)
end

function CellIntegration:GetUtilityListFrame()
  local Cell = _G.Cell
  if not Cell or not Cell.frames or not Cell.frames.utilitiesTab then
    return nil
  end

  for _, child in pairs({ Cell.frames.utilitiesTab:GetChildren() }) do
    if child:IsObjectType("Frame") and child.buttons then
      return child
    end
  end

  return nil
end

function CellIntegration:ReplaceUtilitiesButton()
  local Cell = _G.Cell
  if not Cell or not Cell.frames or not Cell.frames.optionsFrame then
    C_Timer.After(1, function() self:ReplaceUtilitiesButton() end)
    return
  end

  -- Find original button
  local origBtn
  for _, child in pairs({ Cell.frames.optionsFrame:GetChildren() }) do
    if child:IsObjectType("Button") and child.id == "utilities" then
      origBtn = child
      break
    end
  end

  if not origBtn then
    C_Timer.After(1, function() self:ReplaceUtilitiesButton() end)
    return
  end

  -- Create replacement
  local CellL = Cell.L or {}
  local newBtn = Cell.CreateButton(
    Cell.frames.optionsFrame,
    CellL["Utilities"],
    "accent-hover",
    { 105, 20 },
    nil,
    nil,
    "CELL_FONT_WIDGET_TITLE",
    "CELL_FONT_WIDGET_TITLE_DISABLE"
  )

  newBtn.id = "utilities"
  newBtn:SetSize(origBtn:GetSize())

  -- Copy position
  local point, relativeTo, relativePoint, xOfs, yOfs = origBtn:GetPoint()
  newBtn:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)

  -- Make draggable
  newBtn:RegisterForDrag("LeftButton")
  newBtn:SetScript("OnDragStart", function()
    Cell.frames.optionsFrame:StartMoving()
    Cell.frames.optionsFrame:SetUserPlaced(false)
  end)
  newBtn:SetScript("OnDragStop", function()
    Cell.frames.optionsFrame:StopMovingOrSizing()
    Cell.pixelPerfectFuncs.PixelPerfectPoint(Cell.frames.optionsFrame)
    Cell.pixelPerfectFuncs.SavePosition(Cell.frames.optionsFrame, Cell.vars.db["optionsFramePosition"])
  end)

  -- Create custom menu
  self.customMenu = self:CreateUtilitiesMenu(newBtn)

  -- Setup hover behavior
  local function checkMouseOver() return self.customMenu:IsMouseOver() or newBtn:IsMouseOver() end

  local hideTimer

  newBtn:HookScript("OnEnter", function()
    self.customMenu:SetFrameStrata("TOOLTIP")
    self.customMenu:Show()
    -- Update selected state when showing menu
    self.customMenu.UpdateSelection()
  end)

  local function onLeave()
    if hideTimer then
      hideTimer:Cancel()
    end
    hideTimer = C_Timer.NewTimer(0.2, function()
      if not checkMouseOver() then
        self.customMenu:Hide()
      end
    end)
  end

  newBtn:HookScript("OnLeave", onLeave)
  self.customMenu:HookScript("OnLeave", onLeave)

  -- Click handler
  newBtn:SetScript("OnClick", function()
    if Cell.funcs.ShowOptionsFrame then
      Cell.funcs.ShowOptionsFrame()
    end
    if Cell.funcs.ShowUtilitiesTab then
      Cell.funcs.ShowUtilitiesTab()
    end

    C_Timer.After(0.3, function()
      local utilityToShow = CellAdditionsDB.currentTab or "raidTools"
      if utilityToShow == "additions" then
        Cell.Fire("CellAdditions_ShowAdditionsPanel")
      else
        -- If we were showing additions, reset the state
        if ns.wasShowingAdditions then
          ns.wasShowingAdditions = false
          if Cell.frames.additionsPanel then
            Cell.frames.additionsPanel:Hide()
          end
        end

        Cell.Fire("ShowUtilitySettings", utilityToShow)

        local listFrame = self:GetUtilityListFrame()
        if listFrame and listFrame.buttons and listFrame.buttons[utilityToShow] then
          listFrame.buttons[utilityToShow]:Click()
        end
      end
    end)
  end)

  -- Hide original button
  origBtn:SetParent(nil)
  origBtn:Hide()

  self.originalUtilitiesBtn = origBtn
  self.replacementBtn = newBtn

  Utils:Debug("Successfully replaced utilities button")
end

function CellIntegration:RegisterCallbacks()
  local Cell = _G.Cell
  if not Cell or not Cell.RegisterCallback then
    Utils:Debug("Cell.RegisterCallback not available")
    return
  end

  -- Custom event for showing additions panel
  Cell.RegisterCallback(
    "CellAdditions_ShowAdditionsPanel",
    "CellAdditions_ShowAdditionsPanel",
    function() self:ShowAdditionsPanel() end
  )

  -- Hook Cell's tab management system properly
  self:HookCellTabSystem()
end

function CellIntegration:HookCellTabSystem()
  local Cell = _G.Cell
  if not Cell then
    return
  end

  -- Hook into Cell's ShowOptionsTab callback system
  if not self.tabCallbacksRegistered then
    -- Register our own callback to track when Cell switches tabs
    Cell.RegisterCallback("ShowOptionsTab", "CellAdditions_TabTracker", function(tab)
      Utils:Debug("Cell switching to tab: " .. tostring(tab))

      -- If we're showing additions and Cell is switching to another tab, hide additions
      if ns.wasShowingAdditions and tab ~= "additions" then
        Utils:Debug("Hiding additions panel due to Cell tab switch to: " .. tab)
        self:HideAdditionsPanel()

        -- Let Cell handle the height for the new tab - don't interfere
        -- Cell will automatically set the correct height based on the tab
      end
    end)

    self.tabCallbacksRegistered = true
    Utils:Debug("Hooked into Cell's tab system properly")
  end
end

function CellIntegration:ShowAdditionsPanel()
  local Cell = _G.Cell
  if not Cell or not Cell.frames then
    return
  end

  local panel = Cell.frames.additionsPanel
  if not panel then
    return
  end

  local optionsFrame = Cell.frames.optionsFrame

  -- Hide all Cell tab content the proper way
  self:HideAllCellTabContent()

  -- Set the frame height for additions (Cell will manage this properly)
  optionsFrame:SetHeight(550)

  -- Parent panel to content area and show
  panel:SetParent(optionsFrame)
  panel:ClearAllPoints()
  panel:SetAllPoints(optionsFrame)
  panel:Show()

  -- Mark that we're showing additions
  ns.wasShowingAdditions = true

  Utils:Debug("Showing Additions panel with proper Cell integration")
end

function CellIntegration:HideAdditionsPanel()
  local Cell = _G.Cell
  if not Cell or not Cell.frames then
    return
  end

  local panel = Cell.frames.additionsPanel
  if panel then
    panel:Hide()
  end

  -- Clear additions state
  ns.wasShowingAdditions = false

  -- Restore utilities tab content if we were in utilities
  if Cell.frames.utilitiesTab then
    Cell.frames.utilitiesTab:Show()
    Utils:Debug("Restored utilities tab visibility")

    -- Also ensure utility content is visible
    for _, child in pairs({ Cell.frames.utilitiesTab:GetChildren() }) do
      if child:IsObjectType("Frame") and child ~= Cell.frames.utilitiesTab.mask then
        child:Show()
        Utils:Debug("Restored utility content visibility")
      end
    end
  end

  -- DON'T manually set height - let Cell handle it
  -- Cell will automatically set the correct height when showing the target tab

  Utils:Debug("Hidden additions panel and restored utilities content")
end

function CellIntegration:HideAllCellTabContent()
  local Cell = _G.Cell
  if not Cell or not Cell.frames then
    return
  end

  -- Get list of Cell tab frames (excluding utilities since we want to stay in utilities)
  local tabFrames = {
    "generalTab",
    "appearanceTab",
    "layoutsTab",
    "clickCastingsTab",
    "indicatorsTab",
    "debuffsTab",
    "aboutTab",
  }

  -- Hide all other tab frames
  for _, tabName in ipairs(tabFrames) do
    if Cell.frames[tabName] then
      Cell.frames[tabName]:Hide()
      Utils:Debug("Hidden tab frame: " .. tabName)
    end
  end

  -- For utilities tab, we want to keep the tab frame visible but hide its content
  -- This way we can properly restore it later
  if Cell.frames.utilitiesTab then
    -- Keep the utilities tab frame visible but hide its content temporarily
    for _, child in pairs({ Cell.frames.utilitiesTab:GetChildren() }) do
      if child:IsObjectType("Frame") and child ~= Cell.frames.utilitiesTab.mask then
        child:Hide()
        Utils:Debug("Hidden utility content frame")
      end
    end
  end

  Utils:Debug("Hidden Cell tab content while preserving utilities tab structure")
end

function CellIntegration:GetCurrentCellTab()
  local Cell = _G.Cell
  if not Cell then
    return "general"
  end

  -- Check Cell's lastShownTab variable first
  if Cell.vars and Cell.vars.lastShownTab then
    return Cell.vars.lastShownTab
  end

  -- Fallback: check which tab frame is visible
  local tabFrames = {
    { name = "generalTab", id = "general" },
    { name = "appearanceTab", id = "appearance" },
    { name = "layoutsTab", id = "layouts" },
    { name = "clickCastingsTab", id = "clickCastings" },
    { name = "indicatorsTab", id = "indicators" },
    { name = "debuffsTab", id = "debuffs" },
    { name = "utilitiesTab", id = "utilities" },
    { name = "aboutTab", id = "about" },
  }

  for _, tab in ipairs(tabFrames) do
    if Cell.frames[tab.name] and Cell.frames[tab.name]:IsShown() then
      return tab.id
    end
  end

  return "general" -- Default fallback
end

-- ============================================================================
-- Main Addon Implementation
-- ============================================================================

function CellAdditions:Initialize()
  -- Check for Cell
  local Cell = _G.Cell
  if not Cell then
    print("|cffff0000CellAdditions:|r Cell addon not found!")
    return
  end

  -- Store Cell references
  self.Cell = Cell
  self.L = Cell.L or {}
  self.F = Cell.funcs or {}
  self.P = Cell.pixelPerfectFuncs or {}

  -- Make Cell accessible to modules
  ns.Cell = Cell

  -- Initialize components
  self.db = DatabaseManager:New()
  self.db:Initialize()

  self.moduleSystem = ModuleSystem:New()
  ns.moduleSystem = self.moduleSystem

  -- Register any pending modules
  if ns.pendingModules then
    Utils:Debug("Processing " .. #ns.pendingModules .. " pending modules...")
    for _, module in ipairs(ns.pendingModules) do
      self.moduleSystem:RegisterModule(module)
      Utils:Debug("Registered pending module: " .. (module.name or "Unknown"))
    end
    ns.pendingModules = nil
  end

  self.ui = UIManager:New()
  ns.ui = self.ui

  self.cellIntegration = CellIntegration:New()

  -- Initialize modules
  Utils:Debug("About to initialize modules...")
  self.moduleSystem:InitializeModules()

  -- Debug: Check what modules are registered
  local moduleCount = 0
  for id, module in pairs(self.moduleSystem.modules) do
    moduleCount = moduleCount + 1
    Utils:Debug("Found module: " .. id .. " - " .. module.name)
  end
  Utils:Debug("Total modules registered: " .. moduleCount)

  -- Create UI
  Utils:Debug("Creating UI panels...")
  self.ui:CreateMainPanel()
  self.ui:LoadFeatureList(self.moduleSystem.features)
  Utils:Debug("Features loaded: " .. #self.moduleSystem.features)

  -- Integrate with Cell
  self.cellIntegration:ReplaceUtilitiesButton()
  self.cellIntegration:RegisterCallbacks()

  -- Hook the options frame to capture original dimensions when it's first shown
  if Cell.frames.optionsFrame then
    hooksecurefunc(Cell.frames.optionsFrame, "Show", function()
      if not ns.originalOptionsFrameHeight then
        ns.originalOptionsFrameHeight = Cell.frames.optionsFrame:GetHeight()
        ns.originalOptionsFrameWidth = Cell.frames.optionsFrame:GetWidth()
        Utils:Debug(
          "Captured original frame dimensions on Show: "
            .. ns.originalOptionsFrameWidth
            .. "x"
            .. ns.originalOptionsFrameHeight
        )
      end
    end)

    -- Also hook SetHeight to ensure we don't interfere with Cell's height changes
    local originalSetHeight = Cell.frames.optionsFrame.SetHeight
    Cell.frames.optionsFrame.SetHeight = function(frame, height)
      -- If this is Cell setting the height and we're not showing additions, update our stored height
      if not Cell.frames.additionsPanel or not Cell.frames.additionsPanel:IsShown() then
        if height ~= 550 then -- 550 is our extended height
          ns.originalOptionsFrameHeight = height
          Utils:Debug("Updated stored height to: " .. height)
        end
      end
      return originalSetHeight(frame, height)
    end
  end

  Utils:Debug("CellAdditions initialized successfully")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, addon)
  if event == "ADDON_LOADED" and addon == addonName then
    -- Initialize after a short delay to ensure Cell is ready
    C_Timer.After(0.1, function() CellAdditions:Initialize() end)

    eventFrame:UnregisterEvent("ADDON_LOADED")
  end
end)

-- Export functions for compatibility
ns.Debug = function(...) Utils:Debug(...) end
ns.Debug = function(...) Utils:Debug(...) end
ns.pendingModules = ns.pendingModules or {}
ns.RegisterModule = function(module)
  if ns.moduleSystem then
    ns.moduleSystem:RegisterModule(module)
    Utils:Debug("Registered module: " .. (module.name or "Unknown"))
  else
    -- Store for later registration
    table.insert(ns.pendingModules, module)
    Utils:Debug("Queued module for registration: " .. (module.name or "Unknown"))
  end
end
ns.GetModuleSettingsFrame = function(moduleId)
  if ns.ui and ns.ui.frames.settingsFrame then
    return ns.ui.frames.settingsFrame.scrollFrame.content
  end
  return nil
end

-- Global function for texture registration
_G.CellAdditions_RegisterTextures = function(textureList)
  _G.CellAdditions_PendingTextures = textureList
  Utils:Debug("Registered " .. #textureList .. " user textures")
end
