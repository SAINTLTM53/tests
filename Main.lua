-- Add inside your AutofarmBox group:

AutofarmBox:AddToggle("LoopConstruction", {
    Text = "Loop Construction 🏗️",
    Default = false,
    Tooltip = "Auto serverhop + construct forever.",
    Callback = function(Value)
        if Value then
            Library:Notify("🌀 Construction Loop Started", 3)
            _G.IsLoopingFarm = true
            _G.FarmAfterHop = "Construction"

            task.spawn(function()
                while _G.IsLoopingFarm and _G.FarmAfterHop == "Construction" do
                    print("[Loop] Running Construction...")
                    local success, err = pcall(function()
                        -- Insert core construction logic here:
                        local wallCFrames = {
                            {"Wall1 Prompt", CFrame.new(-1672.1, 368.8, -1192.8)},
                            {"Wall1 Prompt2", CFrame.new(-1672.1, 368.8, -1180.0)},
                            {"Wall1 Prompt3", CFrame.new(-1672.1, 368.8, -1165.9)},
                            {"Wall2 Prompt", CFrame.new(-1704.8, 367.9, -1150.3)},
                            {"Wall2 Prompt2", CFrame.new(-1717.0, 367.9, -1150.3)},
                            {"Wall3 Prompt", CFrame.new(-1730.0, 367.9, -1150.3)},
                            {"Wall3 Prompt2", CFrame.new(-1742.0, 367.9, -1150.3)},
                            {"Wall4 Prompt", CFrame.new(-1760.9, 367.9, -1150.3)},
                            {"Wall4 Prompt2", CFrame.new(-1774.7, 367.9, -1150.3)},
                        }

                        local function tp(cf)
                            LocalPlayer.Character.HumanoidRootPart.CFrame = cf
                            task.wait(0.3)
                        end

                        local function firePrompt(prompt)
                            if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                                prompt.RequiresLineOfSight = false
                                prompt.HoldDuration = 0
                                fireproximityprompt(prompt)
                            end
                        end

                        local function waitForTool(tool)
                            for _ = 1, 30 do
                                if LocalPlayer.Backpack:FindFirstChild(tool) then
                                    LocalPlayer.Backpack[tool].Parent = LocalPlayer.Character
                                end
                                if LocalPlayer.Character:FindFirstChild(tool) then return true end
                                task.wait(0.1)
                            end
                            return false
                        end

                        local originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                        local wallQueue = {}

                        for _, data in ipairs(wallCFrames) do
                            local obj = workspace.ConstructionStuff:FindFirstChild(data[1], true)
                            local prompt = obj and obj:FindFirstChildWhichIsA("ProximityPrompt")
                            if prompt and prompt.Enabled then
                                table.insert(wallQueue, { cf = data[2], prompt = prompt })
                            end
                        end

                        if #wallQueue == 0 then
                            warn("❌ No walls available")
                            return
                        end

                        local startPrompt = workspace.ConstructionStuff:FindFirstChild("Start Job"):FindFirstChildWhichIsA("ProximityPrompt")
                        if startPrompt and startPrompt.Enabled then
                            tp(startPrompt.Parent.CFrame)
                            firePrompt(startPrompt)
                            task.wait(0.5)
                        end

                        for _, wall in ipairs(wallQueue) do
                            tp(wall.cf)
                            local plyGrabPrompt = workspace.ConstructionStuff:FindFirstChild("Grab Wood"):FindFirstChildWhichIsA("ProximityPrompt")
                            if plyGrabPrompt and plyGrabPrompt.Enabled then
                                tp(plyGrabPrompt.Parent.CFrame)
                                firePrompt(plyGrabPrompt)
                                task.wait(0.1)
                                firePrompt(plyGrabPrompt)
                                waitForTool("PlyWood")
                            end
                            tp(wall.cf)
                            for _ = 1, 9 do
                                firePrompt(wall.prompt)
                                task.wait(0.06)
                            end
                            task.wait(0.2)
                        end

                        local stopPrompt = workspace.ConstructionStuff:FindFirstChild("Start Job"):FindFirstChildWhichIsA("ProximityPrompt")
                        if stopPrompt and stopPrompt.Enabled then
                            tp(stopPrompt.Parent.CFrame)
                            firePrompt(stopPrompt)
                            task.wait(0.3)
                        end

                        tp(originalPosition)
                    end)

                    if not success then warn("[Loop Error]", err) end

                    Library:Notify("🌐 Server hopping...", 2)
                    task.wait(0.5)

                    -- Server hop
                    local servers = {}
                    local req = syn and syn.request or http_request or request
                    local res = req({
                        Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                    })
                    local data = HttpService:JSONDecode(res.Body)
                    for _, s in ipairs(data.data) do
                        if s.playing < s.maxPlayers and s.id ~= game.JobId then
                            table.insert(servers, s.id)
                        end
                    end
                    if #servers > 0 then
                        queue_on_teleport([[
                            repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
                            getgenv()._FarmAfterHop = "Construction"
                            getgenv()._FromHop = true
                            loadstring(game:HttpGet("https://raw.githubusercontent.com/SAINTLTM53/tests/refs/heads/main/Main.lua"))()
                        ]])
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
                        while true do task.wait() end
                    end
                end
            end)
        else
            _G.IsLoopingFarm = false
            Library:Notify("⛔ Construction Loop Stopped", 3)
        end
    end
})
