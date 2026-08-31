# AoNW Godot Client

This directory contains the Godot 4.7 presentation client and the AoNW Map
Workbench. Terrain3D is the required terrain backend; the Rust engine owns
gameplay rules and authoritative state.

## Project map

| Area | Responsibility |
| --- | --- |
| `game/application/` | Immutable read models, map/session orchestration, and ports. |
| `game/infrastructure/` | Strict protocol, native-engine, map-bundle, and terrain adapters. |
| `game/presentation/` | Terrain3D scene, overlays, camera, controls, and UI. |
| `editor/map_authoring/` | Workbench application, infrastructure, presentation, and composition. |
| `addons/aonw_map_workbench/` | Thin Godot editor-plugin entry point. |
| `assets/` | Reviewed and generated client presentation assets. |

The Godot application owns its supported multiplayer API version independently
from the loaded GDExtension. Transport data is decoded into application read
models before it reaches presentation.

## Boundary

- Rust validates maps and commands and owns snapshots, patches, saves, and
  replays.
- Godot owns rendering, input, camera, editor interaction, and local animation.
- One session controller retains one native Rust transport for its lifecycle.
- The loaded GDExtension exposes both `client_api_version()` and
  `build_identity()` before the first session request; mismatches fail closed.
- The runtime requires canonical map bundles and compiled Terrain3D artifacts;
  it has no mesh-terrain or procedural-texture fallback.
- The client uses one current protocol and one engine, with no per-command
  fallback path.
- Incompatible API versions, unknown closed-enum values, and stale artifacts
  fail closed.

## Quick start

Run from the repository root:

```sh
make bootstrap
make godot-check
```

Open or run the project with Godot 4.7:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path clients/aonw_godot
/Applications/Godot.app/Contents/MacOS/Godot --path clients/aonw_godot
```

The map and runtime headless suites can be run directly:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path clients/aonw_godot --script res://tests/test_map_pipeline.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path clients/aonw_godot --script res://tests/test_runtime.gd
```

The workbench creates and edits canonical logical maps through the Rust
`aonw_map_workbench` boundary. Generated visuals and manual Terrain3D work are
presentation artifacts, never another source of gameplay rules.

## Documentation

Read the [Rust engine guide](../../engine/README.md) for the runtime boundary
and [ADR 0011](../../docs/adr/0011-logical-map-workbench-and-generation.md) for
logical map authoring.
