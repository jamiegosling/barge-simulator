-- BoatScript.lua (Refactored)
-- Main boat controller - orchestrates all boat systems

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Import boat modules
local BoatPhysics = require(ReplicatedStorage.Shared.Modules.Boat.BoatPhysics)
local BoatFuel = require(ReplicatedStorage.Shared.Modules.Boat.BoatFuel)
local BoatCargo = require(ReplicatedStorage.Shared.Modules.Boat.BoatCargo)
local BoatHUD = require(ReplicatedStorage.Shared.Modules.Boat.BoatHUD)
local BoatAudio = require(ReplicatedStorage.Shared.Modules.Boat.BoatAudio)
local BoatControls = require(ReplicatedStorage.Shared.Modules.Boat.BoatControls)

-- ==================== BOAT COMPONENTS ==================== --
local Engine = script.Parent.Parent.BargeEngine.BodyThrust
local SForce = script.Parent.Parent.BargeSteer.BodyAngularVelocity
local DSeat = script.Parent
local Base = script.Parent.Parent.Barge
local boat = DSeat.Parent

-- Disable built-in HUD
DSeat.HeadsUpDisplay = false

-- ==================== CONSTANTS ==================== --
local isTouchDevice = UserInputService.TouchEnabled
BaseDensity = .1

-- ==================== INITIALIZE MODULES ==================== --

-- Initialize Physics Module
BoatPhysics.Initialize({
	Engine = Engine,
	SForce = SForce,
	DSeat = DSeat,
	Base = Base,
	script = script,
	isTouchDevice = isTouchDevice,
	baseMaxSpeed = 18000,
	SteerSpeed = 500
})

-- Initialize Fuel Module
BoatFuel.Initialize({
	boat = boat,
	script = script,
	baseMaxFuel = 200,
	baseCurrentFuel = 100
})

-- Initialize Cargo Module
BoatCargo.Initialize({
	boat = boat,
	script = script,
	baseMaxCargo = 100,
	baseCurrentCargo = 0
})

-- Initialize HUD Module
BoatHUD.Initialize({
	DSeat = DSeat
})

-- Initialize Audio Module
BoatAudio.Initialize({
	Base = Base,
	DSeat = DSeat
})

-- Initialize Controls Module
BoatControls.Initialize({
	DSeat = DSeat,
	script = script
})

-- ==================== CONNECTIONS ==================== --

-- Monitor velocity continuously
local velocityConnection = RunService.Heartbeat:Connect(function()
	-- Update on-screen control inputs
	BoatControls.UpdateControlInputs()
	
	-- Update physics and get current speed/position
	local currentSpeed, currentPosition = BoatPhysics.UpdateVelocity()
	
	-- Handle fuel consumption and distance tracking
	local fuelStateChanged = BoatFuel.ConsumeFuel(currentPosition, DSeat.Occupant ~= nil, currentSpeed)
	
	-- If fuel state changed (ran out or refueled), update throttle
	if fuelStateChanged then
		BoatPhysics.UpdateThrottle(BoatFuel.GetCurrentFuel(), function(throttle)
			BoatAudio.UpdateEngineSound(throttle)
		end)
	end
end)

-- Connect HUD updates to heartbeat
local hudConnection = RunService.Heartbeat:Connect(function()
	local currentSpeed = BoatPhysics.GetCurrentSpeed()
	local cargoValues = BoatCargo.GetValues()
	local fuelValues = BoatFuel.GetValues()
	
	BoatHUD.Update(currentSpeed, cargoValues, fuelValues)
end)

-- Show/hide HUD based on seat occupancy
local seatConnection = DSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
	print("🪑 Occupant changed to:", DSeat.Occupant and DSeat.Occupant.Name or "nil")

	if DSeat.Occupant then
		local player = Players:GetPlayerFromCharacter(DSeat.Occupant.Parent)
		if player then
			print("   Player found:", player.Name)
			
			-- Update fuel values when player sits down
			BoatFuel.Update()
			
			-- Create GUI for player
			BoatHUD.CreateGUIForPlayer(player)
			
			-- Start engine sound when player sits down
			BoatAudio.StartEngineSound()
		end
	else
		-- Destroy HUD
		BoatHUD.Destroy()
		
		-- Reset control states
		BoatControls.ResetControls()
		
		-- Stop engine sound when player gets up
		BoatAudio.StopEngineSound()
	end
end)

-- Handle seat input changes
DSeat.Changed:Connect(function(p)
	if p == "ThrottleFloat" then
		BoatPhysics.UpdateThrottle(BoatFuel.GetCurrentFuel(), function(throttle)
			BoatAudio.UpdateEngineSound(throttle)
		end)
	end
	if p == "SteerFloat" then
		BoatPhysics.UpdateSteering(BoatPhysics.GetCurrentSpeed())
	end
end)

-- Handle upgrade changes
script.ChildAdded:Connect(function(child)
	if child.Name == "SpeedMultiplier" or child.Name == "CargoMultiplier" or child.Name == "FuelMultiplier" then
		-- Update respective modules
		BoatFuel.Update()
		BoatCargo.Update()
		
		if child.Name == "SpeedMultiplier" then
			BoatPhysics.UpdateThrottle(BoatFuel.GetCurrentFuel(), function(throttle)
				BoatAudio.UpdateEngineSound(throttle)
			end)
		end
	elseif child.Name == "InitialCargo" then
		BoatCargo.Update()
	elseif child.Name == "InitialFuel" then
		BoatFuel.Update()
	end
end)

script.ChildRemoved:Connect(function(child)
	if child.Name == "SpeedMultiplier" or child.Name == "CargoMultiplier" or child.Name == "FuelMultiplier" then
		BoatFuel.Update()
		BoatCargo.Update()
		
		if child.Name == "SpeedMultiplier" then
			BoatPhysics.UpdateThrottle(BoatFuel.GetCurrentFuel(), function(throttle)
				BoatAudio.UpdateEngineSound(throttle)
			end)
		end
	end
end)

-- Cleanup on destroy
DSeat.Destroying:Connect(function()
	if velocityConnection then
		velocityConnection:Disconnect()
	end
	if hudConnection then
		hudConnection:Disconnect()
	end
	if seatConnection then
		seatConnection:Disconnect()
	end
	
	-- Clean up modules
	BoatHUD.Destroy()
	BoatAudio.Destroy()
end)