-- Monster Hotel - Monster Data Definitions

MonsterData = {
    {
        id = "robot",
        name = "Evil Robot",
        description = "A malicious android.",
        icon = "images/sprites/evil_robot-icon",
        spriteTable = "images/sprites/evil_robot",
        frameWidth = 32,
        frameHeight = 32,
        speed = 2,
        basePatience = 200,
        baseDamage = 10,
        minHotelLevel = 1
    },
    {
        id = "flesheating-plant",
        name = "Flesheating Plant",
        description = "A carnivorous vegetable.",
        icon = "images/sprites/flesheating-plant-icon",
        spriteTable = "images/sprites/flesheating-plant",
        frameWidth = 32,
        frameHeight = 32,
        speed = 1,
        basePatience = 200,
        baseDamage = 20,
        minHotelLevel = 1
    },
    {
        id = "spider",
        name = "Spider",
        description = "An arachnid of concern.",
        icon = "images/sprites/spider-icon",
        spriteTable = "images/sprites/spider",
        frameWidth = 32,
        frameHeight = 32,
        speed = 3,
        basePatience = 150,
        baseDamage = 30,
        minHotelLevel = 5
    },
    {
        id = "slug",
        name = "Giant Slug",
        description = "Slow but deadly.",
        icon = "images/sprites/giant_slug-icon",
        spriteTable = "images/sprites/giant_slug",
        frameWidth = 32,
        frameHeight = 32,
        speed = 1,
        basePatience = 200,
        baseDamage = 40,
        minHotelLevel = 10
    },
    {
        id = "alien",
        name = "Undercover Alien",
        description = "Alien spy still wearing a human disguise.",
        icon = "images/sprites/alien-icon",
        spriteTable = "images/sprites/alien",
        frameWidth = 32,
        frameHeight = 32,
        speed = 3,
        basePatience = 200,
        baseDamage = 60,
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
