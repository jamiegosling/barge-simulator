-- BoatAudio.lua
-- Handles boat engine sound management

local BoatAudio = {}

-- ==================== MODULE STATE ==================== --
local engineSound = nil
local isEngineRunning = false
local targetPitch = 1.0
local currentPitch = 1.0

local engineIdleSoundId = "rbxassetid://98076378627817"
local engineActiveSoundId = "rbxassetid://98076378627817"
local pitchSmoothingSpeed = 0.1

-- ==================== PUBLIC FUNCTIONS ==================== --

function BoatAudio.Initialize(config)
	-- Config contains: Base, DSeat
	BoatAudio.Base = config.Base
	BoatAudio.DSeat = config.DSeat
end

function BoatAudio.InitializeEngineSound()
	if engineSound then return end
	
	engineSound = Instance.new("Sound")
	engineSound.Name = "EngineSound"
	engineSound.SoundId = engineIdleSoundId
	engineSound.Volume = 0.3
	engineSound.Pitch = 1.0
	engineSound.Looped = true
	engineSound.Parent = BoatAudio.Base
end

function BoatAudio.StartEngineSound()
	if not engineSound then
		BoatAudio.InitializeEngineSound()
	end
	
	if not engineSound.IsPlaying and BoatAudio.DSeat.Occupant then
		engineSound:Play()
		isEngineRunning = true
	end
end

function BoatAudio.StopEngineSound()
	if engineSound and engineSound.IsPlaying then
		engineSound:Stop()
		isEngineRunning = false
	end
end

function BoatAudio.UpdateEngineSound(smoothedThrottleFloat)
	if not engineSound or not isEngineRunning then return end
	
	-- Calculate target pitch based on throttle
	local throttleAmount = math.abs(smoothedThrottleFloat)
	if throttleAmount > 0.01 then
		-- Engine speeds up when throttle is applied
		targetPitch = 1.0 + (throttleAmount * 0.3)  -- Pitch ranges from 1.0 to 1.3
	else
		-- Return to idle pitch
		targetPitch = 1.0
	end
	
	-- Smooth pitch transitions
	currentPitch = currentPitch + (targetPitch - currentPitch) * pitchSmoothingSpeed
	engineSound.Pitch = currentPitch
end

function BoatAudio.Destroy()
	if engineSound then
		engineSound:Destroy()
		engineSound = nil
	end
end

return BoatAudio
