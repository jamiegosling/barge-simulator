local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JobPicked = ReplicatedStorage:WaitForChild("JobPicked")
local JobStatus = ReplicatedStorage:WaitForChild("JobStatus")
local JobsManager = require(ReplicatedStorage.Shared.Modules.JobsManager)

local gui = script.Parent.Parent
local pickButton = gui:WaitForChild("PickJobButton")
local jobListFrame = gui:WaitForChild("JobListFrame")
local jobTemplate = jobListFrame:WaitForChild("JobTemplate")
local statusLabel = gui:WaitForChild("JobStatusLabel")

local function createJobButton(job)
	local newButton = jobTemplate:Clone()
	newButton.Visible = true
	newButton.Text = string.format("📦 %s (%s → %s)  |  💰 £%d", job.name, job.from, job.to, job.reward)
	newButton.Parent = jobListFrame

	newButton.MouseButton1Click:Connect(function()
		print("Selected job:", job.name)
		JobPicked:FireServer(job.id)

		-- Hide menu
		jobListFrame.Visible = false
		pickButton.Visible = false
	end)
end

pickButton.MouseButton1Click:Connect(function()
	if jobListFrame.Visible then
		jobListFrame.Visible = false
	else
		jobListFrame.Visible = true

		-- Clear any old job buttons (except the template)
		for _, child in ipairs(jobListFrame:GetChildren()) do
			if child:IsA("TextButton") and child ~= jobTemplate then
				child:Destroy()
			end
		end

		-- Populate from JobsManager
		for _, job in ipairs(JobsManager:GetAllJobs()) do
			createJobButton(job)
		end
	end
end)

-- Handle job status updates
JobStatus.OnClientEvent:Connect(function(state, job)
	if state == "accepted" then
		statusLabel.Visible = true
		statusLabel.Text = "📦 Current Job: " .. job.name .. " (" .. job.from .. " → " .. job.to .. ")"
	elseif state == "loaded" then
		statusLabel.Visible = true
		statusLabel.Text = "⚓ Loaded: " .. job.name .. " (" .. job.from .. " → " .. job.to .. ")"
	elseif state == "completed" then
		statusLabel.Visible = true
		statusLabel.Text = "✅ Completed!!: " .. job.name
		task.wait(3)
		statusLabel.Visible = false
		pickButton.Visible = true
	end
end)
