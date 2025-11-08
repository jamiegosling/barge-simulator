local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local FuelShopEvent = ReplicatedStorage:WaitForChild("FuelShopEvent")

-- Fuel shop configuration
local FUEL_COST_PER_UNIT = 3  -- Cost per unit of fuel

-- Create fuel shop GUI
local function createFuelShopGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FuelShopGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 380)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -190)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "⛽ Fuel Station ⛽"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Fuel info frame
	local fuelInfoFrame = Instance.new("Frame")
	fuelInfoFrame.Name = "FuelInfoFrame"
	fuelInfoFrame.Size = UDim2.new(1, -20, 0, 100)
	fuelInfoFrame.Position = UDim2.new(0, 10, 0, 60)
	fuelInfoFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	fuelInfoFrame.BorderSizePixel = 0
	fuelInfoFrame.Parent = mainFrame
	
	local fuelInfoCorner = Instance.new("UICorner")
	fuelInfoCorner.CornerRadius = UDim.new(0, 5)
	fuelInfoCorner.Parent = fuelInfoFrame
	
	-- Current fuel display
	local currentFuelLabel = Instance.new("TextLabel")
	currentFuelLabel.Name = "CurrentFuelLabel"
	currentFuelLabel.Size = UDim2.new(1, -20, 0, 30)
	currentFuelLabel.Position = UDim2.new(0, 10, 0, 10)
	currentFuelLabel.BackgroundTransparency = 1
	currentFuelLabel.Text = "Current Fuel: 0/0"
	currentFuelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	currentFuelLabel.TextSize = 16
	currentFuelLabel.Font = Enum.Font.Gotham
	currentFuelLabel.TextXAlignment = Enum.TextXAlignment.Left
	currentFuelLabel.Parent = fuelInfoFrame
	
	-- Fuel level display
	local fuelLevelLabel = Instance.new("TextLabel")
	fuelLevelLabel.Name = "FuelLevelLabel"
	fuelLevelLabel.Size = UDim2.new(1, -20, 0, 25)
	fuelLevelLabel.Position = UDim2.new(0, 10, 0, 40)
	fuelLevelLabel.BackgroundTransparency = 1
	fuelLevelLabel.Text = "Fuel Level: 1"
	fuelLevelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	fuelLevelLabel.TextSize = 14
	fuelLevelLabel.Font = Enum.Font.Gotham
	fuelLevelLabel.TextXAlignment = Enum.TextXAlignment.Left
	fuelLevelLabel.Parent = fuelInfoFrame
	
	-- Cost display
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Size = UDim2.new(1, -20, 0, 25)
	costLabel.Position = UDim2.new(0, 10, 0, 65)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = "Refill Cost: £0"
	costLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	costLabel.TextSize = 16
	costLabel.Font = Enum.Font.Gotham
	costLabel.TextXAlignment = Enum.TextXAlignment.Left
	costLabel.Parent = fuelInfoFrame
	
	-- Money display
	local moneyFrame = Instance.new("Frame")
	moneyFrame.Name = "MoneyFrame"
	moneyFrame.Size = UDim2.new(1, -20, 0, 40)
	moneyFrame.Position = UDim2.new(0, 10, 0, 170)
	moneyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	moneyFrame.BorderSizePixel = 0
	moneyFrame.Parent = mainFrame
	
	local moneyCorner = Instance.new("UICorner")
	moneyCorner.CornerRadius = UDim.new(0, 5)
	moneyCorner.Parent = moneyFrame
	
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.new(1, 0, 1, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Text = "💰 £0"
	moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	moneyLabel.TextSize = 18
	moneyLabel.Font = Enum.Font.Gotham
	moneyLabel.Parent = moneyFrame
	
	-- Buttons container
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.Name = "ButtonsFrame"
	buttonsFrame.Size = UDim2.new(1, -20, 0, 140)
	buttonsFrame.Position = UDim2.new(0, 10, 0, 220)
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.Parent = mainFrame
	
	-- Create buttons for different fuel amounts
	local buttonData = {
		{amount = 25, text = "+25 Fuel", color = Color3.fromRGB(70, 130, 180)},
		{amount = 50, text = "+50 Fuel", color = Color3.fromRGB(60, 150, 100)},
		{amount = 100, text = "+100 Fuel", color = Color3.fromRGB(100, 170, 60)},
		{amount = -1, text = "Fill Tank", color = Color3.fromRGB(0, 150, 0)}
	}
	
	local buttons = {}
	
	-- Create first row (25 and 50)
	for i = 1, 2 do
		local data = buttonData[i]
		local button = Instance.new("TextButton")
		button.Name = "FuelButton" .. i
		button.Size = UDim2.new(0.48, 0, 0, 45)
		button.Position = UDim2.new((i-1) * 0.52, 0, 0, 0)
		button.BackgroundColor3 = data.color
		button.BorderSizePixel = 0
		button.Text = data.text
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 16
		button.Font = Enum.Font.GothamBold
		button.Parent = buttonsFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = button
		
		buttons[i] = {button = button, amount = data.amount}
	end
	
	-- Create second row (100 and Fill)
	for i = 3, 4 do
		local data = buttonData[i]
		local button = Instance.new("TextButton")
		button.Name = "FuelButton" .. i
		button.Size = UDim2.new(0.48, 0, 0, 45)
		button.Position = UDim2.new((i-3) * 0.52, 0, 0, 50)
		button.BackgroundColor3 = data.color
		button.BorderSizePixel = 0
		button.Text = data.text
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 16
		button.Font = Enum.Font.GothamBold
		button.Parent = buttonsFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = button
		
		buttons[i] = {button = button, amount = data.amount}
	end
	
	-- Add cost labels below each button
	local costLabels = {}
	for i = 1, 4 do
		local label = Instance.new("TextLabel")
		label.Name = "CostLabel" .. i
		label.Size = UDim2.new(0.48, 0, 0, 20)
		local row = math.floor((i-1) / 2)
		local col = (i-1) % 2
		label.Position = UDim2.new(col * 0.52, 0, 0, row * 50 + 45)
		label.BackgroundTransparency = 1
		label.Text = "£0"
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.Parent = buttonsFrame
		costLabels[i] = label
	end
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 14
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 5)
	closeCorner.Parent = closeButton
	
	-- Initially hide the GUI
	screenGui.Enabled = false
	
	return screenGui, mainFrame, moneyLabel, currentFuelLabel, fuelLevelLabel, costLabel, buttons, costLabels, closeButton
end

-- Create the GUI
local fuelShopGui, mainFrame, moneyLabel, currentFuelLabel, fuelLevelLabel, costLabel, fuelButtons, costLabels, closeButton = createFuelShopGui()

-- Get player's current fuel information
local function getPlayerFuelInfo()
	local playerBoat = workspace:FindFirstChild("PlayerBoats") and workspace.PlayerBoats:FindFirstChild("Boat_" .. player.Name)
	if not playerBoat then
		return nil
	end
	
	-- Get fuel amount from boat
	local fuelAmount = playerBoat:FindFirstChild("FuelAmount")
	local currentFuel = fuelAmount and fuelAmount.Value or 100
	
	-- Get fuel level from player stats
	local fuelLevel = 1
	local upgradeStats = player:FindFirstChild("UpgradeStats")
	if upgradeStats then
		local fuelLevelValue = upgradeStats:FindFirstChild("FuelLevel")
		if fuelLevelValue then
			fuelLevel = fuelLevelValue.Value
		end
	end
	
	-- Calculate max fuel based on fuel level (base 200 * 1.1^(level-1))
	local baseMaxFuel = 200
	local maxFuel = math.floor(baseMaxFuel * (1.1 ^ (fuelLevel - 1)))
	
	return {
		currentFuel = currentFuel,
		maxFuel = maxFuel,
		fuelLevel = fuelLevel
	}
end

-- Update fuel shop display
local function updateFuelShopDisplay()
	local fuelInfo = getPlayerFuelInfo()
	if not fuelInfo then
		currentFuelLabel.Text = "No boat found"
		costLabel.Text = "Refill Cost: N/A"
		for i = 1, 4 do
			fuelButtons[i].button.Visible = false
			costLabels[i].Visible = false
		end
		return
	end
	
	currentFuelLabel.Text = string.format("Current Fuel: %d/%d", math.floor(fuelInfo.currentFuel), fuelInfo.maxFuel)
	fuelLevelLabel.Text = string.format("Fuel Level: %d (Max Capacity: %d)", fuelInfo.fuelLevel, fuelInfo.maxFuel)
	
	-- Calculate space available
	local fuelNeeded = fuelInfo.maxFuel - fuelInfo.currentFuel
	
	if fuelNeeded > 0 then
		costLabel.Text = string.format("Space Available: %d fuel", fuelNeeded)
		
		-- Update each button and cost label
		for i = 1, 4 do
			local amount = fuelButtons[i].amount
			local actualAmount = amount
			
			-- Handle "Fill Tank" button (amount = -1)
			if amount == -1 then
				actualAmount = fuelNeeded
			end
			
			local cost = actualAmount * FUEL_COST_PER_UNIT
			
			-- Show/hide button based on if we can add that much fuel
			if actualAmount <= fuelNeeded then
				fuelButtons[i].button.Visible = true
				costLabels[i].Visible = true
				costLabels[i].Text = string.format("£%d", cost)
			else
				fuelButtons[i].button.Visible = false
				costLabels[i].Visible = false
			end
		end
	else
		costLabel.Text = "Tank is already full!"
		for i = 1, 4 do
			fuelButtons[i].button.Visible = false
			costLabels[i].Visible = false
		end
	end
end

-- Update money display
local function updateMoneyDisplay()
	local money = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if money then
		moneyLabel.Text = "💰 £" .. money.Value
	end
end

-- Handle fuel shop opening and closing
FuelShopEvent.OnClientEvent:Connect(function(action, data)
	if action == "openFuelShop" then
		fuelShopGui.Enabled = true
		updateMoneyDisplay()
		updateFuelShopDisplay()
	elseif action == "fuelPurchaseResult" then
		if data.success then
			-- Show success message
			local message = Instance.new("TextLabel")
			message.Size = UDim2.new(0, 300, 0, 50)
			message.Position = UDim2.new(0.5, -150, 0.5, -25)
			message.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
			message.BorderSizePixel = 0
			message.Text = data.message
			message.TextColor3 = Color3.fromRGB(255, 255, 255)
			message.TextSize = 16
			message.Font = Enum.Font.GothamBold
			message.Parent = mainFrame
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 5)
			corner.Parent = message
			
			-- Animate and remove message
			local tween = TweenService:Create(message, TweenInfo.new(2), {Position = UDim2.new(0.5, -150, 0.3, -25)})
			tween:Play()
			
			game.Debris:AddItem(message, 2)
			
			-- Update displays
			updateMoneyDisplay()
			updateFuelShopDisplay()
		else
			-- Show error message
			local message = Instance.new("TextLabel")
			message.Size = UDim2.new(0, 300, 0, 50)
			message.Position = UDim2.new(0.5, -150, 0.5, -25)
			message.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
			message.BorderSizePixel = 0
			message.Text = data.message
			message.TextColor3 = Color3.fromRGB(255, 255, 255)
			message.TextSize = 16
			message.Font = Enum.Font.GothamBold
			message.Parent = mainFrame
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 5)
			corner.Parent = message
			
			game.Debris:AddItem(message, 3)
		end
	end
end)

-- Handle button clicks for all fuel buttons
for i = 1, 4 do
	fuelButtons[i].button.MouseButton1Click:Connect(function()
		local fuelInfo = getPlayerFuelInfo()
		if not fuelInfo then
			return
		end
		
		local fuelNeeded = fuelInfo.maxFuel - fuelInfo.currentFuel
		if fuelNeeded <= 0 then
			return
		end
		
		-- Calculate actual amount to purchase
		local amount = fuelButtons[i].amount
		if amount == -1 then
			-- Fill tank
			amount = fuelNeeded
		end
		
		-- Cap amount to available space
		amount = math.min(amount, fuelNeeded)
		
		local cost = amount * FUEL_COST_PER_UNIT
		
		-- Check if player has enough money
		local money = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
		if not money or money.Value < cost then
			-- Show error message
			local message = Instance.new("TextLabel")
			message.Size = UDim2.new(0, 300, 0, 50)
			message.Position = UDim2.new(0.5, -150, 0.5, -25)
			message.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
			message.BorderSizePixel = 0
			message.Text = "Not enough money! Need £" .. cost
			message.TextColor3 = Color3.fromRGB(255, 255, 255)
			message.TextSize = 16
			message.Font = Enum.Font.GothamBold
			message.Parent = mainFrame
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 5)
			corner.Parent = message
			
			game.Debris:AddItem(message, 3)
			return
		end
		
		-- Request fuel purchase from server
		FuelShopEvent:FireServer("purchaseFuel", amount)
	end)
end

closeButton.MouseButton1Click:Connect(function()
	fuelShopGui.Enabled = false
end)

-- Close GUI with Escape key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Escape and fuelShopGui.Enabled then
		fuelShopGui.Enabled = false
	end
end)

-- Update displays periodically when GUI is open
coroutine.wrap(function()
	while true do
		task.wait(1)
		if fuelShopGui.Enabled then
			updateMoneyDisplay()
			updateFuelShopDisplay()
		end
	end
end)()

print("Fuel shop client initialized")
