-- Monster Hotel - Room Indicator
-- Shows off-screen room markers for assigned monsters

local gfx <const> = playdate.graphics

RoomIndicator = {}

function RoomIndicator:init()
    self.indicators = {}
end

function RoomIndicator:update(hotel, cameraY)
    self.indicators = {}

    -- Find all assigned rooms with monsters not yet checked in
    for _, floor in ipairs(hotel.floors) do
        for _, room in ipairs(floor.rooms) do
            if room.assignedMonster and room.status == BOOKING_STATUS.AVAILABLE then
                local roomY = room.y - cameraY + FLOOR_HEIGHT / 2

                -- Check if room is off-screen
                if roomY < 30 then
                    -- Room is above screen
                    table.insert(self.indicators, {
                        x = room.doorX,
                        y = 25,
                        direction = "up",
                        monster = room.assignedMonster,
                        floorNumber = floor.floorNumber
                    })
                elseif roomY > SCREEN_HEIGHT - 30 then
                    -- Room is below screen
                    table.insert(self.indicators, {
                        x = room.doorX,
                        y = SCREEN_HEIGHT - 25,
                        direction = "down",
                        monster = room.assignedMonster,
                        floorNumber = floor.floorNumber
                    })
                end
            end
        end
    end
end

function RoomIndicator:draw()
    for _, indicator in ipairs(self.indicators) do
        self:drawIndicator(indicator)
    end
end

function RoomIndicator:drawIndicator(indicator)
    local x = indicator.x
    local y = indicator.y

    -- Draw arrow pointing to room location
    gfx.setColor(gfx.kColorBlack)

    if indicator.direction == "up" then
        -- Up arrow
        gfx.fillTriangle(x, y - 5, x - 5, y + 5, x + 5, y + 5)
    else
        -- Down arrow
        gfx.fillTriangle(x, y + 5, x - 5, y - 5, x + 5, y - 5)
    end

    -- Draw monster initial in circle
    gfx.fillCircleAtPoint(x, y + (indicator.direction == "up" and 15 or -15), 8)

    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    local initial = string.sub(indicator.monster.name, 1, 1)
    local textY = y + (indicator.direction == "up" and 9 or -21)
    gfx.drawTextAligned(initial, x, textY, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw floor number
    Fonts.set(gfx.font.kVariantItalic)
    local floorText = "F" .. indicator.floorNumber
    local floorY = y + (indicator.direction == "up" and 25 or -35)
    gfx.drawTextAligned(floorText, x, floorY, kTextAlignment.center)
    Fonts.reset()
end

return RoomIndicator
