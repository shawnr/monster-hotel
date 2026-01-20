-- Monster Hotel - Monster Entity

import "data/monsterData"

local gfx <const> = playdate.graphics

-- Monster is NOT a sprite - we draw manually for simplicity
class('Monster').extends()

-- Static counter for unique IDs
Monster.nextId = 1

-- Static cache for loaded sprite tables (avoid reloading for each monster)
Monster.spriteTables = {}

function Monster:init(monsterData, assignedRoom)
    Monster.super.init(self)

    -- Unique identifier
    self.id = Monster.nextId
    Monster.nextId = Monster.nextId + 1

    -- Monster data from definition
    self.data = monsterData
    self.name = monsterData.name

    -- Assigned room
    self.assignedRoom = assignedRoom

    -- State machine
    self.state = MONSTER_STATE.WAITING_IN_LOBBY

    -- Position
    self.x = 0
    self.y = 0

    -- Movement
    self.targetX = 0
    self.targetY = 0
    self.moveTickCounter = 0

    -- Patience tracking
    self.timeSpent = 0  -- In game ticks
    self.basePatience = monsterData.basePatience

    -- Lobby index (for positioning)
    self.lobbyIndex = 0

    -- Checkout time (set when checking out)
    self.checkoutHour = 0

    -- Animation state
    self.spriteTable = nil
    self.currentFrame = 1
    self.animationTimer = 0

    -- Store frame dimensions for drawing
    self.frameWidth = monsterData.frameWidth or 28
    self.frameHeight = monsterData.frameHeight or 36

    -- Visibility flag (since we don't use sprite system)
    self.visible = true
end

function Monster:getIcon()
    return self.data.icon
end

function Monster:update()
    -- Increment time spent (patience drain)
    if self.state ~= MONSTER_STATE.IN_ROOM and
       self.state ~= MONSTER_STATE.EXITING_HOTEL then
        self.timeSpent = self.timeSpent + 1
    end

    -- Note: Rage checking is handled by gameScene:handleMonsterRages()
    -- which has access to lobby/elevator for proper patience calculation

    -- Update based on state
    if self.state == MONSTER_STATE.WAITING_IN_LOBBY then
        self:updateWaitingInLobby()
    elseif self.state == MONSTER_STATE.ENTERING_ELEVATOR then
        self:updateEnteringElevator()
    elseif self.state == MONSTER_STATE.RIDING_ELEVATOR then
        self:updateRidingElevator()
    elseif self.state == MONSTER_STATE.EXITING_TO_ROOM then
        self:updateExitingToRoom()
    elseif self.state == MONSTER_STATE.IN_ROOM then
        -- Nothing to do, waiting for checkout time
    elseif self.state == MONSTER_STATE.WAITING_TO_CHECKOUT then
        self:updateWaitingToCheckout()
    elseif self.state == MONSTER_STATE.CHECKING_OUT then
        self:updateCheckingOut()
    elseif self.state == MONSTER_STATE.RAGING then
        self:updateRaging()
    elseif self.state == MONSTER_STATE.EXITING_HOTEL then
        self:updateExitingHotel()
    end

    -- Move towards target (but not when riding elevator or in room)
    if self.state ~= MONSTER_STATE.RIDING_ELEVATOR and
       self.state ~= MONSTER_STATE.IN_ROOM then
        self:moveTowardsTarget()
    end
end

function Monster:moveTowardsTarget()
    self.moveTickCounter = self.moveTickCounter + 1
    if self.moveTickCounter < MONSTER_MOVE_TICKS then
        return
    end
    self.moveTickCounter = 0

    local speed = MONSTER_TILE_SIZE + self.data.speed

    -- Move towards target X
    if math.abs(self.x - self.targetX) > speed then
        if self.x < self.targetX then
            self.x = self.x + speed
        else
            self.x = self.x - speed
        end
    else
        self.x = self.targetX
    end

    -- Move towards target Y
    if math.abs(self.y - self.targetY) > speed then
        if self.y < self.targetY then
            self.y = self.y + speed
        else
            self.y = self.y - speed
        end
    else
        self.y = self.targetY
    end
end

function Monster:isAtTarget()
    return self.x == self.targetX and self.y == self.targetY
end

function Monster:setPosition(x, y)
    self.x = x
    self.y = y
    self.targetX = x
    self.targetY = y
end

function Monster:setTarget(x, y)
    self.targetX = x
    self.targetY = y
end

-- State update functions
function Monster:updateWaitingInLobby()
    -- Wait for elevator doors to open
    -- Movement to elevator handled by game scene
end

function Monster:updateEnteringElevator()
    -- Moving into elevator - gameScene handles boarding when at target
end

function Monster:updateRidingElevator()
    -- Position is updated by elevator
    -- Waiting for floor
end

function Monster:updateExitingToRoom()
    if self:isAtTarget() then
        -- Arrived at room
        self:enterRoom()
    end
end

function Monster:updateWaitingToCheckout()
    -- Wait for elevator doors to open
end

function Monster:updateCheckingOut()
    -- Moving into elevator for checkout - gameScene handles boarding when at target
end

function Monster:updateRaging()
    -- Storm towards exit
    if self:isAtTarget() then
        self:exitHotel()
    end
end

function Monster:updateExitingHotel()
    -- Monster removal is handled by Hotel:update() when state is EXITING_HOTEL and at target
end

-- State transitions
function Monster:startMovingToElevator(elevatorX, lobbyY)
    self.state = MONSTER_STATE.ENTERING_ELEVATOR
    self:setTarget(elevatorX, lobbyY)
end

function Monster:enterElevator()
    self.state = MONSTER_STATE.RIDING_ELEVATOR
end

function Monster:exitElevatorToRoom(roomDoorX, floorY)
    self.state = MONSTER_STATE.EXITING_TO_ROOM
    self:setTarget(roomDoorX, floorY + FLOOR_HEIGHT - 16)
end

function Monster:enterRoom()
    self.state = MONSTER_STATE.IN_ROOM
    if self.assignedRoom then
        self.assignedRoom:checkIn(self)
    end
    -- Reset time spent for checkout phase
    self.timeSpent = 0
    -- Hide while in room
    self.visible = false
end

function Monster:exitRoom(checkoutHour)
    self.state = MONSTER_STATE.WAITING_TO_CHECKOUT
    self.checkoutHour = checkoutHour
    -- Reset time spent for checkout patience
    self.timeSpent = 0
    -- Show sprite
    self.visible = true
    -- Position at room door and set target to elevator waiting area
    if self.assignedRoom then
        local floorY = self.assignedRoom.y + FLOOR_HEIGHT - 16
        self:setPosition(self.assignedRoom.doorX, floorY)
        -- Walk to elevator waiting area (just left of elevator)
        self:setTarget(ELEVATOR_X - 25, floorY)
    end
end

function Monster:startCheckout(elevatorX)
    self.state = MONSTER_STATE.CHECKING_OUT
    self:setTarget(elevatorX, self.y)
end

function Monster:isNearElevator()
    -- Check if monster is close to the elevator shaft
    return math.abs(self.x - ELEVATOR_X) < 40
end

function Monster:exitElevatorToLobby(lobbyExitX, lobbyY)
    self.state = MONSTER_STATE.EXITING_HOTEL
    self:setTarget(lobbyExitX, lobbyY + FLOOR_HEIGHT - 16)
end

function Monster:startRage()
    self.state = MONSTER_STATE.RAGING

    -- Cancel room assignment if not checked in yet
    if self.assignedRoom and self.assignedRoom.occupant ~= self then
        self.assignedRoom:cancelAssignment()
    end

    -- Set target to nearest exit (lobby)
    self:setTarget(SCREEN_WIDTH - 30, self.y)
end

function Monster:exitHotel()
    self.state = MONSTER_STATE.EXITING_HOTEL
    self:setTarget(SCREEN_WIDTH + 20, self.y)
end

-- Patience calculations
function Monster:getCalculatedPatience(lobby, elevator, room)
    -- Base patience + modifiers - time spent
    local patienceBonus = 0

    if lobby then
        patienceBonus = patienceBonus + lobby.patienceModifier
    end
    if elevator then
        patienceBonus = patienceBonus + elevator.patienceModifier
    end
    if room then
        patienceBonus = patienceBonus + room:getPatienceModifier()
    end

    -- Add unlockable patience bonus (passed from game)
    patienceBonus = patienceBonus + (self.unlockablePatience or 0)

    -- Convert time spent from ticks to seconds
    local timeSpentSeconds = self.timeSpent / GAME_TICK_RATE

    return (patienceBonus * self.basePatience) - timeSpentSeconds
end

function Monster:getPatiencePercentage(lobby, elevator, room)
    local current = self:getCalculatedPatience(lobby, elevator, room)
    local max = self.basePatience
    return Utils.clamp(current / max, 0, 1)
end

function Monster:getPatienceWarningLevel(lobby, elevator, room)
    local pct = 1 - self:getPatiencePercentage(lobby, elevator, room)

    if pct >= PATIENCE_WARN_3 then
        return 3
    elseif pct >= PATIENCE_WARN_2 then
        return 2
    elseif pct >= PATIENCE_WARN_1 then
        return 1
    end
    return 0
end

function Monster:getDamageCost(hotelLevel)
    return self.data.baseDamage + (self.timeSpent / GAME_TICK_RATE) * hotelLevel
end

function Monster:draw()
    -- Always draw a simple visible monster shape (don't rely on sprites)
    local w = 20
    local h = 30

    -- Draw body (filled rectangle)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(self.x - w/2, self.y - h, w, h)

    -- Draw initial in white
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    local initial = string.sub(self.name, 1, 1)
    gfx.drawTextAligned(initial, self.x, self.y - h/2 - 6, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw rage indicator
    if self.state == MONSTER_STATE.RAGING then
        gfx.drawText("!!!", self.x - 8, self.y - h - 12)
    end
end

function Monster:serialize()
    return {
        id = self.id,
        dataId = self.data.id,
        state = self.state,
        x = self.x,
        y = self.y,
        targetX = self.targetX,
        targetY = self.targetY,
        timeSpent = self.timeSpent,
        lobbyIndex = self.lobbyIndex,
        checkoutHour = self.checkoutHour,
        assignedRoomNumber = self.assignedRoom and self.assignedRoom.roomNumber or nil,
        assignedRoomFloor = self.assignedRoom and self.assignedRoom.floorNumber or nil
    }
end

function Monster.deserialize(data, rooms)
    local monsterData = MonsterData.getById(data.dataId)
    if not monsterData then return nil end

    -- Find assigned room
    local assignedRoom = nil
    if data.assignedRoomFloor and data.assignedRoomNumber and rooms then
        for _, room in ipairs(rooms) do
            if room.floorNumber == data.assignedRoomFloor and
               room.roomNumber == data.assignedRoomNumber then
                assignedRoom = room
                break
            end
        end
    end

    local monster = Monster(monsterData, assignedRoom)
    monster.id = data.id
    monster.state = data.state
    monster.x = data.x
    monster.y = data.y
    monster.targetX = data.targetX
    monster.targetY = data.targetY
    monster.timeSpent = data.timeSpent
    monster.lobbyIndex = data.lobbyIndex
    monster.checkoutHour = data.checkoutHour

    -- Update next ID counter
    if data.id >= Monster.nextId then
        Monster.nextId = data.id + 1
    end

    return monster
end

return Monster
