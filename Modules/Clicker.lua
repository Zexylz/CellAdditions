local addonName, ns = ...

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
	-- Check if module is enabled first
	if not CellAdditionsDB or not CellAdditionsDB.clickerEnabled then
		self:CleanupAllClickers() -- Remove any existing clickers
		ns.Debug("Clicker module disabled, removing clickers")
		return
	end

	local pad = 15

	-- Make sure Cell is available
	local Cell = ns.Cell or _G.Cell
	if not Cell then 
		ns.Debug("Cell not available for clicker layout")
		return 
	end

	-- Check if CUF is available (Cell Unit Frames)
	if not _G.CUF or not _G.CUF.Util then
		ns.Debug("CUF not available for clicker layout")
		return
	end

	-- Get all unit buttons directly from CUF
	local unitButtons = _G.CUF.unitButtons
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
	
	-- Get Cell reference
	local Cell = ns.Cell or _G.Cell
	if not Cell then
		ns.Debug("ERROR: Cell not available for Clicker settings")
		return
	end

	-- Set a reasonable height for the content
	content:SetHeight(400)

	-- Clicker Settings header with proper spacing below enable checkbox
	local settingsHeader = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
	settingsHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -25)
	settingsHeader:SetText("Clicker Settings")
	
	-- SECTION 1: GENERAL SETTINGS
	local generalText = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	generalText:SetPoint("TOPLEFT", settingsHeader, "BOTTOMLEFT", 0, -20)
	generalText:SetText("General Settings")
	
	-- Create a container frame for sliders
	local sliderContainer = CreateFrame("Frame", nil, content)
	sliderContainer:SetPoint("TOPLEFT", generalText, "BOTTOMLEFT", 5, -10)
	sliderContainer:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, 0)
	sliderContainer:SetHeight(200)
	
	-- Create width display
	local widthText = sliderContainer:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	widthText:SetPoint("TOPLEFT", sliderContainer, "TOPLEFT", 0, 0)
	widthText:SetText("Width")
	
	local widthValue = sliderContainer:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	widthValue:SetPoint("LEFT", widthText, "RIGHT", 50, 0)
	widthValue:SetJustifyH("CENTER")
	widthValue:SetWidth(40)
	widthValue:SetText(tostring(ClickerManager.settings.width or 100))
	
	-- Width slider
	local widthSlider = Cell.CreateSlider("", sliderContainer, 20, 300, 180, 1)
	widthSlider:SetPoint("TOPLEFT", widthText, "BOTTOMLEFT", 0, -5)
	widthSlider:SetLabel("")
	widthSlider:SetValue(ClickerManager.settings.width or 100)
	widthSlider.afterValueChangedFn = function(value)
		ClickerManager.settings.width = math.floor(value)
		widthValue:SetText(tostring(ClickerManager.settings.width))
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end
	
	-- Create height display
	local heightText = sliderContainer:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	heightText:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -25)
	heightText:SetText("Height")
	
	local heightValue = sliderContainer:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	heightValue:SetPoint("LEFT", heightText, "RIGHT", 45, 0)
	heightValue:SetJustifyH("CENTER")
	heightValue:SetWidth(40)
	heightValue:SetText(tostring(ClickerManager.settings.height or 150))
	
	-- Height slider
	local heightSlider = Cell.CreateSlider("", sliderContainer, 20, 300, 180, 1)
	heightSlider:SetPoint("TOPLEFT", heightText, "BOTTOMLEFT", 0, -5)
	heightSlider:SetLabel("")
	heightSlider:SetValue(ClickerManager.settings.height or 150)
	heightSlider.afterValueChangedFn = function(value)
		ClickerManager.settings.height = math.floor(value)
		heightValue:SetText(tostring(ClickerManager.settings.height))
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end
	
	-- SECTION 2: POSITION
	local positionText = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	positionText:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", -5, -35)
	positionText:SetText("Position")
	
	-- X Offset display
	local xOffsetText = sliderContainer:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	xOffsetText:SetPoint("TOPLEFT", positionText, "BOTTOMLEFT", 5, -10)
	xOffsetText:SetText("X Offset")
	
	local xOffsetValue = sliderContainer:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	xOffsetValue:SetPoint("LEFT", xOffsetText, "RIGHT", 30, 0)
	xOffsetValue:SetJustifyH("CENTER")
	xOffsetValue:SetWidth(40)
	xOffsetValue:SetText(tostring(ClickerManager.settings.offsetX or 0))
	
	-- X offset slider
	local xOffsetSlider = Cell.CreateSlider("", sliderContainer, -50, 50, 180, 1)
	xOffsetSlider:SetPoint("TOPLEFT", xOffsetText, "BOTTOMLEFT", 0, -5)
	xOffsetSlider:SetLabel("")
	xOffsetSlider:SetValue(ClickerManager.settings.offsetX or 0)
	xOffsetSlider.afterValueChangedFn = function(value)
		ClickerManager.settings.offsetX = math.floor(value)
		xOffsetValue:SetText(tostring(ClickerManager.settings.offsetX))
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end
	
	-- Y Offset display
	local yOffsetText = sliderContainer:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	yOffsetText:SetPoint("TOPLEFT", xOffsetSlider, "BOTTOMLEFT", 0, -25)
	yOffsetText:SetText("Y Offset")
	
	local yOffsetValue = sliderContainer:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	yOffsetValue:SetPoint("LEFT", yOffsetText, "RIGHT", 30, 0)
	yOffsetValue:SetJustifyH("CENTER")
	yOffsetValue:SetWidth(40)
	yOffsetValue:SetText(tostring(ClickerManager.settings.offsetY or 0))
	
	-- Y offset slider
	local yOffsetSlider = Cell.CreateSlider("", sliderContainer, -50, 50, 180, 1)
	yOffsetSlider:SetPoint("TOPLEFT", yOffsetText, "BOTTOMLEFT", 0, -5)
	yOffsetSlider:SetLabel("")
	yOffsetSlider:SetValue(ClickerManager.settings.offsetY or 0)
	yOffsetSlider.afterValueChangedFn = function(value)
		ClickerManager.settings.offsetY = math.floor(value)
		yOffsetValue:SetText(tostring(ClickerManager.settings.offsetY))
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end
	
	-- SECTION 3: ADDITIONAL OPTIONS
	local optionsText = content:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	optionsText:SetPoint("TOPLEFT", yOffsetSlider, "BOTTOMLEFT", -5, -35)
	optionsText:SetText("Additional Options")
	
	-- Toggle custom size checkbox
	local customSizeCheckbox = Cell.CreateCheckButton(content, "Use Custom Size", function(checked)
		ClickerManager.settings.useCustomSize = checked
		-- Enable/disable width and height sliders based on custom size
		widthSlider:SetEnabled(checked)
		heightSlider:SetEnabled(checked)
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end)
	customSizeCheckbox:SetPoint("TOPLEFT", optionsText, "BOTTOMLEFT", 5, -15)
	customSizeCheckbox:SetChecked(ClickerManager.settings.useCustomSize)
	
	-- Enable/disable sliders based on initial state
	widthSlider:SetEnabled(ClickerManager.settings.useCustomSize)
	heightSlider:SetEnabled(ClickerManager.settings.useCustomSize)
	
	-- Debug checkbox
	local debugCheckbox = Cell.CreateCheckButton(content, "Show Debug Overlay", function(checked)
		ClickerManager.settings.debug = checked
		C_Timer.After(0.1, function() ClickerManager:LayoutClickers() end)
	end)
	debugCheckbox:SetPoint("TOPLEFT", customSizeCheckbox, "BOTTOMLEFT", 0, -12)
	debugCheckbox:SetChecked(ClickerManager.settings.debug)
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

-- Export the module
ns.Clicker = Clicker
ns.addon = ns.addon or {}
ns.addon.Clicker = Clicker

-- Register the module after a short delay to ensure main addon is loaded
C_Timer.After(0, function()
    if ns.RegisterModule then
        ns.RegisterModule(Clicker)
        ns.Debug("Clicker module registered")
    else
        print("[CellAdditions] ERROR: ns.RegisterModule not available for Clicker module")
    end
end)

-- Register for layout changes
if _G.CUF then
	_G.CUF:RegisterCallback("UpdateLayout", "CellAdditions_Clicker_UpdateLayout", function()
		ClickerManager:LayoutClickers()
	end)
end
