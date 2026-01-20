-- Monster Hotel - Unlock System
-- Tracks and manages unlockable items

import "data/unlockableData"
import "systems/saveSystem"

UnlockSystem = {}

function UnlockSystem:init()
    self.unlockedIds = {}
    self.lifetimeStats = {
        gamesStarted = 0,
        lifetimeGuestsServed = 0,
        maxLevel = 1,
        maxMoney = 0,
        totalDays = 0
    }

    -- Callbacks
    self.onUnlock = nil
end

function UnlockSystem:loadUnlockables()
    -- Ensure defaults are set first
    self.unlockedIds = self.unlockedIds or {}
    self.lifetimeStats = self.lifetimeStats or {
        gamesStarted = 0,
        lifetimeGuestsServed = 0,
        maxLevel = 1,
        maxMoney = 0,
        totalDays = 0
    }

    local data = SaveSystem:loadUnlockables()
    if data then
        self.unlockedIds = data.unlockedIds or {}
        if data.lifetimeStats then
            -- Merge with defaults
            for k, v in pairs(data.lifetimeStats) do
                self.lifetimeStats[k] = v
            end
        end
    end
end

function UnlockSystem:saveUnlockables()
    SaveSystem:saveUnlockables(self.unlockedIds, self.lifetimeStats)
end

function UnlockSystem:isUnlocked(id)
    for _, unlockedId in ipairs(self.unlockedIds) do
        if unlockedId == id then
            return true
        end
    end
    return false
end

function UnlockSystem:unlock(id)
    if not self:isUnlocked(id) then
        table.insert(self.unlockedIds, id)
        self:saveUnlockables()

        if self.onUnlock then
            local unlockable = UnlockableData.getById(id)
            self.onUnlock(unlockable)
        end

        return true
    end
    return false
end

function UnlockSystem:checkForUnlocks(gameStats)
    local newUnlocks = {}

    -- Merge game stats with lifetime stats
    local combinedStats = {
        maxMoney = math.max(gameStats.maxMoney or 0, self.lifetimeStats.maxMoney),
        guestsServed = gameStats.guestsServed or 0,
        maxLevel = math.max(gameStats.maxLevel or 1, self.lifetimeStats.maxLevel),
        daysCompleted = gameStats.daysCompleted or 0,
        totalRages = gameStats.totalRages or 0,
        lifetimeGuestsServed = self.lifetimeStats.lifetimeGuestsServed + (gameStats.guestsServed or 0),
        gamesStarted = self.lifetimeStats.gamesStarted
    }

    -- Check each unlockable
    for _, unlockable in ipairs(UnlockableData.getAll()) do
        if not self:isUnlocked(unlockable.id) then
            if unlockable.checkUnlock(combinedStats) then
                self:unlock(unlockable.id)
                table.insert(newUnlocks, unlockable)
            end
        end
    end

    return newUnlocks
end

function UnlockSystem:updateLifetimeStats(gameStats)
    self.lifetimeStats.gamesStarted = self.lifetimeStats.gamesStarted + 1
    self.lifetimeStats.lifetimeGuestsServed = self.lifetimeStats.lifetimeGuestsServed + (gameStats.guestsServed or 0)
    self.lifetimeStats.maxLevel = math.max(self.lifetimeStats.maxLevel, gameStats.maxLevel or 1)
    self.lifetimeStats.maxMoney = math.max(self.lifetimeStats.maxMoney, gameStats.maxMoney or 0)
    self.lifetimeStats.totalDays = self.lifetimeStats.totalDays + (gameStats.daysCompleted or 0)

    self:saveUnlockables()
end

function UnlockSystem:onNewGameStarted()
    self.lifetimeStats.gamesStarted = self.lifetimeStats.gamesStarted + 1
    self:saveUnlockables()

    -- Check for spooky welcome mat unlock (3 games started)
    self:checkForUnlocks({ gamesStarted = self.lifetimeStats.gamesStarted })
end

function UnlockSystem:getTotalPatienceBonus()
    return UnlockableData.getTotalPatienceBonus(self.unlockedIds)
end

function UnlockSystem:getTotalCostBonus()
    return UnlockableData.getTotalCostBonus(self.unlockedIds)
end

function UnlockSystem:getUnlockedCount()
    return #self.unlockedIds
end

function UnlockSystem:getTotalCount()
    return #UnlockableData.getAll()
end

function UnlockSystem:getAllUnlockables()
    local all = {}
    for _, unlockable in ipairs(UnlockableData.getAll()) do
        table.insert(all, {
            data = unlockable,
            unlocked = self:isUnlocked(unlockable.id)
        })
    end
    return all
end

return UnlockSystem
