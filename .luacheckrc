-- .luacheckrc

std = "lua51"

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
  "BINDING_NAME_.*",
  "addonName",
  "self"
}

exclude_files = {
  "WoWStubs/**"
}
