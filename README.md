# rosegold-civmc

A CivMC scripting API built on Rosegold. It retains movement, inventory,
crafting, enchanting, chat, and permitted player observations while withholding
world queries and raw client access.

Start with [example-civmc](https://github.com/RosegoldMC/example-civmc), or add
`rosegold-civmc` from `RosegoldMC/civmc.cr` to your shard dependencies.

```crystal
require "rosegold-civmc"

bot = Rosegold::CivMC::Bot.new
begin
  bot.join_game
  puts "Connected as #{bot.username}"
  bot.wait_ticks(20)
ensure
  bot.disconnect("Script finished") if bot.connected?
end
```

The default address is `play.civmc.net:25565`. Pass another `host:port` to the
constructor for testing; changing the address does not change the API policy.
Authentication uses Rosegold's Microsoft device-login flow. Keep its token cache
private and out of version control.

## What scripts can observe

The [rules snapshot](server-rules/civmc.md) permits inventory, selected hotbar
slot, own location, health, hunger, potion effects, experience, boss bars,
server-provided chat, kick reasons, player logins/logouts, and the server tab list.
The direct mount exception exposes only its type and location through `riding`.
Use `tab_list`, `boss_bar_states`, and `disconnect_reason` for those observations.

The facade composes `Rosegold::Bot` and explicitly exposes reviewed operations.
Inventory and container wrappers do not expose their client or underlying menu.
There is no `client`, `world`, block/entity query, raw packet subscription,
gamemode getter, recipe registry, mining-time inspection, or pick-block helper.

Forbidden calls fail during Crystal compilation. Compile-failure tests cover
nested handles, callbacks, connection returns, and newly added core methods.
There are no catch-all method or event forwarding hooks.

This prevents accidental access through the facade. It is not a sandbox against
code that deliberately imports the core or reopens classes. Scripts must still
follow CivMC's rules, including the prohibition on direct combat assistance.
Human-client mapping and rendering exceptions do not permit environmental data
to feed bot decisions. No staff approval is implied.

## Events

`on`, `off`, `once`, and `wait_for` accept only these event types:

- `Rosegold::Event::Tick`, `HealthChanged`, `ExperienceChanged`, `Died`, `PlayerJoined`, and `PlayerLeft`.
- `Rosegold::Clientbound::SystemChatMessage`, `PlayerChatMessage`, `DisguisedChatMessage`, `SetContainerContent`, `SetSlot`, and `BossEvent`.
- `Rosegold::CivMC::ContainerOpened`, whose `menu` is restricted.

Use the fully qualified namespace for each type. Handlers execute synchronously;
spawn work that waits for ticks or packets. Server chat events exclude messages
created locally by the spectator client.

## Shared Civ helpers

The facade includes the opt-in helpers from
[rosegold-civ-common](https://github.com/RosegoldMC/civ-common.cr).

`elevator(target_y, timeout_ticks: 1200, cancellation: nil)` uses jump upward and
sneak downward at a known elevator. Supply the destination and stand at the
correct elevator first. Completion is observed from own Y position. Stalls,
falls, cancellation, disconnect, and timeout raise `CivCommon::MovementError`.
Click-configured elevators are not supported.

`raise_level_with(item_name, target_level, timeout_ticks: 1200, cancellation: nil)`
selects a carried item, looks upward, and taps use every two ticks. It returns
`CivCommon::ExperienceResult` with `completed?`, `reason`, and `final_level`.
It stops on the observed target level, depletion, a changed hand/slot, timeout,
cancellation, or disconnect. It assumes no XP yield and performs no crafting,
withdrawal, or repair.

Both helpers release their inputs on exit. The XP helper restores its pitch and
selected slot when connected unless another operation changed them; inventory
swaps are not undone. Give a helper exclusive control of movement, look,
selection, and item use. See the shared library for cancellation and timing limits.
These helpers still need live verification for the server's current plugins.

## Human spectator

`start_spectating(port: 25566)` starts a loopback-only viewer;
`stop_spectating` stops it. Stop the viewer in `ensure`. Scripts receive no relay
or raw client object. Connect a normal Minecraft client to `localhost:25566`.

## Development

Run `shards install`, `crystal spec`, `python3 spec/compile_boundary.py`, and
`crystal tool format --check`.
Read [MIGRATION.md](MIGRATION.md) before moving an existing core bot.
