local addonName, ns = ...
local Cell = ns.Cell

-- Create a Clicker module namespace
local Clicker = {}
ns.Clicker = Clicker

-- Module settings
Clicker.name = "Clicker"
Clicker.id = "clicker"
Clicker.description = "Enhanced click functionality for unit frames"

-- Local variables
local C_Timer = _G.C_Timer
local frameLevel = 4
local lastUpdate = 0
local UPDATE_THROTTLE = 0.05 -- Only update every 0.05 seconds while sliding

-- ClickerManager for internal use
local ClickerManager = {
	activeClickers = {},
	settings = {},
	defaults = {
		width = 100,
		height = 150,
		useCustomSize = false,
		offsetX = 0,
		offsetY = 0,
		debug = false
	}
}

-- Initialize settings
function ClickerManager:InitializeSettings()
	-- Initialize DB if it doesn't exist
	CellAdditionsDB = CellAdditionsDB or {}
	
	-- Create clicker settings if they don't exist
	if not CellAdditionsDB.clickerSettings then
		CellAdditionsDB.clickerSettings = self.defaults
		ns.Debug("Created default clicker settings")
	else
		-- Make sure all expected fields exist
		if CellAdditionsDB.clickerSettings.width == nil then
			CellAdditionsDB.clickerSettings.width = self.defaults.width
		end
		if CellAdditionsDB.clickerSettings.height == nil then
			CellAdditionsDB.clickerSettings.height = self.defaults.height
		end
		if CellAdditionsDB.clickerSettings.useCustomSize == nil then
			CellAdditionsDB.clickerSettings.useCustomSize = self.defaults.useCustomSize
		end
		if CellAdditionsDB.clickerSettings.offsetX == nil then
			CellAdditionsDB.clickerSettings.offsetX = self.defaults.offsetX
		end
		if CellAdditionsDB.clickerSettings.offsetY == nil then
			CellAdditionsDB.clickerSettings.offsetY = self.defaults.offsetY
		end
		if CellAdditionsDB.clickerSettings.debug == nil then
			CellAdditionsDB.clickerSettings.debug = self.defaults.debug
		end
	end
	
	-- Store settings reference
	self.settings = CellAdditionsDB.clickerSettings
	
	-- Sync settings
	self:SyncSettings()
	ns.Debug("Clicker settings initialized")
end

-- Make sure settings are synced
function ClickerManager:SyncSettings()
	-- Nothing to do here since we're directly referencing CellAdditionsDB.clickerSettings
end

-- Clean up all existing clickers
function ClickerManager:CleanupAllClickers()
	-- First, clean up ALL existing clickers
	for name, clicker in pairs(_G) do
		if type(name) == "string" and name:match("^CellClicker_") then
			clicker:Hide()
			clicker:SetParent(nil)
			_G[name] = nil
		end
	end
	
	-- Clear active clickers tracking
	self.activeClickers = {}
	ns.Debug("All clickers cleaned up")
end

-- Layout all clickers
function ClickerManager:LayoutClickers()
	local pad = 15

	-- Make sure Cell is available
	if not Cell then 
		ns.Debug("Cell not available for clicker layout")
		return 
	end

	-- Check if CUF is available (Cell Unit Frames)
	local CUF = _G.CUF
	if not CUF or not CUF.Util then
		ns.Debug("CUF not available for clicker layout")
		return
	end

	-- Get all unit buttons directly from CUF
	local unitButtons = CUF.unitButtons
	if not unitButtons then
		ns.Debug("No unit buttons found in CUF")
		return
	end

	-- First, clean up ALL existing clickers
	for name, clicker in pairs(_G) do
		if type(name) == "string" and name:match("^CellClicker_") then
			clicker:Hide()
			clicker:SetParent(nil)
			_G[name] = nil
		end
	end

	-- Clear active clickers tracking
	self.activeClickers = {}

	-- Debug output
	-- Count how many unit buttons we found
	local count = 0
	for _ in pairs(unitButtons) do count = count + 1 end
	ns.Debug("Starting clicker layout with " .. count .. " unit buttons")

	-- Iterate through unit buttons
	for _, frame in pairs(unitButtons) do
		if frame and frame.widgets and frame:IsVisible() then
			local minX, minY, maxX, maxY
			local hasWidgets = false

			-- Get bounding box of health/power bars and texts
			for _, key in ipairs({ "healthBar" }) do
				local region = frame.widgets[key]
				if region and region:IsVisible() then
					hasWidgets = true
					local l, b, w, h = region:GetRect()
					if l and b and w and h then
						minX = minX and math.min(minX, l) or l
						minY = minY and math.min(minY, b) or b
						maxX = maxX and math.max(maxX, l + w) or (l + w)
						maxY = maxY and math.max(maxY, b + h) or (b + h)
					end
				end
			end

			if hasWidgets and minX and minY and maxX and maxY then
				local clickName = ("CellClicker_%s"):format(frame:GetName() or "Unknown")
				ns.Debug("Creating clicker for: " .. clickName)

				-- Create a new clicker for the frame
				local clicker = CreateFrame("Button", clickName, frame, "SecureActionButtonTemplate,SecureHandlerStateTemplate")

				-- Set frame strata and level to be above other UI elements
				clicker:SetFrameStrata("MEDIUM")
				clicker:SetFrameLevel(frameLevel) -- This ensures it's above most other elements

				-- Get the proper unit ID from the frame
				local unitID = frame.unitid or frame.unit or frame:GetAttribute("unit")
				if not unitID then
					ns.Debug("No unit ID found for " .. clickName)
					return
				end -- Skip if no valid unit

				-- Get the unit type for the menu
				local unitType = "SELF"
				if not UnitIsUnit(unitID, "player") then
					if UnitIsUnit(unitID, "pet") or UnitCreatureType(unitID) then
						unitType = "TARGET"
					elseif UnitIsPlayer(unitID) then
						if UnitCanAttack("player", unitID) then
							unitType = "ENEMY_PLAYER"
						elseif UnitInRaid(unitID) then
							unitType = "RAID_PLAYER"
						elseif UnitInParty(unitID) then
							unitType = "PARTY"
						else
							unitType = "PLAYER"
						end
					else
						unitType = "TARGET"
					end
				end

				local unitButton = CreateFrame("Button", clickName .. "_UnitButton", clicker, "SecureUnitButtonTemplate,SecureHandlerShowHideTemplate")
				unitButton:SetAllPoints()
				unitButton:EnableMouse(true)

				unitButton:SetAttribute("unit", unitID)
				unitButton:RegisterForClicks("AnyUp")
				unitButton:SetAttribute("*type1", "target")
				unitButton:SetAttribute("*type2", "togglemenu")
				unitButton:SetAttribute("useparent-unit", true)
				unitButton:SetAttribute("unitsuffix", "")
				unitButton:SetAttribute("*unitframe", "true")
				unitButton:SetAttribute("*unithasmenu", "true")

				-- Create the background
				local t = clicker:CreateTexture(nil, "BACKGROUND", nil, -8)
				t:SetAllPoints()
				t:SetTexture("Interface\\Buttons\\WHITE8X8")
				t:SetVertexColor(0, 1, 0, 0.3)
				clicker.bg = t

				clicker:ClearAllPoints()
				if self.settings.useCustomSize then
					-- Center the custom-sized box on the frame with offsets
					local frameWidth = frame:GetWidth()
					local frameHeight = frame:GetHeight()
					local xOffset = (frameWidth - self.settings.width) / 2 + self.settings.offsetX
					local yOffset = (frameHeight - self.settings.height) / 2 + self.settings.offsetY

					clicker:SetSize(self.settings.width, self.settings.height)
					clicker:SetPoint("CENTER", frame, "CENTER", self.settings.offsetX, self.settings.offsetY)
				else
					-- Use automatic sizing based on frame elements with bigger padding and offsets
					clicker:ClearAllPoints()
					clicker:SetPoint("TOPLEFT", frame, "TOPLEFT", -pad + self.settings.offsetX, pad + self.settings.offsetY)
					clicker:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", pad + self.settings.offsetX, -pad + self.settings.offsetY)
				end

				clicker:RegisterForClicks("AnyDown", "AnyUp")
				clicker:EnableMouse(true)
				clicker.bg:SetShown(self.settings.debug)

				-- Add to active clickers list
				self.activeClickers[clickName] = true

				-- Show if parent is shown
				clicker:SetShown(frame:IsVisible())
			end
		end
	end
	
	ns.Debug("Clickers layout complete")
end

-- Create settings UI
function Clicker:CreateSettings(parent, enableCheckbox)
	-- Make sure settings are initialized
	ClickerManager:InitializeSettings()

	local content = parent

	-- Set a reasonable height for the content
	content:SetHeight(400)

	-- Create a title for the clicker settings section
	local settingsTitle = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
	settingsTitle:SetText("Clicker Settings")
	settingsTitle:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -10)

	-- SECTION 1: GENERAL SETTINGS

	-- Create width slider with more vertical spacing
	local widthSlider = Cell.CreateSlider("Width", content, 20, 300, 180, 1)
	widthSlider:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 5, -30)
	widthSlider:SetValue(ClickerManager.settings.width or 100)
	widthSlider.afterValueChangedFn = function(value)
		ClickerManager.settings.width = math.floor(value)
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end

	-- Create height slider with more vertical spacing
	local heightSlider = Cell.CreateSlider("Height", content, 20, 300, 180, 1)
	heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -40)
	heightSlider:SetValue(ClickerManager.settings.height or 150)
	heightSlider.afterValueChangedFn = function(value)
		ClickerManager.settings.height = math.floor(value)
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end

	-- Create X offset slider with more vertical spacing
	local xOffsetSlider = Cell.CreateSlider("X Offset", content, -50, 50, 180, 1)
	xOffsetSlider:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, -40)
	xOffsetSlider:SetValue(ClickerManager.settings.offsetX or 0)
	xOffsetSlider.afterValueChangedFn = function(value)
		ClickerManager.settings.offsetX = math.floor(value)
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end

	-- Create Y offset slider with more vertical spacing
	local yOffsetSlider = Cell.CreateSlider("Y Offset", content, -50, 50, 180, 1)
	yOffsetSlider:SetPoint("TOPLEFT", xOffsetSlider, "BOTTOMLEFT", 0, -40)
	yOffsetSlider:SetValue(ClickerManager.settings.offsetY or 0)
	yOffsetSlider.afterValueChangedFn = function(value)
		ClickerManager.settings.offsetY = math.floor(value)
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end

	-- Toggle custom size checkbox
	local customSizeCheckbox = Cell.CreateCheckButton(content, "Use Custom Size", function(checked)
		ClickerManager.settings.useCustomSize = checked
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end)
	customSizeCheckbox:SetPoint("TOPLEFT", yOffsetSlider, "BOTTOMLEFT", 0, -20)
	customSizeCheckbox:SetChecked(ClickerManager.settings.useCustomSize)

	-- Debug checkbox
	local debugCheckbox = Cell.CreateCheckButton(content, "Show Debug Overlay", function(checked)
		ClickerManager.settings.debug = checked
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end)
	debugCheckbox:SetPoint("TOPLEFT", customSizeCheckbox, "BOTTOMLEFT", 0, -15)
	debugCheckbox:SetChecked(ClickerManager.settings.debug)

	-- Note: Apply Now button has been removed
end

-- Initialize function called when the module loads
function Clicker:Initialize()
	-- Initialize settings even if the module is disabled
	ClickerManager:InitializeSettings()

	-- Check if the module is enabled in settings
	if not CellAdditionsDB or not CellAdditionsDB.clickerEnabled then
		ns.Debug("Clicker module not enabled, skipping initialization")
		return
	end

	-- Register Cell callbacks
	if Cell then
		Cell:RegisterCallback("Cell_Init", function()
			C_Timer.After(0.5, function()
				ClickerManager:LayoutClickers()
				ns.Debug("Clicker module initialized after Cell_Init")
			end)
		end)

		Cell:RegisterCallback("Cell_UnitButtonCreated", function()
			C_Timer.After(0.1, function()
				ClickerManager:LayoutClickers()
			end)
		end)

		Cell:RegisterCallback("Cell_RaidFrame_Update", function()
			ClickerManager:LayoutClickers()
		end)

		Cell:RegisterCallback("Cell_PartyFrame_Update", function()
			ClickerManager:LayoutClickers()
		end)

		Cell:RegisterCallback("Cell_SoloFrame_Update", function()
			ClickerManager:LayoutClickers()
		end)

		Cell:RegisterCallback("Cell_Group_Moved", function()
			C_Timer.After(0.1, function()
				ClickerManager:LayoutClickers()
			end)
		end)

		Cell:RegisterCallback("Cell_Group_Updated", function()
			C_Timer.After(0.1, function()
				ClickerManager:LayoutClickers()
			end)
		end)

		Cell:RegisterCallback("Cell_Layout_Updated", function()
			C_Timer.After(0.1, function()
				ClickerManager:LayoutClickers()
			end)
		end)
		
		-- Register for additional Cell events if available
		if Cell.RegisterCallback then
			-- Try to register for Cell's frame initialization events
			Cell.RegisterCallback("FramesInitialized", "Clicker_Init", function()
				C_Timer.After(0.05, function() ClickerManager:LayoutClickers() end)
			end)
			
			-- Register for unit buttons update
			Cell.RegisterCallback("UpdateUnitButtons", "Clicker_Update", function()
				C_Timer.After(0.05, function() ClickerManager:LayoutClickers() end)
			end)
		end
	end

	-- Register for relevant WoW events
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:SetScript("OnEvent", function()
		C_Timer.After(0.05, function() ClickerManager:LayoutClickers() end)
	end)

	-- Debug output
	print("[CellAdditions] Clicker module initialized")
end

-- Enable/disable the module
function Clicker:SetEnabled(enabled)
	if not CellAdditionsDB then
		ns.Debug("Clicker:SetEnabled - CellAdditionsDB not available")
		return
	end

	local wasEnabled = CellAdditionsDB.clickerEnabled
	CellAdditionsDB.clickerEnabled = enabled

	-- Print a user-visible message
	print("[CellAdditions] Clicker module " .. (enabled and "enabled" or "disabled"))

	if enabled then
		if not wasEnabled then
			ns.Debug("Clicker:SetEnabled - Module was disabled, now enabling")
			self:Initialize()
		else
			ns.Debug("Clicker:SetEnabled - Module was already enabled")
		end
	else
		-- Remove clickers if needed
		if wasEnabled then
			ns.Debug("Clicker:SetEnabled - Module was enabled, now disabling")
			ClickerManager:CleanupAllClickers()
			print("[CellAdditions] Clickers removed from frames")
		else
			ns.Debug("Clicker:SetEnabled - Module was already disabled")
		end
	end
end

-- Register the module with the addon
ns.RegisterModule(Clicker)
