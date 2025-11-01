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
	
	-- Money display
	local moneyFrame = Instance.new("Frame")
	moneyFrame.Name = "MoneyFrame"
	moneyFrame.Size = UDim2.new(1, -20, 0, 40)
	moneyFrame.Position = UDim2.new(0, 10, 0, 60)
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
	
	-- Speed upgrade section
	local speedFrame = Instance.new("Frame")
	speedFrame.Name = "SpeedFrame"
	speedFrame.Size = UDim2.new(1, -20, 0, 150)
	speedFrame.Position = UDim2.new(0, 10, 0, 120)
	speedFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	speedFrame.BorderSizePixel = 0
	speedFrame.Parent = mainFrame
	
	local speedCorner = Instance.new("UICorner")
	speedCorner.CornerRadius = UDim.new(0, 5)
	speedCorner.Parent = speedFrame
	
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
	speedInfo.Text = "Current Level: 1\nSpeed Multiplier: 1.0x"
	speedInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	speedInfo.TextSize = 14
	speedInfo.Font = Enum.Font.Gotham
	speedInfo.TextXAlignment = Enum.TextXAlignment.Left
	speedInfo.Parent = speedFrame
	
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Size = UDim2.new(1, -20, 0, 25)
	costLabel.Position = UDim2.new(0, 10, 0, 80)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = "Next Upgrade: £100"
	costLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	costLabel.TextSize = 16
	costLabel.Font = Enum.Font.Gotham
	costLabel.Parent = speedFrame
	
	local upgradeButton = Instance.new("TextButton")
	upgradeButton.Name = "UpgradeButton"
	upgradeButton.Size = UDim2.new(0, 120, 0, 35)
	upgradeButton.Position = UDim2.new(0, 10, 0, 105)
	upgradeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	upgradeButton.BorderSizePixel = 0
	upgradeButton.Text = "Upgrade"
	upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	upgradeButton.TextSize = 16
	upgradeButton.Font = Enum.Font.GothamBold
	upgradeButton.Parent = speedFrame
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 5)
	buttonCorner.Parent = upgradeButton
	
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
	
	return screenGui, mainFrame, moneyLabel, speedInfo, costLabel, upgradeButton, closeButton
end

-- Create the GUI
local shopGui, mainFrame, moneyLabel, speedInfo, costLabel, upgradeButton, closeButton = createShopGui()

-- Update money display
local function updateMoneyDisplay()
	local money = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if money then
		moneyLabel.Text = "💰 £" .. money.Value
	end
end

-- Update upgrade information
local function updateUpgradeInfo()
	UpgradeEvent:FireServer("getInfo", "speed")
end

-- Handle upgrade info response
UpgradeEvent.OnClientEvent:Connect(function(action, data)
	if action == "upgradeInfo" then
		speedInfo.Text = string.format("Current Level: %d\nSpeed Multiplier: %.1fx", data.currentLevel, data.speedMultiplier)
		
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
			updateUpgradeInfo()
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
		updateUpgradeInfo()
	end
end)

-- Handle button clicks
upgradeButton.MouseButton1Click:Connect(function()
	UpgradeEvent:FireServer("purchase", "speed")
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
