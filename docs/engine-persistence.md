# Engine persistence

The Rust engine supports one current canonical save contract and one current
bounded replay contract. These contracts are shared by the native clients;
they do not carry speculative aliases, fallback readers, or upcasters.

`SaveGameDto` owns the complete canonical state, content identities, actor,
event offset, and state digest. `ReplayLogDto` owns a bounded chain of canonical
checkpoints and exact command context and results. The shared client API version
remains in place because Flutter, Godot, and native libraries are independently
built components.

Behavior 2 normalizes unit armies by troop kind before computing canonical state
digests. Archives carrying the prior behavior fingerprint are rejected at the
header validation boundary; they are not silently normalized and replayed under
different digest semantics. The durable JSON schema remains version 2.

## Native write and restore contract

`PersistenceFileStore` is an I/O boundary in `aonw_local_runtime`; pure domain
and engine crates remain filesystem-free. A write uses this sequence:

1. Serialize and strictly decode the current save contract.
2. Write a unique temporary file beside the destination and sync its contents.
3. Move a valid primary to the last-known-good backup. A corrupt primary is
   rejected without replacing an existing good backup.
4. Atomically rename the synced temporary file to the primary path and sync the
   directory where the platform exposes directory syncing.
5. Roll the displaced primary back if installation fails.

Restore validates the primary against the supplied map and ruleset without
mutating the open session. If it fails, the backup must pass the same current
contract before it is opened and promoted to repair the primary. If both fail,
the caller's session remains unchanged.

Backup is another copy of the current format, not an alternate schema. A
reader/upcaster may be introduced only if a second real supported durable
format is intentionally created.

## Evidence

The restore matrix covers all ten strategic command families and eight
mid-workflow states. The corruption corpus covers truncated, oversized,
duplicate-field, unknown-field, content-hash, checkpoint-chain, and exact replay
drift failures. The host recovery drill proves primary writes, backup rotation,
backup promotion, repair, and rejection without session replacement.

Run the focused gate from the repository root:

```sh
make engine-quality-check
```

The machine-readable contracts live in
`engine/fixtures/persistence/manifest.json` and `restore-matrix.json`. They
describe the supported save, replay, restore, and corruption cases directly;
the runtime does not carry a second implementation inventory.

## Shared replay presentation

Local and online playback mount the production `MapScreen` and `MapHudPanels`
with read-only session capabilities. Each verified frame gets a fresh inspection
coordinator; the Flame game, camera and world remain mounted. Resource, research,
city, unit, worker and diplomacy details use the existing recipient queries.
Research selection, production, diplomatic actions, turn progression, automation,
handoff and save commands are unavailable in a viewer.

Starting a seek retires the previous coordinator and its pending queries, closes
its details and suspends pointer, keyboard and gamepad map input. This also applies
to a seek to the same entry. The returned frame creates a new inspection scope;
changing speed or pausing keeps the current scope. Map view changes survive seeks
and the persisted preference is read when another archive opens. Opening, jumping
and repeating clear command effects; observed forward steps retain their effect
history and playback waits for the shared map to present each command.

Playback controls occupy their own area below the map. Widget coverage exercises
both phone orientations, six languages and 200% text, plus same-entry seeks,
read-only terminal inspection, route/lifecycle pauses and observed command audio.
These checks do not replace native archive, privacy or performance gates.

`integration_test/replay_hud_native_test.dart` creates a fog-enabled match and AI
turn through the native Rust adapter, opens the resulting archive in the shared
HUD, and queries research at the initial and final positions. It checks the
recorded final digest, refreshed query stamps, retained Flame world, closed
previous details and absence of gameplay/save requests. The macOS run passed;
this case is included in `make flutter-client-device-test`.
