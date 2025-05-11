local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Library = Library or shared.Library

local exoticRemote = ReplicatedStorage:WaitForChild("ExoticShopRemote")
local selectedItem = nil

local exoticRemoteItems = {
    ["Lemonade($500)"] = "Lemonade",
    ["FakeCard($700)"] = "FakeCard",
    ["Ice-Fruit Bag($2500)"] = "Ice-Fruit Bag",
    ["Ice-Fruit Cupz($150)"] = "Ice-Fruit Cupz",
    ["FijiWater($48)"] = "FijiWater",
    ["FreshWater($48)"] = "FreshWater"
}

local specialItemModels = {
    ["Coffe($25)"] = workspace.GUNS.Coffe,
    ["RedEliteBag($500)"] = workspace.GUNS.RedEliteBag,
    ["Red RCR Bag($2000)"] = workspace.GUNS["Red RCR Bag"],
    ["RCR Bag($2000)"] = workspace.GUNS["RCR Bag"],
    ["Drac Bag($700)"] = workspace.GUNS["Drac Bag"],
    ["DesignerBag($2000)"] = workspace.GUNS.DesignerBag,
    ["BlueEliteBag($500)"] = workspace.GUNS.BlueEliteBag,
    ["Black RCR Bag($2000)"] = workspace.GUNS["Black RCR Bag"],
    ["BagElite($500)"] = workspace.GUNS.BagElite,
}

local quickBuyItems = {
    "Lemonade($500)", "FakeCard($700)", "Ice-Fruit Bag($2500)", "Ice-Fruit Cupz($150)", "FijiWater($48)", "FreshWater($48)",
    "Coffe($25)", "RedEliteBag($500)", "Red RCR Bag($2000)", "RCR Bag($2000)", "Drac Bag($700)", "DesignerBag($2000)",
    "BlueEliteBag($500)", "Black RCR Bag($2000)", "BagElite($500)"
}

local function cleanItemName(name)
    return (name:gsub("%s*%b()", ""))
end

local function teleportWithFreefall(position)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not humanoid then return end

    local state = humanoid:GetState()
    humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    root.Velocity = Vector3.zero
    root.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    task.wait(0.15)
    humanoid:ChangeState(state)
end

local function handleSpecialItemPurchase(displayName)
    local model = specialItemModels[displayName]
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not model or not root then return false end

    local originalPosition = root.Position
    local cleanName = cleanItemName(displayName)
    local prompt = model:FindFirstChild("BuyPrompt", true)

    teleportWithFreefall(model:GetModelCFrame().Position + Vector3.new(0, 3, -4))
    task.wait(0.35)

    if prompt and prompt:IsA("ProximityPrompt") then
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

                Library:Notify("✅ Bought & Equipped: " .. cleanName, 2)
                teleportWithFreefall(originalPosition)
                return true
            end
            task.wait(0.1)
        end

        Library:Notify("❌ Failed to equip: " .. cleanName, 2)
    else
        Library:Notify("❌ No BuyPrompt found for: " .. cleanName, 2)
    end

    teleportWithFreefall(originalPosition)
    return false
end

local function buySelectedItem()
    if not selectedItem then
        Library:Notify("❌ No item selected.", 2)
        return
    end

    if exoticRemoteItems[selectedItem] then
        local remoteName = exoticRemoteItems[selectedItem]
        local success, err = pcall(function()
            return exoticRemote:InvokeServer(remoteName)
        end)

        if success then
            Library:Notify("✅ Successfully bought: " .. remoteName, 2)
        else
            Library:Notify("❌ Remote buy failed: " .. tostring(err), 2)
        end
        return
    end

    if specialItemModels[selectedItem] then
        local success = handleSpecialItemPurchase(selectedItem)
        if not success then
            Library:Notify("❌ Failed to buy or equip: " .. selectedItem, 2)
        end
    else
        Library:Notify("❌ Invalid item selected: " .. selectedItem, 2)
    end
end

return {
    quickBuyItems = quickBuyItems,
    selectedItem = selectedItem,
    buySelectedItem = buySelectedItem
}
