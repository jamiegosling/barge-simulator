-- ResourceManager Module
-- Tracks resource supply and demand at different destinations
-- Manages dynamic pricing based on resource availability

local ResourceManager = {}

-- Pre-calculated distance matrix (in game units)
-- Only this is needed since we're manually specifying all distances
ResourceManager.DISTANCE_MATRIX = {
	London = {
		Leeds = 220, -- ~200 miles in game units
		Bristol = 350  -- ~120 miles in game units
	},
	Leeds = {
		London = 220,
		Bristol = 280  -- ~170 miles in game units
	},
	Bristol = {
		London = 350,
		Leeds = 280
	}
}

-- Resource types configuration
ResourceManager.RESOURCE_TYPES = {
	coal = {
		name = "Coal",
		basePrice = 500,
		volatility = 0.3, -- How much price can vary (30%)
		maxStock = 1000,
		minStock = 100
	},
	steel = {
		name = "Steel",
		basePrice = 700,
		volatility = 0.25,
		maxStock = 800,
		minStock = 50
	},
	grain = {
		name = "Grain",
		basePrice = 600,
		volatility = 0.2,
		maxStock = 1200,
		minStock = 100
	}
}

-- Destination configuration with resource consumption rates
ResourceManager.DESTINATIONS = {
	London = {
		resources = {
			coal = { consumptionRate = 2, currentStock = 500 }, -- consumes 2 units per minute
			grain = { consumptionRate = 3, currentStock = 600 }, -- consumes 3 units per minute
			steel = { consumptionRate = 1, currentStock = 400 }
		},
		produces = {
			steel = { productionRate = 1 } -- produces 1 unit per minute
		}
	},
	Leeds = {
		resources = {
			coal = { consumptionRate = 1, currentStock = 700 },
			grain = { consumptionRate = 2, currentStock = 400 },
			steel = { consumptionRate = 4, currentStock = 200 }
		},
		produces = {
			coal = { productionRate = 3 }, -- produces 3 units per minute
			grain = { productionRate = 2 }
		}
	},
	Bristol = {
		resources = {
			coal = { consumptionRate = 3, currentStock = 300 },
			grain = { consumptionRate = 1, currentStock = 800 },
			steel = { consumptionRate = 2, currentStock = 300 }
		},
		produces = {
			grain = { productionRate = 4 }, -- produces 4 units per minute
			coal = { productionRate = 1 }
		}
	}
}

-- Initialize the resource manager
function ResourceManager:Initialize()
	self:StartResourceSimulation()
end

-- Calculate distance between two destinations
function ResourceManager:GetDistance(from, to)
	if from == to then
		return 0
	end
	
	-- Return distance from matrix
	return self.DISTANCE_MATRIX[from] and self.DISTANCE_MATRIX[from][to] or 100
end

-- Get distance multiplier for pricing
function ResourceManager:GetDistanceMultiplier(distance)
	-- Base multiplier of 1.0, increases with distance
	-- Formula: 1 + (distance / 1000) * 0.5
	-- This means 1000 distance = 1.5x multiplier
	return 1 + (distance / 1000) * 0.5
end

-- Get current stock of a resource at a destination
function ResourceManager:GetStock(destination, resourceType)
	if not self.DESTINATIONS[destination] then
		return 0
	end
	
	local resourceData = self.DESTINATIONS[destination].resources[resourceType]
	if not resourceData then
		return 0
	end
	
	return resourceData.currentStock
end

-- Set stock of a resource at a destination (used when deliveries are made)
function ResourceManager:SetStock(destination, resourceType, amount)
	if not self.DESTINATIONS[destination] then
		return
	end
	
	if not self.DESTINATIONS[destination].resources[resourceType] then
		return
	end
	
	local resourceData = self.DESTINATIONS[destination].resources[resourceType]
	local resourceConfig = self.RESOURCE_TYPES[resourceType]
	
	if resourceConfig then
		resourceData.currentStock = math.max(0, math.min(resourceConfig.maxStock, amount))
	end
end

-- Add resources to a destination (when cargo is delivered)
function ResourceManager:AddResources(destination, resourceType, amount)
	local currentStock = self:GetStock(destination, resourceType)
	self:SetStock(destination, resourceType, currentStock + amount)
end

-- Remove resources from a destination (when cargo is picked up)
function ResourceManager:RemoveResources(destination, resourceType, amount)
	local currentStock = self:GetStock(destination, resourceType)
	self:SetStock(destination, resourceType, currentStock - amount)
end

-- Calculate dynamic price based on supply and demand
function ResourceManager:GetPrice(destination, resourceType)
	local resourceConfig = self.RESOURCE_TYPES[resourceType]
	if not resourceConfig then
		return 0
	end
	
	local currentStock = self:GetStock(destination, resourceType)
	local maxStock = resourceConfig.maxStock
	local minStock = resourceConfig.minStock
	local basePrice = resourceConfig.basePrice
	local volatility = resourceConfig.volatility
	
	-- Calculate supply/demand ratio (0 = high demand, 1 = high supply)
	local supplyRatio = (currentStock - minStock) / (maxStock - minStock)
	supplyRatio = math.max(0, math.min(1, supplyRatio))
	
	-- Price inversely proportional to supply (higher demand = higher price)
	local demandMultiplier = 1 + (1 - supplyRatio) * volatility * 2
	
	-- Calculate final price
	local finalPrice = math.floor(basePrice * demandMultiplier)
	
	return finalPrice
end

-- Cargo size configurations
ResourceManager.CARGO_SIZES = {
	{size = 100, multiplier = 1.0, label = "Small"},
	{size = 110, multiplier = 1.8, label = "Medium"},
	{size = 120, multiplier = 2.5, label = "Large"},
	{size = 130, multiplier = 3.2, label = "Extra Large"}
}

-- Get all available jobs with dynamic pricing and distance bonuses
function ResourceManager:GetAvailableJobs()
	local jobs = {}
	local jobId = 1
	
	-- Generate jobs from each destination that produces resources
	for fromDestination, fromData in pairs(self.DESTINATIONS) do
		-- Check what this destination produces
		for resourceType, productionData in pairs(fromData.produces or {}) do
			-- Find destinations that need this resource
			for toDestination, toData in pairs(self.DESTINATIONS) do
				if toDestination ~= fromDestination and toData.resources[resourceType] then
					-- Check if destination has enough stock to create a job
					local availableStock = self:GetStock(fromDestination, resourceType)
					if availableStock > 50 then -- Minimum stock to create a job
						-- Calculate base price from resource demand
						local basePrice = self:GetPrice(toDestination, resourceType)
						
						-- Calculate distance and distance multiplier
						local distance = self:GetDistance(fromDestination, toDestination)
						local distanceMultiplier = self:GetDistanceMultiplier(distance)
						
						-- Generate jobs with different cargo sizes
						for _, cargoConfig in ipairs(self.CARGO_SIZES) do
							-- Only create job if enough stock available
							if availableStock >= cargoConfig.size then
								local loadSize = cargoConfig.size
								local cargoMultiplier = cargoConfig.multiplier
								
								-- Calculate final reward: base price * distance * cargo size multiplier
								local finalReward = math.floor(basePrice * distanceMultiplier * cargoMultiplier)
								
								table.insert(jobs, {
									id = jobId,
									name = string.format("%s to %s", self.RESOURCE_TYPES[resourceType].name, toDestination),
									from = fromDestination,
									to = toDestination,
									cargo = resourceType,
									loadSize = loadSize,
									cargoSize = loadSize, -- Required cargo capacity for this job
									cargoLabel = cargoConfig.label,
									reward = finalReward,
									distance = distance,
									baseReward = basePrice,
									distanceBonus = finalReward - basePrice,
									availableStock = availableStock
								})
								jobId = jobId + 1
							end
						end
					end
				end
			end
		end
	end
	
	return jobs
end

-- Start the resource simulation (consumption and production)
function ResourceManager:StartResourceSimulation()
	-- Update resources every 30 seconds (simulating per-minute rates)
	spawn(function()
		while true do
			wait(30) -- 30 seconds = 1 minute in game time
			self:UpdateResources()
		end
	end)
end

-- Update all resources based on consumption and production rates
function ResourceManager:UpdateResources()
	for destination, data in pairs(self.DESTINATIONS) do
		-- Process consumption
		for resourceType, resourceData in pairs(data.resources or {}) do
			if resourceData.consumptionRate then
				local currentStock = self:GetStock(destination, resourceType)
				local newStock = currentStock - resourceData.consumptionRate
				self:SetStock(destination, resourceType, newStock)
			end
		end
		
		-- Process production
		for resourceType, productionData in pairs(data.produces or {}) do
			if productionData.productionRate then
				local currentStock = self:GetStock(destination, resourceType)
				local newStock = currentStock + productionData.productionRate
				self:SetStock(destination, resourceType, newStock)
			end
		end
	end
end

-- Get resource status for debugging/UI purposes
function ResourceManager:GetResourceStatus()
	local status = {}
	
	for destination, data in pairs(self.DESTINATIONS) do
		status[destination] = {
			resources = {},
			produces = {}
		}
		
		for resourceType, resourceData in pairs(data.resources or {}) do
			status[destination].resources[resourceType] = {
				stock = resourceData.currentStock,
				price = self:GetPrice(destination, resourceType),
				consumptionRate = resourceData.consumptionRate or 0
			}
		end
		
		for resourceType, productionData in pairs(data.produces or {}) do
			status[destination].produces[resourceType] = {
				productionRate = productionData.productionRate or 0
			}
		end
	end
	
	return status
end

return ResourceManager