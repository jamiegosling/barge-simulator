-- BoatControls.lua
-- Handles boat input controls (on-screen and keyboard)

local Players = game:GetService("Players")

local BoatControls = {}

-- ==================== MODULE STATE ==================== --
local isForwardPressed = false
local isBackwardPressed = false
local isLeftPressed = false
local isRightPressed = false

local controlEvent = nil

-- ==================== PUBLIC FUNCTIONS ==================== --

function BoatControls.Initialize(config)
	-- Config contains: DSeat, script
	BoatControls.DSeat = config.DSeat
	
	-- Create RemoteEvent for on-screen controls communication
	controlEvent = config.script:FindFirstChild("ControlEvent")
	if not controlEvent then
		controlEvent = Instance.new("RemoteEvent")
		controlEvent.Name = "ControlEvent"
		controlEvent.Parent = config.script
	end
	
	-- Server-side: Listen for control input from client
	controlEvent.OnServerEvent:Connect(function(player, action, pressed)
		-- Verify the player is in this boat's seat
		if BoatControls.DSeat.Occupant and Players:GetPlayerFromCharacter(BoatControls.DSeat.Occupant.Parent) == player then
			if action == "Forward" then
				isForwardPressed = pressed
				print("🎮 Server: Forward =", pressed)
			elseif action == "Backward" then
				isBackwardPressed = pressed
				print("🎮 Server: Backward =", pressed)
			elseif action == "Left" then
				isLeftPressed = pressed
				print("🎮 Server: Left =", pressed)
			elseif action == "Right" then
				isRightPressed = pressed
				print("🎮 Server: Right =", pressed)
			end
		end
	end)
end

function BoatControls.UpdateControlInputs()
	if not BoatControls.DSeat.Occupant then return end
	
	-- Only override seat controls if on-screen controls are being used
	local anyControlPressed = isForwardPressed or isBackwardPressed or isLeftPressed or isRightPressed
	if not anyControlPressed then
		return -- Let keyboard/gamepad controls work normally
	end
	
	-- Calculate throttle (forward/backward)
	local throttle = 0
	if isForwardPressed then
		throttle = throttle + 1
	end
	if isBackwardPressed then
		throttle = throttle - 1
	end
	BoatControls.DSeat.ThrottleFloat = throttle
	
	-- Calculate steer (left/right)
	local steer = 0
	if isLeftPressed then
		steer = steer - 1
	end
	if isRightPressed then
		steer = steer + 1
	end
	BoatControls.DSeat.SteerFloat = steer
end

function BoatControls.ResetControls()
	isForwardPressed = false
	isBackwardPressed = false
	isLeftPressed = false
	isRightPressed = false
end

return BoatControls
