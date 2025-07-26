local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

getgenv().headSize = 1
getgenv().hitboxEnabled = false

local adornments = {}
local connections = {}
local renderConnection

local function isValidCharacter(player)
    return player and player.Character
       and player.Character:FindFirstChild("Humanoid")
       and player.Character:FindFirstChild("HumanoidRootPart")
end

local function applyAdornment(player)
    if player == Players.LocalPlayer or not isValidCharacter(player) then return end

    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if adornments[player] then
        adornments[player].Size = Vector3.new(getgenv().headSize, getgenv().headSize, getgenv().headSize)
        adornments[player].Adornee = hrp
        return
    end

    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = hrp
    box.Size = Vector3.new(getgenv().headSize, getgenv().headSize, getgenv().headSize)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.2
    box.Color3 = Color3.fromRGB(0, 170, 255)
    box.Name = "HitboxAdornment"
    box.Parent = game:GetService("CoreGui")

    adornments[player] = box
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
            pcall(applyAdornment, player)
        end
    end)

    table.insert(connections, Players.PlayerAdded:Connect(function(plr)
        table.insert(connections, plr.CharacterAdded:Connect(function()
            task.wait(1)
            pcall(applyAdornment, plr)
        end))
    end))
end

local function stopHitboxLoop()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        pcall(removeAdornment, player)
    end

    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
end

getgenv().startHitboxLoop = startHitboxLoop
getgenv().stopHitboxLoop = stopHitboxLoop
getgenv().setHeadSize = function(sz)
    getgenv().headSize = sz
end
