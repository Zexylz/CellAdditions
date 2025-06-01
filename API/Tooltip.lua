local _, ns = ...

local Tooltip = {}
Tooltip.__index = Tooltip
ns.Tooltip = Tooltip

-- Module metadata
Tooltip.name = "Tooltip"
Tooltip.id = "Tooltip"
Tooltip.description = "Universal tooltip system for any UI element"
Tooltip.version = "1.0"

-- Constants
local TOOLTIP_STRATA = "TOOLTIP"
local TOOLTIP_LEVEL = 100
local PADDING = 8
local BORDER_SIZE = 1
local FADE_DURATION = 1
local SHOW_DELAY = 0
local MAX_WIDTH = 300

local Utils = {}

function Utils:Debug(msg)
  if ns.Debug then
    ns.Debug("[Tooltip] " .. tostring(msg))
  end
end

function Utils:GetAccentColor()
  local Cell = _G.Cell
  if Cell and Cell.GetAccentColorTable then
    return Cell.GetAccentColorTable()
  end
  return { 1, 1, 1 }
end

function Utils:ApplyCellStyling(frame)
  local Cell = _G.Cell
  local accentColor = self:GetAccentColor()

  if Cell and Cell.StylizeFrame then
    -- Use Cell's styling system with accent color for border
    Cell.StylizeFrame(frame, { 0.1, 0.1, 0.1, 0.95 }, { accentColor[1], accentColor[2], accentColor[3], 1 })
  else
    -- Fallback styling with accent color border
    frame:SetBackdrop({
      bgFile = "Interface/Buttons/WHITE8X8",
      edgeFile = "Interface/Buttons/WHITE8X8",
      tile = false,
      tileSize = 0,
      edgeSize = BORDER_SIZE,
      insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    frame:SetBackdropBorderColor(accentColor[1], accentColor[2], accentColor[3], 1)
  end
end

local TooltipInstance = {}
TooltipInstance.__index = TooltipInstance

function TooltipInstance:New(config)
  local instance = setmetatable({}, self)

  -- Configuration
  instance.title = config.title
  instance.text = config.text
  instance.lines = config.lines or {}
  instance.maxWidth = config.maxWidth or MAX_WIDTH
  instance.showDelay = config.showDelay or SHOW_DELAY
  instance.anchor = config.anchor or "BOTTOM"
  instance.offset = config.offset or { x = 0, y = -5 }

  -- State
  instance.frame = nil
  instance.isVisible = false
  instance.showTimer = nil

  return instance
end

function TooltipInstance:CreateFrame()
  if self.frame then
    return self.frame
  end

  -- Create main tooltip frame
  local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  frame:SetFrameStrata(TOOLTIP_STRATA)
  frame:SetFrameLevel(TOOLTIP_LEVEL)
  frame:Hide()

  -- Make tooltip non-interactive so it doesn't steal mouse events
  frame:EnableMouse(false)
  frame:SetMouseClickEnabled(false)

  -- Apply Cell styling
  Utils:ApplyCellStyling(frame)

  -- Create content container
  local content = CreateFrame("Frame", nil, frame)
  content:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
  content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING)

  frame.content = content
  self.frame = frame

  Utils:Debug("Created tooltip frame")
  return frame
end

function TooltipInstance:UpdateContent()
  if not self.frame then
    return
  end

  local content = self.frame.content

  -- Clear existing content
  for _, child in pairs({ content:GetChildren() }) do
    child:Hide()
    child:SetParent(nil)
  end

  local yOffset = 0
  local maxTextWidth = 0

  -- Create title if provided
  if self.title then
    local titleText = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
    titleText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    titleText:SetText(self.title)
    titleText:SetJustifyH("LEFT")
    titleText:SetWordWrap(true)
    titleText:SetWidth(self.maxWidth - (PADDING * 2))

    local accentColor = Utils:GetAccentColor()
    titleText:SetTextColor(accentColor[1], accentColor[2], accentColor[3], 1)

    local titleWidth = titleText:GetStringWidth()
    maxTextWidth = math.max(maxTextWidth, titleWidth)
    yOffset = yOffset - titleText:GetStringHeight() - 4
  end

  -- Create main text if provided
  if self.text then
    local mainText = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    mainText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    mainText:SetText(self.text)
    mainText:SetJustifyH("LEFT")
    mainText:SetWordWrap(true)
    mainText:SetWidth(self.maxWidth - (PADDING * 2))
    mainText:SetTextColor(1, 1, 1, 1)

    local textWidth = mainText:GetStringWidth()
    maxTextWidth = math.max(maxTextWidth, textWidth)
    yOffset = yOffset - mainText:GetStringHeight() - 2
  end

  -- Create additional lines if provided
  for i, line in ipairs(self.lines) do
    local lineText = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    lineText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    lineText:SetText(line)
    lineText:SetJustifyH("LEFT")
    lineText:SetWordWrap(true)
    lineText:SetWidth(self.maxWidth - (PADDING * 2))
    lineText:SetTextColor(0.9, 0.9, 0.9, 1)

    local lineWidth = lineText:GetStringWidth()
    maxTextWidth = math.max(maxTextWidth, lineWidth)
    yOffset = yOffset - lineText:GetStringHeight() - 2
  end

  -- Set frame size based on content
  local frameWidth = math.min(maxTextWidth + (PADDING * 2), self.maxWidth)
  local frameHeight = math.abs(yOffset) + (PADDING * 2)

  self.frame:SetSize(frameWidth, frameHeight)

  Utils:Debug("Updated tooltip content: " .. frameWidth .. "x" .. frameHeight)
end

function TooltipInstance:PositionRelativeTo(targetFrame)
  if not self.frame then
    return
  end

  -- Get mouse cursor position
  local cursorX, cursorY = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  cursorX = cursorX / scale
  cursorY = cursorY / scale

  -- Position tooltip relative to cursor
  local offsetX = self.offset.x or 15 -- Default offset from cursor
  local offsetY = self.offset.y or -15

  self.frame:ClearAllPoints()
  self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cursorX + offsetX, cursorY + offsetY)

  -- Check if tooltip goes off-screen and adjust if needed
  self:CheckScreenBounds()
end

function TooltipInstance:CheckScreenBounds()
  if not self.frame then
    return
  end

  local screenWidth = UIParent:GetWidth()
  local screenHeight = UIParent:GetHeight()

  local left = self.frame:GetLeft()
  local right = self.frame:GetRight()
  local top = self.frame:GetTop()
  local bottom = self.frame:GetBottom()

  if left and right and top and bottom then
    local adjustX, adjustY = 0, 0

    -- Check horizontal bounds
    if left < 0 then
      adjustX = -left + 5
    elseif right > screenWidth then
      adjustX = screenWidth - right - 5
    end

    -- Check vertical bounds
    if bottom < 0 then
      adjustY = -bottom + 5
    elseif top > screenHeight then
      adjustY = screenHeight - top - 5
    end

    -- Apply adjustments if needed
    if adjustX ~= 0 or adjustY ~= 0 then
      local point, relativeTo, relativePoint, x, y = self.frame:GetPoint(1)
      self.frame:SetPoint(point, relativeTo, relativePoint, x + adjustX, y + adjustY)
    end
  end
end

function TooltipInstance:Show(targetFrame)
  if self.isVisible then
    return
  end

  self:CreateFrame()
  self:UpdateContent()
  self:PositionRelativeTo(targetFrame)

  -- Cancel any existing timer
  if self.showTimer then
    self.showTimer:Cancel()
    self.showTimer = nil
  end

  -- Show immediately if no delay, otherwise use timer
  if self.showDelay <= 0 then
    if self.frame then
      self.frame:SetAlpha(1) -- Show at full opacity immediately
      self.frame:Show()
      self.isVisible = true

      -- Enable mouse tracking to follow cursor
      self:StartMouseTracking()

      Utils:Debug("Tooltip shown immediately")
    end
  else
    -- Show with delay
    self.showTimer = C_Timer.NewTimer(self.showDelay, function()
      if self.frame then
        self.frame:SetAlpha(1) -- Show at full opacity immediately
        self.frame:Show()
        self.isVisible = true

        -- Enable mouse tracking to follow cursor
        self:StartMouseTracking()

        Utils:Debug("Tooltip shown after delay")
      end
    end)
  end
end

function TooltipInstance:StartMouseTracking()
  if not self.frame then
    return
  end

  -- Create a tracker frame that follows the mouse
  if not self.mouseTracker then
    self.mouseTracker = CreateFrame("Frame")
    self.mouseTracker:SetScript("OnUpdate", function()
      if self.isVisible and self.frame then
        self:PositionRelativeTo()
      end
    end)
  end

  self.mouseTracker:Show()
end

function TooltipInstance:StopMouseTracking()
  if self.mouseTracker then
    self.mouseTracker:Hide()
  end
end

function TooltipInstance:Hide()
  if not self.isVisible then
    Utils:Debug("Hide called but tooltip not visible")
    return
  end

  -- Cancel show timer if active
  if self.showTimer then
    self.showTimer:Cancel()
    self.showTimer = nil
  end

  -- Stop mouse tracking
  self:StopMouseTracking()

  self.isVisible = false

  if self.frame then
    self.frame:Hide()
  end

  Utils:Debug("Tooltip hidden instantly")
end

function TooltipInstance:Destroy()
  self:Hide()

  if self.frame then
    self.frame:Hide()
    self.frame:SetParent(nil)
    self.frame = nil
  end

  if self.showTimer then
    self.showTimer:Cancel()
    self.showTimer = nil
  end

  if self.mouseTracker then
    self.mouseTracker:Hide()
    self.mouseTracker:SetParent(nil)
    self.mouseTracker = nil
  end

  Utils:Debug("Tooltip destroyed")
end

local TooltipManager = {}
TooltipManager.__index = TooltipManager

function TooltipManager:New()
  local instance = setmetatable({}, self)
  instance.attachments = setmetatable({}, { __mode = "k" }) -- weak table
  instance.activeTooltip = nil
  return instance
end

function TooltipManager:Attach(frame, config)
  if not frame then
    Utils:Debug("Cannot attach tooltip: frame is nil")
    return false
  end

  -- Normalize config
  if type(config) == "string" then
    config = { text = config }
  elseif not config then
    Utils:Debug("Cannot attach tooltip: config is nil")
    return false
  end

  -- Create tooltip instance
  local tooltip = TooltipInstance:New(config)

  -- Store attachment
  self.attachments[frame] = tooltip

  -- Set up event handlers
  frame:HookScript("OnEnter", function() self:ShowTooltip(frame) end)

  frame:HookScript("OnLeave", function() self:HideTooltip(frame) end)

  Utils:Debug("Attached tooltip to frame")
  return true
end

function TooltipManager:Detach(frame)
  if not frame or not self.attachments[frame] then
    return false
  end

  local tooltip = self.attachments[frame]
  tooltip:Destroy()
  self.attachments[frame] = nil

  Utils:Debug("Detached tooltip from frame")
  return true
end

function TooltipManager:ShowTooltip(frame)
  local tooltip = self.attachments[frame]
  if not tooltip then
    Utils:Debug("No tooltip found for frame")
    return
  end

  -- Hide any active tooltip
  if self.activeTooltip and self.activeTooltip ~= tooltip then
    self.activeTooltip:Hide()
  end

  self.activeTooltip = tooltip
  tooltip:Show(frame)
  Utils:Debug("Showing tooltip for frame")
end

function TooltipManager:HideTooltip(frame)
  local tooltip = self.attachments[frame]
  if not tooltip then
    Utils:Debug("No tooltip found for frame to hide")
    return
  end

  if self.activeTooltip == tooltip then
    self.activeTooltip = nil
  end

  tooltip:Hide()
  Utils:Debug("Hiding tooltip for frame")
end

function TooltipManager:HideAll()
  if self.activeTooltip then
    self.activeTooltip:Hide()
    self.activeTooltip = nil
  end
end

function TooltipManager:UpdateConfig(frame, config)
  local tooltip = self.attachments[frame]
  if not tooltip then
    return false
  end

  -- Update configuration
  for key, value in pairs(config) do
    tooltip[key] = value
  end

  -- If tooltip is currently visible, update it
  if tooltip.isVisible then
    tooltip:UpdateContent()
    tooltip:PositionRelativeTo(frame)
  end

  return true
end

function Tooltip:New()
  local instance = setmetatable({}, self)
  instance.manager = TooltipManager:New()
  instance.initialized = false
  return instance
end

function Tooltip:Initialize()
  if self.initialized then
    return
  end

  self.initialized = true
  Utils:Debug("Tooltip API initialized")
end

-- Public API Methods
function Tooltip:Attach(frame, config)
  if not self.initialized then
    self:Initialize()
  end
  return self.manager:Attach(frame, config)
end

function Tooltip:Detach(frame) return self.manager:Detach(frame) end

function Tooltip:Update(frame, config) return self.manager:UpdateConfig(frame, config) end

function Tooltip:HideAll() self.manager:HideAll() end

-- Create singleton instance
local tooltipInstance = Tooltip:New()

-- Export to namespace
ns.Tooltip = tooltipInstance

-- Global convenience function
_G.CellAdditions_Tooltip = tooltipInstance

-- Export class for direct access if needed
ns.TooltipClass = Tooltip

Utils:Debug("Universal Tooltip API loaded")
