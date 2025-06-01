-- TEXTURE TILING SYSTEM
-- ===================
-- CellAdditions automatically detects which textures should use tiling:
--
-- TILED TEXTURES (borders stay fixed, middle repeats):
-- - Names containing: "bar", "health", "border", "frame"
-- - Examples: healthbar1.tga, health_bar_blue.tga, border_fancy.tga, frame_gold.tga
-- - These textures are split into 3 parts: left border | repeating middle | right border
-- - Perfect for health bars that need to stretch without distorting decorative edges
--
-- STRETCHED TEXTURES (entire texture stretches):
-- - All other texture names
-- - Examples: simple_overlay.tga, crystal_texture.tga
-- - These stretch the entire texture to fit the frame
-- - Good for simple patterns or textures without decorative borders
--
-- TEXTURE REQUIREMENTS FOR TILING:
-- - Texture width: preferably 64px (configurable in settings)
-- - Left/right borders: default 8px each (configurable in UI)
-- - Middle section: remaining pixels (48px in a 64px texture with 8px borders)
-- - The middle section will be repeated/tiled horizontally as needed
--
-- JUST ADD YOUR TEXTURE FILENAMES BELOW - ONE PER LINE!
-- No quotes, no commas, no special syntax - just the filename!
--
-- EXAMPLE:
-- If you have "glow.tga", just add:
-- glow.tga

local TEXTURE_FILES = [[

healthbar1.tga
health_bar_blue.tga


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
