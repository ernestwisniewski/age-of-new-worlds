# Architecture decision records

ADRs explain why a long-lived boundary exists and what new code must preserve. Runbooks describe procedures; ADRs describe decisions.

## Index

| ADR | Decision | Status | Implementation |
| --- | --- | --- | --- |
| [0003](0003-command-boundaries.md) | Command Boundaries | Accepted | Implemented |
| [0004](0004-versioned-multiplayer-protocol.md) | Versioned Multiplayer Protocol | Accepted | Implemented |
| [0006](0006-transport-infrastructure.md) | Transport Infrastructure Ownership And Traversal | Accepted | Implemented |
| [0007](0007-strategic-resource-stockpiles.md) | Strategic Resource Stockpiles And Production Allocation | Accepted | Implemented |
| [0008](0008-engine-ownership.md) | Engine Ownership | Accepted | Implemented |
| [0010](0010-terrain-backend-for-godot-authoring.md) | Terrain Backend For Godot Authoring | Accepted | Implemented |
| [0011](0011-logical-map-workbench-and-generation.md) | Logical Map Workbench And Procedural Generation Boundary | Accepted | Implemented |
| [0012](0012-flame-renderer-for-flutter.md) | Flame Renderer For Flutter | Accepted | Implemented |
| [0013](0013-in-process-engine-host-for-multiplayer.md) | In-Process Engine Host For Multiplayer | Accepted | Implemented |

## Status

- **Proposed** — under review and not binding.
- **Accepted** — binding for new code.
- **Rejected** — considered but not adopted.
- **Superseded** — replaced by a later ADR.

Implementation is tracked separately as `Planned`, `In progress`, or `Implemented`.

Create an ADR when a change affects authoritative state ownership, determinism, command semantics, persisted or network compatibility, or a native trust boundary. A local implementation detail belongs in code and tests instead.

An accepted decision is not rewritten when the architecture changes. Create a new ADR, link both records, mark the old one superseded, and update architecture guards and runbooks in the same change.
