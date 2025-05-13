-- Part B: Full logic.lua (Host this on GitHub)

-- [INIT + SETTINGS]
if not game:IsLoaded() then game.Loaded:Wait() end
if not syn or not protectgui then getgenv().protectgui = function() end end

local SilentAimSettings = getgenv().SilentAimSettings or {
    Enabled = false,
    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "RightAlt",
    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false,
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

getgenv().SilentAimSettings = SilentAimSettings

-- [VARIABLES]
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local GetMouseLocation = UserInputService.GetMouseLocation

local resume, create = coroutine.resume, coroutine.create
local PredictionAmount = SilentAimSettings.MouseHitPredictionAmount
local ValidTargetParts = {"Head", "HumanoidRootPart"}

-- [VISUAL FOV & MOUSE BOX]
local mouse_box = Drawing.new("Square")
mouse_box.Visible = false
mouse_box.ZIndex = 999
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = SilentAimSettings.FOVRadius
fov_circle.Filled = false
fov_circle.Visible = SilentAimSettings.FOVVisible
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

-- [UTILS]
local function CalculateChance(pct)
    return (math.random() * 100) <= pct
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function IsPlayerVisible(Player)
    local LPChar, Char = LocalPlayer.Character, Player.Character
    if not LPChar or not Char then return false end
    local Root = Char:FindFirstChild(SilentAimSettings.TargetPart) or Char:FindFirstChild("HumanoidRootPart")
    if not Root then return false end
    return #GetPartsObscuringTarget(Camera, {Root.Position}, {LPChar, Char}) == 0
end

local function getClosestPlayer()
    local closest, dist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if SilentAimSettings.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local Char = player.Character
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
        local Humanoid = Char and Char:FindFirstChild("Humanoid")
        if not HRP or not Humanoid or Humanoid.Health <= 0 then continue end

        if SilentAimSettings.VisibleCheck and not IsPlayerVisible(player) then continue end

        local screenPos, onScreen = WorldToViewportPoint(Camera, HRP.Position)
        if not onScreen then continue end
        local mag = (getMousePosition() - Vector2.new(screenPos.X, screenPos.Y)).Magnitude

        if mag < dist and mag <= SilentAimSettings.FOVRadius then
            dist = mag
            closest = SilentAimSettings.TargetPart == "Random" and Char[ValidTargetParts[math.random(1, #ValidTargetParts)]] or Char[SilentAimSettings.TargetPart]
        end
    end
    return closest
end

-- [RENDERSTEPPED]
resume(create(function()
    RunService.RenderStepped:Connect(function()
        if SilentAimSettings.ShowSilentAimTarget and SilentAimSettings.Enabled then
            local Target = getClosestPlayer()
            if Target then
                local pos, onScreen = WorldToViewportPoint(Camera, Target.Position)
                mouse_box.Visible = onScreen
                mouse_box.Position = Vector2.new(pos.X, pos.Y)
            else
                mouse_box.Visible = false
            end
        else
            mouse_box.Visible = false
        end

        if SilentAimSettings.FOVVisible then
            fov_circle.Visible = true
            fov_circle.Position = getMousePosition()
        else
            fov_circle.Visible = false
        end
    end)
end))

-- [HOOKS]
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local args, method, self = {...}, getnamecallmethod(), {...}[1]
    if checkcaller() or not SilentAimSettings.Enabled then return oldNamecall(...) end
    if self ~= workspace or not CalculateChance(SilentAimSettings.HitChance) then return oldNamecall(...) end

    local Hit = getClosestPlayer()
    if not Hit then return oldNamecall(...) end

    local RayMethods = {
        FindPartOnRayWithIgnoreList = 2,
        FindPartOnRayWithWhitelist = 2,
        FindPartOnRay = 2,
        Raycast = 3
    }

    local index = RayMethods[method]
    if not index or not args[index] then return oldNamecall(...) end

    local Origin = args[index].Origin or args[2]
    local Direction = getDirection(Origin, Hit.Position)
    if method == "Raycast" then
        args[3] = Direction
    else
        args[2] = Ray.new(Origin, Direction)
    end

    return oldNamecall(unpack(args))
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, idx)
    if checkcaller() then return oldIndex(self, idx) end
    if self == Mouse and SilentAimSettings.Enabled and SilentAimSettings.SilentAimMethod == "Mouse.Hit/Target" then
        local Hit = getClosestPlayer()
        if Hit then
            if idx:lower() == "target" then return Hit end
            if idx:lower() == "hit" then
                return SilentAimSettings.MouseHitPrediction and (Hit.CFrame + (Hit.Velocity * PredictionAmount)) or Hit.CFrame
            end
        end
    end
    return oldIndex(self, idx)
end))

-- [CONFIG I/O]
local ConfigFolder = "UniversalSilentAim"
local PlaceFolder = ConfigFolder .. "/" .. tostring(game.PlaceId)
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
if not isfolder(PlaceFolder) then makefolder(PlaceFolder) end

function getgenv()._GetSilentAimFiles()
    local files = {}
    for _, f in ipairs(listfiles(PlaceFolder)) do
        if f:sub(-4) == ".lua" then
            local name = f:match(".+/(.-)%.lua")
            table.insert(files, name)
        end
    end
    return files
end

function getgenv()._CreateSilentAimConfig(name)
    writefile(string.format("%s/%s.lua", PlaceFolder, name), HttpService:JSONEncode(SilentAimSettings))
end

function getgenv()._SaveSilentAimConfig(name)
    getgenv()._CreateSilentAimConfig(name)
end

function getgenv()._LoadSilentAimConfig(name)
    local path = string.format("%s/%s.lua", PlaceFolder, name)
    if not isfile(path) then return end
    local data = HttpService:JSONDecode(readfile(path))
    for k, v in pairs(data) do
        SilentAimSettings[k] = v
    end
end
