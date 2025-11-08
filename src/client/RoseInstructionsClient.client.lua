local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local RoseEvent = ReplicatedStorage:WaitForChild("RoseEvent")

-- Create instructions GUI
local function createInstructionsGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RoseInstructionsGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame
	
	-- Title bar with Rose theme
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 60)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 10)
	titleCorner.Parent = titleBar
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🌹 Rose's Game Instructions 🌹"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = titleBar
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 5)
	closeCorner.Parent = closeButton
	
	-- Instructions content frame (scrollable)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "InstructionsFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -80)
	scrollFrame.Position = UDim2.new(0, 10, 0, 70)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 12
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = mainFrame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 5)
	scrollCorner.Parent = scrollFrame
	
	-- Layout for instructions
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scrollFrame
	
	-- Instructions sections
	local instructions = {
		{
			title = "🚤 Getting Started",
			content = [[Welcome to Barge Simulator! Your adventure begins at the docks where you can start your career as a barge captain.

1. Look for your boat - it has your name above it
2. Click on [Pick Job] to find available delivery jobs
3. Fuel up your boat at the fuel stations - if you run out, you go slowly
4. Pick up cargo and deliver it to earn money!]],
			layoutOrder = 1
		},
		{
			title = "📦 Jobs & Deliveries",
			content = [[Making money is essential for upgrading your boat:

• Each job shows: pickup location, destination, cargo size, and reward
• Larger cargo gets you more money, but you need to upgrade your boat capacity]],
			layoutOrder = 2
		},
		{
			title = "⚓ Boat Upgrades",
			content = [[Upgrade your boat at the shop to improve performance:

🚀 Speed Upgrades: Travel faster and complete jobs quicker
📦 Cargo Upgrades: Carry larger loads for bigger rewards
⛽ Fuel Upgrades: Extend your range without refueling

Each upgrade level costs more but provides better performance!]],
			layoutOrder = 3
		},
		{
			title = "⛽ Fuel Management",
			content = [[Keep your boat running efficiently:

• Monitor your fuel gauge during trips
• Plan routes to include fuel stops
• Fuel capacity upgrades mean you need to fill up less
• Try not to run out of fuel or you slow down]],
			layoutOrder = 4
		},
		{
			title = "💰 Making Money",
			content = [[Maximize your earnings:

• Upgrade speed to complete jobs faster
• Upgrade cargo capacity to take bigger loads for more money]],
			layoutOrder = 5
		}
	}
	
	-- Create instruction sections
	for _, instruction in ipairs(instructions) do
		-- Section container
		local sectionFrame = Instance.new("Frame")
		sectionFrame.Name = "Section_" .. instruction.layoutOrder
		sectionFrame.Size = UDim2.new(1, -10, 0, 120)
		sectionFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		sectionFrame.BorderSizePixel = 0
		sectionFrame.LayoutOrder = instruction.layoutOrder
		sectionFrame.Parent = scrollFrame
		
		local sectionCorner = Instance.new("UICorner")
		sectionCorner.CornerRadius = UDim.new(0, 5)
		sectionCorner.Parent = sectionFrame
		
		-- Section title
		local sectionTitle = Instance.new("TextLabel")
		sectionTitle.Name = "SectionTitle"
		sectionTitle.Size = UDim2.new(1, -20, 0, 30)
		sectionTitle.Position = UDim2.new(0, 10, 0, 5)
		sectionTitle.BackgroundTransparency = 1
		sectionTitle.Text = instruction.title
		sectionTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
		sectionTitle.TextSize = 18
		sectionTitle.Font = Enum.Font.GothamBold
		sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
		sectionTitle.Parent = sectionFrame
		
		-- Section content
		local sectionContent = Instance.new("TextLabel")
		sectionContent.Name = "SectionContent"
		sectionContent.Size = UDim2.new(1, -20, 1, -35)
		sectionContent.Position = UDim2.new(0, 10, 0, 35)
		sectionContent.BackgroundTransparency = 1
		sectionContent.Text = instruction.content
		sectionContent.TextColor3 = Color3.fromRGB(200, 200, 200)
		sectionContent.TextSize = 14
		sectionContent.Font = Enum.Font.Gotham
		sectionContent.TextXAlignment = Enum.TextXAlignment.Left
		sectionContent.TextYAlignment = Enum.TextYAlignment.Top
		sectionContent.TextWrapped = true
		sectionContent.Parent = sectionFrame
	end
	
	-- Update scroll frame size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #instructions * 130 + 20)
	
	-- Initially hide the GUI
	screenGui.Enabled = false
	
	return screenGui, mainFrame, closeButton
end

-- Create the GUI
local instructionsGui, mainFrame, closeButton = createInstructionsGui()

-- Handle Rose event
RoseEvent.OnClientEvent:Connect(function(action)
	if action == "openInstructions" then
		instructionsGui.Enabled = true
	end
end)

-- Handle close button
closeButton.MouseButton1Click:Connect(function()
	instructionsGui.Enabled = false
end)

-- Close GUI with Escape key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Escape and instructionsGui.Enabled then
		instructionsGui.Enabled = false
	end
end)

print("RoseInstructionsClient initialized")
