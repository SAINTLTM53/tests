-- SilentAim.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Mouse = LocalPlayer:GetMouse()
local InflictRemote = ReplicatedStorage:WaitForChild("InflictTarget")
local FireEvent = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("BulletVisualizerServerScript"):WaitForChild("VisualizeM")

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

local function isVisible(targetPos, targetCharacter, visibleCheckEnabled)
	if not visibleCheckEnabled then return true end
	local rayOrigin = Camera.CFrame.Position
	local rayDirection = (targetPos - rayOrigin)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult then
		local hit = raycastResult.Instance
		return hit:IsDescendantOf(targetCharacter)
	end
	return true
end

local function getClosestPlayerToCursor(FOV_RADIUS, visibleCheckEnabled)
	local closestPlayer = nil
	local shortestDist = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(TargetPart) then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local part = player.Character[TargetPart]
				local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if dist < FOV_RADIUS and dist < shortestDist and isVisible(part.Position, player.Character, visibleCheckEnabled) then
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
	local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local igniteScript = tool and tool:FindFirstChild("GunScript_Server") and tool.GunScript_Server:FindFirstChild("IgniteScript")
	local icifyScript = tool and tool:FindFirstChild("GunScript_Server") and tool.GunScript_Server:FindFirstChild("IcifyScript")

	InflictRemote:FireServer(
		tool,
		LocalPlayer,
		humanoid,
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

-- Public API
getgenv().SilentAimConfig = {
	Enabled = false,
	Wallbang = false,
	FOV = true,
	VisibleCheck = false,
}

getgenv().SilentAimAPI = {
	Start = function()
		if getgenv().SilentAimConfig.Enabled then return end
		getgenv().SilentAimConfig.Enabled = true

		getgenv().SilentAimConnection = FireEvent.Event:Connect(function()
			local target = getClosestPlayerToCursor(FOV_RADIUS, getgenv().SilentAimConfig.VisibleCheck)
			if target then
				sendDamage(target)
			end
		end)
	end,

	Stop = function()
		getgenv().SilentAimConfig.Enabled = false
		if getgenv().SilentAimConnection then
			getgenv().SilentAimConnection:Disconnect()
			getgenv().SilentAimConnection = nil
		end
	end,
}
