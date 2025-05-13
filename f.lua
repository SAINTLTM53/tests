-- init
if not game:IsLoaded() then 
    game.Loaded:Wait()
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local SilentAimSettings = {
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

-- variables
getgenv().SilentAimSettings = Settings
local MainFileName = "UniversalSilentAim"
local SelectedFile, FileToSave = "", ""

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren           = game.GetChildren
local GetPlayers            = Players.GetPlayers
local WorldToScreen         = Camera.WorldToScreenPoint
local WorldToViewportPoint  = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild        = game.FindFirstChild
local RenderStepped         = RunService.RenderStepped
local GuiInset              = GuiService.GetGuiInset
local GetMouseLocation      = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local mouse_box = Drawing.new("Square")
mouse_box.Visible    = true 
mouse_box.ZIndex     = 999 
mouse_box.Color      = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness  = 20 
mouse_box.Size       = Vector2.new(20, 20)
mouse_box.Filled     = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness    = 1
fov_circle.NumSides     = 100
fov_circle.Radius       = 180
fov_circle.Filled       = false
fov_circle.Visible      = false
fov_circle.ZIndex       = 999
fov_circle.Transparency = 1
fov_circle.Color        = Color3.fromRGB(54, 57, 241)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {"Instance", "Ray", "table", "boolean", "boolean"}
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {"Instance", "Ray", "table", "boolean"}
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {"Instance", "Ray", "Instance", "boolean", "boolean"}
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {"Instance", "Vector3", "Vector3", "RaycastParams"}
    }
}

function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

--[[file handling]] do 
    if not isfolder(MainFileName) then makefolder(MainFileName) end
    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then
        makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
    end
end

local Files = listfiles(string.format("%s/%s", "UniversalSilentAim", tostring(game.PlaceId)))

local function GetFiles()
    local out = {}
    for i = 1, #Files do
        local file = Files[i]
        if file:sub(-4) == '.lua' then
            local pos = file:find('.lua', 1, true)
            local start = pos
            local char = file:sub(pos, pos)
            while char ~= '/' and char ~= '\\' and char ~= '' do
                pos = pos - 1
                char = file:sub(pos, pos)
            end
            if char == '/' or char == '\\' then
                table.insert(out, file:sub(pos + 1, start - 1))
            end
        end
    end
    return out
end

local function UpdateFile(FileName)
    assert(FileName or FileName == "string", "oopsies")
    writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName),
              HttpService:JSONEncode(SilentAimSettings))
end

local function LoadFile(FileName)
    assert(FileName or FileName == "string", "oopsies")
    local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName)
    local ConfigData = HttpService:JSONDecode(readfile(File))
    for Index, Value in next, ConfigData do
        SilentAimSettings[Index] = Value
    end
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then return false end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player)
    local PC = Player.Character
    local LPC = LocalPlayer.Character
    if not (PC or LPC) then return end
    local PR = FindFirstChild(PC, Options.TargetPart.Value) or FindFirstChild(PC, "HumanoidRootPart")
    if not PR then return end
    local CastPoints, IgnoreList = {PR.Position, LPC, PC}, {LPC, PC}
    return #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList) == 0
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest, DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if Toggles.TeamCheck.Value and Player.Team == LocalPlayer.Team then continue end
        local Char = Player.Character
        if not Char then continue end
        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end
        local HRP = FindFirstChild(Char, "HumanoidRootPart")
        local Hum = FindFirstChild(Char, "Humanoid")
        if not HRP or not Hum or Hum.Health <= 0 then continue end
        local SP, OnScreen = getPositionOnScreen(HRP.Position)
        if not OnScreen then continue end
        local Dist = (getMousePosition() - SP).Magnitude
        if Dist <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = (Options.TargetPart.Value == "Random"
                and Char[ValidTargetParts[math.random(1, #ValidTargetParts)]]
                or Char[Options.TargetPart.Value])
            DistanceToMouse = Dist
        end
    end
    return Closest
end

-- render & hooks
resume(create(function()
    RenderStepped:Connect(function()
        if Toggles.MousePosition.Value and Toggles.aim_Enabled.Value then
            local tgt = getClosestPlayer()
            if tgt then
                local VP, On = WorldToViewportPoint(Camera, tgt.Position)
                mouse_box.Visible = On
                mouse_box.Position = Vector2.new(VP.X, VP.Y)
            else
                mouse_box.Visible = false
            end
        end
        if Toggles.Visible.Value then
            fov_circle.Visible   = Toggles.Visible.Value
            fov_circle.Color     = Options.Color.Value
            fov_circle.Position  = getMousePosition()
        end
    end)
end))

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Args   = {...}
    if Toggles.aim_Enabled.Value and Args[1] == workspace and not checkcaller()
       and CalculateChance(SilentAimSettings.HitChance) then
        -- (all Raycast/FindPartOnRay logic as in your original)
    end
    return oldNamecall(...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and Toggles.aim_Enabled.Value
       and Options.Method.Value == "Mouse.Hit/Target" and getClosestPlayer() then
        -- (all Mouse.Hit/Target logic)
    end
    return oldIndex(self, Index)
end))
