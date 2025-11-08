-- Force Save Utility for Studio Testing
-- This script adds a command to manually trigger saves for testing

local Players = game:GetService("Players")
local UpgradeManager = require(script.Parent:WaitForChild("UpgradeManager"))

-- Command to force save for all players
-- Usage in Studio Command Bar: game.ReplicatedStorage.ForceSaveAll:Fire()
local forceSaveAllEvent = Instance.new("BindableEvent")
forceSaveAllEvent.Name = "ForceSaveAll"
forceSaveAllEvent.Parent = game.ReplicatedStorage

forceSaveAllEvent.Event:Connect(function()
	print("🔧 FORCE SAVE: Saving all players...")
	for _, player in ipairs(Players:GetPlayers()) do
		UpgradeManager.savePlayerUpgrades(player)
	end
	print("✅ FORCE SAVE: Complete!")
end)

-- Command to force save for specific player
-- Usage: game.ReplicatedStorage.ForceSavePlayer:Fire(game.Players.YourUsername)
local forceSavePlayerEvent = Instance.new("BindableEvent")
forceSavePlayerEvent.Name = "ForceSavePlayer"
forceSavePlayerEvent.Parent = game.ReplicatedStorage

forceSavePlayerEvent.Event:Connect(function(player)
	if player and player:IsA("Player") then
		print("🔧 FORCE SAVE: Saving", player.Name)
		UpgradeManager.savePlayerUpgrades(player)
		print("✅ FORCE SAVE: Complete for", player.Name)
	else
		warn("Invalid player passed to ForceSavePlayer")
	end
end)

print("✅ Force Save utility loaded!")
print("   - Use: game.ReplicatedStorage.ForceSaveAll:Fire()")
print("   - Use: game.ReplicatedStorage.ForceSavePlayer:Fire(game.Players.YourUsername)")
