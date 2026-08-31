# AoNW Flutter Client

This is the Flutter and Flame presentation client for the Rust engine. It
consumes the strict client protocol through
`package:aonw_rust_client` and builds the native Rust backend for the host
target.

## Modules

| Area | Responsibility |
| --- | --- |
| `lib/app/` | Bootstrap, composition, routing, lifecycle, and process error handling. |
| `lib/design_system/` | Shared visual tokens and accessible widgets. |
| `lib/features/map/` | Local Rust session orchestration, interaction state, and map presentation. |
| `lib/features/multiplayer/` | Serverpod auth, lobby, recipient projections, reconnect, and resync. |
| `lib/features/settings/` | Client-only preferences and persistence. |
| `lib/features/turns/` | Presentation queue for authoritative turn updates. |
| `lib/game/` | Flame viewport, camera, rendering, and presentation-only effects. |
| `lib/l10n/` | ARB catalogs and generated localization APIs. |

`AppComposition.production()` is the production composition root. Widgets do
not construct FFI sessions or repositories, and presentation code receives
immutable read models rather than wire DTOs.

## Boundary

- Rust owns movement, combat, economy, turns, AI, saves, and replays.
- Flutter owns presentation, input, accessibility, camera, and local animation.
- One gateway retains one Rust session for its complete local-game lifecycle.
- Each multiplayer flow uses one Serverpod session and recipient-only state.
- Accepted commands are followed by an authoritative snapshot or patch; Dart
  never reduces gameplay state locally.
- The client depends only on its current Rust and Serverpod boundaries and has
  no alternate game engine or per-command fallback.
- Incompatible API versions and unknown closed-enum values fail closed.

## Quick start

Run from the repository root:

```sh
make bootstrap
make flutter-client-check
make flutter-client-run
```

Useful focused gates:

```sh
make flutter-client-coverage-report
make flutter-client-device-test
make flutter-client-performance-check
make flutter-client-release-check
make map-stage-1-check
```

The starter map assets are generated from `content/maps/` for both presentation
clients. `make map-stage-1-check` verifies shared semantics without rewriting
Flutter visual goldens.

## Documentation

Release qualification and privacy behavior are defined in
[`docs/release.md`](docs/release.md) and [`docs/privacy.md`](docs/privacy.md).
Client and engine ownership is defined in the
[Rust engine guide](../../engine/README.md) and the
[multiplayer protocol](../../docs/multiplayer-protocol.md).
