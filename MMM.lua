-- logic.lua

-- services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- state
local headSize      = 1
local hitboxEnabled = false
local connections   = {}
local renderConnection

-- apply & reset functions
local function applyHitbox(player)
    if player == Players.LocalPlayer then return end
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        hrp.Size       = Vector3.new(headSize, headSize, headSize)
        hrp.Transparency = 0.8
        hrp.BrickColor  = BrickColor.new("Bright blue")
        hrp.Material    = Enum.Material.Neon
        hrp.CanCollide  = false
    end
end

local function resetHitbox(player)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        hrp.Size        = Vector3.new(2, 2, 1)
        hrp.Transparency= 1
        hrp.BrickColor  = BrickColor.new("Medium stone grey")
        hrp.Material    = Enum.Material.Plastic
        hrp.CanCollide  = true
    end
end

-- main loops
local function startHitboxLoop()
    if renderConnection then return end
    renderConnection = RunService.RenderStepped:Connect(function()
        if not hitboxEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(applyHitbox, player)
        end
    end)
    -- listen for new players
    table.insert(connections, Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(1)
            pcall(applyHitbox, player)
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

-- API table
local Hitbox = {
    hitboxEnabled = hitboxEnabled
}

function Hitbox:startHitboxLoop()
    hitboxEnabled = true
    self.hitboxEnabled = true
    startHitboxLoop()
end

function Hitbox:stopHitboxLoop()
    hitboxEnabled = false
    self.hitboxEnabled = false
    stopHitboxLoop()
end

function Hitbox:setHeadSize(size)
    headSize = size
end

return Hitbox
