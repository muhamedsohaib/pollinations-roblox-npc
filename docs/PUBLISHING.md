# Publishing the quest demo to Roblox

The repository is already build-validated. This is the final account-bound step required by Pollinations quest #15583.

## 1. Open the validated place

Use the release artifact:

https://github.com/muhamedsohaib/pollinations-roblox-npc/releases/download/v0.1.0/pollinations-npc-demo.rbxlx

Open it in Roblox Studio while signed into the Roblox account that should own the demo experience.

## 2. Publish it

In Roblox Studio:

1. Select **File → Publish to Roblox As…**.
2. Create a new experience rather than overwriting an unrelated project.
3. Suggested name: **Pollinations NPC — Grix Demo**.
4. Suggested description: **A secure conversational Roblox NPC powered by Pollinations. Talk to Grix the blacksmith with @grix. Built for Pollinations quest #15583.**
5. Publish the place.

## 3. Configure the experience

Enable outbound HTTP requests in the experience security settings.

Create the experience secret:

```text
POLLINATIONS_API_KEY
```

Set its value to a Pollinations key with only the generation access and budget you intend the demo to use.

Do not put the key into a Script, LocalScript, ReplicatedStorage, place description, GitHub, or screenshots.

## 4. Make the experience playable

Use Creator Dashboard to set the experience's access/privacy so a Pollinations reviewer can open and play it without joining a private test group.

## 5. Smoke-test as a player

Join the published experience.

1. Walk close to **Grix the Blacksmith**.
2. Trigger **Talk**.
3. Send `@grix hello`.
4. Confirm a Pollinations-generated response appears in chat and as a bubble above Grix.
5. Send a second message and confirm the NPC retains that player's conversational context.
6. Confirm another player/session does not inherit the first player's conversation.

## 6. Capture the final URL

Copy the public Roblox experience URL.

That URL is the required **App URL** for the Pollinations app-submission form. Once it is available, update README's **Live demo** section and submit the app with:

- App Name: **Pollinations NPC for Roblox**
- Category: **games**
- Language: **en**
- Quest: **#15583**
- Repository: https://github.com/muhamedsohaib/pollinations-roblox-npc
