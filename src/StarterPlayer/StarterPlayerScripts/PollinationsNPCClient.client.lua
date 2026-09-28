local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local remote = ReplicatedStorage:WaitForChild("PollinationsNPCDisplay")
local textChannels = TextChatService:WaitForChild("TextChannels")
local generalChannel = textChannels:WaitForChild("RBXGeneral")

remote.OnClientEvent:Connect(function(kind, adornee, message)
    if type(message) ~= "string" then
        return
    end

    if kind == "reply" then
        TextChatService:DisplayBubble(adornee, message)
        generalChannel:DisplaySystemMessage(message, "Grix")
    elseif kind == "thinking" then
        generalChannel:DisplaySystemMessage(message, "Grix")
    elseif kind == "hint" then
        generalChannel:DisplaySystemMessage(message, "Pollinations NPC")
    end
end)
