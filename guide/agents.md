# Agent guide

For coding agents writing or reviewing a CivMC script, or changing this shard.
Humans will mostly want the [README](../README.md) and
[MIGRATION.md](../MIGRATION.md).

Start with the [bot legality checklist](bot-legality.md). It maps each clause of
the [rules snapshot](../server-rules/civmc.md) to code, script, operator, mod, or
unresolved.

## Ground rules

- The rules text is a dated snapshot. We did not verify a current
  first-party copy. Say so when you report on legality.
- Do not infer staff approval or permission. A method existing, a build passing,
  or a rule being silent is not permission.
- No bypass. Do not import `rosegold` for access the facade withholds, reopen
  classes, add `method_missing` or forwarding, or reach the composed core bot.
- Do not widen the API, change behavior, or move the core pin in `shard.yml`
  unless the maintainer asked for exactly that.
- A new core method stays unavailable until someone reviews it here and adds a
  test for it.
- Do not guess what staff mean by "directly help during combat", which extra
  fields count under "and nothing else", or whether the spectator viewer or a
  hosted machine is acceptable. Mark them unresolved and leave the decision to
  the operator.
- No private routes, coordinates, accounts, or hosting details in examples,
  docs, or prompts.

## Writing a script

Check your application's `require` lines and `shard.lock`, then read the
installed facade and core sources. Use the timing notes below only if your
application resolves this repository's core pin (`d0e044d51`).

- Use `Rosegold::CivMC::Bot` and `require "rosegold-civmc"`. Disconnect and
  release held inputs in `ensure`.
- Configure targets in advance: positions, containers, and routes come from the
  operator. The facade has no world or entity queries to find them.
- Confirm outcomes from the allowed observations only: inventory, own position,
  health, hunger, effects, EXP, boss bars, server chat, kick reasons, joins and
  leaves, and the tab list. See the [observation checklist](bot-legality.md#what-a-bot-may-read-l67-to-73)
  for extra event fields and menu data that are still Open.
- For mining, aim at a configured point, then use held `start_digging`, check
  allowed state, and `stop_digging` in `ensure`. A simple bounded `dig(ticks)` is
  fine. `estimated_break_ticks` is not exposed. A timeout, a durability change,
  or a pickup does not show which block broke.
- Held `start_digging` can hit a reachable entity instead of the
  intended block.
  Conservative advice, not source text: keep the bot out of combat. L77 bans
  directly helping a player in combat, and the text does not define that.
- `use_hand` queues one tap and does not wait for a result. Use
  `start_using_hand` and `stop_using_hand` for holds.
- Event handlers run synchronously. `spawn` any handler work that waits for
  ticks or packets.
- Do not act on what the spectator viewer shows.

## Changing the shard

- Keep Bot composed from the core with explicit delegation. Review return
  values, nested wrappers, callbacks, exceptions, and event payloads for client
  or world access.
- Add a compile-rejection case to `spec/compile_boundary.py` for each excluded
  API, and a positive case for each supported workflow.
- Check the semantics at the pinned core, not modern core. Read the pin from
  `shard.yml` and look at that revision's source before documenting behavior.
- Keep README, MIGRATION.md, this guide, and the checklist in step with any
  public change.

## Checks

```sh
shards install
crystal spec
python3 spec/compile_boundary.py
crystal tool format --check
```

Local checks, remote CI, controlled-server runs, and live CivMC are separate
evidence. Report which one you ran.
