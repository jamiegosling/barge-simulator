-- JobGuideline Client Script
-- Creates a Roblox-style guideline beam to guide players to their job destinations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Wait for RemoteEvents
local JobStatus = ReplicatedStorage:WaitForChild("JobStatus")
local UpdateJobDestination = ReplicatedStorage:WaitForChild("UpdateJobDestination")

-- Guideline state
local currentGuideline = nil
local currentDestinationPart = nil
local currentAttachment0 = nil
local currentAttachment1 = nil
local isGuidelineActive = false

-- Colors for different states
local PICKUP_COLOR = Color3.fromRGB(255, 200, 50) -- Yellow/Gold for pickup
local DELIVERY_COLOR = Color3.fromRGB(50, 255, 100) -- Green for delivery

-- Create guideline beam from player to destination
local function createGuideline(destinationPosition, isPickup)
	-- Clean up existing guideline
	if currentGuideline then
		currentGuideline:Destroy()
		currentGuideline = nil
	end
	if currentAttachment0 then
		currentAttachment0:Destroy()
		currentAttachment0 = nil
	end
	if currentAttachment1 then
		currentAttachment1:Destroy()
		currentAttachment1 = nil
	end
	if currentDestinationPart then
		currentDestinationPart:Destroy()
		currentDestinationPart = nil
	end
	
	-- Create attachment on player
	currentAttachment0 = Instance.new("Attachment")
	currentAttachment0.Name = "GuidelineStart"
	currentAttachment0.Parent = humanoidRootPart
	
	-- Create invisible destination part for the beam endpoint
	currentDestinationPart = Instance.new("Part")
	currentDestinationPart.Name = "GuidelineDestination"
	currentDestinationPart.Size = Vector3.new(1, 1, 1)
	currentDestinationPart.Position = destinationPosition
	currentDestinationPart.Anchored = true
	currentDestinationPart.CanCollide = false
	currentDestinationPart.Transparency = 1
	currentDestinationPart.Parent = workspace
	
	-- Create attachment on destination
	currentAttachment1 = Instance.new("Attachment")
	currentAttachment1.Name = "GuidelineEnd"
	currentAttachment1.Parent = currentDestinationPart
	
	-- Create the beam
	currentGuideline = Instance.new("Beam")
	currentGuideline.Name = "JobGuideline"
	currentGuideline.Attachment0 = currentAttachment0
	currentGuideline.Attachment1 = currentAttachment1
	
	-- Beam appearance
	local beamColor = isPickup and PICKUP_COLOR or DELIVERY_COLOR
	currentGuideline.Color = ColorSequence.new(beamColor)
	currentGuideline.Width0 = 0.5
	currentGuideline.Width1 = 0.5
	currentGuideline.FaceCamera = true
	currentGuideline.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	
	-- Add texture for a more Roblox-style look
	currentGuideline.Texture = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	currentGuideline.TextureMode = Enum.TextureMode.Wrap
	currentGuideline.TextureLength = 4
	currentGuideline.TextureSpeed = 1
	
	-- Lighting properties
	currentGuideline.LightEmission = 0.8
	currentGuideline.LightInfluence = 0.2
	
	currentGuideline.Parent = humanoidRootPart
	
	isGuidelineActive = true
	print("Guideline created to position:", destinationPosition, "IsPickup:", isPickup)
end

-- Remove guideline
local function removeGuideline()
	if currentGuideline then
		currentGuideline:Destroy()
		currentGuideline = nil
	end
	if currentAttachment0 then
		currentAttachment0:Destroy()
		currentAttachment0 = nil
	end
	if currentAttachment1 then
		currentAttachment1:Destroy()
		currentAttachment1 = nil
	end
	if currentDestinationPart then
		currentDestinationPart:Destroy()
		currentDestinationPart = nil
	end
	
	isGuidelineActive = false
	print("Guideline removed")
end

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Recreate guideline if it was active
	if isGuidelineActive and currentDestinationPart then
		local destinationPos = currentDestinationPart.Position
		local wasPickup = currentGuideline and currentGuideline.Color.Keypoints[1].Value == PICKUP_COLOR
		task.wait(0.5) -- Wait for character to fully load
		createGuideline(destinationPos, wasPickup)
	end
end)

-- Listen for job status updates
JobStatus.OnClientEvent:Connect(function(state, job)
	if state == "accepted" then
		-- Job accepted, show guideline to pickup location
		print("Job accepted, waiting for destination position...")
	elseif state == "loaded" then
		-- Cargo loaded, show guideline to delivery location
		print("Cargo loaded, waiting for delivery destination position...")
	elseif state == "completed" then
		-- Job completed, remove guideline
		removeGuideline()
	elseif state == "cancelled" then
		-- Job cancelled, remove guideline
		removeGuideline()
	end
end)

-- Listen for destination position updates
UpdateJobDestination.OnClientEvent:Connect(function(destinationPosition, isPickup)
	if destinationPosition then
		createGuideline(destinationPosition, isPickup)
	else
		removeGuideline()
	end
end)

-- Update destination part position continuously (in case zones move, though unlikely)
RunService.Heartbeat:Connect(function()
	if isGuidelineActive and currentDestinationPart and humanoidRootPart then
		-- Keep the destination part at the correct position
		-- This is mainly for visual consistency
	end
end)

print("JobGuideline client script loaded")
