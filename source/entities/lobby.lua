-- Monster Hotel - Lobby Entity
-- Special floor at the bottom of the hotel

import "data/lobbyData"

local gfx <const> = playdate.graphics

class('Lobby').extends()

-- Static sprite assets (loaded once)
Lobby.backgroundImage = nil
Lobby.elevatorShaft = nil

function Lobby.loadAssets()
    if Lobby.backgroundImage == nil then
        Lobby.backgroundImage = gfx.image.new("images/hotel/lobby-bg")
        Lobby.elevatorShaft = gfx.image.new("images/hotel/elevator-shaft")
    end
end

function Lobby:init(hotelLevel)
    Lobby.super.init(self)

    -- Load assets if not already loaded
    Lobby.loadAssets()

    self.hotelLevel = hotelLevel
    self.floorNumber = 0
    self.floorType = FLOOR_TYPE.LOBBY

    -- Get lobby data for this level
    self:updateStats()

    -- Monsters waiting in lobby
    self.waitingMonsters = {}

    -- Position (always at bottom)
    self.y = 0

    -- Entry point for new monsters
    self.entryX = 10
    -- Elevator waiting point
    self.elevatorWaitX = ELEVATOR_X - 30
end

function Lobby:updateStats()
    local data = LobbyData.getForLevel(self.hotelLevel)
    self.capacity = data.capacity
    self.patienceModifier = data.patienceModifier
    self.operationalCosts = data.operationalCosts
end

function Lobby:setHotelLevel(level)
    self.hotelLevel = level
    self:updateStats()
end

function Lobby:setY(y)
    self.y = y
end

function Lobby:canAcceptMonster()
    return #self.waitingMonsters < self.capacity
end

function Lobby:addMonster(monster)
    if self:canAcceptMonster() then
        table.insert(self.waitingMonsters, monster)
        monster.lobbyIndex = #self.waitingMonsters
        return true
    end
    return false
end

function Lobby:removeMonster(monster)
    for i, m in ipairs(self.waitingMonsters) do
        if m == monster then
            table.remove(self.waitingMonsters, i)
            -- Update indices for remaining monsters
            for j = i, #self.waitingMonsters do
                self.waitingMonsters[j].lobbyIndex = j
            end
            return true
        end
    end
    return false
end

function Lobby:getWaitingMonsters()
    return self.waitingMonsters
end

function Lobby:getMonstersWaitingForElevator()
    local waiting = {}
    for _, monster in ipairs(self.waitingMonsters) do
        if monster.state == MONSTER_STATE.WAITING_IN_LOBBY then
            table.insert(waiting, monster)
        end
    end
    return waiting
end

function Lobby:getMonsterCount()
    return #self.waitingMonsters
end

function Lobby:getWaitPosition(index)
    -- Spread monsters across the lobby (queue from left to right)
    -- With 2x scale, sprites are ~64px wide, use 70px spacing
    local spacing = 70
    local baseX = self.entryX + 40
    local x = baseX + (index - 1) * spacing
    local y = self.y + FLOOR_HEIGHT - 5  -- Monster feet at floor bottom
    return x, y
end

function Lobby:draw()
    -- Draw lobby background (includes "Lobby" text in the image)
    if Lobby.backgroundImage then
        Lobby.backgroundImage:draw(0, self.y)
    end

    -- Draw elevator shaft in the center
    if Lobby.elevatorShaft then
        local shaftX = ELEVATOR_X + (ELEVATOR_WIDTH - ELEVATOR_SHAFT_WIDTH) / 2
        Lobby.elevatorShaft:draw(shaftX, self.y)
    end
end

function Lobby:serialize()
    local monsterIds = {}
    for _, monster in ipairs(self.waitingMonsters) do
        table.insert(monsterIds, monster.id)
    end

    return {
        hotelLevel = self.hotelLevel,
        y = self.y,
        monsterIds = monsterIds
    }
end

function Lobby:deserialize(data, monsters)
    self.y = data.y
    self:setHotelLevel(data.hotelLevel)

    -- Restore monster references
    self.waitingMonsters = {}
    if data.monsterIds and monsters then
        for _, monsterId in ipairs(data.monsterIds) do
            for _, monster in ipairs(monsters) do
                if monster.id == monsterId then
                    self:addMonster(monster)
                    break
                end
            end
        end
    end
end

return Lobby
