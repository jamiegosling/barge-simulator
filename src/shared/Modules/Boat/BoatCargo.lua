-- BoatCargo.lua
-- Handles cargo capacity management

local BoatCargo = {}

-- ==================== MODULE STATE ==================== --
local currentCargo = 0
local maxCargo = 100
local baseMaxCargo = 100

-- ==================== PUBLIC FUNCTIONS ==================== --

function BoatCargo.Initialize(config)
	-- Config contains: boat, script, baseMaxCargo, initialCargo
	BoatCargo.boat = config.boat
	BoatCargo.script = config.script
	
	baseMaxCargo = config.baseMaxCargo or 100
	maxCargo = baseMaxCargo
	
	-- Set initial cargo values
	local OriginalCargoCapacity = config.script:FindFirstChild("OriginalCargoCapacity")
	if OriginalCargoCapacity then
		baseMaxCargo = OriginalCargoCapacity.Value
	end
	
	local CargoMultiplier = config.script:FindFirstChild("CargoMultiplier")
	if CargoMultiplier then
		maxCargo = baseMaxCargo * CargoMultiplier.Value
	else
		maxCargo = baseMaxCargo
	end
	
	local InitialCargo = config.script:FindFirstChild("InitialCargo")
	if InitialCargo then
		currentCargo = InitialCargo.Value
	else
		currentCargo = config.baseCurrentCargo or 0
	end
end

function BoatCargo.Update()
	local currentMultiplier = BoatCargo.script:FindFirstChild("CargoMultiplier")
	if currentMultiplier then
		maxCargo = baseMaxCargo * currentMultiplier.Value
	else
		maxCargo = baseMaxCargo
	end
	
	-- Update current cargo from boat if it exists
	local cargoAmount = BoatCargo.boat:FindFirstChild("CargoAmount")
	if cargoAmount then
		currentCargo = cargoAmount.Value
	end
end

function BoatCargo.GetCurrentCargo()
	return currentCargo
end

function BoatCargo.GetMaxCargo()
	return maxCargo
end

function BoatCargo.GetValues()
	local cargoAmount = BoatCargo.boat:FindFirstChild("CargoAmount")
	local maxCargoValue = BoatCargo.boat:FindFirstChild("MaxCargo")
	local originalCargo = BoatCargo.boat:FindFirstChild("OriginalCargoCapacity")
	local cargoMultiplier = BoatCargo.script:FindFirstChild("CargoMultiplier")

	local values = {}
	
	if cargoAmount then
		values.currentCargo = cargoAmount.Value
	else
		values.currentCargo = currentCargo
	end

	if maxCargoValue then
		values.maxCargo = maxCargoValue.Value
	elseif originalCargo and cargoMultiplier then
		values.maxCargo = originalCargo.Value * cargoMultiplier.Value
	else
		values.maxCargo = maxCargo
	end
	
	return values
end

return BoatCargo
