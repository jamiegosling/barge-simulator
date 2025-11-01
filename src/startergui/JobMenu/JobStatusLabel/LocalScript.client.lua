local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JobStatus = ReplicatedStorage:WaitForChild("JobStatus")

local statusLabel = script.Parent

-- Handle job status updates
JobStatus.OnClientEvent:Connect(function(state, job)
	if state == "accepted" then
		statusLabel.Visible = true
		statusLabel.Text = "📦 Go to " .. job.from .. " to load your boat"
	elseif state == "loaded" then
		statusLabel.Visible = true
		statusLabel.Text = "⚓ Deliver to " .. job.to
	elseif state == "completed" then
		statusLabel.Visible = true
		statusLabel.Text = "✅ Job Completed!"
		task.wait(3)
		statusLabel.Visible = false
	end
end)