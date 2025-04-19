repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

if getgenv()._FromHop then
    _G.FarmAfterHop = getgenv()._FarmAfterHop
    _G.FromHop = true
end
_G.FarmAfterHop = _G.FarmAfterHop or nil
_G.FromHop = _G.FromHop or false
_G.IsLoopingFarm = false

print("[Init] FarmAfterHop:", _G.FarmAfterHop, "| FromHop:", _G.FromHop)

function ServerHop()
    print("[ServerHop] Attempting to hop...")
    local PlaceId = game.PlaceId
    local servers = {}
    local req = syn and syn.request or http_request or request
    local body = req({
        Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    }).Body
    local data = HttpService:JSONDecode(body)

    for _, s in pairs(data.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            table.insert(servers, s.id)
        end
    end

    if #servers > 0 then
        print("[ServerHop] Found server, preparing to hop...")
        local code = [[
            repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
            getgenv()._FarmAfterHop = "Studio"
            getgenv()._FromHop = true
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SAINTLTM53/tests/refs/heads/main/ui.lua"))()
        ]]
        queue_on_teleport(code)
        TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        while true do task.wait() end
    else
        warn("[ServerHop] No servers found.")
    end
end

function runFarm()
    local foundPrompts = {}
    for _, prompt in pairs(workspace.StudioPay:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Name == "Prompt" and prompt.Enabled then
            local part = prompt.Parent
            if part:IsA("BasePart") then
                table.insert(foundPrompts, {Prompt = prompt, Position = part.Position})
            end
        end
    end

    for _, data in ipairs(foundPrompts) do
        local prompt = data.Prompt
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(data.Position + Vector3.new(0, 2, 0))
        repeat fireproximityprompt(prompt) task.wait(0.3) until not prompt.Enabled
    end
end

function StartLoop()
    if _G.IsLoopingFarm then print("[Loop] Already running") return end
    _G.IsLoopingFarm = true
    _G.FarmAfterHop = "Studio"
    getgenv()._FromHop = nil
    _G.FromHop = false

    task.spawn(function()
        while _G.IsLoopingFarm do
            print("[Loop] Running Studio Farm")
            local success, err = pcall(runFarm)
            if not success then warn("[Loop] Error:", err) end
            ServerHop()
            task.wait(10)
        end
    end)
end

local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "SimpleFarmUI"

local function createButton(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, posY)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = screenGui
    btn.MouseButton1Click:Connect(callback)
end

createButton("🎬 Start Studio Loop", 100, function()
    print("[Button] Starting Studio loop")
    StartLoop()
end)

spawn(function()
    task.wait(5)
    repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    task.wait(1)
    print("[Autoexec] Detected restart:", _G.FarmAfterHop)
    if _G.FromHop and _G.FarmAfterHop == "Studio" and not _G.IsLoopingFarm then
        print("[Autoexec] Resuming loop...")
        StartLoop()
    else
        print("[Autoexec] No loop to resume.")
    end
end)
