-- Monster Hotel - Time System
-- Manages day/night cycle and game clock

TimeSystem = {}

function TimeSystem:init(isFirstDay)
    self.tickCount = 0
    -- Day 1 starts at noon for faster action, other days start at 5am
    if isFirstDay then
        self.gameHour = 12  -- Noon
    else
        self.gameHour = DAY_START_HOUR  -- 5am
    end
    self.dayEnded = false
    self.isPaused = false

    -- Callbacks
    self.onHourChange = nil
    self.onDayEnd = nil
end

function TimeSystem:reset()
    self.tickCount = 0
    self.gameHour = DAY_START_HOUR  -- Subsequent days start at 5am
    self.dayEnded = false
    self.isPaused = false
end

function TimeSystem:update()
    if self.isPaused or self.dayEnded then
        return
    end

    self.tickCount = self.tickCount + 1

    if self.tickCount >= TICKS_PER_HOUR then
        self.tickCount = 0
        self.gameHour = self.gameHour + 1

        -- Notify hour change
        if self.onHourChange then
            self.onHourChange(self:getHour())
        end

        -- Check for day end (2am = hour 26)
        if self.gameHour >= DAY_END_HOUR then
            self.dayEnded = true
            if self.onDayEnd then
                self.onDayEnd()
            end
        end
    end
end

function TimeSystem:getHour()
    -- Returns display hour (0-23)
    return self.gameHour % 24
end

function TimeSystem:getGameHour()
    -- Returns internal game hour (5-26)
    return self.gameHour
end

function TimeSystem:isMorning()
    -- Morning is 5am to noon (checkout time)
    return self.gameHour >= DAY_START_HOUR and self.gameHour < MORNING_END_HOUR
end

function TimeSystem:isAfternoon()
    -- Afternoon is noon to 9pm
    return self.gameHour >= MORNING_END_HOUR and self.gameHour < NIGHT_START_HOUR
end

function TimeSystem:isNight()
    -- Night is 9pm to 2am
    return self.gameHour >= NIGHT_START_HOUR or self.gameHour < DAY_START_HOUR
end

function TimeSystem:getSpawnModifier()
    -- Returns the spawn rate modifier based on time of day
    if self:isMorning() then
        return MORNING_SPAWN_RATE  -- 10% in morning
    elseif self:isNight() then
        return NIGHT_SPAWN_REDUCTION  -- 50% at night
    end
    return 1.0  -- Full rate in afternoon
end

function TimeSystem:getTimeOfDay()
    if self:isMorning() then
        return "morning"
    elseif self:isAfternoon() then
        return "afternoon"
    else
        return "night"
    end
end

function TimeSystem:getFormattedTime()
    return Utils.formatTime(self:getHour())
end

function TimeSystem:getDayProgress()
    -- Returns 0-1 progress through the day
    local hoursElapsed = self.gameHour - DAY_START_HOUR
    local totalHours = DAY_END_HOUR - DAY_START_HOUR
    return hoursElapsed / totalHours
end

function TimeSystem:pause()
    self.isPaused = true
end

function TimeSystem:resume()
    self.isPaused = false
end

function TimeSystem:skipToMorning()
    -- Skip to next morning by ending the current day
    -- Only allow if we're past morning (checkout period)
    if self.gameHour >= MORNING_END_HOUR and not self.dayEnded then
        -- Trigger day end, which will start next day at 5am
        self.dayEnded = true
        if self.onDayEnd then
            self.onDayEnd()
        end
        return true
    end
    return false
end

function TimeSystem:canSkipToMorning()
    -- Can only skip during afternoon/night when not already ended
    return self.gameHour >= MORNING_END_HOUR and not self.dayEnded
end

function TimeSystem:serialize()
    return {
        tickCount = self.tickCount,
        gameHour = self.gameHour,
        dayEnded = self.dayEnded
    }
end

function TimeSystem:deserialize(data)
    self.tickCount = data.tickCount or 0
    self.gameHour = data.gameHour or DAY_START_HOUR
    self.dayEnded = data.dayEnded or false
end

return TimeSystem
