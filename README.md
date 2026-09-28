# Pollinations NPC for Roblox

A small server-first Luau SDK that gives Roblox NPCs conversational dialogue powered by Pollinations.

Built for [Pollinations quest #15583](https://github.com/pollinations/pollinations/issues/15583).

## What it does

- Adds an NPC persona with a few lines of Luau.
- Calls Pollinations through `HttpService` from the **server only**.
- Supports Roblox Secrets through `HttpService:GetSecret()`; no API key needs to live in source.
- Keeps **separate conversation history per player**, so one player's dialogue never leaks into another player's prompt.
- Filters player input before it leaves Roblox and filters AI output before showing it back to the player.
- Applies per-player cooldown and per-minute rate limits.
- Gracefully falls back on HTTP, JSON, filtering, or model errors.
- Uses any Pollinations text model.
- Ships with a Rojo demo that creates a talking NPC named **Grix**.

## 5-minute setup

### 1. Build or sync the place

With [Rojo](https://rojo.space/) installed:

```bash
rojo build default.project.json -o demo.rbxlx
```

Open `demo.rbxlx` in Roblox Studio.

You can also run `rojo serve` and connect the Rojo Studio plugin.

### 2. Enable HTTP requests

In Studio, open **File → Experience Settings → Security** and enable **Allow HTTP Requests**.

### 3. Add the Pollinations key as a Roblox secret

Create a secret named:

```text
POLLINATIONS_API_KEY
```

For local Studio testing, add it under the experience's local secrets. For a published experience, add the production secret in the Roblox Creator Dashboard.

The SDK resolves it with:

```lua
HttpService:GetSecret("POLLINATIONS_API_KEY")
```

and uses it only in the server-side Authorization header.

### 4. Play

Press **Play**.

Walk near **Grix the Blacksmith** and use the proximity prompt. Then type:

```text
@grix hello
```

Grix replies in the chat window and in a bubble above the NPC.

## Minimal usage

```lua
local PollinationsNPC = require(game.ServerScriptService.PollinationsNPC)

local npc = PollinationsNPC.new({
    secretName = "POLLINATIONS_API_KEY",
    model = "openai/gpt-5.6-luna",
    persona = "You are Grix, a concise but helpful fantasy blacksmith.",
})

local reply = npc:Reply(player, "Can you repair my sword?")
```

If you prefer a development key instead of a Roblox secret, you may pass `apiKey`, but keep this code in `ServerScriptService` and never put the key in a `LocalScript`, `ReplicatedStorage`, or a public repository.

## API

### `PollinationsNPC.new(config)`

| Option | Default | Purpose |
| --- | --- | --- |
| `secretName` | `"POLLINATIONS_API_KEY"` | Roblox secret containing the Pollinations key |
| `apiKey` | `nil` | Optional server-only development key |
| `model` | `"openai/gpt-5.6-luna"` | Pollinations text model |
| `persona` | friendly NPC prompt | NPC personality/system prompt |
| `maxHistoryMessages` | `12` | Per-player history retained |
| `maxInputChars` | `500` | Max filtered player input sent to the model |
| `maxOutputChars` | `320` | Max reply shown to the player |
| `cooldownSeconds` | `2` | Minimum delay between requests per player |
| `maxRequestsPerMinute` | `8` | Rolling per-player request cap |
| `maxTokens` | `120` | Completion-token ceiling |
| `fallbackReply` | short retry message | Safe reply on errors |
| `onExchange` | `nil` | Optional server callback after successful dialogue |

### `npc:Reply(player, message)`

Returns:

```lua
reply, nil
```

on success, or:

```lua
fallbackReply, errorCode
```

on failure.

The SDK never throws a normal network/model failure into your gameplay loop.

### `npc:Reset(player)`

Clears that player's conversation memory and rate-limit state.

## Security and privacy choices

1. **Server only** — the API credential never needs to replicate to a client.
2. **Roblox Secrets supported** — production credentials can remain outside source code.
3. **Filtered before external inference** — player text goes through Roblox text filtering before being sent to Pollinations.
4. **Filtered before display** — the generated reply is filtered for the requesting player before it is shown.
5. **Per-player history** — no cross-player prompt leakage.
6. **Bounded context** — message length and history are capped.
7. **Bounded request rate** — a player cannot spam unbounded paid requests through the supplied module.
8. **No silent logging** — the SDK stores dialogue only in server memory unless the developer explicitly supplies `onExchange`.

See [SECURITY.md](SECURITY.md) for deployment guidance.

## Project layout

```text
src/
  ServerScriptService/
    PollinationsNPC.lua
    ExampleNPC.server.lua
  StarterPlayer/
    StarterPlayerScripts/
      PollinationsNPCClient.client.lua
default.project.json
```

The demo deliberately creates its simple NPC at runtime so the repository remains copyable and auditable.

## CI

The repository runs:

- StyLua format checks
- Selene Luau lint
- `rojo build` to prove the demo place serializes successfully

## Live demo

A playable Roblox experience URL will be added here before the quest submission is finalized.

## License

MIT
