local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Engine = script.Parent.Parent.BargeEngine.BodyThrust
local SForce = script.Parent.Parent.BargeSteer.BodyAngularVelocity
local DSeat = script.Parent
local Base = script.Parent.Parent.Barge

-- Disable built-in HUD
DSeat.HeadsUpDisplay = false

-- ==================== VARIABLES ==================== --
local currentSpeed = 0
local movementDirection = 0
local baseMaxSpeed = 20000
local maxSpeed = baseMaxSpeed
SteerSpeed = 500
BaseDensity = .1
local MIN_STEER_SPEED = 1

-- Cargo variables
local baseMaxCargo = 100
local maxCargo = baseMaxCargo
local baseCurrentCargo = 0
local currentCargo = baseCurrentCargo

-- Fuel variables
local baseMaxFuel = 200
local maxFuel = baseMaxFuel
local baseCurrentFuel = 100
local currentFuel = baseCurrentFuel

-- Fuel consumption variables
local FUEL_CONSUMPTION_RATE = 0.1  -- Fuel consumed per stud traveled
local lastPosition = nil
local totalDistanceTraveled = 0

-- Track fuel-empty state to trigger throttle updates without input
local outOfFuel = (currentFuel <= 0)

-- Get upgrade values
local OriginalMaxSpeed = script:FindFirstChild("OriginalMaxSpeed")
local SpeedMultiplier = script:FindFirstChild("SpeedMultiplier")
local OriginalCargoCapacity = script:FindFirstChild("OriginalCargoCapacity")  -- Fixed: match UpgradeManager
local CargoMultiplier = script:FindFirstChild("CargoMultiplier")
local InitialCargo = script:FindFirstChild("InitialCargo")
local OriginalFuelCapacity = script:FindFirstChild("OriginalFuelCapacity")  -- Fixed: match UpgradeManager  
local FuelMultiplier = script:FindFirstChild("FuelMultiplier")
local InitialFuel = script:FindFirstChild("InitialFuel")
local FuelConsumptionRate = script:FindFirstChild("FuelConsumptionRate")

-- Set fuel consumption rate
if FuelConsumptionRate then
	FUEL_CONSUMPTION_RATE = FuelConsumptionRate.Value
end

-- Set initial speed values
if OriginalMaxSpeed then
	baseMaxSpeed = OriginalMaxSpeed.Value
end
if SpeedMultiplier then
	maxSpeed = baseMaxSpeed * SpeedMultiplier.Value
else
	maxSpeed = baseMaxSpeed
end

-- Set initial cargo values
if OriginalCargoCapacity then
	baseMaxCargo = OriginalCargoCapacity.Value
end
if CargoMultiplier then
	maxCargo = baseMaxCargo * CargoMultiplier.Value
else
	maxCargo = baseMaxCargo
end
if InitialCargo then
	currentCargo = InitialCargo.Value
else
	currentCargo = baseCurrentCargo
end

-- Set initial fuel values
if OriginalFuelCapacity then
	baseMaxFuel = OriginalFuelCapacity.Value
end
if FuelMultiplier then
	maxFuel = baseMaxFuel * FuelMultiplier.Value
else
	maxFuel = baseMaxFuel
end
if InitialFuel then
	currentFuel = InitialFuel.Value
	print("⛽ Initial fuel set from InitialFuel:", currentFuel)
else
	currentFuel = baseCurrentFuel
	print("⛽ Initial fuel set to default:", currentFuel)
end

-- ==================== GUI VARIABLES ==================== --
local screenGui = nil
local hudFrame = nil
local speedLabel = nil
local cargoLabel = nil
local fuelLabel = nil

-- ==================== HELPER FUNCTIONS ==================== --

-- Function to create GUI for a player
local function createGUIForPlayer(player)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Remove old GUI if it exists
	local oldGui = playerGui:FindFirstChild("BoatHUD")
	if oldGui then
		oldGui:Destroy()
	end

	-- Create HUD GUI
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BoatHUD"
	screenGui.Parent = playerGui
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = true -- Start enabled

	-- Simple container frame
	hudFrame = Instance.new("Frame")
	hudFrame.Name = "HUDContainer"
	hudFrame.Size = UDim2.new(0, 200, 0, 100)
	hudFrame.Position = UDim2.new(0, 50, 0, 50)
	hudFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	hudFrame.BackgroundTransparency = 0.2
	hudFrame.BorderSizePixel = 2
	hudFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	hudFrame.Visible = true
	hudFrame.Parent = screenGui

	-- Speed display
	speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "SpeedDisplay"
	speedLabel.Size = UDim2.new(1, -10, 0, 30)
	speedLabel.Position = UDim2.new(0, 5, 0, 5)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "🚤 Speed: 0 studs/s"
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.TextSize = 18
	speedLabel.Font = Enum.Font.SourceSansBold
	speedLabel.Visible = true
	speedLabel.Parent = hudFrame

	-- Cargo display
	cargoLabel = Instance.new("TextLabel")
	cargoLabel.Name = "CargoDisplay"
	cargoLabel.Size = UDim2.new(1, -10, 0, 30)
	cargoLabel.Position = UDim2.new(0, 5, 0, 35)
	cargoLabel.BackgroundTransparency = 1
	cargoLabel.Text = "📦 Max Cargo: 100"
	cargoLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	cargoLabel.TextSize = 16
	cargoLabel.Font = Enum.Font.SourceSans
	cargoLabel.Visible = true
	cargoLabel.Parent = hudFrame

	-- Fuel display
	fuelLabel = Instance.new("TextLabel")
	fuelLabel.Name = "FuelDisplay"
	fuelLabel.Size = UDim2.new(1, -10, 0, 30)
	fuelLabel.Position = UDim2.new(0, 5, 0, 65)
	fuelLabel.BackgroundTransparency = 1
	fuelLabel.Text = "⛽ Fuel: 100/200"
	fuelLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	fuelLabel.TextSize = 16
	fuelLabel.Font = Enum.Font.SourceSans
	fuelLabel.Visible = true
	fuelLabel.Parent = hudFrame

	print("🖥️ HUD GUI created for player:", player.Name)
	print("   - ScreenGui Parent:", screenGui.Parent:GetFullName())
	print("   - ScreenGui Enabled:", screenGui.Enabled)
	print("   - HudFrame Visible:", hudFrame.Visible)
	print("   - Children count:", #hudFrame:GetChildren())
end

-- Function to get upgrade values from boat
local function getUpgradeValues()
	local boat = DSeat.Parent
	local values = {}

	-- Get cargo values - use local variables with fallback to boat values
	local cargoAmount = boat:FindFirstChild("CargoAmount")
	local maxCargoValue = boat:FindFirstChild("MaxCargo")
	local originalCargo = boat:FindFirstChild("OriginalCargoCapacity")
	local cargoMultiplier = script:FindFirstChild("CargoMultiplier")  -- Fixed: look in script, not boat

	if cargoAmount then
		values.currentCargo = cargoAmount.Value
	else
		values.currentCargo = currentCargo
	end

	if maxCargoValue then
		values.maxCargo = maxCargoValue.Value
	elseif originalCargo and cargoMultiplier then
		values.maxCargo = originalCargo.Value * cargoMultiplier.Value
	else
		values.maxCargo = maxCargo
	end

	-- Get fuel values - use local variables with fallback to boat values
	local fuelAmount = boat:FindFirstChild("FuelAmount")
	local maxFuelValue = boat:FindFirstChild("MaxFuel")
	local originalFuel = boat:FindFirstChild("OriginalFuelCapacity")
	local fuelMultiplier = script:FindFirstChild("FuelMultiplier")  -- Fixed: look in script, not boat

	if fuelAmount then
		values.currentFuel = fuelAmount.Value
	else
		values.currentFuel = currentFuel
	end

	if maxFuelValue then
		values.maxFuel = maxFuelValue.Value
	elseif originalFuel and fuelMultiplier then
		values.maxFuel = originalFuel.Value * fuelMultiplier.Value
	else
		values.maxFuel = maxFuel
	end

	return values
end

-- Update HUD displays
local function updateHUD()
	if not DSeat.Occupant then
		if screenGui then
			screenGui.Enabled = false
		end
		return
	end

	-- Create GUI if it doesn't exist
	if not screenGui or not screenGui.Parent then
		local player = Players:GetPlayerFromCharacter(DSeat.Occupant.Parent)
		if player then
			createGUIForPlayer(player)
		end
	end

	if screenGui then
		screenGui.Enabled = true

		-- Update speed
		if speedLabel then
			local speed = math.abs(currentSpeed or 0)
			speedLabel.Text = "🚤 Speed: " .. math.floor(speed) .. " studs/s"
		end

		-- Update cargo and fuel
		if cargoLabel and fuelLabel then
			local values = getUpgradeValues()
			cargoLabel.Text = "📦 Max Cargo: " .. math.floor(values.maxCargo)

			fuelLabel.Text = "⛽ Fuel: " .. math.floor(values.currentFuel) .. "/" .. math.floor(values.maxFuel)

			-- Change fuel color based on level
			local fuelPercent = (values.currentFuel / values.maxFuel) * 100
			if fuelPercent <= 20 then
				fuelLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
			elseif fuelPercent <= 50 then
				fuelLabel.TextColor3 = Color3.fromRGB(255, 200, 100) -- Orange
			else
				fuelLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
			end
		end
	end
end

-- ==================== STEERING AND THROTTLE ==================== --

-- Function to handle all steering logic
local function UpdateSteering(speed)
	local angularVelocity = Vector3.new(0, 0, 0)

	if movementDirection ~= 0 and math.abs(DSeat.SteerFloat) > 0.01 then
		-- Quadratic curve - steering grows faster at higher speeds
		local speedFactor = math.min((math.abs(speed) / 50) ^ 2, 1)
		local adjustedSteerSpeed = SteerSpeed * speedFactor

		angularVelocity = Vector3.new(0, -adjustedSteerSpeed * DSeat.SteerFloat * movementDirection, 0)
	end

	SForce.AngularVelocity = angularVelocity
end

-- Function to handle all throttle logic
local function UpdateThrottle()
	local currentMultiplier = script:FindFirstChild("SpeedMultiplier")
	if currentMultiplier then
		maxSpeed = baseMaxSpeed * currentMultiplier.Value
	else
		maxSpeed = baseMaxSpeed
	end

	-- Reduce speed to original if fuel is empty
	local effectiveMaxSpeed = maxSpeed
	if currentFuel <= 0 then
		effectiveMaxSpeed = baseMaxSpeed  -- Use original base speed without multipliers
	end

	Engine.Force = Vector3.new(0, 0, effectiveMaxSpeed * DSeat.ThrottleFloat)
	UpdateSteering(currentSpeed)
end

-- Function to update cargo values
local function UpdateCargo()
	local currentMultiplier = script:FindFirstChild("CargoMultiplier")
	if currentMultiplier then
		maxCargo = baseMaxCargo * currentMultiplier.Value
	else
		maxCargo = baseMaxCargo
	end
	
	-- Update current cargo from boat if it exists
	local boat = DSeat.Parent
	local cargoAmount = boat:FindFirstChild("CargoAmount")
	if cargoAmount then
		currentCargo = cargoAmount.Value
	end
end

-- Function to update fuel values
local function UpdateFuel()
	local currentMultiplier = script:FindFirstChild("FuelMultiplier")
	if currentMultiplier then
		maxFuel = baseMaxFuel * currentMultiplier.Value
	else
		maxFuel = baseMaxFuel
	end
	
	-- Update current fuel - prioritize InitialFuel from script, then FuelAmount from boat
	local initialFuelValue = script:FindFirstChild("InitialFuel")
	if initialFuelValue then
		print("⛽ UpdateFuel: Using InitialFuel from script:", initialFuelValue.Value)
		currentFuel = initialFuelValue.Value
		-- Update boat's FuelAmount to match
		local boat = DSeat.Parent
		local fuelAmount = boat:FindFirstChild("FuelAmount")
		if fuelAmount then
			fuelAmount.Value = currentFuel
		end
	else
		-- Fallback to boat's FuelAmount if InitialFuel doesn't exist
		local boat = DSeat.Parent
		local fuelAmount = boat:FindFirstChild("FuelAmount")
		if fuelAmount then
			print("⛽ UpdateFuel: Using FuelAmount from boat:", fuelAmount.Value)
			currentFuel = fuelAmount.Value
		else
			print("⛽ UpdateFuel: No fuel values found, keeping current:", currentFuel)
		end
	end
end

-- ==================== CONNECTIONS ==================== --

-- Monitor velocity continuously
local velocityConnection = RunService.Heartbeat:Connect(function()
	local partVelocity = Base.AssemblyLinearVelocity
	local relativeVelocity = Base.CFrame:VectorToObjectSpace(partVelocity)
	local forwardSpeed = relativeVelocity.X

	currentSpeed = forwardSpeed

	-- Fuel consumption based on distance traveled
	local currentPosition = Base.Position
	if lastPosition and DSeat.Occupant and math.abs(forwardSpeed) > MIN_STEER_SPEED then
		local distance = (currentPosition - lastPosition).Magnitude
		totalDistanceTraveled = totalDistanceTraveled + distance
		
		-- Consume fuel
		local fuelToConsume = distance * FUEL_CONSUMPTION_RATE
		local previousFuel = currentFuel
		currentFuel = math.max(0, currentFuel - fuelToConsume)
		
		-- Update fuel amount on boat if it exists
		local boat = DSeat.Parent
		local fuelAmount = boat:FindFirstChild("FuelAmount")
		if fuelAmount then
			fuelAmount.Value = currentFuel
		end
		
		-- If fuel-empty state changed, update throttle immediately
		local nowOutOfFuel = (currentFuel <= 0)
		if nowOutOfFuel ~= outOfFuel then
			outOfFuel = nowOutOfFuel
			UpdateThrottle()
		end
	end
	lastPosition = currentPosition

	local newDirection = 0
	if forwardSpeed > MIN_STEER_SPEED then
		newDirection = 1
	elseif forwardSpeed < -MIN_STEER_SPEED then
		newDirection = -1
	end

	if newDirection ~= movementDirection then
		movementDirection = newDirection
		UpdateSteering(forwardSpeed)
	else
		UpdateSteering(forwardSpeed)
	end
end)

-- Connect HUD updates to heartbeat
local hudConnection = RunService.Heartbeat:Connect(updateHUD)

-- Show/hide HUD based on seat occupancy
local seatConnection = DSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
	print("🪑 Occupant changed to:", DSeat.Occupant and DSeat.Occupant.Name or "nil")

	if DSeat.Occupant then
		local player = Players:GetPlayerFromCharacter(DSeat.Occupant.Parent)
		if player then
			print("   Player found:", player.Name)
			print("   Current fuel before UpdateFuel:", currentFuel)
			-- Update fuel values when player sits down
			UpdateFuel()
			print("   Current fuel after UpdateFuel:", currentFuel)
			createGUIForPlayer(player)
		end
	else
		if screenGui then
			screenGui:Destroy()
			screenGui = nil
			hudFrame = nil
			speedLabel = nil
			cargoLabel = nil
			fuelLabel = nil
		end
	end

	updateHUD()
end)

-- Handle seat input changes
DSeat.Changed:Connect(function(p)
	if p == "ThrottleFloat" then
		UpdateThrottle()
	end
	if p == "SteerFloat" then
		UpdateSteering(currentSpeed)
	end
end)

-- Handle upgrade changes
script.ChildAdded:Connect(function(child)
	if child.Name == "SpeedMultiplier" then
		maxSpeed = baseMaxSpeed * child.Value
		UpdateThrottle()
	elseif child.Name == "CargoMultiplier" then
		maxCargo = baseMaxCargo * child.Value
		UpdateCargo()
	elseif child.Name == "FuelMultiplier" then
		maxFuel = baseMaxFuel * child.Value
		UpdateFuel()
	elseif child.Name == "InitialCargo" then
		currentCargo = child.Value
		UpdateCargo()
	elseif child.Name == "InitialFuel" then
		currentFuel = child.Value
		UpdateFuel()
	end
end)

script.ChildRemoved:Connect(function(child)
	if child.Name == "SpeedMultiplier" then
		maxSpeed = baseMaxSpeed
		UpdateThrottle()
	elseif child.Name == "CargoMultiplier" then
		maxCargo = baseMaxCargo
		UpdateCargo()
	elseif child.Name == "FuelMultiplier" then
		maxFuel = baseMaxFuel
		UpdateFuel()
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
	if screenGui then
		screenGui:Destroy()
	end
end)