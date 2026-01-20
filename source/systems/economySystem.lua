-- Monster Hotel - Economy System
-- Handles money, costs, and earnings

import "data/unlockableData"

EconomySystem = {}

function EconomySystem:init(hotel, unlockSystem)
    self.hotel = hotel
    self.unlockSystem = unlockSystem

    -- Day tracking
    self.dayEarnings = 0
    self.dayExpenses = 0
    self.dayDamage = 0
    self.dayGuestsServed = 0
    self.dayRages = 0
    self.startingFloorCount = #hotel.floors

    -- Callbacks
    self.onMoneyChanged = nil
    self.onDamage = nil
end

function EconomySystem:reset()
    self.dayEarnings = 0
    self.dayExpenses = 0
    self.dayDamage = 0
    self.dayGuestsServed = 0
    self.dayRages = 0
    self.startingFloorCount = #self.hotel.floors
end

function EconomySystem:startNewDay()
    self:reset()
end

function EconomySystem:endDay()
    -- Apply operating costs
    local operatingCost = self.hotel:calculateDailyOperatingCost()
    self:applyExpense(operatingCost, "Operating costs")
end

function EconomySystem:processCheckout(monster)
    if not monster or not monster.assignedRoom then
        return 0
    end

    -- Get room cost
    local roomCost = monster.assignedRoom:getCost()

    -- Add unlockable cost bonus
    local costBonus = 0
    if self.unlockSystem then
        costBonus = self.unlockSystem:getTotalCostBonus()
    end

    local totalEarnings = roomCost + costBonus

    -- Add to hotel money
    self.hotel:addMoney(totalEarnings)
    self.dayEarnings = self.dayEarnings + totalEarnings

    -- Update stats
    self.hotel.guestsServed = self.hotel.guestsServed + 1
    self.dayGuestsServed = self.dayGuestsServed + 1

    -- Notify
    if self.onMoneyChanged then
        self.onMoneyChanged(totalEarnings, "Checkout: " .. monster.name)
    end

    return totalEarnings
end

function EconomySystem:processDamage(monster)
    if not monster then return 0 end

    -- Calculate damage cost
    local damageCost = monster:getDamageCost(self.hotel.level)
    damageCost = math.floor(damageCost)

    -- Subtract from hotel money
    self.hotel:subtractMoney(damageCost)
    self.dayDamage = self.dayDamage + damageCost

    -- Update stats
    self.hotel.totalRages = self.hotel.totalRages + 1
    self.dayRages = self.dayRages + 1

    -- Notify
    if self.onDamage then
        self.onDamage(damageCost, monster)
    end
    if self.onMoneyChanged then
        self.onMoneyChanged(-damageCost, "Damage: " .. monster.name .. " raged!")
    end

    return damageCost
end

function EconomySystem:applyExpense(amount, reason)
    self.hotel:subtractMoney(amount)
    self.dayExpenses = self.dayExpenses + amount

    if self.onMoneyChanged then
        self.onMoneyChanged(-amount, reason or "Expense")
    end
end

function EconomySystem:getDaySummary()
    local newFloors = #self.hotel.floors - self.startingFloorCount
    return {
        earnings = self.dayEarnings,
        expenses = self.dayExpenses,
        damage = self.dayDamage,
        net = self.dayEarnings - self.dayExpenses - self.dayDamage,
        operatingCost = self.hotel:calculateDailyOperatingCost(),
        guestsServed = self.dayGuestsServed,
        rages = self.dayRages,
        newFloors = newFloors
    }
end

function EconomySystem:getProjectedOperatingCost()
    return self.hotel:calculateDailyOperatingCost()
end

return EconomySystem
