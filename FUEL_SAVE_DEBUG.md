# Fuel Saving Flow - Debug Guide

## How Fuel Saving Works (After Refactor)

### 1. **Boat Spawns** (`BoatSpawner.server.lua`)
- Boat is cloned and placed in workspace
- `BoatScript.lua` runs immediately in the VehicleSeat

### 2. **BoatFuel Module Initializes** (`BoatFuel.lua`)
- Creates `FuelAmount` NumberValue on the boat
- Sets initial value to default (100) or from `InitialFuel` in script
- Connects to `FuelAmount.Changed` event

### 3. **UpgradeManager Sets Saved Fuel** (`UpgradeManager.lua`)
- `setInitialFuel()` is called by BoatSpawner
- Creates `InitialFuel` NumberValue in BoatScript
- **Updates `FuelAmount` on boat** with saved value from DataStore
- This triggers the `.Changed` event in BoatFuel module

### 4. **Fuel Consumption** (`BoatFuel.ConsumeFuel()`)
- Called every frame from main BoatScript heartbeat loop
- Calculates distance traveled
- Reduces `currentFuel` based on distance
- **Updates `FuelAmount.Value` on the boat**
- Also updates `InitialFuel` in script

### 5. **Fuel Monitoring** (`BoatSpawner.server.lua`)
- Checks `FuelAmount` every 5 seconds
- If changed, calls `UpgradeManager.updatePlayerFuel()`
- Updates in-memory `playerUpgrades` table

### 6. **Player Leaves** (`BoatSpawner.server.lua`)
- `destroyBoatForPlayer()` is called
- Gets final `FuelAmount.Value` from boat
- Calls `updatePlayerFuel()` one last time
- Calls `savePlayerUpgrades()` to write to DataStore

### 7. **Auto-Save** (`UpgradeManager.lua`)
- Runs every 10 seconds (Studio) or 60 seconds (production)
- Saves all player data including fuel

## Debug Output to Watch For

When testing, you should see these messages in order:

```
⛽ Created FuelAmount on boat with value: 100
⛽ Initial fuel set from InitialFuel: 150
Found upgrades data, currentFuel: 150
Updated boat FuelAmount to: 150
⛽ FuelAmount changed externally to: 150
⛽ BoatSpawner: Starting fuel monitoring for Player initial value: 150
⛽ BoatSpawner: Fuel changed for Player from 150 to 145
⛽ UpgradeManager: Updated fuel for Player from 150 to 145
⛽ BoatSpawner: Saving fuel for Player before boat destruction: 140
⛽ UpgradeManager: Updated fuel for Player from 145 to 140
✅ Saved upgrades and money for Player - Current Fuel: 140
```

## Common Issues

### Issue: "No FuelAmount found on boat"
**Cause:** BoatScript hasn't initialized yet when BoatSpawner checks
**Fix:** Added `task.wait(0.5)` before checking for FuelAmount

### Issue: Fuel not saving on player leave
**Cause:** Boat destroyed before fuel value read
**Fix:** `destroyBoatForPlayer()` reads fuel BEFORE destroying boat

### Issue: Fuel resets to default on rejoin
**Cause:** `setInitialFuel()` not being called or upgrades data not loaded
**Fix:** BoatSpawner waits for `upgradeDataLoaded.Event` before applying upgrades

## Testing Checklist

1. ✅ Join game - check initial fuel matches saved value
2. ✅ Drive boat - watch fuel decrease
3. ✅ Wait 5 seconds - check monitoring detects change
4. ✅ Leave game - check final fuel is saved
5. ✅ Rejoin - verify fuel persisted correctly
