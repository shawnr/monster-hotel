-- Monster Hotel - Elevator Data Definitions
-- Elevator tiers based on hotel level

ElevatorData = {
    {
        minLevel = 1,
        name = "Rickety Lift",
        capacity = 2,
        speed = 1,
        patienceModifier = 0
    },
    {
        minLevel = 3,
        name = "Basic Elevator",
        capacity = 6,
        speed = 1.2,
        patienceModifier = 2
    },
    {
        minLevel = 6,
        name = "Modern Elevator",
        capacity = 10,
        speed = 1.5,
        patienceModifier = 5
    },
    {
        minLevel = 9,
        name = "Express Elevator",
        capacity = 15,
        speed = 2,
        patienceModifier = 8
    },
    {
        minLevel = 12,
        name = "Luxury Elevator",
        capacity = 20,
        speed = 2.5,
        patienceModifier = 12
    },
    {
        minLevel = 15,
        name = "Haunted Express",
        capacity = 30,
        speed = 3,
        patienceModifier = 15
    }
}

-- Get elevator data for a given hotel level
function ElevatorData.getForLevel(hotelLevel)
    local bestMatch = ElevatorData[1]
    for _, elevator in ipairs(ElevatorData) do
        if elevator.minLevel <= hotelLevel then
            bestMatch = elevator
        else
            break
        end
    end
    return bestMatch
end

-- Get elevator name for a given hotel level
function ElevatorData.getNameForLevel(hotelLevel)
    return ElevatorData.getForLevel(hotelLevel).name
end

-- Check if elevator would upgrade at this level
function ElevatorData.wouldUpgrade(fromLevel, toLevel)
    local oldData = ElevatorData.getForLevel(fromLevel)
    local newData = ElevatorData.getForLevel(toLevel)
    return oldData.name ~= newData.name
end

return ElevatorData
