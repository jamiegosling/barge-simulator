# BoatScript Update Required

## Issue
`BoatScript` is a **Script** (server-side) that runs in the VehicleSeat of spawned boats. It needs to pass the player reference to `BoatFuel.Initialize()` for achievement tracking to work.

## Required Change

In `BoatScript.lua`, update the `BoatFuel.Initialize()` call to include the player:

### Current Code (needs update):
```lua
BoatFuel.Initialize({
	boat = boat,
	script = script,
	baseMaxFuel = 200,
})
```

### Updated Code:
```lua
-- Get the player who owns this boat
local player = nil
local ownerTag = boat:FindFirstChild("Owner")
if ownerTag then
	player = game:GetService("Players"):GetPlayerByUserId(tonumber(ownerTag.Value))
end

BoatFuel.Initialize({
	boat = boat,
	script = script,
	baseMaxFuel = 200,
	player = player  -- Add player reference for achievement tracking
})
```

## Why This Is Needed

`BoatFuel.lua` is a shared module that can run on both client and server:
- **Server-side** (BoatScript): Calls `AchievementManager` functions directly
- **Client-side** (if used): Uses `RemoteEvent:FireServer()` to communicate with server

Since BoatScript runs on the server, it needs the player reference to track achievements.

## Location
The BoatScript file is located in the boat template in ReplicatedStorage and is spawned by `BoatSpawner.server.lua`.
