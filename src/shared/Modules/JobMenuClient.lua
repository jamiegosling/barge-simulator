local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local JobPicked = ReplicatedStorage:WaitForChild("JobPicked")
local JobStatus = ReplicatedStorage:WaitForChild("JobStatus")
local JobsManager = require(ReplicatedStorage.Shared.Modules.JobsManager)

-- Create job menu GUI
local function createJobMenuGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JobMenuGui"
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
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "📦 Available Jobs 📦"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
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
	
	-- Job list frame with scrolling
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "JobListFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -80)
	scrollFrame.Position = UDim2.new(0, 10, 0, 60)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 12
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = mainFrame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 5)
	scrollCorner.Parent = scrollFrame
	
	-- Layout for job buttons
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scrollFrame
	
	-- Job template (hidden)
	local jobTemplate = Instance.new("TextButton")
	jobTemplate.Name = "JobTemplate"
	jobTemplate.Size = UDim2.new(1, -10, 0, 60)
	jobTemplate.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	jobTemplate.BorderSizePixel = 0
	jobTemplate.Text = ""
	jobTemplate.Visible = false
	jobTemplate.Parent = scrollFrame
	
	local templateCorner = Instance.new("UICorner")
	templateCorner.CornerRadius = UDim.new(0, 5)
	templateCorner.Parent = jobTemplate
	
	-- Job title label
	local jobTitle = Instance.new("TextLabel")
	jobTitle.Name = "JobTitle"
	jobTitle.Size = UDim2.new(1, -20, 0, 30)
	jobTitle.Position = UDim2.new(0, 10, 0, 5)
	jobTitle.BackgroundTransparency = 1
	jobTitle.Text = "Job Name"
	jobTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	jobTitle.TextSize = 16
	jobTitle.Font = Enum.Font.GothamBold
	jobTitle.TextXAlignment = Enum.TextXAlignment.Left
	jobTitle.Parent = jobTemplate
	
	-- Job details label
	local jobDetails = Instance.new("TextLabel")
	jobDetails.Name = "JobDetails"
	jobDetails.Size = UDim2.new(1, -20, 0, 25)
	jobDetails.Position = UDim2.new(0, 10, 0, 30)
	jobDetails.BackgroundTransparency = 1
	jobDetails.Text = "Details"
	jobDetails.TextColor3 = Color3.fromRGB(200, 200, 200)
	jobDetails.TextSize = 14
	jobDetails.Font = Enum.Font.Gotham
	jobDetails.TextXAlignment = Enum.TextXAlignment.Left
	jobDetails.Parent = jobTemplate
	
	-- Initially hide the GUI
	screenGui.Enabled = false
	
	return screenGui, mainFrame, scrollFrame, jobTemplate, closeButton, layout
end

-- Create the GUI
local jobMenuGui, mainFrame, scrollFrame, jobTemplate, closeButton, layout = createJobMenuGui()

-- Current job status
local currentStatusLabel = nil

-- Current job state
local isOnJob = false

-- Update pick button visibility based on job state
local function updatePickButtonVisibility()
	local pickButton = playerGui:FindFirstChild("JobMenu") and playerGui.JobMenu:FindFirstChild("PickJobButton")
	if pickButton then
		pickButton.Visible = not isOnJob
	end
end

-- Create job status label
local function createStatusLabel()
	if currentStatusLabel then return end
	
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "JobStatusLabel"
	statusLabel.Size = UDim2.new(0, 400, 0, 40)
	statusLabel.Position = UDim2.new(0.5, -200, 0, 10)
	statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	statusLabel.BorderSizePixel = 0
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.TextSize = 16
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Visible = false
	statusLabel.Parent = playerGui
	
	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 5)
	statusCorner.Parent = statusLabel
	
	currentStatusLabel = statusLabel
end

-- Create job button
local function createJobButton(job)
	local newButton = jobTemplate:Clone()
	newButton.Visible = true
	newButton.LayoutOrder = job.id
	newButton.Name = "JobButton_" .. job.id
	
	local jobTitle = newButton:FindFirstChild("JobTitle")
	local jobDetails = newButton:FindFirstChild("JobDetails")
	
	if jobTitle then
		jobTitle.Text = "📦 " .. job.name
	end
	
	if jobDetails then
		jobDetails.Text = string.format("From: %s → To: %s  |  💰 £%d", job.from, job.to, job.reward)
	end
	
	newButton.Parent = scrollFrame
	
	newButton.MouseButton1Click:Connect(function()
		print("Selected job:", job.name)
		JobPicked:FireServer(job.id)
		
		-- Set job state and update UI
		isOnJob = true
		updatePickButtonVisibility()
		
		-- Hide menu
		jobMenuGui.Enabled = false
	end)
	
	return newButton
end

-- Open job menu
local function openJobMenu()
	-- Clear any old job buttons (except the template)
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") and child ~= jobTemplate then
			child:Destroy()
		end
	end
	
	-- Populate from JobsManager
	local jobs = JobsManager:GetAllJobs()
	for _, job in ipairs(jobs) do
		createJobButton(job)
	end
	
	-- Update scroll frame size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #jobs * 65 + 10)
	
	-- Show menu
	jobMenuGui.Enabled = true
end

-- Close job menu
local function closeJobMenu()
	jobMenuGui.Enabled = false
end

-- Handle job status updates
JobStatus.OnClientEvent:Connect(function(state, job)
	createStatusLabel()
	
	isOnJob = (state == "accepted" or state == "loaded")
	updatePickButtonVisibility()
	
	if currentStatusLabel then
		if state == "accepted" then
			currentStatusLabel.Visible = true
			currentStatusLabel.Text = "📦 Current Job: " .. job.name .. " (" .. job.from .. " → " .. job.to .. ")"
		elseif state == "loaded" then
			currentStatusLabel.Visible = true
			currentStatusLabel.Text = "⚓ Loaded: " .. job.name .. " (" .. job.from .. " → " .. job.to .. ")"
		elseif state == "completed" then
			currentStatusLabel.Visible = true
			currentStatusLabel.Text = "✅ Completed!!: " .. job.name
			task.wait(3)
			currentStatusLabel.Visible = false
			isOnJob = false
			updatePickButtonVisibility()
		end
	end
end)

-- Handle button clicks
closeButton.MouseButton1Click:Connect(closeJobMenu)

-- Close GUI with Escape key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Escape and jobMenuGui.Enabled then
		closeJobMenu()
	end
end)

-- Export functions for other scripts
return {
	openJobMenu = openJobMenu,
	closeJobMenu = closeJobMenu,
	createJobButton = createJobButton
}
