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

Players.PlayerAdded:Connect(function(player)
	-- Clone boat
	local boat = BoatTemplate:Clone()
	boat.Name = "Boat_" .. player.Name

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
	print("Applied all upgrades to", player.Name .. "'s boat after data loaded")
end)

Players.PlayerRemoving:Connect(function(player)
	local playerBoat = BoatFolder:FindFirstChild("Boat_" .. player.Name)
	if playerBoat then
		playerBoat:Destroy()
	end
end)