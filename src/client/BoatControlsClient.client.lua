-- Client-side script to handle on-screen boat controls
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🎮 BoatControlsClient loaded for player:", player.Name)

-- Configuration
local SHOW_ONSCREEN_CONTROLS = true
local CONTROLS_FOR_TOUCH_ONLY = true  -- Set to false to show controls on desktop for testing

-- Track current boat's control event
local currentControlEvent = nil
local controlsFrame = nil

-- Function to create control buttons
local function createOnScreenControls(screenGui, boatScript)
	print("🎮 createOnScreenControls called")
	print("   - ScreenGui:", screenGui)
	print("   - BoatScript:", boatScript)
	
	-- Remove old controls if they exist
	if controlsFrame then
		controlsFrame:Destroy()
		controlsFrame = nil
	end

	-- Check if we should show controls
	-- Show controls if enabled AND (not touch-only OR touch is enabled)
	local shouldShowControls = SHOW_ONSCREEN_CONTROLS and 
		(not CONTROLS_FOR_TOUCH_ONLY or UserInputService.TouchEnabled)
	
	print("   - Should show controls:", shouldShowControls)
	print("   - TouchEnabled:", UserInputService.TouchEnabled)
	print("   - KeyboardEnabled:", UserInputService.KeyboardEnabled)
	print("   - CONTROLS_FOR_TOUCH_ONLY:", CONTROLS_FOR_TOUCH_ONLY)
	
	if not shouldShowControls then
		print("   - Controls hidden due to configuration")
		return
	end

	-- Get the control event from the boat script
	print("   - Waiting for ControlEvent...")
	local controlEvent = boatScript:WaitForChild("ControlEvent", 5)
	if not controlEvent then
		warn("Could not find ControlEvent in boat script")
		return
	end
	print("   - ControlEvent found:", controlEvent)
	currentControlEvent = controlEvent

	-- Create main controls container
	controlsFrame = Instance.new("Frame")
	controlsFrame.Name = "ControlsFrame"
	controlsFrame.Size = UDim2.new(1, 0, 1, 0) -- Full screen
	controlsFrame.Position = UDim2.new(0, 0, 0, 0)
	controlsFrame.BackgroundTransparency = 1
	controlsFrame.Parent = screenGui

	-- Create left controls frame (Forward/Backward)
	local leftControlsFrame = Instance.new("Frame")
	leftControlsFrame.Name = "LeftControls"
	leftControlsFrame.Size = UDim2.new(0, 80, 0, 180)
	leftControlsFrame.Position = UDim2.new(0, 50, 0.5, -90) -- Left side, centered vertically
	leftControlsFrame.BackgroundTransparency = 1
	leftControlsFrame.Parent = controlsFrame

	-- Create right controls frame (Left/Right)
	local rightControlsFrame = Instance.new("Frame")
	rightControlsFrame.Name = "RightControls"
	rightControlsFrame.Size = UDim2.new(0, 180, 0, 80)
	rightControlsFrame.Position = UDim2.new(1, -230, 0.5, -40) -- Right side, centered vertically
	rightControlsFrame.BackgroundTransparency = 1
	rightControlsFrame.Parent = controlsFrame

	-- Helper function to create a control button
	local function createControlButton(name, position, text, action, parentFrame)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(0, 60, 0, 60)
		button.Position = position
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		button.BackgroundTransparency = 0.3
		button.BorderSizePixel = 2
		button.BorderColor3 = Color3.fromRGB(255, 255, 255)
		button.Text = text
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 24
		button.Font = Enum.Font.SourceSansBold
		button.Parent = parentFrame or controlsFrame

		-- Add rounded corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		local isPressed = false

		-- Handle input begin (works for both mouse and touch)
		button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			   input.UserInputType == Enum.UserInputType.Touch then
				isPressed = true
				button.BackgroundTransparency = 0.1
				if currentControlEvent then
					currentControlEvent:FireServer(action, true)
					print("🎮 Button pressed:", action)
				end
			end
		end)

		-- Handle input end (works for both mouse and touch)
		button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			   input.UserInputType == Enum.UserInputType.Touch then
				if isPressed then
					isPressed = false
					button.BackgroundTransparency = 0.3
					if currentControlEvent then
						currentControlEvent:FireServer(action, false)
						print("🎮 Button released:", action)
					end
				end
			end
		end)

		return button
	end

	-- Create throttle controls (left side)
	createControlButton("ForwardButton", UDim2.new(0, 10, 0, 0), "▲", "Forward", leftControlsFrame)
	createControlButton("BackwardButton", UDim2.new(0, 10, 0, 120), "▼", "Backward", leftControlsFrame)
	
	-- Create steering controls (right side)
	createControlButton("LeftButton", UDim2.new(0, 0, 0, 10), "◄", "Left", rightControlsFrame)
	createControlButton("RightButton", UDim2.new(0, 120, 0, 10), "►", "Right", rightControlsFrame)

	print("🎮 Client: On-screen controls created")
end

-- Monitor for BoatHUD GUI creation
local function onChildAdded(child)
	print("🎮 PlayerGui child added:", child.Name, child.ClassName)
	
	if child.Name == "BoatHUD" and child:IsA("ScreenGui") then
		print("🎮 BoatHUD detected!")
		
		-- Wait a bit for the boat script to be ready
		task.wait(0.1)
		
		-- Find the boat script through the workspace
		-- The GUI was created by a boat's script
		local character = player.Character
		print("   - Character:", character)
		
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			print("   - Humanoid:", humanoid)
			
			if humanoid and humanoid.SeatPart then
				local seat = humanoid.SeatPart
				print("   - Seat:", seat, seat.ClassName)
				
				if seat:IsA("VehicleSeat") then
					print("   - Looking for boat script in seat...")
					
					-- Look for any Script that has a ControlEvent
					local boatScript = nil
					for _, child in ipairs(seat:GetChildren()) do
						print("      - Checking child:", child.Name, child.ClassName)
						if child:IsA("Script") or child:IsA("LocalScript") then
							local hasControlEvent = child:FindFirstChild("ControlEvent")
							print("         - Has ControlEvent:", hasControlEvent ~= nil)
							if hasControlEvent then
								boatScript = child
								break
							end
						end
					end
					
					if boatScript then
						print("   - Boat script found! Creating controls...")
						createOnScreenControls(child, boatScript)
					else
						warn("Could not find boat script with ControlEvent in seat:", seat:GetFullName())
					end
				else
					print("   - Seat is not a VehicleSeat")
				end
			else
				print("   - No seat part found")
			end
		else
			print("   - No character found")
		end
	end
end

-- Listen for GUI creation
print("🎮 Listening for BoatHUD creation...")
playerGui.ChildAdded:Connect(onChildAdded)

-- Check existing GUIs
print("🎮 Checking existing GUIs in PlayerGui...")
for _, child in ipairs(playerGui:GetChildren()) do
	onChildAdded(child)
end

-- Cleanup when GUI is removed
playerGui.ChildRemoved:Connect(function(child)
	if child.Name == "BoatHUD" then
		print("🎮 BoatHUD removed, cleaning up controls")
		currentControlEvent = nil
		if controlsFrame then
			controlsFrame:Destroy()
			controlsFrame = nil
		end
	end
end)

print("🎮 BoatControlsClient fully initialized")
