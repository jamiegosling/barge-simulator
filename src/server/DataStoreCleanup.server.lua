-- local Players = game:GetService("Players")
-- local DataStoreService = game:GetService("DataStoreService")
-- local RunService = game:GetService("RunService")

-- -- DataStore to clean
-- local upgradeDataStore = DataStoreService:GetDataStore("BoatUpgrades")

-- -- Your UserId (replace with your actual Roblox UserId)
-- local ADMIN_USER_ID = 0 -- Replace this with your actual UserId

-- -- Function to clean up duplicate keys for a single player
-- local function cleanupPlayerData(userId)
--     local success, data = pcall(function()
--         return upgradeDataStore:GetAsync(userId)
--     end)
    
--     if not success then
--         warn("Failed to load data for user " .. userId .. ": " .. tostring(data))
--         return false
--     end
    
--     if not data then
--         print("No data found for user " .. userId)
--         return true
--     end
    
--     local hasChanges = false
--     local oldData = {}
    
--     -- Copy original data for comparison
--     for key, value in pairs(data) do
--         oldData[key] = value
--     end
    
--     -- Handle cargo level duplicates
--     if data.cargo_capacityLevel and data.cargoLevel then
--         print("Found duplicate cargo levels for user " .. userId)
--         print("  cargo_capacityLevel:", data.cargo_capacityLevel)
--         print("  cargoLevel:", data.cargoLevel)
        
--         -- Use the higher value to preserve progress
--         if data.cargo_capacityLevel > data.cargoLevel then
--             data.cargoLevel = data.cargo_capacityLevel
--             print("  Using cargo_capacityLevel value (higher):", data.cargoLevel)
--         else
--             print("  Using cargoLevel value (higher or equal):", data.cargoLevel)
--         end
        
--         data.cargo_capacityLevel = nil
--         hasChanges = true
--     elseif data.cargo_capacityLevel and not data.cargoLevel then
--         print("Found only cargo_capacityLevel for user " .. userId .. ", migrating to cargoLevel")
--         data.cargoLevel = data.cargo_capacityLevel
--         data.cargo_capacityLevel = nil
--         hasChanges = true
--     end
    
--     -- Handle fuel level duplicates
--     if data.fuel_capacityLevel and data.fuelLevel then
--         print("Found duplicate fuel levels for user " .. userId)
--         print("  fuel_capacityLevel:", data.fuel_capacityLevel)
--         print("  fuelLevel:", data.fuelLevel)
        
--         -- Use the higher value to preserve progress
--         if data.fuel_capacityLevel > data.fuelLevel then
--             data.fuelLevel = data.fuel_capacityLevel
--             print("  Using fuel_capacityLevel value (higher):", data.fuelLevel)
--         else
--             print("  Using fuelLevel value (higher or equal):", data.fuelLevel)
--         end
        
--         data.fuel_capacityLevel = nil
--         hasChanges = true
--     elseif data.fuel_capacityLevel and not data.fuelLevel then
--         print("Found only fuel_capacityLevel for user " .. userId .. ", migrating to fuelLevel")
--         data.fuelLevel = data.fuel_capacityLevel
--         data.fuel_capacityLevel = nil
--         hasChanges = true
--     end
    
--     -- Save cleaned data if changes were made
--     if hasChanges then
--         local saveSuccess, saveError = pcall(function()
--             upgradeDataStore:SetAsync(userId, data)
--         end)
        
--         if saveSuccess then
--             print("✅ Successfully cleaned up data for user " .. userId)
--             print("  Old data keys:", table.concat(table.keys(oldData), ", "))
--             print("  New data keys:", table.concat(table.keys(data), ", "))
--             return true
--         else
--             warn("❌ Failed to save cleaned data for user " .. userId .. ": " .. tostring(saveError))
--             return false
--         end
--     else
--         print("✅ No cleanup needed for user " .. userId)
--         return true
--     end
-- end

-- -- Function to get all player keys from DataStore
-- local function getAllPlayerKeys()
--     local keys = {}
--     local success, pages = pcall(function()
--         return upgradeDataStore:ListKeysAsync()
--     end)
    
--     if not success then
--         warn("Failed to list DataStore keys: " .. tostring(pages))
--         return keys
--     end
    
--     local currentPage = pages:GetCurrentPage()
--     for _, item in ipairs(currentPage) do
--         table.insert(keys, item.KeyName)
--     end
    
--     -- Check if there are more pages
--     while pages.IsFinished == false do
--         pages:AdvanceToNextPageAsync()
--         currentPage = pages:GetCurrentPage()
--         for _, item in ipairs(currentPage) do
--             table.insert(keys, item.KeyName)
--         end
--     end
    
--     return keys
-- end

-- -- Cleanup all player data
-- local function cleanupAllData()
--     print("🧹 Starting DataStore cleanup...")
    
--     local keys = getAllPlayerKeys()
--     print("Found " .. #keys .. " player entries to check")
    
--     local cleaned = 0
--     local errors = 0
    
--     for _, userId in ipairs(keys) do
--         if cleanupPlayerData(userId) then
--             cleaned = cleaned + 1
--         else
--             errors = errors + 1
--         end
--         task.wait() -- Prevent rate limiting
--     end
    
--     print("🎉 Cleanup complete!")
--     print("  Successfully cleaned: " .. cleaned .. " entries")
--     print("  Errors: " .. errors .. " entries")
    
--     -- Remove this script after cleanup
--     script:Destroy()
-- end

-- -- Admin command to trigger cleanup
-- local function onPlayerAdded(player)
--     if player.UserId == ADMIN_USER_ID then
--         print("Admin detected. Type '/cleanupdatastore' in chat to start cleanup")
        
--         player.Chatted:Connect(function(message)
--             if message:lower() == "/cleanupdatastore" then
--                 print("Starting DataStore cleanup...")
--                 cleanupAllData()
--             end
--         end)
--     end
-- end

-- -- Auto-cleanup in Studio (safer for testing)
-- if RunService:IsStudio() then
--     print("Running in Studio - auto-starting cleanup in 5 seconds...")
--     task.wait(5)
--     cleanupAllData()
-- else
--     -- In production, require admin command
--     Players.PlayerAdded:Connect(onPlayerAdded)
--     print("DataStore cleanup script loaded. Admin must trigger with '/cleanupdatastore'")
-- end
