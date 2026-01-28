-- Monster Hotel - Game Scene
-- Main gameplay scene

import "scenes/sceneManager"
import "entities/hotel"
import "systems/timeSystem"
import "systems/spawnSystem"
import "systems/economySystem"
import "ui/hud"
import "ui/patienceIndicator"
import "ui/roomIndicator"
import "ui/messageOverlay"

local gfx <const> = playdate.graphics

GameScene = {}

function GameScene:enter(options)
    options = options or {}

    -- Initialize or load game state
    if options.isNewGame then
        self:startNewGame(options.saveSlot)
    else
        self:loadGame(options.saveSlot)
    end

    -- Initialize camera
    self.cameraY = 0
    self.targetCameraY = 0

    -- Track the save slot
    self.saveSlot = options.saveSlot or 1

    -- Initialize systems
    self:initializeSystems()

    -- Initialize UI
    self:initializeUI()

    -- Initialize tutorial overlay
    MessageOverlay:init()

    -- Show game start tutorial for new games
    if options.isNewGame then
        MessageOverlay:show(MessageOverlay.MESSAGES.GAME_START)
    end

    -- Game state
    self.isPaused = false
    self.dayEnding = false
    self.canSkipToMorning = false

    -- Level up notification
    self.showingLevelUp = false
    self.levelUpInfo = nil

    -- No Vacancy dialog (shown when hotel is full)
    self.showingNoVacancy = false

    -- Show crank indicator at start of gameplay (only if crank is docked)
    self.showCrankIndicator = playdate.isCrankDocked()
    if self.showCrankIndicator then
        playdate.ui.crankIndicator:start()
    end

    -- Play gameplay music (switches between tracks every 2 minutes)
    MusicSystem:playGameplayMusic()

    -- Set up hotel callback for level up
    self.hotel.onLevelUpCallback = function(changes)
        self:onHotelLevelUp(changes)
    end
end

function GameScene:startNewGame(saveSlot)
    -- Create new hotel
    self.hotel = Hotel()

    -- Track new game in unlock system
    UnlockSystem:onNewGameStarted()
end

function GameScene:loadGame(saveSlot)
    local saveData = SaveSystem:load(saveSlot)

    if saveData and saveData.hotel then
        self.hotel = Hotel()
        self.hotel:deserialize(saveData.hotel)

        -- Restore time
        if saveData.time then
            TimeSystem:deserialize(saveData.time)
        end
    else
        -- No save data, start new game
        self:startNewGame(saveSlot)
    end
end

function GameScene:initializeSystems()
    -- Initialize time system (Day 1 starts at noon for faster gameplay)
    local isFirstDay = self.hotel.dayCount == 1
    TimeSystem:init(isFirstDay)
    TimeSystem.onHourChange = function(hour)
        self:onHourChange(hour)
    end
    TimeSystem.onDayEnd = function()
        self:onDayEnd()
    end

    -- Initialize spawn system
    SpawnSystem:init(self.hotel, TimeSystem)
    SpawnSystem.onMonsterSpawned = function(monster)
        self:onMonsterSpawned(monster)
    end
    SpawnSystem:start()

    -- Initialize economy system
    EconomySystem:init(self.hotel, UnlockSystem)
    EconomySystem.onMoneyChanged = function(amount, reason)
        self:onMoneyChanged(amount, reason)
    end
    EconomySystem.onDamage = function(amount, monster)
        self:onDamage(amount, monster)
    end
end

function GameScene:initializeUI()
    -- Initialize HUD
    HUD:init(self.hotel, TimeSystem)

    -- Initialize patience indicator
    PatienceIndicator:init()

    -- Initialize room indicator
    RoomIndicator:init()
end

function GameScene:exit()
    -- Stop spawn timer
    SpawnSystem:stop()

    -- Clear sprites
    gfx.sprite.removeAll()
end

function GameScene:update()
    if self.isPaused then return end

    -- Handle D-pad elevator movement (continuous while held)
    local upPressed = playdate.buttonIsPressed(playdate.kButtonUp)
    local downPressed = playdate.buttonIsPressed(playdate.kButtonDown)
    if upPressed or downPressed then
        self.hotel.elevator:handleDPad(upPressed, downPressed)
    end

    -- Update time
    TimeSystem:update()

    -- Update hotel (includes elevator and monsters)
    self.hotel:update()

    -- Update UI
    HUD:update()
    PatienceIndicator:update()
    RoomIndicator:update(self.hotel, self.cameraY)
    MessageOverlay:update()

    -- Update camera to follow elevator
    self:updateCamera()

    -- Handle monster-elevator interactions
    self:handleElevatorInteractions()

    -- Handle service floor monsters who were walking to elevator when it left
    self:handleServiceFloorResets()

    -- Check for checkouts in morning
    if TimeSystem:isMorning() then
        self:handleMorningCheckouts()
    end

    -- Handle monster rages
    self:handleMonsterRages()

    -- Check if player can skip to morning (all rooms booked, past checkout time)
    local wasSkippable = self.canSkipToMorning
    self.canSkipToMorning = self:checkCanSkipToMorning()

    -- Show "No Vacancy" dialog when hotel becomes full (only trigger once)
    if self.canSkipToMorning and not wasSkippable and not self.showingNoVacancy then
        self.showingNoVacancy = true
        self.isPaused = true
    end
end

function GameScene:checkCanSkipToMorning()
    -- Can only skip if time allows and hotel is at full occupancy
    if not TimeSystem:canSkipToMorning() then
        return false
    end

    -- Only allow skip when ALL rooms are OCCUPIED (checked in)
    -- Not just unavailable/assigned - must be actually occupied
    local totalRooms = self.hotel:getTotalRoomCount()
    local occupiedRooms = 0
    for _, floor in ipairs(self.hotel.floors) do
        occupiedRooms = occupiedRooms + floor:getOccupiedRoomCount()
    end

    return totalRooms > 0 and occupiedRooms == totalRooms
end

function GameScene:updateCamera()
    -- Camera system: negative cameraY shifts world DOWN (lobby to bottom)
    -- positive cameraY shifts world UP (to see higher floors)

    local lobbyBottomY = self.hotel.lobby.y + FLOOR_HEIGHT
    local screenBottom = SCREEN_HEIGHT - 20  -- Leave space for bottom HUD

    -- lobbyCameraY: positions lobby at screen bottom (usually negative for short hotels)
    local lobbyCameraY = lobbyBottomY - screenBottom

    -- elevatorCameraY: follows elevator, keeping it centered
    local elevatorCenterY = self.hotel.elevator.y + ELEVATOR_HEIGHT / 2
    local elevatorCameraY = elevatorCenterY - SCREEN_HEIGHT / 2 + 20

    -- Use the MINIMUM (most negative) to ensure lobby stays at bottom
    -- As elevator goes UP (lower Y), elevatorCameraY becomes more negative,
    -- eventually exceeding lobbyCameraY and scrolling the view up
    self.targetCameraY = math.min(lobbyCameraY, elevatorCameraY)

    -- Smooth camera movement
    self.cameraY = Utils.lerp(self.cameraY, self.targetCameraY, 0.15)
end

function GameScene:handleElevatorInteractions()
    local elevator = self.hotel.elevator

    -- Only process when doors are fully open
    if not elevator:areDoorsFullyOpen() then return end

    local elevatorFloorY = elevator:getFloorY()

    -- Check if at lobby (use position check as backup to floor number)
    local lobbyY = self.hotel.lobby.y
    local isAtLobby = elevator.currentFloor == 0 or
                      math.abs(elevator.y - elevator:getIdealYForFloor(0)) < 5
    if isAtLobby then
        -- Let monsters waiting in lobby start moving to elevator
        local waitingMonsters = self.hotel.lobby:getMonstersWaitingForElevator()
        for _, monster in ipairs(waitingMonsters) do
            if monster:isAtTarget() and elevator:canAcceptPassenger() then
                -- Start monster moving toward elevator
                local elevatorCenterX = ELEVATOR_X + ELEVATOR_WIDTH / 2
                monster:startMovingToElevator(elevatorCenterX, monster.y)
            end
        end

        -- Let monsters who reached the elevator board it
        local elevatorCenterX = ELEVATOR_X + ELEVATOR_WIDTH / 2
        for _, monster in ipairs(self.hotel.monsters) do
            if monster.state == MONSTER_STATE.ENTERING_ELEVATOR and elevator:canAcceptPassenger() then
                -- Monster must reach elevator center before boarding (within 5px)
                local distanceToCenter = math.abs(monster.x - elevatorCenterX)

                if distanceToCenter < 5 then
                    -- Monster enters elevator - check if we actually get added
                    if elevator:addPassenger(monster) then
                        self.hotel.lobby:removeMonster(monster)
                        monster:enterElevator()

                        -- Position inside elevator
                        local px, py = elevator:getPassengerPosition(#elevator.passengers)
                        monster:setPosition(px, py)
                    end
                end
            end
        end

        -- Let checkout monsters exit to lobby
        -- Checkout monsters: isCheckingOut flag is set, OR they have an occupied room
        for i = #elevator.passengers, 1, -1 do
            local monster = elevator.passengers[i]
            -- A monster is checking out if:
            -- 1. They have the isCheckingOut flag set, OR
            -- 2. They have an assigned room that's occupied (they were the occupant)
            local isCheckout = monster.isCheckingOut or
                              (monster.assignedRoom and monster.assignedRoom.status == BOOKING_STATUS.OCCUPIED)
            if isCheckout then
                -- Check out of room - use Room:checkOut() method for proper cleanup
                if monster.assignedRoom then
                    monster.assignedRoom:checkOut()
                end

                -- Process checkout payment
                EconomySystem:processCheckout(monster)

                -- Track the checkout
                self.hotel:recordCheckOut()

                -- Clear the checking out flag and room reference
                monster.isCheckingOut = false
                monster.assignedRoom = nil

                -- Now remove from elevator and set exit target
                elevator:removePassenger(monster)
                monster:exitElevatorToLobby(SCREEN_WIDTH - 30, self.hotel.lobby.y)
            end
        end
    else
        -- At a guest or service floor
        local currentFloor = self.hotel.floors[elevator.currentFloor]
        if not currentFloor then return end

        local elevatorCenterX = ELEVATOR_X + ELEVATOR_WIDTH / 2

        if currentFloor:isServiceFloor() then
            -- SERVICE FLOOR HANDLING

            -- Monsters exit elevator to service floor when doors open
            -- Skip monsters who just reboarded from a service floor (hasVisitedServiceFloor flag)
            for i = #elevator.passengers, 1, -1 do
                local monster = elevator.passengers[i]
                -- Only non-checkout monsters who haven't visited a service floor yet
                if monster.state == MONSTER_STATE.RIDING_ELEVATOR and
                   not monster.isCheckingOut and
                   not monster.hasVisitedServiceFloor then
                    -- Mark that they've visited a service floor
                    monster.hasVisitedServiceFloor = true
                    -- Exit to service floor (no capacity limit)
                    elevator:removePassenger(monster)
                    monster:setPosition(elevatorCenterX, currentFloor.y + FLOOR_HEIGHT - 5)

                    -- Walk to service position
                    local targetX, targetY = currentFloor:getServiceWaitPosition(currentFloor:getServiceMonsterCount() + 1)
                    monster:exitElevatorToServiceFloor(targetX, currentFloor.y)
                    currentFloor:addServiceMonster(monster)
                    monster.serviceFloor = currentFloor
                end
            end

            -- Determine how many monsters should try to board
            -- If more than 4 monsters: half try to board
            -- If 4 or fewer: all try to board
            local totalOnFloor = currentFloor:getServiceMonsterCount()
            local monstersToBoard = totalOnFloor
            if totalOnFloor > 4 then
                monstersToBoard = math.floor(totalOnFloor / 2)
            end
            local boardingCount = 0

            -- Let monsters on service floor board elevator
            for i = #currentFloor.serviceMonsters, 1, -1 do
                local monster = currentFloor.serviceMonsters[i]

                if monster.state == MONSTER_STATE.ON_SERVICE_FLOOR then
                    -- Only start walking if we haven't hit the boarding limit
                    -- AND the monster has settled (waited minimum time on service floor)
                    if boardingCount < monstersToBoard and
                       elevator:canAcceptPassenger() and
                       monster.serviceFloorSettleTimer <= 0 then
                        monster:startLeavingServiceFloor(elevatorCenterX)
                        boardingCount = boardingCount + 1
                    end
                elseif monster.state == MONSTER_STATE.EXITING_SERVICE_FLOOR then
                    -- Check if close enough to board
                    local distanceToCenter = math.abs(monster.x - elevatorCenterX)
                    if distanceToCenter < 5 and elevator:canAcceptPassenger() then
                        if elevator:addPassenger(monster) then
                            currentFloor:removeServiceMonster(monster)
                            monster.serviceFloor = nil
                            monster:enterElevator()
                            local px, py = elevator:getPassengerPosition(#elevator.passengers)
                            monster:setPosition(px, py)
                        end
                    end
                end
            end
        else
            -- GUEST FLOOR HANDLING
            -- Let monsters exit to their rooms (only check-in monsters, not checkout)
            for i = #elevator.passengers, 1, -1 do
                local monster = elevator.passengers[i]
                -- Check-in monsters have: room.assignedMonster == monster, room.occupant == nil
                -- Checkout monsters have: room.occupant == monster, room.assignedMonster == nil
                if monster.assignedRoom and
                   monster.assignedRoom.floorNumber == elevator.currentFloor and
                   monster.state == MONSTER_STATE.RIDING_ELEVATOR and
                   monster.assignedRoom.assignedMonster == monster then
                    -- Exit to room (check-in)
                    elevator:removePassenger(monster)
                    monster:setPosition(elevatorCenterX, currentFloor.y + FLOOR_HEIGHT - 5)
                    monster:exitElevatorToRoom(monster.assignedRoom.doorX, currentFloor.y)

                    -- Track the check-in
                    self.hotel:recordCheckIn()
                end
            end

            -- Let checkout monsters board the elevator
            for _, monster in ipairs(self.hotel.monsters) do
                local monsterFloor = monster.assignedRoom and monster.assignedRoom.floorNumber or 0

                if monsterFloor == elevator.currentFloor then
                    if monster.state == MONSTER_STATE.WAITING_TO_CHECKOUT then
                        -- Monster is waiting at elevator shaft - check if at target and can board
                        if monster:isAtTarget() and elevator:canAcceptPassenger() then
                            -- Start walking into the elevator
                            monster:startBoardingElevator(elevatorCenterX)
                        end
                    elseif monster.state == MONSTER_STATE.CHECKING_OUT then
                        -- Monster must reach elevator center before boarding (within 5px)
                        local distanceToCenter = math.abs(monster.x - elevatorCenterX)

                        if distanceToCenter < 5 and elevator:canAcceptPassenger() then
                            -- Close enough to board - check if we actually get added
                            if elevator:addPassenger(monster) then
                                monster:enterElevator()

                                -- Position inside elevator
                                local px, py = elevator:getPassengerPosition(#elevator.passengers)
                                monster:setPosition(px, py)
                            end
                        end
                    end
                elseif monster.state == MONSTER_STATE.CHECKING_OUT and monsterFloor ~= elevator.currentFloor then
                    -- Monster was boarding but elevator left - go back to waiting at elevator shaft
                    monster.state = MONSTER_STATE.WAITING_TO_CHECKOUT
                    if monster.assignedRoom then
                        local floorY = monster.assignedRoom.y + FLOOR_HEIGHT - 5
                        -- Return to same side they came from
                        local doorCenterX = monster.assignedRoom.doorX + 19
                        local waitElevatorCenterX = ELEVATOR_X + ELEVATOR_WIDTH / 2
                        local elevatorWaitX
                        if doorCenterX < waitElevatorCenterX then
                            elevatorWaitX = ELEVATOR_X - 10
                        else
                            elevatorWaitX = ELEVATOR_X + ELEVATOR_WIDTH + 10
                        end
                        monster:setTarget(elevatorWaitX, floorY)
                    end
                end
            end
        end
    end

    -- CRITICAL: Force all passenger positions after any boarding occurred
    -- This ensures newly boarded passengers are at elevator center
    elevator:forcePassengerPositions()
end

function GameScene:handleMorningCheckouts()
    local currentHour = TimeSystem:getHour()

    -- Check each occupied room
    local firstMonsterFound = false
    for _, floor in ipairs(self.hotel.floors) do
        for _, room in ipairs(floor.rooms) do
            if room.status == BOOKING_STATUS.OCCUPIED and room.occupant then
                local monster = room.occupant

                -- Check if it's time for this monster to check out
                if monster.state == MONSTER_STATE.IN_ROOM then
                    -- Assign checkout time if not set
                    if monster.checkoutHour == 0 then
                        if not firstMonsterFound then
                            -- First monster checks out at 8am (start of morning)
                            monster.checkoutHour = DAY_START_HOUR
                            firstMonsterFound = true
                        else
                            -- Others checkout randomly between 8am and 11am
                            monster.checkoutHour = math.random(DAY_START_HOUR, 11)
                        end
                    end

                    if currentHour >= monster.checkoutHour then
                        monster:exitRoom(monster.checkoutHour)
                    end
                end
            end
        end
    end
end

function GameScene:handleMonsterRages()
    for _, monster in ipairs(self.hotel.monsters) do
        if monster.state == MONSTER_STATE.RAGING then
            -- Already raging, let it continue
        elseif monster.state ~= MONSTER_STATE.IN_ROOM and
               monster.state ~= MONSTER_STATE.EXITING_HOTEL and
               monster.state ~= MONSTER_STATE.ON_SERVICE_FLOOR and
               monster.state ~= MONSTER_STATE.EXITING_SERVICE_FLOOR and
               not (monster.serviceFloor ~= nil and monster.state == MONSTER_STATE.EXITING_TO_ROOM) then
            -- Check patience (monsters on/heading to service floors don't lose patience)
            local patience = monster:getCalculatedPatience(
                self.hotel.lobby,
                self.hotel.elevator,
                monster.assignedRoom
            )

            if patience <= 0 then
                -- Monster has lost patience - START RAGE!
                monster:startRage()

                -- Show rage message
                MessageOverlay:show(MessageOverlay.MESSAGES.MONSTER_RAGE)

                -- Process damage
                EconomySystem:processDamage(monster)

                -- Track rage for stats
                self.hotel.totalRages = self.hotel.totalRages + 1

                -- Remove from elevator if inside
                self.hotel.elevator:removePassenger(monster)

                -- Remove from lobby if inside
                self.hotel.lobby:removeMonster(monster)

                -- Remove from service floor if inside
                if monster.serviceFloor then
                    monster.serviceFloor:removeServiceMonster(monster)
                    monster.serviceFloor = nil
                end
            end
        end
    end
end

function GameScene:handleServiceFloorResets()
    -- Check all service floors for monsters who were walking to elevator when it left
    local elevator = self.hotel.elevator

    for _, floor in ipairs(self.hotel.floors) do
        if floor:isServiceFloor() then
            -- Only reset if elevator is NOT at this floor (ignore door state)
            local elevatorAtThisFloor = elevator.currentFloor == floor.floorNumber

            if not elevatorAtThisFloor then
                -- Elevator left this floor - reset any monsters trying to board
                for _, monster in ipairs(floor.serviceMonsters) do
                    if monster.state == MONSTER_STATE.EXITING_SERVICE_FLOOR then
                        monster:enterServiceFloor()
                        local targetX, targetY = floor:getServiceWaitPosition(monster.serviceFloorIndex)
                        monster:setTarget(targetX, targetY)
                    end
                end
            end
        end
    end
end

function GameScene:onHourChange(hour)
    -- Hour changed - could trigger events
end

function GameScene:rageOutServiceFloorMonsters()
    -- At day end, all monsters on service floors rage out
    for _, floor in ipairs(self.hotel.floors) do
        if floor:isServiceFloor() then
            local monsters = floor:rageOutServiceMonsters()
            for _, monster in ipairs(monsters) do
                -- Start rage
                monster:startRage()
                monster.serviceFloor = nil

                -- Show rage message
                MessageOverlay:show(MessageOverlay.MESSAGES.MONSTER_RAGE)

                -- Process damage
                EconomySystem:processDamage(monster)

                -- Track rage for stats
                self.hotel.totalRages = self.hotel.totalRages + 1
            end
        end
    end
end

function GameScene:onDayEnd()
    self.dayEnding = true

    -- Stop spawning
    SpawnSystem:stop()

    -- Rage out all monsters on service floors before ending day
    self:rageOutServiceFloorMonsters()

    -- Calculate end of day costs
    EconomySystem:endDay()

    -- Check for unlocks
    local gameStats = {
        maxMoney = self.hotel.maxMoneyReached,
        guestsServed = self.hotel.guestsServed,
        maxLevel = self.hotel.level,
        daysCompleted = self.hotel.dayCount,
        totalRages = self.hotel.totalRages
    }
    local newUnlocks = UnlockSystem:checkForUnlocks(gameStats)

    -- Get day summary
    local summary = EconomySystem:getDaySummary()

    -- Save game
    self:saveGame()

    -- Check for game over
    if self.hotel:isGameOver() then
        SceneManager:switch(GameOverScene, {
            hotel = self.hotel,
            summary = summary
        })
    else
        -- Go to day end scene
        SceneManager:switch(DayEndScene, {
            hotel = self.hotel,
            summary = summary,
            newUnlocks = newUnlocks,
            saveSlot = self.saveSlot
        })
    end
end

function GameScene:onMonsterSpawned(monster)
    -- Set unlockable patience bonus
    monster.unlockablePatience = UnlockSystem:getTotalPatienceBonus()
end

function GameScene:onMoneyChanged(amount, reason)
    HUD:showMoneyChange(amount)
end

function GameScene:onDamage(amount, monster)
    -- Could add screen shake or other effects
end

function GameScene:onHotelLevelUp(changes)
    -- Pause game and show level up notification
    self.showingLevelUp = true
    self.levelUpInfo = changes
    self.isPaused = true

    -- Restart gameplay music on level up
    MusicSystem:restartGameplayMusic()

    -- Service floor message will be shown when level up notification is dismissed
    -- (see dismissLevelUp)
end

function GameScene:dismissLevelUp()
    -- Check if we need to show service floor message after dismissing level up
    local showServiceFloorMessage = self.levelUpInfo and self.levelUpInfo.serviceFloorAdded

    self.showingLevelUp = false
    self.levelUpInfo = nil
    self.isPaused = false

    -- Show service floor tutorial AFTER level up notification is dismissed
    if showServiceFloorMessage then
        MessageOverlay:show(MessageOverlay.MESSAGES.SERVICE_FLOOR)
    end
end

function GameScene:toggleElevatorDoors()
    -- Show tutorial on first door toggle
    MessageOverlay:show(MessageOverlay.MESSAGES.ELEVATOR_DOORS)
    -- Actually toggle the doors
    self.hotel.elevator:toggleDoors()
end

function GameScene:drawLevelUpNotification()
    -- Validate levelUpInfo exists and has required fields
    if not self.levelUpInfo or not self.levelUpInfo.newLevel then
        -- Invalid state - dismiss the notification
        self:dismissLevelUp()
        return
    end

    -- Draw semi-transparent overlay
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    gfx.setDitherPattern(0)

    -- Calculate box height based on content
    local numChanges = 0
    if (self.levelUpInfo.floorsAdded or 0) > 0 then numChanges = numChanges + 1 end
    if self.levelUpInfo.elevatorName then numChanges = numChanges + 1 end
    if self.levelUpInfo.lobbyCapacity then numChanges = numChanges + 1 end

    local boxWidth = 300
    local boxHeight = 100 + (numChanges * 18)
    local boxX = (SCREEN_WIDTH - boxWidth) / 2
    local boxY = (SCREEN_HEIGHT - boxHeight) / 2

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(boxX, boxY, boxWidth, boxHeight, 8)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(boxX, boxY, boxWidth, boxHeight, 8)
    gfx.drawRoundRect(boxX + 1, boxY + 1, boxWidth - 2, boxHeight - 2, 7)

    -- Draw title
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned("LEVEL UP!", SCREEN_WIDTH / 2, boxY + 12, kTextAlignment.center)

    -- Draw new level
    Fonts.reset()
    local levelText = "Hotel is now Level " .. self.levelUpInfo.newLevel
    gfx.drawTextAligned(levelText, SCREEN_WIDTH / 2, boxY + 38, kTextAlignment.center)

    -- Draw changes
    local y = boxY + 60
    local floorsAdded = self.levelUpInfo.floorsAdded or 0
    if floorsAdded > 0 then
        local floorText = "+ " .. floorsAdded .. " new floor" .. (floorsAdded > 1 and "s" or "")
        gfx.drawTextAligned(floorText, SCREEN_WIDTH / 2, y, kTextAlignment.center)
        y = y + 18
    end

    if self.levelUpInfo.elevatorName then
        local elevatorText = "New elevator: " .. self.levelUpInfo.elevatorName
        gfx.drawTextAligned(elevatorText, SCREEN_WIDTH / 2, y, kTextAlignment.center)
        y = y + 18
    end

    if self.levelUpInfo.lobbyCapacity then
        local lobbyText = "Lobby capacity: " .. self.levelUpInfo.lobbyCapacity
        gfx.drawTextAligned(lobbyText, SCREEN_WIDTH / 2, y, kTextAlignment.center)
        y = y + 18
    end

    -- Draw continue prompt
    Fonts.set(gfx.font.kVariantItalic)
    gfx.drawTextAligned("Press any button to continue", SCREEN_WIDTH / 2, boxY + boxHeight - 22, kTextAlignment.center)
end

function GameScene:drawNoVacancyDialog()
    -- Draw semi-transparent overlay
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    gfx.setDitherPattern(0)

    -- Draw dialog box
    local boxWidth = 220
    local boxHeight = 100
    local boxX = (SCREEN_WIDTH - boxWidth) / 2
    local boxY = (SCREEN_HEIGHT - boxHeight) / 2

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(boxX, boxY, boxWidth, boxHeight, 8)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(boxX, boxY, boxWidth, boxHeight, 8)
    gfx.drawRoundRect(boxX + 1, boxY + 1, boxWidth - 2, boxHeight - 2, 7)

    -- Draw title
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned("NO VACANCY", SCREEN_WIDTH / 2, boxY + 22, kTextAlignment.center)

    -- Draw message
    Fonts.reset()
    gfx.drawTextAligned("All rooms occupied!", SCREEN_WIDTH / 2, boxY + 48, kTextAlignment.center)

    -- Draw continue prompt
    Fonts.set(gfx.font.kVariantItalic)
    gfx.drawTextAligned("Press Any Button to Continue", SCREEN_WIDTH / 2, boxY + boxHeight - 24, kTextAlignment.center)
end

function GameScene:dismissNoVacancy()
    self.showingNoVacancy = false
    self.isPaused = false
    TimeSystem:skipToMorning()
end

function GameScene:draw()
    -- Clear screen
    gfx.clear(gfx.kColorWhite)

    -- Apply camera offset for world drawing
    gfx.setDrawOffset(0, -self.cameraY)

    -- Draw hotel (floors, lobby, elevator)
    self.hotel:draw()

    -- Draw patience indicators
    PatienceIndicator:drawAll(self.hotel.monsters, self.hotel.lobby,
                               self.hotel.elevator, self.cameraY)

    -- Reset offset for UI elements (screen-space)
    gfx.setDrawOffset(0, 0)

    -- Draw room indicators
    RoomIndicator:draw()

    -- Draw HUD
    HUD:draw()
    HUD:drawElevatorInfo(self.hotel.elevator)

    -- Draw level-up notification on top of everything
    if self.showingLevelUp and self.levelUpInfo then
        self:drawLevelUpNotification()
    end

    -- Draw No Vacancy dialog on top of everything
    if self.showingNoVacancy then
        self:drawNoVacancyDialog()
    end

    -- Draw crank indicator only if crank is docked
    if self.showCrankIndicator then
        playdate.ui.crankIndicator:update()
    end

    -- Draw tutorial overlay on top of everything
    MessageOverlay:draw()
end

function GameScene:cranked(change, acceleratedChange)
    if self.isPaused then return end
    self.hotel.elevator:handleCrank(change)
end

function GameScene:upButtonDown()
    if self.isPaused then return end
    -- D-pad up as elevator control alternative
end

function GameScene:downButtonDown()
    if self.isPaused then return end
    -- D-pad down as elevator control alternative
end

function GameScene:leftButtonDown()
    -- Dismiss level-up notification with any button
    if self.showingLevelUp then
        self:dismissLevelUp()
        return
    end

    -- Dismiss No Vacancy dialog with any button
    if self.showingNoVacancy then
        self:dismissNoVacancy()
        return
    end

    if self.isPaused then return end
    self:toggleElevatorDoors()
end

function GameScene:rightButtonDown()
    -- Dismiss level-up notification with any button
    if self.showingLevelUp then
        self:dismissLevelUp()
        return
    end

    -- Dismiss No Vacancy dialog with any button
    if self.showingNoVacancy then
        self:dismissNoVacancy()
        return
    end

    if self.isPaused then return end
    self:toggleElevatorDoors()
end

function GameScene:AButtonDown()
    -- Dismiss level-up notification with any button
    if self.showingLevelUp then
        self:dismissLevelUp()
        return
    end

    -- Dismiss No Vacancy dialog with any button
    if self.showingNoVacancy then
        self:dismissNoVacancy()
        return
    end

    if self.isPaused then return end
    self:toggleElevatorDoors()
end

function GameScene:BButtonDown()
    -- Dismiss level-up notification with any button
    if self.showingLevelUp then
        self:dismissLevelUp()
        return
    end

    -- Dismiss No Vacancy dialog with B button
    if self.showingNoVacancy then
        self:dismissNoVacancy()
        return
    end

    if self.isPaused then return end

    -- Otherwise, toggle elevator doors
    self:toggleElevatorDoors()
end

function GameScene:saveGame()
    SaveSystem:save(self.saveSlot, self.hotel, TimeSystem:serialize())
end

function GameScene:startNextDay()
    -- Reset for next day
    self.hotel.dayCount = self.hotel.dayCount + 1
    self.hotel:resetDailyStats()
    TimeSystem:reset()
    EconomySystem:startNewDay()
    SpawnSystem:start()
    self.dayEnding = false

    -- Reset patience for all monsters (they had a good night's sleep!)
    for _, monster in ipairs(self.hotel.monsters) do
        monster:resetPatience()
    end

    -- Restart gameplay music for new day
    MusicSystem:restartGameplayMusic()

    -- Save at start of new day
    self:saveGame()
end

function GameScene:crankDocked()
    -- Show crank indicator when crank is docked
    self.showCrankIndicator = true
    playdate.ui.crankIndicator:start()
end

function GameScene:crankUndocked()
    -- Hide crank indicator when crank is undocked
    self.showCrankIndicator = false
end

return GameScene
