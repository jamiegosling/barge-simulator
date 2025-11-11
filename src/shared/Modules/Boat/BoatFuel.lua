-- BoatFuel.lua
-- Handles fuel consumption, distance tracking, and fuel updates

local BoatFuel = {}

-- ==================== MODULE STATE ==================== --
local currentFuel = 100
local maxFuel = 200
local baseMaxFuel = 200
local lastPosition = nil
local totalDistanceTraveled = 0
local outOfFuel = false

local FUEL_CONSUMPTION_RATE = 0.025  -- Fuel consumed per stud traveled
local MIN_STEER_SPEED = 1

-- ==================== PUBLIC FUNCTIONS ==================== --

function BoatFuel.Initialize(config)
	-- Config contains: boat, script, baseMaxFuel, initialFuel
	BoatFuel.boat = config.boat
	BoatFuel.script = config.script
	
	baseMaxFuel = config.baseMaxFuel or 200
	maxFuel = baseMaxFuel
	
	-- Set fuel consumption rate
	local FuelConsumptionRate = config.script:FindFirstChild("FuelConsumptionRate")
	if FuelConsumptionRate then
		FUEL_CONSUMPTION_RATE = FuelConsumptionRate.Value
	end
	
	-- Set initial fuel values
	local OriginalFuelCapacity = config.script:FindFirstChild("OriginalFuelCapacity")
	if OriginalFuelCapacity then
		baseMaxFuel = OriginalFuelCapacity.Value
	end
	
	local FuelMultiplier = config.script:FindFirstChild("FuelMultiplier")
	if FuelMultiplier then
		maxFuel = baseMaxFuel * FuelMultiplier.Value
	else
		maxFuel = baseMaxFuel
	end
	
	local InitialFuel = config.script:FindFirstChild("InitialFuel")
	if InitialFuel then
		currentFuel = InitialFuel.Value
		print("⛽ Initial fuel set from InitialFuel:", currentFuel)
	else
		currentFuel = config.baseCurrentFuel or 100
		print("⛽ Initial fuel set to default:", currentFuel)
	end
	
	-- Listen for FuelAmount changes on the boat
	local fuelAmount = config.boat:FindFirstChild("FuelAmount")
	if fuelAmount then
		fuelAmount.Changed:Connect(function(newValue)
			currentFuel = newValue
		end)
	end
	
	outOfFuel = (currentFuel <= 0)
end

function BoatFuel.Update()
	-- Skip updating if fuel purchase is in progress
	if BoatFuel.IsFuelPurchaseInProgress() then
		return
	end
	
	local currentMultiplier = BoatFuel.script:FindFirstChild("FuelMultiplier")
	if currentMultiplier then
		maxFuel = baseMaxFuel * currentMultiplier.Value
	else
		maxFuel = baseMaxFuel
	end
	
	-- Update current fuel - prioritize FuelAmount from boat
	local fuelAmount = BoatFuel.boat:FindFirstChild("FuelAmount")
	if fuelAmount then
		currentFuel = fuelAmount.Value
	else
		-- Fallback to InitialFuel if FuelAmount doesn't exist
		local initialFuelValue = BoatFuel.script:FindFirstChild("InitialFuel")
		if initialFuelValue then
			currentFuel = initialFuelValue.Value
			-- Create FuelAmount on boat if it doesn't exist
			if not BoatFuel.boat:FindFirstChild("FuelAmount") then
				local newFuelAmount = Instance.new("NumberValue")
				newFuelAmount.Name = "FuelAmount"
				newFuelAmount.Value = currentFuel
				newFuelAmount.Parent = BoatFuel.boat
			end
		end
	end
end

function BoatFuel.ConsumeFuel(currentPosition, isOccupied, forwardSpeed)
	-- Fuel consumption based on distance traveled
	if lastPosition and isOccupied and math.abs(forwardSpeed) > MIN_STEER_SPEED then
		local distance = (currentPosition - lastPosition).Magnitude
		totalDistanceTraveled = totalDistanceTraveled + distance
		
		-- Consume fuel
		local fuelToConsume = distance * FUEL_CONSUMPTION_RATE
		local previousFuel = currentFuel
		currentFuel = math.max(0, currentFuel - fuelToConsume)
		
		-- Update fuel amount on boat if it exists
		local fuelAmount = BoatFuel.boat:FindFirstChild("FuelAmount")
		if fuelAmount then
			fuelAmount.Value = currentFuel
		end
		
		-- Also update InitialFuel to keep DataStore in sync
		local initialFuelValue = BoatFuel.script:FindFirstChild("InitialFuel")
		if initialFuelValue then
			initialFuelValue.Value = currentFuel
		end
		
		-- Check if fuel-empty state changed
		local nowOutOfFuel = (currentFuel <= 0)
		if nowOutOfFuel ~= outOfFuel then
			outOfFuel = nowOutOfFuel
			return true  -- Signal that fuel state changed
		end
	end
	lastPosition = currentPosition
	return false
end

function BoatFuel.GetCurrentFuel()
	return currentFuel
end

function BoatFuel.GetMaxFuel()
	return maxFuel
end

function BoatFuel.GetTotalDistance()
	return totalDistanceTraveled
end

function BoatFuel.IsOutOfFuel()
	return outOfFuel
end

function BoatFuel.IsFuelPurchaseInProgress()
	local purchaseFlag = BoatFuel.script:FindFirstChild("FuelPurchaseInProgress")
	return purchaseFlag and purchaseFlag.Value == true
end

function BoatFuel.GetValues()
	local fuelAmount = BoatFuel.boat:FindFirstChild("FuelAmount")
	local maxFuelValue = BoatFuel.boat:FindFirstChild("MaxFuel")
	local originalFuel = BoatFuel.boat:FindFirstChild("OriginalFuelCapacity")
	local fuelMultiplier = BoatFuel.script:FindFirstChild("FuelMultiplier")

	local values = {}
	
	if fuelAmount then
		values.currentFuel = fuelAmount.Value
	else
		values.currentFuel = currentFuel
	end

	if maxFuelValue then
		values.maxFuel = maxFuelValue.Value
	elseif originalFuel and fuelMultiplier then
		values.maxFuel = originalFuel.Value * fuelMultiplier.Value
	else
		values.maxFuel = maxFuel
	end
	
	return values
end

return BoatFuel
