local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JobsManager = require(ReplicatedStorage.Shared.Modules.JobsManager)
local JobMessage = ReplicatedStorage:WaitForChild("JobMessage")
local JobStatus = ReplicatedStorage:WaitForChild("JobStatus")


local JobPicked = ReplicatedStorage:WaitForChild("JobPicked")
local ActiveJobs = {} -- player.UserId → job table

-- Helper function: play particle + sound effects for completed delivery
local function PlayDeliveryEffect(player, color)
	print("sparkle function")
	local character = player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
	print("Effect root:", root)
	if not root then return end

	-- 🌟 Sparkle particles (bright burst)
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxassetid://258128463" -- a bright sparkle/glow texture
	sparkles.Color = ColorSequence.new(color or Color3.fromRGB(255, 255, 150))
	sparkles.Lifetime = NumberRange.new(1.2, 1.8)
	sparkles.Rate = 0
	sparkles.Speed = NumberRange.new(2, 6)
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	sparkles.Rotation = NumberRange.new(0, 360)
	sparkles.RotSpeed = NumberRange.new(-90, 90)
	sparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.VelocitySpread = 180
	sparkles.LightInfluence = 0
	sparkles.Brightness = 4 -- 🔆 this makes them really pop
	sparkles.Parent = root

	-- Force visible burst
	sparkles:Emit(100)

	game.Debris:AddItem(sparkles, 3)
	print("end of sparkles function")

	-- 🔔 Optional sound
	-- local sound = Instance.new("Sound")
	-- sound.SoundId = "rbxassetid://138087017"
	-- sound.Volume = 1
	-- sound.Parent = root
	-- sound:Play()
	-- game.Debris:AddItem(sound, 3)
end


-- Create leaderstats for each player
Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = stats
end)

-- Handle job selection
JobPicked.OnServerEvent:Connect(function(player, jobId)
	local job = JobsManager:GetJobById(jobId)
	if job then
		ActiveJobs[player.UserId] = job
		print(player.Name .. " accepted job: " .. job.name) -- logging
		JobMessage:FireClient(player, "Accepted job: " .. job.name)
		JobStatus:FireClient(player, "accepted", job)
	end
end)

-- Handle delivery zone trigger
workspace.LeedsDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	local job = ActiveJobs[player.UserId]
	if not job then return end

	if job.to == "Leeds" then
		player.leaderstats.Money.Value += job.reward
		print(player.Name .. " completed " .. job.name .. " and earned " .. job.reward)
		JobMessage:FireClient(player, "Completed job! Earned £" .. job.reward)
		JobStatus:FireClient(player, "completed", job)
		ActiveJobs[player.UserId] = nil
		-- 🎆 Play visual + audio effect
		PlayDeliveryEffect(player, Color3.fromRGB(0, 170, 255)) -- blue for Leeds
	end
end)

workspace.LondonDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	local job = ActiveJobs[player.UserId]
	if not job then return end

	if job.to == "London" then
		player.leaderstats.Money.Value += job.reward
		print(player.Name .. " completed " .. job.name .. " and earned " .. job.reward)
		JobMessage:FireClient(player, "Completed job! Earned £" .. job.reward)
		JobStatus:FireClient(player, "completed", job)
		ActiveJobs[player.UserId] = nil
		-- 🎆 Play visual + audio effect
		PlayDeliveryEffect(player, Color3.fromRGB(355, 50, 50)) -- red
	end
end)
