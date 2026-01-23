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

    -- Generate room number: floor number + random 10-20
    self.roomNumber = tostring(floorNumber) .. tostring(math.random(10, 20))

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

    -- Draw vertical room number to the right of door (smaller text)
    local digits = tostring(self.roomNumber)
    local digitSpacing = 10  -- Smaller spacing
    local boxWidth = 10
    local boxHeight = #digits * digitSpacing + 4

    -- Draw box for room number
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(self.numberX, self.y + 5, boxWidth, boxHeight)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(self.numberX, self.y + 5, boxWidth, boxHeight)

    -- Draw each digit vertically (smaller)
    local digitY = self.y + 7
    for i = 1, #digits do
        local digit = string.sub(digits, i, i)
        -- Draw smaller by using drawText instead of the larger font
        gfx.drawTextAligned(digit, self.numberX + boxWidth/2, digitY, kTextAlignment.center)
        digitY = digitY + digitSpacing
    end

    -- Draw monster icon on door when room is occupied
    if self.status == BOOKING_STATUS.OCCUPIED and self.occupant then
        local icon = self.occupant:getIconImage()
        if icon then
            -- Draw icon centered on door, scaled down
            local iconX = self.doorX + 3
            local iconY = self.y + 30
            icon:drawScaled(iconX, iconY, 0.7)
        end
    elseif self.assignedMonster then
        -- Monster assigned but not yet checked in - show small indicator
        local icon = self.assignedMonster:getIconImage()
        if icon then
            local iconX = self.doorX + 3
            local iconY = self.y + 30
            -- Draw smaller/faded to indicate "pending"
            gfx.setDitherPattern(0.5)
            icon:drawScaled(iconX, iconY, 0.5)
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
