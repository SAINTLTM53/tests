-- logic.lua

-- init + protectgui stub
if not game:IsLoaded() then
    game.Loaded:Wait()
end
if not syn or not protectgui then
    getgenv().protectgui = function() end
end

-- settings table
local SilentAimSettings = {
    Enabled                  = false,
    ClassName                = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey                = "RightAlt",
    TeamCheck                = false,
    VisibleCheck             = false,
    TargetPart               = "HumanoidRootPart",
    SilentAimMethod          = "Raycast",
    FOVRadius                = 130,
    FOVVisible               = false,
    ShowSilentAimTarget      = false,
    MouseHitPrediction       = false,
    MouseHitPredictionAmount = 0.165,
    HitChance                = 100,
}
getgenv().SilentAimSettings = SilentAimSettings

-- services & locals
local HttpService       = game:GetService("HttpService")
local Camera            = workspace.CurrentCamera
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local GuiService        = game:GetService("GuiService")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer
local Mouse             = LocalPlayer:GetMouse()
local RandomService     = Random.new()

-- Drawing objects
local mouse_box = Drawing.new("Square")
mouse_box.Visible    = false
mouse_box.ZIndex     = 999
mouse_box.Color      = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness  = 20
mouse_box.Size       = Vector2.new(20, 20)
mouse_box.Filled     = true

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness    = 1
fov_circle.NumSides     = 100
fov_circle.Radius       = SilentAimSettings.FOVRadius
fov_circle.Filled       = false
fov_circle.Visible      = false
fov_circle.ZIndex       = 999
fov_circle.Transparency = 1
fov_circle.Color        = Color3.fromRGB(54, 57, 241)

-- file handling
local MainFileName = "UniversalSilentAim"
if not isfolder(MainFileName) then
    makefolder(MainFileName)
end
if not isfolder(MainFileName.."/"..tostring(game.PlaceId)) then
    makefolder(MainFileName.."/"..tostring(game.PlaceId))
end

local function GetFiles()
    local out = {}
    for _, file in ipairs(listfiles(MainFileName.."/"..tostring(game.PlaceId))) do
        if file:sub(-4) == ".lua" then
            local name = file:match("([^\\/]-)%.lua$")
            table.insert(out, name)
        end
    end
    return out
end

local function UpdateFile(name)
    writefile(
        ("%s/%s/%s.lua"):format(MainFileName, tostring(game.PlaceId), name),
        HttpService:JSONEncode(SilentAimSettings)
    )
end

local function LoadFile(name)
    local data = HttpService:JSONDecode(
        readfile(("%s/%s/%s.lua"):format(MainFileName, tostring(game.PlaceId), name))
    )
    for k, v in pairs(data) do
        SilentAimSettings[k] = v
    end
end

-- helpers
local function CalculateChance(pct)
    pct = math.floor(pct)
    return RandomService:NextNumber() <= pct/100
end

local function getMousePos()
    local m = UserInputService:GetMouseLocation()
    return Vector2.new(m.X, m.Y)
end

local function getDirection(origin, pos)
    return (pos - origin).Unit * 1000
end

local function IsVisible(part)
    local pts = { part.Position }
    local count = #Camera:GetPartsObscuringTarget(pts, { LocalPlayer.Character })
    return count == 0
end

local function getClosestPlayer()
    local best, bestDist = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local hum = pl.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                if SilentAimSettings.TeamCheck and pl.Team == LocalPlayer.Team then
                    continue
                end
                local part = pl.Character:FindFirstChild(SilentAimSettings.TargetPart)
                    or pl.Character:FindFirstChild("HumanoidRootPart")
                if part and (not SilentAimSettings.VisibleCheck or IsVisible(part)) then
                    local onScreen, x, y = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(x, y) - getMousePos()).Magnitude
                        if dist < bestDist and dist <= SilentAimSettings.FOVRadius then
                            best, bestDist = part, dist
                        end
                    end
                end
            end
        end
    end
    return best
end

-- rendering & hooks
RunService.RenderStepped:Connect(function()
    -- draw target box
    if SilentAimSettings.ShowSilentAimTarget and SilentAimSettings.Enabled then
        local tgt = getClosestPlayer()
        if tgt then
            local _, x, y = Camera:WorldToViewportPoint(tgt.Position)
            mouse_box.Visible  = true
            mouse_box.Position = Vector2.new(x, y)
        else
            mouse_box.Visible = false
        end
    end
    -- draw FOV circle
    fov_circle.Visible   = SilentAimSettings.FOVVisible
    fov_circle.Radius    = SilentAimSettings.FOVRadius
    fov_circle.Position  = getMousePos()
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod():lower()
    if SilentAimSettings.Enabled and self == workspace and not checkcaller()
       and CalculateChance(SilentAimSettings.HitChance) then
        if method:find("ray") then
            local origin, direction = ...
            local tgt = getClosestPlayer()
            if tgt then
                direction = getDirection(origin, tgt.Position)
                return oldNamecall(self, origin, direction, select(3, ...))
            end
        end
    end
    return oldNamecall(self, ...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, idx)
    if self == Mouse and SilentAimSettings.Enabled and idx:lower() == "hit" then
        local tgt = getClosestPlayer()
        if tgt then return tgt.CFrame end
    end
    return oldIndex(self, idx)
end))
