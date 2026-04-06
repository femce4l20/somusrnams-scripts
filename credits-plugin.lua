local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer

local TextChannels = TextChatService:WaitForChild("TextChannels")

local ChatChannel = TextChannels:FindFirstChild("RBXGeneral")
while not ChatChannel do
	TextChannels.ChildAdded:Wait()
	ChatChannel = TextChannels:FindFirstChild("RBXGeneral")
end

local Prefix = "[cvtmvtt]: "

local function systemMessage(text)
	if ChatChannel then
		pcall(function()
			ChatChannel:DisplaySystemMessage(Prefix .. text)
		end)
	end
end

local function getDisplayName(player)
	if player and player.DisplayName then
		return player.DisplayName
	end
	return player.Name
end

local banner = [[
    
   _______      _________ __  ____      _________ _______ 
  / ____\ \    / /__   __|  \/  \ \    / /__   __|__   __|
 | |     \ \  / /   | |  | \  / |\ \  / /   | |     | |   
 | |      \ \/ /    | |  | |\/| | \ \/ /    | |     | |   
 | |____   \  /     | |  | |  | |  \  /     | |     | |   
  \_____|   \/      |_|  |_|  |_|   \/      |_|     |_|   

  On Discord :3
]]

-- Run once on script start
task.defer(function()
	task.wait(1) -- ensure chat is ready

	systemMessage("Welcome, " .. getDisplayName(LocalPlayer) .. "! I hope you enjoy my scripts!")

	print(banner)
end)
