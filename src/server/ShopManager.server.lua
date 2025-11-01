local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create ShopEvent if it doesn't exist
local ShopEvent = ReplicatedStorage:FindFirstChild("ShopEvent")
if not ShopEvent then
	ShopEvent = Instance.new("RemoteEvent")
	ShopEvent.Name = "ShopEvent"
	ShopEvent.Parent = ReplicatedStorage
end

-- Shop configuration
local SHOP_POSITION = Vector3.new(221.511, 84.444, -176.737) -- Adjust position as needed
local SHOP_MODEL_NAME = "ShopModel" -- Change this to your model's name

-- Create shop from model
local function createShop()
	-- Look for shop model in ReplicatedStorage or ServerStorage
	local shopModel = ReplicatedStorage:FindFirstChild(SHOP_MODEL_NAME) or 
					  game.ServerStorage:FindFirstChild(SHOP_MODEL_NAME) or
					  workspace:FindFirstChild(SHOP_MODEL_NAME)
	
	if not shopModel then
		warn("Shop model '" .. SHOP_MODEL_NAME .. "' not found! Creating basic shop instead.")
		-- Fallback to basic shop creation
		return createBasicShop()
	end
	
	-- Clone the model for the shop
	local shop = shopModel:Clone()
	shop.Name = "BoatUpgradeShop"
	shop:PivotTo(CFrame.new(SHOP_POSITION))
	shop.Parent = workspace
	
	-- Add shop sign if model doesn't have one
	if not shop:FindFirstChild("ShopSign") then
		local sign = Instance.new("BillboardGui")
		sign.Name = "ShopSign"
		sign.Size = UDim2.new(0, 200, 0, 50)
		sign.StudsOffset = Vector3.new(0, 8, 0)
		sign.AlwaysOnTop = true
		sign.Parent = shop.PrimaryPart or shop:FindFirstChildWhichIsA("BasePart")
		
		local signLabel = Instance.new("TextLabel")
		signLabel.Size = UDim2.new(1, 0, 1, 0)
		signLabel.BackgroundTransparency = 0.5
		signLabel.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
		signLabel.BorderSizePixel = 0
		signLabel.Text = "⚓ Boat Upgrades ⚓"
		signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		signLabel.TextStrokeTransparency = 0
		signLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		signLabel.Font = Enum.Font.GothamBold
		signLabel.TextSize = 18
		signLabel.Parent = sign
	end
	
	-- Add click detector to the main part
	local mainPart = shop.PrimaryPart or shop:FindFirstChildWhichIsA("BasePart")
	if mainPart then
		-- Add click detector
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = mainPart
		
		-- Handle shop interactions
		clickDetector.MouseClick:Connect(function(player)
			ShopEvent:FireClient(player, "openShop")
		end)
		
		-- Add proximity prompt for better UX
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open Shop"
		prompt.ObjectText = "Boat Upgrade Shop"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 15
		prompt.Parent = mainPart
		
		prompt.Triggered:Connect(function(player)
			ShopEvent:FireClient(player, "openShop")
		end)
	else
		warn("No valid BasePart found in shop model for interaction!")
	end
	
	print("Boat upgrade shop created from model at position:", SHOP_POSITION)
	return shop
end

-- Fallback basic shop creation
local function createBasicShop()
	local shopPart = Instance.new("Part")
	shopPart.Name = "BoatUpgradeShop"
	shopPart.Size = Vector3.new(8, 6, 8)
	shopPart.Position = SHOP_POSITION
	shopPart.Anchored = true
	shopPart.CanCollide = true
	shopPart.BrickColor = BrickColor.new("Bright blue")
	shopPart.Material = Enum.Material.Neon
	shopPart.Parent = workspace
	
	-- Add shop sign
	local sign = Instance.new("BillboardGui")
	sign.Name = "ShopSign"
	sign.Size = UDim2.new(0, 200, 0, 50)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	sign.AlwaysOnTop = true
	sign.Parent = shopPart
	
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.new(1, 0, 1, 0)
	signLabel.BackgroundTransparency = 0.5
	signLabel.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
	signLabel.BorderSizePixel = 0
	signLabel.Text = "⚓ Boat Upgrades ⚓"
	signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	signLabel.TextStrokeTransparency = 0
	signLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	signLabel.Font = Enum.Font.GothamBold
	signLabel.TextSize = 18
	signLabel.Parent = sign
	
	-- Add click detector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = shopPart
	
	-- Handle shop interactions
	clickDetector.MouseClick:Connect(function(player)
		ShopEvent:FireClient(player, "openShop")
	end)
	
	-- Add proximity prompt for better UX
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Shop"
	prompt.ObjectText = "Boat Upgrade Shop"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 15
	prompt.Parent = shopPart
	
	prompt.Triggered:Connect(function(player)
		ShopEvent:FireClient(player, "openShop")
	end)
	
	print("Basic boat upgrade shop created at position:", SHOP_POSITION)
	return shopPart
end

-- Create the shop when the game starts
local shop = createShop()

print("ShopManager initialized")
