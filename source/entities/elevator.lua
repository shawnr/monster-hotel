-- Monster Hotel - Elevator Entity

import "data/elevatorData"

local gfx <const> = playdate.graphics

-- Elevator is NOT a sprite - we draw it manually for simplicity
class('Elevator').extends()

-- Static sprite assets (loaded once)
Elevator.doorSprites = nil
Elevator.shaftSprite = nil

function Elevator.loadAssets()
    if Elevator.doorSprites == nil then
        Elevator.doorSprites = gfx.imagetable.new("images/environment/elevator-doors")
        Elevator.shaftSprite = gfx.image.new("images/environment/ElevatorEmpty")
    end
end

function Elevator:init(hotelLevel, hotelHeight, numFloors)
    Elevator.super.init(self)

    -- Load assets if not already loaded
    Elevator.loadAssets()

    self.hotelLevel = hotelLevel
    self.hotelHeight = hotelHeight
    self.numFloors = numFloors or 1

    -- Get elevator data for this level
    self:updateStats()

    -- Position (start at lobby - bottom of hotel)
    -- ELEVATOR_X centers the elevator on screen
    self.x = ELEVATOR_X
    -- Lobby is at Y = numFloors * FLOOR_HEIGHT, elevator sits inside the floor
    self.y = self.numFloors * FLOOR_HEIGHT + (FLOOR_HEIGHT - ELEVATOR_HEIGHT) / 2

    -- State
    self.doorsOpen = false
    self.doorFrame = 1  -- 1 = closed, 5 = fully open
    self.doorAnimationSpeed = 0.2

    -- Monsters inside the elevator
    self.passengers = {}

    -- Current floor (for reference, 0 = lobby)
    self.currentFloor = 0

    -- Snap-to-floor state
    self.snapTimer = 0
    self.snapTargetY = nil
    self.lastCrankChange = 0
end

function Elevator:updateStats()
    local data = ElevatorData.getForLevel(self.hotelLevel)
    self.name = data.name
    self.capacity = data.capacity
    self.speedMultiplier = data.speed
    self.patienceModifier = data.patienceModifier
end

function Elevator:setHotelLevel(level)
    self.hotelLevel = level
    self:updateStats()
end

function Elevator:setHotelHeight(height)
    self.hotelHeight = height
end

function Elevator:setNumFloors(numFloors)
    self.numFloors = numFloors
end

function Elevator:update()
    -- Animate doors (5 frames: 1=closed, 5=open)
    local targetFrame = self.doorsOpen and 5 or 1
    if self.doorFrame < targetFrame then
        self.doorFrame = math.min(5, self.doorFrame + self.doorAnimationSpeed)
    elseif self.doorFrame > targetFrame then
        self.doorFrame = math.max(1, self.doorFrame - self.doorAnimationSpeed)
    end

    -- Handle snap-to-floor when elevator is stationary near a floor
    if self.lastCrankChange == 0 and not self.doorsOpen then
        local nearestFloorY, distance = self:getNearestFloorY()
        if distance <= 5 and distance > 0 then
            -- Start or continue snap timer
            self.snapTimer = self.snapTimer + 1
            if self.snapTimer >= 10 then  -- ~0.33 seconds at 30fps
                self:snapToFloor(nearestFloorY)
                self.snapTimer = 0
            end
        else
            self.snapTimer = 0
        end
    else
        self.snapTimer = 0
    end

    -- Reset crank tracking
    self.lastCrankChange = 0
end

function Elevator:handleCrank(crankChange)
    if crankChange == 0 then return end

    -- Track crank movement for snap detection
    self.lastCrankChange = crankChange

    -- Cannot move while doors are open
    if self.doorsOpen or not self:areDoorsFullyClosed() then
        return
    end

    local speed = BASE_ELEVATOR_SPEED * self.speedMultiplier
    local dy = crankChange * speed * 0.1  -- Scale crank to pixels

    -- Crank up (positive change) = elevator goes up = lower Y in screen coords
    self:moveByDelta(0, -dy)
end

function Elevator:handleDPad(upPressed, downPressed)
    -- Cannot move while doors are open
    if self.doorsOpen or not self:areDoorsFullyClosed() then
        return
    end

    local speed = BASE_ELEVATOR_SPEED * self.speedMultiplier * 2

    if upPressed then
        self:moveByDelta(0, -speed)
    elseif downPressed then
        self:moveByDelta(0, speed)
    end
end

function Elevator:moveByDelta(dx, dy)
    local newY = self.y + dy

    -- Clamp to hotel bounds
    -- Top floor (floor N) is at Y=0, lobby is at Y = numFloors * FLOOR_HEIGHT
    local minY = (FLOOR_HEIGHT - ELEVATOR_HEIGHT) / 2  -- Top floor
    local maxY = self.numFloors * FLOOR_HEIGHT + (FLOOR_HEIGHT - ELEVATOR_HEIGHT) / 2  -- Lobby

    newY = Utils.clamp(newY, minY, maxY)

    -- Calculate actual movement
    local actualDy = newY - self.y
    self.y = newY

    -- Move passengers with the elevator
    for i, monster in ipairs(self.passengers) do
        monster.y = monster.y + actualDy
        monster.targetY = monster.targetY + actualDy
    end

    -- Update current floor
    self:updateCurrentFloor()
end

function Elevator:updateCurrentFloor()
    -- Calculate which floor the elevator is at based on Y position
    -- Lobby (floor 0) is at bottom (highest Y), floor N is at top (lowest Y)
    local elevatorCenter = self.y + ELEVATOR_HEIGHT / 2
    local floorFromTop = math.floor(elevatorCenter / FLOOR_HEIGHT)

    -- Convert to floor number (0 = lobby, 1 = first guest floor, etc.)
    self.currentFloor = self.numFloors - floorFromTop

    -- Clamp to valid range
    self.currentFloor = Utils.clamp(self.currentFloor, 0, self.numFloors)
end

function Elevator:isAlignedWithFloor(floorY)
    local elevatorBottom = self.y + ELEVATOR_HEIGHT
    local floorTop = floorY
    local tolerance = 10

    return math.abs(elevatorBottom - (floorTop + FLOOR_HEIGHT)) < tolerance
end

function Elevator:getFloorY()
    -- Get the Y position of the floor the elevator is at
    return self.y + ELEVATOR_HEIGHT - FLOOR_HEIGHT
end

function Elevator:getIdealYForFloor(floorNumber)
    -- Calculate the ideal Y position for the elevator to be aligned with a floor
    -- Floor 0 (lobby) is at the bottom, floor N is at the top
    local floorY = (self.numFloors - floorNumber) * FLOOR_HEIGHT
    return floorY + (FLOOR_HEIGHT - ELEVATOR_HEIGHT) / 2
end

function Elevator:getNearestFloorY()
    -- Find the nearest floor and distance to it
    local bestDistance = math.huge
    local bestY = self.y

    for floor = 0, self.numFloors do
        local idealY = self:getIdealYForFloor(floor)
        local distance = math.abs(self.y - idealY)
        if distance < bestDistance then
            bestDistance = distance
            bestY = idealY
        end
    end

    return bestY, bestDistance
end

function Elevator:snapToFloor(targetY)
    local dy = targetY - self.y
    self.y = targetY

    -- Move passengers with elevator
    for _, monster in ipairs(self.passengers) do
        monster.y = monster.y + dy
        monster.targetY = monster.targetY + dy
    end

    self:updateCurrentFloor()
end

function Elevator:isAlignedWithAnyFloor()
    local _, distance = self:getNearestFloorY()
    return distance < 1  -- Must be very close (snapped)
end

function Elevator:toggleDoors()
    -- Can only open/close doors when aligned with a floor
    if self:isAlignedWithAnyFloor() then
        self.doorsOpen = not self.doorsOpen
    end
end

function Elevator:openDoors()
    self.doorsOpen = true
end

function Elevator:closeDoors()
    self.doorsOpen = false
end

function Elevator:areDoorsFullyOpen()
    return self.doorFrame >= 5
end

function Elevator:areDoorsFullyClosed()
    return self.doorFrame <= 1
end

function Elevator:canAcceptPassenger()
    return #self.passengers < self.capacity
end

function Elevator:addPassenger(monster)
    if self:canAcceptPassenger() then
        table.insert(self.passengers, monster)
        return true
    end
    return false
end

function Elevator:removePassenger(monster)
    for i, m in ipairs(self.passengers) do
        if m == monster then
            table.remove(self.passengers, i)
            return true
        end
    end
    return false
end

function Elevator:getPassengerCount()
    return #self.passengers
end

function Elevator:getPassengers()
    return self.passengers
end

function Elevator:getPassengerPosition(index)
    -- Position passengers inside the elevator
    local spacing = 15
    local startX = self.x + 5
    local x = startX + ((index - 1) % 2) * spacing
    local y = self.y + ELEVATOR_HEIGHT - 20
    return x, y
end

function Elevator:draw()
    -- Draw elevator car at its position
    -- self.x should be ELEVATOR_X (centered on screen)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(self.x, self.y, ELEVATOR_WIDTH, ELEVATOR_HEIGHT)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(self.x, self.y, ELEVATOR_WIDTH, ELEVATOR_HEIGHT)

    -- Draw doors based on animation frame
    local doorOpenAmount = (self.doorFrame - 1) / 4  -- 0 to 1
    local doorWidth = 8
    local gapWidth = math.floor(doorOpenAmount * (ELEVATOR_WIDTH / 2 - doorWidth))

    if doorOpenAmount > 0 then
        -- Doors sliding open - draw door panels on sides
        local leftDoorX = self.x + gapWidth
        local rightDoorX = self.x + ELEVATOR_WIDTH - doorWidth - gapWidth
        gfx.fillRect(self.x, self.y + 5, leftDoorX - self.x, ELEVATOR_HEIGHT - 10)
        gfx.fillRect(rightDoorX + doorWidth, self.y + 5, self.x + ELEVATOR_WIDTH - rightDoorX - doorWidth, ELEVATOR_HEIGHT - 10)
    end

    -- Draw center line when doors are closed or closing
    if doorOpenAmount < 1 then
        local centerX = self.x + ELEVATOR_WIDTH / 2
        gfx.drawLine(centerX, self.y + 5, centerX, self.y + ELEVATOR_HEIGHT - 5)
    end
end

function Elevator:serialize()
    local passengerIds = {}
    for _, monster in ipairs(self.passengers) do
        table.insert(passengerIds, monster.id)
    end

    return {
        hotelLevel = self.hotelLevel,
        y = self.y,
        doorsOpen = self.doorsOpen,
        passengerIds = passengerIds
    }
end

function Elevator:deserialize(data, monsters)
    self.y = data.y
    self.doorsOpen = data.doorsOpen
    self.doorFrame = data.doorsOpen and 5 or 1
    self:setHotelLevel(data.hotelLevel)
    self:updateCurrentFloor()

    -- Restore passenger references
    self.passengers = {}
    if data.passengerIds and monsters then
        for _, monsterId in ipairs(data.passengerIds) do
            for _, monster in ipairs(monsters) do
                if monster.id == monsterId then
                    self:addPassenger(monster)
                    break
                end
            end
        end
    end
end

return Elevator
