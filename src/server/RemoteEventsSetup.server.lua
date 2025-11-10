-- RemoteEventsSetup Server Script
-- Ensures all required RemoteEvents exist in ReplicatedStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- List of required RemoteEvents
local requiredRemoteEvents = {
	"JobPicked",
	"JobStatus",
	"JobMessage",
	"UpdateJobDestination", -- New RemoteEvent for job guideline
	"CancelJob" -- RemoteEvent for job cancellation
}

-- Create RemoteEvents if they don't exist
for _, eventName in ipairs(requiredRemoteEvents) do
	local existingEvent = ReplicatedStorage:FindFirstChild(eventName)
	if not existingEvent then
		local newEvent = Instance.new("RemoteEvent")
		newEvent.Name = eventName
		newEvent.Parent = ReplicatedStorage
		print("Created RemoteEvent:", eventName)
	else
		print("RemoteEvent already exists:", eventName)
	end
end

print("RemoteEventsSetup complete")
