# Security

## Credential handling

Use Roblox Secrets for production credentials.

- Secret name expected by the demo: `POLLINATIONS_API_KEY`
- Resolve it only from a server script with `HttpService:GetSecret()`.
- Never put Pollinations keys in `LocalScript`, `ReplicatedStorage`, attributes replicated to clients, DataStores, screenshots, logs, or source control.
- Do not print a secret or an Authorization header.

The SDK also accepts a plain `apiKey` only for server-side development environments where the caller deliberately supplies one.

## Text handling

The supplied SDK filters player text before sending it to Pollinations. It also filters the model response before displaying it to the requesting player. If filtering fails, the exchange fails closed and returns the fallback reply.

## Cost controls

The default module enforces:

- 2-second per-player cooldown
- 8 requests per player per minute
- 500-character input limit
- 320-character displayed output limit
- 120 completion-token limit
- bounded per-player conversation history

Developers can change these values, but should keep explicit limits in production.

## Reporting

Open a private security advisory on this repository for credential exposure or a vulnerability that should not be disclosed publicly before a fix exists.
