# Migrate a CivMC bot

Replace the application's direct `rosegold` dependency with `rosegold-civmc`
from `RosegoldMC/civmc.cr`. Use the revision or version selected by the example
repository, then resolve and commit the application's dependency lock.

Change `require "rosegold"` to `require "rosegold-civmc"` and
`Rosegold::Bot.new(...)` to `Rosegold::CivMC::Bot.new(...)`. Omitting the address
selects `play.civmc.net:25565`. Connection helpers return or yield the restricted
bot. Keep the existing `ensure` disconnect.

Most movement, item-use, inventory, crafting, and enchanting calls retain their
arguments. Some operations intentionally return `nil` where the core returned
an internal object or incidental result; inspect permitted observations to
confirm a workflow. In particular, do not use `chat`'s return value as a delivery
or server-acceptance acknowledgement.

## Calls that need review

| Existing use | Migration |
| --- | --- |
| `bot.client`, `bot.world`, block/entity scans, arbitrary packet subscriptions | Remove from CivMC scripts. Configure already known targets and confirm through allowed state. |
| Raw inventory/menu/client access | Use `bot.inventory`, `open_container_handle`, and the restricted menu operations. Inventory reads are detached snapshots. |
| `Rosegold::Event::ContainerOpened` | Subscribe to `Rosegold::CivMC::ContainerOpened`; its `menu` is restricted. |
| Core `SpectateServer` setup | Use `start_spectating` and `stop_spectating`; stop in `ensure`. |
| Gamemode, mining-time inspection, pick-block, direct recipe-registry access | Not exposed. Use the supported action DSL and inventory outcomes. |
| Custom elevator/XP loops | Consider `elevator` or `raise_level_with`; read their preconditions and result semantics first. |

The supported event list is in [README.md](README.md). An arbitrary core event
will fail to compile against the facade. Newly added core methods are not
forwarded automatically.

Do not pass an existing unrestricted bot/client into the CivMC constructor.
Construct the facade directly. Low-level core scripts need an explicit review;
changing the namespace alone cannot establish rule compliance.

From version 0.2.0, `elevator` accepts only the destination and optional
`timeout_ticks`. Remove `cancellation:` from elevator calls. XP consumption
still supports cancellation through `raise_level_with`.

Compile the migrated bot, run its local tests, then verify plugin-dependent
behavior on a controlled server. A successful build is not live-server proof.
