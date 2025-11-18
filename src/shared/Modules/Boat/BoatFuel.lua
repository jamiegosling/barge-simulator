-- BoatFuel.lua
-- Handles fuel consumption, distance tracking, and fuel updates

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoatFuel = {}

-- Detect if running on server or client
local isServer = RunService:IsServer()

-- ==================== MODULE STATE ==================== --
local currentFuel = 100
local maxFuel = 200
local baseMaxFuel = 200
local lastPosition = nil
local totalDistanceTraveled = 0
local outOfFuel = false

local FUEL_CONSUMPTION_RATE = 0.025  -- Fuel consumed per stud traveled
local MIN_STEER_SPEED = 1

-- Distance tracking for achievements
local distanceAccumulator = 0
local DISTANCE_REPORT_THRESHOLD = 100  -- Report to server every 100 studs

-- Server-side: Get AchievementManager reference
local AchievementManager
if isServer then
	local ServerScriptService = game:GetService("ServerScriptService")
	pcall(function()
		local serverFolder = ServerScriptService:FindFirstChild("Server")
		if serverFolder then
			AchievementManager = require(serverFolder:FindFirstChild("AchievementManager"))
		end
	end)
end

-- ==================== PUBLIC FUNCTIONS ==================== --

function BoatFuel.Initialize(config)
	-- Config contains: boat, script, baseMaxFuel, initialFuel, player (optional, for server-side)
	BoatFuel.boat = config.boat
	BoatFuel.script = config.script
	BoatFuel.player = config.player  -- Store player reference for server-side achievement tracking
	
	-- Debug: Check if player reference is available for achievement tracking
	if isServer then
		if BoatFuel.player then
			print("⛽ BoatFuel initialized for player:", BoatFuel.player.Name, "- Achievement tracking enabled")
		else
			warn("⚠️ BoatFuel initialized on server without player reference - Achievement tracking disabled")
		end
	end
	
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
	
	-- Create or get FuelAmount on the boat
	local fuelAmount = config.boat:FindFirstChild("FuelAmount")
	if not fuelAmount then
		fuelAmount = Instance.new("NumberValue")
		fuelAmount.Name = "FuelAmount"
		fuelAmount.Value = 0  -- Start at 0, will be set by UpgradeManager.setInitialFuel()
		fuelAmount.Parent = config.boat
		print("⛽ Created FuelAmount on boat, waiting for saved value from DataStore")
	else
		print("⛽ Found existing FuelAmount on boat with value:", fuelAmount.Value, "(will be updated from DataStore)")
	end
	
	-- Listen for FuelAmount changes (e.g., from UpgradeManager.setInitialFuel or fuel purchases)
	fuelAmount.Changed:Connect(function(newValue)
		currentFuel = newValue
		-- print("⛽ FuelAmount changed to:", newValue)
		
		-- Update InitialFuel in script to keep it in sync
		local InitialFuel = config.script:FindFirstChild("InitialFuel")
		if InitialFuel then
			InitialFuel.Value = newValue
		end
	end)
	
	-- Check if InitialFuel already exists (in case it was set before this script ran)
	local InitialFuel = config.script:FindFirstChild("InitialFuel")
	if InitialFuel and InitialFuel.Value > 0 then
		-- InitialFuel was already set, use it immediately
		currentFuel = InitialFuel.Value
		fuelAmount.Value = currentFuel
		print("⛽ Loaded initial fuel from InitialFuel:", currentFuel)
	else
		-- Wait for UpgradeManager to set the value
		-- Use the existing FuelAmount value or 0 as temporary
		currentFuel = fuelAmount.Value
		if currentFuel == 0 then
			print("⛽ Waiting for DataStore to load fuel value...")
		else
			print("⛽ Using temporary fuel value:", currentFuel, "(waiting for DataStore)")
		end
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
		
		-- Track distance for achievements
		distanceAccumulator = distanceAccumulator + distance
		if distanceAccumulator >= DISTANCE_REPORT_THRESHOLD then
			-- Report to achievement system
			if isServer and AchievementManager and BoatFuel.player then
				-- Server-side: Direct call
				AchievementManager.IncrementDistance(BoatFuel.player, distanceAccumulator)
				distanceAccumulator = 0
			elseif not isServer then
				-- Client-side: Use RemoteEvent
				local achievementEvent = ReplicatedStorage:FindFirstChild("AchievementEvent")
				if achievementEvent then
					achievementEvent:FireServer("reportDistance", distanceAccumulator)
					distanceAccumulator = 0
				end
			end
		end
		
		-- Consume fuel
		local fuelToConsume = distance * FUEL_CONSUMPTION_RATE
		local previousFuel = currentFuel
		currentFuel = math.max(0, currentFuel - fuelToConsume)
		
		-- Report fuel consumed to achievement system
		if fuelToConsume > 0 then
			if isServer and AchievementManager and BoatFuel.player then
				-- Server-side: Direct call
				AchievementManager.IncrementFuelConsumed(BoatFuel.player, fuelToConsume)
			elseif not isServer then
				-- Client-side: Use RemoteEvent
				local achievementEvent = ReplicatedStorage:FindFirstChild("AchievementEvent")
				if achievementEvent then
					achievementEvent:FireServer("reportFuelConsumed", fuelToConsume)
				end
			end
		end
		
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
