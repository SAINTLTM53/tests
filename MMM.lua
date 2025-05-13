-- logic.lua

-- services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- state
getgenv().headSize      = 1
getgenv().hitboxEnabled = false
local connections      = {}
local renderConnection

-- apply & reset
local function applyHitbox(player)
    if player == Players.LocalPlayer then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Size        = Vector3.new(getgenv().headSize, getgenv().headSize, getgenv().headSize)
        hrp.Transparency= 0.8
        hrp.BrickColor = BrickColor.new("Bright blue")
        hrp.Material   = Enum.Material.Neon
        hrp.CanCollide = false
    end
end

local function resetHitbox(player)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Size        = Vector3.new(2, 2, 1)
        hrp.Transparency= 1
        hrp.BrickColor = BrickColor.new("Medium stone grey")
        hrp.Material   = Enum.Material.Plastic
        hrp.CanCollide = true
    end
end

-- loops
local function startHitboxLoop()
    if renderConnection then return end
    renderConnection = RunService.RenderStepped:Connect(function()
        if not getgenv().hitboxEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(applyHitbox, player)
        end
    end)
    table.insert(connections, Players.PlayerAdded:Connect(function(pl)
        pl.CharacterAdded:Connect(function()
            task.wait(1)
            pcall(applyHitbox, pl)
        end)
    end))
end

local function stopHitboxLoop()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(resetHitbox, player)
    end
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
end

-- expose API
getgenv().startHitboxLoop = startHitboxLoop
getgenv().stopHitboxLoop  = stopHitboxLoop
getgenv().setHeadSize     = function(sz) getgenv().headSize = sz end
