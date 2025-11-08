local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JobsManager = require(ReplicatedStorage.Shared.Modules.JobsManager)
local JobMessage = ReplicatedStorage:WaitForChild("JobMessage")
local JobStatus = ReplicatedStorage:WaitForChild("JobStatus")

local JobPicked = ReplicatedStorage:WaitForChild("JobPicked")
local ActiveJobs = {} -- player.UserId → {job = job table, loaded = boolean}

-- Helper function to get player's boat cargo capacity
local function GetPlayerBoatCargoCapacity(player)
	-- Find the player's boat in workspace
	local playerBoats = workspace:FindFirstChild("PlayerBoats")
	if not playerBoats then return 0 end
	
	for _, boat in ipairs(playerBoats:GetChildren()) do
		local ownerTag = boat:FindFirstChild("Owner")
		if ownerTag and tostring(ownerTag.Value) == tostring(player.UserId) then
			-- Found the player's boat, now get cargo capacity
			local boatScript = boat:FindFirstChild("VehicleSeat") and boat.VehicleSeat:FindFirstChild("BoatScript")
			if boatScript then
				local originalCargo = boatScript:FindFirstChild("OriginalCargoCapacity")
				local cargoMultiplier = boatScript:FindFirstChild("CargoMultiplier")
				
				if originalCargo and cargoMultiplier then
					return originalCargo.Value * cargoMultiplier.Value
				elseif originalCargo then
					return originalCargo.Value
				end
			end
			
			-- Fallback: check boat directly
			local maxCargo = boat:FindFirstChild("MaxCargo")
			if maxCargo then
				return maxCargo.Value
			end
			
			-- Default base cargo capacity
			return 100
		end
	end
	
	return 0 -- No boat found
end

-- Helper function to check if player is in their boat
local function IsPlayerInBoat(player)
	local character = player.Character
	if not character then 
		print("DEBUG: No character found for", player.Name)
		return false 
	end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		print("DEBUG: No humanoid found for", player.Name)
		return false 
	end
	
	local seat = humanoid.SeatPart
	if not seat then 
		print("DEBUG: No SeatPart found for", player.Name)
		return false 
	end
	
	if not seat:IsA("VehicleSeat") then 
		print("DEBUG: SeatPart is not a VehicleSeat for", player.Name, "found:", seat.Name, seat.ClassName)
		return false 
	end
	
	local boat = seat.Parent
	if not boat then 
		print("DEBUG: No parent found for seat", seat.Name)
		return false 
	end
	
	print("DEBUG: Player", player.Name, "is in seat:", seat.Name, "parent:", boat.Name)
	
	local ownerTag = boat:FindFirstChild("Owner")
	if not ownerTag then 
		print("DEBUG: No Owner tag found on boat", boat.Name)
		return false 
	end
	
	local isOwner = tostring(ownerTag.Value) == tostring(player.UserId)
	print("DEBUG: Owner tag value:", ownerTag.Value, "type:", typeof(ownerTag.Value))
	print("DEBUG: player UserId:", player.UserId, "type:", typeof(player.UserId))
	print("DEBUG: matches:", isOwner)
	
	return isOwner
end

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
		-- Check if player's boat has enough cargo capacity
		local playerCargoCapacity = GetPlayerBoatCargoCapacity(player)
		local requiredCargoSize = job.cargoSize or job.loadSize or 50
		
		if playerCargoCapacity < requiredCargoSize then
			-- Boat doesn't have enough cargo capacity
			print(player.Name .. " tried to pick job requiring " .. requiredCargoSize .. " cargo, but only has " .. playerCargoCapacity)
			JobMessage:FireClient(player, "⚠️ Your boat's cargo capacity (" .. math.floor(playerCargoCapacity) .. ") is too small for this job (requires " .. math.floor(requiredCargoSize) .. "). Upgrade your boat!")
			return
		end
		
		ActiveJobs[player.UserId] = {job = job, loaded = false}
		print(player.Name .. " accepted job: " .. job.name) -- logging
		JobMessage:FireClient(player, "Accepted job: " .. job.name .. ". Go to " .. job.from .. " to load your boat.")
		JobStatus:FireClient(player, "accepted", job)
	end
end)

-- Handle delivery zone trigger
workspace.LeedsDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	local activeJob = ActiveJobs[player.UserId]
	if not activeJob then return end

	local job = activeJob.job
	
	-- Handle pickup logic (loading cargo)
	if job.from == "Leeds" and not activeJob.loaded then
		if not IsPlayerInBoat(player) then
			JobMessage:FireClient(player, "You must be in your boat to load cargo!")
			return
		end
		
		activeJob.loaded = true
		JobMessage:FireClient(player, "Boat loaded! Now deliver to " .. job.to)
		JobStatus:FireClient(player, "loaded", job)
		print(player.Name .. " loaded cargo at Leeds for job: " .. job.name)
		return
	end
	
	-- Handle delivery logic
	if job.to == "Leeds" then
		if not activeJob.loaded then
			JobMessage:FireClient(player, "You need to load your boat at " .. job.from .. " first!")
			return
		end
		
		if not IsPlayerInBoat(player) then
			JobMessage:FireClient(player, "You must be in your boat to deliver!")
			return
		end
		
		-- Update resources based on job completion
		JobsManager:CompleteJob(job)
		
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

	local activeJob = ActiveJobs[player.UserId]
	if not activeJob then return end

	local job = activeJob.job
	
	-- Handle pickup logic (loading cargo)
	if job.from == "London" and not activeJob.loaded then
		if not IsPlayerInBoat(player) then
			JobMessage:FireClient(player, "You must be in your boat to load cargo!")
			return
		end
		
		activeJob.loaded = true
		JobMessage:FireClient(player, "Boat loaded! Now deliver to " .. job.to)
		JobStatus:FireClient(player, "loaded", job)
		print(player.Name .. " loaded cargo at London for job: " .. job.name)
		return
	end
	
	-- Handle delivery logic
	if job.to == "London" then
		if not activeJob.loaded then
			JobMessage:FireClient(player, "You need to load your boat at " .. job.from .. " first!")
			return
		end
		
		if not IsPlayerInBoat(player) then
			JobMessage:FireClient(player, "You must be in your boat to deliver!")
			return
		end
		
		player.leaderstats.Money.Value += job.reward
		print(player.Name .. " completed " .. job.name .. " and earned " .. job.reward)
		JobMessage:FireClient(player, "Completed job! Earned £" .. job.reward)
		JobStatus:FireClient(player, "completed", job)
		ActiveJobs[player.UserId] = nil
		-- 🎆 Play visual + audio effect
		PlayDeliveryEffect(player, Color3.fromRGB(355, 50, 50)) -- red
	end
end)

workspace.BristolDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	local activeJob = ActiveJobs[player.UserId]
	if not activeJob then return end

	local job = activeJob.job
	
	-- Handle pickup logic (loading cargo)
	if job.from == "Bristol" and not activeJob.loaded then
		if not IsPlayerInBoat(player) then
			JobMessage:FireClient(player, "You must be in your boat to load cargo!")
			return
		end
		
		activeJob.loaded = true
		JobMessage:FireClient(player, "Boat loaded! Now deliver to " .. job.to)
		JobStatus:FireClient(player, "loaded", job)
		print(player.Name .. " loaded cargo at Bristol for job: " .. job.name)
		return
	end
	
	-- Handle delivery logic
	if job.to == "Bristol" then
		if not activeJob.loaded then
			JobMessage:FireClient(player, "You need to load your boat at " .. job.from .. " first!")
			return
		end
		
		if not IsPlayerInBoat(player) then
			JobMessage:FireClient(player, "You must be in your boat to deliver!")
			return
		end
		
		player.leaderstats.Money.Value += job.reward
		print(player.Name .. " completed " .. job.name .. " and earned " .. job.reward)
		JobMessage:FireClient(player, "Completed job! Earned £" .. job.reward)
		JobStatus:FireClient(player, "completed", job)
		ActiveJobs[player.UserId] = nil
		-- 🎆 Play visual + audio effect
		PlayDeliveryEffect(player, Color3.fromRGB(255, 165, 0)) -- orange for Bristol
	end
end)
