-- Monster Hotel - Floor Entity

import "entities/room"

local gfx <const> = playdate.graphics

class('Floor').extends()

-- Static sprite assets (loaded once)
Floor.backgroundImages = nil
Floor.elevatorShaft = nil

function Floor.loadAssets()
    if Floor.backgroundImages == nil then
        Floor.backgroundImages = {
            gfx.image.new("images/hotel/floor-bg-1"),
            gfx.image.new("images/hotel/floor-bg-2")
        }
        Floor.elevatorShaft = gfx.image.new("images/hotel/elevator-shaft")
    end
end

-- Floor generation table from GDD
local FLOOR_GENERATION = {
    [1] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE } },
    [2] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE } },
    [3] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE } },
    [4] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE } },
    [5] = { floors = 2, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE } },
    [6] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE } },
    [7] = { floors = 2, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE } },
    [8] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE } },
    [9] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE } },
    [10] = { floors = 2, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE, ROOM_TYPE.CONFERENCE } },
    [11] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE, ROOM_TYPE.CONFERENCE } },
    [12] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE, ROOM_TYPE.CONFERENCE } },
    [13] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE, ROOM_TYPE.CONFERENCE } },
    [14] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE, ROOM_TYPE.CONFERENCE } },
    [15] = { floors = 2, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE, ROOM_TYPE.CONFERENCE, ROOM_TYPE.BALLROOM } }
}

function Floor:init(floorNumber, hotelLevel, floorType, isNewFloor)
    Floor.super.init(self)

    -- Load assets if not already loaded
    Floor.loadAssets()

    self.floorNumber = floorNumber
    self.hotelLevel = hotelLevel
    self.floorType = floorType or FLOOR_TYPE.GUEST

    self.rooms = {}
    self.y = 0  -- Will be set by hotel

    -- Fade-in animation for new floors (0 = invisible, 1 = fully visible)
    -- New floors start invisible and fade in; existing floors start fully visible
    self.fadeAlpha = isNewFloor and 0.0 or 1.0
    self.isFadingIn = isNewFloor or false

    -- Determine which background to use (alternates between floors)
    self.backgroundIndex = ((floorNumber - 1) % 2) + 1

    -- Generate rooms based on floor type
    if self.floorType == FLOOR_TYPE.GUEST then
        self:generateGuestRooms(hotelLevel)
    elseif self.floorType ~= FLOOR_TYPE.LOBBY then
        self:generateServiceFloor()
    end
end

function Floor:setY(y)
    self.y = y
    -- Update room positions
    self:updateRoomPositions()
end

function Floor:update()
    -- Animate fade-in for new floors
    if self.isFadingIn then
        self.fadeAlpha = self.fadeAlpha + 0.02  -- ~1.5 seconds to fully appear
        if self.fadeAlpha >= 1.0 then
            self.fadeAlpha = 1.0
            self.isFadingIn = false
        end
    end
end

function Floor:generateGuestRooms(hotelLevel)
    local genData = FLOOR_GENERATION[math.min(hotelLevel, 15)]
    local availableTypes = genData.types

    -- Check for new types at this level (first room should be new type)
    local newType = nil
    if hotelLevel > 1 then
        local prevData = FLOOR_GENERATION[math.min(hotelLevel - 1, 15)]
        for _, roomType in ipairs(availableTypes) do
            local isNew = true
            for _, prevType in ipairs(prevData.types) do
                if roomType == prevType then
                    isNew = false
                    break
                end
            end
            if isNew and not RoomData.isService(roomType) then
                newType = roomType
                break
            end
        end
    end

    -- Filter out service types for guest floors
    local guestTypes = {}
    for _, roomType in ipairs(availableTypes) do
        if not RoomData.isService(roomType) then
            table.insert(guestTypes, roomType)
        end
    end

    -- Generate 4 rooms
    for i = 1, ROOMS_PER_FLOOR do
        local roomType
        if i == 1 and newType then
            roomType = newType
        else
            roomType = guestTypes[math.random(#guestTypes)]
        end

        local room = Room(self.floorNumber, i, roomType, hotelLevel)
        table.insert(self.rooms, room)
    end

    -- Sort rooms by room number (highest first = leftmost)
    table.sort(self.rooms, function(a, b)
        return tonumber(a.roomNumber) > tonumber(b.roomNumber)
    end)

    self:updateRoomPositions()
end

function Floor:generateServiceFloor()
    -- Service floors have one "room" that takes the whole floor
    local serviceType
    if self.floorType == FLOOR_TYPE.CAFE then
        serviceType = ROOM_TYPE.CAFE
    elseif self.floorType == FLOOR_TYPE.CONFERENCE then
        serviceType = ROOM_TYPE.CONFERENCE
    elseif self.floorType == FLOOR_TYPE.BALLROOM then
        serviceType = ROOM_TYPE.BALLROOM
    end

    if serviceType then
        local room = Room(self.floorNumber, 1, serviceType, self.hotelLevel)
        table.insert(self.rooms, room)
    end
end

function Floor:updateRoomPositions()
    if self.floorType == FLOOR_TYPE.LOBBY then
        return
    end

    -- Calculate positions for rooms symmetrically around elevator shaft
    -- Room layout: door (38px) + number box (12px) = 50px total per room
    local roomDoorWidth = 38
    local roomNumberWidth = 12
    local roomTotalWidth = roomDoorWidth + roomNumberWidth
    local roomSpacing = 6

    -- Elevator shaft center position
    local shaftCenterX = ELEVATOR_X + ELEVATOR_WIDTH / 2
    local shaftHalfWidth = ELEVATOR_WIDTH / 2 + 5  -- Add margin

    -- Left side rooms (positioned right-to-left from shaft)
    -- Room 2 is closest to elevator, Room 1 is at the edge
    local leftRoom2X = shaftCenterX - shaftHalfWidth - roomTotalWidth
    local leftRoom1X = leftRoom2X - roomSpacing - roomTotalWidth

    -- Right side rooms (positioned left-to-right from shaft)
    -- Room 3 is closest to elevator, Room 4 is at the edge
    local rightRoom3X = shaftCenterX + shaftHalfWidth
    local rightRoom4X = rightRoom3X + roomTotalWidth + roomSpacing

    for i, room in ipairs(self.rooms) do
        local x
        if i == 1 then
            x = leftRoom1X
        elseif i == 2 then
            x = leftRoom2X
        elseif i == 3 then
            x = rightRoom3X
        else
            x = rightRoom4X
        end
        room:setPosition(x, self.y)
    end
end

function Floor:getAvailableRoom()
    for _, room in ipairs(self.rooms) do
        if room:isAvailable() then
            return room
        end
    end
    return nil
end

function Floor:getRoomCount()
    return #self.rooms
end

function Floor:getOccupiedRoomCount()
    local count = 0
    for _, room in ipairs(self.rooms) do
        if room.status == BOOKING_STATUS.OCCUPIED then
            count = count + 1
        end
    end
    return count
end

function Floor:getTotalRoomValue()
    local total = 0
    for _, room in ipairs(self.rooms) do
        if room.category == ROOM_CATEGORY.GUEST then
            total = total + room:getCost()
        end
    end
    return total
end

function Floor:isServiceFloor()
    return self.floorType == FLOOR_TYPE.CAFE or
           self.floorType == FLOOR_TYPE.CONFERENCE or
           self.floorType == FLOOR_TYPE.BALLROOM
end

function Floor:draw()
    -- Apply dithering for fade-in effect on new floors
    if self.fadeAlpha < 1.0 then
        -- Use dither pattern to simulate fade (invert for "appearing" effect)
        gfx.setDitherPattern(1.0 - self.fadeAlpha)
    end

    -- Draw floor background (alternating between two patterns)
    local bg = Floor.backgroundImages[self.backgroundIndex]
    if bg then
        bg:draw(0, self.y)
    end

    -- Draw elevator shaft in the center
    if Floor.elevatorShaft then
        local shaftX = ELEVATOR_X + (ELEVATOR_WIDTH - ELEVATOR_SHAFT_WIDTH) / 2
        Floor.elevatorShaft:draw(shaftX, self.y)
    end

    -- Draw rooms
    for _, room in ipairs(self.rooms) do
        room:draw()
    end

    -- Reset dither pattern
    if self.fadeAlpha < 1.0 then
        gfx.setDitherPattern(0)
    end
end

function Floor:serialize()
    local roomsData = {}
    for _, room in ipairs(self.rooms) do
        table.insert(roomsData, room:serialize())
    end

    return {
        floorNumber = self.floorNumber,
        hotelLevel = self.hotelLevel,
        floorType = self.floorType,
        y = self.y,
        rooms = roomsData
    }
end

function Floor:deserialize(data, monsters)
    self.y = data.y
    self.rooms = {}

    for _, roomData in ipairs(data.rooms) do
        local room = Room(roomData.floorNumber, roomData.roomIndex, roomData.roomType, self.hotelLevel)
        room:deserialize(roomData, monsters)
        table.insert(self.rooms, room)
    end
end

-- Static method to get floors to spawn at a level
function Floor.getFloorsToSpawn(hotelLevel)
    local genData = FLOOR_GENERATION[math.min(hotelLevel, 15)]
    return genData.floors
end

-- Static method to get available room types at a level
function Floor.getAvailableTypes(hotelLevel)
    local genData = FLOOR_GENERATION[math.min(hotelLevel, 15)]
    return genData.types
end

return Floor
