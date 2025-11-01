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
		baseCost = 100,
		costMultiplier = 1.5,
		speedIncrease = 2,
		maxLevel = 20
	}
}

-- Player upgrade data cache
local playerUpgrades = {}

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
			moneySpent = 0,
			money = 0  -- Add money persistence
		}
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
	
	-- Load money from DataStore (will override GameManager's initial money)
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if leaderstats then
		local money = leaderstats:WaitForChild("Money", 5)
		if money then
			money.Value = data.money or 0
			print("Loaded money for", player.Name .. ": £" .. money.Value)
		end
	end
	
	print("Initialized upgrades for", player.Name, "Speed Level:", data.speedLevel or 1, "Money: £" .. (data.money or 0))
	
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
		print("Saved upgrades and money for", player.Name, "- Speed Level:", upgrades.speedLevel, "Money: £" .. (upgrades.money or 0))
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

-- Update boat speed with current upgrades
local function updateBoatSpeed(boat, player)
	local speedMultiplier = getSpeedMultiplier(player)
	
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
			-- Store original MaxSpeed if not already stored
			if not boatScript:FindFirstChild("OriginalMaxSpeed") then
				local originalSpeed = Instance.new("NumberValue")
				originalSpeed.Name = "OriginalMaxSpeed"
				originalSpeed.Value = 500 -- Default from your script
				originalSpeed.Parent = boatScript
			end
			
			-- Apply speed multiplier by creating a value in the script
			local originalSpeed = boatScript:FindFirstChild("OriginalMaxSpeed")
			if originalSpeed then
				-- Remove old speed multiplier if it exists
				local oldMultiplier = boatScript:FindFirstChild("SpeedMultiplier")
				if oldMultiplier then
					oldMultiplier:Destroy()
				end
				
				-- Create new speed multiplier value
				local speedMultiplierValue = Instance.new("NumberValue")
				speedMultiplierValue.Name = "SpeedMultiplier"
				speedMultiplierValue.Value = speedMultiplier
				speedMultiplierValue.Parent = boatScript
				
				print("Updated boat speed for", player.Name, "to multiplier:", speedMultiplier)
			end
		else
			warn("No boat script found in VehicleSeat for", player.Name)
		end
	end
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
	
	local currentLevel = upgrades.speedLevel
	if upgradeType == "speed" then
		currentLevel = upgrades.speedLevel
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
	upgrades.speedLevel += 1
	upgrades.moneySpent += cost
	
	-- Update player's upgrade stats
	local speedLevelValue = player:FindFirstChild("UpgradeStats") and player.UpgradeStats:FindFirstChild("SpeedLevel")
	if speedLevelValue then
		speedLevelValue.Value = upgrades.speedLevel
	end
	
	print(player.Name, "upgraded", upgradeType, "to level", upgrades.speedLevel, "for £" .. cost)
	
	-- Update existing boat speed if player has one
	local playerBoat = workspace:FindFirstChild("PlayerBoats") and workspace.PlayerBoats:FindFirstChild("Boat_" .. player.Name)
	if playerBoat then
		updateBoatSpeed(playerBoat, player)
	end
	
	return {
		success = true, 
		message = "Upgrade purchased! Speed level: " .. upgrades.speedLevel,
		newLevel = upgrades.speedLevel,
		cost = cost
	}
end

-- Get current boat speed multiplier
local function getSpeedMultiplier(player)
	local userId = tostring(player.UserId)
	local upgrades = playerUpgrades[userId]
	
	if not upgrades or not upgrades.speedLevel then 
		return 1 
	end
	
	local config = UPGRADE_CONFIG.speed
	return 1 + (upgrades.speedLevel - 1) * config.speedIncrease
end

-- Handle upgrade requests
upgradeEvent.OnServerEvent:Connect(function(player, action, upgradeType)
	if action == "purchase" then
		local result = purchaseUpgrade(player, upgradeType)
		upgradeEvent:FireClient(player, "purchaseResult", result)
	elseif action == "getInfo" then
		local userId = tostring(player.UserId)
		local upgrades = playerUpgrades[userId]
		
		if upgrades then
			local nextCost = getUpgradeCost(upgradeType, upgrades.speedLevel)
			local speedMultiplier = getSpeedMultiplier(player)
			
			upgradeEvent:FireClient(player, "upgradeInfo", {
				currentLevel = upgrades.speedLevel,
				nextCost = nextCost,
				speedMultiplier = speedMultiplier,
				maxLevel = UPGRADE_CONFIG.speed.maxLevel
			})
		end
	end
end)

-- Player events
Players.PlayerAdded:Connect(initializePlayerUpgrades)

Players.PlayerRemoving:Connect(savePlayerUpgrades)

-- Auto-save every 60 seconds
coroutine.wrap(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerUpgrades(player)
		end
	end
end)()

-- Export functions for other scripts
return {
	getSpeedMultiplier = getSpeedMultiplier,
	getPlayerUpgrades = function(player) return playerUpgrades[tostring(player.UserId)] end
}
