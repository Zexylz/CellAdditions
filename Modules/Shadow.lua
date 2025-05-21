local addonName, ns = ...

-- Create module with metatable for better performance
local Shadow = setmetatable({
    id = "Shadow",
    name = "Shadow",
    description = "Apply shadows to Cell frames",
    frameRegistry = setmetatable({}, {__mode = "k"}), -- weak table to allow garbage collection
    updateThrottle = 0.1,
    lastUpdate = 0
}, {
    __index = function(t, k)
        if k == "settings" then
            return CellAdditionsDB.shadowSettings
        end
        return nil
    end
})

-- Get references to Cell utilities
local Cell = ns.Cell
local L = Cell and Cell.L or {}
local F = Cell and Cell.funcs or {}
local P = Cell and Cell.pixelPerfectFuncs or {}

-- Constants
local SHADOW_TEX = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga"  -- Confirmed this file exists!

-- Frame patterns for detection
local framePatterns = {
    ["Solo"] = {
        "CellSoloFramePlayer",
        "CellSoloFrame",
        "Cell_SoloFrame",
        "CellSoloPlayerFrame", -- Add this back in to ensure it works
    },
    ["Party"] = {
        "CellPartyFrameHeaderUnitButton%d",
    },
    ["Raid"] = {
        "CellRaidFrameHeader%dUnitButton%d",
    },
    ["Target"] = {
        "TargetFrame",
        "CellTargetFrame",
        "CellUnitFrameTarget",
        "CellUnitButton_target"
    },
}

-- UnitFrame types and their corresponding frame names
local unitFrameTypes = {
    Player = {
        healthBar = "CUF_Player_HealthBar",
        powerBar = "CUF_Player_PowerBar",
        -- Add alternative frame names to check
        altHealthBar = "PlayerFrameHealthBar",
        altPowerBar = "PlayerFrameManaBar",
        -- Cell-specific frames
        cellHealthBar = "CellUnitFramePlayerHealthBar",
        cellPowerBar = "CellUnitFramePlayerPowerBar"
    },
    Target = {
        -- Add CUF_Target so it works like other frames
        frame = "CUF_Target",
        healthBar = "CUF_Target_HealthBar", 
        powerBar = "CUF_Target_PowerBar",
        -- Add alternative frame names that Cell might be using
        altHealthBar = "TargetFrameHealthBar",
        altPowerBar = "TargetFrameManaBar",
        -- Cell-specific frames
        cellHealthBar = "CellUnitFrameTargetHealthBar",
        cellPowerBar = "CellUnitFrameTargetPowerBar"
    },
    TargetTarget = {
        healthBar = "CUF_TargetTarget_HealthBar",
        powerBar = "CUF_TargetTarget_PowerBar",
        -- Add alternative frame names
        altHealthBar = "TargetFrameToTHealthBar",
        altPowerBar = "TargetFrameToTManaBar",
        -- Cell-specific frames
        cellHealthBar = "CellUnitFrameTargetTargetHealthBar",
        cellPowerBar = "CellUnitFrameTargetTargetPowerBar"
    },
    Focus = {
        healthBar = "CUF_Focus_HealthBar",
        powerBar = "CUF_Focus_PowerBar",
        -- Add alternative frame names
        altHealthBar = "FocusFrameHealthBar",
        altPowerBar = "FocusFrameManaBar",
        -- Cell-specific frames
        cellHealthBar = "CellUnitFrameFocusHealthBar",
        cellPowerBar = "CellUnitFrameFocusPowerBar"
    },
    Pet = {
        healthBar = "CUF_Pet_HealthBar",
        powerBar = "CUF_Pet_PowerBar",
        -- Add alternative frame names
        altHealthBar = "PetFrameHealthBar",
        altPowerBar = "PetFrameManaBar",
        -- Cell-specific frames
        cellHealthBar = "CellUnitFramePetHealthBar",
        cellPowerBar = "CellUnitFramePetPowerBar"
    }
}

-- Shadow prototype
local ShadowPrototype = {}

function ShadowPrototype:Update(size, r, g, b, a)
    if not self.frame or not self.shadowFrame then return end
    
    local frameName = self.frame:GetName() or "unnamed"
    ns.Debug("Updating shadow for " .. frameName .. ": size=" .. size .. ", color=" .. r .. "," .. g .. "," .. b .. "," .. a)
    
    -- Make shadows more visible - use a larger size and offset
    local effectiveSize = size * 1.5  -- Make shadow bigger for visibility
    
    -- Update size with a larger offset to make shadow more visible
    self.shadowFrame:SetPoint("TOPLEFT", -effectiveSize, effectiveSize)
    self.shadowFrame:SetPoint("BOTTOMRIGHT", effectiveSize, -effectiveSize)
    
    -- Update backdrop with more visible settings
    self.shadowFrame:SetBackdrop({
        edgeFile = SHADOW_TEX,
        edgeSize = effectiveSize,
        insets = { left = effectiveSize, right = effectiveSize, top = effectiveSize, bottom = effectiveSize },
    })
    
    -- Update color - ensure high alpha (at least 0.8) for visibility
    self.shadowFrame:SetBackdropColor(0, 0, 0, 0)
    local effectiveAlpha = math.max(0.8, a or 1)  -- Ensure alpha is at least 0.8
    self.shadowFrame:SetBackdropBorderColor(r, g, b, effectiveAlpha)
    
    -- Make sure the shadow is shown
    self.shadowFrame:Show()
    
    ns.Debug("Shadow updated with enhanced visibility for " .. frameName)
end

function ShadowPrototype:Show()
    if self.shadowFrame then
        self.shadowFrame:Show()
    end
end

function ShadowPrototype:Hide()
    if self.shadowFrame then
        self.shadowFrame:Hide()
    end
end

function ShadowPrototype:Remove()
    if self.shadowFrame then
        self.shadowFrame:Hide()
        self.shadowFrame = nil
    end
    Shadow.frameRegistry[self.frame] = nil
end

-- Shadow metatable
local ShadowMT = {
    __index = ShadowPrototype
}

-- Create shadow for a frame
local function CreateShadow(frame, frameType)
    if not frame or not frame.SetPoint or frame.shadow then
        return nil
    end
    
    -- Debug output for more information
    local frameName = frame:GetName() or "unnamed"
    ns.Debug("Creating shadow for " .. frameName .. " (" .. (frameType or "unknown") .. ")")
    
    -- Create shadow frame
    local shadowFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    
    -- Get frame level safely
    local currentLevel = 0
    local success = pcall(function() currentLevel = frame:GetFrameLevel() end)
    
    -- Set frame level safely with a default if there's an error
    if success and currentLevel > 0 then
        shadowFrame:SetFrameLevel(currentLevel - 1)
        ns.Debug("Shadow frame level set to: " .. (currentLevel - 1))
    else
        shadowFrame:SetFrameLevel(0) -- Use a safe default
        ns.Debug("Using default shadow frame level: 0")
    end
    
    -- Create shadow object
    local shadow = setmetatable({
        frame = frame,
        shadowFrame = shadowFrame,
        frameType = frameType
    }, ShadowMT)
    
    -- Store in registry
    Shadow.frameRegistry[frame] = shadow
    
    -- Initial update
    local settings = Shadow.settings
    local size = settings.shadowSize or 5
    local color = {
        r = 0,
        g = 0,
        b = 0,
        a = 1
    }
    
    shadow:Update(size, color.r, color.g, color.b, color.a)
    
    -- Store reference on the frame
    frame.shadow = shadow
    
    ns.Debug("Shadow created successfully for " .. frameName)
    
    return shadow
end

-- Helper to check if a frame is actually visible
local function IsFrameActuallyVisible(frame)
    if not frame then return false end
    
    -- Basic visibility check
    if not frame:IsVisible() or frame:GetAlpha() <= 0 then
        return false
    end
    
    -- Try to get name (might be nil for some frames)
    local name = frame:GetName() or ""
    
    -- Extra checks for raid/party frames
    if name:match("CellRaidFrameHeader%dUnitButton%d") then
        -- For raid frames, check if they have a unit assigned
        if frame.unit or (frame.state and frame.state.unit) then
            return true
        end
        return false
    end
    
    -- For other frames, use basic visibility
    return true
end

-- Get the type of a frame
function Shadow:GetFrameType(frame)
    if not frame then return nil end
    
    -- Try to get name (might be nil for some frames)
    local name = frame:GetName() or ""
    
    -- Check patterns
    for frameType, patterns in pairs(framePatterns) do
        for _, pattern in ipairs(patterns) do
            if name:match(pattern) then
                return frameType
            end
        end
    end
    
    return nil
end

-- Scan for all relevant frames
function Shadow:ScanForFrames()
    -- Always try to apply shadow to CUF_Target
    self:ApplyShadowToCUFTarget()
    
    -- Also apply shadow to CUF_Focus
    self:ApplyShadowToCUFFocus()
    
    -- Scan for solo frames
    for _, pattern in ipairs(framePatterns.Solo) do
        local frame = _G[pattern]
        if frame and IsFrameActuallyVisible(frame) then
            if not self.frameRegistry[frame] then
                CreateShadow(frame, "Solo")
            end
        end
    end
    
    -- Scan for party frames
    for i = 1, 5 do
        local frameName = "CellPartyFrameHeaderUnitButton" .. i
        local frame = _G[frameName]
        if frame and IsFrameActuallyVisible(frame) then
            if not self.frameRegistry[frame] then
                CreateShadow(frame, "Party")
            end
        end
    end
    
    -- Scan for raid frames
    for i = 1, 8 do
        for j = 1, 5 do
            local frameName = "CellRaidFrameHeader" .. i .. "UnitButton" .. j
            local frame = _G[frameName]
            if frame and IsFrameActuallyVisible(frame) then
                if not self.frameRegistry[frame] then
                    CreateShadow(frame, "Raid")
                end
            end
        end
    end
    
    -- Scan for target frames specifically
    if self.settings.unitFrames.Target and self.settings.unitFrames.Target.enabled then
        -- Check framePatterns.Target list
        for _, pattern in ipairs(framePatterns.Target) do
            local frame = _G[pattern]
            if frame then
                if not self.frameRegistry[frame] then
                    ns.Debug("Found target frame: " .. pattern)
                    CreateShadow(frame, "Target")
                end
            end
        end
        
        -- Also try additional patterns like health bars
        local targetHealthBar = _G["TargetFrameHealthBar"]
        if targetHealthBar and not self.frameRegistry[targetHealthBar] then
            ns.Debug("Found TargetFrameHealthBar")
            CreateShadow(targetHealthBar, "Target")
        end
    end
    
    -- Scan for unit frames
    for unitType, frames in pairs(unitFrameTypes) do
        if self.settings.unitFrames[unitType] and self.settings.unitFrames[unitType].enabled then
            for barType, frameName in pairs(frames) do
                local frame = _G[frameName]
                if frame then
                    if not self.frameRegistry[frame] then
                        ns.Debug("Creating shadow for " .. unitType .. " frame: " .. (frameName or "unnamed"))
                        CreateShadow(frame, unitType)
                    end
                end
            end
        end
    end
end

-- Update all shadows based on current settings
function Shadow:UpdateAllShadows()
    -- Update settings from Cell shadow frames
    local settings = self.settings
    
    -- Update color and size for all managed shadows
    for frame, shadow in pairs(self.frameRegistry) do
        if IsFrameActuallyVisible(frame) then
            -- Determine if shadow should be shown based on frame type
            local shouldShow = false
            local frameType = shadow.frameType
            
            if frameType == "Solo" then
                shouldShow = settings.unitFrames.Solo and settings.unitFrames.Solo.enabled
            elseif frameType == "Party" then
                shouldShow = settings.partyFrames
            elseif frameType == "Raid" then
                shouldShow = settings.raidFrames
            elseif unitFrameTypes[frameType] then
                shouldShow = settings.unitFrames[frameType] and settings.unitFrames[frameType].enabled
            end
            
            if shouldShow then
                local size = settings.shadowSize
                local color = {r = 0, g = 0, b = 0, a = 1}
                
                -- Apply color based on frame type
                if frameType == "Solo" and settings.unitFrames.Solo then
                    -- Check if healthColor exists and provide defaults if not
                    if settings.unitFrames.Solo.healthColor then
                        color = {
                            r = settings.unitFrames.Solo.healthColor[1],
                            g = settings.unitFrames.Solo.healthColor[2],
                            b = settings.unitFrames.Solo.healthColor[3],
                            a = settings.unitFrames.Solo.healthColor[4] or 1
                        }
                    else
                        -- Default color for Solo frame
                        color = {r = 0.7, g = 0.9, b = 0.3, a = 1}
                        -- Create the healthColor table since it's missing
                        settings.unitFrames.Solo.healthColor = {0.7, 0.9, 0.3, 1}
                    end
                elseif frameType == "Party" then
                    -- Check if partyHealthColor exists
                    if settings.partyHealthColor and #settings.partyHealthColor >= 3 then
                        color = {
                            r = settings.partyHealthColor[1],
                            g = settings.partyHealthColor[2],
                            b = settings.partyHealthColor[3],
                            a = settings.partyHealthColor[4] or 1
                        }
                    else
                        -- Default lime green for party
                        color = {r = 0.7, g = 0.9, b = 0.3, a = 1}
                        settings.partyHealthColor = {0.7, 0.9, 0.3, 1}
                    end
                elseif frameType == "Raid" then
                    -- Check if raidHealthColor exists
                    if settings.raidHealthColor and #settings.raidHealthColor >= 3 then
                        color = {
                            r = settings.raidHealthColor[1],
                            g = settings.raidHealthColor[2],
                            b = settings.raidHealthColor[3],
                            a = settings.raidHealthColor[4] or 1
                        }
                    else
                        -- Default orange for raid
                        color = {r = 0.9, g = 0.7, b = 0.3, a = 1}
                        settings.raidHealthColor = {0.9, 0.7, 0.3, 1}
                    end
                elseif unitFrameTypes[frameType] and settings.unitFrames[frameType] then
                    -- Unit frame color depends on whether it's health or power bar
                    local frameName = frame:GetName() or ""
                    if frameName:match("HealthBar") then
                        -- Check if healthColor exists
                        if settings.unitFrames[frameType].healthColor then
                            color = {
                                r = settings.unitFrames[frameType].healthColor[1],
                                g = settings.unitFrames[frameType].healthColor[2],
                                b = settings.unitFrames[frameType].healthColor[3],
                                a = settings.unitFrames[frameType].healthColor[4] or 1
                            }
                        else
                            -- Default color based on frame type
                            color = {r = 0.7, g = 0.9, b = 0.3, a = 1}
                            settings.unitFrames[frameType].healthColor = {0.7, 0.9, 0.3, 1}
                        end
                    elseif frameName:match("PowerBar") then
                        -- Check if powerColor exists
                        if settings.unitFrames[frameType].powerColor then
                            color = {
                                r = settings.unitFrames[frameType].powerColor[1],
                                g = settings.unitFrames[frameType].powerColor[2],
                                b = settings.unitFrames[frameType].powerColor[3],
                                a = settings.unitFrames[frameType].powerColor[4] or 1
                            }
                        else
                            -- Default power color
                            color = {r = 0.3, g = 0.7, b = 0.9, a = 1}
                            settings.unitFrames[frameType].powerColor = {0.3, 0.7, 0.9, 1}
                        end
                    end
                end
                
                shadow:Update(size, color.r, color.g, color.b, color.a)
                shadow:Show()
            else
                shadow:Hide()
            end
        else
            shadow:Hide()
        end
    end
end

-- Remove shadows that are no longer needed (with more lenient conditions)
function Shadow:CleanupShadows()
    for frame, shadow in pairs(self.frameRegistry) do
        -- Only remove shadows for frames that have been gone for a while
        -- This helps with frames that briefly disappear during updates
        if not frame.lastSeen then
            frame.lastSeen = GetTime()
        end
        
        local currentTime = GetTime()
        local frameGone = not frame:IsVisible() or not frame:GetParent()
        
        if frameGone then
            -- If frame has been gone for more than 2 seconds, remove the shadow
            if currentTime - frame.lastSeen > 2 then
                ns.Debug("Removing shadow for frame that's been gone for >2 seconds")
                shadow:Remove()
            end
        else
            -- Update last seen time when frame is visible
            frame.lastSeen = currentTime
        end
    end
end

-- Initialize default settings
local function InitSettings()
    -- Create default shadow settings if they don't exist
    if not CellAdditionsDB.shadowSettings then
        CellAdditionsDB.shadowSettings = {
            enabled = true,
            shadowSize = 5,
            
            -- Cell group frames
            partyFrames = true,
            partyHealthColor = {0.7, 0.9, 0.3, 1},
            partyPowerColor = {0.9, 0.7, 0.3, 1},
            raidFrames = false,
            raidHealthColor = {0.9, 0.7, 0.3, 1},
            raidPowerColor = {0.9, 0.5, 0.3, 1},
            
            -- Unit frames with their health and power colors
            unitFrames = {
                Solo = {
                    enabled = true,
                    healthColor = {0.7, 0.9, 0.3, 1},
                    powerColor = {0.9, 0.7, 0.3, 1}
                },
                Player = {
                    enabled = true,
                    healthColor = {0.7, 0.9, 0.3, 1},
                    powerColor = {0.9, 0.7, 0.3, 1}
                },
                Target = {
                    enabled = true, -- Set to TRUE by default
                    healthColor = {0.9, 0.7, 0.3, 1},
                    powerColor = {0.9, 0.5, 0.3, 1}
                },
                TargetTarget = {
                    enabled = false,
                    healthColor = {0.9, 0.3, 0.5, 1},
                    powerColor = {0.9, 0.3, 0.5, 1}
                },
                Focus = {
                    enabled = true,
                    healthColor = {0.7, 0.3, 0.7, 1},
                    powerColor = {0.5, 0.3, 0.7, 1}
                },
                Pet = {
                    enabled = false,
                    healthColor = {0.5, 0.3, 0.7, 1},
                    powerColor = {0.5, 0.3, 0.7, 1}
                }
            }
        }
    else
        -- Ensure all required tables exist to prevent nil errors
        local settings = CellAdditionsDB.shadowSettings
        
        -- Initialize basic settings
        settings.enabled = settings.enabled ~= nil and settings.enabled or true
        settings.shadowSize = settings.shadowSize or 5
        
        -- Initialize party/raid settings
        settings.partyFrames = settings.partyFrames ~= nil and settings.partyFrames or true
        settings.partyHealthColor = settings.partyHealthColor or {0.7, 0.9, 0.3, 1}
        settings.partyPowerColor = settings.partyPowerColor or {0.9, 0.7, 0.3, 1}
        settings.raidFrames = settings.raidFrames ~= nil and settings.raidFrames or false
        settings.raidHealthColor = settings.raidHealthColor or {0.9, 0.7, 0.3, 1}
        settings.raidPowerColor = settings.raidPowerColor or {0.9, 0.5, 0.3, 1}
        
        -- Initialize unit frames
        settings.unitFrames = settings.unitFrames or {}
        
        -- Default unit frame settings
        local defaultUnitFrames = {
            Solo = {
                enabled = true,
                healthColor = {0.7, 0.9, 0.3, 1},
                powerColor = {0.9, 0.7, 0.3, 1}
            },
            Player = {
                enabled = true,
                healthColor = {0.7, 0.9, 0.3, 1},
                powerColor = {0.9, 0.7, 0.3, 1}
            },
            Target = {
                enabled = false,
                healthColor = {0.9, 0.7, 0.3, 1},
                powerColor = {0.9, 0.5, 0.3, 1}
            },
            TargetTarget = {
                enabled = false,
                healthColor = {0.9, 0.3, 0.5, 1},
                powerColor = {0.9, 0.3, 0.5, 1}
            },
            Focus = {
                enabled = true,
                healthColor = {0.7, 0.3, 0.7, 1},
                powerColor = {0.5, 0.3, 0.7, 1}
            },
            Pet = {
                enabled = false,
                healthColor = {0.5, 0.3, 0.7, 1},
                powerColor = {0.5, 0.3, 0.7, 1}
            }
        }
        
        -- Ensure all unit frame settings exist
        for unitType, defaults in pairs(defaultUnitFrames) do
            if not settings.unitFrames[unitType] then
                settings.unitFrames[unitType] = defaults
            else
                -- Ensure sub-fields exist
                local unitSettings = settings.unitFrames[unitType]
                unitSettings.enabled = unitSettings.enabled ~= nil and unitSettings.enabled or defaults.enabled
                unitSettings.healthColor = unitSettings.healthColor or defaults.healthColor
                unitSettings.powerColor = unitSettings.powerColor or defaults.powerColor
            end
        end
    end
    
    return CellAdditionsDB.shadowSettings
end

-- Apply shadow settings to frames
local function ApplyShadows()
    local settings = CellAdditionsDB.shadowSettings
    
    if not settings or not settings.enabled then
        ns.Debug("Shadows disabled, not applying")
        return
    end
    
    ns.Debug("Applying shadow settings")
    
    -- Scan for frames first
    Shadow:ScanForFrames()
    
    -- Update all shadows
    Shadow:UpdateAllShadows()
    
    -- Clean up any unused shadows
    Shadow:CleanupShadows()
end

-- Direct method for CUF_Target since it's having issues with the normal way
function Shadow:ApplyShadowToCUFTarget()
    local frame = _G["CUF_Target"]
    if not frame then return false end
    
    -- Get user settings for the shadow
    local settings = self.settings
    if not settings or not settings.enabled then return false end
    
    -- Get target-specific settings
    local targetSettings = settings.unitFrames.Target
    if not targetSettings or not targetSettings.enabled then return false end
    
    -- Get shadow size and color
    local size = settings.shadowSize or 5   
    local color = targetSettings.healthColor or {0.9, 0.7, 0.3, 1}
    
    -- Remove existing shadow if present
    if frame.shadow and self.frameRegistry[frame] then
        self.frameRegistry[frame]:Remove()
    end
    
    -- Create new shadow frame
    local shadowFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    shadowFrame:SetFrameLevel(0) -- Safe level that always works
    
    -- Position the shadow
    shadowFrame:SetPoint("TOPLEFT", -size, size)
    shadowFrame:SetPoint("BOTTOMRIGHT", size, -size)
    
    -- Set backdrop
    shadowFrame:SetBackdrop({
        edgeFile = SHADOW_TEX,
        edgeSize = size,
        insets = { left = size, right = size, top = size, bottom = size },
    })
    
    -- Apply user colors
    shadowFrame:SetBackdropColor(0, 0, 0, 0)
    shadowFrame:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
    
    -- Create shadow object
    local shadow = setmetatable({
        frame = frame,
        shadowFrame = shadowFrame,
        frameType = "Target"
    }, ShadowMT)
    
    -- Store in registry and on the frame
    self.frameRegistry[frame] = shadow
    frame.shadow = shadow
    
    return true
end

-- Direct method for CUF_Focus (based on target method)
function Shadow:ApplyShadowToCUFFocus()
    local frame = _G["CUF_Focus"]
    if not frame then return false end
    
    -- Get user settings for the shadow
    local settings = self.settings
    if not settings or not settings.enabled then return false end
    
    -- Get focus-specific settings
    local focusSettings = settings.unitFrames.Focus
    if not focusSettings or not focusSettings.enabled then return false end
    
    -- Get shadow size and color
    local size = settings.shadowSize or 5
    local color = focusSettings.healthColor or {0.7, 0.3, 0.7, 1} -- Default purple for focus
    
    -- Remove existing shadow if present
    if frame.shadow and self.frameRegistry[frame] then
        self.frameRegistry[frame]:Remove()
    end
    
    -- Create new shadow frame
    local shadowFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    shadowFrame:SetFrameLevel(0) -- Safe level that always works
    
    -- Position the shadow
    shadowFrame:SetPoint("TOPLEFT", -size, size)
    shadowFrame:SetPoint("BOTTOMRIGHT", size, -size)
    
    -- Set backdrop
    shadowFrame:SetBackdrop({
        edgeFile = SHADOW_TEX,
        edgeSize = size,
        insets = { left = size, right = size, top = size, bottom = size },
    })
    
    -- Apply user colors
    shadowFrame:SetBackdropColor(0, 0, 0, 0)
    shadowFrame:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
    
    -- Create shadow object
    local shadow = setmetatable({
        frame = frame,
        shadowFrame = shadowFrame,
        frameType = "Focus"
    }, ShadowMT)
    
    -- Store in registry and on the frame
    self.frameRegistry[frame] = shadow
    frame.shadow = shadow
    
    return true
end

-- No special target function needed anymore

-- Module initialization
function Shadow:Initialize()
    ns.Debug("Shadow module initializing")
    
    -- Initialize settings
    InitSettings()
    
    -- Create an update frame
    local updateFrame = CreateFrame("Frame")
    self.updateFrame = updateFrame
    
    -- This frame will handle periodic updates for shadows
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        Shadow.lastUpdate = Shadow.lastUpdate + elapsed
        if Shadow.lastUpdate >= Shadow.updateThrottle then
            Shadow.lastUpdate = 0
            
            if CellAdditionsDB.shadowSettings.enabled then
                -- Scan for new frames
                Shadow:ScanForFrames()
                
                -- Update existing shadows
                Shadow:UpdateAllShadows()
                
                -- Clean up unused shadows
                Shadow:CleanupShadows()
            end
        end
    end)
    
    -- Register for Cell events
    if Cell and Cell.RegisterCallback then
        Cell:RegisterCallback("Cell_Init", function()
            C_Timer.After(0.5, function()
                if CellAdditionsDB.shadowSettings.enabled then
                    Shadow:ScanForFrames()
                    Shadow:UpdateAllShadows()
                    -- Force target shadows specifically
                    if CellAdditionsDB.shadowSettings.unitFrames.Target and 
                       CellAdditionsDB.shadowSettings.unitFrames.Target.enabled then
                        Shadow:ForceTargetFrameShadow()
                    end
                end
            end)
        end)
        
        Cell:RegisterCallback("Cell_UnitButtonCreated", function()
            C_Timer.After(0.1, function()
                if CellAdditionsDB.shadowSettings.enabled then
                    Shadow:ScanForFrames()
                    Shadow:UpdateAllShadows()
                end
            end)
        end)
        
        -- These events handle updates to various frame types
        local updateEvents = {
            "Cell_RaidFrame_Update",
            "Cell_PartyFrame_Update",
            "Cell_SoloFrame_Update",
            "Cell_Group_Moved",
            "Cell_Group_Updated",
            "Cell_Layout_Updated"
        }
        
        for _, event in ipairs(updateEvents) do
            Cell:RegisterCallback(event, function()
                if CellAdditionsDB.shadowSettings.enabled then
                    C_Timer.After(0.1, function()
                        Shadow:ScanForFrames()
                        Shadow:UpdateAllShadows()
                    end)
                end
            end)
        end
    end
    
    -- Also register for WoW events
    local eventFrame = CreateFrame("Frame")
    self.eventFrame = eventFrame
    
    -- Add specific handler for Target frames
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    -- This additional event handling is dedicated to Target frames
    -- which often have issues with shadows
    eventFrame:HookScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_TARGET_CHANGED" then
            -- Wait a moment for the target frame to fully update
            C_Timer.After(0.1, function()
                -- Check if target shadows are enabled
                if CellAdditionsDB and 
                   CellAdditionsDB.shadowSettings and 
                   CellAdditionsDB.shadowSettings.enabled and
                   CellAdditionsDB.shadowSettings.unitFrames and
                   CellAdditionsDB.shadowSettings.unitFrames.Target and
                   CellAdditionsDB.shadowSettings.unitFrames.Target.enabled then
                    
                    ns.Debug("Target changed, checking for target frames...")
                    
                    -- Direct frame check for Blizzard target frame
                    local targetFrame = _G["TargetFrame"]
                    if targetFrame then
                        ns.Debug("Found Blizzard TargetFrame")
                        if not Shadow.frameRegistry[targetFrame] then
                            CreateShadow(targetFrame, "Target")
                        end
                    end
                    
                    -- Check for target health bar
                    local healthBar = _G["TargetFrameHealthBar"]
                    if healthBar then
                        ns.Debug("Found TargetFrameHealthBar")
                        if not Shadow.frameRegistry[healthBar] then
                            CreateShadow(healthBar, "Target")
                        end
                    end
                    
                    -- Check for Cell target frame
                    local cellTarget = _G["CellUnitFrameTarget"]
                    if cellTarget then
                        ns.Debug("Found CellUnitFrameTarget")
                        if not Shadow.frameRegistry[cellTarget] then
                            CreateShadow(cellTarget, "Target")
                        end
                    end
                    
                    -- Apply all shadows to ensure they're updated
                    ApplyShadows()
                end
            end)
        end
    end)
    
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    eventFrame:RegisterEvent("GROUP_JOINED")
    eventFrame:RegisterEvent("GROUP_LEFT")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" and ... == "Cell" then
            C_Timer.After(1, function()
                if CellAdditionsDB.shadowSettings.enabled then
                    Shadow:ScanForFrames()
                    Shadow:UpdateAllShadows()
                end
            end)
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, function()
                if CellAdditionsDB.shadowSettings.enabled then
                    Shadow:ScanForFrames()
                    Shadow:UpdateAllShadows()
                end
            end)
        elseif CellAdditionsDB.shadowSettings.enabled then
            C_Timer.After(0.1, function()
                Shadow:ScanForFrames()
                Shadow:UpdateAllShadows()
            end)
        end
    end)
    
    -- Add specialized target frame event handling
    local targetFrame = CreateFrame("Frame")
    targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    targetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    targetFrame:SetScript("OnEvent", function(_, event)
        -- Wait a moment for target frame to be fully updated
        C_Timer.After(0.2, function()
            -- Always try the direct approach first for CUF_Target
            Shadow:ApplyShadowToCUFTarget()
            
            -- Then apply regular shadows
            if CellAdditionsDB.shadowSettings and 
               CellAdditionsDB.shadowSettings.enabled then
                
                ns.Debug("Target changed, applying shadows")
                -- Just scan and update like normal
                Shadow:ScanForFrames()
                Shadow:UpdateAllShadows()
            end
        end)
    end)
    
    -- Add specialized focus frame event handling
    local focusFrame = CreateFrame("Frame")
    focusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    focusFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    focusFrame:SetScript("OnEvent", function(self, event)
        -- Wait a moment for focus frame to be fully updated
        C_Timer.After(0.2, function()
            -- Always try the direct approach first for CUF_Focus
            Shadow:ApplyShadowToCUFFocus()
            
            -- Then apply regular shadows if needed
            if CellAdditionsDB.shadowSettings and 
               CellAdditionsDB.shadowSettings.enabled then
                
                ns.Debug("Focus changed, applying shadows")
                -- Just scan and update like normal
                Shadow:ScanForFrames()
                Shadow:UpdateAllShadows()
            end
        end)
    end)
    
    -- Just do a single initial apply after a delay
    C_Timer.After(1, function()
        -- Apply all shadows once at startup
        if CellAdditionsDB.shadowSettings and 
           CellAdditionsDB.shadowSettings.enabled then
            
            ns.Debug("Initial apply of all shadows")
            Shadow:ScanForFrames()
            Shadow:UpdateAllShadows()
        end
    end)
    
    ns.Debug("Shadow module initialized")
end

-- Create settings UI
function Shadow:CreateSettings(parent)
    if not parent then
        ns.Debug("ERROR: No parent frame provided for Shadow settings")
        return
    end

    ns.Debug("Creating Shadow settings panel")
    
    -- Initialize settings if needed
    local settings = InitSettings()
    
    -- Create main container with dark background
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    container:SetFrameLevel(parent:GetFrameLevel() + 1)
    
    -- Get accent color
    local accentColor = Cell.GetAccentColorTable()
    
    -- Enable Shadow checkbox (placed directly at the top, no separator)
    local enableShadowCB = Cell.CreateCheckButton(container, "Enable Shadow", function(checked)
        settings.enabled = checked
        ns.Debug("Shadow enabled: " .. tostring(checked))
        ApplyShadows()
    end)
    enableShadowCB:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -10)
    enableShadowCB:SetChecked(settings.enabled)
    
    -- Shadow Settings text
    local shadowSettingsText = container:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    shadowSettingsText:SetPoint("TOPLEFT", enableShadowCB, "BOTTOMLEFT", 0, -12)
    shadowSettingsText:SetText("Shadow Settings")
    
    -- Shadow size text
    local shadowSizeText = container:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    shadowSizeText:SetPoint("TOPLEFT", shadowSettingsText, "BOTTOMLEFT", 10, -8)
    shadowSizeText:SetText("Shadow Size")
    
    -- Shadow size slider
    local shadowSizeSlider = Cell.CreateSlider("", container, 1, 15, 120, 1)
    shadowSizeSlider:SetPoint("TOPLEFT", shadowSizeText, "BOTTOMLEFT", 0, -8)
    shadowSizeSlider:SetLabel("")
    shadowSizeSlider:SetValue(settings.shadowSize)
    
    -- Current value display box
    local valueBox = CreateFrame("Frame", nil, container, "BackdropTemplate")
    Cell.StylizeFrame(valueBox, {0.15, 0.15, 0.15, 1}, {0, 0, 0, 0})
    valueBox:SetSize(40, 25)
    valueBox:SetPoint("LEFT", shadowSizeSlider, "RIGHT", 10, 0)
    
    local valueText = valueBox:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    valueText:SetPoint("CENTER", valueBox, "CENTER")
    valueText:SetText(settings.shadowSize)
    
    shadowSizeSlider.afterValueChangedFn = function(value)
        settings.shadowSize = value
        valueText:SetText(value)
        ns.Debug("Shadow size set to: " .. value)
        ApplyShadows()
    end
    
    -- Cell section with separator
    local cellSeparator = Cell.CreateSeparator("Cell", container)
    cellSeparator:SetPoint("TOPLEFT", shadowSizeSlider, "BOTTOMLEFT", -10, -25)
    
    -- Solo Frame checkbox (added as requested)
    local soloFrameCB = Cell.CreateCheckButton(container, "Solo Frame", function(checked)
        if not settings.unitFrames then settings.unitFrames = {} end
        if not settings.unitFrames.Solo then settings.unitFrames.Solo = {} end
        settings.unitFrames.Solo.enabled = checked
        ns.Debug("Solo frame shadows: " .. tostring(checked))
        ApplyShadows()
    end)
    soloFrameCB:SetPoint("TOPLEFT", cellSeparator, "BOTTOMLEFT", 10, -10)
    soloFrameCB:SetChecked(settings.unitFrames and settings.unitFrames.Solo and settings.unitFrames.Solo.enabled)
    
    -- Solo Frame color swatch
    local soloColorSwatch = Cell.CreateColorPicker(container, "", true, function(r, g, b, a)
        if not settings.unitFrames then settings.unitFrames = {} end
        if not settings.unitFrames.Solo then 
            settings.unitFrames.Solo = {
                healthColor = {r, g, b, a},
                powerColor = {r, g, b, a}
            }
        else
            settings.unitFrames.Solo.healthColor = {r, g, b, a}
        end
        ns.Debug("Solo frame color changed")
        ApplyShadows()
    end)
    soloColorSwatch:SetPoint("RIGHT", container, "RIGHT", -10, 0)
    soloColorSwatch:SetPoint("TOP", soloFrameCB, "TOP", 0, 0)
    
    -- Set initial color
    if settings.unitFrames and settings.unitFrames.Solo and settings.unitFrames.Solo.healthColor then
        soloColorSwatch:SetColor(
            settings.unitFrames.Solo.healthColor[1],
            settings.unitFrames.Solo.healthColor[2],
            settings.unitFrames.Solo.healthColor[3],
            settings.unitFrames.Solo.healthColor[4]
        )
    else
        soloColorSwatch:SetColor(0.7, 0.9, 0.3, 1) -- Default green color
    end
    
    -- Party Frames checkbox
    local partyFramesCB = Cell.CreateCheckButton(container, "Party Frames", function(checked)
        settings.partyFrames = checked
        ns.Debug("Party frames shadows: " .. tostring(checked))
        ApplyShadows()
    end)
    partyFramesCB:SetPoint("TOPLEFT", soloFrameCB, "BOTTOMLEFT", 0, -8)
    partyFramesCB:SetChecked(settings.partyFrames)
    
    -- Party frames color swatch
    local partyColorSwatch = Cell.CreateColorPicker(container, "", true, function(r, g, b, a)
        -- Store the party frame color changes here
        settings.partyHealthColor = {r, g, b, a}
        ns.Debug("Party frame color changed")
        ApplyShadows()
    end)
    partyColorSwatch:SetPoint("RIGHT", container, "RIGHT", -10, 0)
    partyColorSwatch:SetPoint("TOP", partyFramesCB, "TOP", 0, 0)
    partyColorSwatch:SetColor(0.7, 0.9, 0.3, 1) -- Lime green
    
    -- Raid Frames checkbox
    local raidFramesCB = Cell.CreateCheckButton(container, "Raid Frames", function(checked)
        settings.raidFrames = checked
        ns.Debug("Raid frames shadows: " .. tostring(checked))
        ApplyShadows()
    end)
    raidFramesCB:SetPoint("TOPLEFT", partyFramesCB, "BOTTOMLEFT", 0, -8)
    raidFramesCB:SetChecked(settings.raidFrames)
    
    -- Raid frames color swatch
    local raidColorSwatch = Cell.CreateColorPicker(container, "", true, function(r, g, b, a)
        -- Store the raid frame color changes here
        settings.raidHealthColor = {r, g, b, a}
        ns.Debug("Raid frame color changed")
        ApplyShadows()
    end)
    raidColorSwatch:SetPoint("RIGHT", container, "RIGHT", -10, 0)
    raidColorSwatch:SetPoint("TOP", raidFramesCB, "TOP", 0, 0)
    raidColorSwatch:SetColor(0.9, 0.7, 0.3, 1) -- Orange
    
    -- Cell - Unit Frames section with separator
    local unitFramesSeparator = Cell.CreateSeparator("Cell - Unit Frames", container)
    unitFramesSeparator:SetPoint("TOPLEFT", raidFramesCB, "BOTTOMLEFT", -10, -25)
    
    -- Create column headers for HB and PB
    local hbLabel = container:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    hbLabel:SetPoint("TOPRIGHT", container, "TOPRIGHT", -45, 0)
    hbLabel:SetPoint("TOP", unitFramesSeparator, "BOTTOM", 0, -12)
    hbLabel:SetText("HB")
    
    local pbLabel = container:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
    pbLabel:SetPoint("TOPRIGHT", container, "TOPRIGHT", -15, 0)
    pbLabel:SetPoint("TOP", unitFramesSeparator, "BOTTOM", 0, -12)
    pbLabel:SetText("PB")
    
    -- Unit frames definitions
    local unitFrames = {
        { name = "Player", key = "Player" },
        { name = "Target", key = "Target" },
        { name = "Target's Target", key = "TargetTarget" },
        { name = "Focus", key = "Focus" },
        { name = "Pet", key = "Pet" }
    }
    
    -- Create unit frame checkboxes and color swatches
    local prevElement
    
    for i, unit in ipairs(unitFrames) do
        local unitSettings = settings.unitFrames[unit.key]
        
        -- Unit frame checkbox
        local unitCB = Cell.CreateCheckButton(container, unit.name, function(checked)
            unitSettings.enabled = checked
            ns.Debug(unit.name .. " frame shadows: " .. tostring(checked))
            
            -- For target frame, add special handling to force-find frames
            if unit.key == "Target" and checked then
                ns.Debug("Performing enhanced target frame detection...")
                
                -- Check all possible frame names
                local targetFrameNames = {
                    "TargetFrame",
                    "CellUnitFrameTarget", 
                    "CellTargetFrame",
                    "TargetFrameHealthBar",
                    "CellUnitButton_target"
                }
                
                for _, name in ipairs(targetFrameNames) do
                    local frame = _G[name]
                    if frame then
                        ns.Debug("Found target frame: " .. name)
                        if not Shadow.frameRegistry[frame] then
                            CreateShadow(frame, "Target")
                        end
                    end
                end
            end
            
            ApplyShadows()
        end)
        
        if i == 1 then
            -- First unit frame has more space below the column headers
            unitCB:SetPoint("TOPLEFT", unitFramesSeparator, "BOTTOMLEFT", 10, -30)
        else
            -- More space between unit frame checkboxes
            unitCB:SetPoint("TOPLEFT", prevElement, "BOTTOMLEFT", 0, -8)
        end
        unitCB:SetChecked(unitSettings.enabled)
        
        -- Health bar color swatch (HB)
        local healthColor = unitSettings.healthColor
        local healthSwatch = Cell.CreateColorPicker(container, "", true, function(r, g, b, a)
            -- Store the unit frame health bar color changes here
            unitSettings.healthColor[1] = r
            unitSettings.healthColor[2] = g
            unitSettings.healthColor[3] = b
            unitSettings.healthColor[4] = a
            ns.Debug(unit.key .. " health bar color changed")
            
            -- Special handling for Target frame colors
            if unit.key == "Target" then
                Shadow:ApplyShadowToCUFTarget()
            end
            
            -- Update all shadows
            ApplyShadows()
        end)
        healthSwatch:SetPoint("TOP", unitCB, "TOP", 0, 0)
        healthSwatch:SetPoint("RIGHT", hbLabel, "RIGHT", 0, 0)
        healthSwatch:SetColor(healthColor[1], healthColor[2], healthColor[3], healthColor[4])
        
        -- Power bar color swatch (PB)
        local powerColor = unitSettings.powerColor
        local powerSwatch = Cell.CreateColorPicker(container, "", true, function(r, g, b, a)
            -- Store the unit frame power bar color changes here
            unitSettings.powerColor[1] = r
            unitSettings.powerColor[2] = g
            unitSettings.powerColor[3] = b
            unitSettings.powerColor[4] = a
            ns.Debug(unit.key .. " power bar color changed")
            ApplyShadows()
        end)
        powerSwatch:SetPoint("TOP", unitCB, "TOP", 0, 0)
        powerSwatch:SetPoint("RIGHT", pbLabel, "RIGHT", 0, 0)
        powerSwatch:SetColor(powerColor[1], powerColor[2], powerColor[3], powerColor[4])
        
        prevElement = unitCB
    end
    
    -- Store frames for reference
    Shadow.frames = {
        container = container,
        enableShadowCB = enableShadowCB,
        shadowSizeSlider = shadowSizeSlider
    }
    
    return container
end

-- Toggle module enabled/disabled state
function Shadow:SetEnabled(enabled)
    if CellAdditionsDB and CellAdditionsDB.shadowSettings then
        CellAdditionsDB.shadowSettings.enabled = enabled
        
        -- Update UI if available
        if Shadow.frames and Shadow.frames.enableShadowCB then
            Shadow.frames.enableShadowCB:SetChecked(enabled)
        end
        
        ApplyShadows()
    end
end

-- Register the module
ns.RegisterModule(Shadow) 