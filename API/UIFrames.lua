local _, ns = ...

-- Global declarations for WoW API functions
---@diagnostic disable: undefined-global
---@diagnostic enable: undefined-global

-- Create UI frames API
local UIFrames = {}
ns.UIFrames = UIFrames

-- Get references to Cell utilities
local Cell = ns.Cell

-- Get accent color from Cell
local function GetAccentColor()
    return Cell.GetAccentColorTable()
end

-- Create a solo frame
function UIFrames.CreateSoloFrame(parent)
    if not parent then
        parent = UIParent
    end

    -- Ensure CellAdditionsDB exists
    ---@diagnostic disable-next-line: undefined-global
    CellAdditionsDB = CellAdditionsDB or {}
    ---@diagnostic disable-next-line: undefined-global
    CellAdditionsDB.UISettings = CellAdditionsDB.UISettings or {}
    ---@diagnostic disable-next-line: undefined-global
    CellAdditionsDB.framePositions = CellAdditionsDB.framePositions or {}

    -- Create the frame
    local soloFrame = Cell.CreateFrame("CellAdditionsSoloFrame", parent)
    soloFrame:SetSize(200, 60)
    soloFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    Cell.StylizeFrame(soloFrame)

    -- Make it movable
    soloFrame:SetMovable(true)
    soloFrame:RegisterForDrag("LeftButton")
    soloFrame:SetScript("OnDragStart", function(dragFrame)
        ---@diagnostic disable-next-line: undefined-global
        if not CellAdditionsDB.UISettings.locked then
            dragFrame:StartMoving()
        end
    end)
    soloFrame:SetScript("OnDragStop", function(dragFrame)
        dragFrame:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, xOfs, yOfs = dragFrame:GetPoint()
        ---@diagnostic disable-next-line: undefined-global
        CellAdditionsDB.framePositions.soloFrame = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)

    -- Add title
    local title = soloFrame:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
    title:SetPoint("TOP", soloFrame, "TOP", 0, -5)
    title:SetText("Solo Frame")
    title:SetTextColor(GetAccentColor()[1], GetAccentColor()[2], GetAccentColor()[3])

    -- Add health bar
    local healthBar = CreateFrame("StatusBar", nil, soloFrame)
    healthBar:SetStatusBarTexture(Cell.vars.texture)
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)
    healthBar:SetSize(180, 20)
    healthBar:SetPoint("TOP", title, "BOTTOM", 0, -5)
    healthBar:SetStatusBarColor(0, 1, 0)

    -- Add power bar
    local powerBar = CreateFrame("StatusBar", nil, soloFrame)
    powerBar:SetStatusBarTexture(Cell.vars.texture)
    powerBar:SetMinMaxValues(0, 100)
    powerBar:SetValue(100)
    powerBar:SetSize(180, 10)
    powerBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -2)
    powerBar:SetStatusBarColor(0, 0, 1)

    -- Add class icon
    local classIcon = soloFrame:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(24, 24)
    classIcon:SetPoint("LEFT", soloFrame, "LEFT", 5, 0)

    -- Set icon based on player class
    ---@diagnostic disable-next-line: undefined-global
    local classFile = select(2, UnitClass("player"))
    if classFile then
        classIcon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        ---@diagnostic disable-next-line: undefined-global
        classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
    end

    -- Store references
    soloFrame.title = title
    soloFrame.healthBar = healthBar
    soloFrame.powerBar = powerBar
    soloFrame.classIcon = classIcon

    -- Update function for live data
    soloFrame.Update = function(self)
        -- Update health
        ---@diagnostic disable-next-line: undefined-global
        local health = UnitHealth("player")
        ---@diagnostic disable-next-line: undefined-global
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
        ---@diagnostic disable-next-line: undefined-global
        local power = UnitPower("player")
        ---@diagnostic disable-next-line: undefined-global
        local maxPower = UnitPowerMax("player")
        if maxPower > 0 then
            self.powerBar:SetValue(power / maxPower * 100)
        end
    end

    -- Set up update timer
    soloFrame.timer = C_Timer.NewTicker(0.2, function()
        if soloFrame:IsShown() then
            soloFrame:Update()
        end
    end)

    -- Initial update
    soloFrame:Update()

    -- Restore position if saved
    ---@diagnostic disable-next-line: undefined-global
    if CellAdditionsDB.framePositions.soloFrame then
        ---@diagnostic disable-next-line: undefined-global
        local pos = CellAdditionsDB.framePositions.soloFrame
        soloFrame:ClearAllPoints()
        soloFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    end

    -- Store in namespace
    if not ns.frames then ns.frames = {} end
    ns.frames.soloFrame = soloFrame

    return soloFrame
end

-- Create styled divider
function UIFrames.CreateDivider(parent, width, height)
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
    if not ns.frames then ns.frames = {} end
    ns.frames.divider = divider

    return divider
end

-- Create styled toggle switch in Cell style
function UIFrames.CreateToggle(parent, text, callback, tooltips)
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
    function toggle:SetChecked(checked)
        self.button:SetChecked(checked)
    end

    function toggle:GetChecked()
        return self.button:GetChecked()
    end

    function toggle:SetEnabled(enabled)
        Cell.SetEnabled(enabled, self.button, self.label)
    end

    return toggle
end

-- Initialize function to create all UI frames
function UIFrames.Initialize()
    -- Ensure CellAdditionsDB exists
    ---@diagnostic disable-next-line: undefined-global
    CellAdditionsDB = CellAdditionsDB or {}
    ---@diagnostic disable-next-line: undefined-global
    CellAdditionsDB.UISettings = CellAdditionsDB.UISettings or {}

    if ns.Debug then
        ns.Debug("Creating UI frames")
    end

    -- Create solo frame if enabled
    ---@diagnostic disable-next-line: undefined-global
    if CellAdditionsDB.UISettings.soloFrame then
        UIFrames.CreateSoloFrame()
        if ns.Debug then
            ns.Debug("Solo frame created")
        end
    end
end

-- Return the API
return UIFrames