-- Monster Hotel - Monster Entity

import "data/monsterData"

local gfx <const> = playdate.graphics

-- Monster is NOT a sprite - we draw manually for simplicity
class('Monster').extends()

-- Static counter for unique IDs
Monster.nextId = 1

-- Static cache for loaded sprite tables and icons (avoid reloading for each monster)
Monster.spriteTables = {}
Monster.iconImages = {}

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

    -- Explicit flag to track if this monster is checking out (vs checking in)
    self.isCheckingOut = false

    -- Animation state
    self.currentFrame = 1
    self.animationTimer = 0
    self.animationSpeed = 10  -- Frames between animation updates (slower for better walk cycle visibility)
    self.facingRight = true  -- Direction monster is facing
    self.wasMoving = false   -- Track if we were moving last frame

    -- Store frame dimensions for drawing
    self.frameWidth = monsterData.frameWidth or 32
    self.frameHeight = monsterData.frameHeight or 32

    -- Load sprite table if not already cached
    self:loadSprites()

    -- Visibility flag (since we don't use sprite system)
    self.visible = true
end

function Monster:loadSprites()
    local spritePath = self.data.spriteTable
    local iconPath = self.data.icon

    -- Load sprite table if not cached
    if spritePath and not Monster.spriteTables[spritePath] then
        Monster.spriteTables[spritePath] = gfx.imagetable.new(spritePath)
    end
    self.spriteTable = Monster.spriteTables[spritePath]

    -- Load icon if not cached
    if iconPath and not Monster.iconImages[iconPath] then
        Monster.iconImages[iconPath] = gfx.image.new(iconPath)
    end
    self.iconImage = Monster.iconImages[iconPath]
end

function Monster:getIcon()
    return self.data.icon
end

function Monster:getIconImage()
    return self.iconImage
end

function Monster:update()
    -- Increment time spent (patience drain)
    -- Only count time when monster is visible and actively waiting/moving
    -- Don't count time when: in room, invisible (waiting inside room), or exiting
    if self.visible and
       self.state ~= MONSTER_STATE.IN_ROOM and
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

    -- Update animation
    self:updateAnimation()
end

function Monster:updateAnimation()
    -- Check if we should be animating based on state (not just position)
    local isMovingState = self.state == MONSTER_STATE.ENTERING_ELEVATOR or
                          self.state == MONSTER_STATE.EXITING_TO_ROOM or
                          self.state == MONSTER_STATE.CHECKING_OUT or
                          self.state == MONSTER_STATE.EXITING_HOTEL or
                          self.state == MONSTER_STATE.RAGING
    local isMovingToTarget = (self.x ~= self.targetX or self.y ~= self.targetY)
    local shouldAnimate = isMovingState or isMovingToTarget

    if shouldAnimate then
        self.animationTimer = self.animationTimer + 1
        if self.animationTimer >= self.animationSpeed then
            self.animationTimer = 0
            if self.spriteTable then
                local frameCount = self.spriteTable:getLength()
                self.currentFrame = (self.currentFrame % frameCount) + 1
            end
        end

        -- Update facing direction based on target
        if self.targetX > self.x then
            self.facingRight = true
        elseif self.targetX < self.x then
            self.facingRight = false
        end
    else
        -- Reset to first frame when idle
        self.currentFrame = 1
        self.animationTimer = 0
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
    -- Target the center of the door (door is 38px wide)
    self:setTarget(roomDoorX + 19, floorY + FLOOR_HEIGHT - 5)
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
    -- Mark as checking out (used to identify checkout vs check-in monsters in elevator)
    self.isCheckingOut = true
    -- Reset time spent for checkout patience
    self.timeSpent = 0
    -- Exit room and become visible - walk to elevator shaft to wait
    self.visible = true
    -- Start at room door position
    if self.assignedRoom then
        local floorY = self.assignedRoom.y + FLOOR_HEIGHT - 5
        local doorCenterX = self.assignedRoom.doorX + 19  -- Center of 38px door
        self:setPosition(doorCenterX, floorY)
        -- Target: just to the right of elevator doors (wait position)
        local elevatorWaitX = ELEVATOR_X + ELEVATOR_WIDTH + 10
        self:setTarget(elevatorWaitX, floorY)
    end
end

function Monster:startBoardingElevator(elevatorCenterX)
    -- Called when elevator arrives with doors open and monster is waiting at shaft
    -- Start walking into the elevator
    self.state = MONSTER_STATE.CHECKING_OUT
    self:setTarget(elevatorCenterX, self.y)
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
    self:setTarget(lobbyExitX, lobbyY + FLOOR_HEIGHT - 5)
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

-- Reset patience (called at start of new day)
function Monster:resetPatience()
    self.timeSpent = 0
end

-- Patience calculations
function Monster:getCalculatedPatience(lobby, elevator, room)
    -- Base patience + bonus from upgrades - time spent waiting
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

    -- Additive formula: each point of bonus adds 1 second of patience
    -- This keeps patience tight even at higher levels
    return self.basePatience + patienceBonus - timeSpentSeconds
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
    -- Draw at 1.75x scale (56x56 from 32x32 sprites)
    local scale = 1.75
    local scaledWidth = self.frameWidth * scale
    local scaledHeight = self.frameHeight * scale

    -- Position: x is center, y is feet position (bottom of sprite)
    local drawX = self.x - scaledWidth / 2
    local drawY = self.y - scaledHeight

    -- Draw sprite if available
    if self.spriteTable then
        local frame = self.spriteTable:getImage(self.currentFrame)
        if frame then
            if self.facingRight then
                frame:drawScaled(drawX, drawY, scale)
            else
                -- Flip horizontally when facing left
                frame:drawScaled(drawX + scaledWidth, drawY, -scale, scale)
            end
        end
    else
        -- Fallback: draw simple rectangle if no sprite
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(drawX, drawY, scaledWidth, scaledHeight)

        -- Draw initial in white
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
        local initial = string.sub(self.name, 1, 1)
        gfx.drawTextAligned(initial, self.x, self.y - scaledHeight/2 - 6, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Draw rage indicator
    if self.state == MONSTER_STATE.RAGING then
        gfx.drawText("!!!", self.x - 8, drawY - 12)
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
        isCheckingOut = self.isCheckingOut,
        visible = self.visible,
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
    monster.isCheckingOut = data.isCheckingOut or false

    -- Restore visibility from save data, or set based on state for backward compatibility
    if data.visible ~= nil then
        monster.visible = data.visible
    else
        -- Set visibility based on state (for old saves without visible flag)
        monster.visible = not (data.state == MONSTER_STATE.IN_ROOM or
                               data.state == MONSTER_STATE.WAITING_TO_CHECKOUT)
    end

    -- Update next ID counter
    if data.id >= Monster.nextId then
        Monster.nextId = data.id + 1
    end

    return monster
end

return Monster
