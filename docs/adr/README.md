# Architecture decision records

ADRs explain why a long-lived boundary exists and what new code must preserve. Runbooks describe procedures; ADRs describe decisions.

## Index

| ADR | Decision | Status | Implementation |
| --- | --- | --- | --- |
| [0001](0001-map-and-state-ownership.md) | Map And State Ownership | Superseded | In progress |
| [0002](0002-deterministic-game-engine.md) | Deterministic Game Engine | Superseded | In progress |
| [0003](0003-command-boundaries.md) | Command Boundaries | Accepted | Implemented |
| [0004](0004-versioned-multiplayer-protocol.md) | Versioned Multiplayer Protocol | Accepted | Implemented |
| [0005](0005-immutable-deployment.md) | Immutable Deployment Promotion | Accepted | In progress |
| [0006](0006-transport-infrastructure.md) | Transport Infrastructure Ownership And Traversal | Accepted | Implemented |
| [0007](0007-strategic-resource-stockpiles.md) | Strategic Resource Stockpiles And Production Allocation | Accepted | Implemented |
| [0008](0008-rust-engine-ownership-and-strangler-migration.md) | Rust Engine Ownership And Strangler Migration | Accepted | In progress |
| [0009](0009-dart-feature-freeze-and-parallel-successor-clients.md) | Dart Feature Freeze And Parallel Successor Clients | Accepted | In progress |
| [0010](0010-terrain-backend-for-godot-authoring.md) | Terrain Backend For Godot Authoring | Accepted | In progress |
| [0011](0011-logical-map-workbench-and-generation.md) | Logical Map Workbench And Procedural Generation Boundary | Accepted | Implemented |
| [0012](0012-flame-renderer-for-successor-flutter.md) | Flame Renderer For Successor Flutter | Accepted | In progress |
| [0013](0013-in-process-rust-host-for-successor-multiplayer.md) | In-Process Rust Host For Successor Multiplayer | Accepted | In progress |

## Status

- **Proposed** — under review and not binding.
- **Accepted** — binding for new code.
- **Rejected** — considered but not adopted.
- **Superseded** — replaced by a later ADR.

Implementation is tracked separately as `Planned`, `In progress`, or `Implemented`.

Create an ADR when a change affects authoritative state ownership, determinism, command semantics, persisted or network compatibility, or the deployment trust boundary. A local implementation detail belongs in code and tests instead.

An accepted decision is not rewritten when the architecture changes. Create a new ADR, link both records, mark the old one superseded, and update architecture guards and runbooks in the same change.
