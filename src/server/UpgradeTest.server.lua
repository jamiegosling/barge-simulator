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

local ADMIN_USER_IDS = {7825536211, 9138538712}
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
			print("Cargo Level:", data.cargoLevel or "nil")
			print("Fuel Level:", data.fuelLevel or "nil")
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
local function setPlayerData(player, speedLevel, money, currentFuel, fuelLevel, cargoLevel)
	local targetPlayer = player
	local userId = tostring(targetPlayer.UserId)
	
	local newData = {
		speedLevel = speedLevel,
		moneySpent = 0,
		money = money,
		currentFuel = currentFuel,
		fuelLevel = fuelLevel,
		cargoLevel = cargoLevel
	}
	
	local success, errorMessage = pcall(function()
		upgradeDataStore:SetAsync(userId, newData)
	end)
	
	if success then
		print("Updated DataStore for " .. targetPlayer.Name .. ":")
		print("  Speed Level:", speedLevel)
		print("  Money:", money)
		if currentFuel ~= nil then print("  Current Fuel:", currentFuel) end
		if fuelLevel ~= nil then print("  Fuel Level:", fuelLevel) end
		if cargoLevel ~= nil then print("  Cargo Level:", cargoLevel) end
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

-- Debug function to force save current data
local function forceSaveData(player)
	local userId = tostring(player.UserId)
	local upgrades = require(script.Parent:WaitForChild("UpgradeManager")).getPlayerUpgrades(player)
	
	if not upgrades then
		print("No upgrade data found to save")
		return
	end
	
	-- Get current money from leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild("Money")
		if money then
			upgrades.money = money.Value
		end
	end
	
	local success, errorMessage = pcall(function()
		upgradeDataStore:SetAsync(userId, upgrades)
	end)
	
	if success then
		print("Force saved data for " .. player.Name .. ":")
		print("  Speed Level:", upgrades.speedLevel)
		print("  Money:", upgrades.money)
	else
		print("Failed to force save:", errorMessage)
	end
end

-- Debug function to toggle auto-save
local function toggleAutoSave(player)
	local UpgradeManager = require(script.Parent:WaitForChild("UpgradeManager"))
	local currentStatus = not UpgradeManager.isPlayerAutoSaveDisabled(player)
	local newStatus = not currentStatus
	UpgradeManager.setPlayerAutoSave(player, newStatus)
	print("Auto-save is now", newStatus and "ENABLED" or "DISABLED", "for", player.Name)
	if not newStatus then
		print("Warning: Your data will not be saved on leave. Use /forcesave to save manually.")
	end
end

-- Command for testing (admins only)
local function processCommand(player, command)
	if not (player.UserId == game.CreatorId or (TEST_USER_ID > 0 and player.UserId == TEST_USER_ID) or table.find(ADMIN_USER_IDS, player.UserId)) then
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
		-- Accept: /setdata speedLevel money [currentFuel] [fuelLevel] [cargoLevel]
		local numbers = {}
		for num in params:gmatch("%d+") do
			table.insert(numbers, tonumber(num))
		end
		local speedLevel = numbers[1]
		local money = numbers[2]
		local currentFuel = numbers[3]
		local fuelLevel = numbers[4]
		local cargoLevel = numbers[5]
		if speedLevel and money then
			setPlayerData(player, speedLevel, money, currentFuel, fuelLevel, cargoLevel)
		else
			print("Usage: /setdata [speedLevel] [money] [currentFuel?] [fuelLevel?] [cargoLevel?]")
		end
	elseif command == "/cleardata" then
		clearPlayerData(player)
	elseif command == "/viewkeys" then
		viewAllKeys()
	elseif command == "/forcesave" then
		forceSaveData(player)
	elseif command == "/autosave" then
		toggleAutoSave(player)
	elseif command == "/help" then
		print("=== Debug Commands ===")
		print("/add [amount] - Add test money")
		print("/testupgrades - View current upgrade stats")
		print("/viewdata - View DataStore data")
		print("/setdata [speedLevel] [money] [currentFuel?] [fuelLevel?] [cargoLevel?] - Set DataStore values")
		print("/cleardata - Clear DataStore data")
		print("/viewkeys - View all DataStore keys")
		print("/forcesave - Force save current data")
		print("/autosave - Toggle auto-save on/off (player-specific)")
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
	
	if player.UserId == game.CreatorId or (TEST_USER_ID > 0 and player.UserId == TEST_USER_ID) or table.find(ADMIN_USER_IDS, player.UserId) then -- Game creator, test user, or admin
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
