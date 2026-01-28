-- Monster Hotel - Hotel Entity (Game State Container)

import "entities/lobby"
import "entities/floor"
import "entities/elevator"

local gfx <const> = playdate.graphics

class('Hotel').extends()

function Hotel:init()
    Hotel.super.init(self)

    -- Core state - calculate initial level from starting money
    self.money = HOTEL_START_MONEY
    self.maxMoneyReached = HOTEL_START_MONEY
    self.level = self:calculateLevelFromMoney(self.money)  -- Level based on starting money
    self.dayCount = 1

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

    -- Track which service floor types have been added (for first-time guarantee)
    self.addedServiceTypes = {
        [FLOOR_TYPE.CAFE] = false,
        [FLOOR_TYPE.CONFERENCE] = false,
        [FLOOR_TYPE.BALLROOM] = false
    }

    -- Initialize with starting configuration
    self:initializeNewHotel()
end

function Hotel:initializeNewHotel()
    -- Create lobby (at bottom, highest Y value)
    self.lobby = Lobby(self.level)

    -- Create floors based on starting level
    -- Each level from 1 to current level adds floors according to floor generation table
    local totalFloorsNeeded = 0
    for level = 1, self.level do
        totalFloorsNeeded = totalFloorsNeeded + Floor.getFloorsToSpawn(level)
    end

    -- Create all needed floors (not as "new floors" so no fade-in animation)
    for i = 1, totalFloorsNeeded do
        local floor = Floor(i, self.level, FLOOR_TYPE.GUEST, false)
        table.insert(self.floors, floor)
    end

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
            -- Hide monsters inside elevator when doors are closed
            local isInElevator = monster.state == MONSTER_STATE.RIDING_ELEVATOR
            local doorsOpen = self.elevator.doorFrame > 1.5  -- Partially open or more
            if isInElevator and not doorsOpen then
                -- Skip drawing - monster is hidden inside closed elevator
            else
                monster:draw()
            end
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
        lobbyCapacity = nil, -- Only set if actually increased
        serviceFloorAdded = false  -- Set if a service floor was added
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

    -- Check for newly available service types that must be added
    local forcedServiceType = self:getNewlyAvailableServiceType(newLevel)

    -- Add new floors (they're added at the TOP, so everything shifts DOWN)
    local floorsToAdd = Floor.getFloorsToSpawn(newLevel)
    changes.floorsAdded = floorsToAdd

    -- Shift elevator down by the amount the floors will shift
    -- This keeps the elevator at the same relative position
    local shiftAmount = floorsToAdd * FLOOR_HEIGHT
    self.elevator.y = self.elevator.y + shiftAmount

    -- Also shift any passengers in the elevator
    for _, monster in ipairs(self.elevator.passengers) do
        monster.y = monster.y + shiftAmount
        monster.targetY = monster.targetY + shiftAmount
    end

    for i = 1, floorsToAdd do
        -- First floor at this level uses the forced service type (if any)
        local forceType = (i == 1) and forcedServiceType or nil
        local isServiceFloor = self:addNewFloor(newLevel, forceType)
        if isServiceFloor then
            changes.serviceFloorAdded = true
        end
    end

    self:recalculateLayout()

    -- Notify callback if set (named differently to avoid shadowing method)
    if self.onLevelUpCallback then
        self.onLevelUpCallback(changes)
    end
end

-- Check if a service type is newly available at this level and hasn't been added yet
function Hotel:getNewlyAvailableServiceType(hotelLevel)
    -- Service type availability levels from FLOOR_GENERATION:
    -- Level 5: CAFE
    -- Level 10: CONFERENCE
    -- Level 15: BALLROOM

    local newServiceType = nil

    if hotelLevel >= 5 then
        -- Check if CAFE is available and hasn't been added
        if not self.addedServiceTypes[FLOOR_TYPE.CAFE] then
            newServiceType = FLOOR_TYPE.CAFE
        end
    end

    if hotelLevel >= 10 then
        -- Check if CONFERENCE is available and hasn't been added
        if not self.addedServiceTypes[FLOOR_TYPE.CONFERENCE] then
            newServiceType = FLOOR_TYPE.CONFERENCE
        end
    end

    if hotelLevel >= 15 then
        -- Check if BALLROOM is available and hasn't been added
        if not self.addedServiceTypes[FLOOR_TYPE.BALLROOM] then
            newServiceType = FLOOR_TYPE.BALLROOM
        end
    end

    return newServiceType
end

function Hotel:addNewFloor(hotelLevel, forcedServiceType)
    local floorNumber = #self.floors + 1

    -- Determine floor type (check for service floors at certain levels)
    local floorType = FLOOR_TYPE.GUEST

    -- If a service type is forced (first-time guarantee), use it
    if forcedServiceType then
        floorType = forcedServiceType
        self.addedServiceTypes[forcedServiceType] = true
        print("Guaranteed service floor added:", forcedServiceType)
    else
        -- Normal logic: 20% chance of service floor when available
        local availableTypes = Floor.getAvailableTypes(hotelLevel)
        for _, roomType in ipairs(availableTypes) do
            if RoomData.isService(roomType) then
                -- 20% chance of service floor when available
                if math.random(100) <= 20 then
                    if roomType == ROOM_TYPE.CAFE then
                        floorType = FLOOR_TYPE.CAFE
                        self.addedServiceTypes[FLOOR_TYPE.CAFE] = true
                    elseif roomType == ROOM_TYPE.CONFERENCE then
                        floorType = FLOOR_TYPE.CONFERENCE
                        self.addedServiceTypes[FLOOR_TYPE.CONFERENCE] = true
                    elseif roomType == ROOM_TYPE.BALLROOM then
                        floorType = FLOOR_TYPE.BALLROOM
                        self.addedServiceTypes[FLOOR_TYPE.BALLROOM] = true
                    end
                    break
                end
            end
        end
    end

    -- New floor added during gameplay - mark as new for fade-in animation
    local newFloor = Floor(floorNumber, hotelLevel, floorType, true)
    table.insert(self.floors, newFloor)

    -- Return whether this was a service floor
    return floorType ~= FLOOR_TYPE.GUEST
end

-- Room management
function Hotel:getAvailableRoom()
    -- Collect all available rooms across all floors
    local availableRooms = {}
    for _, floor in ipairs(self.floors) do
        for _, room in ipairs(floor.rooms) do
            if room:isAvailable() then
                table.insert(availableRooms, room)
            end
        end
    end

    -- Pick a random room from available ones
    if #availableRooms > 0 then
        return availableRooms[math.random(#availableRooms)]
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
        addedServiceTypes = self.addedServiceTypes,
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

    -- Restore added service types tracking (or scan floors for legacy saves)
    if data.addedServiceTypes then
        self.addedServiceTypes = data.addedServiceTypes
    else
        -- Legacy save - scan floors to determine what service types exist
        self.addedServiceTypes = {
            [FLOOR_TYPE.CAFE] = false,
            [FLOOR_TYPE.CONFERENCE] = false,
            [FLOOR_TYPE.BALLROOM] = false
        }
    end

    -- Restore floors first (creates rooms without monster links)
    self.floors = {}
    for _, floorData in ipairs(data.floors) do
        local floor = Floor(floorData.floorNumber, floorData.hotelLevel, floorData.floorType)
        floor:deserialize(floorData, nil)
        table.insert(self.floors, floor)

        -- Track service types from existing floors (for legacy saves)
        if floorData.floorType == FLOOR_TYPE.CAFE then
            self.addedServiceTypes[FLOOR_TYPE.CAFE] = true
        elseif floorData.floorType == FLOOR_TYPE.CONFERENCE then
            self.addedServiceTypes[FLOOR_TYPE.CONFERENCE] = true
        elseif floorData.floorType == FLOOR_TYPE.BALLROOM then
            self.addedServiceTypes[FLOOR_TYPE.BALLROOM] = true
        end
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
