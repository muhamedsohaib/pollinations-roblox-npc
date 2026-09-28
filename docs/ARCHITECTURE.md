# Architecture

## Request path

1. The player explicitly addresses the demo NPC with `@grix`.
2. The server verifies the player is close enough to the NPC.
3. `PollinationsNPC:Reply()` applies cooldown and rolling per-minute limits.
4. Roblox filters the player's text for that player.
5. The server builds a prompt from the NPC persona plus only that player's bounded history.
6. The server resolves the Pollinations credential from Roblox Secrets and calls `POST https://gen.pollinations.ai/v1/chat/completions`.
7. The returned text is length-bounded and passed through Roblox filtering.
8. The filtered reply is remembered for that player and sent only to that player's client.
9. The client displays the response in `RBXGeneral` and as an NPC bubble with `TextChatService:DisplayBubble()`.

## Trust boundaries

### Client

The client only receives already-filtered display strings and an NPC instance reference. It never receives the Pollinations key, raw HTTP response, conversation history, or another player's messages.

### Roblox server

The server owns credentials, history, rate limits, filtering, and external requests.

### Pollinations

Pollinations receives the filtered message, bounded per-player context, the configured persona, and model name.

## Failure behavior

Expected operational failures return a configurable fallback string rather than throwing into gameplay:

- cooldown/rate limit
- missing secret
- filtering failure
- transport/API failure
- malformed JSON
- missing completion content

## Data retention

By default, history exists only in memory for the lifetime of the server and is cleared for a player on departure. Nothing is persisted unless a developer explicitly provides an `onExchange` callback.
