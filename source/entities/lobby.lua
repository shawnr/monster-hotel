-- Monster Hotel - Lobby Entity
-- Special floor at the bottom of the hotel

import "data/lobbyData"

local gfx <const> = playdate.graphics

class('Lobby').extends()

-- Static sprite assets (loaded once)
Lobby.tileSprites = nil
Lobby.decorSprites = {}

function Lobby.loadAssets()
    if Lobby.tileSprites == nil then
        Lobby.tileSprites = gfx.imagetable.new("images/tiles/tiles")
        -- Load lobby-specific decorations
        Lobby.decorSprites.clock = gfx.image.new("images/environment/GrandfatherClock")
        Lobby.decorSprites.fourPoster = gfx.image.new("images/environment/FourPoster")
        Lobby.decorSprites.storageBox = gfx.image.new("images/environment/StorageBox")
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
    -- Spread monsters across the lobby
    local spacing = 20
    local baseX = self.entryX + 30
    local x = baseX + ((index - 1) % 5) * spacing
    local y = self.y + FLOOR_HEIGHT - 20
    return x, y
end

function Lobby:draw()
    -- Draw clean lobby with simple lines
    -- Floor line at bottom
    gfx.drawLine(0, self.y + FLOOR_HEIGHT - 1, SCREEN_WIDTH, self.y + FLOOR_HEIGHT - 1)

    -- Draw lobby label
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
    gfx.drawText("LOBBY", 5, self.y + 5)
    gfx.setFont(gfx.getSystemFont())

    -- Draw front desk (filled rectangle with inverted text)
    gfx.fillRect(10, self.y + 25, 60, 25)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawText("DESK", 20, self.y + 32)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw capacity indicator next to desk
    local capacityText = self:getMonsterCount() .. "/" .. self.capacity
    gfx.drawText(capacityText, 75, self.y + 32)

    -- Draw elevator shaft area
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(ELEVATOR_X - 2, self.y, ELEVATOR_WIDTH + 4, FLOOR_HEIGHT)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(ELEVATOR_X - 2, self.y, ELEVATOR_WIDTH + 4, FLOOR_HEIGHT)

    -- Draw entry/exit door (on the right)
    gfx.drawRect(SCREEN_WIDTH - 50, self.y + 10, 40, 45)
    gfx.drawText("EXIT", SCREEN_WIDTH - 45, self.y + 28)
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
