-- Monster Hotel - Spawn System
-- Handles monster spawning logic

import "data/monsterData"

SpawnSystem = {}

function SpawnSystem:init(hotel, timeSystem)
    self.hotel = hotel
    self.timeSystem = timeSystem
    self.spawnTimer = nil
    self.enabled = true

    -- Callbacks
    self.onMonsterSpawned = nil
end

function SpawnSystem:start()
    self.enabled = true
    self:setupTimer()
end

function SpawnSystem:stop()
    self.enabled = false
    if self.spawnTimer then
        self.spawnTimer:remove()
        self.spawnTimer = nil
    end
end

function SpawnSystem:setupTimer()
    if self.spawnTimer then
        self.spawnTimer:remove()
    end

    self.spawnTimer = playdate.timer.new(SPAWN_CHECK_INTERVAL, function()
        self:trySpawn()
    end)
    self.spawnTimer.repeats = true
end

function SpawnSystem:trySpawn()
    if not self.enabled then return end
    if not self:canSpawn() then return end

    -- Calculate spawn chance
    local hour = self.timeSystem:getHour()
    local baseChance = BASE_SPAWN_CHANCE + hour
    local modifier = self.timeSystem:getSpawnModifier()
    local chance = baseChance * modifier

    -- Roll for spawn
    if math.random(100) <= chance then
        self:spawnMonster()
    end
end

function SpawnSystem:canSpawn()
    -- No spawning during morning checkout period (8am - noon)
    if self.timeSystem:isMorning() then
        return false
    end

    -- Check if lobby has space
    if not self.hotel.lobby:canAcceptMonster() then
        return false
    end

    -- Check if there are available rooms
    if self.hotel:getAvailableRoomCount() <= 0 then
        return false
    end

    return true
end

function SpawnSystem:spawnMonster()
    -- Get random monster type for current hotel level
    local monsterData = MonsterData.getRandomMonster(self.hotel.level)
    if not monsterData then return nil end

    -- Find an available room
    local room = self.hotel:getAvailableRoom()
    if not room then return nil end

    -- Create monster
    local monster = Monster(monsterData, room)

    -- Assign room to monster
    room:assignMonster(monster)

    -- Add to hotel and lobby first (so lobbyIndex is set)
    self.hotel:addMonster(monster)
    self.hotel.lobby:addMonster(monster)

    -- Position monster at lobby entrance (monster feet at floor bottom)
    local lobbyFloorY = self.hotel.lobby.y + FLOOR_HEIGHT - 5
    monster:setPosition(self.hotel.lobby.entryX - 40, lobbyFloorY)

    -- Set target to their queue position in lobby
    local waitX, waitY = self.hotel.lobby:getWaitPosition(monster.lobbyIndex)
    monster:setTarget(waitX, waitY)

    -- Notify
    if self.onMonsterSpawned then
        self.onMonsterSpawned(monster)
    end

    return monster
end

function SpawnSystem:forceSpawn()
    -- Force spawn a monster (for testing or special events)
    if self:canSpawn() then
        return self:spawnMonster()
    end
    return nil
end

function SpawnSystem:getSpawnChance()
    -- Get current spawn chance for display
    local hour = self.timeSystem:getHour()
    local baseChance = BASE_SPAWN_CHANCE + hour
    local modifier = self.timeSystem:getSpawnModifier()
    return math.floor(baseChance * modifier)
end

return SpawnSystem
