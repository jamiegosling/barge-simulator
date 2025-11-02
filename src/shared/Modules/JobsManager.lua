-- JobsManager Module
-- Now uses dynamic resource-based job generation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ResourceManager = require(ReplicatedStorage.Shared.Modules.ResourceManager)

local JobsManager = {}

-- Initialize the resource manager
ResourceManager:Initialize()

-- Get all available jobs (now dynamically generated)
function JobsManager:GetAllJobs()
	return ResourceManager:GetAvailableJobs()
end

-- Get job by ID (searches through dynamic jobs)
function JobsManager:GetJobById(id)
	local jobs = self:GetAllJobs()
	for _, job in ipairs(jobs) do
		if job.id == id then
			return job
		end
	end
	return nil
end

-- Get resource status for debugging/UI
function JobsManager:GetResourceStatus()
	return ResourceManager:GetResourceStatus()
end

-- Handle job completion (update resources)
function JobsManager:CompleteJob(job)
	if job and job.cargo and job.from and job.to and job.loadSize then
		-- Remove resources from pickup location
		ResourceManager:RemoveResources(job.from, job.cargo, job.loadSize)
		-- Add resources to delivery location
		ResourceManager:AddResources(job.to, job.cargo, job.loadSize)
		return true
	end
	return false
end

return JobsManager
