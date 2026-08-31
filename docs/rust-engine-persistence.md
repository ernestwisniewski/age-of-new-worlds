# Rust engine persistence

The Rust engine supports one current canonical save contract and one current
bounded replay contract. These contracts are shared by the new native clients;
they do not wrap a Dart save, carry an internal format version, or include a
legacy reader, adapter, alias, fallback, or upcaster.

`SaveGameDto` owns the complete canonical state, content identities, actor,
event offset, and state digest. `ReplayLogDto` owns a bounded chain of canonical
checkpoints and exact command context and results. The shared client API version
remains in place because Flutter, Godot, and native libraries are independently
built components.

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

Backup is another copy of the current format, not compatibility infrastructure.
Development saves made before production cutover have no support guarantee.
Compatibility support starts only when the first production Rust writer is
enabled after the Engine Completion Gate. A reader/upcaster may be introduced
only if a second real supported durable format is intentionally created.

## Evidence

The restore matrix covers all ten strategic command families and eight
mid-workflow states. The corruption corpus covers truncated, oversized,
duplicate-field, unknown-field, content-hash, checkpoint-chain, and exact replay
drift failures. The host recovery drill proves primary writes, backup rotation,
backup promotion, repair, and rejection without session replacement.

Run the focused gate from the repository root:

```sh
make rust-persistence-check
```

The machine-readable contracts live in
`engine/fixtures/persistence/manifest.json` and `restore-matrix.json`. They
describe the supported save, replay, restore, and corruption cases directly;
the runtime does not carry a second implementation inventory.
