# Achievements System Guide

## Overview
The Achievements DataStore tracks player progress across multiple sessions, separate from the main upgrade/progression DataStore. This provides clean separation of concerns and allows for easy expansion of achievement types.

## Architecture

### DataStore Structure
- **DataStore Name**: `PlayerAchievements`
- **Separate from**: `BoatUpgrades` DataStore
- **Auto-save**: 10 seconds (Studio) / 60 seconds (Production)

### Tracked Statistics

| Stat | Description | Source |
|------|-------------|--------|
| `totalDistanceTraveled` | Total studs traveled across all sessions | `BoatFuel.lua` |
| `totalJobsCompleted` | Total number of jobs completed | `GameManager.server.lua` |
| `totalMoneyEarned` | Total money earned (not current balance) | `GameManager.server.lua` |
| `totalFuelConsumed` | Total fuel consumed across all sessions | `BoatFuel.lua` |
| `totalUpgradesPurchased` | Total upgrades purchased | `UpgradeManager.lua` |
| `longestSingleTrip` | Longest distance traveled in one trip | `BoatFuel.lua` |
| `sessionDistanceTraveled` | Distance in current session (resets on job completion) | `BoatFuel.lua` |
| `jobsByType` | Table tracking completions per cargo type | `GameManager.server.lua` |
| `firstJobCompletedTime` | Timestamp of first job completion | `AchievementManager.lua` |
| `lastPlayedTime` | Last time player was in game | `AchievementManager.lua` |

## File Structure

```
src/
├── server/
│   ├── AchievementManager.lua          # Main achievement system (NEW)
│   ├── GameManager.server.lua          # Modified: tracks jobs & money
│   └── UpgradeManager.lua              # Modified: tracks upgrades
└── shared/
    └── Modules/
        └── Boat/
            └── BoatFuel.lua            # Modified: tracks distance & fuel
```

## How It Works

### 1. Distance Tracking (Client → Server)
- **Client-side** (`BoatFuel.lua`): Accumulates distance traveled
- **Threshold**: Reports to server every 100 studs
- **RemoteEvent**: `AchievementEvent:FireServer("reportDistance", distance)`
- **Server-side** (`AchievementManager.lua`): Increments `totalDistanceTraveled`

### 2. Fuel Consumption Tracking (Client → Server)
- **Client-side** (`BoatFuel.lua`): Reports fuel consumed
- **RemoteEvent**: `AchievementEvent:FireServer("reportFuelConsumed", amount)`
- **Server-side** (`AchievementManager.lua`): Increments `totalFuelConsumed`

### 3. Job Completion Tracking (Server-side)
- **Location**: `GameManager.server.lua` (line 185-186)
- **Triggers**: When player delivers cargo
- **Tracks**: Total jobs completed and jobs by cargo type
- **Also tracks**: Money earned from job reward

### 4. Upgrade Purchase Tracking (Server-side)
- **Location**: `UpgradeManager.lua` (line 504-506)
- **Triggers**: When player purchases any upgrade
- **Tracks**: Total upgrades purchased

## API Reference

### Server-side Functions (AchievementManager)

```lua
-- Increment distance traveled
AchievementManager.IncrementDistance(player, distance)

-- Increment fuel consumed
AchievementManager.IncrementFuelConsumed(player, fuelAmount)

-- Increment jobs completed (with optional cargo type)
AchievementManager.IncrementJobsCompleted(player, cargoType)

-- Increment money earned
AchievementManager.IncrementMoneyEarned(player, amount)

-- Increment upgrades purchased
AchievementManager.IncrementUpgradesPurchased(player)

-- Get player's achievement data
local achievements = AchievementManager.GetPlayerAchievements(player)

-- Manual save (for testing)
AchievementManager.savePlayerAchievements(player)
```

### Client-side RemoteEvent

```lua
local achievementEvent = ReplicatedStorage:WaitForChild("AchievementEvent")

-- Request achievement data
achievementEvent:FireServer("getAchievements")

-- Listen for response
achievementEvent.OnClientEvent:Connect(function(action, data)
    if action == "achievementData" then
        print("Total Distance:", data.totalDistanceTraveled)
        print("Total Jobs:", data.totalJobsCompleted)
        -- etc.
    end
end)

-- Manual save (testing)
achievementEvent:FireServer("manualSave")
```

## Data Persistence

### Save Triggers
1. **Auto-save**: Every 10s (Studio) / 60s (Production)
2. **Player leaving**: `Players.PlayerRemoving`
3. **Game closing**: `game:BindToClose()`
4. **Manual**: Via RemoteEvent or direct function call

### Data Merging
Uses `UpdateAsync` with merge logic to prevent race conditions:
- Takes the **maximum** value when concurrent updates occur
- Preserves `firstJobCompletedTime` (earliest timestamp)
- Updates `lastPlayedTime` on every save

## Testing

### Studio Testing
```lua
-- In command bar or test script:
local AchievementManager = require(game.ServerScriptService.AchievementManager)
local player = game.Players:GetPlayers()[1]

-- Get current achievements
local achievements = AchievementManager.GetPlayerAchievements(player)
print(achievements)

-- Manual save
AchievementManager.savePlayerAchievements(player)
```

### Client Testing
```lua
-- In LocalScript:
local achievementEvent = game.ReplicatedStorage:WaitForChild("AchievementEvent")

-- Request data
achievementEvent:FireServer("getAchievements")

-- Listen for response
achievementEvent.OnClientEvent:Connect(function(action, data)
    if action == "achievementData" then
        for key, value in pairs(data) do
            print(key, "=", value)
        end
    end
end)
```

## Future Expansion Ideas

### Additional Stats to Track
- `totalTimePlayedSeconds` - Track session duration
- `boatsOwned` - Different boat types unlocked
- `maxMoneyHeld` - Highest money balance achieved
- `perfectDeliveries` - Jobs completed without damage
- `fastestDelivery` - Shortest time to complete a job
- `totalRefuels` - Number of times refueled

### Achievement Milestones
Create achievement badges/rewards based on thresholds:
```lua
local ACHIEVEMENTS = {
    {id = "first_steps", name = "First Steps", requirement = {totalDistanceTraveled = 1000}},
    {id = "explorer", name = "Explorer", requirement = {totalDistanceTraveled = 10000}},
    {id = "job_starter", name = "Job Starter", requirement = {totalJobsCompleted = 1}},
    {id = "professional", name = "Professional", requirement = {totalJobsCompleted = 100}},
    -- etc.
}
```

### Leaderboards
Query all players' achievements to create leaderboards:
- Most distance traveled
- Most jobs completed
- Highest money earned

## Notes

- **Performance**: Distance reports are throttled to every 100 studs to minimize RemoteEvent calls
- **Fuel tracking**: Reports every fuel consumption (very frequent) - consider adding throttling if performance issues arise
- **Studio Mode**: DataStore may not be available; system gracefully handles this
- **Data Safety**: Uses `UpdateAsync` with merge logic to prevent data loss from concurrent updates
