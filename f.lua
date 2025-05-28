local MinPlayers = 2 -- Find a server with a minimum of 1 player
local MaxPlayers = 12 -- Find a server with a maximum of 2 players (Excluding yourself)

local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
local ServerList = game:GetService("HttpService"):JSONDecode(game:HttpGetAsync(Api)).data

for _, Server in ipairs (ServerList) do
    local PlayerCount = Server.playing
    if PlayerCount >= MinPlayers and PlayerCount <= MaxPlayers then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, Server.id)
        return
    end
end

print("No server found.")
