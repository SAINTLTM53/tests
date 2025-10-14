-- OutfitUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tabs = shared.Tabs or getgenv().Tabs
local Library = shared.Library or getgenv().Library

local ClothShopRemote = ReplicatedStorage:WaitForChild("ClothShopRemote")
local ClothingList = require(ReplicatedStorage:WaitForChild("ClothingList"))

local Shirts, Pants = ClothingList.Shirts, ClothingList.Pants

local Hats = {
    "BlackPuffer", "Essential Hood", "MRHoodieBRR", "HeadScarf", "PinkCleezy", "RedHat", "BlackHat",
    "BluHat", "WhiteFurHoodie", "BlackFurHoodie", "BlueCleezy", "RedCleezy", "CleezyB", "Hood"
}
local Glasses = { "PinkShades", "BlackShades", "RedShades", "BluShades", "DarkShades", "Glasses" }
local Shiestys = { "ShiestyBlu", "ShiestyDesign", "PinkShiesty", "RedShiesty", "Shiesty", "BluShiesty", "YellowShiesty", "ShiestyRed", "WhiteShiesty" }
local Masks = { "MacReddy", "SkullMask", "MaskH", "ClownMask", "MRCLOWN MAN", "JasonMask" }

local function toDropdownOptions(list)
    local result = {}
    for _, item in ipairs(list) do
        if typeof(item) == "string" then
            table.insert(result, item)
        elseif typeof(item) == "table" and item.Name then
            table.insert(result, item.Name)
        end
    end
    return result
end

getgenv().WearOutfit = function(category, item)
    task.spawn(function()
        ClothShopRemote:FireServer("Buy", category, item)
        task.wait(0.15)
        ClothShopRemote:FireServer("Wear", category, item)
        Library:Notify("Equipped " .. item .. " from " .. category, 3)
    end)
end

local Remote = ClothShopRemote

local OutfitComponent = {}
OutfitComponent.__index = OutfitComponent
function OutfitComponent.new(name, steps)
    return setmetatable({ name = name, steps = steps }, OutfitComponent)
end
function OutfitComponent:apply()
    for _, args in ipairs(self.steps) do
        Remote:FireServer(unpack(args))
        task.wait(0.1)
    end
end

local spiderman = OutfitComponent.new("Spiderman", {
    {"Reset Data"},
    {"Buy", "Shirts", "Spiderman"}, {"Wear", "Shirts", "Spiderman"},
    {"Buy", "Pants", "Spiderman"}, {"Wear", "Pants", "Spiderman"},
    {"Buy", "Shiestys", "Shiesty"}, {"Wear", "Shiestys", "Shiesty"},
    {"Buy", "Hats", "RedHat"}, {"Wear", "Hats", "RedHat"},
})

local drill = OutfitComponent.new("Drill Fit", {
    {"Reset Data"},
    {"Buy", "Shirts", "BlackTech"}, {"Wear", "Shirts", "BlackTech"},
    {"Buy", "Pants", "Amiri Bandana MX1 Jeans w Yellow Thunder 4s"},
    {"Wear", "Pants", "Amiri Bandana MX1 Jeans w Yellow Thunder 4s"},
    {"Buy", "Shiestys", "Shiesty"}, {"Wear", "Shiestys", "Shiesty"},
    {"Buy", "Glasses", "DarkShades"}, {"Wear", "Glasses", "DarkShades"},
    {"Buy", "Hats", "BlackHat"}, {"Wear", "Hats", "BlackHat"},
})

getgenv().ApplyOutfit = {
    Spiderman = function() spiderman:apply() end,
    DrillFit = function() drill:apply() end,
    Reset = function() Remote:FireServer("Reset Data") end,
}

getgenv().RandomizeOutfit = function()
    task.spawn(function()
        Remote:FireServer("Reset Data")
        task.wait(0.2)

        local shirtList = require(ReplicatedStorage:WaitForChild("ClothingList")).Shirts
        local shirt = shirtList[math.random(1, #shirtList)].Name
        Remote:FireServer("Buy", "Shirts", shirt)
        Remote:FireServer("Wear", "Shirts", shirt)
        task.wait(0.1)

        local pantsList = require(ReplicatedStorage:WaitForChild("ClothingList")).Pants
        local pants = pantsList[math.random(1, #pantsList)].Name
        Remote:FireServer("Buy", "Pants", pants)
        Remote:FireServer("Wear", "Pants", pants)
        task.wait(0.1)

        local categories = {"Hats", "Glasses", "Masks", "Shiestys"}
        local folderName = categories[math.random(1, #categories)]
        local folder = ReplicatedStorage:WaitForChild("WoodyHats"):FindFirstChild(folderName)
        if folder then
            local children = folder:GetChildren()
            if #children > 0 then
                local item = children[math.random(1, #children)].Name
                Remote:FireServer("Buy", folderName, item)
                Remote:FireServer("Wear", folderName, item)
            end
        end
    end)
end

getgenv().OutfitDropdowns = {
    {name = "Shirts", items = Shirts},
    {name = "Pants", items = Pants},
    {name = "Hats", items = Hats},
    {name = "Glasses", items = Glasses},
    {name = "Shiestys", items = Shiestys},
    {name = "Masks", items = Masks},
    options = toDropdownOptions,
}
