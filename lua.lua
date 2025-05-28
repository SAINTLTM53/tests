AutofarmBox:AddToggle("LoopHouse", {
    Text = "Loop House Robbery 🏠",
    Default = false,
    Tooltip = "Continuously robs houses and serverhops.",
    Callback = function(Value)
        if Value then
            Library:Notify("🏠 House Robbery Loop Started", 3)
            _G.IsLoopingFarm = true
            _G.FarmAfterHop = "House"
            getgenv()._FromHop = nil
            _G.FromHop = false

            task.spawn(function()
                while _G.IsLoopingFarm and _G.FarmAfterHop == "House" do
                    local success, err = pcall(function()
                        local function KickDownDoor(cf)
                            local rayOrigin = cf.Position + Vector3.new(0, 5, 0)
                            local rayDir = Vector3.new(0, -10, 0)
                            local part = workspace:FindPartOnRay(Ray.new(rayOrigin, rayDir))
                            if part and part.CanCollide then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = cf
                                local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    prompt.RequiresLineOfSight = false
                                    for _ = 1, 8 do fireproximityprompt(prompt) task.wait(0.1) end
                                    local timer, timeout = 0, 5
                                    while part.CanCollide and part.Transparency < 1 and timer < timeout do
                                        fireproximityprompt(prompt)
                                        task.wait(0.2)
                                        timer += 0.2
                                    end
                                end
                            end
                            return part and not part.CanCollide and part.Transparency >= 1
                        end

                        local function LootMoney(cframes)
                            for _, cf in ipairs(cframes) do
                                for _, obj in ipairs(workspace:GetDescendants()) do
                                    if obj:IsA("BasePart") and obj.Name == "MoneyGrab" and obj.Transparency < 1 and (obj.Position - cf.Position).Magnitude < 1 then
                                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
                                        if prompt then
                                            prompt.RequiresLineOfSight = false
                                            LocalPlayer.Character.HumanoidRootPart.CFrame = cf
                                            task.wait(0.3)
                                            for _ = 1, 6 do fireproximityprompt(prompt) task.wait(0.05) end
                                        end
                                        break
                                    end
                                end
                            end
                        end

                        local hardDoor = CFrame.new(-590.680908, 254.330566, -701.006226)
                        local woodDoor = CFrame.new(-590.787598, 254.334854, -679.249634)

                        local hardCash = {
                    CFrame.new(-598.759521, 252.007339, -711.958496),
                    CFrame.new(-607.092285, 253.089981, -701.857544),
                    CFrame.new(-598.39502, 252.392899, -711.153625),
                    CFrame.new(-607.836914, 253.089981, -702.305664),
                    CFrame.new(-598.257446, 252.007339, -710.849792),
                    CFrame.new(-598.767456, 252.131973, -711.97583),
                    CFrame.new(-598.401245, 252.131973, -711.167175),
                    CFrame.new(-598.437256, 252.274185, -711.246765),
                    CFrame.new(-598.757446, 252.274185, -711.953796),
                    CFrame.new(-598.757446, 252.397659, -711.953796),
                    CFrame.new(-598.757446, 252.537674, -711.953796),
                    CFrame.new(-598.757446, 252.676651, -711.953796),
                    CFrame.new(-598.757446, 252.810562, -711.953796),
                    CFrame.new(-598.54248, 252.007339, -711.479187),
                    CFrame.new(-598.39502, 252.546158, -711.153625),
                    CFrame.new(-598.39502, 252.704727, -711.153625),
                    CFrame.new(-598.39502, 252.830399, -711.153625),
                    CFrame.new(-598.39502, 252.96846, -711.153625),
                    CFrame.new(-610.890747, 253.170853, -703.304565),
                    CFrame.new(-610.810791, 253.050858, -703.322083),
                    CFrame.new(-608.896362, 253.209976, -702.94342),
                    CFrame.new(-608.890869, 253.089981, -703.01123),
                    CFrame.new(-607.801392, 253.209976, -702.209412),
                }
                        local woodCash = {
                    CFrame.new(-601.734985, 253.181381, -684.773926),
                    CFrame.new(-598.345337, 253.334213, -684.057373),
                    CFrame.new(-600.543457, 253.061386, -684.503174),
                    CFrame.new(-598.345337, 253.200363, -684.100647),
                    CFrame.new(-601.755981, 253.061386, -683.188782),
                    CFrame.new(-601.649414, 253.061386, -684.90033),
                    CFrame.new(-600.591797, 253.334213, -684.503174),
                    CFrame.new(-600.548462, 253.200363, -684.503174),
                    CFrame.new(-603.292969, 253.10051, -682.698669),
                    CFrame.new(-599.430908, 253.334213, -684.232666),
                    CFrame.new(-599.474121, 253.200363, -684.232666),
                    CFrame.new(-599.479248, 253.061386, -684.232666),
                    CFrame.new(-598.345337, 253.061386, -684.105713)
                }

                        local robbed = false
                        if KickDownDoor(hardDoor) then
                            LootMoney(hardCash)
                            robbed = true
                        elseif KickDownDoor(woodDoor) then
                            LootMoney(woodCash)
                            robbed = true
                        end

                        if not robbed then
                            warn("❌ No houses to rob.")
                        end
                    end)

                    if not success then warn("[Loop Error] House:", err) end

                    Library:Notify("🔁 Hopping Server...", 2)
                    task.wait(0.5)

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
                            getgenv()._FarmAfterHop = "House"
                            getgenv()._FromHop = true
                            loadstring(game:HttpGet("https://raw.githubusercontent.com/SAINTLTM53/tests/refs/heads/main/lua"))()
                        ]])
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
                        while true do task.wait() end
                    end
                end
            end)
        else
            _G.IsLoopingFarm = false
            Library:Notify("⛔ House Robbery Loop Stopped", 3)
        end
    end
})
