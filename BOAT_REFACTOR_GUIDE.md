# BoatScript Refactoring Guide

## Summary

Successfully refactored `BoatScript.lua` from **738 lines** to **196 lines** (73% reduction) by splitting it into modular components.

## What Gets Spawned?

**The `Barge` model from `ReplicatedStorage.BoatTemplates` is what gets spawned.** This is the physical boat model (the 3D geometry, parts, VehicleSeat, etc.).

### The Boat Modules Are NOT Models

The modules in `src/shared/Modules/Boat/` are **code modules**, not boat models. They contain the logic that controls the boat.

### How They Work Together

1. **BoatSpawner clones the Barge model** from `ReplicatedStorage.BoatTemplates`
2. **The cloned boat contains a VehicleSeat** with `BoatScript.lua` inside it
3. **BoatScript.lua requires the modules** and uses them to control the boat
4. **The modules operate on the physical boat parts** (Engine, SForce, DSeat, Base, etc.)

### The Flow

```
Barge Model (in ReplicatedStorage.BoatTemplates)
  └─ VehicleSeat
      └─ BoatScript.lua (LocalScript)
          ├─ requires BoatPhysics module → controls Engine/SForce
          ├─ requires BoatFuel module → manages fuel consumption
          ├─ requires BoatCargo module → tracks cargo
          ├─ requires BoatHUD module → creates GUI
          ├─ requires BoatAudio module → plays sounds
          └─ requires BoatControls module → handles input
```

**The Barge model is the boat, and the modules are the brains that control it.**

## New Module Structure

```
src/shared/Modules/Boat/
├── BoatPhysics.lua    - Movement, steering, throttle control
├── BoatFuel.lua       - Fuel consumption & distance tracking
├── BoatCargo.lua      - Cargo capacity management
├── BoatHUD.lua        - GUI creation and updates
├── BoatAudio.lua      - Engine sound management
└── BoatControls.lua   - Input handling (touch & keyboard)
```

## Module Responsibilities

### 1. **BoatPhysics.lua** (~140 lines)
- Steering calculations
- Throttle control
- Speed multipliers
- Input smoothing (touch controls)
- Velocity updates

**Key Functions:**
- `Initialize(config)` - Set up physics system
- `UpdateSteering(speed)` - Handle steering logic
- `UpdateThrottle(currentFuel, onEngineUpdate)` - Handle throttle
- `UpdateVelocity()` - Returns current speed and position
- `GetCurrentSpeed()` - Get current boat speed

### 2. **BoatFuel.lua** (~160 lines)
- Fuel consumption based on distance
- **Distance tracking** (totalDistanceTraveled)
- Fuel capacity calculations
- Fuel purchase detection

**Key Functions:**
- `Initialize(config)` - Set up fuel system
- `ConsumeFuel(position, isOccupied, speed)` - Track distance & consume fuel
- `GetTotalDistance()` - **Get total studs traveled**
- `GetCurrentFuel()` / `GetMaxFuel()` - Fuel values
- `Update()` - Refresh fuel values from upgrades

### 3. **BoatCargo.lua** (~95 lines)
- Cargo capacity management
- Cargo multiplier handling

**Key Functions:**
- `Initialize(config)` - Set up cargo system
- `Update()` - Refresh cargo values
- `GetValues()` - Get current/max cargo

### 4. **BoatHUD.lua** (~165 lines)
- GUI creation for players
- Speed/cargo/fuel display
- HUD updates

**Key Functions:**
- `Initialize(config)` - Set up HUD system
- `CreateGUIForPlayer(player)` - Create boat HUD
- `Update(speed, cargoValues, fuelValues)` - Update displays
- `Destroy()` - Clean up GUI

### 5. **BoatAudio.lua** (~80 lines)
- Engine sound initialization
- Dynamic pitch based on throttle
- Sound start/stop

**Key Functions:**
- `Initialize(config)` - Set up audio system
- `StartEngineSound()` / `StopEngineSound()` - Control engine
- `UpdateEngineSound(throttle)` - Adjust pitch

### 6. **BoatControls.lua** (~90 lines)
- On-screen touch controls
- Keyboard/gamepad input
- Control state management

**Key Functions:**
- `Initialize(config)` - Set up controls
- `UpdateControlInputs()` - Apply control states to seat
- `ResetControls()` - Clear control states

## Main BoatScript.lua (196 lines)

Now acts as an orchestrator that:
1. Imports all modules
2. Initializes each system
3. Connects heartbeat loops
4. Handles seat occupancy events
5. Manages upgrade changes

## Benefits

✅ **Maintainability** - Each system is isolated and easier to debug
✅ **Reusability** - Modules can be used in other boat types
✅ **Testability** - Individual systems can be tested separately
✅ **Readability** - Clear separation of concerns
✅ **Extensibility** - Easy to add new features (like stats tracking!)

## Distance Tracking Integration

The `BoatFuel` module already tracks distance traveled:

```lua
-- Get total distance traveled by a boat
local totalDistance = BoatFuel.GetTotalDistance()
```

This makes it easy to:
- Save distance to DataStore when player leaves
- Track distance per session
- Award achievements for distance milestones
- Calculate fuel efficiency

## Next Steps for Stats Tracking

Now that the code is modular, you can easily:

1. **Create StatsManager.lua** - Track jobs completed & distance
2. **Hook into BoatFuel.GetTotalDistance()** - Save distance on player leave
3. **Hook into GameManager job completion** - Increment job counter
4. **Add milestone rewards** - Check thresholds and award bonuses

The modular structure makes these additions much cleaner!
