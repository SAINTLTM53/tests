local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

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

local function cleanItemName(name)
    return (name:gsub("%s*%b()", "")) 
end

getgenv().BuyItemFromQuickList = function(selectedItem)
    if not selectedItem then
        warn("❌ No item selected.")
        return
    end

    if exoticRemoteItems[selectedItem] then
        local remoteName = exoticRemoteItems[selectedItem]
        local ok, err = pcall(function()
            return exoticRemote:InvokeServer(remoteName)
        end)
        if ok then
            print("✅ Bought:", remoteName)
        else
            warn("❌ Remote failed:", err)
        end
        return
    end

    local model = specialItemModels[selectedItem]
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not model or not root then return end

    local cleanName = cleanItemName(selectedItem)
    local prompt = model:FindFirstChild("BuyPrompt", true)
    local originalPos = root.Position

    teleportTo(model:GetModelCFrame().Position + Vector3.new(0, 3, -4))
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

                print("✅ Equipped:", cleanName)

                teleportTo(originalPos)
                return
            end
            task.wait(0.1)
        end

        warn("❌ Tool not equipped.")
    else
        warn("❌ No BuyPrompt for:", cleanName)
    end

    teleportTo(originalPos)
end
