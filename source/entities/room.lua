-- Monster Hotel - Room Entity

import "data/roomData"

local gfx <const> = playdate.graphics

class('Room').extends()

-- Static sprite assets
Room.doorImage = nil

function Room.loadAssets()
    if Room.doorImage == nil then
        Room.doorImage = gfx.image.new("images/hotel/room-door")
    end
end

function Room:init(floorNumber, roomIndex, roomType, hotelLevel)
    Room.loadAssets()
    Room.super.init(self)

    self.floorNumber = floorNumber
    self.roomIndex = roomIndex
    self.roomType = roomType
    self.hotelLevel = hotelLevel

    -- Generate room number: floor number + 0 + room index (e.g., 101, 102, 103, 104)
    self.roomNumber = tostring(floorNumber) .. "0" .. tostring(roomIndex)

    -- Get room data
    local data = RoomData.getByType(roomType)
    self.capacity = data.capacity
    self.baseCost = data.baseCost
    self.category = data.category
    self.isService = data.category == ROOM_CATEGORY.SERVICE

    -- Status
    self.status = BOOKING_STATUS.AVAILABLE
    self.occupant = nil
    self.assignedMonster = nil  -- Monster assigned but not yet arrived

    -- Position (will be set by floor)
    self.x = 0
    self.y = 0
    self.doorX = 0
end

function Room:setPosition(x, y)
    self.x = x
    self.y = y
    -- Door is on the left, room number is on the right
    self.doorX = x
    self.numberX = x + 40  -- Room number to the right of door (door is 38px wide)
end

function Room:getPatienceModifier()
    local data = RoomData.getByType(self.roomType)
    return data.getPatienceModifier(self.hotelLevel)
end

function Room:getCost()
    local data = RoomData.getByType(self.roomType)
    return data.getCost()
end

function Room:isAvailable()
    return self.status == BOOKING_STATUS.AVAILABLE and self.assignedMonster == nil
end

function Room:assignMonster(monster)
    self.assignedMonster = monster
end

function Room:checkIn(monster)
    self.status = BOOKING_STATUS.OCCUPIED
    self.occupant = monster
    self.assignedMonster = nil
end

function Room:checkOut()
    local monster = self.occupant
    self.status = BOOKING_STATUS.AVAILABLE
    self.occupant = nil
    return monster
end

function Room:cancelAssignment()
    self.assignedMonster = nil
end

function Room:getMonsterIcon()
    if self.assignedMonster then
        return self.assignedMonster:getIcon()
    end
    return nil
end

function Room:draw()
    -- Draw door sprite
    if Room.doorImage then
        Room.doorImage:draw(self.doorX, self.y + 5)
    end

    -- Draw vertical room number to the right of door
    -- Large panel like reference image 14
    local digits = tostring(self.roomNumber)
    local boxWidth = 16
    local digitHeight = 16  -- Full height per digit
    local boxHeight = #digits * digitHeight + 8
    local boxY = self.y + 8

    -- Draw box for room number (white fill with black border)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(self.numberX, boxY, boxWidth, boxHeight)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(self.numberX, boxY, boxWidth, boxHeight)

    -- Draw each digit at full size, centered in box
    local digitY = boxY + 6
    for i = 1, #digits do
        local digit = string.sub(digits, i, i)
        gfx.drawTextAligned(digit, self.numberX + boxWidth / 2, digitY, kTextAlignment.center)
        digitY = digitY + digitHeight
    end

    -- Draw monster icon on door when room is occupied
    if self.status == BOOKING_STATUS.OCCUPIED and self.occupant then
        local icon = self.occupant:getIconImage()
        if icon then
            -- Draw 40px icon centered on door, in top half
            -- Icons are 32x32, so scale = 40/32 = 1.25
            local iconScale = 1.25
            local iconSize = 32 * iconScale  -- 40px
            local iconX = self.doorX + (38 - iconSize) / 2  -- Center on 38px door
            local iconY = self.y + 12  -- Top half of door (door starts at y+5)
            icon:drawScaled(iconX, iconY, iconScale)
        end
    elseif self.assignedMonster then
        -- Monster assigned but not yet checked in - show smaller faded indicator
        local icon = self.assignedMonster:getIconImage()
        if icon then
            local iconScale = 0.8
            local iconSize = 32 * iconScale
            local iconX = self.doorX + (38 - iconSize) / 2
            local iconY = self.y + 20
            gfx.setDitherPattern(0.5)
            icon:drawScaled(iconX, iconY, iconScale)
            gfx.setDitherPattern(0)
        else
            -- Fallback: small open circle
            gfx.drawCircleAtPoint(self.doorX + 19, self.y + 35, 4)
        end
    end
end

function Room:serialize()
    return {
        floorNumber = self.floorNumber,
        roomIndex = self.roomIndex,
        roomType = self.roomType,
        roomNumber = self.roomNumber,
        status = self.status,
        occupantId = self.occupant and self.occupant.id or nil,
        assignedMonsterId = self.assignedMonster and self.assignedMonster.id or nil,
        x = self.x,
        y = self.y
    }
end

function Room:deserialize(data, monsters)
    self.roomNumber = data.roomNumber
    self.status = data.status
    self.x = data.x
    self.y = data.y

    -- Restore monster references if monsters array provided
    if monsters then
        self:linkMonsters(monsters)
    end
end

function Room:linkMonsters(monsters)
    -- Find monsters whose assignedRoom matches this room
    -- Link them based on their state
    self.occupant = nil
    self.assignedMonster = nil

    for _, monster in ipairs(monsters) do
        if monster.assignedRoom == self then
            -- Monster belongs to this room
            if monster.state == MONSTER_STATE.IN_ROOM or
               monster.state == MONSTER_STATE.WAITING_TO_CHECKOUT or
               monster.state == MONSTER_STATE.CHECKING_OUT or
               monster.isCheckingOut then
                -- Monster is in room or checking out - they're the occupant
                self.occupant = monster
                self.status = BOOKING_STATUS.OCCUPIED
            elseif monster.state == MONSTER_STATE.WAITING_IN_LOBBY or
                   monster.state == MONSTER_STATE.ENTERING_ELEVATOR or
                   monster.state == MONSTER_STATE.RIDING_ELEVATOR or
                   monster.state == MONSTER_STATE.EXITING_TO_ROOM then
                -- Monster is en route to room - they're assigned
                self.assignedMonster = monster
            end
            break  -- Only one monster per room
        end
    end
end

return Room
