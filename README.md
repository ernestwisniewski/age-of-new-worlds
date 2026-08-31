# Age of New Worlds

[![CI](https://github.com/ernestwisniewski/aonw/actions/workflows/ci.yml/badge.svg)](https://github.com/ernestwisniewski/aonw/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B.svg)](https://flutter.dev)

Age of New Worlds is an open-source, turn-based 4X game built around a hex map.
The authoritative engine is written in Rust, the presentation clients use
Flutter/Flame and Godot, and online matches are hosted by Serverpod with the
same Rust rules and recipient projections used by local sessions.

## Public Links

| Destination | Link |
| --- | --- |
| Website | [aonw.net](https://aonw.net/) |
| Architecture | [Interactive Rust engine map](https://engine.aonw.net/architecture) |
| Rust engine | [4X engine and API documentation](https://engine.aonw.net/) |
| Devlog | [ernest.dev](https://ernest.dev) |
| GitHub | [ernestwisniewski/aonw](https://github.com/ernestwisniewski/aonw) |
| iOS | [App Store](https://apps.apple.com/pl/app/age-of-new-worlds/id6781790591) |
| Windows/Linux/macOS | [Steam](https://store.steampowered.com/app/4833240/Age_of_New_Worlds/), [itch.io](https://ernest-dev.itch.io/aonw) |
| Android | [Google Play](https://play.google.com/store/apps/details?id=aonw.net.game), [itch.io](https://ernest-dev.itch.io/aonw) |

## Repository

| Area | Purpose |
| --- | --- |
| `engine/` | Deterministic Rust engine, contracts, runtimes, projections, native adapters, and map tooling. |
| `clients/aonw_flutter/` | Flutter and Flame client for local and online play. |
| `clients/aonw_godot/` | Godot presentation client and Terrain3D map workbench. |
| `packages/aonw_engine_client/` | Dart binding to the Rust local runtime. |
| `packages/aonw_server_native/` | Native Rust boundary used by the Serverpod host. |
| `packages/aonw_server_client/` | Generated Serverpod auth and game client. |
| `server/` | Serverpod authentication, game transactions, recipient delivery, persistence, and public status. |
| `content/` | Versioned logical maps and scenarios shared with Rust and Godot. |
| `docs/` | Architecture, gameplay contracts, quality policy, and runbooks. |

## Quick start

Use the Flutter version pinned in [`.fvmrc`](.fvmrc). FVM is optional; Make uses `.fvm/flutter_sdk` automatically when it exists.

```sh
make bootstrap
make rust-engine-quality-check
make flutter-client-check
make godot-check
make server-test
```

`make bootstrap` installs the locked package graphs and the matching Serverpod CLI. It does not generate code, start Docker, or alter lockfiles.

The complete release qualification is `make release-check`. Useful focused
checks include:

```sh
make rust-engine-check
make rust-coverage-check
make engine-performance-check
make engine-transition-performance-check
make flutter-client-performance-check
make server-integration-test
```

## Run the Flutter client

For local play backed by the in-process Rust runtime:

```sh
make flutter-client-run
```

For the local multiplayer stack:

```sh
cp .env.example .env
# Replace every placeholder secret in .env.
make local-start
make local
```

The API runs at `http://localhost:8080`. Four local accounts are seeded as
`test1@example.test` through `test4@example.test`; the shared development
password is `AonwTest123!`.

Run the automated multiplayer smoke with:

```sh
make local-multiplayer-smoke
```

Stop the stack without removing its data:

```sh
make local-down
```

## Rust and Godot

```sh
make rust-check
make godot-check
make map-stage-1-check
make godot-editor
make godot-run
```

`make map-stage-1-check` compares normalized Flutter and Godot map semantics;
client-owned visual goldens remain separate and are never rewritten by this gate.

## Documentation

Start with [docs/README.md](docs/README.md). It explains which implementation is authoritative, where each subsystem lives, and which checks apply to a change, including [static analysis](docs/static-analysis.md), [critical journeys](docs/critical-e2e.md), [mutation testing](docs/mutation-testing.md), and [architecture budgets](docs/architecture-budgets.md).

Contribution setup and pull-request expectations are in [CONTRIBUTING.md](CONTRIBUTING.md). Architecture decisions are indexed in [docs/adr/README.md](docs/adr/README.md).

## Localization

English is the source language in
`clients/aonw_flutter/lib/l10n/app_en.arb`. Regenerate localization output from
the Flutter client directory after changing ARB files.

## License

Code is released under the [MIT License](LICENSE). Asset and dependency notices are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
