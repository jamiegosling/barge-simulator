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
		maxLevel = 20
	},
	cargo_capacity = {
		baseCost = 2500,
		costMultiplier = 1.5,
		capacityIncrease = 1.1,
		maxLevel = 20
	},
	fuel_capacity = {
		baseCost = 2500,
		costMultiplier = 1.5,
		capacityIncrease = 1.1,
		maxLevel = 20
	}
}

-- Player upgrade data cache
local playerUpgrades = {}

-- Track which players are being saved to prevent duplicates
local savingPlayers = {}

-- Player-specific auto-save control (for testing)
local playersWithDisabledAutoSave = {}

-- Track fuel changes for smart saving
local fuelChangeTimestamps = {}

-- Check if running in Studio
local IS_STUDIO = game:GetService("RunService"):IsStudio()
local AUTO_SAVE_INTERVAL = IS_STUDIO and 10 or 60  -- 10 seconds in Studio, 60 in production

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
	print("🎮 UpgradeManager: initializePlayerUpgrades called for", player.Name)
	local userId = tostring(player.UserId)
	
	-- Check if we're in Studio and DataStore isn't available
	local isStudio = game:GetService("RunService"):IsStudio()
	
	print("📊 UpgradeManager: Loading data from DataStore for", player.Name)
	-- Load player data from DataStore
	local success, data = pcall(function()
		return upgradeDataStore:GetAsync(userId)
	end)
	print("📊 UpgradeManager: DataStore load result - success:", success, "data exists:", data ~= nil)
	
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
			money = 0,  -- Add money persistence
			currentFuel = 100  -- Add current fuel persistence
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
	
	-- Add currentFuel if missing
	if not data.currentFuel then
		data.currentFuel = 100
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
	
	print("✅ Initialized upgrades for", player.Name, "Speed Level:", data.speedLevel or 1, "Cargo Level:", data.cargoLevel or 1, "Fuel Level:", data.fuelLevel or 1, "Money: £" .. (data.money or 0), "Current Fuel:", data.currentFuel or 100)
	
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
	print("🔔 Firing upgradeDataLoaded event for", player.Name)
	upgradeDataLoaded:Fire(player)
	print("✅ upgradeDataLoaded event fired for", player.Name)
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
	
	-- Debug: Show what we're about to save
	print("DEBUG: About to save for", player.Name)
	print("  - upgrades table exists:", upgrades ~= nil)
	if upgrades then
		print("  - currentFuel:", upgrades.currentFuel)
		print("  - money:", upgrades.money)
		print("  - speedLevel:", upgrades.speedLevel)
	end
	
	-- Note: Fuel is now saved in BoatSpawner before boat destruction
	-- to ensure it's available when PlayerRemoving fires
	
	-- Check if we're in Studio
	local isStudio = game:GetService("RunService"):IsStudio()
	
	print("DEBUG: Attempting DataStore save for", player.Name)
	print("  - userId:", userId)
	print("  - isStudio:", isStudio)
	
	-- Use UpdateAsync to prevent race conditions
	local success, errorMessage = pcall(function()
		upgradeDataStore:UpdateAsync(userId, function(oldData)
			-- If oldData exists, merge critical fields (to preserve any concurrent updates)
			-- but always use our current upgrades data as the source of truth
			return upgrades
		end)
	end)
	
	print("DEBUG: DataStore save result - success:", success)
	if not success then
		print("DEBUG: Error message:", errorMessage)
		if isStudio and string.find(tostring(errorMessage), "StudioAccessToApisNotAllowed") then
			print("Studio mode - skipping save for", player.Name)
		else
			warn("Failed to save upgrade data for " .. player.Name .. ": " .. tostring(errorMessage))
		end
	else
		print("✅ Saved upgrades and money for", player.Name, "- Speed Level:", upgrades.speedLevel, "Cargo Level:", upgrades.cargoLevel, "Fuel Level:", upgrades.fuelLevel, "Current Fuel:", upgrades.currentFuel, "Money: £" .. (upgrades.money or 0))
		
		-- Clear fuel change timestamp after successful save
		fuelChangeTimestamps[userId] = nil
		
		-- Verify the save by reading back immediately (only in Studio for debugging)
		if IS_STUDIO then
			local verifySuccess, verifyData = pcall(function()
				return upgradeDataStore:GetAsync(userId)
			end)
			
			if verifySuccess then
				print("DEBUG: Verification - currentFuel in DataStore:", verifyData.currentFuel)
			else
				print("DEBUG: Verification failed:", verifyData)
			end
		end
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
	
	-- Use proper key mapping
	local keyMapping = {
		speed = "speedLevel",
		cargo_capacity = "cargoLevel",
		fuel_capacity = "fuelLevel"
	}
	local levelKey = keyMapping[upgradeType]
	if not levelKey or not upgrades[levelKey] then return 1 end
	
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

-- Set InitialFuel from DataStore (called during boat spawning)
local function setInitialFuel(boat, player)
	local userId = tostring(player.UserId)
	local upgrades = playerUpgrades[userId]
	
	print("⛽ UpgradeManager.setInitialFuel: Attempting to set initial fuel for", player.Name)
	if upgrades then
		print("⛽ UpgradeManager.setInitialFuel: Found upgrades data, currentFuel:", upgrades.currentFuel)
	else
		warn("⛽ UpgradeManager.setInitialFuel: No upgrades data found for", player.Name)
		return
	end
	
	if upgrades.currentFuel then
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
				-- Remove old InitialFuel if it exists
				local oldInitialFuel = boatScript:FindFirstChild("InitialFuel")
				if oldInitialFuel then
					oldInitialFuel:Destroy()
				end
				
				-- Create new InitialFuel value
				local initialFuelValue = Instance.new("NumberValue")
				initialFuelValue.Name = "InitialFuel"
				initialFuelValue.Value = upgrades.currentFuel
				initialFuelValue.Parent = boatScript
				
				-- Also update the FuelAmount on the boat itself
				local fuelAmount = boat:FindFirstChild("FuelAmount")
				if fuelAmount then
					print("⛽ UpgradeManager.setInitialFuel: Found FuelAmount, updating from", fuelAmount.Value, "to", upgrades.currentFuel)
					fuelAmount.Value = upgrades.currentFuel
					print("⛽ UpgradeManager.setInitialFuel: Updated boat FuelAmount to:", fuelAmount.Value)
				else
					warn("⛽ UpgradeManager.setInitialFuel: No FuelAmount found on boat, creating it")
					-- Create it if it doesn't exist
					local newFuelAmount = Instance.new("NumberValue")
					newFuelAmount.Name = "FuelAmount"
					newFuelAmount.Value = upgrades.currentFuel
					newFuelAmount.Parent = boat
					print("⛽ UpgradeManager.setInitialFuel: Created FuelAmount with value:", upgrades.currentFuel)
				end
				
				print("⛽ UpgradeManager.setInitialFuel: Set InitialFuel for", player.Name, "to:", upgrades.currentFuel)
			else
				print("No boat script found in VehicleSeat")
			end
		else
			print("No VehicleSeat found in boat")
		end
	else
		print("No currentFuel found in upgrades data for", player.Name)
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

-- Function to update fuel and mark for saving
local function updatePlayerFuel(player, newFuelValue)
	local userId = tostring(player.UserId)
	local upgrades = playerUpgrades[userId]
	
	if upgrades then
		local oldFuel = upgrades.currentFuel
		upgrades.currentFuel = newFuelValue
		fuelChangeTimestamps[userId] = tick()  -- Mark time of change
		print("⛽ UpgradeManager: Updated fuel for", player.Name, "from", oldFuel, "to", newFuelValue)
	else
		warn("⚠️ UpgradeManager: No upgrades data found for", player.Name, "when trying to update fuel")
	end
end

-- Player events
Players.PlayerAdded:Connect(initializePlayerUpgrades)

-- Initialize players who are already in the game (important for Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	print("🔄 Initializing upgrades for player already in game:", player.Name)
	initializePlayerUpgrades(player)
end

-- Note: PlayerRemoving save is now handled by BoatSpawner to ensure fuel is saved before boat destruction
-- Players.PlayerRemoving:Connect(savePlayerUpgrades)

-- Auto-save (10 seconds in Studio, 60 in production)
coroutine.wrap(function()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			-- Only save if auto-save is not disabled for this player
			if not isPlayerAutoSaveDisabled(player) then
				savePlayerUpgrades(player)
			end
		end
	end
end)()

-- Studio-specific: Additional save on fuel changes (every 5 seconds if fuel changed)
if IS_STUDIO then
	coroutine.wrap(function()
		while true do
			task.wait(5)
			for _, player in ipairs(Players:GetPlayers()) do
				local userId = tostring(player.UserId)
				-- If fuel changed in last 5 seconds and not disabled, save it
				if fuelChangeTimestamps[userId] and not isPlayerAutoSaveDisabled(player) then
					local timeSinceChange = tick() - fuelChangeTimestamps[userId]
					if timeSinceChange < 5 then
						print("⛽ Studio: Saving fuel for", player.Name, "(changed recently)")
						savePlayerUpgrades(player)
					end
				end
			end
		end
	end)()
end

-- Bind to game close to save all player data (important for Studio testing)
game:BindToClose(function()
	print("🛑 Game closing - saving all player data...")
	for _, player in ipairs(Players:GetPlayers()) do
		if not isPlayerAutoSaveDisabled(player) then
			savePlayerUpgrades(player)
		end
	end
	-- Give time for saves to complete
	if IS_STUDIO then
		print("⏳ Waiting 2 seconds for saves to complete...")
		task.wait(2)
		print("✅ Save complete, safe to close")
	else
		task.wait(5)  -- More time in production
	end
end)

-- Handle upgrade requests (defined after all functions are available)
upgradeEvent.OnServerEvent:Connect(function(player, action, upgradeType)
	if action == "purchase" then
		local result = purchaseUpgrade(player, upgradeType)
		upgradeEvent:FireClient(player, "purchaseResult", result)
	elseif action == "manualSave" then
		-- Manual save for testing
		print("🔧 Manual save requested for", player.Name)
		savePlayerUpgrades(player)
		upgradeEvent:FireClient(player, "saveComplete", {success = true})
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
	setInitialFuel = setInitialFuel,
	savePlayerUpgrades = savePlayerUpgrades,
	updatePlayerFuel = updatePlayerFuel,  -- New: track fuel changes
	getPlayerUpgrades = function(player) 
		local userId = tostring(player.UserId)
		return playerUpgrades[userId]
	end,
	getAutoSaveEnabled = getAutoSaveEnabled,
	setAutoSaveEnabled = setAutoSaveEnabled,
	setPlayerAutoSave = setPlayerAutoSave,
	isPlayerAutoSaveDisabled = isPlayerAutoSaveDisabled
}
