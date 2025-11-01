-- JobsManager Module
local JobsManager = {}

JobsManager.Jobs = {
	{ id = 1, name = "Coal to Leeds", from = "London", to = "Leeds", reward = 500 },
	{ id = 2, name = "Steel to Bristol", from = "Leeds", to = "Bristol", reward = 700 },
	{ id = 3, name = "Grain to London", from = "Leeds", to = "London", reward = 600 },
}

function JobsManager:GetAllJobs()
	return self.Jobs
end

function JobsManager:GetJobById(id)
	for _, job in ipairs(self.Jobs) do
		if job.id == id then
			return job
		end
	end
end

return JobsManager
