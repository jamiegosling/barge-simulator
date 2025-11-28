local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JobsManager = require(ReplicatedStorage.Shared.Modules.JobsManager)
local JobMessage = ReplicatedStorage:WaitForChild("JobMessage")
local JobStatus = ReplicatedStorage:WaitForChild("JobStatus")
local UpdateJobDestination = ReplicatedStorage:WaitForChild("UpdateJobDestination")

-- Import AchievementManager
local AchievementManager = require(ServerScriptService:WaitForChild("Server"):WaitForChild("AchievementManager"))

local JobPicked = ReplicatedStorage:WaitForChild("JobPicked")
local CancelJob = ReplicatedStorage:WaitForChild("CancelJob")
local ActiveJobs = {} -- player.UserId → {job = job table, loaded = boolean}
local PlayersInZones = {} -- player.UserId → {zoneName = true, ...}

local PlayDeliveryEffect

-- Helper function to get delivery zone position
local function GetDeliveryZonePosition(zoneName)
	local zonePart = workspace:FindFirstChild(zoneName .. "DeliveryZone")
	if zonePart then
		return zonePart.Position
	end
	-- Fallback: return a default position if zone not found
	warn("Could not find delivery zone:", zoneName .. "DeliveryZone")
	return Vector3.new(0, 10, 0)
end

-- Helper function to get player's boat
local function GetPlayerBoat(player)
	local playerBoats = workspace:FindFirstChild("PlayerBoats")
	if not playerBoats then return nil end

	for _, boat in ipairs(playerBoats:GetChildren()) do
		local ownerTag = boat:FindFirstChild("Owner")
		if ownerTag and tostring(ownerTag.Value) == tostring(player.UserId) then
			return boat
		end
	end

	return nil
end

-- Helper function to get player's boat cargo capacity
local function GetPlayerBoatCargoCapacity(player)
	local boat = GetPlayerBoat(player)
	if not boat then return 0 end

	-- Found the player's boat, now get cargo capacity
	local vehicleSeat = boat:FindFirstChildWhichIsA("VehicleSeat")
	local boatScript = vehicleSeat and (vehicleSeat:FindFirstChild("BoatScript") or vehicleSeat:FindFirstChildWhichIsA("Script"))

	if boatScript then
		local originalCargo = boatScript:FindFirstChild("OriginalCargoCapacity")
		local cargoMultiplier = boatScript:FindFirstChild("CargoMultiplier")

		if originalCargo and cargoMultiplier then
			return originalCargo.Value * cargoMultiplier.Value
			-- return 100 * cargoMultiplier.Value
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

-- Helper functions for zone tracking
local function AddPlayerToZone(player, zoneName)
	if not PlayersInZones[player.UserId] then
		PlayersInZones[player.UserId] = {}
	end
	PlayersInZones[player.UserId][zoneName] = true
	print("DEBUG: Player", player.Name, "entered zone:", zoneName)
end

local function RemovePlayerFromZone(player, zoneName)
	if PlayersInZones[player.UserId] then
		PlayersInZones[player.UserId][zoneName] = nil
		print("DEBUG: Player", player.Name, "left zone:", zoneName)
	end
end

local function IsPlayerInZone(player, zoneName)
	return PlayersInZones[player.UserId] and PlayersInZones[player.UserId][zoneName] == true
end

local function CheckJobActionInCurrentZone(player)
	local activeJob = ActiveJobs[player.UserId]
	if not activeJob then return end
	
	local job = activeJob.job
	
	-- Check if player is in the pickup zone and needs to load
	if not activeJob.loaded and IsPlayerInZone(player, job.from) then
		if not IsPlayerInBoat(player) then
			JobMessage:FireClient(player, "You must be in your boat to load cargo!")
			return
		end
		
		activeJob.loaded = true
		JobMessage:FireClient(player, "Boat loaded! Now deliver to " .. job.to)
		JobStatus:FireClient(player, "loaded", job)
		
		-- Send guideline to delivery location
		local deliveryPosition = GetDeliveryZonePosition(job.to)
		UpdateJobDestination:FireClient(player, deliveryPosition, false) -- false = delivery location
		
        PlayDeliveryEffect(player)
		print(player.Name .. " loaded cargo at " .. job.from .. " for job: " .. job.name)
		return
	end
	
	-- Check if player is in the delivery zone and ready to deliver
	if activeJob.loaded and IsPlayerInZone(player, job.to) then
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
		
		-- Track achievements
		AchievementManager.IncrementJobsCompleted(player, job.cargo)
		AchievementManager.IncrementMoneyEarned(player, job.reward)
		
		-- Remove guideline
		UpdateJobDestination:FireClient(player, nil, false)
		
		ActiveJobs[player.UserId] = nil
		
		-- Play visual effect based on zone
		local zoneColors = {
			Leeds = Color3.fromRGB(0, 170, 255),
			London = Color3.fromRGB(255, 50, 50),
			Bristol = Color3.fromRGB(255, 165, 0),
			Exeter = Color3.fromRGB(255, 165, 0),
			Newcastle = Color3.fromRGB(255, 165, 0),
			Boatyard = Color3.fromRGB(255, 165, 0)
		}
		PlayDeliveryEffect(player, zoneColors[job.to] or Color3.fromRGB(255, 255, 255))
	end
end

-- Helper function: play particle + sound effects for completed delivery
local function makeSparkleSize(multiplier)
	multiplier = multiplier or 1
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1 * multiplier),
		NumberSequenceKeypoint.new(0.3, 0.8 * multiplier),
		NumberSequenceKeypoint.new(1, 0)
	})
end

local function emitSparkles(target, color, emitCount, speedRange, sizeMultiplier, brightness)
	if not target then return end

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxassetid://258128463"
	sparkles.Color = ColorSequence.new(color)
	sparkles.Lifetime = NumberRange.new(1.2, 1.8)
	sparkles.Rate = 0
	sparkles.Speed = speedRange or NumberRange.new(2, 6)
	sparkles.Size = makeSparkleSize(sizeMultiplier)
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
	sparkles.Brightness = brightness or 4
	sparkles.Parent = target
	sparkles:Emit(emitCount or 100)

	game.Debris:AddItem(sparkles, 3)
end

PlayDeliveryEffect = function(player, color)
	local effectColor = color or Color3.fromRGB(255, 255, 150)

	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
		emitSparkles(root, effectColor, 100)
	end

	local boat = GetPlayerBoat(player)
	if boat then
		local boatRoot = boat.PrimaryPart or boat:FindFirstChild("Hull") or boat:FindFirstChildWhichIsA("BasePart")
		if not boatRoot then
			local boatSeat = boat:FindFirstChildWhichIsA("VehicleSeat")
			boatRoot = boatSeat or boatRoot
		end

		emitSparkles(boatRoot, effectColor, 140, NumberRange.new(1, 4), 1.6, 3)
	end

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
	
	-- Handle character respawns - sync job state
	player.CharacterAdded:Connect(function(character)
		task.wait(1) -- Wait a moment for character to fully load
		
		local activeJob = ActiveJobs[player.UserId]
		if activeJob then
			print("🔄 Resyncing job state for respawning player:", player.Name)
			if activeJob.loaded then
				-- Player had loaded cargo, restore loaded state
				JobStatus:FireClient(player, "loaded", activeJob.job)
				-- Send guideline to destination
				local destinationPosition = GetDeliveryZonePosition(activeJob.job.to)
				UpdateJobDestination:FireClient(player, destinationPosition, false) -- false = delivery location
			else
				-- Player had accepted job but not loaded yet
				JobStatus:FireClient(player, "accepted", activeJob.job)
				-- Send guideline to pickup location
				local pickupPosition = GetDeliveryZonePosition(activeJob.job.from)
				UpdateJobDestination:FireClient(player, pickupPosition, true) -- true = pickup location
			end
		end
	end)
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
	-- Remove guideline
	UpdateJobDestination:FireClient(player, nil, false)
	
	ActiveJobs[player.UserId] = nil
	PlayersInZones[player.UserId] = nil
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
		
		-- Send guideline to pickup location
		local pickupPosition = GetDeliveryZonePosition(job.from)
		UpdateJobDestination:FireClient(player, pickupPosition, true) -- true = pickup location
		
		-- Check if player is already in the correct zone for immediate action
		CheckJobActionInCurrentZone(player)
	end
end)

-- Handle job cancellation
CancelJob.OnServerEvent:Connect(function(player)
	local activeJob = ActiveJobs[player.UserId]
	if not activeJob then
		JobMessage:FireClient(player, "You don't have an active job to cancel.")
		return
	end
	
	local job = activeJob.job
	local cancellationFee = math.floor(job.reward * 0.1)
	
	-- Check if player has enough money to pay the cancellation fee
	local playerMoney = player.leaderstats.Money.Value
	if playerMoney < cancellationFee then
		JobMessage:FireClient(player, "You don't have enough money to cancel this job (Fee: £" .. cancellationFee .. ")")
		return
	end
	
	-- Charge the cancellation fee
	player.leaderstats.Money.Value = player.leaderstats.Money.Value - cancellationFee
	
	-- Clear the active job
	ActiveJobs[player.UserId] = nil
	
	-- Remove guideline
	UpdateJobDestination:FireClient(player, nil, false)
	
	-- Notify player
	JobMessage:FireClient(player, "Job cancelled. You were charged £" .. cancellationFee .. " cancellation fee.")
	JobStatus:FireClient(player, "cancelled", job)
	
	print(player.Name .. " cancelled job: " .. job.name .. " and paid £" .. cancellationFee .. " fee")
end)

-- Handle delivery zone triggers with zone tracking
workspace.LeedsDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	AddPlayerToZone(player, "Leeds")
	CheckJobActionInCurrentZone(player)
end)

workspace.LeedsDeliveryZone.TouchEnded:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	RemovePlayerFromZone(player, "Leeds")
end)

workspace.LondonDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	AddPlayerToZone(player, "London")
	CheckJobActionInCurrentZone(player)
end)

workspace.LondonDeliveryZone.TouchEnded:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	RemovePlayerFromZone(player, "London")
end)

workspace.BristolDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	AddPlayerToZone(player, "Bristol")
	CheckJobActionInCurrentZone(player)
end)

workspace.BristolDeliveryZone.TouchEnded:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	RemovePlayerFromZone(player, "Bristol")
end)

workspace.ExeterDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	AddPlayerToZone(player, "Exeter")
	CheckJobActionInCurrentZone(player)
end)

workspace.ExeterDeliveryZone.TouchEnded:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	RemovePlayerFromZone(player, "Exeter")
end)

workspace.NewcastleDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	AddPlayerToZone(player, "Newcastle")
	CheckJobActionInCurrentZone(player)
end)

workspace.NewcastleDeliveryZone.TouchEnded:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	RemovePlayerFromZone(player, "Newcastle")
end)

workspace.BoatyardDeliveryZone.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	AddPlayerToZone(player, "Boatyard")
	CheckJobActionInCurrentZone(player)
end)

workspace.BoatyardDeliveryZone.TouchEnded:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	RemovePlayerFromZone(player, "Boatyard")
end)