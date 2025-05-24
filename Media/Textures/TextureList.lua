-- JUST ADD YOUR TEXTURE FILENAMES BELOW - ONE PER LINE!
-- No quotes, no commas, no special syntax - just the filename!
--
-- EXAMPLE:
-- If you have "glow.tga", just add:
-- glow.tga


local TEXTURE_FILES = [[

healthbar1.tga


]]



local function ProcessTextureList()
    local textures = {}
    
    -- Split by lines and clean up
    for line in TEXTURE_FILES:gmatch("[^\r\n]+") do
        -- Remove whitespace and comments
        line = line:match("^%s*(.-)%s*$")
        
        -- Skip empty lines and comments
        if line and line ~= "" and not line:match("^%-%-") and not line:match("ADD YOUR TEXTURES") and not line:match("THAT'S IT") then
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
