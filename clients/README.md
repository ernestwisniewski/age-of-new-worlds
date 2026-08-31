# AoNW Clients

`clients/` contains the presentation clients for the Rust engine.
Both clients consume the same strict, versioned multiplayer API and keep
gameplay rules, authoritative state transitions, saves, and replays in Rust.

## Clients

| Client | Purpose |
| --- | --- |
| [`aonw_flutter/`](aonw_flutter/) | Flutter and Flame desktop/mobile client backed by `package:aonw_engine_client`. |
| [`aonw_godot/`](aonw_godot/) | Godot 4.7 desktop client and Terrain3D map workbench backed by the Rust GDExtension. |

## Contract

- The clients implement presentation, input, accessibility, camera, and local
  animation only.
- Rust owns gameplay validation and every authoritative state transition.
- The shared multiplayer API remains explicitly versioned where peers must
  negotiate compatibility.
- Clients use one game engine and one current protocol; they do not implement
  alternate rules or per-command fallback paths.
- Unknown protocol values and incompatible native libraries fail closed.

## Quick start

Run focused client checks from the repository root:

```sh
make flutter-client-check
make godot-check
```

Run the clients with:

```sh
make flutter-client-run
```

Shared map semantics are covered by `make flutter-client-map-contract-test`
and the Godot map pipeline within `make godot-check`. Client-owned visual
goldens remain separate.

## Documentation

Read the client-specific [Flutter](aonw_flutter/README.md) and
[Godot](aonw_godot/README.md) guides. Engine ownership and quality gates are
defined in the [Rust engine guide](../engine/README.md), with architecture
decisions indexed under [`docs/adr/`](../docs/adr/README.md).
