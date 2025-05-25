local _, ns = ...

-- Create UI frames API
local UIFrames = {}
ns.UIFrames = UIFrames

-- Get references to Cell utilities
local Cell = ns.Cell
local L = Cell and Cell.L or {}
local F = Cell and Cell.funcs or {}
local P = Cell and Cell.pixelPerfectFuncs or {}

-- Get accent color from Cell
local function GetAccentColor() return Cell.GetAccentColorTable() end

-- Create a solo frame
function UIFrames:CreateSoloFrame(parent)
  if not parent then
    parent = UIParent
  end

  -- Create the frame
  local frame = Cell.CreateFrame("CellAdditionsSoloFrame", parent)
  frame:SetSize(200, 60)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  Cell.StylizeFrame(frame)

  -- Make it movable
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(frame)
    if not CellAdditionsDB.UISettings.locked then
      frame:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(frame)
    frame:StopMovingOrSizing()
    -- Save position
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    if not CellAdditionsDB.framePositions then
      CellAdditionsDB.framePositions = {}
    end
    CellAdditionsDB.framePositions.soloFrame = {
      point = point,
      relativePoint = relativePoint,
      xOfs = xOfs,
      yOfs = yOfs,
    }
  end)

  -- Add title
  local title = frame:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
  title:SetPoint("TOP", frame, "TOP", 0, -5)
  title:SetText("Solo Frame")
  title:SetTextColor(GetAccentColor()[1], GetAccentColor()[2], GetAccentColor()[3])

  -- Add health bar
  local healthBar = CreateFrame("StatusBar", nil, frame)
  healthBar:SetStatusBarTexture(Cell.vars.texture)
  healthBar:SetMinMaxValues(0, 100)
  healthBar:SetValue(100)
  healthBar:SetSize(180, 20)
  healthBar:SetPoint("TOP", title, "BOTTOM", 0, -5)
  healthBar:SetStatusBarColor(0, 1, 0)

  -- Add power bar
  local powerBar = CreateFrame("StatusBar", nil, frame)
  powerBar:SetStatusBarTexture(Cell.vars.texture)
  powerBar:SetMinMaxValues(0, 100)
  powerBar:SetValue(100)
  powerBar:SetSize(180, 10)
  powerBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -2)
  powerBar:SetStatusBarColor(0, 0, 1)

  -- Add class icon
  local classIcon = frame:CreateTexture(nil, "ARTWORK")
  classIcon:SetSize(24, 24)
  classIcon:SetPoint("LEFT", frame, "LEFT", 5, 0)

  -- Set icon based on player class
  local classFile = select(2, UnitClass("player"))
  if classFile then
    classIcon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
    classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
  end

  -- Store references
  frame.title = title
  frame.healthBar = healthBar
  frame.powerBar = powerBar
  frame.classIcon = classIcon

  -- Update function for live data
  frame.Update = function(self)
    -- Update health
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    if maxHealth > 0 then
      local percent = health / maxHealth * 100
      self.healthBar:SetValue(percent)

      -- Update health color based on percentage
      local r, g, b
      if percent > 60 then
        r, g, b = 0, 1, 0
      elseif percent > 30 then
        r, g, b = 1, 1, 0
      else
        r, g, b = 1, 0, 0
      end
      self.healthBar:SetStatusBarColor(r, g, b)
    end

    -- Update power
    local power = UnitPower("player")
    local maxPower = UnitPowerMax("player")
    if maxPower > 0 then
      self.powerBar:SetValue(power / maxPower * 100)
    end
  end

  -- Set up update timer
  frame.timer = C_Timer.NewTicker(0.2, function()
    if frame:IsShown() then
      frame:Update()
    end
  end)

  -- Initial update
  frame:Update()

  -- Restore position if saved
  if CellAdditionsDB.framePositions and CellAdditionsDB.framePositions.soloFrame then
    local pos = CellAdditionsDB.framePositions.soloFrame
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
  end

  -- Store in namespace
  if not ns.frames then
    ns.frames = {}
  end
  ns.frames.soloFrame = frame

  return frame
end

-- Create styled divider
function UIFrames:CreateDivider(parent, width, height)
  width = width or 300
  height = height or 2

  local divider = parent:CreateTexture(nil, "ARTWORK")
  divider:SetSize(width, height)

  -- Get accent color from Cell
  local accentColor = GetAccentColor()
  divider:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.8)

  -- Add shadow/glow
  local shadow = parent:CreateTexture(nil, "ARTWORK")
  shadow:SetPoint("TOPLEFT", divider, "TOPLEFT", 0, -1)
  shadow:SetPoint("BOTTOMRIGHT", divider, "BOTTOMRIGHT", 1, -2)
  shadow:SetColorTexture(0, 0, 0, 0.5)

  -- Store in namespace
  if not ns.frames then
    ns.frames = {}
  end
  ns.frames.divider = divider

  return divider
end

-- Create styled toggle switch in Cell style
function UIFrames:CreateToggle(parent, text, callback, tooltips)
  -- Create a container frame
  local toggle = CreateFrame("Frame", nil, parent)
  toggle:SetSize(150, 30)

  -- Create text label
  local label = toggle:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
  label:SetPoint("LEFT", toggle, "LEFT", 0, 0)
  label:SetText(text)

  -- Create the actual button using Cell's checkbox
  local button = Cell.CreateCheckButton(toggle, "", function(checked)
    if callback then
      callback(checked)
    end
  end)
  button:SetPoint("LEFT", label, "RIGHT", 5, 0)

  -- Add tooltips if provided
  if tooltips then
    Cell.SetTooltips(button, "ANCHOR_RIGHT", 0, 0, unpack(tooltips))
  end

  -- Save references
  toggle.button = button
  toggle.label = label

  -- Button methods
  function toggle:SetChecked(checked) self.button:SetChecked(checked) end

  function toggle:GetChecked() return self.button:GetChecked() end

  function toggle:SetEnabled(enabled) Cell.SetEnabled(enabled, self.button, self.label) end

  return toggle
end

-- Initialize function to create all UI frames
function UIFrames:Initialize()
  ns.Debug("Creating UI frames")

  -- Create solo frame if enabled
  if CellAdditionsDB and CellAdditionsDB.UISettings and CellAdditionsDB.UISettings.soloFrame then
    self:CreateSoloFrame()
    ns.Debug("Solo frame created")
  end
end

-- Return the API
return UIFrames
