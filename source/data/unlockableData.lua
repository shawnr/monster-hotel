-- Monster Hotel - Unlockable Data Definitions

UnlockableData = {
    {
        id = "paintings",
        name = "Paintings in Lobby",
        challenge = "Earn at least $1000 in one game",
        type = UNLOCKABLE_TYPE.PATIENCE,
        effect = 10,
        checkUnlock = function(gameStats)
            return gameStats.maxMoney >= 1000
        end
    },
    {
        id = "fountain",
        name = "Fountain",
        challenge = "Earn at least $2000 in one game",
        type = UNLOCKABLE_TYPE.COST,
        effect = 40,
        checkUnlock = function(gameStats)
            return gameStats.maxMoney >= 2000
        end
    },
    {
        id = "showers",
        name = "Nicer Showers",
        challenge = "Earn at least $3000 in one game",
        type = UNLOCKABLE_TYPE.COST,
        effect = 50,
        checkUnlock = function(gameStats)
            return gameStats.maxMoney >= 3000
        end
    },
    {
        id = "muzak",
        name = "Elevator Muzak",
        challenge = "Serve at least 30 guests in one game",
        type = UNLOCKABLE_TYPE.PATIENCE,
        effect = 20,
        checkUnlock = function(gameStats)
            return gameStats.guestsServed >= 30
        end
    },
    {
        id = "bellhop",
        name = "Bellhop Bot",
        challenge = "Reach Hotel Level 5",
        type = UNLOCKABLE_TYPE.PATIENCE,
        effect = 15,
        checkUnlock = function(gameStats)
            return gameStats.maxLevel >= 5
        end
    },
    {
        id = "mints",
        name = "Complimentary Mints",
        challenge = "Survive 10 days",
        type = UNLOCKABLE_TYPE.COST,
        effect = 25,
        checkUnlock = function(gameStats)
            return gameStats.daysCompleted >= 10
        end
    },
    {
        id = "chandelier",
        name = "Haunted Chandelier",
        challenge = "Have 5 monsters rage out in one game",
        type = UNLOCKABLE_TYPE.PATIENCE,
        effect = 30,
        checkUnlock = function(gameStats)
            return gameStats.totalRages >= 5
        end
    },
    {
        id = "loyalty",
        name = "Monster Loyalty Card",
        challenge = "Serve 100 total guests (lifetime)",
        type = UNLOCKABLE_TYPE.COST,
        effect = 100,
        checkUnlock = function(gameStats)
            return gameStats.lifetimeGuestsServed >= 100
        end
    },
    {
        id = "mat",
        name = "Spooky Welcome Mat",
        challenge = "Start a new game 3 times",
        type = UNLOCKABLE_TYPE.PATIENCE,
        effect = 5,
        checkUnlock = function(gameStats)
            return gameStats.gamesStarted >= 3
        end
    },
    {
        id = "coffin",
        name = "Coffin Beds",
        challenge = "Reach Hotel Level 10",
        type = UNLOCKABLE_TYPE.COST,
        effect = 75,
        checkUnlock = function(gameStats)
            return gameStats.maxLevel >= 10
        end
    }
}

-- Get all unlockables
function UnlockableData.getAll()
    return UnlockableData
end

-- Get unlockable by ID
function UnlockableData.getById(id)
    for _, unlockable in ipairs(UnlockableData) do
        if unlockable.id == id then
            return unlockable
        end
    end
    return nil
end

-- Calculate total patience bonus from unlocked items
function UnlockableData.getTotalPatienceBonus(unlockedIds)
    local total = 0
    for _, id in ipairs(unlockedIds) do
        local unlockable = UnlockableData.getById(id)
        if unlockable and unlockable.type == UNLOCKABLE_TYPE.PATIENCE then
            total = total + unlockable.effect
        end
    end
    return total
end

-- Calculate total cost bonus from unlocked items
function UnlockableData.getTotalCostBonus(unlockedIds)
    local total = 0
    for _, id in ipairs(unlockedIds) do
        local unlockable = UnlockableData.getById(id)
        if unlockable and unlockable.type == UNLOCKABLE_TYPE.COST then
            total = total + unlockable.effect
        end
    end
    return total
end

return UnlockableData
