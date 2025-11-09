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

-- Cargo type colors
local CARGO_COLORS = {
	coal = Color3.fromRGB(60, 60, 60), -- Dark gray for coal
	steel = Color3.fromRGB(120, 120, 140), -- Blue-gray for steel
	grain = Color3.fromRGB(180, 140, 80) -- Golden brown for grain
}

-- Current sort option
local currentSort = "reward" -- default sort by reward

-- Current filter option
local currentFilter = "all" -- default show all locations

-- Create job menu GUI
local function createJobMenuGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JobMenuGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 550) -- Increased height for sort dropdown
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -275)
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
	
	-- Sort dropdown frame
	local sortFrame = Instance.new("Frame")
	sortFrame.Name = "SortFrame"
	sortFrame.Size = UDim2.new(1, -20, 0, 35)
	sortFrame.Position = UDim2.new(0, 10, 0, 55)
	sortFrame.BackgroundTransparency = 1
	sortFrame.Parent = mainFrame
	
	-- Sort label
	local sortLabel = Instance.new("TextLabel")
	sortLabel.Name = "SortLabel"
	sortLabel.Size = UDim2.new(0, 60, 1, 0)
	sortLabel.Position = UDim2.new(0, 40, 0, 0) -- Moved right
	sortLabel.BackgroundTransparency = 1
	sortLabel.Text = "Sort by:"
	sortLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	sortLabel.TextSize = 14
	sortLabel.Font = Enum.Font.Gotham
	sortLabel.TextXAlignment = Enum.TextXAlignment.Left
	sortLabel.Parent = sortFrame
	
	-- Sort dropdown button
	local sortButton = Instance.new("TextButton")
	sortButton.Name = "SortButton"
	sortButton.Size = UDim2.new(0, 140, 1, 0) -- Slightly smaller to make room for filter
	sortButton.Position = UDim2.new(0, 110, 0, 0) -- Moved right
	sortButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	sortButton.BorderSizePixel = 0
	sortButton.Text = "Reward (High→Low)"
	sortButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sortButton.TextSize = 11
	sortButton.Font = Enum.Font.Gotham
	sortButton.Parent = sortFrame
	
	local sortButtonCorner = Instance.new("UICorner")
	sortButtonCorner.CornerRadius = UDim.new(0, 5)
	sortButtonCorner.Parent = sortButton
	
	-- Filter label
	local filterLabel = Instance.new("TextLabel")
	filterLabel.Name = "FilterLabel"
	filterLabel.Size = UDim2.new(0, 85, 1, 0)
	filterLabel.Position = UDim2.new(0, 270, 0, 0) -- Moved right
	filterLabel.BackgroundTransparency = 1
	filterLabel.Text = "Starting From:"
	filterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	filterLabel.TextSize = 14
	filterLabel.Font = Enum.Font.Gotham
	filterLabel.TextXAlignment = Enum.TextXAlignment.Left
	filterLabel.Parent = sortFrame
	
	-- Filter dropdown button
	local filterButton = Instance.new("TextButton")
	filterButton.Name = "FilterButton"
	filterButton.Size = UDim2.new(0, 120, 1, 0)
	filterButton.Position = UDim2.new(0, 360, 0, 0) -- Moved right to make room for label
	filterButton.BackgroundColor3 = Color3.fromRGB(80, 60, 80) -- Purple-ish color to distinguish from sort
	filterButton.BorderSizePixel = 0
	filterButton.Text = "All Locations"
	filterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	filterButton.TextSize = 11
	filterButton.Font = Enum.Font.Gotham
	filterButton.Parent = sortFrame
	
	local filterButtonCorner = Instance.new("UICorner")
	filterButtonCorner.CornerRadius = UDim.new(0, 5)
	filterButtonCorner.Parent = filterButton
	
	-- Sort dropdown menu (initially hidden)
	local sortDropdown = Instance.new("Frame")
	sortDropdown.Name = "SortDropdown"
	sortDropdown.Size = UDim2.new(0, 140, 0, 160) -- Increased height for new option
	sortDropdown.Position = UDim2.new(0, 100, 0, 95) -- Moved right to align with sort button
	sortDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	sortDropdown.BorderSizePixel = 0
	sortDropdown.Visible = false
	sortDropdown.ZIndex = 10 -- Ensure dropdown appears above other elements
	sortDropdown.Parent = mainFrame -- Parent to main frame to avoid clipping
	
	-- Filter dropdown menu (initially hidden)
	local filterDropdown = Instance.new("Frame")
	filterDropdown.Name = "FilterDropdown"
	filterDropdown.Size = UDim2.new(0, 120, 0, 200) -- Taller for more locations
	filterDropdown.Position = UDim2.new(0, 350, 0, 95) -- Moved right to align with filter button
	filterDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	filterDropdown.BorderSizePixel = 0
	filterDropdown.Visible = false
	filterDropdown.ZIndex = 10
	filterDropdown.Parent = mainFrame
	
	local dropdownCorner = Instance.new("UICorner")
	dropdownCorner.CornerRadius = UDim.new(0, 5)
	dropdownCorner.Parent = sortDropdown
	
	-- Sort options
	local sortOptions = {
		{text = "Reward (High→Low)", value = "reward"},
		{text = "Reward (Low→High)", value = "reward_low_high"},
		{text = "Start Location (A→Z)", value = "start_location"},
		{text = "Finish Location (A→Z)", value = "finish_location"}
	}
	
	local filterDropdownCorner = Instance.new("UICorner")
	filterDropdownCorner.CornerRadius = UDim.new(0, 5)
	filterDropdownCorner.Parent = filterDropdown
	
	-- Filter options (all locations plus "All")
	local filterOptions = {
		{text = "All Locations", value = "all"},
		{text = "London", value = "London"},
		{text = "Leeds", value = "Leeds"},
		{text = "Bristol", value = "Bristol"},
		{text = "Boatyard", value = "Boatyard"},
		{text = "Newcastle", value = "Newcastle"},
		{text = "Exeter", value = "Exeter"}
	}
	
	local sortOptionButtons = {}
	for i, option in ipairs(sortOptions) do
		local optionButton = Instance.new("TextButton")
		optionButton.Name = "SortOption_" .. option.value
		optionButton.Size = UDim2.new(1, -4, 0, 35)
		optionButton.Position = UDim2.new(0, 2, 0, (i-1) * 37 + 2)
		optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		optionButton.BorderSizePixel = 0
		optionButton.Text = option.text
		optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		optionButton.TextSize = 10
		optionButton.Font = Enum.Font.Gotham
		optionButton.ZIndex = 11 -- Ensure buttons appear above dropdown
		optionButton.Parent = sortDropdown
		
		local optionCorner = Instance.new("UICorner")
		optionCorner.CornerRadius = UDim.new(0, 3)
		optionCorner.Parent = optionButton
		
		sortOptionButtons[option.value] = optionButton
	end
	
	local filterOptionButtons = {}
	for i, option in ipairs(filterOptions) do
		local optionButton = Instance.new("TextButton")
		optionButton.Name = "FilterOption_" .. option.value
		optionButton.Size = UDim2.new(1, -4, 0, 25) -- Smaller height for more options
		optionButton.Position = UDim2.new(0, 2, 0, (i-1) * 27 + 2)
		optionButton.BackgroundColor3 = Color3.fromRGB(80, 60, 80)
		optionButton.BorderSizePixel = 0
		optionButton.Text = option.text
		optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		optionButton.TextSize = 10
		optionButton.Font = Enum.Font.Gotham
		optionButton.ZIndex = 11
		optionButton.Parent = filterDropdown
		
		local optionCorner = Instance.new("UICorner")
		optionCorner.CornerRadius = UDim.new(0, 3)
		optionCorner.Parent = optionButton
		
		filterOptionButtons[option.value] = optionButton
	end
	
	-- Job list frame with scrolling
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "JobListFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -120) -- Adjusted for sort dropdown
	scrollFrame.Position = UDim2.new(0, 10, 0, 100) -- Moved down for sort dropdown
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
	
	return screenGui, mainFrame, scrollFrame, jobTemplate, closeButton, layout, sortButton, sortDropdown, sortOptionButtons, filterButton, filterDropdown, filterOptionButtons
end

-- Create the GUI
local jobMenuGui, mainFrame, scrollFrame, jobTemplate, closeButton, layout, sortButton, sortDropdown, sortOptionButtons, filterButton, filterDropdown, filterOptionButtons = createJobMenuGui()

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

-- Get cargo color based on cargo type
local function getCargoColor(cargoType)
	return CARGO_COLORS[cargoType] or Color3.fromRGB(60, 60, 60) -- Default to coal color
end

-- Filter jobs based on current filter option
local function filterJobs(jobs)
	if currentFilter == "all" then
		return jobs
	else
		local filteredJobs = {}
		for _, job in ipairs(jobs) do
			if job.from == currentFilter then
				table.insert(filteredJobs, job)
			end
		end
		return filteredJobs
	end
end

-- Sort jobs based on current sort option
local function sortJobs(jobs)
	if currentSort == "reward" then
		table.sort(jobs, function(a, b) return a.reward > b.reward end)
	elseif currentSort == "reward_low_high" then
		table.sort(jobs, function(a, b) return a.reward < b.reward end)
	elseif currentSort == "start_location" then
		table.sort(jobs, function(a, b) return a.from < b.from end)
	elseif currentSort == "finish_location" then
		table.sort(jobs, function(a, b) return a.to < b.to end)
	end
	return jobs
end

-- Create job button
local function createJobButton(job, sortOrder)
	local newButton = jobTemplate:Clone()
	newButton.Visible = true
	newButton.LayoutOrder = sortOrder or job.id -- Use sortOrder if provided, otherwise use job.id
	newButton.Name = "JobButton_" .. job.id
	
	-- Set background color based on cargo type
	newButton.BackgroundColor3 = getCargoColor(job.cargo)
	
	local jobTitle = newButton:FindFirstChild("JobTitle")
	local jobDetails = newButton:FindFirstChild("JobDetails")
	
	if jobTitle then
		jobTitle.Text = "📦 " .. job.name .. " (" .. (job.cargoLabel or "Standard") .. ")"
	end
	
	if jobDetails then
		jobDetails.Text = string.format("From: %s → To: %s  |  Cargo: %d  |  💰 £%d", job.from, job.to, job.cargoSize or job.loadSize, job.reward)
	end
	
	newButton.Parent = scrollFrame
	
	newButton.MouseButton1Click:Connect(function()
		print("Selected job:", job.name)
		JobPicked:FireServer(job.id)
		
		-- Don't set isOnJob here - wait for server validation via JobStatus event
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
	print("DEBUG: Got", #jobs, "jobs before filtering/sorting")
	
	-- Filter jobs based on current filter option
	jobs = filterJobs(jobs)
	print("DEBUG: Filtered by", currentFilter, "- now have", #jobs, "jobs")
	
	-- Sort jobs based on current sort option
	jobs = sortJobs(jobs)
	print("DEBUG: Sorted by", currentSort)
	
	-- Create job buttons with proper sort order
	for i, job in ipairs(jobs) do
		createJobButton(job, i) -- Pass the index as sort order
		if i <= 3 then -- Debug first few jobs
			print("DEBUG: Job", i, ":", job.name, "Reward:", job.reward, "From:", job.from, "To:", job.to)
		end
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

-- Handle sort dropdown toggle
sortButton.MouseButton1Click:Connect(function()
	local newVisibility = not sortDropdown.Visible
	sortDropdown.Visible = newVisibility
	-- Hide filter dropdown if it's open
	if newVisibility then
		filterDropdown.Visible = false
	end
	print("DEBUG: Sort dropdown visibility toggled to:", newVisibility)
end)

-- Handle filter dropdown toggle
filterButton.MouseButton1Click:Connect(function()
	local newVisibility = not filterDropdown.Visible
	filterDropdown.Visible = newVisibility
	-- Hide sort dropdown if it's open
	if newVisibility then
		sortDropdown.Visible = false
	end
	print("DEBUG: Filter dropdown visibility toggled to:", newVisibility)
end)

-- Handle sort option selection
for sortValue, optionButton in pairs(sortOptionButtons) do
	optionButton.MouseButton1Click:Connect(function()
		print("DEBUG: Sort option clicked:", sortValue)
		currentSort = sortValue
		-- Update button text
		for _, option in ipairs({{text = "Reward (High→Low)", value = "reward"}, {text = "Reward (Low→High)", value = "reward_low_high"}, {text = "Start Location (A→Z)", value = "start_location"}, {text = "Finish Location (A→Z)", value = "finish_location"}}) do
			if option.value == sortValue then
				sortButton.Text = option.text
				print("DEBUG: Button text updated to:", option.text)
				break
			end
		end
		-- Hide dropdown
		sortDropdown.Visible = false
		-- Refresh job list with new sort
		if jobMenuGui.Enabled then
			print("DEBUG: Refreshing job menu with new sort")
			openJobMenu()
		end
	end)
end

-- Handle filter option selection
for filterValue, optionButton in pairs(filterOptionButtons) do
	optionButton.MouseButton1Click:Connect(function()
		print("DEBUG: Filter option clicked:", filterValue)
		currentFilter = filterValue
		-- Update button text
		for _, option in ipairs({{text = "All Locations", value = "all"}, {text = "London", value = "London"}, {text = "Leeds", value = "Leeds"}, {text = "Bristol", value = "Bristol"}, {text = "Boatyard", value = "Boatyard"}, {text = "Newcastle", value = "Newcastle"}, {text = "Exeter", value = "Exeter"}}) do
			if option.value == filterValue then
				filterButton.Text = option.text
				print("DEBUG: Filter button text updated to:", option.text)
				break
			end
		end
		-- Hide dropdown
		filterDropdown.Visible = false
		-- Refresh job list with new filter
		if jobMenuGui.Enabled then
			print("DEBUG: Refreshing job menu with new filter")
			openJobMenu()
		end
	end)
end

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
