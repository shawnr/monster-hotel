-- Monster Hotel - Room Indicator
-- Shows pointers to pickup/dropoff locations for monsters

local gfx <const> = playdate.graphics

RoomIndicator = {}

function RoomIndicator:init()
    self.indicators = {}
end

-- Check if a floor's room number panels might be off-screen
-- Show indicator if ANY part of the floor is visible but not fully visible
-- This helps players see where to go even when floor is partially scrolled
function RoomIndicator:isFloorHidden(floorY, cameraY)
    local screenTop = cameraY
    local screenBottom = cameraY + SCREEN_HEIGHT

    local floorTop = floorY
    local floorBottom = floorY + FLOOR_HEIGHT

    -- Calculate how much of the floor is visible
    local visibleTop = math.max(floorTop, screenTop)
    local visibleBottom = math.min(floorBottom, screenBottom)
    local visibleHeight = math.max(0, visibleBottom - visibleTop)
    local visiblePercent = visibleHeight / FLOOR_HEIGHT

    -- Show indicator if floor is partially visible (at least 5% showing)
    -- but not mostly visible (less than 80% showing)
    -- This means: show bubble when floor is on screen edge
    local partiallyOnScreen = visiblePercent > 0.05
    local mostlyHidden = visiblePercent < 0.8

    return partiallyOnScreen and mostlyHidden
end

-- Check if floor is completely off-screen (for different behavior)
function RoomIndicator:isFloorOffScreen(floorY, cameraY)
    local screenTop = cameraY
    local screenBottom = cameraY + SCREEN_HEIGHT

    local floorTop = floorY
    local floorBottom = floorY + FLOOR_HEIGHT

    -- Floor is off-screen if no part is visible
    return floorBottom < screenTop or floorTop > screenBottom
end

-- Get direction indicator should point (up or down from screen center)
function RoomIndicator:getDirection(targetY, cameraY)
    local screenCenterY = cameraY + SCREEN_HEIGHT / 2
    if targetY < screenCenterY then
        return "up"
    else
        return "down"
    end
end

function RoomIndicator:update(hotel, cameraY)
    self.indicators = {}

    for _, monster in ipairs(hotel.monsters) do
        local indicator = nil

        if monster.state == MONSTER_STATE.RIDING_ELEVATOR then
            -- Monster is in elevator - point to their DESTINATION
            if monster.isCheckingOut then
                -- Checking out - point to lobby
                local lobbyY = hotel.lobby.y
                if self:shouldShowIndicator(lobbyY, cameraY) then
                    indicator = {
                        x = ELEVATOR_X + ELEVATOR_WIDTH / 2,
                        y = self:getDirection(lobbyY, cameraY) == "up" and 25 or SCREEN_HEIGHT - 25,
                        direction = self:getDirection(lobbyY, cameraY),
                        monster = monster,
                        floorNumber = 0
                    }
                end
            else
                -- Checking in - point to their assigned room
                if monster.assignedRoom then
                    local roomFloorY = monster.assignedRoom.y
                    if self:shouldShowIndicator(roomFloorY, cameraY) then
                        indicator = {
                            x = monster.assignedRoom.doorX + 19,
                            y = self:getDirection(roomFloorY, cameraY) == "up" and 25 or SCREEN_HEIGHT - 25,
                            direction = self:getDirection(roomFloorY, cameraY),
                            monster = monster,
                            floorNumber = monster.assignedRoom.floorNumber
                        }
                    end
                end
            end
        elseif monster.state == MONSTER_STATE.WAITING_IN_LOBBY or
               monster.state == MONSTER_STATE.ENTERING_ELEVATOR then
            -- Monster waiting in lobby - point to lobby (their current location)
            local lobbyY = hotel.lobby.y
            if self:shouldShowIndicator(lobbyY, cameraY) then
                indicator = {
                    x = monster.x,
                    y = self:getDirection(lobbyY, cameraY) == "up" and 25 or SCREEN_HEIGHT - 25,
                    direction = self:getDirection(lobbyY, cameraY),
                    monster = monster,
                    floorNumber = 0
                }
            end
        elseif monster.state == MONSTER_STATE.WAITING_TO_CHECKOUT or
               monster.state == MONSTER_STATE.CHECKING_OUT then
            -- Monster waiting on a floor for pickup - point to their current location
            if monster.assignedRoom then
                local floorY = monster.assignedRoom.y
                if self:shouldShowIndicator(floorY, cameraY) then
                    indicator = {
                        x = ELEVATOR_X + ELEVATOR_WIDTH / 2,
                        y = self:getDirection(floorY, cameraY) == "up" and 25 or SCREEN_HEIGHT - 25,
                        direction = self:getDirection(floorY, cameraY),
                        monster = monster,
                        floorNumber = monster.assignedRoom.floorNumber
                    }
                end
            end
        elseif monster.state == MONSTER_STATE.ON_SERVICE_FLOOR or
               monster.state == MONSTER_STATE.EXITING_SERVICE_FLOOR then
            -- Monster on service floor - point to their current location
            if monster.serviceFloor then
                local floorY = monster.serviceFloor.y
                if self:shouldShowIndicator(floorY, cameraY) then
                    indicator = {
                        x = ELEVATOR_X + ELEVATOR_WIDTH / 2,
                        y = self:getDirection(floorY, cameraY) == "up" and 25 or SCREEN_HEIGHT - 25,
                        direction = self:getDirection(floorY, cameraY),
                        monster = monster,
                        floorNumber = monster.serviceFloor.floorNumber
                    }
                end
            end
        end

        if indicator then
            table.insert(self.indicators, indicator)
        end
    end
end

-- Decide whether to show indicator for a floor
-- Show if floor is partially visible but mostly hidden, OR completely off-screen
function RoomIndicator:shouldShowIndicator(floorY, cameraY)
    return self:isFloorHidden(floorY, cameraY) or self:isFloorOffScreen(floorY, cameraY)
end

function RoomIndicator:draw()
    for _, indicator in ipairs(self.indicators) do
        self:drawIndicator(indicator)
    end
end

function RoomIndicator:drawIndicator(indicator)
    local x = indicator.x
    local y = indicator.y

    -- Draw larger solid black bubble (no letter)
    gfx.setColor(gfx.kColorBlack)

    if indicator.direction == "up" then
        -- Up arrow (larger)
        gfx.fillTriangle(x, y - 6, x - 7, y + 6, x + 7, y + 6)
        -- Black circle below arrow (larger)
        gfx.fillCircleAtPoint(x, y + 18, 11)
    else
        -- Down arrow (larger)
        gfx.fillTriangle(x, y + 6, x - 7, y - 6, x + 7, y - 6)
        -- Black circle above arrow (larger)
        gfx.fillCircleAtPoint(x, y - 18, 11)
    end
end

return RoomIndicator
