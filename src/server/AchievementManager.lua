local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DataStore for persistent player achievement data
local achievementDataStore = DataStoreService:GetDataStore("PlayerAchievements")

-- RemoteEvents for client-server communication
local achievementEvent = Instance.new("RemoteEvent")
achievementEvent.Name = "AchievementEvent"
achievementEvent.Parent = ReplicatedStorage

-- Player achievement data cache
local playerAchievements = {}

-- Track which players are being saved to prevent duplicates
local savingPlayers = {}

-- Check if running in Studio
local IS_STUDIO = game:GetService("RunService"):IsStudio()
local AUTO_SAVE_INTERVAL = IS_STUDIO and 10 or 60  -- 10 seconds in Studio, 60 in production

-- Initialize player achievements when they join
local function initializePlayerAchievements(player)
	print("🏆 AchievementManager: initializePlayerAchievements called for", player.Name)
	local userId = tostring(player.UserId)
	
	-- Check if we're in Studio and DataStore isn't available
	local isStudio = game:GetService("RunService"):IsStudio()
	
	print("📊 AchievementManager: Loading data from DataStore for", player.Name)
	-- Load player data from DataStore
	local success, data = pcall(function()
		return achievementDataStore:GetAsync(userId)
	end)
	print("📊 AchievementManager: DataStore load result - success:", success, "data exists:", data ~= nil)
	
	if not success then
		if isStudio and string.find(tostring(data), "StudioAccessToApisNotAllowed") then
			print("Studio mode detected - using temporary achievement data for", player.Name)
			data = nil
		else
			warn("Failed to load achievement data for " .. player.Name .. ": " .. tostring(data))
			data = nil
		end
	end
	
	-- Set default values if no data exists
	if not data then
		data = {
			totalDistanceTraveled = 0,
			totalJobsCompleted = 0,
			totalMoneyEarned = 0,
			totalFuelConsumed = 0,
			totalUpgradesPurchased = 0,
			longestSingleTrip = 0,
			sessionDistanceTraveled = 0,  -- Reset each session
			jobsByType = {},  -- Track completions per cargo type
			firstJobCompletedTime = nil,
			lastPlayedTime = os.time()
		}
	end
	
	-- Reset session-specific stats
	data.sessionDistanceTraveled = 0
	data.lastPlayedTime = os.time()
	
	playerAchievements[userId] = data
	
	print("✅ Initialized achievements for", player.Name, 
		"Distance:", data.totalDistanceTraveled, 
		"Jobs:", data.totalJobsCompleted,
		"Money Earned:", data.totalMoneyEarned)
end

-- Save player achievements to DataStore
local function savePlayerAchievements(player)
	local userId = tostring(player.UserId)
	local achievements = playerAchievements[userId]
	
	if not achievements then return end
	
	-- Prevent duplicate saves
	if savingPlayers[userId] then
		print("⚠️ Save already in progress for", player.Name)
		return
	end
	savingPlayers[userId] = true
	
	-- Update last played time
	achievements.lastPlayedTime = os.time()
	
	-- Check if we're in Studio
	local isStudio = game:GetService("RunService"):IsStudio()
	
	print("DEBUG: Attempting achievement DataStore save for", player.Name)
	
	-- Use UpdateAsync to prevent race conditions
	local success, errorMessage = pcall(function()
		achievementDataStore:UpdateAsync(userId, function(oldData)
			-- Merge with old data to preserve any concurrent updates
			if oldData then
				-- Keep the higher values (in case of concurrent updates)
				return {
					totalDistanceTraveled = math.max(achievements.totalDistanceTraveled, oldData.totalDistanceTraveled or 0),
					totalJobsCompleted = math.max(achievements.totalJobsCompleted, oldData.totalJobsCompleted or 0),
					totalMoneyEarned = math.max(achievements.totalMoneyEarned, oldData.totalMoneyEarned or 0),
					totalFuelConsumed = math.max(achievements.totalFuelConsumed, oldData.totalFuelConsumed or 0),
					totalUpgradesPurchased = math.max(achievements.totalUpgradesPurchased, oldData.totalUpgradesPurchased or 0),
					longestSingleTrip = math.max(achievements.longestSingleTrip, oldData.longestSingleTrip or 0),
					jobsByType = achievements.jobsByType,
					firstJobCompletedTime = oldData.firstJobCompletedTime or achievements.firstJobCompletedTime,
					lastPlayedTime = achievements.lastPlayedTime
				}
			else
				return achievements
			end
		end)
	end)
	
	savingPlayers[userId] = nil
	
	print("DEBUG: Achievement DataStore save result - success:", success)
	if not success then
		print("DEBUG: Error message:", errorMessage)
		if isStudio and string.find(tostring(errorMessage), "StudioAccessToApisNotAllowed") then
			print("Studio mode - skipping achievement save for", player.Name)
		else
			warn("Failed to save achievement data for " .. player.Name .. ": " .. tostring(errorMessage))
		end
	else
		print("✅ Saved achievements for", player.Name, 
			"- Distance:", achievements.totalDistanceTraveled,
			"Jobs:", achievements.totalJobsCompleted,
			"Money Earned:", achievements.totalMoneyEarned)
	end
end

-- ==================== PUBLIC FUNCTIONS ==================== --

-- Increment distance traveled
local function IncrementDistance(player, distance)
	local userId = tostring(player.UserId)
	local achievements = playerAchievements[userId]
	
	if achievements then
		achievements.totalDistanceTraveled = achievements.totalDistanceTraveled + distance
		achievements.sessionDistanceTraveled = achievements.sessionDistanceTraveled + distance
		
		-- Update longest single trip
		if achievements.sessionDistanceTraveled > achievements.longestSingleTrip then
			achievements.longestSingleTrip = achievements.sessionDistanceTraveled
		end
		
		print("📊 Distance tracked:", player.Name, "+", math.floor(distance), "studs | Total:", math.floor(achievements.totalDistanceTraveled), "| Session:", math.floor(achievements.sessionDistanceTraveled))
	else
		warn("⚠️ No achievement data found for", player.Name, "when tracking distance")
	end
end

-- Increment fuel consumed
local function IncrementFuelConsumed(player, fuelAmount)
	local userId = tostring(player.UserId)
	local achievements = playerAchievements[userId]
	
	if achievements then
		achievements.totalFuelConsumed = achievements.totalFuelConsumed + fuelAmount
		-- print("⛽ Fuel tracked:", player.Name, "+", math.floor(fuelAmount * 100) / 100, "| Total:", math.floor(achievements.totalFuelConsumed * 100) / 100)
	else
		-- warn("⚠️ No achievement data found for", player.Name, "when tracking fuel")
	end
end

-- Increment jobs completed
local function IncrementJobsCompleted(player, cargoType)
	local userId = tostring(player.UserId)
	local achievements = playerAchievements[userId]
	
	if achievements then
		achievements.totalJobsCompleted = achievements.totalJobsCompleted + 1
		
		-- Track first job completion time
		if not achievements.firstJobCompletedTime then
			achievements.firstJobCompletedTime = os.time()
		end
		
		-- Track by cargo type
		if cargoType then
			if not achievements.jobsByType[cargoType] then
				achievements.jobsByType[cargoType] = 0
			end
			achievements.jobsByType[cargoType] = achievements.jobsByType[cargoType] + 1
		end
		
		-- Reset session distance (for longest trip tracking)
		achievements.sessionDistanceTraveled = 0
	end
end

-- Increment money earned (separate from current money balance)
local function IncrementMoneyEarned(player, amount)
	local userId = tostring(player.UserId)
	local achievements = playerAchievements[userId]
	
	if achievements then
		achievements.totalMoneyEarned = achievements.totalMoneyEarned + amount
	end
end

-- Increment upgrades purchased
local function IncrementUpgradesPurchased(player)
	local userId = tostring(player.UserId)
	local achievements = playerAchievements[userId]
	
	if achievements then
		achievements.totalUpgradesPurchased = achievements.totalUpgradesPurchased + 1
	end
end

-- Get player achievements
local function GetPlayerAchievements(player)
	local userId = tostring(player.UserId)
	return playerAchievements[userId]
end

-- ==================== PLAYER EVENTS ==================== --

Players.PlayerAdded:Connect(initializePlayerAchievements)

-- Initialize players who are already in the game (important for Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	print("🔄 Initializing achievements for player already in game:", player.Name)
	initializePlayerAchievements(player)
end

-- Save on player leaving
Players.PlayerRemoving:Connect(function(player)
	print("👋 Player leaving, saving achievements for", player.Name)
	savePlayerAchievements(player)
	
	-- Clean up
	local userId = tostring(player.UserId)
	playerAchievements[userId] = nil
end)

-- Auto-save (10 seconds in Studio, 60 in production)
coroutine.wrap(function()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerAchievements(player)
		end
	end
end)()

-- Bind to game close to save all player data (important for Studio testing)
game:BindToClose(function()
	print("🛑 Game closing - saving all achievement data...")
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerAchievements(player)
	end
	-- Give time for saves to complete
	if IS_STUDIO then
		print("⏳ Waiting 2 seconds for achievement saves to complete...")
		task.wait(2)
		print("✅ Achievement save complete, safe to close")
	else
		task.wait(5)  -- More time in production
	end
end)

-- Handle achievement requests from clients
achievementEvent.OnServerEvent:Connect(function(player, action, data)
	if action == "getAchievements" then
		local achievements = GetPlayerAchievements(player)
		if achievements then
			achievementEvent:FireClient(player, "achievementData", achievements)
		end
	elseif action == "manualSave" then
		-- Manual save for testing
		print("🔧 Manual achievement save requested for", player.Name)
		savePlayerAchievements(player)
		achievementEvent:FireClient(player, "saveComplete", {success = true})
	elseif action == "reportDistance" then
		-- Client reporting distance traveled
		if data and type(data) == "number" and data > 0 then
			IncrementDistance(player, data)
		end
	elseif action == "reportFuelConsumed" then
		-- Client reporting fuel consumed
		if data and type(data) == "number" and data > 0 then
			IncrementFuelConsumed(player, data)
		end
	end
end)

-- Export functions for other scripts
return {
	IncrementDistance = IncrementDistance,
	IncrementFuelConsumed = IncrementFuelConsumed,
	IncrementJobsCompleted = IncrementJobsCompleted,
	IncrementMoneyEarned = IncrementMoneyEarned,
	IncrementUpgradesPurchased = IncrementUpgradesPurchased,
	GetPlayerAchievements = GetPlayerAchievements,
	savePlayerAchievements = savePlayerAchievements
}
