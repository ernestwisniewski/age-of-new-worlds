# Contributing

Thanks for contributing to Age of New Worlds. Follow the project
[Code of Conduct](CODE_OF_CONDUCT.md) in issues, discussions, and reviews.

## Setup

Use the Flutter SDK selected by `.fvmrc`; FVM is optional. Make automatically
uses `.fvm/flutter_sdk` when it exists.

```sh
make bootstrap
```

Bootstrap verifies the toolchain, installs locked Dart dependencies, and
ensures the Serverpod CLI version from `server/pubspec.yaml`. For server work,
copy `.env.example` to `.env` and replace every placeholder secret. OrbStack or
Docker Desktop can provide the Docker Compose runtime.

## Checks

Run the repository gate before opening a pull request:

```sh
make ci
```

Useful focused gates are:

```sh
make engine-quality-check
make flutter-client-check
make godot-check
make server-test
make architecture-check
make generated-code-check
make compose-check
```

`make release-check` adds release-mode Rust tests, pinned-device engine runtime
measurements, Flutter device/performance/build checks, and the
Serverpod deployment checks.

PostgreSQL integration tests are deliberately separate:

```sh
make server-integration-test
```

The local online journey uses the real Compose stack:

```sh
make local-start
make local-multiplayer-smoke
make local-down
```

## Generated code

The drift gate verifies generated artifacts without rewriting the checkout.
When generator sources change, regenerate deliberately:

```sh
(cd clients/aonw_flutter && flutter gen-l10n)
(cd server && dart pub global run serverpod_cli:serverpod_cli generate)
(cd server && dart pub global run serverpod_cli:serverpod_cli create-migration)
```

Review every generated diff and rerun `make generated-code-check`. The server
keeps one initial schema migration until a deployed schema requires a real
follow-up migration.

## Engine development

Read [Engine quality](docs/engine-quality.md) and
[ADR 0008](docs/adr/0008-engine-ownership.md) before changing the engine or a
native boundary.

- Keep canonical state, legality, costs, pathfinding, combat, fog, AI, turns,
  save, replay, and recipient projection in `engine/`.
- Keep pure engine crates independent of frameworks, I/O, networking, clocks,
  system randomness, and localization.
- Do not put gameplay rules in Dart adapters, GDScript, scenes, widgets, Flame
  components, or Serverpod endpoints.
- Keep fixture expectations independently reviewable; production code must not
  calculate and approve its own expected output in CI.
- Change durable schemas and public protocols through their explicit version
  and compatibility policies.
- Run `make engine-quality-check` and every affected client/server gate.

## Client development

Flutter application code lives under `clients/aonw_flutter`; its English and
Polish localization sources are under `clients/aonw_flutter/lib/l10n`. Godot
runtime and editor code live under `clients/aonw_godot`.

Presentation may calculate layout, picking, interpolation, and animation. It
must consume engine-provided legality and results instead of rebuilding rules.
The Flutter gamepad plugin belongs to the Flutter client and must not become a
root package.

## Guidelines

- Keep changes focused and add an appropriate test.
- Update documentation when a public contract, workflow, or operational
  procedure changes.
- Preserve unrelated worktree changes.
- Do not commit `.env`, signing keys, `.codex/`, IDE state, build outputs,
  traces, or unreviewed benchmark output.
- Keep generated files synchronized with their sources.
- Follow accepted [architecture decisions](docs/adr/README.md). A binding
  decision change needs a superseding ADR and matching guards.
- Use comments for intent and invariants, not narration of obvious code.
