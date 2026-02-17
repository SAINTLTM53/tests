local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local exoticRemote = ReplicatedStorage:WaitForChild("ExoticShopRemote")

local exoticRemoteItems = {
    ["Bandage($350)"] = "Bandage",
    ["Lemonade($500)"] = "Lemonade",
    ["Shiesty($75)"] = "Shiesty",
    ["Sledge Hammer($400)"] = "Sledge Hammer",
    ["FakeCard($700)"] = "FakeCard",
    ["Ice-Fruit Bag($2500)"] = "Ice-Fruit Bag",
    ["Ice-Fruit Cupz($150)"] = "Ice-Fruit Cupz",
    ["FijiWater($48)"] = "FijiWater",
    ["FreshWater($48)"] = "FreshWater"
}

local specialItemModels = {
    ["Coffe($25)"] = workspace.GUNS:FindFirstChild("Coffe"),
    ["RedEliteBag($500)"] = workspace.GUNS:FindFirstChild("RedEliteBag"),
    ["Red RCR Bag($2000)"] = workspace.GUNS:FindFirstChild("Red RCR Bag"),
    ["RCR Bag($2000)"] = workspace.GUNS:FindFirstChild("RCR Bag"),
    ["Drac Bag($700)"] = workspace.GUNS:FindFirstChild("Drac Bag"),
    ["DesignerBag($2000)"] = workspace.GUNS:FindFirstChild("DesignerBag"),
    ["BlueEliteBag($500)"] = workspace.GUNS:FindFirstChild("BlueEliteBag"),
    ["Black RCR Bag($2000)"] = workspace.GUNS:FindFirstChild("Black RCR Bag"),
    ["BagElite($500)"] = workspace.GUNS:FindFirstChild("BagElite")
}

local function cleanItemName(name)
    return (name:gsub("%s*%b()", "")) 
end

getgenv().BuyItemFromQuickList = function(selectedItem)
    if not selectedItem then return end

    if exoticRemoteItems[selectedItem] then
        local remoteName = exoticRemoteItems[selectedItem]
        local ok, err = pcall(function()
            return exoticRemote:InvokeServer(remoteName)
        end)
        return
    end

local model = specialItemModels[selectedItem]
local character = LocalPlayer.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
local humanoid = character and character:FindFirstChildOfClass("Humanoid")

if not model or not root or not humanoid then return end

local cleanName = cleanItemName(selectedItem)
local prompt = model:FindFirstChild("BuyPrompt", true)
if not prompt then return end

local modelCFrame = model:GetPivot()
if not modelCFrame then return end

local offset = CFrame.new(0, 4, -6) -- higher + further back
local targetCFrame = modelCFrame * offset

local oldPlatformStand = humanoid.PlatformStand
local oldAutoRotate = humanoid.AutoRotate

humanoid.PlatformStand = true
humanoid.AutoRotate = false

root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero

if _G.teleportTo then
    _G.teleportTo(targetCFrame)
else
    root.CFrame = targetCFrame
end

task.wait(0.15)

root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero

humanoid.PlatformStand = oldPlatformStand
humanoid.AutoRotate = oldAutoRotate

    task.wait(0.75)

    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    fireproximityprompt(prompt)
    task.wait(0.5)

    local timeout = tick() + 3
    while tick() < timeout do
        local tool = LocalPlayer.Backpack:FindFirstChild(cleanName) or LocalPlayer.Character:FindFirstChild(cleanName)
        if tool and tool:IsA("Tool") then
            if tool.Parent == LocalPlayer.Backpack then
                LocalPlayer.Character.Humanoid:EquipTool(tool)
                task.wait(0.1)
            end

            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            break
        end
        task.wait(0.1)
    end

    if _G.teleportTo then
        _G.teleportTo(CFrame.new(originalPos))
    end
end
