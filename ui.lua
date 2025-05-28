AutofarmBox:AddToggle("LoopStudio", {
    Text = "Loop Studio Farm 🎬",
    Default = false,
    Tooltip = "Continuously farms studio prompts and serverhops.",
    Callback = function(Value)
        if Value then
            Library:Notify("🎬 Studio Farm Loop Started", 3)
            _G.IsLoopingFarm = true
            _G.FarmAfterHop = "Studio"
            getgenv()._FromHop = nil
            _G.FromHop = false

            task.spawn(function()
                while _G.IsLoopingFarm and _G.FarmAfterHop == "Studio" do
                    local success, err = pcall(function()
                        local foundPrompts = {}
                        for _, prompt in pairs(workspace.StudioPay:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") and prompt.Name == "Prompt" and prompt.Enabled then
                                local part = prompt.Parent
                                if part:IsA("BasePart") then
                                    table.insert(foundPrompts, {Prompt = prompt, Position = part.Position})
                                end
                            end
                        end

                        for _, data in ipairs(foundPrompts) do
                            local prompt = data.Prompt
                            local pos = data.Position + Vector3.new(0, 2, 0)
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
                            repeat fireproximityprompt(prompt) task.wait(0.25) until not prompt.Enabled
                        end

                        if #foundPrompts == 0 then
                            warn("❌ No Studio prompts available.")
                        end
                    end)

                    if not success then warn("[Loop Error] Studio:", err) end

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
                            getgenv()._FarmAfterHop = "Studio"
                            getgenv()._FromHop = true
                            loadstring(game:HttpGet("https://raw.githubusercontent.com/SAINTLTM53/tests/refs/heads/main/ui.lua"))()
                        ]])
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
                        while true do task.wait() end
                    end
                end
            end)
        else
            _G.IsLoopingFarm = false
            Library:Notify("⛔ Studio Farm Loop Stopped", 3)
        end
    end
})
