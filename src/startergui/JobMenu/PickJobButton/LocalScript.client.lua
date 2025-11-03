local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JobPicked = ReplicatedStorage:WaitForChild("JobPicked")
local JobStatus = ReplicatedStorage:WaitForChild("JobStatus")
local JobsManager = require(ReplicatedStorage.Shared.Modules.JobsManager)

local JobMenuClient = require(ReplicatedStorage.Shared.Modules.JobMenuClient)

local gui = script.Parent.Parent
local pickButton = gui:WaitForChild("PickJobButton")

pickButton.MouseButton1Click:Connect(function()
	JobMenuClient.openJobMenu()
end)
