-- --[[
-- 	Fuel Shop Setup Example
	
-- 	This script shows how to create fuel shop models in your world.
-- 	You can place this script in ServerScriptService and modify it to create
-- 	fuel shops at specific locations in your game.
	
-- 	To use:
-- 	1. Copy this script to ServerScriptService
-- 	2. Modify the positions and models as needed
-- 	3. The FuelShopManager will automatically detect any model with "FuelShop" in the name
-- 	   or any model that has a "FuelShop" StringValue child
-- --]]

-- local Workspace = game:GetService("Workspace")

-- -- Example fuel shop locations (modify these for your map)
-- local fuelShopLocations = {
-- 	{
-- 		position = Vector3.new(100, 5, 100),
-- 		name = "FuelShop_Dock1"
-- 	},
-- 	{
-- 		position = Vector3.new(-200, 5, 150),
-- 		name = "FuelShop_Dock2"
-- 	},
-- 	{
-- 		position = Vector3.new(50, 5, -300),
-- 		name = "FuelShop_Dock3"
-- 	}
-- }

-- -- Function to create a simple fuel shop model
-- local function createFuelShopModel(location)
-- 	local fuelShop = Instance.new("Model")
-- 	fuelShop.Name = location.name
-- 	fuelShop.Parent = Workspace
	
-- 	-- Create a simple building
-- 	local base = Instance.new("Part")
-- 	base.Name = "Base"
-- 	base.Size = Vector3.new(12, 1, 12)
-- 	base.Position = location.position
-- 	base.Anchored = true
-- 	base.BrickColor = BrickColor.new("Dark grey")
-- 	base.Material = Enum.Material.Concrete
-- 	base.Parent = fuelShop
	
-- 	-- Create fuel pumps
-- 	local pump1 = Instance.new("Part")
-- 	pump1.Name = "Pump1"
-- 	pump1.Size = Vector3.new(2, 4, 2)
-- 	pump1.Position = location.position + Vector3.new(-3, 2.5, 0)
-- 	pump1.Anchored = true
-- 	pump1.BrickColor = BrickColor.new("Bright red")
-- 	pump1.Material = Enum.Material.Plastic
-- 	pump1.Parent = fuelShop
	
-- 	local pump2 = Instance.new("Part")
-- 	pump2.Name = "Pump2"
-- 	pump2.Size = Vector3.new(2, 4, 2)
-- 	pump2.Position = location.position + Vector3.new(3, 2.5, 0)
-- 	pump2.Anchored = true
-- 	pump2.BrickColor = BrickColor.new("Bright red")
-- 	pump2.Material = Enum.Material.Plastic
-- 	pump2.Parent = fuelShop
	
-- 	-- Add fuel signs
-- 	local sign = Instance.new("Part")
-- 	sign.Name = "Sign"
-- 	sign.Size = Vector3.new(8, 6, 0.5)
-- 	sign.Position = location.position + Vector3.new(0, 5, -6)
-- 	sign.Anchored = true
-- 	sign.BrickColor = BrickColor.new("White")
-- 	sign.Material = Enum.Material.Plastic
-- 	sign.Parent = fuelShop
	
-- 	-- Add fuel text to sign (using SurfaceGui)
-- 	local surfaceGui = Instance.new("SurfaceGui")
-- 	surfaceGui.Name = "FuelSign"
-- 	surfaceGui.Face = Enum.NormalId.Front
-- 	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
-- 	surfaceGui.PixelsPerStud = 50
-- 	surfaceGui.Parent = sign
	
-- 	local textLabel = Instance.new("TextLabel")
-- 	textLabel.Size = UDim2.new(1, 0, 1, 0)
-- 	textLabel.Position = UDim2.new(0, 0, 0, 0)
-- 	textLabel.BackgroundTransparency = 1
-- 	textLabel.Text = "⛽\nFUEL"
-- 	textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
-- 	textLabel.TextSize = 30
-- 	textLabel.Font = Enum.Font.GothamBold
-- 	textLabel.Parent = surfaceGui
	
-- 	-- Add a roof
-- 	local roof = Instance.new("Part")
-- 	roof.Name = "Roof"
-- 	roof.Size = Vector3.new(14, 0.5, 14)
-- 	roof.Position = location.position + Vector3.new(0, 6, 0)
-- 	roof.Anchored = true
-- 	roof.BrickColor = BrickColor.new("Medium grey")
-- 	roof.Material = EnumMaterial.Metal
-- 	roof.Parent = fuelShop
	
-- 	-- Add the FuelShop tag (this is what the FuelShopManager looks for)
-- 	local fuelShopTag = Instance.new("StringValue")
-- 	fuelShopTag.Name = "FuelShop"
-- 	fuelShopTag.Parent = fuelShop
	
-- 	print("Created fuel shop:", location.name, "at position:", location.position)
-- end

-- -- Create fuel shops at the specified locations
-- for _, location in ipairs(fuelShopLocations) do
-- 	createFuelShopModel(location)
-- end

-- print("Fuel shop setup complete!")
-- print("The FuelShopManager will automatically detect these shops and handle player interactions.")
