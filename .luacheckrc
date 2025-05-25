-- Use Lua 5.1 standard environment
std = "lua51"

-- Declare known globals used by the addon
globals = {
  "Cell",
  "UnitButton",
  "CreateFrame",
  "GetTime",
  "C_Timer",
  "C_AddOns",
  "UIParent",
  "DEFAULT_CHAT_FRAME",
  "IsAddOnLoaded",
  "hooksecurefunc",
  "GetAddOnMetadata",
  "LibStub",
  "SLASH_.*",
  "BINDING_HEADER_.*",
  "BINDING_NAME_.*"
}

-- Allow unused function arguments (e.g. 'self' in method definitions)
unused_args = false

-- Ignore WoW API stub files cloned from external repo
exclude_files = {
  "WoWStubs/**"
}