-- Use Lua 5.1 standard (WoW uses Lua 5.1)
std = "lua51"

-- Globals used in WoW and your addon
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
  "LOCALE_deDE", "LOCALE_enUS", "LOCALE_esES", "LOCALE_frFR",
  "LOCALE_itIT", "LOCALE_koKR", "LOCALE_ptBR", "LOCALE_ruRU",
  "LOCALE_zhCN", "LOCALE_zhTW"
}

-- Allow unused function arguments (e.g. self)
unused_args = false

["Locales/.*%.lua"] = {
  ignore = { "line is too long" }
}

-- Exclude third-party stubs and language server files
exclude_files = {
  "WoWStubs/**",
  "lua-language-server/**"
}