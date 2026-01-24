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

    -- Also find monsters waiting to checkout or checking out on off-screen floors
    for _, monster in ipairs(hotel.monsters) do
        if monster.state == MONSTER_STATE.WAITING_TO_CHECKOUT or
           monster.state == MONSTER_STATE.CHECKING_OUT then
            -- Get the floor this monster is on
            local monsterFloor = monster.assignedRoom and monster.assignedRoom.floorNumber or 0
            if monsterFloor > 0 then
                local floor = hotel.floors[monsterFloor]
                if floor then
                    local floorY = floor.y - cameraY + FLOOR_HEIGHT / 2

                    -- Check if floor is off-screen
                    if floorY < 30 then
                        -- Floor is above screen - indicator at elevator shaft position
                        table.insert(self.indicators, {
                            x = ELEVATOR_X + ELEVATOR_WIDTH / 2,
                            y = 25,
                            direction = "up",
                            monster = monster,
                            floorNumber = monsterFloor
                        })
                    elseif floorY > SCREEN_HEIGHT - 30 then
                        -- Floor is below screen
                        table.insert(self.indicators, {
                            x = ELEVATOR_X + ELEVATOR_WIDTH / 2,
                            y = SCREEN_HEIGHT - 25,
                            direction = "down",
                            monster = monster,
                            floorNumber = monsterFloor
                        })
                    end
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
