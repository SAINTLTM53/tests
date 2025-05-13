-- logic.lua

-- init + protectgui stub
if not game:IsLoaded() then game.Loaded:Wait() end
if not syn or not protectgui then getgenv().protectgui = function() end end

-- settings
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

-- Drawing objects (exposed for UI)
getgenv().mouse_box    = Drawing.new("Square")
local mouse_box        = getgenv().mouse_box
mouse_box.Visible      = false
mouse_box.ZIndex       = 999
mouse_box.Color        = Color3.fromRGB(54,57,241)
mouse_box.Thickness    = 20
mouse_box.Size         = Vector2.new(20,20)
mouse_box.Filled       = true

getgenv().fov_circle   = Drawing.new("Circle")
local fov_circle       = getgenv().fov_circle
fov_circle.Thickness   = 1
fov_circle.NumSides    = 100
fov_circle.Radius      = SilentAimSettings.FOVRadius
fov_circle.Filled      = false
fov_circle.Visible     = false
fov_circle.ZIndex      = 999
fov_circle.Transparency= 1
fov_circle.Color       = Color3.fromRGB(54,57,241)

-- caching functions
local GetChildren           = game.GetChildren
local GetPlayers            = Players.GetPlayers
local WorldToScreen         = Camera.WorldToScreenPoint
local WorldToViewportPoint  = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild        = game.FindFirstChild
local RenderStepped         = RunService.RenderStepped
local GetMouseLocation      = UserInputService.GetMouseLocation
local resume = coroutine.resume
local create = coroutine.create

local ValidTargetParts = {"Head","HumanoidRootPart"}
local PredictionAmount = 0.165

-- raycast specs
local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {ArgCountRequired=3, Args={"Instance","Ray","table","boolean","boolean"}},
    FindPartOnRayWithWhitelist = {ArgCountRequired=3, Args={"Instance","Ray","table","boolean"}},
    FindPartOnRay            = {ArgCountRequired=2, Args={"Instance","Ray","Instance","boolean","boolean"}},
    Raycast                  = {ArgCountRequired=3, Args={"Instance","Vector3","Vector3","RaycastParams"}},
}

-- Calculate hit chance
local function CalculateChance(p)
    p = math.floor(p)
    return RandomService:NextNumber() <= p/100
end

-- Mouse position helper
local function getMousePos()
    local m = GetMouseLocation(UserInputService)
    return Vector2.new(m.X,m.Y)
end

-- Direction vector helper
local function getDirection(o,p)
    return (p-o).Unit * 1000
end

-- Visibility check
local function IsVisible(part)
    return #Camera:GetPartsObscuringTarget({part.Position},{LocalPlayer.Character}) == 0
end

-- Find closest valid player
local function getClosestPlayer()
    local best,bd = nil,math.huge
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl~=LocalPlayer and pl.Character and pl.Character:FindFirstChild("Humanoid").Health>0 then
            if SilentAimSettings.TeamCheck and pl.Team==LocalPlayer.Team then continue end
            local part = pl.Character:FindFirstChild(SilentAimSettings.TargetPart)
                      or pl.Character:FindFirstChild("HumanoidRootPart")
            if part and (not SilentAimSettings.VisibleCheck or IsVisible(part)) then
                local on,x,y = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(x,y)-getMousePos()).Magnitude
                    if d<bd and d<=SilentAimSettings.FOVRadius then best,bd=part,d end
                end
            end
        end
    end
    return best
end

-- Draw loop & hooks
RunService.RenderStepped:Connect(function()
    if SilentAimSettings.ShowSilentAimTarget and SilentAimSettings.Enabled then
        local tgt = getClosestPlayer()
        if tgt then
            local _,x,y = Camera:WorldToViewportPoint(tgt.Position)
            mouse_box.Visible,mouse_box.Position = true,Vector2.new(x,y)
        else
            mouse_box.Visible = false
        end
    end
    fov_circle.Visible   = SilentAimSettings.FOVVisible
    fov_circle.Radius    = SilentAimSettings.FOVRadius
    fov_circle.Position  = getMousePos()
end)

local oldNC
oldNC = hookmetamethod(game,"__namecall",newcclosure(function(self,...)
    local m = getnamecallmethod():lower()
    if SilentAimSettings.Enabled and self==workspace
       and not checkcaller() and CalculateChance(SilentAimSettings.HitChance)
       and m:find("ray")
    then
        local o,d = ...
        local tgt = getClosestPlayer()
        if tgt then
            d = getDirection(o,tgt.Position)
            return oldNC(self,o,d,select(3,...))
        end
    end
    return oldNC(self,...)
end))

local oldIdx
oldIdx = hookmetamethod(game,"__index",newcclosure(function(self,i)
    if self==Mouse and SilentAimSettings.Enabled and i:lower()=="hit" then
        local tgt=getClosestPlayer()
        if tgt then return tgt.CFrame end
    end
    return oldIdx(self,i)
end))
