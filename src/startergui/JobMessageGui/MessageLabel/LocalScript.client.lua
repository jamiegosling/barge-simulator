local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JobMessage = ReplicatedStorage:WaitForChild("JobMessage")
local label = script.Parent

label.Text = ""

-- Optional: fade out effect
local function showMessage(text)
	label.Text = text
	label.Visible = true
	wait(3)
	label.Visible = false
end

JobMessage.OnClientEvent:Connect(function(text)
	showMessage(text)
end)
