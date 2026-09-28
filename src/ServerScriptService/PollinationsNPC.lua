local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local PollinationsNPC = {}
PollinationsNPC.__index = PollinationsNPC

local API_URL = "https://gen.pollinations.ai/v1/chat/completions"

local DEFAULTS = {
    secretName = "POLLINATIONS_API_KEY",
    model = "openai/gpt-5.6-luna",
    persona = "You are a friendly, concise NPC in a Roblox experience.",
    maxHistoryMessages = 12,
    maxInputChars = 500,
    maxOutputChars = 320,
    cooldownSeconds = 2,
    maxRequestsPerMinute = 8,
    maxTokens = 120,
    fallbackReply = "Give me a moment, then try talking to me again.",
}

local function copyDefaults(config)
    local merged = {}

    for key, value in pairs(DEFAULTS) do
        merged[key] = value
    end

    for key, value in pairs(config or {}) do
        merged[key] = value
    end

    return merged
end

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function clampText(value, maxChars)
    if #value <= maxChars then
        return value
    end

    return string.sub(value, 1, maxChars)
end

local function filterForUser(text, player)
    local ok, filtered = pcall(function()
        local result = TextService:FilterStringAsync(
            text,
            player.UserId,
            Enum.TextFilterContext.PublicChat
        )
        return result:GetNonChatStringForUserAsync(player.UserId)
    end)

    if not ok or type(filtered) ~= "string" or filtered == "" then
        return nil
    end

    return filtered
end

function PollinationsNPC.new(config)
    local settings = copyDefaults(config)
    local self = setmetatable({}, PollinationsNPC)

    self.settings = settings
    self.historyByUserId = {}
    self.requestsByUserId = {}
    self.lastRequestAtByUserId = {}

    return self
end

function PollinationsNPC:_authorizationHeader()
    if self.settings.apiKey then
        return "Bearer " .. self.settings.apiKey
    end

    local ok, secret = pcall(function()
        return HttpService:GetSecret(self.settings.secretName)
    end)

    if not ok or not secret then
        return nil
    end

    return secret:AddPrefix("Bearer ")
end

function PollinationsNPC:_rateLimit(userId)
    local now = os.clock()
    local lastRequestAt = self.lastRequestAtByUserId[userId]

    if lastRequestAt and now - lastRequestAt < self.settings.cooldownSeconds then
        return false, "cooldown"
    end

    local requests = self.requestsByUserId[userId] or {}
    local fresh = {}

    for _, timestamp in ipairs(requests) do
        if now - timestamp < 60 then
            table.insert(fresh, timestamp)
        end
    end

    if #fresh >= self.settings.maxRequestsPerMinute then
        self.requestsByUserId[userId] = fresh
        return false, "rate_limited"
    end

    table.insert(fresh, now)
    self.requestsByUserId[userId] = fresh
    self.lastRequestAtByUserId[userId] = now

    return true, nil
end

function PollinationsNPC:_messagesFor(userId, userMessage)
    local messages = {
        {
            role = "system",
            content = self.settings.persona,
        },
    }

    for _, message in ipairs(self.historyByUserId[userId] or {}) do
        table.insert(messages, message)
    end

    table.insert(messages, {
        role = "user",
        content = userMessage,
    })

    return messages
end

function PollinationsNPC:_remember(userId, userMessage, assistantMessage)
    local history = self.historyByUserId[userId] or {}

    table.insert(history, {
        role = "user",
        content = userMessage,
    })
    table.insert(history, {
        role = "assistant",
        content = assistantMessage,
    })

    while #history > self.settings.maxHistoryMessages do
        table.remove(history, 1)
    end

    self.historyByUserId[userId] = history
end

function PollinationsNPC:Reply(player, rawMessage)
    if not player or type(rawMessage) ~= "string" then
        return self.settings.fallbackReply, "invalid_input"
    end

    local message = trim(rawMessage)
    if message == "" then
        return self.settings.fallbackReply, "empty_input"
    end

    local allowed, limitError = self:_rateLimit(player.UserId)
    if not allowed then
        return self.settings.fallbackReply, limitError
    end

    local filteredInput = filterForUser(
        clampText(message, self.settings.maxInputChars),
        player
    )
    if not filteredInput then
        return self.settings.fallbackReply, "input_filter_failed"
    end

    local authorization = self:_authorizationHeader()
    if not authorization then
        return self.settings.fallbackReply, "missing_api_key"
    end

    local body = HttpService:JSONEncode({
        model = self.settings.model,
        messages = self:_messagesFor(player.UserId, filteredInput),
        max_tokens = self.settings.maxTokens,
    })

    local requestOk, response = pcall(function()
        return HttpService:RequestAsync({
            Url = API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = authorization,
            },
            Body = body,
        })
    end)

    if not requestOk or not response.Success then
        warn(
            "[PollinationsNPC] request failed",
            requestOk and response.StatusCode or "transport"
        )
        return self.settings.fallbackReply, "request_failed"
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not decodeOk
        or type(decoded) ~= "table"
        or type(decoded.choices) ~= "table"
        or type(decoded.choices[1]) ~= "table"
        or type(decoded.choices[1].message) ~= "table"
        or type(decoded.choices[1].message.content) ~= "string"
    then
        return self.settings.fallbackReply, "invalid_response"
    end

    local rawReply = clampText(
        trim(decoded.choices[1].message.content),
        self.settings.maxOutputChars
    )
    local filteredReply = filterForUser(rawReply, player)

    if not filteredReply then
        return self.settings.fallbackReply, "output_filter_failed"
    end

    self:_remember(player.UserId, filteredInput, filteredReply)

    if type(self.settings.onExchange) == "function" then
        task.spawn(function()
            local ok, err = pcall(self.settings.onExchange, {
                userId = player.UserId,
                model = self.settings.model,
                userMessage = filteredInput,
                reply = filteredReply,
            })

            if not ok then
                warn("[PollinationsNPC] onExchange callback failed", err)
            end
        end)
    end

    return filteredReply, nil
end

function PollinationsNPC:Reset(player)
    if not player then
        return
    end

    local userId = player.UserId
    self.historyByUserId[userId] = nil
    self.requestsByUserId[userId] = nil
    self.lastRequestAtByUserId[userId] = nil
end

return PollinationsNPC
