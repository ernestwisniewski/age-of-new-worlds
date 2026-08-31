# ADR 0009: Dart Feature Freeze And Parallel Successor Clients

- Status: Accepted
- Date: 2026-08-22
- Implementation: In progress

## Context

ADR 0008 establishes Rust as the successor engine while keeping legacy root
Flutter compatibility releasable until retirement. This preserves current
production continuity, while the target architecture remains Rust-first in
`engine/` with successor presentation under `clients/aonw_flutter`.

Waiting for complete Dart retirement would couple UI replacement to the longest part of the engine migration. Continuing feature development in the root Flutter application would also let presentation code and Dart rules grow together while Rust is becoming authoritative.

## Decision

The current Dart application becomes maintenance-only while successor clients are developed in parallel:

```mermaid
flowchart LR
  Rust["Authoritative Rust engine"] --> Flutter["Successor Flutter client"]
  Rust --> Godot["Godot client and Map Workbench"]
  Legacy["Frozen Dart application"] -. maintenance only .-> Release["Legacy release path"]
```

- Root Flutter compatibility sources are feature-frozen at the tree OIDs
  recorded in `tool/legacy_freeze_manifest.v1` and treated as legacy compatibility
  baselines;
- the root Flutter application remains buildable and releasable, but receives no successor features;
- a freeze exception is limited to a critical production failure, security issue, or toolchain compatibility change;
- an exception requires separate owner approval, focused verification, and a reviewed manifest update;
- current `test/` and the legacy Dart test set remain part of legacy regression
  coverage;
- normal successor workflows and code generators must not write into either frozen tree;
- the new Flutter client is built independently under `clients/aonw_flutter/` and must not import legacy gameplay packages;
- the existing Godot client will be renamed once to `clients/aonw_godot/`; a second Godot client will not be created;
- gameplay rules remain owned by the authoritative engine, never by Flutter widgets or GDScript.

This ADR supersedes ADR 0008 only for successor-client timing and physical client locations. ADR 0008 remains binding for engine ownership, parity, cutover, rollback, session backend pinning, and retirement.

## Consequences

The successor UI can advance in small vertical slices while the shipping application remains stable. The freeze makes accidental legacy feature work visible and keeps rollback available without creating another source of gameplay rules.

Critical maintenance changes carry an explicit review cost because the stored tree OID must change. Generated files inside frozen trees cannot be refreshed as an incidental part of successor work.

## Migration And Verification

`make p0-check` verifies the recorded tree OIDs, rejects staged and unstaged changes plus untracked additions in frozen trees, checks successor dependency boundaries, and runs negative fixtures proving that the guards fail closed.

Every successor checkpoint reports both current tree OIDs. A freeze exception updates the manifest only after its code change and regression evidence have been approved together.

## Related Decisions And Documentation

- [ADR 0008: Rust engine ownership and strangler migration](0008-rust-engine-ownership-and-strangler-migration.md)
- [Rust engine migration](../rust-engine-migration.md)

## Rejected Alternatives

- Waiting for Dart retirement before starting the successor Flutter client.
- Copying the root Flutter application into the successor client.
- Maintaining two Godot clients.
- Allowing successor code generation to refresh frozen Dart sources.
