std = "lua51"

globals = {
  "ChatFrame1",
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

unused_args = false

exclude_files = {
  "WoWStubs/**",
  "lua-language-server/**"
}

max_line_length = 120