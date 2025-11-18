-- AchievementInit.server.lua
-- Initializes the AchievementManager system on server startup

print("🏆 Initializing Achievement System...")

local ServerScriptService = game:GetService("ServerScriptService")
local serverFolder = script.Parent
local AchievementManager = require(serverFolder.AchievementManager)

print("✅ Achievement System initialized successfully!")
