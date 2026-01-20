-- Monster Hotel - Room Data Definitions

RoomData = {
    -- Guest room types
    SINGLE = {
        type = ROOM_TYPE.SINGLE,
        category = ROOM_CATEGORY.GUEST,
        capacity = 1,
        baseCost = 100,
        -- Patience modifier is CurrentHotelLevel (set dynamically)
        getPatienceModifier = function(hotelLevel)
            return hotelLevel
        end,
        getCost = function()
            return 100
        end
    },
    DOUBLE = {
        type = ROOM_TYPE.DOUBLE,
        category = ROOM_CATEGORY.GUEST,
        capacity = 2,
        baseCost = 200,
        -- Patience modifier is 2 * CurrentHotelLevel
        getPatienceModifier = function(hotelLevel)
            return 2 * hotelLevel
        end,
        getCost = function()
            return 200
        end
    },
    SUITE = {
        type = ROOM_TYPE.SUITE,
        category = ROOM_CATEGORY.GUEST,
        capacity = 4,
        baseCost = 500,
        -- Patience modifier is 4 * CurrentHotelLevel
        getPatienceModifier = function(hotelLevel)
            return 4 * hotelLevel
        end,
        getCost = function()
            return 500
        end
    },

    -- Service types (take up entire floor)
    CAFE = {
        type = ROOM_TYPE.CAFE,
        category = ROOM_CATEGORY.SERVICE,
        capacity = 20,
        baseCost = 100,
        getPatienceModifier = function(hotelLevel)
            return hotelLevel
        end,
        getCost = function()
            return 100
        end
    },
    CONFERENCE = {
        type = ROOM_TYPE.CONFERENCE,
        category = ROOM_CATEGORY.SERVICE,
        capacity = 40,
        baseCost = 200,
        getPatienceModifier = function(hotelLevel)
            return 2 * hotelLevel
        end,
        getCost = function()
            return 200
        end
    },
    BALLROOM = {
        type = ROOM_TYPE.BALLROOM,
        category = ROOM_CATEGORY.SERVICE,
        capacity = 100,
        baseCost = 500,
        getPatienceModifier = function(hotelLevel)
            return 4 * hotelLevel
        end,
        getCost = function()
            return 500
        end
    }
}

-- Get room data by type
function RoomData.getByType(roomType)
    return RoomData[roomType]
end

-- Check if room type is a service
function RoomData.isService(roomType)
    local data = RoomData[roomType]
    return data and data.category == ROOM_CATEGORY.SERVICE
end

-- Get guest room types
function RoomData.getGuestTypes()
    return { ROOM_TYPE.SINGLE, ROOM_TYPE.DOUBLE, ROOM_TYPE.SUITE }
end

-- Get service types
function RoomData.getServiceTypes()
    return { ROOM_TYPE.CAFE, ROOM_TYPE.CONFERENCE, ROOM_TYPE.BALLROOM }
end

return RoomData
