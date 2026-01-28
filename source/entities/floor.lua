-- Monster Hotel - Floor Entity

import "entities/room"
import "data/serviceFloorData"

local gfx <const> = playdate.graphics

class('Floor').extends()

-- Static sprite assets (loaded once)
Floor.backgroundImages = nil
Floor.specialtyBackgrounds = nil
Floor.elevatorShaft = nil

function Floor.loadAssets()
    if Floor.backgroundImages == nil then
        Floor.backgroundImages = {
            gfx.image.new("images/hotel/floor-bg-1"),
            gfx.image.new("images/hotel/floor-bg-2")
        }
        Floor.specialtyBackgrounds = {
            [FLOOR_TYPE.CAFE] = gfx.image.new("images/hotel/cafe-bg"),
            [FLOOR_TYPE.CONFERENCE] = gfx.image.new("images/hotel/conference-bg"),
            [FLOOR_TYPE.BALLROOM] = gfx.image.new("images/hotel/ballroom-bg")
        }
        Floor.elevatorShaft = gfx.image.new("images/hotel/elevator-shaft")
    end
end

-- Floor generation table from GDD (line 267)
local FLOOR_GENERATION = {
    [1] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE } },
    [2] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE } },
    [3] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE } },
    [4] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE } },
    [5] = { floors = 2, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE } },
    [6] = { floors = 1, types = { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE, ROOM_TYPE.CAFE } },
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

    -- Service floor monster tracking
    self.serviceMonsters = {}

    -- Fade-in animation for new floors (0 = invisible, 1 = fully visible)
    -- New floors start invisible and fade in; existing floors start fully visible
    self.fadeAlpha = isNewFloor and 0.0 or 1.0
    self.isFadingIn = isNewFloor or false

    -- Determine which background to use (alternates between floors)
    self.backgroundIndex = ((floorNumber - 1) % 2) + 1

    -- Service floor name (randomly selected for service floors)
    self.serviceName = nil
    if self:isServiceFloor() then
        self.serviceName = ServiceFloorData.getRandomName(self.floorType)
    end

    -- Generate rooms based on floor type (service floors have no rooms)
    if self.floorType == FLOOR_TYPE.GUEST then
        self:generateGuestRooms(hotelLevel)
    end
    -- Service floors don't have guest rooms - they just have the background and label
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


function Floor:updateRoomPositions()
    if self.floorType == FLOOR_TYPE.LOBBY then
        return
    end

    -- Calculate positions for rooms toward screen edges, leaving space around elevator
    -- Room layout: door (38px) + number box (14px) = 52px total per room
    local roomDoorWidth = 38
    local roomNumberWidth = 14
    local roomTotalWidth = roomDoorWidth + roomNumberWidth
    local roomSpacing = 4

    -- Position rooms from edges inward, leaving wide elevator area in center
    -- Left edge starts at x=0, right edge at SCREEN_WIDTH=400
    local leftEdgeMargin = 2
    local rightEdgeMargin = 2

    -- Left side rooms (positioned from left edge, room 1 at far left)
    local leftRoom1X = leftEdgeMargin
    local leftRoom2X = leftRoom1X + roomTotalWidth + roomSpacing

    -- Right side rooms (positioned from right edge, room 4 at far right)
    -- Account for door+number width from right edge
    local rightRoom4X = SCREEN_WIDTH - rightEdgeMargin - roomTotalWidth
    local rightRoom3X = rightRoom4X - roomTotalWidth - roomSpacing

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

-- Service floor capacity is half the lobby capacity
function Floor:getServiceCapacity(lobbyCapacity)
    return math.floor(lobbyCapacity / 2)
end

function Floor:canAcceptServiceMonster(lobbyCapacity)
    if not self:isServiceFloor() then return false end
    return #self.serviceMonsters < self:getServiceCapacity(lobbyCapacity)
end

function Floor:addServiceMonster(monster)
    table.insert(self.serviceMonsters, monster)
    monster.serviceFloorIndex = #self.serviceMonsters
    return true
end

function Floor:removeServiceMonster(monster)
    for i, m in ipairs(self.serviceMonsters) do
        if m == monster then
            table.remove(self.serviceMonsters, i)
            -- Update indices for remaining monsters
            for j = i, #self.serviceMonsters do
                self.serviceMonsters[j].serviceFloorIndex = j
            end
            return true
        end
    end
    return false
end

function Floor:getServiceMonsterCount()
    return #self.serviceMonsters
end

function Floor:getServiceMonsters()
    return self.serviceMonsters
end

-- Get position for a monster on the service floor
-- Monsters hang out on the RIGHT side of the floor, away from the elevator
function Floor:getServiceWaitPosition(index)
    local y = self.y + FLOOR_HEIGHT - 5
    local spacing = 4  -- Tight spacing, overlapping is fine

    -- Right side of elevator - start near right edge and pack towards elevator
    local rightStartX = SCREEN_WIDTH - 40  -- Start near right edge (x=360)
    local x = rightStartX - (index - 1) * spacing

    -- Clamp to not go past elevator shaft
    local minX = ELEVATOR_X + ELEVATOR_WIDTH + 10
    if x < minX then
        x = minX
    end

    return x, y
end

-- Rage out all monsters on this service floor (called at day end)
function Floor:rageOutServiceMonsters()
    local monsters = {}
    for _, monster in ipairs(self.serviceMonsters) do
        table.insert(monsters, monster)
    end
    -- Clear the list (monsters will be handled by caller)
    self.serviceMonsters = {}
    return monsters
end

function Floor:draw()
    -- Apply dithering for fade-in effect on new floors
    if self.fadeAlpha < 1.0 then
        -- Use dither pattern to simulate fade (invert for "appearing" effect)
        gfx.setDitherPattern(1.0 - self.fadeAlpha)
    end

    -- Draw floor background
    local bg
    if self:isServiceFloor() and Floor.specialtyBackgrounds[self.floorType] then
        -- Use specialty background for service floors
        bg = Floor.specialtyBackgrounds[self.floorType]
    else
        -- Use alternating background for guest floors
        bg = Floor.backgroundImages[self.backgroundIndex]
    end
    if bg then
        bg:draw(0, self.y)
    end

    -- Draw elevator shaft in the center
    if Floor.elevatorShaft then
        local shaftX = ELEVATOR_X + (ELEVATOR_WIDTH - ELEVATOR_SHAFT_WIDTH) / 2
        Floor.elevatorShaft:draw(shaftX, self.y)
    end

    -- Draw rooms (guest floors only)
    for _, room in ipairs(self.rooms) do
        room:draw()
    end

    -- Draw service floor label on left side
    if self:isServiceFloor() and self.serviceName then
        self:drawServiceLabel()
    end

    -- Draw thick floor divider line at the bottom of the floor
    gfx.setColor(gfx.kColorBlack)
    local lineY = self.y + FLOOR_HEIGHT - 1
    gfx.fillRect(0, lineY - 2, SCREEN_WIDTH, 3)  -- 3px thick line

    -- Reset dither pattern
    if self.fadeAlpha < 1.0 then
        gfx.setDitherPattern(0)
    end
end

function Floor:drawServiceLabel()
    -- Draw a bordered box on the left side with the service floor name
    local labelText = self.serviceName
    local typeLabel = ServiceFloorData.getTypeLabel(self.floorType)

    local paddingH = 4
    local paddingV = 2
    local lineSpacing = 0
    local maxBoxWidth = 150
    local maxTextWidth = maxBoxWidth - paddingH * 2

    -- Use system font (smaller than custom font)
    local smallFont = gfx.getSystemFont(gfx.font.kVariantNormal)
    gfx.setFont(smallFont)

    -- Calculate text size and truncate if needed
    local nameWidth, nameHeight = gfx.getTextSize(labelText)
    local typeWidth, typeHeight = gfx.getTextSize(typeLabel)

    -- Truncate name with ellipsis if too long
    if nameWidth > maxTextWidth then
        while nameWidth > maxTextWidth and #labelText > 3 do
            labelText = string.sub(labelText, 1, #labelText - 1)
            nameWidth, nameHeight = gfx.getTextSize(labelText .. "...")
        end
        labelText = labelText .. "..."
        nameWidth, nameHeight = gfx.getTextSize(labelText)
    end

    -- Box dimensions - capped at max width
    local boxWidth = math.min(maxBoxWidth, math.max(nameWidth, typeWidth) + paddingH * 2)
    local boxHeight = nameHeight + typeHeight + paddingV * 2 + lineSpacing
    local boxX = 4
    local boxY = self.y + (FLOOR_HEIGHT - boxHeight) / 2

    -- Draw white background with black border
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(boxX, boxY, boxWidth, boxHeight, 3)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(boxX, boxY, boxWidth, boxHeight, 3)

    -- Draw service name
    gfx.drawText(labelText, boxX + paddingH, boxY + paddingV)

    -- Draw type label below (italic for distinction)
    local italicFont = gfx.getSystemFont(gfx.font.kVariantItalic)
    gfx.setFont(italicFont)
    gfx.drawText(typeLabel, boxX + paddingH, boxY + paddingV + nameHeight + lineSpacing)

    -- Reset to game font
    Fonts.reset()
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
        serviceName = self.serviceName,
        rooms = roomsData
    }
end

function Floor:deserialize(data, monsters)
    self.y = data.y
    self.serviceName = data.serviceName
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
