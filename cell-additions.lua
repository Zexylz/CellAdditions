local addonName, ns = ...

-- Create addon table
local CellAdditions = {}
ns.addon = CellAdditions

-- Store references
CellAdditions.Cell = _G.Cell
CellAdditions.L = CellAdditions.Cell and CellAdditions.Cell.L or {}
CellAdditions.F = CellAdditions.Cell and CellAdditions.Cell.funcs or {}
CellAdditions.P = CellAdditions.Cell and CellAdditions.Cell.pixelPerfectFuncs or {}

-- Debug output function
local function Debug(msg)
	if CellAdditionsDB and CellAdditionsDB.debug then
		-- Use DEFAULT_CHAT_FRAME:AddMessage to ensure visibility
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage("[CellAdditions DEBUG] " .. tostring(msg), 1, 0.5, 0)
		else
			-- Fallback to print if DEFAULT_CHAT_FRAME is not available
			print("[CellAdditions DEBUG] " .. tostring(msg))
		end
	end
end

-- Make Debug function available to modules
ns.Debug = Debug

-- Initialize function
function CellAdditions:Initialize()
	if not self.Cell then
		print("CellAdditions: Cell addon not found!")
		return
	end

	-- Initialize UI Frames API if available
	if ns.UIFrames and ns.UIFrames.Initialize then
		ns.UIFrames:Initialize()
	end
	
	-- Initialize modules
	-- if self.shadow then -- Removed old self.shadow:Initialize() as new Shadow.lua doesn't use it.
	--	self.shadow:Initialize()
	-- end
end

-- Event frame
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
	if addon == addonName then
		CellAdditions:Initialize()
	end
end)

-- Get references to Cell
local Cell = _G.Cell
local L = Cell and Cell.L or {}
local F = Cell and Cell.funcs or {}
local P = Cell and Cell.pixelPerfectFuncs or {}

-- Make Cell accessible to modules
ns.Cell = Cell

-- Modules table to store all registered modules
ns.modules = {}

-- Shadow options - initialize default settings
ns.shadowOptions = {
	enabled = true,
	size = 5,
	
	-- Cell frames
	partyFrames = false,
	partyHealthColor = {0.7, 0.9, 0.3, 1},
	partyPowerColor = {0.9, 0.7, 0.3, 1},
	
	raidFrames = false,
	raidHealthColor = {0.9, 0.7, 0.3, 1},
	raidPowerColor = {0.9, 0.5, 0.3, 1},
	
	soloFrame = false,
	soloHealthColor = {0.7, 0.9, 0.3, 1},
	soloPowerColor = {0.9, 0.7, 0.3, 1},
	
	-- Unit frames
	playerFrame = false,
	playerHealthColor = {0.7, 0.9, 0.3, 1},
	playerPowerColor = {0.9, 0.7, 0.3, 1},
	
	targetFrame = false,
	targetHealthColor = {0.9, 0.7, 0.3, 1},
	targetPowerColor = {0.9, 0.5, 0.3, 1},
	
	targettargetFrame = false,
	targettargetHealthColor = {0.9, 0.3, 0.5, 1},
	targettargetPowerColor = {0.9, 0.3, 0.5, 1},
	
	focusFrame = false,
	focusHealthColor = {0.7, 0.3, 0.7, 1},
	focusPowerColor = {0.5, 0.3, 0.7, 1},
	
	petFrame = false,
	petHealthColor = {0.5, 0.3, 0.7, 1},
	petPowerColor = {0.5, 0.3, 0.7, 1},
}

-- Helper function to ensure our tab shows its pressed state
local function UpdateAdditionsButtonState(show)
	local optionsFrame = Cell.frames.optionsFrame
	if not optionsFrame then
		return
	end

	for _, child in pairs({ optionsFrame:GetChildren() }) do
		if child:IsObjectType("Button") and child.id and child.id == "additions" then
			child:SetButtonState(show and "PUSHED" or "NORMAL")
			break
		end
	end
end

-- Initialize DB
local function InitDB()
	-- Create default settings if they don't exist
	if not CellAdditionsDB then
		CellAdditionsDB = {
			enabled = true,
			shadowEnabled = true, -- This might be a general toggle for all shadows
			clickerEnabled = true,
			debug = true, -- Enable debug by default for testing
			currentTab = "raidTools",
			-- Shadow module default settings (these seem distinct from shadowConfig)
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

			-- NEW: shadowConfig for AceConfig panel from Shadow.lua
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
				}
			}
		}
		Debug("Created default settings, including shadowConfig.")
	else
		-- Make sure all expected fields exist
		if CellAdditionsDB.shadowEnabled == nil then
			CellAdditionsDB.shadowEnabled = true
		end
		if CellAdditionsDB.clickerEnabled == nil then
			CellAdditionsDB.clickerEnabled = true
		end
		if CellAdditionsDB.debug == nil then
			CellAdditionsDB.debug = true -- Enable debug by default for testing
		end

		-- Initialize Shadow module settings if they don't exist (original ones)
		if CellAdditionsDB.shadowSize == nil then
			CellAdditionsDB.shadowSize = 4
		end
		if CellAdditionsDB.shadowColor == nil then
			CellAdditionsDB.shadowColor = { r = 0, g = 0, b = 0, a = 1 }
		end
		if CellAdditionsDB.shadowBars == nil then
			CellAdditionsDB.shadowBars = {
				healthBar = false,
				powerBar = false,
			}
		end
		if CellAdditionsDB.useStandaloneCellShadow == nil then
			CellAdditionsDB.useStandaloneCellShadow = false
		end
		if CellAdditionsDB.usePartyButtonShadow == nil then
			CellAdditionsDB.usePartyButtonShadow = false
		end
		if CellAdditionsDB.useRaidButtonShadow == nil then
			CellAdditionsDB.useRaidButtonShadow = false
		end
		
		-- NEW: Ensure shadowConfig and its sub-tables/defaults exist if DB was already there
		if CellAdditionsDB.shadowConfig == nil then
			CellAdditionsDB.shadowConfig = {
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
				}
			}
			Debug("Initialized missing shadowConfig in existing CellAdditionsDB.")
		else
			-- Ensure individual fields within shadowConfig have defaults if shadowConfig exists but is partial
			local sc = CellAdditionsDB.shadowConfig
			if sc.enableShadow == nil then sc.enableShadow = true end
			if sc.shadowSize == nil then sc.shadowSize = 5 end
			if sc.partyFrames == nil then sc.partyFrames = true end
			if sc.raidFrames == nil then sc.raidFrames = false end
			if sc.unitFrames == nil then
				sc.unitFrames = { Player = true, Target = false, TargetTarget = false, Focus = false, Pet = false }
			else
				if sc.unitFrames.Player == nil then sc.unitFrames.Player = true end
				if sc.unitFrames.Target == nil then sc.unitFrames.Target = false end
				if sc.unitFrames.TargetTarget == nil then sc.unitFrames.TargetTarget = false end
				if sc.unitFrames.Focus == nil then sc.unitFrames.Focus = false end
				if sc.unitFrames.Pet == nil then sc.unitFrames.Pet = false end
			end
		end
	end
end

-- Function to register a module
function ns.RegisterModule(module)
	if not module or not module.id or not module.name then
		Debug("Failed to register module: missing required properties")
		return
	end

	-- Add module to modules table
	ns.modules[module.id] = module
	Debug("Registered module: " .. module.name)
end

-- Function to initialize all modules
function ns.InitializeModules()
	Debug("Initializing modules...")
	
	-- First validate our API modules are loaded
	ns.ValidateAPIs()
	
	-- Loop through all registered modules and initialize them
	for id, module in pairs(ns.modules) do
		if type(module.Initialize) == "function" then
			Debug("Initializing module: " .. module.name)
			module:Initialize()
		end
	end
end

-- Function to validate APIs are properly loaded
function ns.ValidateAPIs()
	Debug("Validating API modules...")
	
	-- Check for ns.API
	if not ns.API then
		Debug("ERROR: API namespace not initialized. Creating it now.")
		ns.API = {}
	end
	
	-- Check for Shadow API
	if not ns.API.Shadow then
		Debug("ERROR: Shadow API not loaded. This module should be loaded via the TOC file.")
	else
		Debug("Shadow API is loaded and available")
	end
	
	Debug("API validation complete")
end

-- Helper function to find Cell's utility list frame
local function GetUtilityListFrame()
	if not Cell or not Cell.frames then
		Debug("GetUtilityListFrame: Cell or Cell.frames is nil")
		return nil
	end

	if not Cell.frames.utilitiesTab then
		Debug("GetUtilityListFrame: Cell.frames.utilitiesTab is nil")
		return nil
	end

	-- Get all children of the utilities tab
	local children = { Cell.frames.utilitiesTab:GetChildren() }
	Debug("GetUtilityListFrame: Found " .. #children .. " children in utilitiesTab")

	for i, child in ipairs(children) do
		if child:IsObjectType("Frame") then
			Debug("GetUtilityListFrame: Child " .. i .. " is a Frame")
			if child.buttons then
				Debug("GetUtilityListFrame: Found list frame with buttons")
				return child
			end
		end
	end

	Debug("GetUtilityListFrame: No suitable list frame found")
	return nil
end

-- Use Cell's native accent color
local function GetAccentColor()
	-- Cell already has a function to get the accent color
	return Cell.GetAccentColorTable()
end

-- Variables for list interface
local listButtons = {}
local selected = 1
local listFrame
local settingsFrame

-- Features will be populated from modules
local features = {}

local panel, listFrame, settingsFrame, selected, listButtons = nil, nil, nil, 1, {}

-- Make these variables available in the namespace so modules can access them
ns.listButtons = listButtons
ns.selected = selected
ns.features = features

-- Create our own content tab
local function CreateAdditionsPanel()
	-- Create the main tab panel - this will be the standalone Additions panel
	panel = Cell.CreateFrame("CellAdditionsPanel", UIParent, 400, 500) -- Restored to original dimensions
	panel:SetPoint("CENTER")
	panel:SetFrameStrata("HIGH")
	panel:Hide()

	-- Skip creating title and description to save space
	local contentAnchor = panel

	-- Create a list pane on the left side
	local listPane = Cell.CreateTitledPane(panel, "Features", 120, 120) -- Restored to original dimensions
	listPane:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, -5)

	-- Create a frame for the list
	listFrame = Cell.CreateFrame("CellAdditionsTab_ListFrame", listPane)
	listFrame:SetPoint("TOPLEFT", listPane, 0, -25)
	listFrame:SetPoint("BOTTOMRIGHT", listPane, 0, 5)
	listFrame:Show()

	-- Create a scroll frame for the list
	Cell.CreateScrollFrame(listFrame)
	listFrame.scrollFrame:SetScrollStep(19)

	-- Create a settings pane on the right side
	local settingsPane = Cell.CreateTitledPane(panel, "Settings", 265, 400) -- Restored to original dimensions
	settingsPane:SetPoint("TOPLEFT", listPane, "TOPRIGHT", 5, 0)
	settingsPane:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 5)

	-- Create settings frame
	settingsFrame = Cell.CreateFrame("CellAdditionsTab_SettingsFrame", settingsPane, 10, 10, true)
	settingsFrame:SetPoint("TOPLEFT", settingsPane, 0, -25)
	settingsFrame:SetPoint("BOTTOMRIGHT", settingsPane)
	settingsFrame:Show()

	-- Create scroll frame for settings
	Cell.CreateScrollFrame(settingsFrame)
	settingsFrame.scrollFrame:SetScrollStep(19)

	-- Store references
	panel.listPane = listPane
	panel.listFrame = listFrame
	panel.settingsPane = settingsPane
	panel.settingsFrame = settingsFrame

	-- Function to load the list of features
	function LoadFeatureList()
		-- Clear existing buttons
		for _, button in ipairs(listButtons) do
			button:Hide()
		end
		wipe(listButtons)

		-- Create list buttons for each feature
		for i, feature in ipairs(features) do
			local button =
				Cell.CreateButton(listFrame.scrollFrame.content, feature.name, "transparent-accent", { 115, 25 })

			-- Set text position (no icon for now)
			local fontString = button:GetFontString()
			fontString:ClearAllPoints()
			fontString:SetPoint("LEFT", button, "LEFT", 10, 0)
			fontString:SetJustifyH("LEFT")

			-- Set position
			if i == 1 then
				button:SetPoint("TOPLEFT")
				button:SetPoint("TOPRIGHT")
			else
				button:SetPoint("TOPLEFT", listButtons[i - 1], "BOTTOMLEFT")
				button:SetPoint("TOPRIGHT", listButtons[i - 1], "BOTTOMRIGHT")
			end

			-- Store feature data
			button.feature = feature
			button.index = i

			-- Set click handler
			button:SetScript("OnClick", function()
				selected = i
				ListHighlightFn(i)
			end)

			listButtons[i] = button
		end

		-- Update list frame height
		listFrame.scrollFrame.content:SetHeight(#features * 25)
	end

	-- Function to show settings for a feature
	function ShowFeatureSettings(index)
		-- Clear existing content
		settingsFrame.scrollFrame.content:SetHeight(1)
		for _, child in pairs({ settingsFrame.scrollFrame.content:GetChildren() }) do
			child:Hide()
		end
		for _, region in pairs({ settingsFrame.scrollFrame.content:GetRegions() }) do
			region:Hide()
		end

		-- Update selected feature
		selected = index
		local feature = features[index]

		-- Get accent color
		local accentColor = GetAccentColor()

		-- Add a horizontal line at the top
		local line = settingsFrame.scrollFrame.content:CreateTexture(nil, "ARTWORK")
		line:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.6)
		line:SetSize(250, 1)
		line:SetPoint("TOPLEFT", settingsFrame.scrollFrame.content, "TOPLEFT", 5, -5)

		-- Create feature-specific settings
		local module = ns.modules[feature.id]
		if module then
			Debug("Showing settings for module: " .. module.name)
			
			-- Special handling for Shadow module - don't create extra checkboxes
			if module.id == "Shadow" then
				Debug("Calling CreateSettings for Shadow module")
				if module.CreateSettings and type(module.CreateSettings) == "function" then
					module:CreateSettings(settingsFrame.scrollFrame.content)
				end
				return -- Early return for Shadow module
			end
			
			-- For other modules, create an enable checkbox with native WoW UI
			if module.id ~= "Shadow" then
				local enableCb = CreateFrame("CheckButton", nil, settingsFrame.scrollFrame.content, "UICheckButtonTemplate")
				enableCb:SetSize(24, 24)
				enableCb:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 5, -10)
				
				enableCb.text = enableCb:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
				enableCb.text:SetText("Enable " .. module.name)
				enableCb.text:SetPoint("LEFT", enableCb, "RIGHT", 2, 0)
				
				-- Make sure we use the right property name for the enabled state with proper nil check
				local enabledProperty = module.id .. "Enabled"
				enableCb:SetChecked(CellAdditionsDB[enabledProperty] == nil or CellAdditionsDB[enabledProperty])
				
				enableCb:SetScript("OnClick", function(self)
					-- Call the module's SetEnabled function if it exists
					if module.SetEnabled and type(module.SetEnabled) == "function" then
						module:SetEnabled(self:GetChecked())
					else
						-- Fallback if module doesn't have SetEnabled function
						CellAdditionsDB[module.id .. "Enabled"] = self:GetChecked()
						Debug(module.name .. " " .. (self:GetChecked() and "enabled" or "disabled"))
					end
				end)

				-- If the module has a CreateSettings function, call it to add more settings
				if module.CreateSettings and type(module.CreateSettings) == "function" then
					module:CreateSettings(settingsFrame.scrollFrame.content, enableCb)
				end
			end
		end
	end

	-- Function to highlight a list item
	function ListHighlightFn(index)
		-- Update button states
		for i, button in ipairs(listButtons) do
			button:SetButtonState(i == index and "PUSHED" or "NORMAL")
		end

		-- Show settings for the selected feature
		ShowFeatureSettings(index)
	end

	-- Make the function available in the namespace
	ns.ListHighlightFn = ListHighlightFn

	-- Load the feature list
	LoadFeatureList()

	-- Reset button removed as requested

	-- Add version text with accent color
	local versionText = panel:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	versionText:SetText("Version: 1.0")
	versionText:SetTextColor(GetAccentColor()[1], GetAccentColor()[2], GetAccentColor()[3], 0.7)
	versionText:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 10)

	-- Store the panel reference
	Cell.frames.additionsPanel = panel

	-- Select the first feature by default
	if listButtons[1] then
		ListHighlightFn(1)
	end

	return panel
end

-- Create custom utilities menu that appears on hover
local function CreateCustomUtilitiesMenu(parent)
	-- Create the menu container frame
	local menu = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Cell.StylizeFrame(menu, { 0, 1, 0, 0.1 }, { 0, 0, 0, 1 })
	menu:SetPoint("TOPLEFT", parent, "TOPRIGHT", 1, 0)
	menu:Hide()

	-- Apply Cell styling
	Cell.StylizeFrame(menu, nil, Cell.GetAccentColorTable())

	-- Calculate width for the button text
	local dummyText = menu:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
	dummyText:SetText("Additions") -- Use the longest text for sizing
	local width = ceil(dummyText:GetStringWidth() + 25) -- Increase padding for better appearance

	-- Menu buttons
	local buttons = {}

	-- Menu items with their functionality callbacks
	local menuItems = {
		{
			text = "Raid Tools",
			id = "raidTools",
			callback = function()
				-- Hide the menu
				menu:Hide()

				-- Store the current utility
				CellAdditionsDB.currentTab = "raidTools"

				-- Click the original utilities button
				for _, child in pairs({ Cell.frames.optionsFrame:GetChildren() }) do
					if child:IsObjectType("Button") and child.id and child.id == "utilities" then
						-- Simulate clicking the button
						if child:GetScript("OnClick") then
							child:GetScript("OnClick")(child)
						end
						break
					end
				end

				-- Show raid tools content
				C_Timer.After(0.1, function()
					local listFrame = GetUtilityListFrame()
					if listFrame and listFrame.buttons and listFrame.buttons["raidTools"] then
						listFrame.buttons["raidTools"]:Click()
					end
				end)
			end,
		},
		{
			text = "Spell Request",
			id = "spellRequest",
			callback = function()
				menu:Hide()
				-- Store the current utility
				CellAdditionsDB.currentTab = "spellRequest"

				-- Click the original utilities button
				for _, child in pairs({ Cell.frames.optionsFrame:GetChildren() }) do
					if child:IsObjectType("Button") and child.id and child.id == "utilities" then
						-- Simulate clicking the button
						if child:GetScript("OnClick") then
							child:GetScript("OnClick")(child)
						end
						break
					end
				end

				-- Show spell request content
				C_Timer.After(0.1, function()
					local listFrame = GetUtilityListFrame()
					if listFrame and listFrame.buttons and listFrame.buttons["spellRequest"] then
						listFrame.buttons["spellRequest"]:Click()
					end
				end)
			end,
		},
		{
			text = "Dispel Request",
			id = "dispelRequest",
			callback = function()
				menu:Hide()
				-- Store the current utility
				CellAdditionsDB.currentTab = "dispelRequest"

				-- Click the original utilities button
				for _, child in pairs({ Cell.frames.optionsFrame:GetChildren() }) do
					if child:IsObjectType("Button") and child.id and child.id == "utilities" then
						-- Simulate clicking the button
						if child:GetScript("OnClick") then
							child:GetScript("OnClick")(child)
						end
						break
					end
				end

				-- Show dispel request content
				C_Timer.After(0.1, function()
					local listFrame = GetUtilityListFrame()
					if listFrame and listFrame.buttons and listFrame.buttons["dispelRequest"] then
						listFrame.buttons["dispelRequest"]:Click()
					end
				end)
			end,
		},
		{
			text = "Quick Assist",
			id = "quickAssist",
			callback = function()
				menu:Hide()
				-- Store the current utility
				CellAdditionsDB.currentTab = "quickAssist"

				-- Click the original utilities button
				for _, child in pairs({ Cell.frames.optionsFrame:GetChildren() }) do
					if child:IsObjectType("Button") and child.id and child.id == "utilities" then
						-- Simulate clicking the button
						if child:GetScript("OnClick") then
							child:GetScript("OnClick")(child)
						end
						break
					end
				end

				-- Show quick assist content
				C_Timer.After(0.1, function()
					local listFrame = GetUtilityListFrame()
					if listFrame and listFrame.buttons and listFrame.buttons["quickAssist"] then
						listFrame.buttons["quickAssist"]:Click()
					end
				end)
			end,
		},
		{
			text = "Quick Cast",
			id = "quickCast",
			callback = function()
				menu:Hide()
				-- Store the current utility
				CellAdditionsDB.currentTab = "quickCast"

				-- Click the original utilities button
				for _, child in pairs({ Cell.frames.optionsFrame:GetChildren() }) do
					if child:IsObjectType("Button") and child.id and child.id == "utilities" then
						-- Simulate clicking the button
						if child:GetScript("OnClick") then
							child:GetScript("OnClick")(child)
						end
						break
					end
				end

				-- Show quick cast content
				C_Timer.After(0.1, function()
					local listFrame = GetUtilityListFrame()
					if listFrame and listFrame.buttons and listFrame.buttons["quickCast"] then
						listFrame.buttons["quickCast"]:Click()
					end
				end)
			end,
		},
		{
			text = "Additions",
			id = "additions",
			callback = function()
				Debug("Additions option clicked!")
				menu:Hide()

				-- Store the current utility
				CellAdditionsDB.currentTab = "additions"

				-- Show the Cell options frame if not already visible
				if Cell.funcs.ShowOptionsFrame then
					Cell.funcs.ShowOptionsFrame()
				end

				-- Instead of manually hiding tabs, let's fire Cell's event to switch to utilities tab
				-- Then we'll hook into that event in our RegisterWithCellTabSystem function
				C_Timer.After(0.1, function()
					-- First show the utilities tab
					if Cell.funcs.ShowUtilitiesTab then
						Cell.funcs.ShowUtilitiesTab()

						-- Then fire our custom event to show our panel
						Cell.Fire("CellAdditions_ShowAdditionsPanel")
					end
				end)
			end,
		},
	}

	-- Create a button for our menu
	local function CreateMenuButton(item, index)
		local btn = Cell.CreateButton(menu, item.text, "transparent-accent", { 20, 20 }, true)
		btn.id = item.id
		if index == 1 then
			btn:SetPoint("TOPLEFT")
			btn:SetPoint("TOPRIGHT")
		else
			btn:SetPoint("TOPLEFT", buttons[index - 1], "BOTTOMLEFT")
			btn:SetPoint("TOPRIGHT", buttons[index - 1], "BOTTOMRIGHT")
		end

		-- Set the click handler to the provided callback
		btn:SetScript("OnClick", function()
			Debug("Menu button clicked: " .. item.text)
			if item.callback then
				item.callback()
			end
		end)

		-- Add hover logging too
		btn:HookScript("OnEnter", function()
			Debug("Mouse entered menu item: " .. item.text)
		end)

		return btn
	end

	-- Add menu items based on game version
	local itemCount = Cell.isRetail and 6 or 3
	for i = 1, itemCount do
		buttons[i] = CreateMenuButton(menuItems[i], i)
	end

	-- Size the menu - make sure it's large enough for all items
	P.Size(menu, width, 20 * itemCount)

	return menu
end

-- Replace the utilities button with our own
local function AddReplacementUtilitiesButton()
	-- Wait for Cell to be fully loaded
	C_Timer.After(1, function()
		Debug("Checking if Cell is loaded...")
		-- Make sure Cell is loaded
		if not Cell or not Cell.loaded then
			Debug("Cell not loaded yet, retrying in 1 second")
			C_Timer.After(1, AddReplacementUtilitiesButton)
			return
		end
		Debug("Cell is loaded, proceeding with button replacement")

		-- Get reference to the options frame
		local optionsFrame = Cell.frames.optionsFrame
		if not optionsFrame then
			Debug("Cell options frame not found, retrying in 1 second")
			C_Timer.After(1, AddReplacementUtilitiesButton)
			return
		end

		-- First, find the original utilities button
		local origUtilitiesBtn
		for _, child in pairs({ optionsFrame:GetChildren() }) do
			if child:IsObjectType("Button") and child.id and child.id == "utilities" then
				origUtilitiesBtn = child
				break
			end
		end

		if not origUtilitiesBtn then
			Debug("Original Utilities button not found, retrying in 1 second")
			C_Timer.After(1, AddReplacementUtilitiesButton)
			return
		end

		-- Create our replacement button at exactly the same position
		local newUtilitiesBtn = Cell.CreateButton(
			optionsFrame,
			L["Utilities"],
			"accent-hover",
			{ 105, 20 },
			nil,
			nil,
			"CELL_FONT_WIDGET_TITLE",
			"CELL_FONT_WIDGET_TITLE_DISABLE"
		)
		newUtilitiesBtn.id = "utilities" -- Use the same ID

		-- Make it look and act exactly like the original button
		newUtilitiesBtn:SetSize(origUtilitiesBtn:GetSize())
		local point, relativeTo, relativePoint, xOfs, yOfs = origUtilitiesBtn:GetPoint()
		newUtilitiesBtn:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)

		-- Copy any additional points
		for i = 2, origUtilitiesBtn:GetNumPoints() do
			local point, relativeTo, relativePoint, xOfs, yOfs = origUtilitiesBtn:GetPoint(i)
			newUtilitiesBtn:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
		end

		-- Make it draggable like the original
		newUtilitiesBtn:RegisterForDrag("LeftButton")
		newUtilitiesBtn:SetScript("OnDragStart", function()
			optionsFrame:StartMoving()
			optionsFrame:SetUserPlaced(false)
		end)
		newUtilitiesBtn:SetScript("OnDragStop", function()
			optionsFrame:StopMovingOrSizing()
			P.PixelPerfectPoint(optionsFrame)
			P.SavePosition(optionsFrame, Cell.vars.db["optionsFramePosition"])
		end)

		-- Create the custom utilities menu
		local customMenu = CreateCustomUtilitiesMenu(newUtilitiesBtn)

		-- Add hover behavior
		newUtilitiesBtn:HookScript("OnEnter", function()
			Debug("Mouse entered utilities button")
			customMenu:SetFrameStrata("TOOLTIP")
			customMenu:Show()
			Debug("Menu shown")
		end)

		-- Set proper click handler to open the utilities panel
		newUtilitiesBtn:SetScript("OnClick", function()
			Debug("Utilities button clicked - opening utilities panel")

			-- Show the options frame first
			if Cell.funcs.ShowOptionsFrame then
				Cell.funcs.ShowOptionsFrame()
			end

			-- Then show the utilities tab specifically
			if Cell.funcs.ShowUtilitiesTab then
				Cell.funcs.ShowUtilitiesTab()
				Debug("Opened utilities tab")
			else
				Debug("ERROR: Cell.funcs.ShowUtilitiesTab is nil")
			end

			-- After the tab is shown, show the current utility
			-- Either use the one stored in our settings, or default to raidTools
			C_Timer.After(0.3, function() -- Increased delay to give more time for frames to load
				local success, errorMsg = pcall(function()
					local utilityToShow = CellAdditionsDB.currentTab or "raidTools"
					Debug("Showing utility: " .. utilityToShow)

					-- Special handling for the "additions" tab
					if utilityToShow == "additions" then
						Debug("Showing additions panel via custom event")

						-- Fire our custom event to show the Additions panel
						-- Check if Cell.Fire function signature has changed in r253
						if Cell.Fire then
							pcall(function()
								Cell.Fire("CellAdditions_ShowAdditionsPanel")
							end)
						end

						return -- Skip the rest since we're showing our own panel
					end

					-- For regular utilities, fire the Cell event to show the specific utility
					-- Check if Cell.Fire function signature has changed in r253
					if Cell.Fire then
						pcall(function()
							Cell.Fire("ShowUtilitySettings", utilityToShow)
						end)
					end

					-- Also click the corresponding button in the list if available
					local listFrame = GetUtilityListFrame()
					Debug("List frame found: " .. (listFrame and "yes" or "no"))
					if listFrame then
						Debug("Buttons available: " .. (listFrame.buttons and "yes" or "no"))
					end

					if listFrame and listFrame.buttons and listFrame.buttons[utilityToShow] then
						Debug("Clicking button for: " .. utilityToShow)
						listFrame.buttons[utilityToShow]:Click()
					else
						Debug("Button for " .. utilityToShow .. " not found")
					end
				end)

				if not success then
					Debug("Error showing utility: " .. (errorMsg or "unknown error"))
				end
			end)
		end)

		-- More reliable hover behavior with delayed hide
		local isMouseOverFrames = function()
			return customMenu:IsMouseOver() or newUtilitiesBtn:IsMouseOver()
		end

		local hideTimer = nil

		local function onLeave()
			Debug("Mouse left button/menu area")
			if hideTimer then
				hideTimer:Cancel()
			end

			hideTimer = C_Timer.NewTimer(0.2, function()
				if not isMouseOverFrames() then
					customMenu:Hide()
					Debug("Menu hidden")
					hideTimer = nil
				end
			end)
		end

		customMenu:HookScript("OnLeave", onLeave)
		newUtilitiesBtn:HookScript("OnLeave", onLeave)

		-- Keep track of the original button and our new button
		ns.origUtilitiesBtn = origUtilitiesBtn
		ns.newUtilitiesBtn = newUtilitiesBtn
		ns.customMenu = customMenu

		-- Now completely replace the original button
		origUtilitiesBtn:SetParent(nil) -- Remove from the UI
		origUtilitiesBtn:Hide()

		Debug(
			"Successfully replaced Cell's Utilities button with dimensions: "
				.. newUtilitiesBtn:GetWidth()
				.. "x"
				.. newUtilitiesBtn:GetHeight()
		)
	end)
end

-- Register for Cell's tab system
local function RegisterWithCellTabSystem()
	-- Check if Cell has the new callback system (r253+)
	if not Cell or not Cell.RegisterCallback then
		Debug("ERROR: Cell.RegisterCallback not found. Cell may be outdated or not properly loaded.")
		return
	end
	
	-- Register our callback to hook into tab switching
	Cell.RegisterCallback("ShowOptionsTab", "CellAdditions_ShowTab", function(_, tab)
		-- Check if tab is nil and provide a default
		if tab == nil then
			Debug("WARNING: Received nil tab parameter")
			tab = "general" -- Default to general tab
		end
		
		Debug("Tab switch to: " .. tostring(tab))

		-- Always hide our panel first to prevent overlapping
		if Cell.frames.additionsPanel then
			Cell.frames.additionsPanel:Hide()
		end
		
		-- Restore original frame height if we're not showing our custom tab
		if tab ~= "custom_additions" and Cell.frames.optionsFrame and ns.originalOptionsFrameHeight then
			Debug("Restoring original options frame height")
			Cell.frames.optionsFrame:SetHeight(ns.originalOptionsFrameHeight)
		end

		-- Check if it's our custom tab
		if tab == "custom_additions" then
			-- Hide all standard Cell tabs
			if Cell.frames.generalTab then
				Cell.frames.generalTab:Hide()
			end
			if Cell.frames.appearanceTab then
				Cell.frames.appearanceTab:Hide()
			end
			if Cell.frames.layoutsTab then
				Cell.frames.layoutsTab:Hide()
			end
			if Cell.frames.clickCastingsTab then
				Cell.frames.clickCastingsTab:Hide()
			end
			if Cell.frames.indicatorsTab then
				Cell.frames.indicatorsTab:Hide()
			end
			if Cell.frames.debuffsTab then
				Cell.frames.debuffsTab:Hide()
			end
			if Cell.frames.utilitiesTab then
				Cell.frames.utilitiesTab:Hide()
			end
			if Cell.frames.aboutTab then
				Cell.frames.aboutTab:Hide()
			end

			-- Show our panel
			if Cell.frames.additionsPanel then
				Cell.frames.additionsPanel:Show()
			end
		else
			-- For other tabs, make sure the corresponding tab is shown
			if type(tab) == "string" then
				local tabFrameName = tab .. "Tab"
				if Cell.frames[tabFrameName] then
					Cell.frames[tabFrameName]:Show()
					Debug("Showing tab frame: " .. tabFrameName)
				end
			else
				Debug("WARNING: Invalid tab type: " .. type(tab))
			end
		end
	end)

	-- Also hook into the utilities tab specifically since it's the most problematic
	Cell.RegisterCallback("ShowUtilitySettings", "CellAdditions_HidePanel", function(_, utilityName)
		-- Always hide our panel when showing utilities
		if Cell.frames.additionsPanel then
			Cell.frames.additionsPanel:Hide()
			Debug("Hiding Additions panel due to utility switch: " .. tostring(utilityName))
		end

		-- Make sure the utilities tab is visible
		if Cell.frames.utilitiesTab then
			Cell.frames.utilitiesTab:Show()
			Debug("Showing utilities tab")
		end
	end)

	-- Register a callback for our custom event to show the Additions panel
	Cell.RegisterCallback("CellAdditions_ShowAdditionsPanel", "CellAdditions_ShowAdditionsPanel", function(_)
		Debug("CellAdditions_ShowAdditionsPanel event triggered")

		-- We need to make sure the right frames are visible
		-- First, find out which tab is currently selected
		local currentTab = nil
		for _, tabName in ipairs({
			"general",
			"appearance",
			"layouts",
			"clickCastings",
			"indicators",
			"debuffs",
			"utilities",
			"about",
		}) do
			local tabButton = nil
			-- Find the tab button
			for _, child in pairs({ Cell.frames.optionsFrame:GetChildren() }) do
				if child:IsObjectType("Button") and child.id and child.id == tabName then
					tabButton = child
					break
				end
			end

			if tabButton and tabButton:GetButtonState() == "PUSHED" then
				currentTab = tabName
				break
			end
		end

		Debug("Current tab detected: " .. tostring(currentTab))

		-- Now hide all content frames
		if Cell.frames.generalTab then
			Cell.frames.generalTab:Hide()
		end
		if Cell.frames.appearanceTab then
			Cell.frames.appearanceTab:Hide()
		end
		if Cell.frames.layoutsTab then
			Cell.frames.layoutsTab:Hide()
		end
		if Cell.frames.clickCastingsTab then
			Cell.frames.clickCastingsTab:Hide()
		end
		if Cell.frames.indicatorsTab then
			Cell.frames.indicatorsTab:Hide()
		end
		if Cell.frames.debuffsTab then
			Cell.frames.debuffsTab:Hide()
		end
		if Cell.frames.aboutTab then
			Cell.frames.aboutTab:Hide()
		end

		-- Handle utilities tab separately
		if Cell.frames.utilitiesTab then
			-- Hide all children of the utilities tab
			for _, child in pairs({ Cell.frames.utilitiesTab:GetChildren() }) do
				if child:IsObjectType("Frame") then
					child:Hide()
				end
			end

			-- If utilities is the current tab, keep it visible
			if currentTab == "utilities" then
				Cell.frames.utilitiesTab:Show()
			else
				Cell.frames.utilitiesTab:Hide()
			end
		end

		-- Now show our panel
		if Cell.frames.additionsPanel then
			-- Check for any visible utility frames and hide them
			if Cell.frames.utilitiesTab then
				for _, child in pairs({ Cell.frames.utilitiesTab:GetChildren() }) do
					if child:IsObjectType("Frame") and child:IsVisible() then
						Debug("Hiding visible utility frame")
						child:Hide()
					end
				end
			end

			-- Hide other content frames, but don't touch the tab frames themselves
			if Cell.frames.utilitiesTab then
				-- For utilities tab, only hide its children
				for _, child in pairs({ Cell.frames.utilitiesTab:GetChildren() }) do
					if child:IsObjectType("Frame") and child:IsVisible() then
						child:Hide()
						Debug("Hiding utility child frame")
					end
				end
			end

			-- Find the content area of the options frame
			local contentFrame = Cell.frames.optionsFrame.content
			local optionsFrame = Cell.frames.optionsFrame

			-- Expand the main options frame to give more space for our content
			if optionsFrame then
				-- Store original dimensions if not already stored
				if not ns.originalOptionsFrameWidth then
					ns.originalOptionsFrameWidth = optionsFrame:GetWidth()
					ns.originalOptionsFrameHeight = optionsFrame:GetHeight()
					Debug("Stored original options frame dimensions: " .. ns.originalOptionsFrameWidth .. "x" .. ns.originalOptionsFrameHeight)
				end
				
				-- Only extend the height to accommodate our settings
				local newHeight = 550 -- Taller frame for our content
				
				Debug("Extending options frame height to: " .. newHeight)
				optionsFrame:SetHeight(newHeight)
			end

			-- Reset parent and position to the content area, not the entire options frame
			if contentFrame then
				Cell.frames.additionsPanel:SetParent(contentFrame)
				Cell.frames.additionsPanel:ClearAllPoints()
				Cell.frames.additionsPanel:SetAllPoints(contentFrame)
				Debug("Panel parented to content area")

				-- Resize the content frame to fit our content if needed
				if Cell.frames.additionsPanel.settingsBox then
					local height = Cell.frames.additionsPanel.settingsBox:GetHeight() + 100 -- Add padding for title and other elements
					Debug("Setting content frame height to: " .. height)
					contentFrame:SetHeight(height)
				end
			else
				-- Fallback if content frame not found
				Cell.frames.additionsPanel:SetParent(Cell.frames.optionsFrame)
				Cell.frames.additionsPanel:ClearAllPoints()
				-- Position below the tab bar instead of covering the entire frame
				Cell.frames.additionsPanel:SetPoint("TOPLEFT", Cell.frames.optionsFrame, "TOPLEFT", 5, -25)
				Cell.frames.additionsPanel:SetPoint("BOTTOMRIGHT", Cell.frames.optionsFrame, "BOTTOMRIGHT", -5, 5)
				Debug("Panel parented to options frame with offset")

				-- Resize the options frame to fit our content if needed
				if Cell.frames.additionsPanel.settingsBox then
					local height = Cell.frames.additionsPanel.settingsBox:GetHeight() + 100 -- Add padding for title and other elements
					Debug("Setting options frame height to: " .. height)
					P.Height(Cell.frames.optionsFrame, height)
				end
			end

			Cell.frames.additionsPanel:Show()
			Debug("Showing Additions panel via custom event")

			-- Update button state
			UpdateAdditionsButtonState(true)
		else
			Debug("ERROR: additionsPanel not found!")
		end
	end)

	-- Add our tab height to Cell's tabHeight table
	local env = getfenv(Cell.Fire)
	if env and env.tabHeight then
		-- Use the height of our settings box plus padding
		local tabHeight = 550 -- Default height increased to match our panel height
		if Cell.frames.additionsPanel and Cell.frames.additionsPanel.settingsBox then
			tabHeight = Cell.frames.additionsPanel.settingsBox:GetHeight() + 120 -- Increased padding
		end
		env.tabHeight["custom_additions"] = tabHeight
		Debug("Tab height registered successfully: " .. tabHeight)
	else
		Debug("Failed to register tab height")
	end
end

-- Function to populate features list from modules
local function PopulateFeatures()
	-- Clear existing features
	wipe(features)

	-- Add each module as a feature
	for id, module in pairs(ns.modules) do
		table.insert(features, {
			name = module.name,
			id = module.id,
			description = module.description,
		})
	end

	-- Sort features alphabetically by name
	table.sort(features, function(a, b)
		return a.name < b.name
	end)

	Debug("Populated " .. #features .. " features from modules")
end

-- Initialize when addon loads
local function Initialize()
	if not Cell then
		Debug("Cell addon not found. Make sure Cell is installed and enabled.")
		return
	end

	Debug("CellAdditions loaded successfully.")

	-- Initialize the database
	InitDB() -- Ensures CellAdditionsDB and CellAdditionsDB.shadowConfig are ready

	-- Load module files
	Debug("Loading modules...")
	-- Modules are loaded automatically via the TOC file (like Shadow.lua)

	-- Initialize all registered modules (this calls module:Initialize() if it exists)
	-- ns.InitializeModules() -- The new Shadow.lua doesn't have Initialize().
	-- Let's check if ns.InitializeModules() is still needed for other modules.
	-- For now, we assume other modules might still use it. If ns.addon.Shadow is populated
	-- by WoW loading the file, we don't need to call an Initialize on it for AceConfig.
	if ns.InitializeModules then
		ns.InitializeModules()
	end

	-- Populate features from modules
	PopulateFeatures()

	-- Create our own content tab
	CreateAdditionsPanel()

	-- Add our replacement utilities button
	AddReplacementUtilitiesButton()

	-- Register with Cell's tab system
	RegisterWithCellTabSystem()
	
	-- Setup AceConfig for Shadow Module
	if ns.addon and ns.addon.Shadow and ns.addon.Shadow.GetOptions then
		local AceConfig = LibStub("AceConfig-3.0", true)
		local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)

		if AceConfig and AceConfigDialog then
			local shadowOptionsTable = ns.addon.Shadow:GetOptions()
			if shadowOptionsTable then
				AceConfig:RegisterOptionsTable("CellAdditions_Shadow", shadowOptionsTable)
				AceConfigDialog:AddToBlizOptions("CellAdditions_Shadow", "Shadows", "CellAdditions")
				Debug("CellAdditions Shadow options registered with AceConfig and added to Blizzard options.")
			else
				Debug("CellAdditions ERROR: Could not get Shadow options table.")
			end
		else
			Debug("CellAdditions ERROR: AceConfig-3.0 or AceConfigDialog-3.0 not found. Shadow options will not be available.")
		end
	else
		Debug("CellAdditions WARN: Shadow module or GetOptions not found. Shadow options panel will not be created.")
	end

	-- Add additional hooks to ensure our panel is hidden when it should be
	hooksecurefunc(Cell.frames.optionsFrame, "Hide", function()
		if Cell.frames.additionsPanel then
			Cell.frames.additionsPanel:Hide()
			Debug("Hiding Additions panel due to options frame hide")
		end
	end)

	-- Keep the options frame at original width but allow height to adjust
	C_Timer.After(0.5, function()
		local optionsFrame = Cell.frames.optionsFrame
		if optionsFrame then
			-- Keep the original frame width
			local originalWidth = 432
			P.Width(optionsFrame, originalWidth)
			Debug("Maintained original frame width at " .. originalWidth)

			-- Store the original height for reference
			ns.originalFrameHeight = optionsFrame:GetHeight()
			Debug("Stored original frame height: " .. ns.originalFrameHeight)
		end
	end)
end

-- Register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" then
		if addon == addonName then
			-- Wait a bit to ensure Cell is fully loaded
			C_Timer.After(2, Initialize)
		end
	end
end) 

-- If Cell is already loaded when this addon loads, initialize
if Cell then
	C_Timer.After(2, Initialize)
end

-- Function to get a module's settings frame
function ns.GetModuleSettingsFrame(moduleId)
	Debug("Getting settings frame for module: " .. moduleId)
	
	-- Make sure the panel exists and has a settings frame
	if not panel or not panel.settingsFrame then
		Debug("ERROR: Panel or settings frame not found")
		return nil
	end
	
	-- Return the settings frame's content
	local content = panel.settingsFrame.scrollFrame.content
	print("[DEBUG] ns.GetModuleSettingsFrame returns:", content, type(content), content and content.GetObjectType and content:GetObjectType())
	return content
end
