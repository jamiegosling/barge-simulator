-- BoatHUD.lua
-- Handles boat HUD GUI creation and updates

local Players = game:GetService("Players")

local BoatHUD = {}

-- ==================== MODULE STATE ==================== --
local screenGui = nil
local hudFrame = nil
local speedLabel = nil
local cargoLabel = nil
local fuelLabel = nil

-- ==================== PUBLIC FUNCTIONS ==================== --

function BoatHUD.Initialize(config)
	-- Config contains: DSeat
	BoatHUD.DSeat = config.DSeat
end

function BoatHUD.CreateGUIForPlayer(player)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Remove old GUI if it exists
	local oldGui = playerGui:FindFirstChild("BoatHUD")
	if oldGui then
		oldGui:Destroy()
	end

	-- Create HUD GUI
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BoatHUD"
	screenGui.Parent = playerGui
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = true
	screenGui.DisplayOrder = -1

	-- Simple container frame
	hudFrame = Instance.new("Frame")
	hudFrame.Name = "HUDContainer"
	hudFrame.Size = UDim2.new(0, 200, 0, 100)
	hudFrame.Position = UDim2.new(0, 50, 0, 50)
	hudFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	hudFrame.BackgroundTransparency = 0.2
	hudFrame.BorderSizePixel = 2
	hudFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	hudFrame.Visible = true
	hudFrame.Parent = screenGui

	-- Speed display
	speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "SpeedDisplay"
	speedLabel.Size = UDim2.new(1, -10, 0, 30)
	speedLabel.Position = UDim2.new(0, 5, 0, 5)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "🚤 Speed: 0 studs/s"
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.TextSize = 18
	speedLabel.Font = Enum.Font.SourceSansBold
	speedLabel.Visible = true
	speedLabel.Parent = hudFrame

	-- Cargo display
	cargoLabel = Instance.new("TextLabel")
	cargoLabel.Name = "CargoDisplay"
	cargoLabel.Size = UDim2.new(1, -10, 0, 30)
	cargoLabel.Position = UDim2.new(0, 5, 0, 35)
	cargoLabel.BackgroundTransparency = 1
	cargoLabel.Text = "📦 Max Cargo: 100"
	cargoLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	cargoLabel.TextSize = 16
	cargoLabel.Font = Enum.Font.SourceSans
	cargoLabel.Visible = true
	cargoLabel.Parent = hudFrame

	-- Fuel display
	fuelLabel = Instance.new("TextLabel")
	fuelLabel.Name = "FuelDisplay"
	fuelLabel.Size = UDim2.new(1, -10, 0, 30)
	fuelLabel.Position = UDim2.new(0, 5, 0, 65)
	fuelLabel.BackgroundTransparency = 1
	fuelLabel.Text = "⛽ Fuel: 100/200"
	fuelLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	fuelLabel.TextSize = 16
	fuelLabel.Font = Enum.Font.SourceSans
	fuelLabel.Visible = true
	fuelLabel.Parent = hudFrame

	print("🖥️ HUD GUI created for player:", player.Name)
	print("   - ScreenGui Parent:", screenGui.Parent:GetFullName())
	print("   - ScreenGui Enabled:", screenGui.Enabled)
	print("   - HudFrame Visible:", hudFrame.Visible)
	print("   - Children count:", #hudFrame:GetChildren())
end

function BoatHUD.Update(currentSpeed, cargoValues, fuelValues)
	if not BoatHUD.DSeat.Occupant then
		if screenGui then
			screenGui.Enabled = false
		end
		return
	end

	-- Create GUI if it doesn't exist
	if not screenGui or not screenGui.Parent then
		local player = Players:GetPlayerFromCharacter(BoatHUD.DSeat.Occupant.Parent)
		if player then
			BoatHUD.CreateGUIForPlayer(player)
		end
	end

	if screenGui then
		screenGui.Enabled = true

		-- Update speed
		if speedLabel then
			local speed = math.abs(currentSpeed or 0)
			speedLabel.Text = "🚤 Speed: " .. math.floor(speed) .. " studs/s"
		end

		-- Update cargo and fuel
		if cargoLabel and fuelLabel then
			cargoLabel.Text = "📦 Max Cargo: " .. math.floor(cargoValues.maxCargo)
			fuelLabel.Text = "⛽ Fuel: " .. math.floor(fuelValues.currentFuel) .. "/" .. math.floor(fuelValues.maxFuel)

			-- Change fuel color based on level
			local fuelPercent = (fuelValues.currentFuel / fuelValues.maxFuel) * 100
			if fuelPercent <= 20 then
				fuelLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
			elseif fuelPercent <= 50 then
				fuelLabel.TextColor3 = Color3.fromRGB(255, 200, 100) -- Orange
			else
				fuelLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
			end
		end
	end
end

function BoatHUD.Destroy()
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
		hudFrame = nil
		speedLabel = nil
		cargoLabel = nil
		fuelLabel = nil
	end
end

function BoatHUD.GetScreenGui()
	return screenGui
end

return BoatHUD
