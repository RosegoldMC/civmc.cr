# Bot legality checklist

This is a working checklist, not a ruling. It maps every normative clause in
the [rules snapshot](../server-rules/civmc.md) to who has to satisfy it. The
snapshot is a dated copy: General Rules 2023-02-27, Minecraft Rules
2024-10-14, Mod Exceptions 2024-10-15, supplied from Discord text on
2026-10-14. We did not verify a current first-party copy, so
any row can be stale. No staff approval of this library or of any script is
implied, and none should be inferred from silence, from a build that compiles,
or from a method existing on the facade.

Line numbers refer to `server-rules/civmc.md`. Re-anchor them if the snapshot
is replaced.

## Classes

| Class | Meaning |
| --- | --- |
| Code | The facade blocks accidental access at compile time. This is not a sandbox, and it does not prove a script is legal. |
| Script | The script author has to satisfy it. Review the script itself. |
| Operator | The human running the bot. No code can satisfy it. |
| Mod | Applies to human client mods only. A bot or script cannot use it. |
| Open | Unresolved. Do not rely on it, and do not treat it as cleared. Ask CivMC staff, in the open, before a script depends on it. |

## Before you run anything

1. The rules may have changed. Row L12 says they can change and apply
   retroactively. Get the current text from CivMC before a long run.
2. Go through every row below that is not `Mod`. Each `Script`, `Operator`,
   and `Open` row needs an answer you can state.
3. Stay on the facade. Do not import `rosegold` directly, reopen facade or core
   classes, or add forwarding to reach `client`, `world`, entities, or raw
   packets. That is a bypass, whatever the rest of this list says.
4. A passing local build and spec run says nothing about live behavior. See
   [Verification](#verification).

## General Rules

| Lines | Clause | Class | What to check |
| --- | --- | --- | --- |
| 12 | Rules and punishments can change, retroactively. | Operator | Re-read the rules before each run. |
| 12 | No circumventing punishments. | Operator, Script | Reconnect loops and retries must not be used to get around a ban or kick. A retry is not authorization. |
| 16 | Content on any CivMC-hosted platform can be moderated. | Operator | Applies to anything the script says in chat. |
| 17, 18 | Repeat minor offenses grow bans. Stay civil. | Operator | |
| 22 | No harassment of a person or group. | Script, Operator | `chat` sends whatever it is given. Scripted messages must not harass. |
| 23 | No graphic NSFW content. | Script, Operator | Same as above. |
| 24 | No doxxing. | Script, Operator | The script must not post another player's personal or real-life information. Treat player names and tab data from the server as player information when deciding what to publish. |
| 25 | No helping others break rules or avoid punishments. | Script, Operator | |
| 26, 27 | Report rule breaking you see. Association can be punished. | Operator | |
| 28 | Staff may remove unpleasant users at discretion. | Operator | |
| 32 | Minimum age 13. | Operator | |
| 33 | No VPN, VPS, or other proxy. | Operator, Open | Whether a hosted or always-on machine counts is not answered in the snapshot. Do not assume it is fine. |
| 34 | No trading in-game goods or services for out-of-game ones. | Operator | |
| 35 | No malicious code. | Script | |

## Cheating

| Lines | Clause | Class | What to check |
| --- | --- | --- | --- |
| 41 | Cheating is forbidden. The list is not exhaustive. | Script, Operator | |
| 43 | No tool that retrieves block information a vanilla client could not. | Code, Script | The facade has no `world` or `block_at`, and tests reject them. A script still must not infer block data some other way (see L63). |
| 44 | No auto clickers, kill aura, reach, or combat hacks. | Script, Open | The facade's `use_hand`, `attack`, and held `start_digging` run on core timing. Keep that timing as the core provides it, and see L77 for combat. |
| 45 | No fast break, interact hacks, or behavior impossible in vanilla. | Script | Use the facade's mining and use calls as the core provides them, without trying to exceed what a vanilla client can do. |
| 46, 47 | No exploiting unintended mechanics or bugs, especially duplication. | Script, Operator | Nothing in this library checks it. |
| 49 | Client mods are allowed if they do not enable cheating. | Mod | |
| 51 | No block glitching to reach inaccessible areas. | Script | `move_to` and the elevator helper use vanilla physics. Do not script clips. |

## Accounts and association

| Lines | Clause | Class | What to check |
| --- | --- | --- | --- |
| 55 | One account only. | Operator | The cached Microsoft login is not permission for extra accounts. |
| 56 | Association and disassociation rules. Sharing account access, even briefly, leads to permanent association. | Operator, Open | Whether the permanent association is automatic or at staff discretion is unclear in the text. Never hand the token cache to anyone. |

## Botting and mods

| Lines | Clause | Class | What to check |
| --- | --- | --- | --- |
| 60 | Bots are allowed only within vanilla behavior and these rules. | Script | |
| 62 | Follow vanilla physics, occlusion, movement, and the rest of vanilla behavior. The list is open. | Code, Script | The core owns physics and occlusion, and the facade does not change them. The open list has not been audited beyond those. |
| 63 | Do not discover information that would otherwise be unknown. | Script, Open | Includes indirect routes: timing a dig to find a block, inferring entities from chat or sound, or reading the spectator view and acting on it. Which indirect routes count is not defined. |

### What a bot may read (L67 to 73)

L68 is an allowlist ending in "and nothing else". The facade exposes more
members than the list names, so each row says where the match is exact.

| Lines | Observation | Class | Facade surface and caveat |
| --- | --- | --- | --- |
| 67 | Chat from the server only, not client-mod messages. | Code | System, player, and disguised chat events. Locally created spectator chat is filtered. |
| 68 | Inventory. | Code, Open | Detached stack snapshots through `inventory` and container handles. The inventory allowance does not establish permission to read typed menu metadata: processing progress and fuel uses, level costs, enchantment offers, or merchant metadata and trades. |
| 68 | Selected hotbar slot. | Code | `hotbar_selection`, `main_hand`. |
| 68 | Own location. | Code | `x`, `y`, `z`, `location`, `feet`. |
| 68 | Health. | Code | `health`, `HealthChanged`, `Died`. |
| 68 | Hunger. | Code, Open | `food` is hunger. `saturation` and `should_eat?` are not named in the list. |
| 68 | Potion effects. | Code | `effects`, `effect_by_name`, and the level helpers. |
| 68 | EXP. | Code, Open | `experience_level` is the plain match. Progress and total are not named. |
| 68 | Boss bar. | Code | `boss_bar_states`. |
| 68 | Kick reasons. | Code | `disconnect_reason`. |
| 68 | Player logins and logouts. | Code, Open | `PlayerJoined` and `PlayerLeft` each carry a full copy of the tab entry. The login and logout allowance does not establish permission to read extra fields such as ping, game mode, or profile properties. |
| 68 | Server tab list. | Code, Open | `tab_list` returns copied entries. Which entry fields are allowed is not stated. |
| 68 | "and nothing else". | Open | `look`, `yaw`, `pitch`, `eyes`, `sneaking?`, `sprinting?`, `uuid`, `username`, `host`, `port`, `connected?`, and `spawned?` are not named. They are the bot's own state and connection facts, not environmental data, but they are not on the list either. |
| 69 | No environmental data: entity or block locations or information about them. | Code, Script | The facade has no world, block, or entity query. Do not rebuild one from other observations. |
| 70 | Entity type, item type, name, X, Z for client mods only, never feeding a bot or script. | Mod | Not available to bots. The library does not implement it. |
| 71, 72 | Top-layer blocks and light level for client mapping. | Mod | Not available to bots. |
| 73 | The entity you are directly riding: its type and location. | Code | `riding` and `riding?`. Direct mount only. |

## Additional limits and mod exceptions

| Lines | Clause | Class | What to check |
| --- | --- | --- | --- |
| 77 | Bots and scripts may not directly help a player during combat. | Script, Open | The facade exposes `attack` and held digging, and can also eat and use items. The text does not define "directly help", and we do not interpret it. Whether other actions near combat are acceptable is unresolved. Conservative advice, separate from the rule: keep the bot out of combat. |
| 78 | Mods may change nametag text and color, but not make nametags more visible at distance or through walls. | Mod | |
| 79 | Entity-rendering mods (capes, cosmetics) must not significantly alter the rendered entity's size, and must not alter its hitbox at all. | Mod | |
| 83 | Cosmetic mods are allowed if they give no in-game advantage, such as transparent blocks or seeing what you otherwise could not. | Mod | |
| 84 | Performance mods are always allowed if they add no functionality. | Mod | |
| 85 | Mods may download server information for later use (maps, schematics, replays), if not used to discover otherwise unknown information. Cave mode is allowed in the Nether only. | Mod | A bot cannot use this to read environmental data. |
| 86 | Holographic build guides. | Mod | Reading world data or non-vanilla placement only for vanity builds that do not affect gameplay. `place_block_against` is vanilla placement and not this exception. |

## Spectator viewer

`start_spectating` hands the world to a human's normal client on loopback. Rows
L69 to L72 describe human-client features, but the snapshot does not say a
viewer like this qualifies. Treat it as Open. The script must not read, act on,
or log anything from it, and the operator should not expect it to be cleared.

## Mining, using items, and combat

These notes are for the pinned core, `d0e044d51`, not modern core. Newer core
changes mining and attack timing, and `estimated_break_ticks` is excluded here.

- `start_digging` holds the attack button. On the press, the raytrace selects a
  reached entity or block. An entity is attacked, and a block starts breaking.
  The input can hit a reachable entity instead of the intended block, and a
  script that cannot see entities cannot rule that out.
- `dig(ticks)` holds attack, waits that many client ticks (a tick wait, not a guarantee of ticks achieved), then
  releases. `attack` is `dig 0`: one press and release.
- Use `start_digging`, check allowed state, then `stop_digging` in `ensure`, or
  a small bounded `dig`. Look at an operator-configured point first.
- A timeout, a durability change, or an item entering the inventory does not
  prove a particular block broke. Write workflows that do not need that proof.
- `use_hand` queues one tap and does not wait for a result. `start_using_hand`
  holds use until `stop_using_hand`. Release in `ensure`.
- Do not route a script around these limits with timing tricks or retries.

## Verification

- Local: `crystal spec`, `python3 spec/compile_boundary.py`,
  `crystal tool format --check`. These show the facade boundary, not live behavior.
- Live: plugin-dependent behavior and what CivMC actually does are unverified,
  and no live tests are planned here.

## Known gaps

- We did not verify a current first-party copy of the rules.
- Rows marked Open need staff input, not a code change.
- The set of other vanilla behaviors under L62 has not been audited.
- Extra facade data is not cleared. See the [observation table](#what-a-bot-may-read-l67-to-73)
  for rows marked Open.
- Live plugin behavior for the shared helpers is unverified.
