# Contributor guidance

Read README.md, MIGRATION.md, and server-rules/civmc.md before changing the API.
Agents also read [guide/agents.md](guide/agents.md) and the
[bot legality checklist](guide/bot-legality.md).
This shard owns CivMC policy; Rosegold core remains server-independent.

The rules file is a dated snapshot. We did not verify a current first-party copy, and
no staff approval is implied for this library or for any script. Do not infer
permission from the code, a passing build, or silence in the rules.

Keep Bot composed from the core, with explicit delegation. Do not inherit the
core Bot or use method_missing forwarding. Review return values, nested wrappers,
callbacks, exceptions, and event payloads for raw client/world access. New core
methods must remain unavailable until explicitly reviewed here. Do not widen the
API, bypass the facade, or change behavior or the core pin without being asked.

Only server-provided chat is a bot observation. Human-client mapping/rendering
exceptions do not permit environmental data in scripts. Preserve vanilla
physics, reach, collision, and occlusion. Shared helpers must use only allowed
observations and release their inputs on interruption.

Run crystal spec, python3 spec/compile_boundary.py, and
crystal tool format --check. Keep compile-rejection tests
for excluded APIs and positive compilation for supported workflows. Local tests,
remote CI, controlled-server checks, and live CivMC verification are separate.
Never publish private routes, coordinates, accounts, or infrastructure examples.
