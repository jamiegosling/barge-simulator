-- AchievementClient.client.lua
-- Example client script for querying and displaying player achievements

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local achievementEvent = ReplicatedStorage:WaitForChild("AchievementEvent")

-- Store achievement data locally
local achievementData = nil

-- Request achievement data from server
local function requestAchievements()
	achievementEvent:FireServer("getAchievements")
end

-- Listen for achievement data from server
achievementEvent.OnClientEvent:Connect(function(action, data)
	if action == "achievementData" then
		achievementData = data
		print("🏆 Achievement Data Received:")
		print("  Total Distance Traveled:", math.floor(data.totalDistanceTraveled), "studs")
		print("  Total Jobs Completed:", data.totalJobsCompleted)
		print("  Total Money Earned: £" .. data.totalMoneyEarned)
		print("  Total Fuel Consumed:", math.floor(data.totalFuelConsumed))
		print("  Total Upgrades Purchased:", data.totalUpgradesPurchased)
		print("  Longest Single Trip:", math.floor(data.longestSingleTrip), "studs")
		
		-- Print jobs by type
		if data.jobsByType and next(data.jobsByType) then
			print("  Jobs by Type:")
			for cargoType, count in pairs(data.jobsByType) do
				print("    -", cargoType .. ":", count)
			end
		end
	elseif action == "saveComplete" then
		print("✅ Manual achievement save completed")
	end
end)

-- Request achievements when player joins
task.wait(2)  -- Wait for server to initialize
requestAchievements()

-- Example: Request achievements every 30 seconds to keep UI updated
task.spawn(function()
	while true do
		task.wait(30)
		requestAchievements()
	end
end)

-- Example: Manual save command (for testing)
-- You can call this from a GUI button or command
local function manualSave()
	achievementEvent:FireServer("manualSave")
end

-- Export functions for use in other scripts
return {
	requestAchievements = requestAchievements,
	manualSave = manualSave,
	getAchievementData = function()
		return achievementData
	end
}
