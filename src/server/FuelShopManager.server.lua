local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- RemoteEvent for fuel shop communication
local fuelShopEvent = Instance.new("RemoteEvent")
fuelShopEvent.Name = "FuelShopEvent"
fuelShopEvent.Parent = ReplicatedStorage

-- Fuel shop configuration
local FUEL_COST_PER_UNIT = 5  -- Cost per unit of fuel

-- Get the UpgradeManager module
local upgradeManager = require(script.Parent.UpgradeManager)

-- Calculate max fuel based on fuel level
local function calculateMaxFuel(fuelLevel)
	local baseMaxFuel = 200
	return math.floor(baseMaxFuel * (1.1 ^ (fuelLevel - 1)))
end

-- Get player's current fuel information
local function getPlayerFuelInfo(player)
	local playerBoat = workspace:FindFirstChild("PlayerBoats") and workspace.PlayerBoats:FindFirstChild("Boat_" .. player.Name)
	if not playerBoat then
		return nil
	end
	
	-- Get fuel amount from boat
	local fuelAmount = playerBoat:FindFirstChild("FuelAmount")
	local currentFuel = fuelAmount and fuelAmount.Value or 100
	
	-- Get fuel level from player stats
	local fuelLevel = 1
	local upgradeStats = player:FindFirstChild("UpgradeStats")
	if upgradeStats then
		local fuelLevelValue = upgradeStats:FindFirstChild("FuelLevel")
		if fuelLevelValue then
			fuelLevel = fuelLevelValue.Value
		end
	end
	
	-- Calculate max fuel based on fuel level
	local maxFuel = calculateMaxFuel(fuelLevel)
	
	return {
		currentFuel = currentFuel,
		maxFuel = maxFuel,
		fuelLevel = fuelLevel,
		playerBoat = playerBoat
	}
end

-- Process fuel purchase
local function purchaseFuel(player, fuelAmount)
	local fuelInfo = getPlayerFuelInfo(player)
	if not fuelInfo then
		return {success = false, message = "No boat found!"}
	end
	
	-- Calculate cost
	local cost = fuelAmount * FUEL_COST_PER_UNIT
	
	-- Check if player has enough money
	local money = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if not money or money.Value < cost then
		return {success = false, message = "Not enough money! Need £" .. cost}
	end
	
	-- Check if fuel amount is valid (don't overfill)
	local maxFuelable = fuelInfo.maxFuel - fuelInfo.currentFuel
	if fuelAmount > maxFuelable then
		return {success = false, message = "Cannot add that much fuel!"}
	end
	
	-- Process purchase
	money.Value -= cost
	
	-- Update fuel on boat
	local fuelAmountValue = fuelInfo.playerBoat:FindFirstChild("FuelAmount")
	if fuelAmountValue then
		fuelAmountValue.Value = fuelInfo.currentFuel + fuelAmount
	else
		-- Create FuelAmount if it doesn't exist
		fuelAmountValue = Instance.new("NumberValue")
		fuelAmountValue.Name = "FuelAmount"
		fuelAmountValue.Value = fuelInfo.currentFuel + fuelAmount
		fuelAmountValue.Parent = fuelInfo.playerBoat
	end
	
	-- Update fuel in boat script
	local vehicleSeat = fuelInfo.playerBoat:FindFirstChildWhichIsA("VehicleSeat")
	if vehicleSeat then
		local boatScript = vehicleSeat:FindFirstChildWhichIsA("LocalScript")
		if not boatScript then
			boatScript = vehicleSeat:FindFirstChildWhichIsA("Script")
		end
		
		if boatScript then
			-- Update InitialFuel to match new fuel amount
			local initialFuel = boatScript:FindFirstChild("InitialFuel")
			if initialFuel then
				initialFuel.Value = fuelInfo.currentFuel + fuelAmount
			end
		end
	end
	
	-- Update player's fuel data in DataStore
	local playerUpgrades = upgradeManager.getPlayerUpgrades(player)
	if playerUpgrades then
		playerUpgrades.currentFuel = fuelInfo.currentFuel + fuelAmount
	end
	
	print(player.Name, "purchased", fuelAmount, "fuel for £" .. cost)
	print("New fuel level:", fuelInfo.currentFuel + fuelAmount, "/", fuelInfo.maxFuel)
	
	return {
		success = true,
		message = "Purchased " .. fuelAmount .. " fuel for £" .. cost .. "!",
		newFuelLevel = fuelInfo.currentFuel + fuelAmount,
		maxFuel = fuelInfo.maxFuel,
		cost = cost
	}
end

-- Handle fuel shop requests
fuelShopEvent.OnServerEvent:Connect(function(player, action, data)
	if action == "purchaseFuel" then
		local result = purchaseFuel(player, data)
		fuelShopEvent:FireClient(player, "fuelPurchaseResult", result)
	end
end)

-- Create fuel shop detectors for fuel shop models
local function createFuelShopDetector(model)
	print("[FuelShop] Creating detector for model:", model.Name)
	
	-- Get model position (use pivot or calculate from bounding box)
	local modelPosition
	if model.PrimaryPart then
		modelPosition = model.PrimaryPart.Position
		print("[FuelShop] Using PrimaryPart position:", modelPosition)
	else
		-- Calculate center of bounding box
		local cf, size = model:GetBoundingBox()
		modelPosition = cf.Position
		print("[FuelShop] Using bounding box position:", modelPosition)
	end
	
	-- Create a trigger part for the fuel shop
	local trigger = model:FindFirstChild("Trigger")
	if not trigger then
		print("[FuelShop] Creating new trigger part")
		-- Create a trigger part if it doesn't exist
		trigger = Instance.new("Part")
		trigger.Name = "Trigger"
		trigger.Size = Vector3.new(150, 150, 150)
		trigger.Position = modelPosition + Vector3.new(0, 2, 0)
		trigger.Anchored = true
		trigger.CanCollide = false
		trigger.Transparency = 1
		trigger.Parent = model
		print("[FuelShop] Trigger created at position:", trigger.Position)
		
		-- Add a detection zone visual (optional)
		-- local detectionZone = Instance.new("Part")
		-- detectionZone.Name = "DetectionZone"
		-- detectionZone.Size = Vector3.new(150, 150, 150)  -- Roughly matches ProximityPrompt range
		-- detectionZone.Position = modelPosition + Vector3.new(0, 0.5, 0)
		-- detectionZone.Anchored = true
		-- detectionZone.CanCollide = false
		-- detectionZone.Transparency = 0.9
		-- detectionZone.BrickColor = BrickColor.new("Bright yellow")
		-- detectionZone.Material = Enum.Material.Neon
		-- detectionZone.Parent = model
		-- print("[FuelShop] Detection zone created at position:", detectionZone.Position)
	else
		print("[FuelShop] Using existing trigger")
	end
	
	-- Add a FuelShop tag to identify it
	local tag = Instance.new("StringValue")
	tag.Name = "FuelShop"
	tag.Parent = model
	
	-- Add proximity prompt for interaction (always add, even if trigger exists)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy Fuel"
	prompt.ObjectText = "Fuel Station"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 75  -- Match the large trigger zone (150/2)
	prompt.RequiresLineOfSight = false
	prompt.Parent = trigger
	
	print("[FuelShop] Proximity prompt added to trigger")
	
	-- Handle proximity prompt trigger
	prompt.Triggered:Connect(function(player)
		print("[FuelShop] Player", player.Name, "triggered fuel shop prompt")
		
		-- Check if player is in a boat
		local playerBoat = workspace:FindFirstChild("PlayerBoats") and workspace.PlayerBoats:FindFirstChild("Boat_" .. player.Name)
		if playerBoat then
			print("[FuelShop] Player has boat, opening fuel shop GUI")
			fuelShopEvent:FireClient(player, "openFuelShop")
		else
			print("[FuelShop] Player has no boat, cannot open fuel shop")
		end
	end)
	
	print("Created fuel shop detector for model:", model.Name)
end

-- Find and setup existing fuel shop models
workspace.ChildAdded:Connect(function(child)
	print("[FuelShop] Workspace child added:", child.Name, "Type:", child.ClassName)
	if child:IsA("Model") then
		local hasFuelShopInName = child.Name:find("FuelShop") ~= nil
		local hasFuelShopChild = child:FindFirstChild("FuelShop") ~= nil
		print("[FuelShop] Model check - Name contains 'FuelShop':", hasFuelShopInName, "Has FuelShop child:", hasFuelShopChild)
		
		if hasFuelShopInName or hasFuelShopChild then
			print("[FuelShop] Model qualifies as fuel shop, creating detector")
			createFuelShopDetector(child)
		end
	end
end)

-- Setup existing models
print("[FuelShop] Scanning workspace for existing fuel shop models...")
local fuelShopsFound = 0
for _, child in ipairs(workspace:GetChildren()) do
	if child:IsA("Model") then
		local hasFuelShopInName = child.Name:find("FuelShop") ~= nil
		local hasFuelShopChild = child:FindFirstChild("FuelShop") ~= nil
		
		if hasFuelShopInName or hasFuelShopChild then
			print("[FuelShop] Found existing fuel shop:", child.Name)
			createFuelShopDetector(child)
			fuelShopsFound = fuelShopsFound + 1
		end
	end
end

print("[FuelShop] Fuel shop manager initialized - Found", fuelShopsFound, "fuel shop(s)")
