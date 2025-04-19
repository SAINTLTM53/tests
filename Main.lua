repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

print("[Script] Loaded")

if not _G.FarmAfterHop then _G.FarmAfterHop = nil end
_G.IsLoopingFarm = false
if getgenv()._FromHop then
    _G.FarmAfterHop = getgenv()._FarmAfterHop
    _G.FromHop = true
end
_G.FarmAfterHop = _G.FarmAfterHop or nil
_G.FromHop = _G.FromHop or false
print("[Init] FarmAfterHop:", _G.FarmAfterHop)

local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "SimpleFarmUI"

local function createButton(name, yOffset, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 200, 0, 40)
	button.Position = UDim2.new(0, 20, 0, 100 + yOffset)
	button.Text = name
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = screenGui
	button.MouseButton1Click:Connect(callback)
end

function ServerHop()
	print("[ServerHop] Attempting to hop...")
	local PlaceId = game.PlaceId
	local servers = {}
	local req = syn and syn.request or http_request or request
	local body = req({
		Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
	}).Body
	local data = game:GetService("HttpService"):JSONDecode(body)

	for _, s in pairs(data.data) do
		if s.playing < s.maxPlayers and s.id ~= game.JobId then
			table.insert(servers, s.id)
		end
	end

	if #servers > 0 then
		print("[ServerHop] Found server, preparing to hop...")
		local code = [[
			repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
			getgenv()._FarmAfterHop = "]] .. tostring(_G.FarmAfterHop) .. [["
			getgenv()._FromHop = true
			loadstring(game:HttpGet("https://raw.githubusercontent.com/SAINTLTM53/tests/refs/heads/main/Main.lua"))()
		]]
		queue_on_teleport(code)
		TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)

		while true do task.wait() end
	else
		warn("[ServerHop] No available servers to hop to.")
	end
end

local function runFarm(name)
	print("[runFarm] Executing farm:", name)
	if name == "Construction" then
		local originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
		local wallCFrames = {
			{"Wall1 Prompt", CFrame.new(-1672.1, 368.8, -1192.8)},
			{"Wall1 Prompt2", CFrame.new(-1672.1, 368.8, -1180.0)},
			{"Wall1 Prompt3", CFrame.new(-1672.1, 368.8, -1165.9)},
			{"Wall2 Prompt", CFrame.new(-1704.8, 367.9, -1150.3)},
			{"Wall2 Prompt2", CFrame.new(-1717.0, 367.9, -1150.3)},
			{"Wall3 Prompt", CFrame.new(-1730.0, 367.9, -1150.3)},
			{"Wall3 Prompt2", CFrame.new(-1742.0, 367.9, -1150.3)},
			{"Wall4 Prompt", CFrame.new(-1760.9, 367.9, -1150.3)},
			{"Wall4 Prompt2", CFrame.new(-1774.7, 367.9, -1150.3)}
		}
		local function tp(cf) LocalPlayer.Character.HumanoidRootPart.CFrame = cf task.wait(0.25) end
		local function firePrompt(prompt)
			if prompt and prompt.Enabled then
				prompt.RequiresLineOfSight = false
				prompt.HoldDuration = 0
				if fireproximityprompt then fireproximityprompt(prompt) else prompt:InputHoldBegin() task.wait(0.05) prompt:InputHoldEnd() end
			end
		end
		local function waitForTool(tool)
			for _ = 1, 30 do
				if LocalPlayer.Backpack:FindFirstChild(tool) then
					LocalPlayer.Backpack[tool].Parent = LocalPlayer.Character
				end
				if LocalPlayer.Character:FindFirstChild(tool) then return true end
				task.wait(0.1)
			end
			return false
		end
		local wallQueue = {}
		for _, data in ipairs(wallCFrames) do
			local obj = workspace.ConstructionStuff:FindFirstChild(data[1], true)
			local prompt = obj and obj:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt and prompt.Enabled then
				table.insert(wallQueue, { cf = data[2], prompt = prompt })
			end
		end
		if #wallQueue == 0 then warn("❌ No wood walls available to build.") return end
		local startPrompt = workspace.ConstructionStuff:FindFirstChild("Start Job"):FindFirstChildWhichIsA("ProximityPrompt")
		if startPrompt and startPrompt.Enabled then tp(startPrompt.Parent.CFrame) firePrompt(startPrompt) task.wait(0.5) end
		for _, wall in ipairs(wallQueue) do
			local char = workspace:FindFirstChild(LocalPlayer.Name)
			local hasPlyWood = char and char:FindFirstChild("PlyWood")
			if not hasPlyWood then
				local grabPrompt = workspace.ConstructionStuff:FindFirstChild("Grab Wood"):FindFirstChildWhichIsA("ProximityPrompt")
				if grabPrompt and grabPrompt.Enabled then tp(grabPrompt.Parent.CFrame) firePrompt(grabPrompt) task.wait(0.1) firePrompt(grabPrompt) if not waitForTool("PlyWood") then break end end
			end
			tp(wall.cf)
			while wall.prompt and wall.prompt.Enabled do
				local char = workspace:FindFirstChild(LocalPlayer.Name)
				local hasPlyWood = char and char:FindFirstChild("PlyWood")
				if not hasPlyWood then
					local grabPrompt = workspace.ConstructionStuff:FindFirstChild("Grab Wood"):FindFirstChildWhichIsA("ProximityPrompt")
					if grabPrompt and grabPrompt.Enabled then tp(grabPrompt.Parent.CFrame) firePrompt(grabPrompt) waitForTool("PlyWood") end
				end
				tp(wall.cf)
				for _ = 1, 9 do firePrompt(wall.prompt) task.wait(0.05) end
				task.wait(0.1)
			end
		end
		local stopPrompt = workspace.ConstructionStuff:FindFirstChild("Start Job"):FindFirstChildWhichIsA("ProximityPrompt")
		if stopPrompt and stopPrompt.Enabled then tp(stopPrompt.Parent.CFrame) firePrompt(stopPrompt) task.wait(0.3) end
		if originalPosition then tp(originalPosition) end
	elseif name == "Studio" then
		task.wait(3)
	elseif name == "House" then
		task.wait(3)
	end
end

function StartLoop(farmName)
	if _G.IsLoopingFarm then print("[Loop] Already running") return end
	_G.IsLoopingFarm = true
	_G.FarmAfterHop = farmName

	task.spawn(function()
		while _G.IsLoopingFarm do
			print("[Loop] Running:", farmName)
			local success, err = pcall(function()
				runFarm(farmName)
			end)
			if not success then warn("[Loop] Error in farm:", err) end
			print("[Loop] Finished cycle, hopping...")
			ServerHop()
			task.wait(15)
		end
	end)
end

spawn(function()
	task.wait(5)
	repeat task.wait() until game:IsLoaded() and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	task.wait(2)
	print("[Autoexec] Detected auto farm restart:", _G.FarmAfterHop)
	if _G.FromHop and _G.FarmAfterHop and not _G.IsLoopingFarm then
		StartLoop(_G.FarmAfterHop)
	else
		print("[Autoexec] No loop to resume or already running.")
	end
end)

createButton("🔨 Construction Loop", 0, function()
	print("[Button] Starting Construction loop")
	StartLoop("Construction")
end)
