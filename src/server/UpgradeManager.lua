local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DataStore for persistent player upgrade data
local upgradeDataStore = DataStoreService:GetDataStore("BoatUpgrades")

-- RemoteEvents for client-server communication
local upgradeEvent = Instance.new("RemoteEvent")
upgradeEvent.Name = "UpgradeEvent"
upgradeEvent.Parent = ReplicatedStorage

-- Signal to indicate when upgrade data is loaded
local upgradeDataLoaded = Instance.new("BindableEvent")
upgradeDataLoaded.Name = "UpgradeDataLoaded"
upgradeDataLoaded.Parent = script

-- Upgrade configuration
local UPGRADE_CONFIG = {
	speed = {
		baseCost = 2500,
		costMultiplier = 1.5,
		speedIncrease = 1.1,
		maxLevel = 35
	},
	cargo_capacity = {
		baseCost = 2500,
		costMultiplier = 1.5,
		capacityIncrease = 1.1,
		maxLevel = 35
	},
	fuel_capacity = {
		baseCost = 2500,
		costMultiplier = 1.5,
		capacityIncrease = 1.1,
		maxLevel = 35
	}
}

-- Player upgrade data cache
local playerUpgrades = {}

-- Auto-save control (can be modified by test script)
local autoSaveEnabled = true

-- Player-specific auto-save control (for testing)
local playersWithDisabledAutoSave = {}

-- Function to get auto-save status
function getAutoSaveEnabled()
	return autoSaveEnabled
end

-- Function to set auto-save status
function setAutoSaveEnabled(enabled)
	autoSaveEnabled = enabled
end

-- Function to disable auto-save for specific player (testing)
function setPlayerAutoSave(player, enabled)
	local userId = tostring(player.UserId)
	if enabled then
		playersWithDisabledAutoSave[userId] = nil
		print("Auto-save ENABLED for", player.Name)
	else
		playersWithDisabledAutoSave[userId] = true
		print("Auto-save DISABLED for", player.Name, "(testing mode)")
	end
end

-- Function to check if player has auto-save disabled
function isPlayerAutoSaveDisabled(player)
	local userId = tostring(player.UserId)
	return playersWithDisabledAutoSave[userId] == true
end

-- Initialize player upgrades when they join
local function initializePlayerUpgrades(player)
	local userId = tostring(player.UserId)
	
	-- Check if we're in Studio and DataStore isn't available
	local isStudio = game:GetService("RunService"):IsStudio()
	
	-- Load player data from DataStore
	local success, data = pcall(function()
		return upgradeDataStore:GetAsync(userId)
	end)
	
	if not success then
		if isStudio and string.find(tostring(data), "StudioAccessToApisNotAllowed") then
			print("Studio mode detected - using temporary upgrade data for", player.Name)
			data = nil
		else
			warn("Failed to load upgrade data for " .. player.Name .. ": " .. tostring(data))
			data = nil
		end
	end
	
	-- Set default values if no data exists
	if not data then
		data = {
			speedLevel = 1,
			cargoLevel = 1,
			fuelLevel = 1,
			moneySpent = 0,
			money = 0  -- Add money persistence
		}
	end

	-- Add any missing keys (for upgrades added since player has played)
	local keyMapping = {
		speed = "speedLevel",
		cargo_capacity = "cargoLevel",
		fuel_capacity = "fuelLevel"
	}
	
	for upgradeType, dataKey in pairs(keyMapping) do
		if not data[dataKey] then
			data[dataKey] = 1
		end
	end
	
	playerUpgrades[userId] = data
	
	-- Create upgrade stats folder
	local upgradeStats = Instance.new("Folder")
	upgradeStats.Name = "UpgradeStats"
	upgradeStats.Parent = player
	
	local speedLevel = Instance.new("IntValue")
	speedLevel.Name = "SpeedLevel"
	speedLevel.Value = data.speedLevel or 1
	speedLevel.Parent = upgradeStats
	
	local cargoLevel = Instance.new("IntValue")
	cargoLevel.Name = "CargoLevel"
	cargoLevel.Value = data.cargoLevel or 1
	cargoLevel.Parent = upgradeStats
	
	local fuelLevel = Instance.new("IntValue")
	fuelLevel.Name = "FuelLevel"
	fuelLevel.Value = data.fuelLevel or 1
	fuelLevel.Parent = upgradeStats
	
	-- Load money from DataStore (will override GameManager's initial money)
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if leaderstats then
		local money = leaderstats:WaitForChild("Money", 5)
		if money then
			money.Value = data.money or 0
			print("Loaded money for", player.Name .. ": £" .. money.Value)
		end
	end
	
	print("Initialized upgrades for", player.Name, "Speed Level:", data.speedLevel or 1, "Cargo Level:", data.cargoLevel or 1, "Fuel Level:", data.fuelLevel or 1, "Money: £" .. (data.money or 0))
	
	-- Track money changes for auto-saving
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if leaderstats then
		local money = leaderstats:WaitForChild("Money", 5)
		if money then
			money.Changed:Connect(function(newValue)
				-- Update local data when money changes
				local upgrades = playerUpgrades[userId]
				if upgrades then
					upgrades.money = newValue
				end
			end)
		end
	end
	
	-- Fire signal to indicate upgrade data is loaded
	upgradeDataLoaded:Fire(player)
end

-- Save player upgrades to DataStore
local function savePlayerUpgrades(player)
	-- Check if auto-save is disabled for this specific player
	if isPlayerAutoSaveDisabled(player) then
		print("Auto-save disabled for", player.Name, "- skipping save")
		return
	end
	
	local userId = tostring(player.UserId)
	local upgrades = playerUpgrades[userId]
	
	if not upgrades then return end
	
	-- Get current money from leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild("Money")
		if money then
			upgrades.money = money.Value
		end
	end
	
	-- Check if we're in Studio
	local isStudio = game:GetService("RunService"):IsStudio()
	
	local success, errorMessage = pcall(function()
		upgradeDataStore:SetAsync(userId, upgrades)
	end)
	
	if not success then
		if isStudio and string.find(tostring(errorMessage), "StudioAccessToApisNotAllowed") then
			print("Studio mode - skipping save for", player.Name)
		else
			warn("Failed to save upgrade data for " .. player.Name .. ": " .. tostring(errorMessage))
		end
	else
		print("Saved upgrades and money for", player.Name, "- Speed Level:", upgrades.speedLevel, "Cargo Level:", upgrades.cargoLevel, "Fuel Level:", upgrades.fuelLevel, "Money: £" .. (upgrades.money or 0))
	end
end

-- Get upgrade cost for next level
local function getUpgradeCost(upgradeType, currentLevel)
	local config = UPGRADE_CONFIG[upgradeType]
	if not config then return nil end
	
	if currentLevel >= config.maxLevel then
		return nil -- Max level reached
	end
	
	return math.floor(config.baseCost * (config.costMultiplier ^ (currentLevel - 1)))
end

-- Get upgrade multiplier for any upgrade type
local function getUpgradeMultiplier(player, upgradeType)
	local userId = tostring(player.UserId)
	local upgrades = playerUpgrades[userId]
	
	if not upgrades then return 1 end
	
	local levelKey = upgradeType .. "Level"
	if not upgrades[levelKey] then return 1 end
	
	local config = UPGRADE_CONFIG[upgradeType]
	if not config then return 1 end
	
	local increaseKey = upgradeType == "speed" and "speedIncrease" or "capacityIncrease"
	return config[increaseKey] ^ (upgrades[levelKey] - 1)
end

-- Get current boat speed multiplier (backward compatibility)
local function getSpeedMultiplier(player)
	return getUpgradeMultiplier(player, "speed")
end

-- Update boat upgrade with current upgrades
local function updateBoatUpgrade(boat, player, upgradeType)
	local multiplier = getUpgradeMultiplier(player, upgradeType)
	
	-- Find the VehicleSeat in the boat
	local vehicleSeat = boat:FindFirstChildWhichIsA("VehicleSeat")
	if vehicleSeat then
		-- Look for the custom boat script in the seat
		local boatScript = vehicleSeat:FindFirstChildWhichIsA("LocalScript")
		if not boatScript then
			-- Also check for regular Script
			boatScript = vehicleSeat:FindFirstChildWhichIsA("Script")
		end
		
		if boatScript then
			-- Store original value if not already stored
			local originalName = "Original" .. (upgradeType == "speed" and "MaxSpeed" or upgradeType == "cargo_capacity" and "CargoCapacity" or "FuelCapacity")
			if not boatScript:FindFirstChild(originalName) then
				local originalValue = Instance.new("NumberValue")
				originalValue.Name = originalName
				originalValue.Value = upgradeType == "speed" and 500 or upgradeType == "cargo_capacity" and 100 or 200
				originalValue.Parent = boatScript
			end
			
			-- Apply multiplier by creating a value in the script
			local originalValue = boatScript:FindFirstChild(originalName)
			if originalValue then
				-- Remove old multiplier if it exists
				local multiplierName = upgradeType == "speed" and "SpeedMultiplier" or upgradeType == "cargo_capacity" and "CargoMultiplier" or "FuelMultiplier"
				local oldMultiplier = boatScript:FindFirstChild(multiplierName)
				if oldMultiplier then
					oldMultiplier:Destroy()
				end
				
				-- Create new multiplier value
				local multiplierValue = Instance.new("NumberValue")
				multiplierValue.Name = multiplierName
				multiplierValue.Value = multiplier
				multiplierValue.Parent = boatScript
				
				print("Updated boat", upgradeType, "for", player.Name, "to multiplier:", multiplier)
			end
		else
			warn("No boat script found in VehicleSeat for", player.Name)
		end
	end
end

-- Update boat speed with current upgrades (backward compatibility)
local function updateBoatSpeed(boat, player)
	updateBoatUpgrade(boat, player, "speed")
end

-- Process upgrade purchase
local function purchaseUpgrade(player, upgradeType)
	local userId = tostring(player.UserId)
	local upgrades = playerUpgrades[userId]
	
	if not upgrades then
		return {success = false, message = "Upgrade data not found"}
	end
	
	local config = UPGRADE_CONFIG[upgradeType]
	if not config then
		return {success = false, message = "Invalid upgrade type"}
	end
	
	local keyMapping = {
		speed = "speedLevel",
		cargo_capacity = "cargoLevel",
		fuel_capacity = "fuelLevel"
	}
	
	local levelKey = keyMapping[upgradeType]
	if not levelKey then
		return {success = false, message = "Invalid upgrade type"}
	end
	
	local currentLevel = upgrades[levelKey]
	if not currentLevel then
		return {success = false, message = "Invalid upgrade type or level not found"}
	end
	
	-- Check if max level reached
	if currentLevel >= config.maxLevel then
		return {success = false, message = "Maximum level reached!"}
	end
	
	-- Calculate cost
	local cost = getUpgradeCost(upgradeType, currentLevel)
	
	-- Check if player has enough money
	local money = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if not money or money.Value < cost then
		return {success = false, message = "Not enough money! Need £" .. cost}
	end
	
	-- Process purchase
	money.Value -= cost
	upgrades[levelKey] += 1
	upgrades.moneySpent += cost
	
	-- Update player's upgrade stats
	local levelValue = player:FindFirstChild("UpgradeStats") and player.UpgradeStats:FindFirstChild(upgradeType == "speed" and "SpeedLevel" or upgradeType == "cargo_capacity" and "CargoLevel" or "FuelLevel")
	if levelValue then
		levelValue.Value = upgrades[levelKey]
	end
	
	print(player.Name, "upgraded", upgradeType, "to level", upgrades[levelKey], "for £" .. cost)
	
	-- Update existing boat if player has one
	local playerBoat = workspace:FindFirstChild("PlayerBoats") and workspace.PlayerBoats:FindFirstChild("Boat_" .. player.Name)
	if playerBoat then
		updateBoatUpgrade(playerBoat, player, upgradeType)
	end
	
	return {
		success = true, 
		message = "Upgrade purchased! " .. upgradeType .. " level: " .. upgrades[levelKey],
		newLevel = upgrades[levelKey],
		cost = cost
	}
end

-- Player events
Players.PlayerAdded:Connect(initializePlayerUpgrades)

Players.PlayerRemoving:Connect(savePlayerUpgrades)

-- Auto-save every 60 seconds (respects player-specific settings)
coroutine.wrap(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			-- Only save if auto-save is not disabled for this player
			if not isPlayerAutoSaveDisabled(player) then
				savePlayerUpgrades(player)
			end
		end
	end
end)()

-- Handle upgrade requests (defined after all functions are available)
upgradeEvent.OnServerEvent:Connect(function(player, action, upgradeType)
	if action == "purchase" then
		local result = purchaseUpgrade(player, upgradeType)
		upgradeEvent:FireClient(player, "purchaseResult", result)
	elseif action == "getInfo" then
		local userId = tostring(player.UserId)
		local upgrades = playerUpgrades[userId]
		
		if upgrades then
			local keyMapping = {
				speed = "speedLevel",
				cargo_capacity = "cargoLevel",
				fuel_capacity = "fuelLevel"
			}
			
			local levelKey = keyMapping[upgradeType]
			if not levelKey then
				return -- Invalid upgrade type
			end
			
			local nextCost = getUpgradeCost(upgradeType, upgrades[levelKey])
			local multiplier = getUpgradeMultiplier(player, upgradeType)
			
			upgradeEvent:FireClient(player, "upgradeInfo", {
				currentLevel = upgrades[levelKey],
				nextCost = nextCost,
				multiplier = multiplier,
				maxLevel = UPGRADE_CONFIG[upgradeType].maxLevel
			})
		end
	end
end)

-- Export functions for other scripts
return {
	getUpgradeMultiplier = getUpgradeMultiplier,
	getSpeedMultiplier = getSpeedMultiplier,
	updateBoatUpgrade = updateBoatUpgrade,
	updateBoatSpeed = updateBoatSpeed,
	getPlayerUpgrades = function(player) 
		local userId = tostring(player.UserId)
		return playerUpgrades[userId]
	end,
	getAutoSaveEnabled = getAutoSaveEnabled,
	setAutoSaveEnabled = setAutoSaveEnabled,
	setPlayerAutoSave = setPlayerAutoSave,
	isPlayerAutoSaveDisabled = isPlayerAutoSaveDisabled
}
