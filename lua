-- 🏠 Full House Robbery Farm Script with Loop + Server Hop
repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Resume state after teleport
if getgenv()._FromHop then
    _G.FarmAfterHop = getgenv()._FarmAfterHop
    _G.FromHop = true
end
_G.FarmAfterHop = _G.FarmAfterHop or nil
_G.FromHop = _G.FromHop or false
_G.IsLoopingFarm = false

print("[Init] FarmAfterHop:", _G.FarmAfterHop)

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
            https://raw.githubusercontent.com/SAINTLTM53/tests/refs/heads/main/lua
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
        CFrame.new(-610.890747, 253.170853, -703.304565),
    }

    local WoodenMoneyCFrames = {
        CFrame.new(-601.734985, 253.181381, -684.773926),
        CFrame.new(-598.345337, 253.334213, -684.057373),
        CFrame.new(-600.543457, 253.061386, -684.503174),
        CFrame.new(-601.755981, 253.061386, -683.188782),
        CFrame.new(-603.292969, 253.10051, -682.698669),
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

-- 🧠 Resume after teleport
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
