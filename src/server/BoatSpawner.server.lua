-- ServerScriptService/BoatSpawner.lua
print("🚤 BoatSpawner script is running!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BoatTemplate = ReplicatedStorage:WaitForChild("BoatTemplates"):WaitForChild("Barge")
local BoatFolder = Instance.new("Folder")
BoatFolder.Name = "PlayerBoats"
BoatFolder.Parent = workspace

-- Import UpgradeManager
local UpgradeManager = require(script.Parent:WaitForChild("UpgradeManager"))
local upgradeDataLoaded = script.Parent:WaitForChild("UpgradeManager"):WaitForChild("UpgradeDataLoaded")

local spawnPositions = {
	Vector3.new(130, 10.341, -211.5),
	Vector3.new(140, 10.341, -201.5),
	Vector3.new(120, 10.341, -216.5),
}

local nextSpawnIndex = 1

-- Apply upgrades to a boat (generic function)
local function applyUpgrades(boat, player, upgradeType)
	UpgradeManager.updateBoatUpgrade(boat, player, upgradeType)
end

-- Apply speed upgrades to a boat (backward compatibility)
local function applySpeedUpgrades(boat, player)
	applyUpgrades(boat, player, "speed")
end

-- Spawn boat for player (extracted function)
local function spawnBoatForPlayer(player)
	-- Clone boat
	local boat = BoatTemplate:Clone()
	boat.Name = "Boat_" .. player.Name

	-- Add FuelAmount value for tracking
	local fuelAmount = Instance.new("NumberValue")
	fuelAmount.Name = "FuelAmount"
	fuelAmount.Value = 100  -- Default value, will be updated by UpgradeManager
	fuelAmount.Parent = boat

	-- Optional: Tag ownership
	local ownerTag = Instance.new("StringValue")
	ownerTag.Name = "Owner"
	ownerTag.Value = player.UserId
	ownerTag.Parent = boat

	-- Add player name label
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "PlayerLabel"
	billboardGui.Size = UDim2.new(0, 100, 0, 30)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Position above boat
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = boat

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.BorderSizePixel = 0
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = billboardGui

	-- Position boat at a dock/spawn
	local spawnPos = spawnPositions[nextSpawnIndex]
	nextSpawnIndex += 1
	if nextSpawnIndex > #spawnPositions then
		nextSpawnIndex = 1
	end

	-- Move the entire boat model
	boat:PivotTo(CFrame.new(spawnPos))

	boat.Parent = BoatFolder
	print("Spawned boat for", player.Name, "at position", spawnPos)
	
	-- Wait for upgrade data to be loaded before applying upgrades
	upgradeDataLoaded.Event:Wait()
	-- Apply all upgrades (speed, cargo, and fuel)
	applyUpgrades(boat, player, "speed")
	applyUpgrades(boat, player, "cargo_capacity")
	applyUpgrades(boat, player, "fuel_capacity")
	-- Set initial fuel from DataStore
	UpgradeManager.setInitialFuel(boat, player)
	print("Applied all upgrades to", player.Name .. "'s boat after data loaded")
	
	-- Monitor fuel changes periodically for this boat
	local fuelAmount = boat:FindFirstChild("FuelAmount")
	if fuelAmount then
		-- Track fuel changes every 5 seconds
		task.spawn(function()
			local lastFuelValue = fuelAmount.Value
			while boat.Parent and player.Parent do
				task.wait(5)
				if fuelAmount.Value ~= lastFuelValue then
					-- Fuel changed, update the tracking system
					UpgradeManager.updatePlayerFuel(player, fuelAmount.Value)
					lastFuelValue = fuelAmount.Value
				end
			end
		end)
	end
end

-- Destroy boat for player (extracted function)
local function destroyBoatForPlayer(player)
	local playerBoat = BoatFolder:FindFirstChild("Boat_" .. player.Name)
	if playerBoat then
		-- Save fuel before destroying boat
		local fuelAmount = playerBoat:FindFirstChild("FuelAmount")
		if fuelAmount then
			print("⛽ BoatSpawner: Saving fuel for", player.Name, "before boat destruction:", fuelAmount.Value)
			-- Use the new updatePlayerFuel function to track changes
			UpgradeManager.updatePlayerFuel(player, fuelAmount.Value)
		else
			print("⚠️ DEBUG: No FuelAmount found on boat for", player.Name)
		end
		playerBoat:Destroy()
		
		-- Force save to DataStore after updating fuel
		UpgradeManager.savePlayerUpgrades(player)
		print("✅ BoatSpawner: Forced save after fuel update for", player.Name)
	end
end

Players.PlayerAdded:Connect(function(player)
	-- Wait for character to load before spawning boat
	player.CharacterAdded:Connect(function(character)
		print("🚤 Character loaded for", player.Name, "- spawning boat")
		spawnBoatForPlayer(player)
	end)
	
	-- Handle character death/respawn - destroy boat when character dies
	player.CharacterRemoving:Connect(function(character)
		print("💥 Character died/respawning for", player.Name, "- destroying boat")
		destroyBoatForPlayer(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print("👋 Player leaving game:", player.Name, "- cleaning up boat")
	destroyBoatForPlayer(player)
end)