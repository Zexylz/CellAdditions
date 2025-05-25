-- Use Lua 5.1 standard environment
std = "lua51"

-- Declare known globals used by the addon
globals = {
  "Cell",
  "CellAdditionsDB",
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
  "wipe",
  "SLASH_.*",
  "BINDING_HEADER_.*",
  "BINDING_NAME_.*",
  "UnitHealth",
  "UnitHealthMax",
  "UnitPower",
  "UnitPowerMax",
  "UnitClass",
  "CLASS_ICON_TCOORDS",
  -- Locales
  "LOCALE_deDE", "LOCALE_enUS", "LOCALE_esES", "LOCALE_frFR",
  "LOCALE_itIT", "LOCALE_koKR", "LOCALE_ptBR", "LOCALE_ruRU",
  "LOCALE_zhCN", "LOCALE_zhTW"
}

-- Allow unused function arguments (e.g. 'self' in method definitions)
unused_args = false

-- Ignore WoW API stub files cloned from external repo
exclude_files = {
  "WoWStubs/**"
}