-- Monster Hotel - Room Entity

import "data/roomData"

local gfx <const> = playdate.graphics

class('Room').extends()

-- Static sprite assets
Room.doorSprites = nil

function Room.loadAssets()
    if Room.doorSprites == nil then
        Room.doorSprites = gfx.imagetable.new("images/environment/door")
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
    -- Door is centered in the room
    self.doorX = x + 20
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
    -- Simple door rectangle
    gfx.drawRect(self.x, self.y + 10, 40, 45)
    -- Door handle
    gfx.fillCircleAtPoint(self.x + 35, self.y + 32, 3)

    -- Draw room status indicator above door
    if self.status == BOOKING_STATUS.OCCUPIED then
        -- Occupied - filled rectangle with X
        gfx.fillRect(self.x + 5, self.y + 2, 30, 10)
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
        gfx.drawText("OCC", self.x + 8, self.y + 2)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    elseif self.assignedMonster then
        -- Monster assigned - show initial in circle
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(self.x + 20, self.y + 7, 8)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(self.x + 20, self.y + 7, 8)
        local initial = string.sub(self.assignedMonster.data.name, 1, 1)
        gfx.drawTextAligned(initial, self.x + 20, self.y + 1, kTextAlignment.center)
    end

    -- Room number below door
    gfx.drawText(self.roomNumber, self.x + 5, self.y + 48)
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

    -- Restore monster references
    if data.occupantId and monsters then
        for _, monster in ipairs(monsters) do
            if monster.id == data.occupantId then
                self.occupant = monster
                break
            end
        end
    end
    if data.assignedMonsterId and monsters then
        for _, monster in ipairs(monsters) do
            if monster.id == data.assignedMonsterId then
                self.assignedMonster = monster
                break
            end
        end
    end
end

return Room
