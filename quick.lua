local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Remotes & Mappings
local exoticRemote = ReplicatedStorage:WaitForChild("ExoticShopRemote")

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

-- Clean Name
local function cleanItemName(name)
    return (name:gsub("%s*%b()", "")) 
end

-- Core Purchase Logic
local function BuyItemFromQuickList(selectedItem)
    if not selectedItem then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if exoticRemoteItems[selectedItem] then
        local remoteName = exoticRemoteItems[selectedItem]
        local success, result = pcall(function()
            return exoticRemote:InvokeServer(remoteName)
        end)
        if success then
            print("✅ Bought:", remoteName)
        else
            warn("❌ Remote failed:", result)
        end
        return
    end

    local model = specialItemModels[selectedItem]
    if not model then
        warn("❌ Item model not found:", selectedItem)
        return
    end

    local prompt = model:FindFirstChild("BuyPrompt", true)
    local cleanName = cleanItemName(selectedItem)
    local originalPos = root.Position

    local modelCFrame = model:GetPivot()
    local targetCFrame = modelCFrame + Vector3.new(0, 3, -4)
    local selectedMethod = (Options and Options.TeleportMethod and Options.TeleportMethod.Value) or _G.teleportMethod or "Seat spoof method"

    if selectedMethod == "Seat spoof method" and _G.SeatSpoofTeleport then
        _G.SeatSpoofTeleport(targetCFrame)
    elseif selectedMethod == "Fastest tp method" and _G.FastestTeleport then
        _G.FastestTeleport(targetCFrame)
    else
        warn("❌ No valid teleport method.")
        return
    end

    task.wait(0.75)

    if prompt and prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
        task.wait(0.5)

        local timeout = tick() + 3
        while tick() < timeout do
            local tool = LocalPlayer.Backpack:FindFirstChild(cleanName) or LocalPlayer.Character:FindFirstChild(cleanName)
            if tool then
                if tool.Parent == LocalPlayer.Backpack then
                    LocalPlayer.Character.Humanoid:EquipTool(tool)
                    task.wait(0.1)
                end

                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)

                if selectedMethod == "Seat spoof method" then
                    _G.SeatSpoofTeleport(CFrame.new(originalPos))
                elseif selectedMethod == "Fastest tp method" then
                    _G.FastestTeleport(CFrame.new(originalPos))
                end
                return
            end
            task.wait(0.1)
        end
        warn("❌ Tool not equipped:", cleanName)
    else
        warn("❌ No BuyPrompt for:", cleanName)
    end

    if selectedMethod == "Seat spoof method" then
        _G.SeatSpoofTeleport(CFrame.new(originalPos))
    elseif selectedMethod == "Fastest tp method" then
        _G.FastestTeleport(CFrame.new(originalPos))
    end
end

-- 🎛️ Obsidian UI Integration
local buyOptions = {}
for name in pairs(exoticRemoteItems) do table.insert(buyOptions, name) end
for name in pairs(specialItemModels) do table.insert(buyOptions, name) end
table.sort(buyOptions)

local selectedItem = buyOptions[1]

Tele:AddDropdown("QuickBuyDropdown", {
    Values = buyOptions,
    Default = buyOptions[1],
    Multi = false,
    Text = "Select Item to Buy",
    Tooltip = "Choose an exotic item to purchase.",
}):OnChanged(function(value)
    selectedItem = value
end)

Tele:AddButton("Buy Selected Item", function()
    local success, err = pcall(function()
        BuyItemFromQuickList(selectedItem)
    end)
    if not success then
        Library:Notify("❌ Failed: " .. tostring(err), 4)
    end
end)
