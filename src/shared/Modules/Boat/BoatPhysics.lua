-- BoatPhysics.lua
-- Handles boat movement, steering, and throttle control

local BoatPhysics = {}

-- ==================== CONSTANTS ==================== --
local MIN_STEER_SPEED = 1

-- ==================== MODULE STATE ==================== --
local currentSpeed = 0
local movementDirection = 0
local smoothedSteerFloat = 0
local smoothedThrottleFloat = 0

-- ==================== HELPER FUNCTIONS ==================== --

-- Function to smooth input values for better touch control
local function smoothInput(rawValue, smoothedValue, smoothingFactor)
	return smoothedValue + (rawValue - smoothedValue) * smoothingFactor
end

-- Function to apply dead zone to input
local function applyDeadZone(value, deadZone)
	if math.abs(value) < deadZone then
		return 0
	end
	return value
end

-- ==================== PUBLIC FUNCTIONS ==================== --

function BoatPhysics.Initialize(config)
	-- Config contains: Engine, SForce, DSeat, Base, script, isTouchDevice
	BoatPhysics.Engine = config.Engine
	BoatPhysics.SForce = config.SForce
	BoatPhysics.DSeat = config.DSeat
	BoatPhysics.Base = config.Base
	BoatPhysics.script = config.script
	
	-- Touch control settings
	local isTouchDevice = config.isTouchDevice or false
	BoatPhysics.steeringSmoothingFactor = isTouchDevice and 0.1 or 1.0
	BoatPhysics.throttleSmoothingFactor = isTouchDevice and 0.2 or 1.0
	BoatPhysics.touchSteerDeadZone = isTouchDevice and 0.1 or 0.01
	BoatPhysics.touchThrottleDeadZone = isTouchDevice and 0.08 or 0.01
	
	-- Speed settings
	BoatPhysics.baseMaxSpeed = config.baseMaxSpeed or 18000
	BoatPhysics.maxSpeed = BoatPhysics.baseMaxSpeed
	BoatPhysics.SteerSpeed = config.SteerSpeed or 500
end

function BoatPhysics.UpdateSteering(speed)
	local angularVelocity = Vector3.new(0, 0, 0)

	-- Apply dead zone and smoothing to steering input
	local rawSteer = BoatPhysics.DSeat.SteerFloat
	local deadZoneSteer = applyDeadZone(rawSteer, BoatPhysics.touchSteerDeadZone)
	smoothedSteerFloat = smoothInput(deadZoneSteer, smoothedSteerFloat, BoatPhysics.steeringSmoothingFactor)

	if movementDirection ~= 0 and math.abs(smoothedSteerFloat) > 0.01 then
		-- Quadratic curve - steering grows faster at higher speeds
		local speedFactor = math.min((math.abs(speed) / 50) ^ 2, 1)
		local adjustedSteerSpeed = BoatPhysics.SteerSpeed * speedFactor

		angularVelocity = Vector3.new(0, -adjustedSteerSpeed * smoothedSteerFloat * movementDirection, 0)
	end

	BoatPhysics.SForce.AngularVelocity = angularVelocity
end

function BoatPhysics.UpdateThrottle(currentFuel, onEngineUpdate)
	-- Update max speed from multiplier if it exists
	local currentMultiplier = BoatPhysics.script:FindFirstChild("SpeedMultiplier")
	if currentMultiplier then
		BoatPhysics.maxSpeed = BoatPhysics.baseMaxSpeed * currentMultiplier.Value
	else
		BoatPhysics.maxSpeed = BoatPhysics.baseMaxSpeed
	end

	-- Reduce speed if fuel is empty
	local effectiveMaxSpeed = BoatPhysics.maxSpeed
	if currentFuel <= 0 then
		effectiveMaxSpeed = BoatPhysics.baseMaxSpeed * 0.75
	end

	-- Apply dead zone and smoothing to throttle input
	local rawThrottle = BoatPhysics.DSeat.ThrottleFloat
	local deadZoneThrottle = applyDeadZone(rawThrottle, BoatPhysics.touchThrottleDeadZone)
	smoothedThrottleFloat = smoothInput(deadZoneThrottle, smoothedThrottleFloat, BoatPhysics.throttleSmoothingFactor)

	BoatPhysics.Engine.Force = Vector3.new(0, 0, effectiveMaxSpeed * smoothedThrottleFloat)
	
	-- Notify engine sound system
	if onEngineUpdate then
		onEngineUpdate(smoothedThrottleFloat)
	end
	
	BoatPhysics.UpdateSteering(currentSpeed)
end

function BoatPhysics.UpdateVelocity()
	local partVelocity = BoatPhysics.Base.AssemblyLinearVelocity
	local relativeVelocity = BoatPhysics.Base.CFrame:VectorToObjectSpace(partVelocity)
	local forwardSpeed = relativeVelocity.X

	currentSpeed = forwardSpeed

	local newDirection = 0
	if forwardSpeed > MIN_STEER_SPEED then
		newDirection = 1
	elseif forwardSpeed < -MIN_STEER_SPEED then
		newDirection = -1
	end

	if newDirection ~= movementDirection then
		movementDirection = newDirection
		BoatPhysics.UpdateSteering(forwardSpeed)
	else
		BoatPhysics.UpdateSteering(forwardSpeed)
	end
	
	return currentSpeed, BoatPhysics.Base.Position
end

function BoatPhysics.GetCurrentSpeed()
	return currentSpeed
end

function BoatPhysics.GetSmoothedThrottle()
	return smoothedThrottleFloat
end

function BoatPhysics.UpdateMaxSpeed(newMaxSpeed)
	BoatPhysics.maxSpeed = newMaxSpeed
end

return BoatPhysics
