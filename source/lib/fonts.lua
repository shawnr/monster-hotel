-- Monster Hotel - Font System
-- Provides access to the game's custom fonts

local gfx <const> = playdate.graphics

Fonts = {
    regular = nil,
    bold = nil,
    italic = nil
}

function Fonts.load()
    Fonts.regular = gfx.font.new("fonts/Newsleak/Newsleak-serif")
    Fonts.bold = gfx.font.new("fonts/Newsleak/Newsleak-serif-bold")
    Fonts.italic = gfx.font.new("fonts/Newsleak/Newsleak-serif-italic")

    -- Set regular as the default
    if Fonts.regular then
        gfx.setFont(Fonts.regular)
    end
end

-- Get font by variant (matches gfx.font.kVariant* constants)
function Fonts.get(variant)
    if variant == gfx.font.kVariantBold then
        return Fonts.bold or Fonts.regular
    elseif variant == gfx.font.kVariantItalic then
        return Fonts.italic or Fonts.regular
    else
        return Fonts.regular
    end
end

-- Convenience function to set font (replaces gfx.setFont(gfx.getSystemFont(...)))
function Fonts.set(variant)
    local font = Fonts.get(variant)
    if font then
        gfx.setFont(font)
    end
end

-- Reset to regular font
function Fonts.reset()
    if Fonts.regular then
        gfx.setFont(Fonts.regular)
    end
end

return Fonts
