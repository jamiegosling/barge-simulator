-- Test script for boat upgrade system
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Wait for services to be ready
local UpgradeManager = require(script.Parent:WaitForChild("UpgradeManager"))

-- Create RemoteEvent for debug commands
local debugEvent = Instance.new("RemoteEvent")
debugEvent.Name = "DebugCommandEvent"
debugEvent.Parent = ReplicatedStorage

-- DataStore for debugging
local upgradeDataStore = DataStoreService:GetDataStore("BoatUpgrades")

-- Add your UserId here for testing (replace with your actual UserId)
local TEST_USER_ID = 0 -- Set to your UserId if game.CreatorId doesn't work

-- Test function to give players money for testing
local function addTestMoney(player, amount)
	local money = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if money then
		money.Value += amount
		print("Added £" .. amount .. " to " .. player.Name .. " for testing")
	end
end

-- Debug function to view player DataStore data
local function viewPlayerData(player)
	local targetPlayer = player
	local userId = tostring(targetPlayer.UserId)
	
	local success, data = pcall(function()
		return upgradeDataStore:GetAsync(userId)
	end)
	
	if success then
		print("=== DataStore Data for " .. targetPlayer.Name .. " ===")
		if data then
			print("Speed Level:", data.speedLevel or "nil")
			print("Money Spent:", data.moneySpent or "nil")
			print("Money:", data.money or "nil")
			print("Raw Data:", data)
		else
			print("No data found in DataStore")
		end
		print("=====================================")
	else
		print("Failed to read DataStore:", data)
	end
end

-- Debug function to modify player DataStore data
local function setPlayerData(player, speedLevel, money)
	local targetPlayer = player
	local userId = tostring(targetPlayer.UserId)
	
	local newData = {
		speedLevel = speedLevel,
		moneySpent = 0,
		money = money
	}
	
	local success, errorMessage = pcall(function()
		upgradeDataStore:SetAsync(userId, newData)
	end)
	
	if success then
		print("Updated DataStore for " .. targetPlayer.Name .. ":")
		print("  Speed Level:", speedLevel)
		print("  Money:", money)
		print("Player must rejoin for changes to take effect.")
	else
		print("Failed to update DataStore:", errorMessage)
	end
end

-- Debug function to clear player DataStore data
local function clearPlayerData(player)
	local targetPlayer = player
	local userId = tostring(targetPlayer.UserId)
	
	local success, errorMessage = pcall(function()
		upgradeDataStore:RemoveAsync(userId)
	end)
	
	if success then
		print("Cleared DataStore for " .. targetPlayer.Name)
		print("Player must rejoin for changes to take effect.")
	else
		print("Failed to clear DataStore:", errorMessage)
	end
end

-- Debug function to view all DataStore keys (limited)
local function viewAllKeys()
	local success, pages = pcall(function()
		return upgradeDataStore:ListKeysAsync()
	end)
	
	if success then
		print("=== DataStore Keys ===")
		local count = 0
		while true do
			local items = pages:GetCurrentPage()
			for _, item in ipairs(items) do
				count += 1
				print("Key " .. count .. ":", item.KeyName)
				if count >= 10 then -- Limit to prevent spam
					print("... (showing first 10 keys)")
					break
				end
			end
			if pages.IsFinished or count >= 10 then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
		print("Total keys found:", count)
		print("====================")
	else
		print("Failed to list DataStore keys:", pages)
	end
end

-- Command for testing (admins only)
local function processCommand(player, command)
	if not (player.UserId == game.CreatorId or (TEST_USER_ID > 0 and player.UserId == TEST_USER_ID)) then
		return -- Not authorized
	end
	
	print("Processing command:", command, "from", player.Name)
	
	if command:sub(1, 4) == "/add" then
		local amount = tonumber(command:sub(6))
		if amount then
			addTestMoney(player, amount)
		end
	elseif command == "/testupgrades" then
		print("=== Upgrade System Test ===")
		local upgrades = UpgradeManager.getPlayerUpgrades(player)
		if upgrades then
			print("Player upgrades:", upgrades.speedLevel, "speed level")
			print("Speed multiplier:", UpgradeManager.getSpeedMultiplier(player))
		else
			print("No upgrade data found")
		end
	elseif command == "/viewdata" then
		viewPlayerData(player)
	elseif command:sub(1, 9) == "/setdata " then
		local params = command:sub(10)
		local speedLevel, money = params:match("(%d+)%s+(%d+)")
		if speedLevel and money then
			setPlayerData(player, tonumber(speedLevel), tonumber(money))
		else
			print("Usage: /setdata [speedLevel] [money]")
		end
	elseif command == "/cleardata" then
		clearPlayerData(player)
	elseif command == "/viewkeys" then
		viewAllKeys()
	elseif command == "/help" then
		print("=== Debug Commands ===")
		print("/add [amount] - Add test money")
		print("/testupgrades - View current upgrade stats")
		print("/viewdata - View DataStore data")
		print("/setdata [speedLevel] [money] - Set DataStore values")
		print("/cleardata - Clear DataStore data")
		print("/viewkeys - View all DataStore keys")
		print("/help - Show this help")
	else
		print("Unknown command. Type /help for available commands.")
	end
end

-- Handle RemoteEvent commands
debugEvent.OnServerEvent:Connect(function(player, command)
	processCommand(player, command)
end)

-- Keep chat commands as backup (but they might not work due to chat filtering)
Players.PlayerAdded:Connect(function(player)
	print("Player joined:", player.Name, "UserId:", player.UserId)
	print("Game CreatorId:", game.CreatorId)
	print("Test UserId:", TEST_USER_ID)
	print("Is creator?", player.UserId == game.CreatorId)
	print("Is test user?", player.UserId == TEST_USER_ID)
	
	if player.UserId == game.CreatorId or (TEST_USER_ID > 0 and player.UserId == TEST_USER_ID) then -- Game creator or test user
		print("Upgrade system test script loaded. Creator can use commands.")
		print("Use RemoteEvent: game.ReplicatedStorage.DebugCommandEvent:FireServer('/viewdata')")
		
		player.Chatted:Connect(function(message)
			print("Chat received:", message)
			processCommand(player, message)
		end)
	else
		print("Player is not game creator. Debug commands disabled.")
	end
end)

print("Upgrade test script initialized")
