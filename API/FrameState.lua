local _, ns = ...
local _, ns = ...
local Cell = ns.Cell

-- Create an API namespace for frame state detection
local FrameState = {}
ns.API = ns.API or {}
ns.API.FrameState = FrameState

-- Local variables
local currentLayout = nil

-- Function to refresh and get the current layout information
function FrameState.GetCurrentLayout()
    -- Get current layout information
    if Cell and Cell.vars.db then
        -- Check current active layout
        if Cell.vars and Cell.vars.currentLayout then
            currentLayout = Cell.vars.currentLayout
        end
    end
    return currentLayout
end

-- Function to check if a frame type is enabled in Cell Unit Frames
function FrameState.IsFrameTypeEnabled(frameType)
    -- Default to enabled
    local isEnabled = true
    -- Map frameType to unit key in CUF_DB if it's one of our predefined types
    local unitKey
    if frameType == "TargetTarget" then 
        unitKey = "targettarget"
    elseif frameType == "Pet" then 
        unitKey = "pet"
    elseif frameType == "Focus" then 
        unitKey = "focus"
    elseif frameType == "Party" then 
        unitKey = "party"
    elseif frameType == "Raid" then 
        unitKey = "raid"
    elseif frameType == "Solo" then 
        unitKey = "player"
    else
        -- For any other frame type, try to use it directly as a unit key
        -- This allows checking any unit frame type that Cell supports
        unitKey = string.lower(frameType)
    end
    -- Get the layout table safely
    if _G.CUF and _G.CUF.DB and _G.CUF.DB.CurrentLayoutTable then
        local layout = _G.CUF.DB.CurrentLayoutTable()
        -- If we have a layout table and a unit key, check the enabled state
        if layout and unitKey and layout[unitKey] then
            -- Check for enabled property
            if layout[unitKey].enabled ~= nil then
                isEnabled = layout[unitKey].enabled
            elseif layout[unitKey].show ~= nil then
                isEnabled = layout[unitKey].show
            end
        end
    end
    return isEnabled
end

-- Function to get all available frame types from the current layout
function FrameState.GetAvailableFrameTypes()
    local availableTypes = {}
    -- Get the layout table safely
    if _G.CUF and _G.CUF.DB and _G.CUF.DB.CurrentLayoutTable then
        local layout = _G.CUF.DB.CurrentLayoutTable()
        -- If we have a layout, get all unit keys
        if layout then
            for unitKey, _ in pairs(layout) do
                -- Convert some common unit keys to more readable names
                if unitKey == "targettarget" then
                    table.insert(availableTypes, "TargetTarget")
                elseif unitKey == "player" then
                    table.insert(availableTypes, "Solo")
                else
                    -- Capitalize the first letter for better readability
                    local firstChar = string.sub(unitKey, 1, 1)
                    local rest = string.sub(unitKey, 2)
                    table.insert(availableTypes, string.upper(firstChar) .. rest)
                end
            end
        end
    end
    return availableTypes
end

-- Function to get all frame types' states
function FrameState.GetAllFrameStates()
    local frameTypes = FrameState.GetAvailableFrameTypes()
    local states = {}
    for _, frameType in ipairs(frameTypes) do
        states[frameType] = FrameState.IsFrameTypeEnabled(frameType)
    end
    return states
end

-- Function to register for Cell callbacks
function FrameState.RegisterCallbacks(callbackFunc)
    if not Cell then return false end
    -- Register for layout changes
    Cell:RegisterCallback("CellLayoutChanged", callbackFunc)
    -- Register for setup completion
    Cell:RegisterCallback("CellSetupDone", callbackFunc)
    -- Also register with CUF callbacks if available
    if _G.CUF then
        -- Listen for layout changes
        _G.CUF:RegisterCallback("UpdateLayout", "CellAdditions_FrameState_UpdateLayout", callbackFunc)
        -- Listen for widget updates (which includes enabling/disabling frames)
        _G.CUF:RegisterCallback("UpdateWidget", "CellAdditions_FrameState_UpdateWidget", callbackFunc)
        -- Listen for DB changes
        _G.CUF:RegisterCallback("LoadPageDB", "CellAdditions_FrameState_LoadPageDB", callbackFunc)
    end
    return true
end

-- Return the API
return FrameState
