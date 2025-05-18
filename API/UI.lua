local addonName, ns = ...
local Cell = ns.Cell

-- Create a UI API namespace
local UI = {}
ns.API = ns.API or {}
ns.API.UI = UI

-- UI Manager for internal use
local UIManager = {
    panels = {},
    widgets = {},
    callbacks = {},
}

-- ============================================================================
-- Frame Creation Functions
-- ============================================================================

-- Create a basic frame
function UI:CreateFrame(name, parent, template)
    -- Use Cell's frame creation if available, otherwise fall back to standard WoW
    if Cell and Cell.CreateFrame then
        return Cell.CreateFrame(name, parent, template)
    else
        return CreateFrame("Frame", name, parent, template)
    end
end

-- Create a button
function UI:CreateButton(name, parent, text, width, height)
    local button
    
    -- Use Cell's button creation if available
    if Cell and Cell.CreateButton then
        button = Cell.CreateButton(name, parent)
    else
        button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    end
    
    if text then button:SetText(text) end
    if width then button:SetWidth(width) end
    if height then button:SetHeight(height) end
    
    return button
end

-- Create a slider
function UI:CreateSlider(name, parent, min, max, step, width, height)
    local slider
    
    -- Make sure parent is a valid frame
    if not parent or not parent.GetObjectType then
        print("[CellAdditions] ERROR: Invalid parent frame passed to CreateSlider")
        return nil
    end
    
    -- Use Cell's slider creation if available
    if Cell and Cell.CreateSlider then
        -- Cell's CreateSlider function takes different parameters
        slider = Cell.CreateSlider(parent, min, max)
        
        -- Set step separately if provided
        if step then
            slider:SetValueStep(step)
        end
    else
        slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
        slider:SetMinMaxValues(min, max)
        if step then
            slider:SetValueStep(step)
        end
    end
    
    -- Set width and height if provided
    if width and slider.SetWidth then slider:SetWidth(width) end
    if height and slider.SetHeight then slider:SetHeight(height) end
    
    -- Store the name for our own reference
    slider.widgetName = name
    
    return slider
end

-- ============================================================================
-- Color Picker Functions
-- ============================================================================

-- Create a color swatch using Cell's color picker
function UI:CreateColorSwatch(parent, initialColor, callback, width, height)
    local swatch
    
    -- Make sure parent is a valid frame
    if not parent or type(parent) ~= "table" or not parent.GetObjectType then
        print("[CellAdditions] ERROR: Invalid parent frame passed to CreateColorSwatch")
        return nil
    end
    
    -- Use Cell's color picker if available
    if Cell and Cell.CreateColorPicker then
        -- Cell.CreateColorPicker(parent, label, hasOpacity, onChange, onConfirm)
        -- We'll use an empty label and handle the color change through our callback
        local hasOpacity = initialColor and initialColor.a ~= nil
        
        -- Create the color picker with appropriate callbacks
        swatch = Cell.CreateColorPicker(parent, "", hasOpacity, 
            -- onChange callback
            function(r, g, b, a)
                if callback then
                    local color = {r=r, g=g, b=b, a=a or 1}
                    callback(color)
                end
            end
        )
        
        -- Set the initial color if provided
        if initialColor then
            swatch:SetColor(initialColor.r, initialColor.g, initialColor.b, initialColor.a or 1)
        end
        
        -- Store the color for later retrieval
        swatch.color = initialColor or {r=1, g=1, b=1, a=1}
    else
        -- Fallback to our custom implementation if Cell's API is not available
        swatch = CreateFrame("Button", nil, parent)
        swatch:SetSize(width or 20, height or 20)
        
        -- Create the colored texture
        local texture = swatch:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints(swatch)
        swatch.texture = texture
        
        -- Create a border
        local border = swatch:CreateTexture(nil, "BACKGROUND")
        border:SetPoint("TOPLEFT", swatch, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.3, 0.3, 0.3, 1)
        swatch.border = border
        
        -- Set initial color if provided
        if initialColor then
            self:SetColorSwatchColor(swatch, initialColor)
        end
        
        -- Set up the callback if provided
        if callback then
            swatch:SetScript("OnClick", function()
                self:OpenColorPicker(swatch, callback)
            end)
        end
    end
    
    return swatch
end

-- Set the color of a color swatch
function UI:SetColorSwatchColor(swatch, color)
    if not swatch then return end
    
    -- Handle Cell's color swatch if that's what we're using
    if swatch.SetColor then
        swatch:SetColor(color.r, color.g, color.b, color.a or 1)
        return
    end
    
    -- Otherwise handle our custom swatch
    if swatch.texture then
        swatch.texture:SetColorTexture(color.r, color.g, color.b, color.a or 1)
    end
    
    -- Store the color on the swatch for later retrieval
    swatch.color = color
end

-- Get the color from a color swatch
function UI:GetColorSwatchColor(swatch)
    if not swatch then return {r=1, g=1, b=1, a=1} end
    
    -- Handle Cell's color swatch if that's what we're using
    if swatch.GetColor then
        local r, g, b, a = swatch:GetColor()
        return {r=r, g=g, b=b, a=a}
    end
    
    -- Otherwise return our stored color
    return swatch.color or {r=1, g=1, b=1, a=1}
end

-- Function to create a toggle with color picker
function UI:CreateToggleWithColorPicker(parent, label, initialState, initialColor, toggleCallback, colorCallback)
    -- Create a container frame
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(250, 30)
    
    -- Create the checkbox using Cell's API if available
    local checkbox
    if Cell and Cell.CreateCheckButton then
        checkbox = Cell.CreateCheckButton(parent, label)
        checkbox:SetChecked(initialState)
        checkbox:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        
        -- Set up the callback
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            if toggleCallback then
                toggleCallback(checked)
            end
        end)
    else
        -- Fallback to standard WoW UI
        checkbox = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        checkbox:SetChecked(initialState)
        
        -- Add the label
        _G[checkbox:GetName() .. "Text"]:SetText(label)
        
        -- Set up the callback
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            if toggleCallback then
                toggleCallback(checked)
            end
        end)
    end
    
    -- Create the color swatch with the correct parameter order
    -- parent, initialColor, callback, width, height
    local colorSwatch = self:CreateColorSwatch(
        container, 
        initialColor, 
        function(color)
            if colorCallback then
                colorCallback(color)
            end
        end,
        20, -- width
        20  -- height
    )
    
    -- Position the color swatch further to the right to match the layout in the screenshot
    -- Calculate the width of the checkbox and label
    local labelWidth = 0
    if checkbox.GetTextWidth then
        labelWidth = checkbox:GetTextWidth() or 100
    elseif checkbox:GetName() and _G[checkbox:GetName() .. "Text"] then
        labelWidth = _G[checkbox:GetName() .. "Text"]:GetWidth() or 100
    else
        labelWidth = 100 -- Default width if we can't determine it
    end
    
    -- Position the color swatch to the far right of the container
    colorSwatch:SetPoint("RIGHT", container, "RIGHT", -10, 0)
    
    return container, checkbox, colorSwatch
end

-- Open color picker for a swatch
function UI:OpenColorPicker(swatch, callback)
    if not swatch then return end
    
    -- Get the current color from the swatch
    local color = self:GetColorSwatchColor(swatch)
    local oldColor = CopyTable(color)
    
    -- Function to update the color
    local function UpdateColor()
        -- Get the selected color
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = OpacitySliderFrame:IsShown() and OpacitySliderFrame:GetValue() or 1
        
        -- Update the color
        color.r, color.g, color.b, color.a = r, g, b, a
        
        -- Update the swatch
        self:SetColorSwatchColor(swatch, color)
        
        -- Call the callback if provided
        if callback then
            callback(color)
        end
    end
    
    -- Function to cancel the color change
    local function CancelColor(previousValues)
        -- Restore the old color
        if previousValues then
            color.r, color.g, color.b, color.a = previousValues[1], previousValues[2], previousValues[3], previousValues[4]
            self:SetColorSwatchColor(swatch, color)
        else
            self:SetColorSwatchColor(swatch, oldColor)
        end
        
        -- Call the callback with the old color
        if callback then
            callback(color)
        end
    end
    
    -- Use the standard WoW color picker API
    ColorPickerFrame.previousValues = {color.r, color.g, color.b, color.a}
    ColorPickerFrame.func = UpdateColor
    ColorPickerFrame.opacityFunc = UpdateColor
    ColorPickerFrame.cancelFunc = CancelColor
    
    -- Set the initial color
    ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
    
    -- Set up opacity
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = color.a
    
    -- Show the color picker
    ColorPickerFrame:Hide() -- Hide first to reset the OnShow handler
    ColorPickerFrame:Show()
end

-- ============================================================================
-- Checkbox Functions
-- ============================================================================

-- Create a checkbox
function UI:CreateCheckbox(name, parent, text, initialValue)
    local checkbox
    
    -- Use Cell's checkbox if available
    if Cell and Cell.CreateCheckButton then
        -- Cell.CreateCheckButton expects (parent, text) parameters
        checkbox = Cell.CreateCheckButton(parent, text)
        -- Note: Cell's checkbox doesn't support setting a name directly
    else
        checkbox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
        checkbox.Text:SetText(text)
    end
    
    -- Set initial value if provided
    if initialValue ~= nil then
        checkbox:SetChecked(initialValue)
    end
    
    -- Store the name for our own reference
    checkbox.widgetName = name
    
    return checkbox
end

-- ============================================================================
-- Panel Functions
-- ============================================================================

-- Create a settings panel
function UI:CreateSettingsPanel(name, parent, title, width, height)
    local panel
    
    -- Use Cell's panel if available
    if Cell and Cell.CreatePanel then
        panel = Cell.CreatePanel(name, parent)
    else
        panel = CreateFrame("Frame", name, parent, "BackdropTemplate")
        panel:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        panel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        panel:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end
    
    -- Set size if provided
    if width and height then
        panel:SetSize(width, height)
    end
    
    -- Add title if provided
    if title then
        local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
        titleText:SetText(title)
        panel.titleText = titleText
    end
    
    return panel
end

-- ============================================================================
-- Higher-Level UI Components
-- ============================================================================

-- Function to create the main settings panel
function UI:CreateMainPanel(parent, title)
    -- Create the main settings panel
    local panel = self:CreateSettingsPanel("CellAdditionsMainPanel", parent, title or "CellAdditions Settings", 600, 500)
    
    -- Store the panel for later use
    UIManager.panels.main = panel
    
    return panel
end

-- Function to create a module settings panel
function UI:CreateModulePanel(parent, moduleName)
    -- Create the module settings panel
    local panel = self:CreateSettingsPanel("CellAdditions" .. moduleName .. "Panel", parent, moduleName .. " Settings", 600, 500)
    
    -- Store the panel for later use
    UIManager.panels[moduleName] = panel
    
    return panel
end

-- Function to create a toggle button
function UI:CreateToggleButton(parent, name, text, initialState, callback)
    -- Create the button
    local button = self:CreateButton(name, parent, text, 120, 25)
    
    -- Set up the toggle state
    button.state = initialState or false
    
    -- Update the button text based on state
    local function UpdateButtonText()
        button:SetText(text .. ": " .. (button.state and "ON" or "OFF"))
    end
    
    -- Initial text update
    UpdateButtonText()
    
    -- Set up the click handler
    button:SetScript("OnClick", function(self)
        -- Toggle the state
        self.state = not self.state
        
        -- Update the text
        UpdateButtonText()
        
        -- Call the callback if provided
        if callback then
            callback(self.state)
        end
    end)
    
    -- Store the button for later use
    UIManager.widgets[name] = button
    
    return button
end

-- Function to create a color picker with label
function UI:CreateColorPickerWithLabel(parent, name, label, initialColor, callback)
    -- Create a container frame
    local container = CreateFrame("Frame", name .. "Container", parent)
    container:SetSize(150, 25)
    
    -- Create the label
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", container, "LEFT", 0, 0)
    labelText:SetText(label)
    
    -- Create the color swatch
    local swatch = self:CreateColorSwatch(name, container, 20, 20, initialColor)
    swatch:SetPoint("LEFT", labelText, "RIGHT", 10, 0)
    
    -- Set up the click handler
    swatch:SetScript("OnClick", function(self)
        UI:OpenColorPicker(self, function(newColor)
            if callback then
                callback(newColor)
            end
        end)
    end)
    
    -- Store the color picker for later use
    UIManager.widgets[name] = {
        container = container,
        label = labelText,
        swatch = swatch
    }
    
    return container
end

-- Function to create a slider with label and value text
function UI:CreateSliderWithLabel(parent, name, label, min, max, step, initialValue, callback)
    -- Create a container frame
    local container = CreateFrame("Frame", name .. "Container", parent)
    container:SetSize(250, 50)
    
    -- Create the label
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    labelText:SetText(label)
    
    -- Create the slider - make sure parameters are in the right order
    -- Note: CreateSlider expects (name, parent, min, max, step, width, height)
    local sliderName = name or ("Slider_" .. label:gsub(" ", ""))
    local slider = self:CreateSlider(sliderName, container, min, max, step, 200)
    slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -5)
    
    -- Set initial value if provided
    if initialValue ~= nil then
        slider:SetValue(initialValue)
    end
    
    -- Create the value text
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueText:SetText(initialValue or min)
    
    -- Set up the value changed handler
    slider:SetScript("OnValueChanged", function(self, value)
        -- Round to nearest step if needed
        if step == math.floor(step) then
            value = math.floor(value + 0.5)
        else
            -- Round to the nearest step
            value = math.floor(value / step + 0.5) * step
        end
        
        -- Update the value text
        valueText:SetText(value)
        
        -- Call the callback if provided
        if callback then
            callback(value)
        end
    end)
    
    -- Store the slider for later use
    UIManager.widgets[name] = {
        container = container,
        label = labelText,
        slider = slider,
        valueText = valueText
    }
    
    return container
end

-- Function to create a checkbox with label
function UI:CreateCheckboxWithLabel(parent, name, label, initialValue, callback)
    -- Create the checkbox
    local checkbox = self:CreateCheckbox(name, parent, label, initialValue)
    
    -- Set up the click handler
    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        
        -- Call the callback if provided
        if callback then
            callback(checked)
        end
    end)
    
    -- Store the checkbox for later use
    UIManager.widgets[name] = checkbox
    
    return checkbox
end

-- Function to create a dropdown menu
function UI:CreateDropdownWithLabel(parent, name, label, items, initialValue, callback)
    -- Create a container frame
    local container = CreateFrame("Frame", name .. "Container", parent)
    container:SetSize(200, 50)
    
    -- Create the label
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    labelText:SetText(label)
    
    local dropdown = nil
    
    if Cell and Cell.CreateDropdown then
        -- Use Cell's dropdown
        dropdown = Cell.CreateDropdown(name, container)
        dropdown:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -5)
        
        -- Set up the items
        dropdown:SetItems(items)
        
        -- Set the initial value
        dropdown:SetValue(initialValue)
        
        -- Set up the callback
        dropdown:SetCallback(function(value)
            if callback then
                callback(value)
            end
        end)
    else
        -- Create a dropdown using WoW's built-in dropdown
        dropdown = CreateFrame("Frame", name, container, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", -15, -5)
        
        -- Set up the dropdown
        local function OnClick(self, arg1, arg2, checked)
            UIDropDownMenu_SetText(dropdown, self.value)
            
            -- Call the callback if provided
            if callback then
                callback(self.value)
            end
        end
        
        local function Initialize(self, level)
            local info = UIDropDownMenu_CreateInfo()
            
            for _, item in ipairs(items) do
                info.text = item
                info.value = item
                info.func = OnClick
                UIDropDownMenu_AddButton(info)
            end
        end
        
        UIDropDownMenu_Initialize(dropdown, Initialize)
        UIDropDownMenu_SetWidth(dropdown, 180)
        UIDropDownMenu_SetText(dropdown, initialValue)
    end
    
    -- Store the dropdown for later use
    UIManager.widgets[name] = {
        container = container,
        label = labelText,
        dropdown = dropdown
    }
    
    return container
end

-- Function to create a tab panel
function UI:CreateTabPanel(parent, name, tabs)
    -- Create the main container
    local container = CreateFrame("Frame", name, parent)
    container:SetSize(parent:GetWidth() - 40, parent:GetHeight() - 60)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -40)
    
    -- Create the tab buttons
    local tabButtons = {}
    local tabFrames = {}
    local tabWidth = math.min(100, (container:GetWidth() - 10) / #tabs)
    
    for i, tab in ipairs(tabs) do
        -- Create the tab button
        local button = self:CreateButton(name .. "Tab" .. i, parent, tab.name, tabWidth, 25)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 20 + (i-1) * (tabWidth + 5), -10)
        
        -- Create the tab content frame
        local frame = CreateFrame("Frame", name .. "Content" .. i, container)
        frame:SetAllPoints(container)
        frame:Hide()
        
        -- Store the tab info
        tabButtons[i] = button
        tabFrames[i] = frame
        
        -- Set up the click handler
        button:SetScript("OnClick", function()
            -- Hide all frames
            for j, frame in ipairs(tabFrames) do
                frame:Hide()
                tabButtons[j]:SetEnabled(true)
            end
            
            -- Show this frame
            frame:Show()
            button:SetEnabled(false)
            
            -- Call the callback if provided
            if tab.callback then
                tab.callback(frame)
            end
        end)
    end
    
    -- Show the first tab by default
    tabFrames[1]:Show()
    tabButtons[1]:SetEnabled(false)
    
    -- Store the tab panel for later use
    UIManager.widgets[name] = {
        container = container,
        tabs = tabButtons,
        frames = tabFrames
    }
    
    return {
        container = container,
        tabs = tabButtons,
        frames = tabFrames
    }
end

-- Function to register a callback
function UI:RegisterCallback(event, callback)
    if not UIManager.callbacks[event] then
        UIManager.callbacks[event] = {}
    end
    
    table.insert(UIManager.callbacks[event], callback)
end

-- Function to trigger a callback
function UI:TriggerCallback(event, ...)
    if not UIManager.callbacks[event] then return end
    
    for _, callback in ipairs(UIManager.callbacks[event]) do
        callback(...)
    end
end

-- Return the API
return UI
