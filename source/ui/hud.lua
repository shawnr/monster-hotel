-- Monster Hotel - HUD (Heads Up Display)
-- Shows money, time, day counter, and elevator info

local gfx <const> = playdate.graphics

HUD = {}

function HUD:init(hotel, timeSystem)
    self.hotel = hotel
    self.timeSystem = timeSystem

    -- Animation for money changes
    self.moneyChangeAmount = 0
    self.moneyChangeTimer = 0
    self.moneyChangeIsPositive = true
end

function HUD:showMoneyChange(amount)
    self.moneyChangeAmount = amount
    self.moneyChangeTimer = 60  -- Show for 2 seconds at 30fps
    self.moneyChangeIsPositive = amount > 0
end

function HUD:update()
    -- Update money change animation
    if self.moneyChangeTimer > 0 then
        self.moneyChangeTimer = self.moneyChangeTimer - 1
    end
end

function HUD:draw()
    -- Draw HUD background bar at top
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_WIDTH, 20)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, 20, SCREEN_WIDTH, 20)

    -- Draw money (left side)
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
    local moneyText = Utils.formatMoney(self.hotel.money)
    gfx.drawText(moneyText, 5, 3)

    -- Draw money change indicator
    if self.moneyChangeTimer > 0 then
        local changeText
        if self.moneyChangeIsPositive then
            changeText = "+" .. Utils.formatMoney(self.moneyChangeAmount)
        else
            changeText = "-" .. Utils.formatMoney(math.abs(self.moneyChangeAmount))
        end

        -- Fade out effect
        local alpha = self.moneyChangeTimer / 60
        local xOffset = (60 - self.moneyChangeTimer) * 0.5

        gfx.setFont(gfx.getSystemFont(gfx.font.kVariantItalic))
        local moneyWidth = gfx.getTextSize(moneyText)
        gfx.drawText(changeText, 10 + moneyWidth, 3 - xOffset)
    end

    -- Draw time (center)
    gfx.setFont(gfx.getSystemFont())
    local timeText = self.timeSystem:getFormattedTime()
    gfx.drawTextAligned(timeText, SCREEN_WIDTH / 2, 3, kTextAlignment.center)

    -- Draw day counter (right side)
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
    local dayText = "Day " .. self.hotel.dayCount
    gfx.drawTextAligned(dayText, SCREEN_WIDTH - 5, 3, kTextAlignment.right)

    -- Draw level indicator (below day)
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantItalic))
    local levelText = "Lvl " .. self.hotel.level
    gfx.drawTextAligned(levelText, SCREEN_WIDTH - 50, 3, kTextAlignment.right)

    gfx.setFont(gfx.getSystemFont())
end

function HUD:drawElevatorInfo(elevator)
    -- Draw elevator status at bottom of screen
    local y = SCREEN_HEIGHT - 18

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, y - 2, SCREEN_WIDTH, 20)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, y - 2, SCREEN_WIDTH, y - 2)

    -- Elevator name and capacity
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantItalic))
    local elevatorText = elevator.name .. " [" .. elevator:getPassengerCount() .. "/" .. elevator.capacity .. "]"
    gfx.drawText(elevatorText, 5, y)

    -- Door status
    local doorStatus = elevator.doorsOpen and "OPEN" or "CLOSED"
    gfx.drawTextAligned(doorStatus, SCREEN_WIDTH - 5, y, kTextAlignment.right)

    -- Floor indicator
    local floorText = "Floor " .. elevator.currentFloor
    gfx.drawTextAligned(floorText, SCREEN_WIDTH / 2, y, kTextAlignment.center)

    gfx.setFont(gfx.getSystemFont())
end

return HUD
