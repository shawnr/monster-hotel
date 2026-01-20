-- Monster Hotel - Utility Functions

Utils = {}

-- Deep copy a table
function Utils.deepCopy(orig)
    local origType = type(orig)
    local copy
    if origType == 'table' then
        copy = {}
        for origKey, origValue in next, orig, nil do
            copy[Utils.deepCopy(origKey)] = Utils.deepCopy(origValue)
        end
        setmetatable(copy, Utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Clamp a value between min and max
function Utils.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Linear interpolation
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Check if a point is within a rectangle
function Utils.pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

-- Check if two rectangles overlap
function Utils.rectsOverlap(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

-- Get random element from a table
function Utils.randomChoice(tbl)
    if #tbl == 0 then return nil end
    return tbl[math.random(#tbl)]
end

-- Shuffle a table in place
function Utils.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- Format time as HH:MM
function Utils.formatTime(hour)
    local displayHour = hour % 24
    local ampm = displayHour >= 12 and "PM" or "AM"
    if displayHour == 0 then displayHour = 12
    elseif displayHour > 12 then displayHour = displayHour - 12
    end
    return string.format("%d:00 %s", displayHour, ampm)
end

-- Format money with $ and commas
function Utils.formatMoney(amount)
    local formatted = tostring(math.floor(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return "$" .. formatted
end

-- Get the sign of a number (-1, 0, or 1)
function Utils.sign(x)
    if x > 0 then return 1
    elseif x < 0 then return -1
    else return 0
    end
end

-- Calculate distance between two points
function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Round to nearest integer
function Utils.round(x)
    return math.floor(x + 0.5)
end

-- Create a simple timer that calls a function after delay
function Utils.after(delay, callback)
    local timer = playdate.timer.new(delay, callback)
    timer.repeats = false
    return timer
end

-- Create a repeating timer
function Utils.every(interval, callback)
    local timer = playdate.timer.new(interval, callback)
    timer.repeats = true
    return timer
end

return Utils
