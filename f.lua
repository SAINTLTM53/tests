-- SilentAim.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local InflictRemote = ReplicatedStorage:WaitForChild("InflictTarget")
local FireEvent = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("BulletVisualizerServerScript"):WaitForChild("VisualizeM")

-- // CONFIG //
local TargetPart = "Head"
local Damage = 1000
local FOV_RADIUS = 150

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 30
fovCircle.Color = Color3.fromRGB(125, 85, 255)
fovCircle.Transparency = 0.8
fovCircle.Radius = FOV_RADIUS
fovCircle.Filled = false
fovCircle.Visible = false

local circleConnection
local fireConnection

getgenv().SilentAimConfig = {
	Enabled = false,
	Wallbang = false,
	FOV = false,
	VisibleCheck = false,
	FOVRadius = 150
}

-- // FUNCTIONS //
local function isVisible(targetPos, targetCharacter)
	if not getgenv().SilentAimConfig.VisibleCheck then return true end
	local rayOrigin = Camera.CFrame.Position
	local rayDirection = (targetPos - rayOrigin)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {LocalPlayer.Character}
	local result = Workspace:Raycast(rayOrigin, rayDirection, params)
	if result then
		local hit = result.Instance
		return hit:IsDescendantOf(targetCharacter)
	end
	return true
end

local function getClosestPlayerToCursor()
	local closestPlayer, shortestDist = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(TargetPart) then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local part = player.Character[TargetPart]
				local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if dist < getgenv().SilentAimConfig.FOVRadius and dist < shortestDist and isVisible(part.Position, player.Character) then
						shortestDist = dist
						closestPlayer = player
					end
				end
			end
		end
	end
	return closestPlayer
end

local function sendDamage(target)
	if not target or not target.Character or not target.Character:FindFirstChild(TargetPart) then return end
	local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
	local part = target.Character[TargetPart]
	local hum = target.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local igniteScript = tool and tool:FindFirstChild("GunScript_Server") and tool.GunScript_Server:FindFirstChild("IgniteScript")
	local icifyScript = tool and tool:FindFirstChild("GunScript_Server") and tool.GunScript_Server:FindFirstChild("IcifyScript")

	InflictRemote:FireServer(
		tool,
		LocalPlayer,
		hum,
		part,
		Damage,
		{0, 0, false, false, igniteScript, icifyScript, 100, 100},
		{false, 5, 3},
		part,
		{false, {1930359546}, 1, 1.5, 1},
		nil,
		nil,
		true
	)
end

-- // MAIN API //
getgenv().SilentAimAPI = {
	Start = function()
		if getgenv().SilentAimConfig.Enabled then return end
		getgenv().SilentAimConfig.Enabled = true

		fireConnection = FireEvent.Event:Connect(function()
			local target = getClosestPlayerToCursor()
			if target then
				sendDamage(target)
			end
		end)
	end,

	Stop = function()
		getgenv().SilentAimConfig.Enabled = false
		if fireConnection then
			fireConnection:Disconnect()
			fireConnection = nil
		end
	end,

	UpdateFOV = function(value)
		getgenv().SilentAimConfig.FOVRadius = value
		fovCircle.Radius = value
	end,

	ToggleFOV = function(state)
		getgenv().SilentAimConfig.FOV = state
		if state then
			circleConnection = RunService.Heartbeat:Connect(function()
				fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
				fovCircle.Radius = getgenv().SilentAimConfig.FOVRadius
				fovCircle.Visible = true
			end)
		else
			if circleConnection then
				circleConnection:Disconnect()
				circleConnection = nil
			end
			fovCircle.Visible = false
		end
	end
}
