local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

-- Force enable ProximityPromptService
ProximityPromptService.Enabled = true
print("[DEBUG] ProximityPromptService enabled:", ProximityPromptService.Enabled)

-- Create RoseEvent if it doesn't exist
local RoseEvent = ReplicatedStorage:FindFirstChild("RoseEvent")
if not RoseEvent then
	RoseEvent = Instance.new("RemoteEvent")
	RoseEvent.Name = "RoseEvent"
	RoseEvent.Parent = ReplicatedStorage
end

-- Rose NPC configuration
local ROSE_MODEL_NAME = "Rose"
local INSTRUCTIONS_DISTANCE = 15

print("[DEBUG] RoseNPCManager: Script is running!")

-- Find Rose model in workspace
local function findRoseModel()
	print("  -> Searching for model named: '" .. ROSE_MODEL_NAME .. "'")
	local roseModel = workspace:WaitForChild(ROSE_MODEL_NAME, 30)
	
	if not roseModel then
		print("  -> [ERROR] Model not found!")
		warn("Rose model not found in workspace! Please ensure there's a model named 'Rose' with a Humanoid.")
		return nil
	else
		print("  -> [SUCCESS] Found model: ", roseModel:GetFullName())
	end
	
	-- Check if it has a Humanoid
	print("  -> Checking for Humanoid in model...")
	local humanoid = roseModel:FindFirstChildWhichIsA("Humanoid")
	
	if not humanoid then
		print("  -> [ERROR] Humanoid not found in model!")
		warn("Rose model doesn't have a Humanoid! Please ensure Rose is a proper humanoid model.")
		return nil
	else
		print("  -> [SUCCESS] Found Humanoid: ", humanoid:GetFullName())
	end
	
	return roseModel
end

-- Setup Rose NPC interaction
local function setupRoseNPC(roseModel)
	if not roseModel then return end
	
	-- Find the primary part for interaction (prioritize HumanoidRootPart)
	print("  -> Finding a part for the prompt...")
	local primaryPart = roseModel.PrimaryPart or roseModel:FindFirstChild("HumanoidRootPart") or roseModel:FindFirstChildWhichIsA("BasePart")
	
	if not primaryPart then
		print("  -> [ERROR] No valid part found for interaction (PrimaryPart, HumanoidRootPart, or any BasePart).")
		warn("No valid BasePart found in Rose model for interaction!")
		return
	else
		print("  -> [SUCCESS] Using part for prompt: ", primaryPart:GetFullName())
	end
	
	-- Add Rose identifier sign
	local sign = Instance.new("BillboardGui")
	sign.Name = "RoseSign"
	sign.Size = UDim2.new(0, 150, 0, 40)
	sign.StudsOffset = Vector3.new(0, 6, 0)
	sign.AlwaysOnTop = true
	sign.Parent = primaryPart
	
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.new(1, 0, 1, 0)
	signLabel.BackgroundTransparency = 0.3
	signLabel.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
	signLabel.BorderSizePixel = 0
	signLabel.Text = "🌹 Rose - Instructions"
	signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	signLabel.TextStrokeTransparency = 0
	signLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	signLabel.Font = Enum.Font.GothamBold
	signLabel.TextSize = 14
	signLabel.Parent = sign
	
	-- Create a separate trigger part for the proximity prompt (like FuelShop does)
	print("  -> Creating trigger part for ProximityPrompt...")
	local trigger = Instance.new("Part")
	trigger.Name = "RoseTrigger"
	trigger.Size = Vector3.new(10, 10, 10)
	trigger.Position = primaryPart.Position
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.Transparency = 1  -- Invisible
	trigger.Parent = roseModel
	
	-- Add proximity prompt to the trigger part
	print("  -> Creating ProximityPrompt...")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk to Rose"
	prompt.ObjectText = "Game Instructions"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = INSTRUCTIONS_DISTANCE
	prompt.RequiresLineOfSight = false  -- Same as FuelShop
	prompt.Parent = trigger
	print("  -> ProximityPrompt created and parented to:", trigger:GetFullName())
	print("  -> Prompt settings - ActionText:", prompt.ActionText, "MaxDistance:", prompt.MaxActivationDistance)
	
	prompt.Triggered:Connect(function(player)
		print("🌹 " .. player.Name .. " is talking to Rose!")
		RoseEvent:FireClient(player, "openInstructions")
	end)
	
	print("[SUCCESS] Rose NPC setup complete for model: " .. roseModel:GetFullName())
end

-- Initialize Rose NPC
local roseModel = findRoseModel()
if roseModel then
	setupRoseNPC(roseModel)
else
	warn("Could not find Rose model. Please check that Rose exists in workspace and has a Humanoid.")
end

print("RoseNPCManager initialized")
