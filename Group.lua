-- OutfitUI.lua (put this on GitHub)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tabs = shared.Tabs or getgenv().Tabs
local Library = shared.Library or getgenv().Library

local ClothShopRemote = ReplicatedStorage:WaitForChild("ClothShopRemote")
local ClothingList = require(ReplicatedStorage:WaitForChild("ClothingList"))

local Shirts = ClothingList.Shirts
local Pants = ClothingList.Pants

local Hats = {
    "BlackPuffer", "Essential Hood", "MRHoodieBRR", "HeadScarf", "PinkCleezy", "RedHat", "BlackHat",
    "BluHat", "WhiteFurHoodie", "BlackFurHoodie", "BlueCleezy", "RedCleezy", "CleezyB", "Hood"
}

local Glasses = {
    "PinkShades", "BlackShades", "RedShades", "BluShades", "DarkShades", "Glasses"
}

local Shiestys = {
    "ShiestyBlu", "ShiestyDesign", "PinkShiesty", "RedShiesty", "Shiesty", "BluShiesty",
    "YellowShiesty", "ShiestyRed", "WhiteShiesty"
}

local Masks = {
    "MacReddy", "SkullMask", "MaskH", "ClownMask", "MRCLOWN MAN", "JasonMask"
}

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

local function buyAndWear(category, item)
    task.spawn(function()
        ClothShopRemote:FireServer("Buy", category, item)
        task.wait(0.15)
        ClothShopRemote:FireServer("Wear", category, item)
        Library:Notify("Equipped " .. item .. " from " .. category, 3)
    end)
end

local OutfitTab = Tabs.Outfit

local categories = {
    {name = "Shirts", items = Shirts},
    {name = "Pants", items = Pants},
    {name = "Hats", items = Hats},
    {name = "Glasses", items = Glasses},
    {name = "Shiestys", items = Shiestys},
    {name = "Masks", items = Masks},
}

for i, cat in ipairs(categories) do
    local box = (i % 2 == 1) and OutfitTab:AddLeftGroupbox(cat.name) or OutfitTab:AddRightGroupbox(cat.name)
    box:AddDropdown(cat.name .. "Dropdown", {
        Text = "Select " .. cat.name:sub(1, -2),
        Values = toDropdownOptions(cat.items),
        Callback = function(selected)
            buyAndWear(cat.name, selected)
        end
    })
end

local Outfits = OutfitTab:AddLeftGroupbox("Preset Outfits")
local Remote = ReplicatedStorage:WaitForChild("ClothShopRemote")

local OutfitComponent = {}
OutfitComponent.__index = OutfitComponent

function OutfitComponent.new(name, sequence)
    return setmetatable({ name = name, steps = sequence }, OutfitComponent)
end

function OutfitComponent:apply()
    for _, args in ipairs(self.steps) do
        Remote:FireServer(unpack(args))
        task.wait(0.1)
    end
end

local spidermanOutfit = OutfitComponent.new("Spiderman", {
    {"Reset Data"},
    {"Buy", "Shirts", "Spiderman"},
    {"Wear", "Shirts", "Spiderman"},
    {"Buy", "Pants", "Spiderman"},
    {"Wear", "Pants", "Spiderman"},
    {"Buy", "Shiestys", "Shiesty"},
    {"Wear", "Shiestys", "Shiesty"},
    {"Buy", "Hats", "RedHat"},
    {"Wear", "Hats", "RedHat"},
})

local drillOutfit = OutfitComponent.new("Drill Fit", {
    {"Reset Data"},
    {"Buy", "Shirts", "BlackTech"},
    {"Wear", "Shirts", "BlackTech"},
    {"Buy", "Pants", "Amiri Bandana MX1 Jeans w Yellow Thunder 4s"},
    {"Wear", "Pants", "Amiri Bandana MX1 Jeans w Yellow Thunder 4s"},
    {"Buy", "Shiestys", "Shiesty"},
    {"Wear", "Shiestys", "Shiesty"},
    {"Buy", "Glasses", "DarkShades"},
    {"Wear", "Glasses", "DarkShades"},
    {"Buy", "Hats", "BlackHat"},
    {"Wear", "Hats", "BlackHat"},
})

Outfits:AddButton("Wear Spiderman Fit", function()
    spidermanOutfit:apply()
end)

Outfits:AddButton("Wear Drill Fit", function()
    drillOutfit:apply()
end)

local function getRandomItem(folder)
    local items = folder:GetChildren()
    if #items == 0 then return nil end
    return items[math.random(1, #items)].Name
end

Outfits:AddButton("Randomize Outfit", function()
    task.spawn(function()
        Remote:FireServer("Reset Data")
        task.wait(0.2)

        local shirtList = require(ReplicatedStorage:WaitForChild("ClothingList"))["Shirts"]
        local shirt = shirtList[math.random(1, #shirtList)]["Name"]
        Remote:FireServer("Buy", "Shirts", shirt)
        Remote:FireServer("Wear", "Shirts", shirt)
        task.wait(0.1)

        local pantsList = require(ReplicatedStorage:WaitForChild("ClothingList"))["Pants"]
        local pants = pantsList[math.random(1, #pantsList)]["Name"]
        Remote:FireServer("Buy", "Pants", pants)
        Remote:FireServer("Wear", "Pants", pants)
        task.wait(0.1)

        local categories = {"Hats", "Glasses", "Masks", "Shiestys"}
        local folderName = categories[math.random(1, #categories)]
        local folder = ReplicatedStorage:WaitForChild("WoodyHats"):FindFirstChild(folderName)
        if folder then
            local item = getRandomItem(folder)
            if item then
                Remote:FireServer("Buy", folderName, item)
                Remote:FireServer("Wear", folderName, item)
            end
        end
    end)
end)

Outfits:AddButton("Reset Fit", function()
    Remote:FireServer("Reset Data")
end)
