local addonName, ns = ...
local Cell = ns.Cell

-- Create a Shadow API namespace
local ShadowAPI = {}
ns.API = ns.API or {}
ns.API.Shadow = ShadowAPI

-- Constants
local DEFAULT_SHADOW_SIZE = 4
local DEFAULT_SHADOW_COLOR = { r = 0, g = 0, b = 0, a = 1 }
local DEFAULT_GLOW_TEXTURE = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga"

-- Function to check if a frame is actually visible
local function IsFrameActuallyVisible(frame)
    return frame and frame:IsShown() and frame:GetAlpha() > 0
end

-- Create shadow function
function ShadowAPI:CreateShadow(frame, options)
    if not frame or not frame.SetPoint then
        return nil
    end
    
    -- Default options
    options = options or {}
    local size = options.size or DEFAULT_SHADOW_SIZE
    local color = options.color or DEFAULT_SHADOW_COLOR
    local glowTexture = options.texture or DEFAULT_GLOW_TEXTURE
    local frameType = options.frameType
    
    -- If the frame already has a shadow, remove it first so we can update
    if frame.shadow then
        frame.shadow:Hide()
        frame.shadow = nil
    end
    
    -- Create the shadow frame
    local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    
    -- Position the shadow
    shadow:SetFrameLevel(frame:GetFrameLevel() - 1)
    shadow:SetPoint("TOPLEFT", -size, size)
    shadow:SetPoint("BOTTOMRIGHT", size, -size)
    
    -- Set up the backdrop
    shadow:SetBackdrop({
        edgeFile = glowTexture,
        edgeSize = size,
        insets = { left = size, right = size, top = size, bottom = size },
    })
    
    -- Set colors
    shadow:SetBackdropColor(0, 0, 0, 0) -- Transparent center
    
    -- Ensure we have a valid color with all components
    if not color then color = DEFAULT_SHADOW_COLOR end
    if not color.r then color.r = 0 end
    if not color.g then color.g = 0 end
    if not color.b then color.b = 0 end
    if not color.a then color.a = 1 end
    
    shadow:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
    
    -- Store the frame type with the shadow for later updates
    shadow.frameType = frameType
    
    -- Attach the shadow to the frame
    frame.shadow = shadow
    
    return shadow
end

-- Update shadow color
function ShadowAPI:UpdateShadowColor(shadow, color)
    if not shadow then return end
    
    -- Ensure we have a valid color with all components
    if not color then color = DEFAULT_SHADOW_COLOR end
    if not color.r then color.r = 0 end
    if not color.g then color.g = 0 end
    if not color.b then color.b = 0 end
    if not color.a then color.a = 1 end
    
    shadow:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
end

-- Update shadow size
function ShadowAPI:UpdateShadowSize(shadow, size)
    if not shadow or not shadow:GetParent() then return end
    
    local frame = shadow:GetParent()
    size = size or DEFAULT_SHADOW_SIZE
    
    -- Update position
    shadow:ClearAllPoints()
    shadow:SetPoint("TOPLEFT", -size, size)
    shadow:SetPoint("BOTTOMRIGHT", size, -size)
    
    -- Update backdrop
    shadow:SetBackdrop({
        edgeFile = shadow:GetBackdrop().edgeFile or DEFAULT_GLOW_TEXTURE,
        edgeSize = size,
        insets = { left = size, right = size, top = size, bottom = size },
    })
end

-- Frame detection patterns
ShadowAPI.FramePatterns = {
    ["solo"] = {
        "CellSoloFramePlayer",
        "CellSoloFrame",
        "Cell_SoloFrame",
    },
    ["party"] = {
        "CellPartyFrameHeaderUnitButton%d",
        "PartyMemberFrame%d",
        "CompactPartyFrameMember%d",
    },
    ["raid"] = {
        "CellRaidFrameHeader%d",
    },
    ["target"] = {
        "CellTargetFrame",
        "TargetFrame",
    },
    ["targettarget"] = {
        "CellTargetTargetFrame",
        "TargetTargetFrame",
    },
    ["focus"] = {
        "CellFocusFrame",
        "FocusFrame",
    },
    ["pet"] = {
        "CellPetFrame",
        "PetFrame",
    },
    ["boss"] = {
        "CellBossFrame%d",
        "BossFrame%d",
        "Boss%dFrame",
        "Boss%dTargetFrame",
    },
    ["healthbar"] = {
        -- Solo frame
        "CellSoloFramePlayerHealthBar",
        -- Party frames
        "CellPartyFrameHeaderUnitButton%dHealthBar",
        -- Raid frames
        "CellRaidFrameHeader%dUnitButton%dHealthBar",
        -- Target frame
        "CellTargetFrameHealthBar",
        -- Target's target frame
        "CellTargetTargetFrameHealthBar",
        -- Focus frame
        "CellFocusFrameHealthBar",
        -- Pet frame
        "CellPetFrameHealthBar",
        -- Boss frames
        "CellBossFrame%dHealthBar",
        -- Additional patterns for health bars
        "Cell_SoloFramePlayerHealthBar",
        "Cell_TargetFrameHealthBar",
        "Cell_TargetTargetFrameHealthBar",
        "Cell_FocusFrameHealthBar",
        "Cell_PetFrameHealthBar",
        -- CUF frames
        "CUF_PlayerHealthBar",
        "CUF_Player_HealthBar",
        "CUF_TargetHealthBar",
        "CUF_Target_HealthBar",
        "CUF_TargetTargetHealthBar",
        "CUF_TargetTarget_HealthBar",
        "CUF_FocusHealthBar",
        "CUF_Focus_HealthBar",
        "CUF_PetHealthBar",
        "CUF_Pet_HealthBar",
        "CUF_Boss%dHealthBar",
        "CUF_Boss%d_HealthBar",
    },
    ["powerbar"] = {
        -- Solo frame
        "CellSoloFramePlayerPowerBar",
        -- Party frames
        "CellPartyFrameHeaderUnitButton%dPowerBar",
        -- Raid frames
        "CellRaidFrameHeader%dUnitButton%dPowerBar",
        -- Target frame
        "CellTargetFramePowerBar",
        -- Target's target frame
        "CellTargetTargetFramePowerBar",
        -- Focus frame
        "CellFocusFramePowerBar",
        -- Pet frame
        "CellPetFramePowerBar",
        -- Boss frames
        "CellBossFrame%dPowerBar",
        -- Additional patterns for power bars
        "Cell_SoloFramePlayerPowerBar",
        "Cell_TargetFramePowerBar",
        "Cell_TargetTargetFramePowerBar",
        "Cell_FocusFramePowerBar",
        "Cell_PetFramePowerBar",
        -- CUF frames
        "CUF_PlayerPowerBar",
        "CUF_Player_PowerBar",
        "CUF_TargetPowerBar",
        "CUF_Target_PowerBar",
        "CUF_TargetTargetPowerBar",
        "CUF_TargetTarget_PowerBar",
        "CUF_FocusPowerBar",
        "CUF_Focus_PowerBar",
        "CUF_PetPowerBar",
        "CUF_Pet_PowerBar",
        "CUF_Boss%dPowerBar",
        "CUF_Boss%d_PowerBar",
    },
}

-- Function to find frames by pattern
function ShadowAPI:FindFramesByPattern(pattern)
    local frames = {}
    
    -- Special handling for patterns with double %d (like raid frames with header and button)
    if pattern:find("%d.*%d") then
        -- For patterns like CellRaidFrameHeader%dUnitButton%dHealthBar
        for i = 1, 8 do -- Headers
            for j = 1, 5 do -- Buttons per header
                local frameName = pattern
                frameName = frameName:gsub("%d", i, 1) -- Replace first %d with i
                frameName = frameName:gsub("%d", j, 1) -- Replace second %d with j
                local frame = _G[frameName]
                if frame and IsFrameActuallyVisible(frame) then
                    table.insert(frames, frame)
                end
            end
        end
    -- If pattern contains a single %d, iterate through numbers
    elseif pattern:find("%d") then
        for i = 1, 40 do -- Reasonable limit for party/raid frames
            local frameName = pattern:gsub("%d", i)
            local frame = _G[frameName]
            if frame and IsFrameActuallyVisible(frame) then
                table.insert(frames, frame)
            end
        end
    else
        -- Simple lookup for non-numbered frames
        local frame = _G[pattern]
        if frame and IsFrameActuallyVisible(frame) then
            table.insert(frames, frame)
        end
    end
    
    return frames
end

-- Function to find all frames of a specific type
function ShadowAPI:FindFramesByType(frameType)
    local frames = {}
    local patterns = self.FramePatterns[string.lower(frameType)]
    
    if not patterns then return frames end
    
    for _, pattern in ipairs(patterns) do
        local foundFrames = self:FindFramesByPattern(pattern)
        for _, frame in ipairs(foundFrames) do
            table.insert(frames, frame)
        end
    end
    
    return frames
end

-- Return the API
return ShadowAPI
