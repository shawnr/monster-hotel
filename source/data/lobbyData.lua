-- Monster Hotel - Lobby Data Definitions
-- Lobby stats based on hotel level

LobbyData = {
    [1] = { patienceModifier = 1, capacity = 8, operationalCosts = 10 },
    [2] = { patienceModifier = 5, capacity = 10, operationalCosts = 20 },
    [3] = { patienceModifier = 8, capacity = 11, operationalCosts = 40 },
    [4] = { patienceModifier = 8, capacity = 12, operationalCosts = 50 },
    [5] = { patienceModifier = 8, capacity = 13, operationalCosts = 60 },
    [6] = { patienceModifier = 8, capacity = 14, operationalCosts = 80 },
    [7] = { patienceModifier = 9, capacity = 18, operationalCosts = 100 },
    [8] = { patienceModifier = 9, capacity = 20, operationalCosts = 120 },
    [9] = { patienceModifier = 9, capacity = 22, operationalCosts = 140 },
    [10] = { patienceModifier = 9, capacity = 25, operationalCosts = 160 },
    [11] = { patienceModifier = 9, capacity = 29, operationalCosts = 180 },
    [12] = { patienceModifier = 10, capacity = 35, operationalCosts = 200 },
    [13] = { patienceModifier = 10, capacity = 45, operationalCosts = 250 },
    [14] = { patienceModifier = 10, capacity = 50, operationalCosts = 300 },
    [15] = { patienceModifier = 11, capacity = 100, operationalCosts = 500 }
}

-- Get lobby data for a given hotel level
function LobbyData.getForLevel(hotelLevel)
    -- Cap at level 15 for direct lookup, beyond that use level 15 stats
    local level = math.min(hotelLevel, 15)
    return LobbyData[level]
end

-- Get capacity for a given hotel level
function LobbyData.getCapacity(hotelLevel)
    return LobbyData.getForLevel(hotelLevel).capacity
end

-- Get patience modifier for a given hotel level
function LobbyData.getPatienceModifier(hotelLevel)
    return LobbyData.getForLevel(hotelLevel).patienceModifier
end

-- Get operational costs for a given hotel level
function LobbyData.getOperationalCosts(hotelLevel)
    return LobbyData.getForLevel(hotelLevel).operationalCosts
end

return LobbyData
