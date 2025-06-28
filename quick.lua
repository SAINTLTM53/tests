getgenv().BuyItemFromQuickList = function(selectedItem)
    if not selectedItem then
        return
    end

    if exoticRemoteItems[selectedItem] then
        local remoteName = exoticRemoteItems[selectedItem]
        local ok, err = pcall(function()
            return exoticRemote:InvokeServer(remoteName)
        end)
        if ok then
        else
        end
        return
    end

    local model = specialItemModels[selectedItem]
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not model or not root then
        return
    end

    local cleanName = cleanItemName(selectedItem)
    local prompt = model:FindFirstChild("BuyPrompt", true)
    if not prompt then
        return
    end

    local originalPos = root.Position
    local modelCFrame = model:GetPivot()
    if not modelCFrame then
        return
    end

    local targetCFrame = modelCFrame + Vector3.new(0, 3, -4)
    _G.teleportTo(targetCFrame)
    task.wait(0.75)

    if prompt:IsA("ProximityPrompt") then
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
    end

    _G.teleportTo(CFrame.new(originalPos))
end
