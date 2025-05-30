-- CellAdditions English Localization
-- Base language file

local _, ns = ...

-- Create localization table
ns.L = setmetatable({
  -- General
  ["CellAdditions"] = "CellAdditions",
  ["Features"] = "Features",
  ["Settings"] = "Settings",
  ["Version"] = "Version",
  ["About"] = "About",
  ["Enable"] = "Enable",
  ["Enabled"] = "Enabled",
  ["Disabled"] = "Disabled",

  -- Main UI
  ["Additions"] = "Additions",
  ["No settings available for this feature"] = "No settings available for this feature",

  -- Clicker Module
  ["Clicker"] = "Clicker",
  ["Enhanced click functionality with customizable textures for unit frames"] = "Enhanced click functionality with customizable textures for unit frames",
  ["Clicker Settings"] = "Clicker Settings",
  ["General Settings"] = "General Settings",
  ["Position Settings"] = "Position Settings",
  ["Texture Settings"] = "Texture Settings",
  ["Advanced Settings"] = "Advanced Settings",

  -- Clicker Settings
  ["Use Custom Size"] = "Use Custom Size",
  ["Width"] = "Width",
  ["Height"] = "Height",
  ["X Offset"] = "X Offset",
  ["Y Offset"] = "Y Offset",
  ["Enable Texture Overlay"] = "Enable Texture Overlay",
  ["Texture"] = "Texture",
  ["No Texture"] = "No Texture",
  ["Refresh Texture List"] = "Refresh Texture List",
  ["Scans the texture folder for new files"] = "Scans the texture folder for new files",
  ["Texture Alpha"] = "Texture Alpha",
  ["Show Debug Overlay"] = "Show Debug Overlay",

  -- Clicker Messages
  ["Texture enabled"] = "Texture enabled",
  ["Selected texture"] = "Selected texture",
  ["Texture list refreshed"] = "Texture list refreshed",
  ["textures found"] = "textures found",
  ["Clicker module enabled"] = "Clicker module enabled",
  ["Clicker module disabled"] = "Clicker module disabled",

  -- Shadow Module
  ["Shadow"] = "Shadow",
  ["Add dynamic shadow effects to Cell unit frames and bars"] = "Add dynamic shadow effects to Cell unit frames and bars",
  ["Shadow Settings"] = "Shadow Settings",
  ["Cell"] = "Cell",
  ["Cell - Unit Frames"] = "Cell - Unit Frames",

  -- Shadow Settings
  ["Enable Shadow"] = "Enable Shadow",
  ["Shadow Size"] = "Shadow Size",
  ["Shadow Color"] = "Shadow Color",
  ["Shadow Offset X"] = "Shadow Offset X",
  ["Shadow Offset Y"] = "Shadow Offset Y",
  ["Shadow Quality"] = "Shadow Quality",
  ["Use Standalone Cell Shadow"] = "Use Standalone Cell Shadow",
  ["Health Bar Shadow"] = "Health Bar Shadow",
  ["Power Bar Shadow"] = "Power Bar Shadow",
  ["Use Party Button Shadow"] = "Use Party Button Shadow",
  ["Use Raid Button Shadow"] = "Use Raid Button Shadow",

  -- Shadow Unit Frames
  ["Player"] = "Player",
  ["Target"] = "Target",
  ["Target of Target"] = "Target of Target",
  ["Focus"] = "Focus",
  ["Pet"] = "Pet",

  -- Shadow Frame Types
  ["Solo Frame"] = "Solo Frame",
  ["Party Frames"] = "Party Frames",
  ["Raid Frames"] = "Raid Frames",
  ["Player Frame"] = "Player Frame",
  ["Target Frame"] = "Target Frame",
  ["Target's Target Frame"] = "Target's Target Frame",
  ["Focus Frame"] = "Focus Frame",
  ["Pet Frame"] = "Pet Frame",

  -- Colors
  ["Red"] = "Red",
  ["Green"] = "Green",
  ["Blue"] = "Blue",
  ["Alpha"] = "Alpha",

  -- Quality levels
  ["Low"] = "Low",
  ["Medium"] = "Medium",
  ["High"] = "High",
  ["Ultra"] = "Ultra",

  -- Messages
  ["Module initialized successfully"] = "Module initialized successfully",
  ["Settings saved"] = "Settings saved",
  ["Settings loaded"] = "Settings loaded",
  ["Error"] = "Error",
  ["Warning"] = "Warning",
  ["Info"] = "Info",

  -- Utilities Menu
  ["Raid Tools"] = "Raid Tools",
  ["Spell Request"] = "Spell Request",
  ["Dispel Request"] = "Dispel Request",
  ["Quick Assist"] = "Quick Assist",
  ["Quick Cast"] = "Quick Cast",
  ["Utilities"] = "Utilities",
}, {
  -- Metatable for fallback to key if translation not found
  __index = function(t, key) return key end,
})

-- Export for compatibility
_G.CellAdditions_L = ns.L
