local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local ShopEvent = ReplicatedStorage:WaitForChild("ShopEvent")
local UpgradeEvent = ReplicatedStorage:WaitForChild("UpgradeEvent")

-- Create shop GUI
local function createShopGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
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
	title.Text = "⚓ Boat Upgrade Shop ⚓"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Tab buttons
	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "TabFrame"
	tabFrame.Size = UDim2.new(1, -20, 0, 40)
	tabFrame.Position = UDim2.new(0, 10, 0, 60)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = mainFrame
	
	local speedTab = Instance.new("TextButton")
	speedTab.Name = "SpeedTab"
	speedTab.Size = UDim2.new(0, 100, 1, 0)
	speedTab.Position = UDim2.new(0, 0, 0, 0)
	speedTab.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	speedTab.BorderSizePixel = 0
	speedTab.Text = "🚀 Speed"
	speedTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedTab.TextSize = 14
	speedTab.Font = Enum.Font.GothamBold
	speedTab.Parent = tabFrame
	
	local cargoTab = Instance.new("TextButton")
	cargoTab.Name = "CargoTab"
	cargoTab.Size = UDim2.new(0, 100, 1, 0)
	cargoTab.Position = UDim2.new(0, 110, 0, 0)
	cargoTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	cargoTab.BorderSizePixel = 0
	cargoTab.Text = "📦 Cargo"
	cargoTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	cargoTab.TextSize = 14
	cargoTab.Font = Enum.Font.GothamBold
	cargoTab.Parent = tabFrame
	
	local fuelTab = Instance.new("TextButton")
	fuelTab.Name = "FuelTab"
	fuelTab.Size = UDim2.new(0, 100, 1, 0)
	fuelTab.Position = UDim2.new(0, 220, 0, 0)
	fuelTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	fuelTab.BorderSizePixel = 0
	fuelTab.Text = "⛽ Fuel"
	fuelTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	fuelTab.TextSize = 14
	fuelTab.Font = Enum.Font.GothamBold
	fuelTab.Parent = tabFrame
	
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 5)
	tabCorner.Parent = speedTab
	
	local tabCorner2 = Instance.new("UICorner")
	tabCorner2.CornerRadius = UDim.new(0, 5)
	tabCorner2.Parent = cargoTab
	
	local tabCorner3 = Instance.new("UICorner")
	tabCorner3.CornerRadius = UDim.new(0, 5)
	tabCorner3.Parent = fuelTab
	
	-- Money display
	local moneyFrame = Instance.new("Frame")
	moneyFrame.Name = "MoneyFrame"
	moneyFrame.Size = UDim2.new(1, -20, 0, 40)
	moneyFrame.Position = UDim2.new(0, 10, 0, 360)
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
	
	-- Upgrade content frame (scrollable)
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 0, 240)
	contentFrame.Position = UDim2.new(0, 10, 0, 110)
	contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = mainFrame
	
	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 5)
	contentCorner.Parent = contentFrame
	
	-- Speed upgrade section
	local speedFrame = Instance.new("Frame")
	speedFrame.Name = "SpeedFrame"
	speedFrame.Size = UDim2.new(1, 0, 1, 0)
	speedFrame.Position = UDim2.new(0, 0, 0, 0)
	speedFrame.BackgroundTransparency = 1
	speedFrame.Parent = contentFrame
	
	local speedTitle = Instance.new("TextLabel")
	speedTitle.Name = "SpeedTitle"
	speedTitle.Size = UDim2.new(1, -20, 0, 30)
	speedTitle.Position = UDim2.new(0, 10, 0, 10)
	speedTitle.BackgroundTransparency = 1
	speedTitle.Text = "🚀 Boat Speed Upgrade"
	speedTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedTitle.TextSize = 18
	speedTitle.Font = Enum.Font.GothamBold
	speedTitle.Parent = speedFrame
	
	local speedInfo = Instance.new("TextLabel")
	speedInfo.Name = "SpeedInfo"
	speedInfo.Size = UDim2.new(1, -20, 0, 40)
	speedInfo.Position = UDim2.new(0, 10, 0, 40)
	speedInfo.BackgroundTransparency = 1
	speedInfo.Text = "Current Level: 1\nSpeed Multiplier: 1.00x (0% faster)"
	speedInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	speedInfo.TextSize = 14
	speedInfo.Font = Enum.Font.Gotham
	speedInfo.TextXAlignment = Enum.TextXAlignment.Left
	speedInfo.Parent = speedFrame
	
	local speedCostLabel = Instance.new("TextLabel")
	speedCostLabel.Name = "SpeedCostLabel"
	speedCostLabel.Size = UDim2.new(1, -20, 0, 25)
	speedCostLabel.Position = UDim2.new(0, 10, 0, 80)
	speedCostLabel.BackgroundTransparency = 1
	speedCostLabel.Text = "Next Upgrade: £100"
	speedCostLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	speedCostLabel.TextSize = 16
	speedCostLabel.Font = Enum.Font.Gotham
	speedCostLabel.Parent = speedFrame
	
	local speedUpgradeButton = Instance.new("TextButton")
	speedUpgradeButton.Name = "SpeedUpgradeButton"
	speedUpgradeButton.Size = UDim2.new(0, 120, 0, 35)
	speedUpgradeButton.Position = UDim2.new(0, 10, 0, 105)
	speedUpgradeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	speedUpgradeButton.BorderSizePixel = 0
	speedUpgradeButton.Text = "Upgrade"
	speedUpgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedUpgradeButton.TextSize = 16
	speedUpgradeButton.Font = Enum.Font.GothamBold
	speedUpgradeButton.Parent = speedFrame
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 5)
	buttonCorner.Parent = speedUpgradeButton
	
	-- Cargo upgrade section
	local cargoFrame = Instance.new("Frame")
	cargoFrame.Name = "CargoFrame"
	cargoFrame.Size = UDim2.new(1, 0, 1, 0)
	cargoFrame.Position = UDim2.new(0, 0, 0, 0)
	cargoFrame.BackgroundTransparency = 1
	cargoFrame.Visible = false
	cargoFrame.Parent = contentFrame
	
	local cargoTitle = Instance.new("TextLabel")
	cargoTitle.Name = "CargoTitle"
	cargoTitle.Size = UDim2.new(1, -20, 0, 30)
	cargoTitle.Position = UDim2.new(0, 10, 0, 10)
	cargoTitle.BackgroundTransparency = 1
	cargoTitle.Text = "📦 Cargo Capacity Upgrade"
	cargoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	cargoTitle.TextSize = 18
	cargoTitle.Font = Enum.Font.GothamBold
	cargoTitle.Parent = cargoFrame
	
	local cargoInfo = Instance.new("TextLabel")
	cargoInfo.Name = "CargoInfo"
	cargoInfo.Size = UDim2.new(1, -20, 0, 40)
	cargoInfo.Position = UDim2.new(0, 10, 0, 40)
	cargoInfo.BackgroundTransparency = 1
	cargoInfo.Text = "Current Level: 1\nCargo Capacity: 1.00x (0% more capacity)"
	cargoInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	cargoInfo.TextSize = 14
	cargoInfo.Font = Enum.Font.Gotham
	cargoInfo.TextXAlignment = Enum.TextXAlignment.Left
	cargoInfo.Parent = cargoFrame
	
	local cargoCostLabel = Instance.new("TextLabel")
	cargoCostLabel.Name = "CargoCostLabel"
	cargoCostLabel.Size = UDim2.new(1, -20, 0, 25)
	cargoCostLabel.Position = UDim2.new(0, 10, 0, 80)
	cargoCostLabel.BackgroundTransparency = 1
	cargoCostLabel.Text = "Next Upgrade: £100"
	cargoCostLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	cargoCostLabel.TextSize = 16
	cargoCostLabel.Font = Enum.Font.Gotham
	cargoCostLabel.Parent = cargoFrame
	
	local cargoUpgradeButton = Instance.new("TextButton")
	cargoUpgradeButton.Name = "CargoUpgradeButton"
	cargoUpgradeButton.Size = UDim2.new(0, 120, 0, 35)
	cargoUpgradeButton.Position = UDim2.new(0, 10, 0, 105)
	cargoUpgradeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	cargoUpgradeButton.BorderSizePixel = 0
	cargoUpgradeButton.Text = "Upgrade"
	cargoUpgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cargoUpgradeButton.TextSize = 16
	cargoUpgradeButton.Font = Enum.Font.GothamBold
	cargoUpgradeButton.Parent = cargoFrame
	
	local cargoButtonCorner = Instance.new("UICorner")
	cargoButtonCorner.CornerRadius = UDim.new(0, 5)
	cargoButtonCorner.Parent = cargoUpgradeButton
	
	-- Fuel upgrade section
	local fuelFrame = Instance.new("Frame")
	fuelFrame.Name = "FuelFrame"
	fuelFrame.Size = UDim2.new(1, 0, 1, 0)
	fuelFrame.Position = UDim2.new(0, 0, 0, 0)
	fuelFrame.BackgroundTransparency = 1
	fuelFrame.Visible = false
	fuelFrame.Parent = contentFrame
	
	local fuelTitle = Instance.new("TextLabel")
	fuelTitle.Name = "FuelTitle"
	fuelTitle.Size = UDim2.new(1, -20, 0, 30)
	fuelTitle.Position = UDim2.new(0, 10, 0, 10)
	fuelTitle.BackgroundTransparency = 1
	fuelTitle.Text = "⛽ Fuel Capacity Upgrade"
	fuelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	fuelTitle.TextSize = 18
	fuelTitle.Font = Enum.Font.GothamBold
	fuelTitle.Parent = fuelFrame
	
	local fuelInfo = Instance.new("TextLabel")
	fuelInfo.Name = "FuelInfo"
	fuelInfo.Size = UDim2.new(1, -20, 0, 40)
	fuelInfo.Position = UDim2.new(0, 10, 0, 40)
	fuelInfo.BackgroundTransparency = 1
	fuelInfo.Text = "Current Level: 1\nFuel Capacity: 1.00x (0% more capacity)"
	fuelInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	fuelInfo.TextSize = 14
	fuelInfo.Font = Enum.Font.Gotham
	fuelInfo.TextXAlignment = Enum.TextXAlignment.Left
	fuelInfo.Parent = fuelFrame
	
	local fuelCostLabel = Instance.new("TextLabel")
	fuelCostLabel.Name = "FuelCostLabel"
	fuelCostLabel.Size = UDim2.new(1, -20, 0, 25)
	fuelCostLabel.Position = UDim2.new(0, 10, 0, 80)
	fuelCostLabel.BackgroundTransparency = 1
	fuelCostLabel.Text = "Next Upgrade: £100"
	fuelCostLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	fuelCostLabel.TextSize = 16
	fuelCostLabel.Font = Enum.Font.Gotham
	fuelCostLabel.Parent = fuelFrame
	
	local fuelUpgradeButton = Instance.new("TextButton")
	fuelUpgradeButton.Name = "FuelUpgradeButton"
	fuelUpgradeButton.Size = UDim2.new(0, 120, 0, 35)
	fuelUpgradeButton.Position = UDim2.new(0, 10, 0, 105)
	fuelUpgradeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	fuelUpgradeButton.BorderSizePixel = 0
	fuelUpgradeButton.Text = "Upgrade"
	fuelUpgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	fuelUpgradeButton.TextSize = 16
	fuelUpgradeButton.Font = Enum.Font.GothamBold
	fuelUpgradeButton.Parent = fuelFrame
	
	local fuelButtonCorner = Instance.new("UICorner")
	fuelButtonCorner.CornerRadius = UDim.new(0, 5)
	fuelButtonCorner.Parent = fuelUpgradeButton
	
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
	
	return screenGui, mainFrame, moneyLabel, speedInfo, speedCostLabel, speedUpgradeButton, closeButton, speedTab, cargoTab, fuelTab, speedFrame, cargoFrame, fuelFrame, cargoInfo, cargoCostLabel, cargoUpgradeButton, fuelInfo, fuelCostLabel, fuelUpgradeButton
end

-- Create the GUI
local shopGui, mainFrame, moneyLabel, speedInfo, speedCostLabel, speedUpgradeButton, closeButton, speedTab, cargoTab, fuelTab, speedFrame, cargoFrame, fuelFrame, cargoInfo, cargoCostLabel, cargoUpgradeButton, fuelInfo, fuelCostLabel, fuelUpgradeButton = createShopGui()

-- Current selected upgrade type
local currentUpgradeType = "speed"

-- Update money display
local function updateMoneyDisplay()
	local money = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if money then
		moneyLabel.Text = "💰 £" .. money.Value
	end
end

-- Update upgrade information for specific type
local function updateUpgradeInfo(upgradeType)
	UpgradeEvent:FireServer("getInfo", upgradeType)
end

-- Update all upgrade information (for dynamic updates)
local function updateAllUpgradeInfo()
	if shopGui.Enabled then
		updateUpgradeInfo("speed")
		updateUpgradeInfo("cargo_capacity")
		updateUpgradeInfo("fuel_capacity")
	end
end

-- Monitor player level changes for dynamic GUI updates
local function setupLevelMonitoring()
	local upgradeStats = player:WaitForChild("UpgradeStats", 10)
	if not upgradeStats then return end
	
	-- Monitor speed level changes
	local speedLevel = upgradeStats:WaitForChild("SpeedLevel", 5)
	if speedLevel then
		speedLevel.Changed:Connect(function(newLevel)
			if shopGui.Enabled and currentUpgradeType == "speed" then
				updateUpgradeInfo("speed")
				print("🚀 Speed level changed to:", newLevel, "- updating GUI")
			end
		end)
	end
	
	-- Monitor cargo level changes
	local cargoLevel = upgradeStats:WaitForChild("CargoLevel", 5)
	if cargoLevel then
		cargoLevel.Changed:Connect(function(newLevel)
			if shopGui.Enabled and currentUpgradeType == "cargo_capacity" then
				updateUpgradeInfo("cargo_capacity")
				print("📦 Cargo level changed to:", newLevel, "- updating GUI")
			end
		end)
	end
	
	-- Monitor fuel level changes
	local fuelLevel = upgradeStats:WaitForChild("FuelLevel", 5)
	if fuelLevel then
		fuelLevel.Changed:Connect(function(newLevel)
			if shopGui.Enabled and currentUpgradeType == "fuel_capacity" then
				updateUpgradeInfo("fuel_capacity")
				print("⛽ Fuel level changed to:", newLevel, "- updating GUI")
			end
		end)
	end
	
	print("✅ Level monitoring setup complete")
end

-- Switch to specific upgrade tab
local function switchToTab(upgradeType)
	-- Hide all frames
	speedFrame.Visible = false
	cargoFrame.Visible = false
	fuelFrame.Visible = false
	
	-- Reset all tab colors
	speedTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	cargoTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	fuelTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	
	-- Show selected frame and highlight tab
	if upgradeType == "speed" then
		speedFrame.Visible = true
		speedTab.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	elseif upgradeType == "cargo_capacity" then
		cargoFrame.Visible = true
		cargoTab.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	elseif upgradeType == "fuel_capacity" then
		fuelFrame.Visible = true
		fuelTab.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	end
	
	currentUpgradeType = upgradeType
	updateUpgradeInfo(upgradeType)
end

-- Handle upgrade info response
UpgradeEvent.OnClientEvent:Connect(function(action, data)
	if action == "upgradeInfo" then
		local percentageIncrease = math.floor((data.multiplier - 1) * 100)
		local infoText, costLabel, upgradeButton
		
		if currentUpgradeType == "speed" then
			infoText = speedInfo
			costLabel = speedCostLabel
			upgradeButton = speedUpgradeButton
			infoText.Text = string.format("Current Level: %d\nSpeed Multiplier: %.2fx (%d%% faster)", data.currentLevel, data.multiplier, percentageIncrease)
		elseif currentUpgradeType == "cargo_capacity" then
			infoText = cargoInfo
			costLabel = cargoCostLabel
			upgradeButton = cargoUpgradeButton
			infoText.Text = string.format("Current Level: %d\nCargo Capacity: %.2fx (%d%% more capacity)", data.currentLevel, data.multiplier, percentageIncrease)
		elseif currentUpgradeType == "fuel_capacity" then
			infoText = fuelInfo
			costLabel = fuelCostLabel
			upgradeButton = fuelUpgradeButton
			infoText.Text = string.format("Current Level: %d\nFuel Capacity: %.2fx (%d%% more capacity)", data.currentLevel, data.multiplier, percentageIncrease)
		end
		
		if data.nextCost then
			costLabel.Text = "Next Upgrade: £" .. data.nextCost
			upgradeButton.Visible = true
		else
			costLabel.Text = "MAX LEVEL REACHED!"
			upgradeButton.Visible = false
		end
	elseif action == "purchaseResult" then
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
			updateAllUpgradeInfo()  -- Update all tabs after purchase
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

-- Handle shop opening
ShopEvent.OnClientEvent:Connect(function(action)
	if action == "openShop" then
		shopGui.Enabled = true
		updateMoneyDisplay()
		
		-- Setup level monitoring if not already done
		coroutine.wrap(setupLevelMonitoring)()
		
		-- Update all upgrade info when shop opens
		updateAllUpgradeInfo()
		switchToTab(currentUpgradeType)
	end
end)

-- Handle button clicks
speedUpgradeButton.MouseButton1Click:Connect(function()
	UpgradeEvent:FireServer("purchase", "speed")
end)

cargoUpgradeButton.MouseButton1Click:Connect(function()
	UpgradeEvent:FireServer("purchase", "cargo_capacity")
end)

fuelUpgradeButton.MouseButton1Click:Connect(function()
	UpgradeEvent:FireServer("purchase", "fuel_capacity")
end)

-- Handle tab clicks
speedTab.MouseButton1Click:Connect(function()
	switchToTab("speed")
end)

cargoTab.MouseButton1Click:Connect(function()
	switchToTab("cargo_capacity")
end)

fuelTab.MouseButton1Click:Connect(function()
	switchToTab("fuel_capacity")
end)

closeButton.MouseButton1Click:Connect(function()
	shopGui.Enabled = false
end)

-- Close GUI with Escape key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Escape and shopGui.Enabled then
		shopGui.Enabled = false
	end
end)

-- Update money display periodically
coroutine.wrap(function()
	while true do
		task.wait(1)
		if shopGui.Enabled then
			updateMoneyDisplay()
		end
	end
end)()

print("Shop client initialized")

-- Setup level monitoring when script starts (for dynamic updates)
coroutine.wrap(setupLevelMonitoring)()
