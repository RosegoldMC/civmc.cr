# Contributor guidance

Read README.md, MIGRATION.md, and server-rules/civmc.md before changing the API.
This shard owns CivMC policy; Rosegold core remains server-independent.

Keep Bot composed from the core, with explicit delegation. Do not inherit the
core Bot or use method_missing forwarding. Review return values, nested wrappers,
callbacks, exceptions, and event payloads for raw client/world access. New core
methods must remain unavailable until explicitly reviewed here.

Only server-provided chat is a bot observation. Human-client mapping/rendering
exceptions do not permit environmental data in scripts. Preserve vanilla
physics, reach, collision, and occlusion. Shared helpers must use only allowed
observations and release their inputs on interruption.

Run crystal spec, python3 spec/compile_boundary.py, and
crystal tool format --check. Keep compile-rejection tests
for excluded APIs and positive compilation for supported workflows. Local tests,
remote CI, controlled-server checks, and live CivMC verification are separate.
Never publish private routes, coordinates, accounts, or infrastructure examples.
