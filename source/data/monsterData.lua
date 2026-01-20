-- Monster Hotel - Monster Data Definitions

MonsterData = {
    {
        id = "ghoul",
        name = "Ghoul",
        description = "A fiend from beyond time and space.",
        icon = "Boss",
        spriteTable = "images/sprites/Boss",  -- Image table path
        frameWidth = 28,
        frameHeight = 36,
        speed = 2,
        basePatience = 200,
        baseDamage = 10,
        minHotelLevel = 1
    },
    {
        id = "eyeball",
        name = "Giant Eyeball",
        description = "The terrifying guardian of the dungeon.",
        icon = "EyeGuy",
        spriteTable = "images/sprites/EyeGuy",
        frameWidth = 24,
        frameHeight = 40,
        speed = 1,
        basePatience = 400,
        baseDamage = 20,
        minHotelLevel = 1
    },
    {
        id = "creeper",
        name = "Creeper",
        description = "An unpredictable and frantic baddie.",
        icon = "Glitcher",
        spriteTable = "images/sprites/Glitcher",
        frameWidth = 28,
        frameHeight = 40,
        speed = 3,
        basePatience = 200,
        baseDamage = 30,
        minHotelLevel = 5
    },
    {
        id = "zombie",
        name = "Zombie",
        description = "Undead and proud of it.",
        icon = "Zombie",
        spriteTable = "images/sprites/Zombie",
        frameWidth = 28,
        frameHeight = 30,
        speed = 1,
        basePatience = 500,
        baseDamage = 10,
        minHotelLevel = 10
    },
    {
        id = "alien",
        name = "Undercover Alien",
        description = "Alien spy still wearing a human disguise.",
        icon = "Player",
        spriteTable = "images/sprites/Player",
        frameWidth = 28,
        frameHeight = 40,
        speed = 2,
        basePatience = 500,
        baseDamage = 50,
        minHotelLevel = 15
    }
}

-- Get monsters available at a given hotel level
function MonsterData.getAvailableMonsters(hotelLevel)
    local available = {}
    for _, monster in ipairs(MonsterData) do
        if monster.minHotelLevel <= hotelLevel then
            table.insert(available, monster)
        end
    end
    return available
end

-- Get a random monster for the given hotel level
function MonsterData.getRandomMonster(hotelLevel)
    local available = MonsterData.getAvailableMonsters(hotelLevel)
    if #available == 0 then return nil end
    return available[math.random(#available)]
end

-- Get monster data by ID
function MonsterData.getById(id)
    for _, monster in ipairs(MonsterData) do
        if monster.id == id then
            return monster
        end
    end
    return nil
end

return MonsterData
