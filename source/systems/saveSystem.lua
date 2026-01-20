-- Monster Hotel - Save System
-- Handles game save/load using Playdate datastore

SaveSystem = {}

-- Helper to get formatted timestamp using Playdate API
local function getTimestamp()
    local time = playdate.getTime()
    return string.format("%04d-%02d-%02d %02d:%02d",
        time.year, time.month, time.day, time.hour, time.minute)
end

-- Save game data to a slot
function SaveSystem:save(slot, hotel, timeData)
    local saveData = {
        version = 1,
        hotel = hotel:serialize(),
        time = timeData,
        savedAt = getTimestamp()
    }

    local filename = "save" .. slot
    local success = playdate.datastore.write(saveData, filename)

    if success then
        print("Game saved to slot " .. slot)
    else
        print("Failed to save game to slot " .. slot)
    end

    return success
end

-- Load game data from a slot
function SaveSystem:load(slot)
    local filename = "save" .. slot
    local saveData = playdate.datastore.read(filename)

    if saveData then
        print("Game loaded from slot " .. slot)
    end

    return saveData
end

-- Delete a save slot
function SaveSystem:delete(slot)
    local filename = "save" .. slot
    playdate.datastore.delete(filename)
    print("Deleted save slot " .. slot)
end

-- Check if a save slot exists
function SaveSystem:exists(slot)
    local filename = "save" .. slot
    local data = playdate.datastore.read(filename)
    return data ~= nil
end

-- Get save info without loading full data
function SaveSystem:getSaveInfo(slot)
    local saveData = self:load(slot)
    if not saveData then
        return nil
    end

    return {
        exists = true,
        savedAt = saveData.savedAt or "Unknown",
        day = saveData.hotel and saveData.hotel.dayCount or 1,
        money = saveData.hotel and saveData.hotel.money or 0,
        level = saveData.hotel and saveData.hotel.level or 1,
        version = saveData.version or 0
    }
end

-- Get all save slot info
function SaveSystem:getAllSaveInfo()
    local slots = {}
    for i = 1, 3 do
        slots[i] = self:getSaveInfo(i) or { exists = false }
    end
    return slots
end

-- Save unlockables (persistent across all games)
function SaveSystem:saveUnlockables(unlockedIds, stats)
    local unlockData = {
        version = 1,
        unlockedIds = unlockedIds,
        lifetimeStats = stats,
        savedAt = getTimestamp()
    }

    playdate.datastore.write(unlockData, "unlockables")
end

-- Load unlockables
function SaveSystem:loadUnlockables()
    return playdate.datastore.read("unlockables")
end

-- Save lifetime stats (persistent)
function SaveSystem:saveLifetimeStats(stats)
    local data = self:loadUnlockables() or { unlockedIds = {} }
    data.lifetimeStats = stats
    data.savedAt = getTimestamp()
    playdate.datastore.write(data, "unlockables")
end

-- Load lifetime stats
function SaveSystem:loadLifetimeStats()
    local data = self:loadUnlockables()
    if data and data.lifetimeStats then
        return data.lifetimeStats
    end
    return {
        gamesStarted = 0,
        lifetimeGuestsServed = 0,
        maxLevel = 1,
        maxMoney = 0,
        totalDays = 0
    }
end

return SaveSystem
