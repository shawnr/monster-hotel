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

    -- Game state
    self.isPaused = false
    self.dayEnding = false
    self.canSkipToMorning = false

    -- Level up notification
    self.showingLevelUp = false
    self.levelUpInfo = nil

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

    -- Update time
    TimeSystem:update()

    -- Update hotel (includes elevator and monsters)
    self.hotel:update()

    -- Update UI
    HUD:update()
    PatienceIndicator:update()
    RoomIndicator:update(self.hotel, self.cameraY)

    -- Update camera to follow elevator
    self:updateCamera()

    -- Handle monster-elevator interactions
    self:handleElevatorInteractions()

    -- Check for checkouts in morning
    if TimeSystem:isMorning() then
        self:handleMorningCheckouts()
    end

    -- Handle monster rages
    self:handleMonsterRages()

    -- Check if player can skip to morning (all rooms booked, past checkout time)
    self.canSkipToMorning = self:checkCanSkipToMorning()
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
        for _, monster in ipairs(self.hotel.monsters) do
            if monster.state == MONSTER_STATE.ENTERING_ELEVATOR and
               monster:isAtTarget() and elevator:canAcceptPassenger() then
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
        -- At a guest floor
        local currentFloor = self.hotel.floors[elevator.currentFloor]
        if not currentFloor then return end

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
                monster:setPosition(ELEVATOR_X + ELEVATOR_WIDTH / 2, currentFloor.y + FLOOR_HEIGHT - 5)
                monster:exitElevatorToRoom(monster.assignedRoom.doorX, currentFloor.y)

                -- Track the check-in
                self.hotel:recordCheckIn()
            end
        end

        -- Let checkout monsters board the elevator
        local elevatorCenterX = ELEVATOR_X + ELEVATOR_WIDTH / 2
        for _, monster in ipairs(self.hotel.monsters) do
            local monsterFloor = monster.assignedRoom and monster.assignedRoom.floorNumber or 0

            if monsterFloor == elevator.currentFloor then
                if monster.state == MONSTER_STATE.WAITING_TO_CHECKOUT and elevator:canAcceptPassenger() then
                    -- Start moving toward elevator center
                    monster:startCheckout(elevatorCenterX)
                elseif monster.state == MONSTER_STATE.CHECKING_OUT then
                    -- Check if monster is close to elevator (use proximity, not exact position)
                    local distanceToElevator = math.abs(monster.x - elevatorCenterX)
                    if distanceToElevator < 20 and elevator:canAcceptPassenger() then
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
                -- Monster was checking out but elevator left - reset to waiting at door
                -- This prevents monsters getting stuck mid-checkout
                monster.state = MONSTER_STATE.WAITING_TO_CHECKOUT
                if monster.assignedRoom then
                    local doorCenterX = monster.assignedRoom.doorX + 19
                    local floorY = monster.assignedRoom.y + FLOOR_HEIGHT - 5
                    monster:setTarget(doorCenterX, floorY)
                end
            end
        end
    end
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
               monster.state ~= MONSTER_STATE.EXITING_HOTEL then
            -- Check patience
            local patience = monster:getCalculatedPatience(
                self.hotel.lobby,
                self.hotel.elevator,
                monster.assignedRoom
            )

            if patience <= 0 then
                -- Monster has lost patience - START RAGE!
                monster:startRage()

                -- Process damage
                EconomySystem:processDamage(monster)

                -- Track rage for stats
                self.hotel.totalRages = self.hotel.totalRages + 1

                -- Remove from elevator if inside
                self.hotel.elevator:removePassenger(monster)

                -- Remove from lobby if inside
                self.hotel.lobby:removeMonster(monster)
            end
        end
    end
end

function GameScene:onHourChange(hour)
    -- Hour changed - could trigger events
end

function GameScene:onDayEnd()
    self.dayEnding = true

    -- Stop spawning
    SpawnSystem:stop()

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
end

function GameScene:dismissLevelUp()
    self.showingLevelUp = false
    self.levelUpInfo = nil
    self.isPaused = false
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

    -- Draw skip to morning indicator if available
    if self.canSkipToMorning then
        Fonts.set(gfx.font.kVariantBold)
        local skipText = "B: Skip to Morning"
        local textWidth, textHeight = gfx.getTextSize(skipText)
        local x = SCREEN_WIDTH - textWidth - 10
        local y = 25

        -- Draw background
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x - 4, y - 2, textWidth + 8, textHeight + 4)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(x - 4, y - 2, textWidth + 8, textHeight + 4)
        gfx.drawText(skipText, x, y)
    end

    -- Draw level-up notification on top of everything
    if self.showingLevelUp and self.levelUpInfo then
        self:drawLevelUpNotification()
    end
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
    if self.isPaused then return end
    self.hotel.elevator:toggleDoors()
end

function GameScene:rightButtonDown()
    -- Dismiss level-up notification with any button
    if self.showingLevelUp then
        self:dismissLevelUp()
        return
    end
    if self.isPaused then return end
    self.hotel.elevator:toggleDoors()
end

function GameScene:AButtonDown()
    -- Dismiss level-up notification with any button
    if self.showingLevelUp then
        self:dismissLevelUp()
        return
    end
    if self.isPaused then return end
    self.hotel.elevator:toggleDoors()
end

function GameScene:BButtonDown()
    -- Dismiss level-up notification with any button
    if self.showingLevelUp then
        self:dismissLevelUp()
        return
    end
    if self.isPaused then return end

    -- If skip to morning is available, use B to skip
    if self.canSkipToMorning then
        TimeSystem:skipToMorning()
        return
    end

    -- Otherwise, toggle elevator doors
    self.hotel.elevator:toggleDoors()
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

    -- Save at start of new day
    self:saveGame()
end

function GameScene:crankDocked()
    -- Show crank indicator
end

function GameScene:crankUndocked()
    -- Hide crank indicator
end

return GameScene
