-- Monster Hotel - Hotel Entity (Game State Container)

import "entities/lobby"
import "entities/floor"
import "entities/elevator"

local gfx <const> = playdate.graphics

class('Hotel').extends()

function Hotel:init()
    Hotel.super.init(self)

    -- Core state
    self.level = HOTEL_START_LEVEL
    self.money = HOTEL_START_MONEY
    self.dayCount = 1
    self.maxMoneyReached = HOTEL_START_MONEY

    -- Stats for unlockables
    self.guestsServed = 0
    self.totalRages = 0
    self.lifetimeGuestsServed = 0  -- Loaded from persistent storage

    -- Daily stats (reset each day)
    self.dailyCheckIns = 0
    self.dailyCheckOuts = 0

    -- Floors (index 0 = lobby, 1+ = guest floors)
    self.floors = {}
    self.lobby = nil
    self.elevator = nil

    -- All monsters in the hotel
    self.monsters = {}

    -- Initialize with starting configuration
    self:initializeNewHotel()
end

function Hotel:initializeNewHotel()
    -- Create lobby (at bottom, highest Y value)
    self.lobby = Lobby(self.level)

    -- Create first guest floor (above lobby)
    local firstFloor = Floor(1, self.level, FLOOR_TYPE.GUEST)
    table.insert(self.floors, firstFloor)

    -- Calculate positions
    self:recalculateLayout()

    -- Create elevator
    self.elevator = Elevator(self.level, self:getHeight(), #self.floors)
end

function Hotel:getHeight()
    -- Total height of the hotel in pixels
    return (1 + #self.floors) * FLOOR_HEIGHT
end

function Hotel:recalculateLayout()
    -- Y coordinates: 0 is at TOP of hotel, increases downward
    -- Top floor is at Y=0, lobby is at bottom (highest Y)
    local numFloors = #self.floors

    -- Guest floors from top to bottom
    for i, floor in ipairs(self.floors) do
        -- Floor 1 is just above lobby, floor N is at top
        local floorIndex = numFloors - i  -- Reverse order: highest floor number at top
        floor:setY(floorIndex * FLOOR_HEIGHT)
    end

    -- Lobby is at the bottom
    self.lobby:setY(numFloors * FLOOR_HEIGHT)

    if self.elevator then
        self.elevator:setHotelHeight(self:getHeight())
        self.elevator:setNumFloors(#self.floors)
    end
end

function Hotel:getMaxScroll()
    -- Maximum camera scroll (how far down we can scroll)
    local totalHeight = self:getHeight()
    return math.max(0, totalHeight - SCREEN_HEIGHT + 40)  -- +40 for HUD space
end

function Hotel:update()
    -- Update elevator
    if self.elevator then
        self.elevator:update()
    end

    -- Update floors (for fade-in animation)
    for _, floor in ipairs(self.floors) do
        floor:update()
    end

    -- Update monsters
    for i = #self.monsters, 1, -1 do
        local monster = self.monsters[i]
        monster:update()

        -- Remove monsters that have exited
        if monster.state == MONSTER_STATE.EXITING_HOTEL and monster:isAtTarget() then
            self:removeMonster(monster)
        end
    end
end

function Hotel:draw()
    -- Draw lobby
    self.lobby:draw()

    -- Draw floors
    for _, floor in ipairs(self.floors) do
        floor:draw()
    end

    -- Draw elevator
    if self.elevator then
        self.elevator:draw()
    end

    -- Draw monsters manually
    for _, monster in ipairs(self.monsters) do
        -- Only draw visible monsters (hidden when inside rooms)
        if monster.visible then
            monster:draw()
        end
    end
end

-- Money management
function Hotel:addMoney(amount)
    self.money = self.money + amount
    if self.money > self.maxMoneyReached then
        self.maxMoneyReached = self.money
        -- Check for level up
        self:checkLevelUp()
    end
end

function Hotel:subtractMoney(amount)
    self.money = self.money - amount
    if self.money < 0 then
        self.money = 0
    end
end

function Hotel:isGameOver()
    return self.money <= 0
end

-- Level management
function Hotel:checkLevelUp()
    local newLevel = self:calculateLevelFromMoney(self.money)
    if newLevel > self.level then
        local oldLevel = self.level
        self.level = newLevel
        self:onLevelUp(oldLevel, newLevel)
    end
end

function Hotel:calculateLevelFromMoney(money)
    -- Check standard thresholds
    for level = 15, 1, -1 do
        if money >= HOTEL_LEVEL_THRESHOLDS[level] then
            if level == 15 then
                -- Beyond level 15, use formula
                local extraMoney = money - HOTEL_LEVEL_THRESHOLDS[15]
                local extraLevels = math.floor(extraMoney / LEVEL_UP_MULTIPLIER)
                return 15 + extraLevels
            end
            return level
        end
    end
    return 1
end

function Hotel:onLevelUp(oldLevel, newLevel)
    -- Track what changed for notification
    local oldElevatorName = self.elevator.name
    local oldLobbyCapacity = self.lobby.capacity

    local changes = {
        newLevel = newLevel,
        oldLevel = oldLevel,
        floorsAdded = 0,
        elevatorName = nil,  -- Only set if actually upgraded
        lobbyCapacity = nil  -- Only set if actually increased
    }

    -- Upgrade elevator
    self.elevator:setHotelLevel(newLevel)
    if self.elevator.name ~= oldElevatorName then
        changes.elevatorName = self.elevator.name
    end

    -- Upgrade lobby
    self.lobby:setHotelLevel(newLevel)
    if self.lobby.capacity > oldLobbyCapacity then
        changes.lobbyCapacity = self.lobby.capacity
    end

    -- Add new floors
    local floorsToAdd = Floor.getFloorsToSpawn(newLevel)
    changes.floorsAdded = floorsToAdd
    for i = 1, floorsToAdd do
        self:addNewFloor(newLevel)
    end

    self:recalculateLayout()

    -- Notify callback if set
    if self.onLevelUp then
        self.onLevelUp(changes)
    end
end

function Hotel:addNewFloor(hotelLevel)
    local floorNumber = #self.floors + 1

    -- Determine floor type (check for service floors at certain levels)
    local floorType = FLOOR_TYPE.GUEST
    local availableTypes = Floor.getAvailableTypes(hotelLevel)

    -- Check if this level introduces a new service type
    for _, roomType in ipairs(availableTypes) do
        if RoomData.isService(roomType) then
            -- 20% chance of service floor when available
            if math.random(100) <= 20 then
                if roomType == ROOM_TYPE.CAFE then
                    floorType = FLOOR_TYPE.CAFE
                elseif roomType == ROOM_TYPE.CONFERENCE then
                    floorType = FLOOR_TYPE.CONFERENCE
                elseif roomType == ROOM_TYPE.BALLROOM then
                    floorType = FLOOR_TYPE.BALLROOM
                end
                break
            end
        end
    end

    -- New floor added during gameplay - mark as new for fade-in animation
    local newFloor = Floor(floorNumber, hotelLevel, floorType, true)
    table.insert(self.floors, newFloor)
end

-- Room management
function Hotel:getAvailableRoom()
    -- Find first available room across all floors
    for _, floor in ipairs(self.floors) do
        local room = floor:getAvailableRoom()
        if room then
            return room
        end
    end
    return nil
end

function Hotel:getTotalRoomCount()
    local count = 0
    for _, floor in ipairs(self.floors) do
        count = count + floor:getRoomCount()
    end
    return count
end

function Hotel:getAvailableRoomCount()
    local count = 0
    for _, floor in ipairs(self.floors) do
        for _, room in ipairs(floor.rooms) do
            if room:isAvailable() then
                count = count + 1
            end
        end
    end
    return count
end

function Hotel:getAllRooms()
    local rooms = {}
    for _, floor in ipairs(self.floors) do
        for _, room in ipairs(floor.rooms) do
            table.insert(rooms, room)
        end
    end
    return rooms
end

-- Daily stats tracking
function Hotel:recordCheckIn()
    self.dailyCheckIns = self.dailyCheckIns + 1
end

function Hotel:recordCheckOut()
    self.dailyCheckOuts = self.dailyCheckOuts + 1
    self.guestsServed = self.guestsServed + 1
end

function Hotel:resetDailyStats()
    self.dailyCheckIns = 0
    self.dailyCheckOuts = 0
end

-- Monster management
function Hotel:addMonster(monster)
    table.insert(self.monsters, monster)
end

function Hotel:removeMonster(monster)
    for i, m in ipairs(self.monsters) do
        if m == monster then
            table.remove(self.monsters, i)
            break
        end
    end

    -- Remove from lobby if present
    self.lobby:removeMonster(monster)

    -- Remove from elevator if present
    self.elevator:removePassenger(monster)

    -- Clear any room references to this monster (safety cleanup)
    if monster.assignedRoom then
        if monster.assignedRoom.occupant == monster then
            monster.assignedRoom:checkOut()
        end
        if monster.assignedRoom.assignedMonster == monster then
            monster.assignedRoom:cancelAssignment()
        end
        monster.assignedRoom = nil
    end
end

function Hotel:getMonstersOnFloor(floorNumber)
    local monstersOnFloor = {}
    for _, monster in ipairs(self.monsters) do
        -- Check monster's current floor based on Y position
        local monsterFloor = math.floor(-monster.y / FLOOR_HEIGHT)
        if monsterFloor == floorNumber then
            table.insert(monstersOnFloor, monster)
        end
    end
    return monstersOnFloor
end

function Hotel:getMonstersWaitingToCheckout()
    local waiting = {}
    for _, monster in ipairs(self.monsters) do
        if monster.state == MONSTER_STATE.WAITING_TO_CHECKOUT then
            table.insert(waiting, monster)
        end
    end
    return waiting
end

-- Operating costs calculation
function Hotel:calculateDailyOperatingCost()
    local totalGuestRoomValue = 0
    local serviceFloorCount = 0

    for _, floor in ipairs(self.floors) do
        if floor:isServiceFloor() then
            serviceFloorCount = serviceFloorCount + 1
        else
            totalGuestRoomValue = totalGuestRoomValue + floor:getTotalRoomValue()
        end
    end

    -- Formula: (0.05 * TotalGuestRoomValue) + (50 * ServiceFloors) + (Level * 100)
    local cost = (0.05 * totalGuestRoomValue) +
                 (50 * serviceFloorCount) +
                 (self.level * 100)

    return math.floor(cost)
end

-- Serialization
function Hotel:serialize()
    local floorsData = {}
    for _, floor in ipairs(self.floors) do
        table.insert(floorsData, floor:serialize())
    end

    local monstersData = {}
    for _, monster in ipairs(self.monsters) do
        table.insert(monstersData, monster:serialize())
    end

    return {
        level = self.level,
        money = self.money,
        dayCount = self.dayCount,
        maxMoneyReached = self.maxMoneyReached,
        guestsServed = self.guestsServed,
        totalRages = self.totalRages,
        lobby = self.lobby:serialize(),
        elevator = self.elevator:serialize(),
        floors = floorsData,
        monsters = monstersData
    }
end

function Hotel:deserialize(data)
    self.level = data.level
    self.money = data.money
    self.dayCount = data.dayCount
    self.maxMoneyReached = data.maxMoneyReached or data.money
    self.guestsServed = data.guestsServed or 0
    self.totalRages = data.totalRages or 0

    -- Restore floors first (creates rooms without monster links)
    self.floors = {}
    for _, floorData in ipairs(data.floors) do
        local floor = Floor(floorData.floorNumber, floorData.hotelLevel, floorData.floorType)
        floor:deserialize(floorData, nil)
        table.insert(self.floors, floor)
    end

    -- Get all rooms for monster deserialization
    local allRooms = self:getAllRooms()

    -- Restore monsters (links monster.assignedRoom to actual room objects)
    self.monsters = {}
    for _, monsterData in ipairs(data.monsters) do
        local monster = Monster.deserialize(monsterData, allRooms)
        if monster then
            table.insert(self.monsters, monster)
        end
    end

    -- Link rooms back to monsters (room.occupant and room.assignedMonster)
    -- Do NOT call floor:deserialize again - that recreates rooms!
    for _, floor in ipairs(self.floors) do
        for _, room in ipairs(floor.rooms) do
            room:linkMonsters(self.monsters)
        end
    end

    -- Restore lobby with monster references
    self.lobby = Lobby(self.level)
    self.lobby:deserialize(data.lobby, self.monsters)

    -- Restore elevator with monster references
    self.elevator = Elevator(self.level, self:getHeight(), #self.floors)
    self.elevator:deserialize(data.elevator, self.monsters)

    self:recalculateLayout()
end

return Hotel
