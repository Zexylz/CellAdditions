-- NINESLICE TEXTURE SYSTEM
-- ========================
-- CellAdditions automatically detects which textures should use nineslice scaling:
--
-- NINESLICE TEXTURES (borders stay fixed, middle scales):
-- - Names containing: "nineslice", "9slice", "border", "frame", "button"
-- - Examples: border_fancy.tga, frame_gold.tga, nineslice_button.tga
-- - These textures are split into 9 parts: 4 corners + 4 edges + 1 center
-- - Corners never scale, edges scale in one direction, center scales in both
-- - Perfect for frames/borders that need to stretch without distorting decorative edges
--
-- SIMPLE TEXTURES (entire texture stretches):
-- - All other texture names (including "bar" and "health" textures)
-- - Examples: simple_overlay.tga, crystal_texture.tga, healthbar1.tga, blueBar.tga
-- - These stretch the entire texture to fit the frame
-- - Good for simple patterns or textures without decorative borders
--
-- NINESLICE TEXTURE REQUIREMENTS:
-- - Texture dimensions: preferably 64x64px (configurable in settings)
-- - Border width/height: default 8px each (configurable in UI)
-- - Center section: remaining pixels that will scale
-- - Design your texture with non-scaling borders and scalable center
--
-- JUST ADD YOUR TEXTURE FILENAMES BELOW - ONE PER LINE!
-- No quotes, no commas, no special syntax - just the filename!
--
-- EXAMPLE:
-- If you have "glow.tga", just add:
-- glow.tga

local TEXTURE_FILES = [[

healthbar1.tga
blueBar.tga


]]

local function ProcessTextureList()
  local textures = {}

  -- Split by lines and clean up
  for line in TEXTURE_FILES:gmatch("[^\r\n]+") do
    -- Remove whitespace and comments
    line = line:match("^%s*(.-)%s*$")

    -- Skip empty lines and comments
    if
      line
      and line ~= ""
      and not line:match("^%-%-")
      and not line:match("ADD YOUR TEXTURES")
      and not line:match("THAT'S IT")
    then
      -- Check if it looks like a texture file
      if line:match("%.tga$") or line:match("%.blp$") then
        table.insert(textures, line)
      end
    end
  end

  return textures
end

-- Register the textures
_G.CellAdditions_RegisterTextures(ProcessTextureList())
