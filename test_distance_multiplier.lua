-- Test script for the new distance multiplier system
-- This script helps verify that the redistributive system works as intended

local ResourceManager = require(game.ReplicatedStorage.Shared.Modules.ResourceManager)

-- Test the distance multiplier function
print("=== Distance Multiplier Test ===")
print("Testing new redistributive distance multiplier system:")

-- Get all distances from the matrix
local testDistances = {}
for from, destinations in pairs(ResourceManager.DISTANCE_MATRIX) do
	for to, dist in pairs(destinations) do
		if from ~= to then
			table.insert(testDistances, {from = from, to = to, distance = dist})
		end
	end
end

-- Sort by distance for better visualization
table.sort(testDistances, function(a, b) return a.distance < b.distance end)

-- Calculate average distance
local totalDistance = 0
for _, route in ipairs(testDistances) do
	totalDistance = totalDistance + route.distance
end
local averageDistance = totalDistance / #testDistances

print(string.format("Average distance: %.1f", averageDistance))
print("\nRoute analysis:")

-- Show multiplier for each route
for _, route in ipairs(testDistances) do
	local multiplier = ResourceManager:GetDistanceMultiplier(route.distance)
	local category = "Average"
	if multiplier > 1.1 then
		category = "Long (Bonus)"
	elseif multiplier < 0.9 then
		category = "Short (Reduced)"
	end
	
	print(string.format("%s to %s: %d units -> %.2fx multiplier (%s)", 
		route.from, route.to, route.distance, multiplier, category))
end

print("\n=== Reward Comparison Test ===")
-- Test reward calculation for a sample job
local sampleBasePrice = 600 -- Coal base price
local sampleCargoMultiplier = 1.8 -- Medium cargo

print(string.format("Sample job: Coal, Medium cargo, Base price: £%d", sampleBasePrice))

for _, route in ipairs(testDistances) do
	local distance = route.distance
	local multiplier = ResourceManager:GetDistanceMultiplier(distance)
	local oldReward = math.floor(sampleBasePrice * (1 + (distance / 10) * 0.5) * sampleCargoMultiplier)
	local newReward = math.floor(sampleBasePrice * sampleCargoMultiplier * multiplier)
	
	print(string.format("%s->%s (%d): Old: £%d | New: £%d | Change: %+.1f%%", 
		route.from, route.to, distance, oldReward, newReward, 
		((newReward - oldReward) / oldReward) * 100))
end

print("\n=== Test Complete ===")
