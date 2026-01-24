-- Monster Hotel - Patience Indicator
-- Shows exclamation points above monsters based on patience level

local gfx <const> = playdate.graphics

PatienceIndicator = {}

function PatienceIndicator:init()
    -- Animation
    self.animTimer = 0
    self.animOffset = 0
end

function PatienceIndicator:update()
    -- Animate exclamation points
    self.animTimer = self.animTimer + 1
    if self.animTimer >= 10 then
        self.animTimer = 0
        self.animOffset = (self.animOffset + 1) % 2
    end
end

function PatienceIndicator:draw(monster, lobby, elevator, cameraY)
    if not monster.visible then return end

    local warningLevel = monster:getPatienceWarningLevel(lobby, elevator, monster.assignedRoom)
    if warningLevel == 0 then return end

    -- Calculate position above monster (in world coordinates)
    -- Note: gfx.setDrawOffset already handles camera, so we use world coordinates directly
    local x = monster.x
    -- Monster Y is feet position, subtract sprite height (~56px scaled) plus padding
    local y = monster.y - 56 - 16 - self.animOffset

    -- Don't draw if off-screen (check in screen space)
    local screenY = y - cameraY
    if screenY < -20 or screenY > SCREEN_HEIGHT + 20 then return end

    -- Draw exclamation points based on warning level
    local text = string.rep("!", warningLevel)

    -- Red background for urgency (using inverted for visibility)
    local textWidth = gfx.getTextSize(text)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(x - textWidth / 2 - 2, y - 2, textWidth + 4, 14, 2)

    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawTextAligned(text, x, y, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function PatienceIndicator:drawAll(monsters, lobby, elevator, cameraY)
    for _, monster in ipairs(monsters) do
        self:draw(monster, lobby, elevator, cameraY)
    end
end

return PatienceIndicator
