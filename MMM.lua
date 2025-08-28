local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

getgenv().headSize = 1
getgenv().hitboxEnabled = false

local adornments = {}
local connections = {}
local renderConnection

local function isValidCharacter(player)
	local char = player.Character
	return char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")
end

local function applyAdornment(player)
	if player == Players.LocalPlayer or not isValidCharacter(player) then return end

	local hrp = player.Character.HumanoidRootPart
	local adorn = adornments[player]

	if adorn then
		adorn.Size = Vector3.new(getgenv().headSize, getgenv().headSize, getgenv().headSize)
		adorn.Adornee = hrp
	else
		local box = Instance.new("BoxHandleAdornment")
		box.Name = "HitboxAdornment"
		box.Adornee = hrp
		box.Size = Vector3.new(getgenv().headSize, getgenv().headSize, getgenv().headSize)
		box.AlwaysOnTop = true
		box.ZIndex = 5
		box.Transparency = 0.2
		box.Color3 = Color3.fromRGB(0, 170, 255)
		box.Parent = hrp 

		adornments[player] = box
	end
end

local function removeAdornment(player)
	if adornments[player] then
		adornments[player]:Destroy()
		adornments[player] = nil
	end
end

local function startHitboxLoop()
	if renderConnection then return end
	renderConnection = RunService.RenderStepped:Connect(function()
		if not getgenv().hitboxEnabled then return end
		for _, player in ipairs(Players:GetPlayers()) do
			applyAdornment(player)
		end
	end)

	table.insert(connections, Players.PlayerAdded:Connect(function(plr)
		table.insert(connections, plr.CharacterAdded:Connect(function()
			task.wait(1)
			applyAdornment(plr)
		end))
	end))

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Players.LocalPlayer then
			table.insert(connections, plr.CharacterAdded:Connect(function()
				task.wait(1)
				applyAdornment(plr)
			end))
		end
	end
end

local function stopHitboxLoop()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}

	for _, player in pairs(adornments) do
		player:Destroy()
	end
	adornments = {}
end

getgenv().setHeadSize = function(size)
	getgenv().headSize = size
	for player, adorn in pairs(adornments) do
		if adorn and adorn:IsA("BoxHandleAdornment") then
			adorn.Size = Vector3.new(size, size, size)
		end
	end
end

getgenv().startHitboxLoop = startHitboxLoop
getgenv().stopHitboxLoop = stopHitboxLoop
