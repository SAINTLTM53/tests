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
            getgenv()._FarmAfterHop = "House"
            getgenv()._FromHop = true
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SAINTLTM53/tests/refs/heads/main/lua"))()
        ]]
        queue_on_teleport(code)
        TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        while true do task.wait() end
    else
        warn("[ServerHop] No servers found.")
    end
end

function runFarm()
    local function KickDownDoor(doorCFrame)
        local rayOrigin = doorCFrame.Position + Vector3.new(0, 5, 0)
        local rayDirection = Vector3.new(0, -10, 0)
        local doorPart = workspace:FindPartOnRay(Ray.new(rayOrigin, rayDirection))
        if doorPart and doorPart.CanCollide then
            LocalPlayer.Character.HumanoidRootPart.CFrame = doorCFrame
            local prompt = doorPart:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                prompt.RequiresLineOfSight = false
                for _ = 1, 8 do fireproximityprompt(prompt) task.wait(0.1) end
                local timeout, timer = 5, 0
                while doorPart.CanCollide and doorPart.Transparency < 1 and timer < timeout do
                    fireproximityprompt(prompt)
                    task.wait(0.2)
                    timer += 0.2
                end
            end
        end
        return doorPart and not doorPart.CanCollide and doorPart.Transparency >= 1
    end

    local function LootMoney(cframes)
        for _, cf in ipairs(cframes) do
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name == "MoneyGrab" and obj.Transparency < 1 and (obj.Position - cf.Position).Magnitude < 1 then
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
                    if prompt then
                        prompt.RequiresLineOfSight = false
                        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
                        task.wait(0.3)
                        for _ = 1, 6 do fireproximityprompt(prompt) task.wait(0.05) end
                    end
                end
            end
        end
    end

    local HardDoorCFrame = CFrame.new(-590.680908, 254.330566, -701.006226)
    local WoodenDoorCFrame = CFrame.new(-590.787598, 254.334854, -679.249634)

    local HardMoneyCFrames = {
                    CFrame.new(-598.759521, 252.007339, -711.958496),
                    CFrame.new(-607.092285, 253.089981, -701.857544),
                    CFrame.new(-598.39502, 252.392899, -711.153625),
                    CFrame.new(-607.836914, 253.089981, -702.305664),
                    CFrame.new(-598.257446, 252.007339, -710.849792),
                    CFrame.new(-598.767456, 252.131973, -711.97583),
                    CFrame.new(-598.401245, 252.131973, -711.167175),
                    CFrame.new(-598.437256, 252.274185, -711.246765),
                    CFrame.new(-598.757446, 252.274185, -711.953796),
                    CFrame.new(-598.757446, 252.397659, -711.953796),
                    CFrame.new(-598.757446, 252.537674, -711.953796),
                    CFrame.new(-598.757446, 252.676651, -711.953796),
                    CFrame.new(-598.757446, 252.810562, -711.953796),
                    CFrame.new(-598.54248, 252.007339, -711.479187),
                    CFrame.new(-598.39502, 252.546158, -711.153625),
                    CFrame.new(-598.39502, 252.704727, -711.153625),
                    CFrame.new(-598.39502, 252.830399, -711.153625),
                    CFrame.new(-598.39502, 252.96846, -711.153625),
                    CFrame.new(-610.890747, 253.170853, -703.304565),
                    CFrame.new(-610.810791, 253.050858, -703.322083),
                    CFrame.new(-608.896362, 253.209976, -702.94342),
                    CFrame.new(-608.890869, 253.089981, -703.01123),
                    CFrame.new(-607.801392, 253.209976, -702.209412),
                }

                local WoodenMoneyCFrames = {
                    CFrame.new(-601.734985, 253.181381, -684.773926),
                    CFrame.new(-598.345337, 253.334213, -684.057373),
                    CFrame.new(-600.543457, 253.061386, -684.503174),
                    CFrame.new(-598.345337, 253.200363, -684.100647),
                    CFrame.new(-601.755981, 253.061386, -683.188782),
                    CFrame.new(-601.649414, 253.061386, -684.90033),
                    CFrame.new(-600.591797, 253.334213, -684.503174),
                    CFrame.new(-600.548462, 253.200363, -684.503174),
                    CFrame.new(-603.292969, 253.10051, -682.698669),
                    CFrame.new(-599.430908, 253.334213, -684.232666),
                    CFrame.new(-599.474121, 253.200363, -684.232666),
                    CFrame.new(-599.479248, 253.061386, -684.232666),
                    CFrame.new(-598.345337, 253.061386, -684.105713)
                }

    local anyRobbed = false
    if KickDownDoor(HardDoorCFrame) then
        LootMoney(HardMoneyCFrames)
        anyRobbed = true
    elseif KickDownDoor(WoodenDoorCFrame) then
        LootMoney(WoodenMoneyCFrames)
        anyRobbed = true
    end

    if not anyRobbed then
        warn("❌ No houses available to rob.")
    end
end

function StartLoop()
    if _G.IsLoopingFarm then print("[Loop] Already running") return end
    _G.IsLoopingFarm = true
    _G.FarmAfterHop = "House"
getgenv()._FromHop = nil  
_G.FromHop = false


    task.spawn(function()
        while _G.IsLoopingFarm do
            print("[Loop] Running House Robbery")
            local success, err = pcall(function()
                runFarm()
            end)
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

createButton("🏠 Start House Loop", 100, function()
	print("[Button] Starting House loop")
	StartLoop()
end)

spawn(function()
    task.wait(5)
    repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    task.wait(1)
    print("[Autoexec] Detected restart:", _G.FarmAfterHop)
    if _G.FromHop and _G.FarmAfterHop == "House" and not _G.IsLoopingFarm then
        StartLoop()
    else
        print("[Autoexec] No loop to resume.")
    end
end)
