-- Monster Hotel - Service Floor Data
-- Unique names for service floors (cafes, conference rooms, ballrooms)

ServiceFloorData = {
    [FLOOR_TYPE.CAFE] = {
        names = {
            "The Cryptid Cafe",
            "McGorely's Grind",
            "Phantom Brews",
            "Romero's",
            "The Blood Bank Cafe",
            "LoveCRAFT Beer and Cocktail Bar",
            "The BOOstro",
            "The Cobweb Cafe",
            "Moonlight Munchies",
            "The Overlook",
        }
    },
    [FLOOR_TYPE.CONFERENCE] = {
        names = {
            "The Furry Monsters of the World Annual Conference",
            "MonsterCon",
            "Cryptid Research Conference",
            "Covens of Cincinnati Gathering",
            "Ghost Hunters Annual Meeting",
            "Invertebrate Monsters Summit",
            "Spiritual Monsters Conference",
            "The Annual Meeting of the Monsters of the Sea",
            "Gathering of the Gargoyles",
            "The Mary Shelley Synthetic Monsters Conference",
            "The Texas Chainsaw Manufacturing Conference",
        }
    },
    [FLOOR_TYPE.BALLROOM] = {
        names = {
            "The Dr. Frankenstein Memorial Ballroom",
            "All Hail Cthulu",
            "George A. Romero Event Space",
            "The Sam Raimi Slaughter Hall",
            "The H.P. Lovecraft Memorial Aquarium",
            "The Stephen King Festival Hall",
            "The Stephen Graham Jones Rockin' Metal Concert Hall",
            "The Dracula Room",
            "The Creature from the Black Lagoon Room",
            "The Honorary Invisible Man Hideout",
        }
    }
}

-- Get a random name for a service floor type
function ServiceFloorData.getRandomName(floorType)
    local data = ServiceFloorData[floorType]
    if data and data.names then
        return data.names[math.random(#data.names)]
    end
    return nil
end

-- Get display label for floor type (short version for label box)
function ServiceFloorData.getTypeLabel(floorType)
    if floorType == FLOOR_TYPE.CAFE then
        return "Cafe"
    elseif floorType == FLOOR_TYPE.CONFERENCE then
        return "Conference"
    elseif floorType == FLOOR_TYPE.BALLROOM then
        return "Ballroom"
    end
    return nil
end

return ServiceFloorData
