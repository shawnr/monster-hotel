-- Monster Hotel - Floor Entity

import "entities/room"

local gfx <const> = playdate.graphics

class('Floor').extends()

-- Static sprite assets (loaded once)
Floor.tileSprites = nil
Floor.decorSprites = {}

function Floor.loadAssets()
    if Floor.tileSprites == nil then
        Floor.tileSprites = gfx.imagetable.new("images/tiles/tiles")
        -- Load decoration sprites
        Floor.decorSprites.fireplace = gfx.image.new("images/environment/Fireplace")
        Floor.decorSprites.clock = gfx.image.new("images/environment/GrandfatherClock")
        Floor.decorSprites.fourPoster = gfx.image.new("images/environment/FourPoster")
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

function Floor:init(floorNumber, hotelLevel, floorType)
    Floor.super.init(self)

    -- Load assets if not already loaded
    Floor.loadAssets()

    self.floorNumber = floorNumber
    self.hotelLevel = hotelLevel
    self.floorType = floorType or FLOOR_TYPE.GUEST

    self.rooms = {}
    self.y = 0  -- Will be set by hotel

    -- Random decoration positions for this floor (seeded by floor number for consistency)
    self.decorations = {}
    self:generateDecorations()

    -- Generate rooms based on floor type
    if self.floorType == FLOOR_TYPE.GUEST then
        self:generateGuestRooms(hotelLevel)
    elseif self.floorType ~= FLOOR_TYPE.LOBBY then
        self:generateServiceFloor()
    end
end

function Floor:generateDecorations()
    -- Use floor number as seed for consistent decorations
    local seed = self.floorNumber * 17 + 31

    -- Add 1-2 decorations per floor in spaces between rooms
    local decorTypes = {"fireplace", "clock"}
    local numDecor = (seed % 2) + 1

    for i = 1, numDecor do
        local decorType = decorTypes[((seed + i) % #decorTypes) + 1]
        -- Position decorations in gaps (left side near edge, right side near edge)
        local xPos
        if i == 1 then
            xPos = 5  -- Left edge
        else
            xPos = SCREEN_WIDTH - 20  -- Right edge
        end
        table.insert(self.decorations, {type = decorType, x = xPos})
    end
end

function Floor:setY(y)
    self.y = y
    -- Update room positions
    self:updateRoomPositions()
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
    -- Elevator shaft is at ELEVATOR_X - 2 with width ELEVATOR_WIDTH + 4
    local shaftLeft = ELEVATOR_X - 2
    local shaftRight = ELEVATOR_X + ELEVATOR_WIDTH + 2
    local roomWidth = 45
    local roomSpacing = 5
    local margin = 10  -- Gap between rooms and shaft

    -- Left side rooms (positioned right-to-left from shaft)
    local leftRoom2X = shaftLeft - margin - roomWidth
    local leftRoom1X = leftRoom2X - roomSpacing - roomWidth

    -- Right side rooms (positioned left-to-right from shaft)
    local rightRoom1X = shaftRight + margin
    local rightRoom2X = rightRoom1X + roomWidth + roomSpacing

    for i, room in ipairs(self.rooms) do
        local x
        if i == 1 then
            x = leftRoom1X
        elseif i == 2 then
            x = leftRoom2X
        elseif i == 3 then
            x = rightRoom1X
        else
            x = rightRoom2X
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
    -- Draw clean floor with simple lines (no busy tile patterns)
    -- Floor line at bottom
    gfx.drawLine(0, self.y + FLOOR_HEIGHT - 1, SCREEN_WIDTH, self.y + FLOOR_HEIGHT - 1)

    -- Ceiling line at top
    gfx.drawLine(0, self.y + 2, SCREEN_WIDTH, self.y + 2)

    -- Draw elevator shaft area
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(ELEVATOR_X - 2, self.y, ELEVATOR_WIDTH + 4, FLOOR_HEIGHT)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(ELEVATOR_X - 2, self.y, ELEVATOR_WIDTH + 4, FLOOR_HEIGHT)

    -- Draw floor number
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
    gfx.drawText("F" .. self.floorNumber, 5, self.y + 5)
    gfx.setFont(gfx.getSystemFont())

    -- Draw rooms
    for _, room in ipairs(self.rooms) do
        room:draw()
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
