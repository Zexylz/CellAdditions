local addonName, ns = ...
local Cell = ns.Cell

-- Create a EnhancedShadow module namespace
local EnhancedShadow = {}
ns.EnhancedShadow = EnhancedShadow

-- Module settings
EnhancedShadow.name = "Enhanced Shadow"
EnhancedShadow.id = "EnhancedShadow"
EnhancedShadow.description = "Enhanced shadow effects for frames"

-- ShadowNewManager for internal use
local ShadowNewManager = {
	frameCache = {},
	settings = {},
	defaults = {
		size = 4,
		color = { r = 0, g = 0, b = 0, a = 1 },
		barTypes = {
			healthBar = true,
			powerBar = true,
		},
	},
	updateThrottle = 0.1,
	lastUpdate = 0,
}

-- Frame detection patterns
local framePatterns = {
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
		"CellRaidFrameHeader%d", -- Updated pattern to match actual frame names
	},
}

-- Initialize settings
function ShadowNewManager:InitializeSettings()
	-- Initialize DB if it doesn't exist
	CellAdditionsDB = CellAdditionsDB or {}
	
	-- Make sure the shadow_new_enabled flag is initialized
	if CellAdditionsDB.shadow_new_enabled == nil then
		CellAdditionsDB.shadow_new_enabled = true
	end

	-- Shadow settings with namespaced keys
	CellAdditionsDB.shadow_new_shadowSize = CellAdditionsDB.shadow_new_shadowSize or self.defaults.size
	
	-- Initialize frame-specific colors
	if not CellAdditionsDB.shadow_new_frameColors then
		CellAdditionsDB.shadow_new_frameColors = {}
	end
	
	-- Initialize colors for each frame type
	local frameTypes = {
		"Solo", 
		"Party", 
		"Raid", 
		"Target",
		"TargetTarget", 
		"Pet", 
		"Focus",
		"HealthBar",
		"PowerBar",
		"TargetPower",
		"TargetTargetPower",
		"FocusPower",
		"PetPower",
		"CUF_Player",
		"CUF_Player_Power"
	}
	
	for _, frameType in ipairs(frameTypes) do
		if not CellAdditionsDB.shadow_new_frameColors[frameType] then
			CellAdditionsDB.shadow_new_frameColors[frameType] = {
				r = self.defaults.color.r,
				g = self.defaults.color.g,
				b = self.defaults.color.b,
				a = self.defaults.color.a,
			}
		end
	end

	-- Initialize bar settings
	if not CellAdditionsDB.shadow_new_shadowBars then
		CellAdditionsDB.shadow_new_shadowBars = {
			healthBar = false,
			powerBar = false,
		}
	end

	-- Frame type settings
	if CellAdditionsDB.shadow_new_useStandaloneCellShadow == nil then
		CellAdditionsDB.shadow_new_useStandaloneCellShadow = false
	end

	if CellAdditionsDB.shadow_new_usePartyButtonShadow == nil then
		CellAdditionsDB.shadow_new_usePartyButtonShadow = false
	end

	if CellAdditionsDB.shadow_new_useRaidButtonShadow == nil then
		CellAdditionsDB.shadow_new_useRaidButtonShadow = false
	end
	
	-- CUF Player frame setting
	if CellAdditionsDB.shadow_new_useCUFPlayerShadow == nil then
		CellAdditionsDB.shadow_new_useCUFPlayerShadow = false
	end
	
	-- Solo frame setting (separate from Player Frame)
	if CellAdditionsDB.shadow_new_useCellSoloFrameShadow == nil then
		CellAdditionsDB.shadow_new_useCellSoloFrameShadow = false
	end
	
	-- Target frame settings
	if CellAdditionsDB.shadow_new_useTargetFrameShadow == nil then
		CellAdditionsDB.shadow_new_useTargetFrameShadow = false
	end
	
	-- CUF_TargetTarget setting
	if CellAdditionsDB.shadow_new_useCUFTargetTargetShadow == nil then
		CellAdditionsDB.shadow_new_useCUFTargetTargetShadow = false
	end
	
	-- CUF_Pet setting
	if CellAdditionsDB.shadow_new_useCUFPetShadow == nil then
		CellAdditionsDB.shadow_new_useCUFPetShadow = false
	end
	
	-- CUF_Focus setting
	if CellAdditionsDB.shadow_new_useCUFFocusShadow == nil then
		CellAdditionsDB.shadow_new_useCUFFocusShadow = false
	end

	-- Initialize advanced settings
	if CellAdditionsDB.shadow_new_shadowQuality == nil then
		CellAdditionsDB.shadow_new_shadowQuality = 3
	end

	if CellAdditionsDB.shadow_new_shadowOffsetX == nil then
		CellAdditionsDB.shadow_new_shadowOffsetX = 0
	end

	if CellAdditionsDB.shadow_new_shadowOffsetY == nil then
		CellAdditionsDB.shadow_new_shadowOffsetY = 0
	end

	-- Store settings reference and ensure they're synced
	self.settings = CellAdditionsDB

	-- Sync settings to the shadow manager
	self:SyncSettings()
	
	ns.Debug("EnhancedShadow settings initialized")
end

-- Make sure settings are synced
function ShadowNewManager:SyncSettings()
	self.settings.shadow_new_shadowSize = CellAdditionsDB.shadow_new_shadowSize
	self.settings.shadow_new_shadowBars = CellAdditionsDB.shadow_new_shadowBars
	self.settings.shadow_new_useStandaloneCellShadow = CellAdditionsDB.shadow_new_useStandaloneCellShadow
	self.settings.shadow_new_usePartyButtonShadow = CellAdditionsDB.shadow_new_usePartyButtonShadow
	self.settings.shadow_new_useRaidButtonShadow = CellAdditionsDB.shadow_new_useRaidButtonShadow
	self.settings.shadow_new_useCellSoloFrameShadow = CellAdditionsDB.shadow_new_useCellSoloFrameShadow
	self.settings.shadow_new_useCUFPlayerShadow = CellAdditionsDB.shadow_new_useCUFPlayerShadow
	self.settings.shadow_new_useCUFTargetTargetShadow = CellAdditionsDB.shadow_new_useCUFTargetTargetShadow
	self.settings.shadow_new_useCUFPetShadow = CellAdditionsDB.shadow_new_useCUFPetShadow
	self.settings.shadow_new_useCUFFocusShadow = CellAdditionsDB.shadow_new_useCUFFocusShadow
	self.settings.shadow_new_frameColors = CellAdditionsDB.shadow_new_frameColors
	
	-- Update frame-specific color pickers if they exist
	for frameType, colorPicker in pairs(self.frameColorPickers or {}) do
		if colorPicker and colorPicker.SetColor and CellAdditionsDB.shadow_new_frameColors[frameType] then
			-- Force the color picker to be visible
			if colorPicker.Show then
				colorPicker:Show()
			end
			
			-- Make sure the color is properly set
			colorPicker:SetColor(
				CellAdditionsDB.shadow_new_frameColors[frameType].r,
				CellAdditionsDB.shadow_new_frameColors[frameType].g,
				CellAdditionsDB.shadow_new_frameColors[frameType].b,
				CellAdditionsDB.shadow_new_frameColors[frameType].a
			)
			
			-- Debug the color being set
			ns.Debug("Set color for " .. frameType .. ": " .. 
				CellAdditionsDB.shadow_new_frameColors[frameType].r .. ", " .. 
				CellAdditionsDB.shadow_new_frameColors[frameType].g .. ", " .. 
				CellAdditionsDB.shadow_new_frameColors[frameType].b .. ", " .. 
				CellAdditionsDB.shadow_new_frameColors[frameType].a)
		end
	end

	ns.Debug("ShadowNew settings synced")
end

-- Function to check if a frame is actually visible
local function IsFrameActuallyVisible(frame)
	if not frame then
		return false
	end

	-- Get the frame name
	local name = frame:GetName()
	if not name then
		return false
	end

	-- Basic visibility check first
	if not frame:IsVisible() or frame:GetAlpha() <= 0 then
		return false
	end

	-- Check frame type and handle accordingly
	if name:match("CellRaidFrameHeader%dUnitButton%d") then
		-- For raid unit buttons, check if they have a unit assigned
		if frame.unit or (frame.state and frame.state.unit) then
			return true
		end
		return false
	elseif
		name:match("CellPartyFrameHeaderUnitButton%d")
		or name:match("CellSoloFramePlayer")
		or name:match("CellSoloFrame")
		or name:match("Cell_SoloFrame")
	then
		-- For party and solo frames, just check if they're visible and have content
		return true
	end

	-- For any other frames, use basic visibility check
	return true
end

-- Function to check if a frame type is enabled in Cell Unit Frames
local function IsFrameTypeEnabled(frameType)
	-- Direct message to chat
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] Checking if " .. frameType .. " frame is enabled (ShadowNew)", 1, 1, 0)
	end
	
	-- Default to enabled
	local isEnabled = true
	
	-- Map frameType to unit key in CUF_DB
	local unitKey = nil
	if frameType == "TargetTarget" then unitKey = "targettarget"
	elseif frameType == "Pet" then unitKey = "pet"
	elseif frameType == "Focus" then unitKey = "focus"
	elseif frameType == "Party" then unitKey = "party"
	elseif frameType == "Raid" then unitKey = "raid"
	elseif frameType == "Solo" then unitKey = "player" end
	
	-- Check EXACTLY like Cell_UnitFrames does in UpdateUnitFrameVisibility
	if _G.CUF and _G.CUF.DB and unitKey then
		-- Log whether CUF.DB.CurrentLayoutTable() exists
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] CUF.DB.CurrentLayoutTable() exists: " .. 
				(CUF.DB.CurrentLayoutTable() and "YES" or "NO") .. " (ShadowNew)", 1, 1, 0)
		end
		
		-- Log whether unitKey exists in the table
		if CUF.DB.CurrentLayoutTable() then
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] CUF.DB.CurrentLayoutTable()[" .. unitKey .. "] exists: " .. 
					(CUF.DB.CurrentLayoutTable()[unitKey] and "YES" or "NO") .. " (ShadowNew)", 1, 1, 0)
			end
		end
		
		-- This is the exact check from the screenshot
		if CUF.DB.CurrentLayoutTable()[unitKey] then
			-- Log the actual enabled value
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] CUF.DB.CurrentLayoutTable()[" .. unitKey .. "].enabled = " .. 
					(CUF.DB.CurrentLayoutTable()[unitKey].enabled == nil and "nil" or 
					tostring(CUF.DB.CurrentLayoutTable()[unitKey].enabled)) .. " (ShadowNew)", 1, 1, 0)
			end
			
			if CUF.DB.CurrentLayoutTable()[unitKey].enabled ~= nil then
				isEnabled = CUF.DB.CurrentLayoutTable()[unitKey].enabled
				
				-- Direct message to chat
				if DEFAULT_CHAT_FRAME then
					DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] " .. frameType .. " frame is " .. 
						(isEnabled and "ENABLED" or "DISABLED") .. " in CUF.DB.CurrentLayoutTable (ShadowNew)", 
						isEnabled and 0 or 1, isEnabled and 1 or 0, 0)
				end
			end
		end
	end
	
	-- Also check if the frame actually exists and is visible
	local frameNames = {}
	if frameType == "Pet" then
		frameNames = {"CellPetFrame", "PetFrame", "Cell_PetFrame", "CellPetFrameUnitButton1", "CUF_Pet_HealthBar"}
		-- Also check if player has a pet
		if UnitExists("pet") then
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] Player has an active pet (ShadowNew)", 0, 1, 0)
			end
		end
	elseif frameType == "TargetTarget" then
		frameNames = {"CellTargetTargetFrame", "TargetTargetFrame", "Cell_TargetTargetFrame", "CellTargetTargetFrameUnitButton1", "CUF_TargetTarget_HealthBar"}
		-- Also check if player has a target of target
		if UnitExists("targettarget") then
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] Player has a target's target (ShadowNew)", 0, 1, 0)
			end
		end
	elseif frameType == "Focus" then
		frameNames = {"CellFocusFrame", "FocusFrame", "Cell_FocusFrame", "CellFocusFrameUnitButton1", "CUF_Focus_HealthBar"}
		-- Also check if player has a focus target
		if UnitExists("focus") then
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] Player has a focus target (ShadowNew)", 0, 1, 0)
			end
		end
	end
	
	-- Check if any of the frames exist and are visible
	for _, frameName in ipairs(frameNames) do
		local frame = _G[frameName]
		if frame and IsFrameActuallyVisible(frame) then
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions] Found visible " .. frameType .. " frame: " .. frameName .. " (ShadowNew)", 0, 1, 0)
			end
		end
	end
	
	return isEnabled
end

-- Constants
local SLIDER_MIN = 0
local SLIDER_MAX = 10
local SLIDER_STEP = 1
local DEFAULT_SHADOW_SIZE = 4
local glowTex = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga"

-- Create shadow function
local function CreateShadowNew(frame, frameType)
	-- If the frame already has a shadow_new, remove it first so we can update the color
	if frame and frame.shadow_new then
		frame.shadow_new:Hide()
		frame.shadow_new = nil
	end

	if not frame or not frame.SetPoint then
		return
	end

	-- CRITICAL SAFETY CHECK - Prevent target frame toggle from affecting player frames
	if frameType == "Target" and frame:GetName() and frame:GetName():find("CUF_Player") then
		ns.Debug("PROTECTION: Prevented Target shadow from being applied to " .. frame:GetName())
		return nil
	end

	local size = CellAdditionsDB.shadow_new_shadowSize or DEFAULT_SHADOW_SIZE
    
	-- If size is 0, don't create any shadow
	if size == 0 then
		return nil
	end

	local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")

	shadow:SetFrameLevel(frame:GetFrameLevel() - 1)
	shadow:SetPoint("TOPLEFT", -size, size)
	shadow:SetPoint("BOTTOMRIGHT", size, -size)

	shadow:SetBackdrop({
		edgeFile = glowTex,
		edgeSize = size,
		insets = { left = size, right = size, top = size, bottom = size },
	})

	shadow:SetBackdropColor(0, 0, 0, 0)
	
	-- Determine which color to use
	local color = nil
	
	-- Debug the frame type and color being used
	ns.Debug("Creating shadow_new for frame type: " .. (frameType or "nil") .. " on frame: " .. (frame:GetName() or "unnamed"))
	
	-- Use frame-specific color if it exists
	if frameType and CellAdditionsDB.shadow_new_frameColors and CellAdditionsDB.shadow_new_frameColors[frameType] then
		color = CellAdditionsDB.shadow_new_frameColors[frameType]
		ns.Debug("Using color for " .. frameType .. ": " .. 
			CellAdditionsDB.shadow_new_frameColors[frameType].r .. ", " .. 
			CellAdditionsDB.shadow_new_frameColors[frameType].g .. ", " .. 
			CellAdditionsDB.shadow_new_frameColors[frameType].b .. ", " .. 
			CellAdditionsDB.shadow_new_frameColors[frameType].a)
	-- Fall back to default black color if no frame-specific color exists
	else
		color = {r = 0, g = 0, b = 0, a = 1}
		ns.Debug("Using default black color")
	end
	
	-- Ensure we have a valid color with all components
	if not color then color = {r = 0, g = 0, b = 0, a = 1} end
	if not color.r then color.r = 0 end
	if not color.g then color.g = 0 end
	if not color.b then color.b = 0 end
	if not color.a then color.a = 1 end
	
	shadow:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
	
	-- Store the frame type with the shadow for later updates
	shadow.frameType = frameType
	
	frame.shadow_new = shadow
	return shadow
end

-- Add helper function to remove shadows
local function RemoveShadowNew(frame)
	if frame and frame.shadow_new then
		frame.shadow_new:Hide()
		frame.shadow_new = nil
	end
	
	-- Also clean up bar shadows if they exist
	if frame and frame.barShadows_new then
		for _, shadow in pairs(frame.barShadows_new) do
			if shadow then
				shadow:Hide()
				shadow = nil
			end
		end
		frame.barShadows_new = {}
	end
end

-- Add function to clean up all raid frame shadows
local function CleanupAllRaidShadowsNew()
	-- Clean up numbered raid frames and their unit buttons
	for i = 1, 8 do
		for j = 1, 5 do
			local frameName = "CellRaidFrameHeader" .. i .. "UnitButton" .. j
			local frame = _G[frameName]
			if frame then
				RemoveShadowNew(frame)
			end
		end
	end

	-- Clean up through Cell.frames
	if Cell and Cell.frames then
		for name, frame in pairs(Cell.frames) do
			if name:match("CellRaidFrameHeader%dUnitButton%d") then
				RemoveShadowNew(frame)
			elseif name == "CellSoloFramePlayer" and not CellAdditionsDB.shadow_new_useStandaloneCellShadow then
				-- Clean up solo frame shadow if the toggle is off
				RemoveShadowNew(frame)
			end
		end
	end
	
	-- Also check for direct solo frame
	local soloFrame = _G["CellSoloFramePlayer"]
	if soloFrame and not CellAdditionsDB.shadow_new_useStandaloneCellShadow then
		RemoveShadowNew(soloFrame)
	end
end

-- Helper function to map frame types to color keys
local function GetColorKeyForFrameType(frameType)
	-- Map lowercase frame types to proper case for color keys
	local colorKeyMap = {
		solo = "Solo",
		party = "Party",
		raid = "Raid",
		targettarget = "TargetTarget",
		pet = "Pet",
		focus = "Focus"
	}
	
	return colorKeyMap[frameType] or frameType
end

-- Frame scanning and caching
function ShadowNewManager:ScanForFrames()
	-- Clean up all existing shadows first
	CleanupAllRaidShadowsNew()

	-- Clear existing cache
	self.frameCache = {}

	-- Check for Cell solo frame (CellSoloFramePlayer)
	local cellSoloFrame = _G["CellSoloFramePlayer"]
	if cellSoloFrame and IsFrameActuallyVisible(cellSoloFrame) then
		-- Only add to frameCache if the toggle is enabled
		if self.settings.shadow_new_useStandaloneCellShadow then
			self.frameCache[cellSoloFrame] = "Solo"
			ns.Debug("ShadowNew: Found CellSoloFramePlayer (Cell solo frame)")
		else
			-- Remove any existing shadow if the toggle is off
			RemoveShadowNew(cellSoloFrame)
			ns.Debug("ShadowNew: Found CellSoloFramePlayer but toggle is off, removed shadow")
		end
	end
	
	-- Check for Cell Unit Frames player frame (CUF_Player)
	local cufPlayerFrame = _G["CUF_Player"]
	if cufPlayerFrame and IsFrameActuallyVisible(cufPlayerFrame) then
		self.frameCache[cufPlayerFrame] = "CUF_Player"
		ns.Debug("ShadowNew: Found CUF_Player (Cell Unit Frames player frame)")
	end
	
	-- Check for CUF Target frame (CUF_Target)
	local cufTargetFrame = _G["CUF_Target"]
	if cufTargetFrame and IsFrameActuallyVisible(cufTargetFrame) then
		self.frameCache[cufTargetFrame] = "Target"
		ns.Debug("ShadowNew: Found CUF_Target (Cell Unit Frames target frame)")
	end
	
	-- Check for CUF Target's health bar
	local cufTargetHealthBar = _G["CUF_Target_HealthBar"]
	if cufTargetHealthBar and IsFrameActuallyVisible(cufTargetHealthBar) then
		self.frameCache[cufTargetHealthBar] = "Target"
		ns.Debug("ShadowNew: Found CUF_Target_HealthBar")
	end
	
	-- Check for CUF Target's power bar
	local cufTargetPowerBar = _G["CUF_Target_PowerBar"]
	if cufTargetPowerBar and IsFrameActuallyVisible(cufTargetPowerBar) then
		self.frameCache[cufTargetPowerBar] = "TargetPower"
		ns.Debug("ShadowNew: Found CUF_Target_PowerBar")
	end
	
	-- Check for CUF player's health bar
	local cufPlayerHealthBar = _G["CUF_Player_HealthBar"]
	if cufPlayerHealthBar and IsFrameActuallyVisible(cufPlayerHealthBar) then
		self.frameCache[cufPlayerHealthBar] = "CUF_Player_HealthBar"
		ns.Debug("ShadowNew: Found CUF_Player_HealthBar")
	end
	
	-- Check for CUF player's power bar
	local cufPlayerPowerBar = _G["CUF_Player_PowerBar"]
	if cufPlayerPowerBar and IsFrameActuallyVisible(cufPlayerPowerBar) then
		self.frameCache[cufPlayerPowerBar] = "CUF_Player_PowerBar"
		ns.Debug("ShadowNew: Found CUF_Player_PowerBar")
	end
	
	-- Check for solo frames (separate from player frames)
	for _, pattern in ipairs({ "CellSoloFrame", "Cell_SoloFrame" }) do
		local frame = _G[pattern]
		if frame and IsFrameActuallyVisible(frame) then
			self.frameCache[frame] = "Solo"
			ns.Debug("ShadowNew: Found Solo frame: " .. pattern)
		end
	end
	
	-- Check for focus frame
	local focusFrame = _G["CellFocusFrame"]
	if focusFrame and IsFrameActuallyVisible(focusFrame) then
		self.frameCache[focusFrame] = "Focus"
		ns.Debug("ShadowNew: Found CellFocusFrame")
	end
	
	-- Try alternative focus frame names
	for _, pattern in ipairs({ "FocusFrame", "Cell_FocusFrame", "CellFocusFrameUnitButton1" }) do
		local frame = _G[pattern]
		if frame and IsFrameActuallyVisible(frame) then
			self.frameCache[frame] = "Focus"
			ns.Debug("ShadowNew: Found alternative focus frame: " .. pattern)
		end
	end

	-- Check for party frames
	for i = 1, 5 do
		local frameName = "CellPartyFrameHeaderUnitButton" .. i
		local frame = _G[frameName]
		if frame and IsFrameActuallyVisible(frame) then
			self.frameCache[frame] = "Party"
		end
	end

	-- Check for raid unit buttons
	for i = 1, 8 do -- For each header
		for j = 1, 5 do -- For each button in the header
			local frameName = "CellRaidFrameHeader" .. i .. "UnitButton" .. j
			local frame = _G[frameName]
			if frame then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "raid"
				else
					RemoveShadowNew(frame)
				end
			end
		end
	end

	-- Try alternative lookup through Cell.frames
	if Cell and Cell.frames then
		for name, frame in pairs(Cell.frames) do
			if name:match("CellRaidFrameHeader%dUnitButton%d") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "raid"
				else
					RemoveShadowNew(frame)
				end
			elseif name:match("CellPartyFrameHeaderUnitButton%d") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "Party"
				end
			elseif name == "CellSoloFramePlayer" or name:match("^CellSoloFramePlayer$") then
				-- Make sure the solo frame toggle is enabled before adding to cache
				if IsFrameActuallyVisible(frame) and self.settings.shadow_new_useStandaloneCellShadow then
					self.frameCache[frame] = "Solo"
					ns.Debug("ShadowNew: Found Cell solo frame in Cell.frames: " .. name)
				else
					-- Remove any existing shadow if toggle is off
					RemoveShadowNew(frame)
					ns.Debug("ShadowNew: Found Cell solo frame but toggle is off, removed shadow: " .. name)
				end
			elseif name == "CUF_Player" or name:match("CUF_Player$") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "CUF_Player"
					ns.Debug("ShadowNew: Found CUF player frame in Cell.frames: " .. name)
				end
			elseif name == "CUF_Target" or name:match("CUF_Target$") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "Target"
					ns.Debug("ShadowNew: Found CUF target frame in Cell.frames: " .. name)
				end
			elseif name == "CUF_Target_HealthBar" or name:match("CUF_Target_HealthBar$") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "Target"
					ns.Debug("ShadowNew: Found CUF target health bar in Cell.frames: " .. name)
				end
			elseif name == "CUF_Target_PowerBar" or name:match("CUF_Target_PowerBar$") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "TargetPower"
					ns.Debug("ShadowNew: Found CUF target power bar in Cell.frames: " .. name)
				end
			elseif name == "CUF_Player_HealthBar" or name:match("CUF_Player_HealthBar$") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "CUF_Player_HealthBar"
					ns.Debug("ShadowNew: Found CUF player health bar in Cell.frames: " .. name)
				end
			elseif name == "CUF_Player_PowerBar" or name:match("CUF_Player_PowerBar$") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "CUF_Player_PowerBar"
					ns.Debug("ShadowNew: Found CUF player power bar in Cell.frames: " .. name)
				end
			elseif name:match("CellFocusFrame") or name:match("FocusFrame") or name:match("Cell_FocusFrame") then
				if IsFrameActuallyVisible(frame) then
					self.frameCache[frame] = "Focus"
					ns.Debug("ShadowNew: Found focus frame in Cell.frames: " .. name)
				end
			end
		end
	end

	ns.Debug("ShadowNew frame scan complete")
end

-- Add this function to forcefully remove all CUF shadows
local function CleanupAllCUFShadows()
	-- List all possible CUF frame names
	local frameNames = {
		"CUF_Player",
		"CUF_Player_HealthBar",
		"CUF_Player_PowerBar",
		"CUF_Target",
		"CUF_Target_HealthBar",
		"CUF_Target_PowerBar",
		"CUF_TargetTarget",
		"CUF_TargetTarget_HealthBar",
		"CUF_TargetTarget_PowerBar",
		"CUF_Focus",
		"CUF_Focus_HealthBar",
		"CUF_Focus_PowerBar",
		"CUF_Pet",
		"CUF_Pet_HealthBar",
		"CUF_Pet_PowerBar"
	}
	
	-- Forcefully remove shadows from these frames
	for _, name in ipairs(frameNames) do
		local frame = _G[name]
		if frame then
			-- Remove any shadow_new
			if frame.shadow_new then
				frame.shadow_new:Hide()
				frame.shadow_new = nil
				ns.Debug("Removed shadow_new from " .. name)
			end
			
			-- Remove any shadow (regular)
			if frame.shadow then
				frame.shadow:Hide()
				frame.shadow = nil
				ns.Debug("Removed shadow from " .. name)
			end
			
			-- Check for any child frames with shadows
			for _, child in pairs({frame:GetChildren()}) do
				if child.shadow_new then
					child.shadow_new:Hide()
					child.shadow_new = nil
				end
				if child.shadow then
					child.shadow:Hide()
					child.shadow = nil
				end
			end
		end
	end
	
	-- Also try to clean from Cell.frames registry
	if Cell and Cell.frames then
		for name, frame in pairs(Cell.frames) do
			if name:match("CUF_") then
				if frame.shadow_new then
					frame.shadow_new:Hide()
					frame.shadow_new = nil
					ns.Debug("Removed shadow_new from Cell.frames[" .. name .. "]")
				end
				if frame.shadow then
					frame.shadow:Hide()
					frame.shadow = nil
					ns.Debug("Removed shadow from Cell.frames[" .. name .. "]")
				end
			end
		end
	end
	
	print("[CellAdditions] Cleaned up all CUF shadows")
end

-- Modify the ApplyShadowToCUFPlayerFrame function to use the new cleanup
function ShadowNewManager:ApplyShadowToCUFPlayerFrame(frame)
	if not frame or not self.settings.shadow_new_useCUFPlayerShadow then
		return
	end
	
	-- First clean up any existing shadows
	CleanupAllCUFShadows()
	
	-- Then create a new shadow with red color
	CreateShadowNew(frame, "CUF_Player")
end

-- Update all shadows
function ShadowNewManager:UpdateAll()
	-- Clean up all shadows first
	CleanupAllRaidShadowsNew()
	
	-- Also clean up CUF shadows
	CleanupAllCUFShadows()
	
	self:SyncSettings()

	-- Handle CUF bar shadows first and separately
	local cufBars = {
		health = { "CUF_Player_HealthBar", "CUF_Target_HealthBar" },
		power = { "CUF_Player_PowerBar", "CUF_Target_PowerBar" },
	}

	-- First, remove all CUF shadows
	for _, frames in pairs(cufBars) do
		for _, frameName in ipairs(frames) do
			local frame = _G[frameName]
			if frame then
				RemoveShadowNew(frame)
			end
		end
	end

	-- Apply shadows to CUF frames
	if CellAdditionsDB.shadow_new_useCUFPlayerShadow then
		self:ApplyShadowToCUFPlayerFrame(_G["CUF_Player"])
	end
	
	if CellAdditionsDB.shadow_new_useTargetFrameShadow then
		self:ApplyShadowToCUFTargetFrame()
	end
    
    -- Apply shadows to focus frame
    self:ApplyCUFFocusShadow()

	-- Fix: Ensure correct toggle is checked for each frame type
	local frameToggles = {
		["CUF_Player"] = "shadow_new_useCUFPlayerShadow",
		["CUF_Player_HealthBar"] = "shadow_new_useCUFPlayerShadow",
		["CUF_Player_PowerBar"] = "shadow_new_useCUFPlayerShadow",
		["CUF_Target"] = "shadow_new_useTargetFrameShadow",
		["CUF_Target_HealthBar"] = "shadow_new_useTargetFrameShadow",
		["CUF_Target_PowerBar"] = "shadow_new_useTargetFrameShadow",
		["CUF_TargetTarget"] = "shadow_new_useCUFTargetTargetShadow", 
		["CUF_TargetTarget_HealthBar"] = "shadow_new_useCUFTargetTargetShadow",
		["CUF_TargetTarget_PowerBar"] = "shadow_new_useCUFTargetTargetShadow",
	}
	
	-- Update Cell frames - always recreate shadows to ensure color updates
	for frame, frameType in pairs(self.frameCache) do
		-- Skip focus frames as we handled them separately
		if frameType ~= "Focus" then
			-- Always remove existing shadow first
			if frame and frame.shadow_new then
				frame.shadow_new:Hide()
				frame.shadow_new = nil
			end
			
			-- Then apply new shadow if frame is visible
			if IsFrameActuallyVisible(frame) then
				self:ApplyShadow(frame, frameType)
			end
		end
	end

	-- Ensure raid frames are updated
	if CellAdditionsDB.shadow_new_useRaidButtonShadow then
		for i = 1, 8 do -- For each header
			for j = 1, 5 do -- For each button in the header
				local frameName = "CellRaidFrameHeader" .. i .. "UnitButton" .. j
				local frame = _G[frameName]
				if frame then
					if IsFrameActuallyVisible(frame) then
						self:ApplyShadow(frame, "raid")
					else
						RemoveShadowNew(frame)
					end
				end
			end
		end
	else
		-- If raid shadows are disabled, clean them all up
		CleanupAllRaidShadowsNew()
	end
    
    -- Final check specifically for target frames
    -- This ensures target frames always have shadows if enabled
    if CellAdditionsDB.shadow_new_useTargetFrameShadow then
        self:ForceApplyTargetShadows()
    end

	ns.Debug("ShadowNew update complete")
end

-- Create a separate shadow function specifically for bars
function ShadowNewManager:CreateBarShadowNew(frame, barType)
	if not frame or not frame.SetPoint or frame.shadow_new then
		return
	end

	local size = CellAdditionsDB.shadow_new_shadowSize or DEFAULT_SHADOW_SIZE
    
	-- If size is 0, don't create any shadow
	if size == 0 then
		return nil
	end

	local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")

	shadow:SetFrameLevel(frame:GetFrameLevel() - 1)
	shadow:SetPoint("TOPLEFT", -size, size)
	shadow:SetPoint("BOTTOMRIGHT", size, -size)

	shadow:SetBackdrop({
		edgeFile = glowTex,
		edgeSize = size,
		insets = { left = size, right = size, top = size, bottom = size },
	})

	shadow:SetBackdropColor(0, 0, 0, 0)
	
	-- Only use the specific bar color
	local color = nil
	
	-- Use bar-specific color if it exists
	if barType and CellAdditionsDB.shadow_new_frameColors and CellAdditionsDB.shadow_new_frameColors[barType] then
		color = CellAdditionsDB.shadow_new_frameColors[barType]
	else
		color = {r = 0, g = 0, b = 0, a = 1}
	end
	
	-- Ensure we have a valid color with all components
	if not color then color = {r = 0, g = 0, b = 0, a = 1} end
	if not color.r then color.r = 0 end
	if not color.g then color.g = 0 end
	if not color.b then color.b = 0 end
	if not color.a then color.a = 1 end
	
	shadow:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
	
	frame.shadow_new = shadow
	return shadow
end

-- Shadow application functions
function ShadowNewManager:ApplyShadowToStandaloneCellFrame(frame)
	if not frame or not self.settings.shadow_new_useStandaloneCellShadow then
		return
	end

	-- Make sure we're using the correct color
	CreateShadowNew(frame, "Solo")
end

function ShadowNewManager:ApplyShadowToCellSoloFrame(frame)
	if not frame or not self.settings.shadow_new_useStandaloneCellShadow then
		return
	end

	CreateShadowNew(frame, "Solo")
end

function ShadowNewManager:ApplyShadowToCUFPlayerHealthBar(frame)
	if not frame or not self.settings.shadow_new_useCUFPlayerShadow then
		return
	end
	
	CreateShadowNew(frame, "HealthBar")
end

function ShadowNewManager:ApplyShadowToCUFPlayerPowerBar(frame)
	if not frame or not self.settings.shadow_new_useCUFPlayerShadow then
		return
	end
	
	CreateShadowNew(frame, "CUF_Player_Power")
end

function ShadowNewManager:ApplyShadowToPartyButton(frame)
	if not frame or not self.settings.shadow_new_usePartyButtonShadow then
		return
	end

	CreateShadowNew(frame, "Party")
end

function ShadowNewManager:ApplyShadowToRaidButton(frame)
	if not frame or not self.settings.shadow_new_useRaidButtonShadow then
		return
	end

	CreateShadowNew(frame, "Raid")
end

-- Shadow application logic
function ShadowNewManager:ApplyShadow(frame, frameType)
	if not frame then
		return
	end

	if frameType == "Player" then
		self:ApplyShadowToStandaloneCellFrame(frame)
	elseif frameType == "Solo" then
		self:ApplyShadowToCellSoloFrame(frame)
	elseif frameType == "CUF_Player" then
		self:ApplyShadowToCUFPlayerFrame(frame)
	elseif frameType == "CUF_Player_HealthBar" then
		self:ApplyShadowToCUFPlayerHealthBar(frame)
	elseif frameType == "CUF_Player_PowerBar" then
		self:ApplyShadowToCUFPlayerPowerBar(frame)
	elseif frameType == "Target" then
		-- If this is a primary Target frame (not a health/power bar)
		if frame:GetName() and frame:GetName() == "CUF_Target" then
			self:ApplyShadowToCUFTargetFrame()
		else
			self:ApplyShadowToTargetFrame(frame)
		end
	elseif frameType:find("Target") or frameType:find("target") then
		self:ApplyShadowToTargetFrame(frame)
	elseif frameType == "Party" then
		self:ApplyShadowToPartyButton(frame)
	elseif frameType == "Raid" or frameType == "raid" then
		self:ApplyShadowToRaidButton(frame)
	end
end

-- Create settings UI
-- Function to force update all color pickers
local function ForceUpdateAllColorPickers()
	C_Timer.After(0.1, function()
		if not ShadowNewManager.frameColorPickers then return end
		
		for frameType, picker in pairs(ShadowNewManager.frameColorPickers) do
			if picker and picker.SetColor and CellAdditionsDB.shadow_new_frameColors and CellAdditionsDB.shadow_new_frameColors[frameType] then
				local color = CellAdditionsDB.shadow_new_frameColors[frameType]
				-- Force the color picker to update
				picker:SetColor(color.r, color.g, color.b, color.a)
				
				-- Make sure the color picker is visible
				if picker.Show then picker:Show() end
			end
		end
	end)
end

-- Function to hook into a color picker to ensure all pickers update when any one is clicked
local function HookColorPicker(picker)
	if not picker or not picker:GetScript("OnShow") then return end
	
	-- Hook into the OnShow script to force update all color pickers
	picker:HookScript("OnShow", function()
		ForceUpdateAllColorPickers()
	end)
	
	-- Also hook into mouse events
	picker:HookScript("OnMouseDown", function()
		ForceUpdateAllColorPickers()
	end)
end

function EnhancedShadow:CreateSettings(parent, enableCheckbox)
	-- Make sure settings are initialized
	ShadowNewManager:InitializeSettings()

	local content = parent

	-- Set a reasonable height for the content
	content:SetHeight(400)
	
	-- Force update all color pickers when the settings panel is opened
	ForceUpdateAllColorPickers()

	-- Create a title for the shadow settings section
	local settingsTitle = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
	settingsTitle:SetText("Shadow Settings")
	settingsTitle:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -10)

	-- SECTION 1: SHADOW SIZE SLIDER
	-- Create shadow size slider
	local sizeSlider = Cell.CreateSlider("Shadow Size", content, 0, 10, 180, 1)
	sizeSlider:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 5, -20)
	sizeSlider:SetValue(CellAdditionsDB.shadow_new_shadowSize or 4)
	sizeSlider.afterValueChangedFn = function(value)
		-- Store previous enabled settings if we're going from non-zero to zero
		local previousSize = CellAdditionsDB.shadow_new_shadowSize or 4
		local wasEnabled = previousSize > 0
		local nowEnabled = value > 0
        
		-- Update the stored size value
		CellAdditionsDB.shadow_new_shadowSize = value
		ShadowNewManager.settings.shadow_new_shadowSize = value
        
		-- If we're transitioning between enabled/disabled states
		if wasEnabled ~= nowEnabled then
			-- When going from enabled to disabled (size 0), remove all shadows
			if not nowEnabled then
				print("[CellAdditions] Shadow effects temporarily disabled (size = 0)")
				-- Clean up all raid frame shadows
				CleanupAllRaidShadowsNew()
			else
				-- When going from disabled to enabled, update everything to restore shadows
				print("[CellAdditions] Shadow effects enabled (size = " .. value .. ")")
			end
		end
        
		-- Force a complete update of all shadows
		ShadowNewManager:ScanForFrames()
		ShadowNewManager:UpdateAll()
		
		ns.Debug("Shadow size changed to: " .. value)
	end

	-- SECTION 2: CELL FRAMES
	local cellTitle = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
	cellTitle:SetText("Cell")
	cellTitle:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", -5, -20)

	-- Initialize frame color pickers table if not already done
	ShadowNewManager.frameColorPickers = ShadowNewManager.frameColorPickers or {}
	
	-- Party Frames
	local partyFrameCheckbox = Cell.CreateCheckButton(
		content,
		"Party Frames",
		function(checked)
			CellAdditionsDB.shadow_new_usePartyButtonShadow = checked
			ShadowNewManager.settings.shadow_new_usePartyButtonShadow = checked
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	partyFrameCheckbox:SetPoint("TOPLEFT", cellTitle, "BOTTOMLEFT", 0, -10)
	partyFrameCheckbox:SetChecked(CellAdditionsDB.shadow_new_usePartyButtonShadow)
	
	-- Party frame color picker
	local partyColor = CellAdditionsDB.shadow_new_frameColors["Party"]
	local partyColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = partyColor.r, g = partyColor.g, b = partyColor.b, a = partyColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["Party"].r = r
			CellAdditionsDB.shadow_new_frameColors["Party"].g = g
			CellAdditionsDB.shadow_new_frameColors["Party"].b = b
			CellAdditionsDB.shadow_new_frameColors["Party"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	partyColorPicker:SetPoint("RIGHT", content, "RIGHT", -20, 0)
	partyColorPicker:SetPoint("TOP", partyFrameCheckbox, "TOP", 0, 0)
	ShadowNewManager.frameColorPickers["Party"] = partyColorPicker
	HookColorPicker(partyColorPicker)
	
	-- Raid Frame
	local raidFrameCheckbox = Cell.CreateCheckButton(
		content,
		"Raid Frames",
		function(checked)
			CellAdditionsDB.shadow_new_useRaidButtonShadow = checked
			ShadowNewManager.settings.shadow_new_useRaidButtonShadow = checked
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	raidFrameCheckbox:SetPoint("TOPLEFT", partyFrameCheckbox, "BOTTOMLEFT", 0, -10)
	raidFrameCheckbox:SetChecked(CellAdditionsDB.shadow_new_useRaidButtonShadow)
	
	-- Raid frame color picker
	local raidColor = CellAdditionsDB.shadow_new_frameColors["Raid"]
	local raidColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = raidColor.r, g = raidColor.g, b = raidColor.b, a = raidColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["Raid"].r = r
			CellAdditionsDB.shadow_new_frameColors["Raid"].g = g
			CellAdditionsDB.shadow_new_frameColors["Raid"].b = b
			CellAdditionsDB.shadow_new_frameColors["Raid"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	raidColorPicker:SetPoint("RIGHT", content, "RIGHT", -20, 0)
	raidColorPicker:SetPoint("TOP", raidFrameCheckbox, "TOP", 0, 0)
	ShadowNewManager.frameColorPickers["Raid"] = raidColorPicker
	HookColorPicker(raidColorPicker)
	
	-- Solo Frame (moved up to Cell category)
	local soloFrameCheckbox = Cell.CreateCheckButton(
		content,
		"Solo Frame",
		function(checked)
			CellAdditionsDB.shadow_new_useStandaloneCellShadow = checked
			ShadowNewManager.settings.shadow_new_useStandaloneCellShadow = checked
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	soloFrameCheckbox:SetPoint("TOPLEFT", raidFrameCheckbox, "BOTTOMLEFT", 0, -10)
	soloFrameCheckbox:SetChecked(CellAdditionsDB.shadow_new_useStandaloneCellShadow)
	
	-- Solo frame color picker
	local soloColor = CellAdditionsDB.shadow_new_frameColors["Solo"]
	local soloColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = soloColor.r, g = soloColor.g, b = soloColor.b, a = soloColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["Solo"].r = r
			CellAdditionsDB.shadow_new_frameColors["Solo"].g = g
			CellAdditionsDB.shadow_new_frameColors["Solo"].b = b
			CellAdditionsDB.shadow_new_frameColors["Solo"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	soloColorPicker:SetPoint("TOP", soloFrameCheckbox, "TOP", 0, 0)
	soloColorPicker:SetPoint("RIGHT", content, "RIGHT", -20, 0)
	ShadowNewManager.frameColorPickers["Solo"] = soloColorPicker
	HookColorPicker(soloColorPicker)

	-- SECTION 3: CELL - UNIT FRAMES
	local unitFramesTitle = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
	unitFramesTitle:SetText("Cell - Unit Frames")
	unitFramesTitle:SetPoint("TOPLEFT", soloFrameCheckbox, "BOTTOMLEFT", 0, -20)

	-- Add column headers for health bar and power bar
	local hbHeader = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	hbHeader:SetText("HB")
	hbHeader:SetPoint("RIGHT", content, "RIGHT", -60, 0) 
	hbHeader:SetPoint("TOP", unitFramesTitle, "TOP", 0, 0)

	local pbHeader = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	pbHeader:SetText("PB")
	pbHeader:SetPoint("RIGHT", content, "RIGHT", -20, 0)
	pbHeader:SetPoint("TOP", unitFramesTitle, "TOP", 0, 0)

	-- Cell Unit Frames Player Frame
	local cufPlayerFrameCheckbox = Cell.CreateCheckButton(
		content,
		"Cell UF Player",
		function(checked)
			CellAdditionsDB.shadow_new_useCUFPlayerShadow = checked
			ShadowNewManager.settings.shadow_new_useCUFPlayerShadow = checked
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	cufPlayerFrameCheckbox:SetPoint("TOPLEFT", unitFramesTitle, "BOTTOMLEFT", 0, -10)
	cufPlayerFrameCheckbox:SetChecked(CellAdditionsDB.shadow_new_useCUFPlayerShadow or false)
	
	-- CUF Player frame health bar color picker
	if not CellAdditionsDB.shadow_new_frameColors["CUF_Player"] then
		CellAdditionsDB.shadow_new_frameColors["CUF_Player"] = {r = 1.0, g = 0.0, b = 0.0, a = 1.0} -- Red color (was blue)
	end
	local cufPlayerColor = CellAdditionsDB.shadow_new_frameColors["CUF_Player"]
	local cufPlayerColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = cufPlayerColor.r, g = cufPlayerColor.g, b = cufPlayerColor.b, a = cufPlayerColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["CUF_Player"].r = r
			CellAdditionsDB.shadow_new_frameColors["CUF_Player"].g = g
			CellAdditionsDB.shadow_new_frameColors["CUF_Player"].b = b
			CellAdditionsDB.shadow_new_frameColors["CUF_Player"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	cufPlayerColorPicker:SetPoint("TOP", cufPlayerFrameCheckbox, "TOP", 0, 0)
	cufPlayerColorPicker:SetPoint("RIGHT", hbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["CUF_Player"] = cufPlayerColorPicker
	HookColorPicker(cufPlayerColorPicker)
	
	-- CUF Player power bar color picker
	if not CellAdditionsDB.shadow_new_frameColors["CUF_Player_Power"] then
		CellAdditionsDB.shadow_new_frameColors["CUF_Player_Power"] = {r = 0.0, g = 0.4, b = 0.8, a = 1.0} -- Darker blue
	end
	local cufPlayerPowerColor = CellAdditionsDB.shadow_new_frameColors["CUF_Player_Power"]
	local cufPlayerPowerColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = cufPlayerPowerColor.r, g = cufPlayerPowerColor.g, b = cufPlayerPowerColor.b, a = cufPlayerPowerColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["CUF_Player_Power"].r = r
			CellAdditionsDB.shadow_new_frameColors["CUF_Player_Power"].g = g
			CellAdditionsDB.shadow_new_frameColors["CUF_Player_Power"].b = b
			CellAdditionsDB.shadow_new_frameColors["CUF_Player_Power"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	cufPlayerPowerColorPicker:SetPoint("TOP", cufPlayerFrameCheckbox, "TOP", 0, 0)
	cufPlayerPowerColorPicker:SetPoint("RIGHT", pbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["CUF_Player_Power"] = cufPlayerPowerColorPicker
	HookColorPicker(cufPlayerPowerColorPicker)
	
	-- Target Frame checkbox
	local targetFrameCheckbox = Cell.CreateCheckButton(
		content,
		"Target Frame",
		function(checked)
			-- We need to add this setting
			CellAdditionsDB.shadow_new_useTargetFrameShadow = checked
			ShadowNewManager.settings.shadow_new_useTargetFrameShadow = checked
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	targetFrameCheckbox:SetPoint("TOPLEFT", cufPlayerFrameCheckbox, "BOTTOMLEFT", 0, -10)
	targetFrameCheckbox:SetChecked(CellAdditionsDB.shadow_new_useTargetFrameShadow)
	
	-- Target frame health bar color picker
	if not CellAdditionsDB.shadow_new_frameColors["Target"] then
		CellAdditionsDB.shadow_new_frameColors["Target"] = {r = 0.8, g = 0.6, b = 0.1, a = 1.0} -- Gold color
	end
	local targetColor = CellAdditionsDB.shadow_new_frameColors["Target"]
	local targetColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = targetColor.r, g = targetColor.g, b = targetColor.b, a = targetColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["Target"].r = r
			CellAdditionsDB.shadow_new_frameColors["Target"].g = g
			CellAdditionsDB.shadow_new_frameColors["Target"].b = b
			CellAdditionsDB.shadow_new_frameColors["Target"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	targetColorPicker:SetPoint("TOP", targetFrameCheckbox, "TOP", 0, 0)
	targetColorPicker:SetPoint("RIGHT", hbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["Target"] = targetColorPicker
	HookColorPicker(targetColorPicker)
	
	-- Target frame power bar color picker
	if not CellAdditionsDB.shadow_new_frameColors["TargetPower"] then
		CellAdditionsDB.shadow_new_frameColors["TargetPower"] = {r = 0.8, g = 0.4, b = 0.1, a = 1.0} -- Orange color
	end
	local targetPowerColor = CellAdditionsDB.shadow_new_frameColors["TargetPower"]
	local targetPowerColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = targetPowerColor.r, g = targetPowerColor.g, b = targetPowerColor.b, a = targetPowerColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["TargetPower"].r = r
			CellAdditionsDB.shadow_new_frameColors["TargetPower"].g = g
			CellAdditionsDB.shadow_new_frameColors["TargetPower"].b = b
			CellAdditionsDB.shadow_new_frameColors["TargetPower"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	targetPowerColorPicker:SetPoint("TOP", targetFrameCheckbox, "TOP", 0, 0)
	targetPowerColorPicker:SetPoint("RIGHT", pbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["TargetPower"] = targetPowerColorPicker
	HookColorPicker(targetPowerColorPicker)
	
	-- Target's Target Frame
	local targetTargetFrameCheckbox = Cell.CreateCheckButton(
		content,
		"Target's Target Frame",
		function(checked)
			CellAdditionsDB.shadow_new_useCUFTargetTargetShadow = checked
			ShadowNewManager.settings.shadow_new_useCUFTargetTargetShadow = checked
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	targetTargetFrameCheckbox:SetPoint("TOPLEFT", targetFrameCheckbox, "BOTTOMLEFT", 0, -10)
	targetTargetFrameCheckbox:SetChecked(CellAdditionsDB.shadow_new_useCUFTargetTargetShadow)
	
	-- Target's Target frame health bar color picker
	local targetTargetColor = CellAdditionsDB.shadow_new_frameColors["TargetTarget"]
	if not targetTargetColor then
		targetTargetColor = {r = 0.8, g = 0.2, b = 0.4, a = 1.0} -- Pinkish color
		CellAdditionsDB.shadow_new_frameColors["TargetTarget"] = targetTargetColor
	end
	
	local targetTargetColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = targetTargetColor.r, g = targetTargetColor.g, b = targetTargetColor.b, a = targetTargetColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["TargetTarget"].r = r
			CellAdditionsDB.shadow_new_frameColors["TargetTarget"].g = g
			CellAdditionsDB.shadow_new_frameColors["TargetTarget"].b = b
			CellAdditionsDB.shadow_new_frameColors["TargetTarget"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	targetTargetColorPicker:SetPoint("TOP", targetTargetFrameCheckbox, "TOP", 0, 0)
	targetTargetColorPicker:SetPoint("RIGHT", hbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["TargetTarget"] = targetTargetColorPicker
	HookColorPicker(targetTargetColorPicker)
	
	-- Target's Target frame power bar color picker
	if not CellAdditionsDB.shadow_new_frameColors["TargetTargetPower"] then
		CellAdditionsDB.shadow_new_frameColors["TargetTargetPower"] = {r = 0.8, g = 0.2, b = 0.4, a = 1.0} -- Same as health for now
	end
	local targetTargetPowerColor = CellAdditionsDB.shadow_new_frameColors["TargetTargetPower"]
	local targetTargetPowerColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = targetTargetPowerColor.r, g = targetTargetPowerColor.g, b = targetTargetPowerColor.b, a = targetTargetPowerColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["TargetTargetPower"].r = r
			CellAdditionsDB.shadow_new_frameColors["TargetTargetPower"].g = g
			CellAdditionsDB.shadow_new_frameColors["TargetTargetPower"].b = b
			CellAdditionsDB.shadow_new_frameColors["TargetTargetPower"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	targetTargetPowerColorPicker:SetPoint("TOP", targetTargetFrameCheckbox, "TOP", 0, 0)
	targetTargetPowerColorPicker:SetPoint("RIGHT", pbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["TargetTargetPower"] = targetTargetPowerColorPicker
	HookColorPicker(targetTargetPowerColorPicker)
	
	-- Focus Frame
	local focusFrameCheckbox = Cell.CreateCheckButton(
		content,
		"Focus Frame",
		function(checked)
			CellAdditionsDB.shadow_new_useCUFFocusShadow = checked
			ShadowNewManager.settings.shadow_new_useCUFFocusShadow = checked
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	focusFrameCheckbox:SetPoint("TOPLEFT", targetTargetFrameCheckbox, "BOTTOMLEFT", 0, -10)
	focusFrameCheckbox:SetChecked(CellAdditionsDB.shadow_new_useCUFFocusShadow)
	
	-- Focus frame health bar color picker
	local focusColor = CellAdditionsDB.shadow_new_frameColors["Focus"]
	if not focusColor then
		focusColor = {r = 0.6, g = 0.2, b = 0.6, a = 1.0} -- Purple color
		CellAdditionsDB.shadow_new_frameColors["Focus"] = focusColor
	end
	
	local focusColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = focusColor.r, g = focusColor.g, b = focusColor.b, a = focusColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["Focus"].r = r
			CellAdditionsDB.shadow_new_frameColors["Focus"].g = g
			CellAdditionsDB.shadow_new_frameColors["Focus"].b = b
			CellAdditionsDB.shadow_new_frameColors["Focus"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	focusColorPicker:SetPoint("TOP", focusFrameCheckbox, "TOP", 0, 0)
	focusColorPicker:SetPoint("RIGHT", hbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["Focus"] = focusColorPicker
	HookColorPicker(focusColorPicker)
	
	-- Focus frame power bar color picker
	if not CellAdditionsDB.shadow_new_frameColors["FocusPower"] then
		CellAdditionsDB.shadow_new_frameColors["FocusPower"] = {r = 0.4, g = 0.1, b = 0.5, a = 1.0} -- Darker purple
	end
	local focusPowerColor = CellAdditionsDB.shadow_new_frameColors["FocusPower"]
	local focusPowerColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = focusPowerColor.r, g = focusPowerColor.g, b = focusPowerColor.b, a = focusPowerColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["FocusPower"].r = r
			CellAdditionsDB.shadow_new_frameColors["FocusPower"].g = g
			CellAdditionsDB.shadow_new_frameColors["FocusPower"].b = b
			CellAdditionsDB.shadow_new_frameColors["FocusPower"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	focusPowerColorPicker:SetPoint("TOP", focusFrameCheckbox, "TOP", 0, 0)
	focusPowerColorPicker:SetPoint("RIGHT", pbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["FocusPower"] = focusPowerColorPicker
	HookColorPicker(focusPowerColorPicker)
	
	-- Pet Frame
	local petFrameCheckbox = Cell.CreateCheckButton(
		content,
		"Pet Frame",
		function(checked)
			CellAdditionsDB.shadow_new_useCUFPetShadow = checked
			ShadowNewManager.settings.shadow_new_useCUFPetShadow = checked
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	petFrameCheckbox:SetPoint("TOPLEFT", focusFrameCheckbox, "BOTTOMLEFT", 0, -10)
	petFrameCheckbox:SetChecked(CellAdditionsDB.shadow_new_useCUFPetShadow)
	
	-- Pet frame health bar color picker
	local petColor = CellAdditionsDB.shadow_new_frameColors["Pet"]
	if not petColor then
		petColor = {r = 0.4, g = 0.2, b = 0.8, a = 1.0} -- Purple color
		CellAdditionsDB.shadow_new_frameColors["Pet"] = petColor
	end
	
	local petColorPicker = Cell.CreateColorPicker(
		content,
		"",
		{r = petColor.r, g = petColor.g, b = petColor.b, a = petColor.a},
		function(r, g, b, a)
			CellAdditionsDB.shadow_new_frameColors["Pet"].r = r
			CellAdditionsDB.shadow_new_frameColors["Pet"].g = g
			CellAdditionsDB.shadow_new_frameColors["Pet"].b = b
			CellAdditionsDB.shadow_new_frameColors["Pet"].a = a
			ShadowNewManager:SyncSettings()
			ShadowNewManager:UpdateAll()
		end
	)
	petColorPicker:SetPoint("TOP", petFrameCheckbox, "TOP", 0, 0)
	petColorPicker:SetPoint("RIGHT", hbHeader, "RIGHT", 0, 0)
	ShadowNewManager.frameColorPickers["Pet"] = petColorPicker
	HookColorPicker(petColorPicker)
	
	-- We don't need separate bar settings section anymore as they're integrated
	-- into the unit frames section with the HB/PB columns
end

-- Initialize function called when the module loads
function EnhancedShadow:Initialize()
	-- Initialize settings even if the module is disabled
	ShadowNewManager:InitializeSettings()

	-- Check if the module is enabled in settings
	if not CellAdditionsDB or not CellAdditionsDB.shadow_new_enabled then
		ns.Debug("EnhancedShadow module not enabled, skipping initialization")
		return
	end

	-- Initialize color pickers
	C_Timer.After(0.5, function()
		if ShadowNewManager.frameColorPickers then
			for frameType, picker in pairs(ShadowNewManager.frameColorPickers) do
				if picker and picker.SetColor and CellAdditionsDB.shadow_new_frameColors and CellAdditionsDB.shadow_new_frameColors[frameType] then
					local color = CellAdditionsDB.shadow_new_frameColors[frameType]
					picker:SetColor(color.r, color.g, color.b, color.a)
				end
			end
		end
	end)
    
    -- Hook directly into the CUF_Target frame if it exists
    C_Timer.After(1, function()
        local targetFrame = _G["CUF_Target"]
        if targetFrame then
            targetFrame:HookScript("OnShow", function()
                if CellAdditionsDB.shadow_new_useTargetFrameShadow then
                    print("[CellAdditions] Target frame detected - applying shadow")
                    ShadowNewManager:ForceApplyTargetShadows()
                end
            end)
            
            -- Also hook Health and Power bars
            local healthBar = _G["CUF_Target_HealthBar"]
            if healthBar then
                healthBar:HookScript("OnShow", function()
                    if CellAdditionsDB.shadow_new_useTargetFrameShadow and CellAdditionsDB.shadow_new_shadowBars.healthBar then
                        print("[CellAdditions] Target health bar detected - applying shadow")
                        ShadowNewManager:ForceApplyTargetShadows()
                    end
                end)
            end
            
            local powerBar = _G["CUF_Target_PowerBar"]
            if powerBar then
                powerBar:HookScript("OnShow", function()
                    if CellAdditionsDB.shadow_new_useTargetFrameShadow and CellAdditionsDB.shadow_new_shadowBars.powerBar then
                        print("[CellAdditions] Target power bar detected - applying shadow")
                        ShadowNewManager:ForceApplyTargetShadows()
                    end
                end)
            end
            
            print("[CellAdditions] Hooked into target frame successfully")
        else
            print("[CellAdditions] Target frame not found for hooking - will try later")
            
            -- Set up a delayed retry system
            local retryCount = 0
            local maxRetries = 5
            local retryTimer
            
            local function retryTargetHook()
                retryCount = retryCount + 1
                local targetFrame = _G["CUF_Target"]
                if targetFrame then
                    targetFrame:HookScript("OnShow", function()
                        if CellAdditionsDB.shadow_new_useTargetFrameShadow then
                            print("[CellAdditions] Target frame detected on retry - applying shadow")
                            ShadowNewManager:ForceApplyTargetShadows()
                        end
                    end)
                    print("[CellAdditions] Successfully hooked into target frame on retry " .. retryCount)
                    if retryTimer then retryTimer:Cancel() end
                else
                    if retryCount < maxRetries then
                        retryTimer = C_Timer.NewTimer(2, retryTargetHook)
                    else
                        print("[CellAdditions] Failed to find target frame after " .. maxRetries .. " retries")
                    end
                end
            end
            
            retryTimer = C_Timer.NewTimer(2, retryTargetHook)
        end
    end)

	-- Register Cell callbacks
	if Cell then
		Cell:RegisterCallback("Cell_Init", function()
			C_Timer.After(0.5, function()
				ShadowNewManager:ScanForFrames()
				ShadowNewManager:UpdateAll()
				ns.Debug("EnhancedShadow module initialized after Cell_Init")
                
                -- Force apply target shadows specifically
                ShadowNewManager:ForceApplyTargetShadows()
			end)
		end)

		Cell:RegisterCallback("Cell_UnitButtonCreated", function()
			C_Timer.After(0.1, function()
				ShadowNewManager:ScanForFrames()
				ShadowNewManager:UpdateAll()
                
                -- Also check for target frames
                ShadowNewManager:ForceApplyTargetShadows()
			end)
		end)

		Cell:RegisterCallback("Cell_RaidFrame_Update", function()
			ShadowNewManager:UpdateAll()
		end)

		Cell:RegisterCallback("Cell_PartyFrame_Update", function()
			ShadowNewManager:UpdateAll()
		end)

		Cell:RegisterCallback("Cell_SoloFrame_Update", function()
			ShadowNewManager:UpdateAll()
		end)

		Cell:RegisterCallback("Cell_Group_Moved", function()
			C_Timer.After(0.1, function()
				ShadowNewManager:ScanForFrames()
				ShadowNewManager:UpdateAll()
			end)
		end)

		Cell:RegisterCallback("Cell_Group_Updated", function()
			C_Timer.After(0.1, function()
				ShadowNewManager:ScanForFrames()
				ShadowNewManager:UpdateAll()
			end)
		end)

		Cell:RegisterCallback("Cell_Layout_Updated", function()
			C_Timer.After(0.1, function()
				ShadowNewManager:ScanForFrames()
				ShadowNewManager:UpdateAll()
                
                -- Specifically check target frames again
                ShadowNewManager:ForceApplyTargetShadows()
			end)
		end)
	end

	-- Register for relevant WoW events
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
	eventFrame:RegisterEvent("GROUP_JOINED")
	eventFrame:RegisterEvent("GROUP_LEFT")
	eventFrame:SetScript("OnEvent", function(self, event, ...)
		if
			event == "GROUP_ROSTER_UPDATE"
			or event == "RAID_ROSTER_UPDATE"
			or event == "GROUP_JOINED"
			or event == "GROUP_LEFT"
		then
			C_Timer.After(0.1, function()
				ShadowNewManager:ScanForFrames()
				ShadowNewManager:UpdateAll()
			end)
		end
	end)

	-- Apply shadows to Cell frames
	self:ApplyShadows()

	-- Debug output
	print("[CellAdditions] EnhancedShadow module initialized")
end

-- Apply shadows to Cell frames
function EnhancedShadow:ApplyShadows()
	-- Make sure Cell is loaded
	if not Cell or not Cell.frames then
		ns.Debug("EnhancedShadow:ApplyShadows - Cell frames not available")
		return
	end

	-- Apply shadow to unit frames
	C_Timer.After(1, function()
		ShadowNewManager:ScanForFrames()
		ShadowNewManager:UpdateAll()
		print("[CellAdditions] EnhancedShadow effects are now being applied to frames")
	end)
end

-- Enable/disable the module
function EnhancedShadow:SetEnabled(enabled)
	if not CellAdditionsDB then
		ns.Debug("EnhancedShadow:SetEnabled - CellAdditionsDB not available")
		return
	end

	local wasEnabled = CellAdditionsDB.shadow_new_enabled
	CellAdditionsDB.shadow_new_enabled = enabled

	-- Print a user-visible message
	print("[CellAdditions] EnhancedShadow module " .. (enabled and "enabled" or "disabled"))

	if enabled then
		if not wasEnabled then
			ns.Debug("EnhancedShadow:SetEnabled - Module was disabled, now enabling")
			self:Initialize()
		else
			ns.Debug("EnhancedShadow:SetEnabled - Module was already enabled")
		end
	else
		-- Remove shadows if needed
		if wasEnabled then
			ns.Debug("EnhancedShadow:SetEnabled - Module was enabled, now disabling")
			CleanupAllRaidShadowsNew()
			print("[CellAdditions] EnhancedShadow effects removed from frames")
		else
			ns.Debug("EnhancedShadow:SetEnabled - Module was already disabled")
		end
	end
end

-- Register the module with the addon
ns.RegisterModule(EnhancedShadow)

-- Add a special function to handle Target frames specifically
function ShadowNewManager:ApplyShadowToTargetFrame(frame)
	if not frame or not self.settings.shadow_new_useTargetFrameShadow then
		return
	end
	
	-- Safety check - make sure this is actually a target frame
	local frameName = frame:GetName() or ""
	if frameName:find("CUF_Player") then
		ns.Debug("SAFETY: Prevented target shadow application to player frame: " .. frameName)
		return
	end
	
	-- Only apply to actual target frames
	if frameName:find("Target") or frameName:find("target") then
		CreateShadowNew(frame, "Target")
		ns.Debug("Applied target shadow to: " .. frameName)
	end
end

-- Add a dedicated function for CUF_Target frames
function ShadowNewManager:ApplyShadowToCUFTargetFrame()
    -- Find the CUF_Target frame directly
    local frame = _G["CUF_Target"]
    if not frame or not self.settings.shadow_new_useTargetFrameShadow then
        return
    end
    
    -- First clean up any existing shadows
    if frame.shadow_new then
        frame.shadow_new:Hide()
        frame.shadow_new = nil
    end
    
    -- Create a new shadow with target color - force the frame to have shadow
    local targetColor = CellAdditionsDB.shadow_new_frameColors["Target"]
    if not targetColor then
        targetColor = {r = 0.8, g = 0.6, b = 0.1, a = 1.0} -- Gold color
        CellAdditionsDB.shadow_new_frameColors["Target"] = targetColor
    end
    
    local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    local size = CellAdditionsDB.shadow_new_shadowSize or 4
    
    shadow:SetFrameLevel(frame:GetFrameLevel() - 1)
    shadow:SetPoint("TOPLEFT", -size, size)
    shadow:SetPoint("BOTTOMRIGHT", size, -size)
    
    shadow:SetBackdrop({
        edgeFile = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga",
        edgeSize = size,
        insets = { left = size, right = size, top = size, bottom = size },
    })
    
    shadow:SetBackdropColor(0, 0, 0, 0)
    shadow:SetBackdropBorderColor(targetColor.r, targetColor.g, targetColor.b, targetColor.a)
    
    frame.shadow_new = shadow
    
    ns.Debug("Applied DIRECT shadow to CUF_Target frame: " .. (frame:GetName() or "unnamed"))
    
    -- Also apply to health and power bars if enabled
    local healthBar = _G["CUF_Target_HealthBar"]
    local powerBar = _G["CUF_Target_PowerBar"]
    
    if healthBar and self.settings.shadow_new_shadowBars.healthBar then
        if healthBar.shadow_new then
            healthBar.shadow_new:Hide()
            healthBar.shadow_new = nil
        end
        
        local healthShadow = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
        healthShadow:SetFrameLevel(healthBar:GetFrameLevel() - 1)
        healthShadow:SetPoint("TOPLEFT", -size, size)
        healthShadow:SetPoint("BOTTOMRIGHT", size, -size)
        
        healthShadow:SetBackdrop({
            edgeFile = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga",
            edgeSize = size,
            insets = { left = size, right = size, top = size, bottom = size },
        })
        
        healthShadow:SetBackdropColor(0, 0, 0, 0)
        healthShadow:SetBackdropBorderColor(targetColor.r, targetColor.g, targetColor.b, targetColor.a)
        
        healthBar.shadow_new = healthShadow
        ns.Debug("Applied DIRECT shadow to CUF_Target_HealthBar")
    end
    
    if powerBar and self.settings.shadow_new_shadowBars.powerBar then
        if powerBar.shadow_new then
            powerBar.shadow_new:Hide()
            powerBar.shadow_new = nil
        end
        
        local powerColor = CellAdditionsDB.shadow_new_frameColors["TargetPower"]
        if not powerColor then
            powerColor = {r = 0.8, g = 0.4, b = 0.1, a = 1.0} -- Orange color
            CellAdditionsDB.shadow_new_frameColors["TargetPower"] = powerColor
        end
        
        local powerShadow = CreateFrame("Frame", nil, powerBar, "BackdropTemplate")
        powerShadow:SetFrameLevel(powerBar:GetFrameLevel() - 1)
        powerShadow:SetPoint("TOPLEFT", -size, size)
        powerShadow:SetPoint("BOTTOMRIGHT", size, -size)
        
        powerShadow:SetBackdrop({
            edgeFile = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga",
            edgeSize = size,
            insets = { left = size, right = size, top = size, bottom = size },
        })
        
        powerShadow:SetBackdropColor(0, 0, 0, 0)
        powerShadow:SetBackdropBorderColor(powerColor.r, powerColor.g, powerColor.b, powerColor.a)
        
        powerBar.shadow_new = powerShadow
        ns.Debug("Applied DIRECT shadow to CUF_Target_PowerBar")
    end
    
    -- Print a message to confirm
    print("[CellAdditions] Applied shadow to Target frame")
end

-- Add this function to forcefully apply target shadows
function ShadowNewManager:ForceApplyTargetShadows()
    -- Always apply to target frame if the setting is enabled
    if CellAdditionsDB.shadow_new_useTargetFrameShadow then
        -- Force direct application to target frame
        self:ApplyShadowToCUFTargetFrame()
        
        -- Also check Cell.frames for any target-related frames
        if Cell and Cell.frames then
            for name, frame in pairs(Cell.frames) do
                if name:find("Target") and not name:find("Player") then
                    -- For any target frame that's not a player frame
                    if frame.shadow_new then
                        frame.shadow_new:Hide()
                        frame.shadow_new = nil
                    end
                    CreateShadowNew(frame, "Target")
                    ns.Debug("Applied shadow to target frame in Cell.frames: " .. name)
                end
            end
        end
    end
end

-- Add a function to apply shadow to CUF_Focus frame
function ShadowNewManager:ApplyCUFFocusShadow()
    local focusFrame = _G["CUF_Focus"]
    if not focusFrame then return end
    
    -- Remove any existing shadow
    if focusFrame.shadow_new then
        focusFrame.shadow_new:Hide()
        focusFrame.shadow_new = nil
    end
    
    -- Create a purple shadow
    local focusColor = {r = 0.6, g = 0.2, b = 0.8, a = 1.0}
    local shadow = CreateFrame("Frame", nil, focusFrame, "BackdropTemplate")
    local size = CellAdditionsDB.shadow_new_shadowSize or 4
    
    shadow:SetFrameLevel(focusFrame:GetFrameLevel() - 1)
    shadow:SetPoint("TOPLEFT", -size, size)
    shadow:SetPoint("BOTTOMRIGHT", size, -size)
    
    shadow:SetBackdrop({
        edgeFile = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga",
        edgeSize = size,
        insets = { left = size, right = size, top = size, bottom = size },
    })
    
    shadow:SetBackdropColor(0, 0, 0, 0)
    shadow:SetBackdropBorderColor(focusColor.r, focusColor.g, focusColor.b, focusColor.a)
    
    focusFrame.shadow_new = shadow
    
    print("[CellAdditions] Applied purple shadow to Focus frame")
    
    -- Also apply shadows to focus frame health/power bars if needed
    local healthBar = _G["CUF_Focus_HealthBar"]
    local powerBar = _G["CUF_Focus_PowerBar"]
    
    if healthBar and CellAdditionsDB.shadow_new_shadowBars and CellAdditionsDB.shadow_new_shadowBars.healthBar then
        -- Remove any existing shadow
        if healthBar.shadow_new then
            healthBar.shadow_new:Hide()
            healthBar.shadow_new = nil
        end
        
        -- Create shadow for health bar
        local hbShadow = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
        hbShadow:SetFrameLevel(healthBar:GetFrameLevel() - 1)
        hbShadow:SetPoint("TOPLEFT", -size, size)
        hbShadow:SetPoint("BOTTOMRIGHT", size, -size)
        
        hbShadow:SetBackdrop({
            edgeFile = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga",
            edgeSize = size,
            insets = { left = size, right = size, top = size, bottom = size },
        })
        
        hbShadow:SetBackdropColor(0, 0, 0, 0)
        hbShadow:SetBackdropBorderColor(focusColor.r, focusColor.g, focusColor.b, focusColor.a)
        
        healthBar.shadow_new = hbShadow
    end
    
    if powerBar and CellAdditionsDB.shadow_new_shadowBars and CellAdditionsDB.shadow_new_shadowBars.powerBar then
        -- Remove any existing shadow
        if powerBar.shadow_new then
            powerBar.shadow_new:Hide()
            powerBar.shadow_new = nil
        end
        
        -- Create shadow for power bar
        local pbShadow = CreateFrame("Frame", nil, powerBar, "BackdropTemplate")
        pbShadow:SetFrameLevel(powerBar:GetFrameLevel() - 1)
        pbShadow:SetPoint("TOPLEFT", -size, size)
        pbShadow:SetPoint("BOTTOMRIGHT", size, -size)
        
        pbShadow:SetBackdrop({
            edgeFile = "Interface\\AddOns\\CellAdditions\\Media\\glowTex.tga",
            edgeSize = size,
            insets = { left = size, right = size, top = size, bottom = size },
        })
        
        pbShadow:SetBackdropColor(0, 0, 0, 0)
        pbShadow:SetBackdropBorderColor(focusColor.r, focusColor.g, focusColor.b, focusColor.a)
        
        powerBar.shadow_new = pbShadow
    end
end

-- Create event handler for target frame
local targetEventFrame = CreateFrame("Frame")
targetEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        -- Wait a brief moment for UI to update
        C_Timer.After(0.1, function()
            -- Apply target shadows
            ShadowNewManager:ForceApplyTargetShadows()
        end)
    end
end)

-- Create event handler for focus frame
local focusEventFrame = CreateFrame("Frame")
focusEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_FOCUS_CHANGED" then
        -- Wait a brief moment for UI to update
        C_Timer.After(0.1, function()
            -- Apply focus shadows
            ShadowNewManager:ApplyCUFFocusShadow()
        end)
    end
end)

-- Register this handler with Cell if possible
if Cell and Cell.RegisterCallback then
    Cell:RegisterCallback("Cell_LayoutLoaded", function()
        C_Timer.After(0.5, function()
            ShadowNewManager:ForceApplyTargetShadows()
        end)
    end)
    
    Cell:RegisterCallback("Cell_LayoutApplied", function()
        C_Timer.After(0.5, function()
            ShadowNewManager:ForceApplyTargetShadows()
        end)
    end)
end 