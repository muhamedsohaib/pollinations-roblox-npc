local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PollinationsNPC = require(script.Parent.PollinationsNPC)

local NPC_NAME = "Grix"
local REMOTE_NAME = "PollinationsNPCDisplay"
local PREFIX = "@grix"
local MAX_DISTANCE = 28

local function getOrCreateRemote()
    local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)

    if remote then
        return remote
    end

    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage

    return remote
end

local function getOrCreateNPC()
    local existing = Workspace:FindFirstChild(NPC_NAME)

    if existing and existing:IsA("Model") then
        return existing
    end

    local model = Instance.new("Model")
    model.Name = NPC_NAME

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(3, 4, 2)
    torso.Anchored = true
    torso.Position = Vector3.new(0, 2, 0)
    torso.Color = Color3.fromRGB(71, 48, 35)
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(2.4, 2.4, 2.4)
    head.Anchored = true
    head.Position = Vector3.new(0, 5, 0)
    head.Color = Color3.fromRGB(229, 194, 152)
    head.Parent = model

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "TalkPrompt"
    prompt.ActionText = "Talk"
    prompt.ObjectText = "Grix the Blacksmith"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12
    prompt.Parent = head

    model.PrimaryPart = torso
    model.Parent = Workspace

    return model
end

local function closeEnough(player, head)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return false
    end

    return (root.Position - head.Position).Magnitude <= MAX_DISTANCE
end

local remote = getOrCreateRemote()
local npcModel = getOrCreateNPC()
local npcHead = npcModel:WaitForChild("Head")
local prompt = npcHead:WaitForChild("TalkPrompt")

local npc = PollinationsNPC.new({
    secretName = "POLLINATIONS_API_KEY",
    model = "openai/gpt-5.6-luna",
    persona = table.concat({
        "You are Grix, a fantasy-village blacksmith in a Roblox game.",
        "You are gruff, concise, and helpful.",
        "Stay in character.",
        "Do not claim to perform game actions you cannot actually perform.",
        "Keep replies under three short sentences.",
    }, " "),
})

prompt.Triggered:Connect(function(player)
    remote:FireClient(
        player,
        "hint",
        npcHead,
        "Type @grix followed by your message in chat."
    )
end)

local function connectPlayer(player)
    player.Chatted:Connect(function(message)
        local lower = string.lower(message)

        if string.sub(lower, 1, #PREFIX) ~= PREFIX then
            return
        end

        if not closeEnough(player, npcHead) then
            remote:FireClient(
                player,
                "hint",
                npcHead,
                "Move closer to Grix before talking."
            )
            return
        end

        local promptText = string.sub(message, #PREFIX + 1):match("^%s*(.-)%s*$")

        if not promptText or promptText == "" then
            remote:FireClient(
                player,
                "hint",
                npcHead,
                "Try: @grix can you repair my sword?"
            )
            return
        end

        remote:FireClient(player, "thinking", npcHead, "Grix is thinking...")

        task.spawn(function()
            local reply, err = npc:Reply(player, promptText)

            if err then
                warn("[Grix] dialogue fallback", err)
            end

            remote:FireClient(player, "reply", npcHead, reply)
        end)
    end)
end

Players.PlayerAdded:Connect(connectPlayer)
Players.PlayerRemoving:Connect(function(player)
    npc:Reset(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    connectPlayer(player)
end
