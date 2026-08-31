# Contributing

Thanks for taking a look at Age of New Worlds.

Please follow the project [Code of Conduct](CODE_OF_CONDUCT.md) when
participating in issues, pull requests, discussions, and reviews.

## Setup

Use the exact Flutter SDK selected by `.fvmrc` and its bundled Dart SDK. The
manifest constraints describe package compatibility; `.fvmrc` is the local and
CI toolchain pin. FVM is optional:
`fvm install --setup --skip-pub-get` provisions the project SDK without an
unlocked dependency resolution, and Make automatically prefers
`.fvm/flutter_sdk` when it exists.

```sh
make bootstrap
```

Bootstrap verifies the active toolchain, resolves the root Flutter graph,
generated client, and server lockfiles with `--enforce-lockfile`,
and ensures
the Serverpod CLI version pinned in `server/pubspec.yaml`. It does not run
generators or tests.

For backend work, copy `.env.example` to `.env`, replace placeholder secrets,
and use Docker Compose for PostgreSQL and Redis.

## Checks

Before opening a pull request, run:

```sh
make ci
```

`make ci` runs generated-code drift, formatting, analysis, architecture,
mutation, deterministic performance, and coverage gates plus the
generated-client smoke test. CI delegates to the same Make targets.

For a focused analysis pass, run `make analyze`. The four packages compose one
strict base with ecosystem-specific upstream profiles; see the
[static-analysis policy](docs/static-analysis.md) before changing a rule or an
exclusion.

Run `make mutation` after changing the combat serializer, unit-command
validator, authentication input validator, or their focused tests. Any mutation
baseline change must be explained by reviewed source or assertion changes and
must preserve the historical ratchet; see the
[mutation-testing policy](docs/mutation-testing.md).

Run the generated-code gate on its own while changing generator inputs:

```sh
make generated-code-check
```

It recreates legacy root build-runner output, Flutter localizations,
Serverpod protocol/client/test output, and Serverpod migrations in an isolated
snapshot of the current workspace. It reports drift without modifying the
active checkout. A matching Serverpod CLI is required; `make bootstrap`
installs or verifies it.

When touching Serverpod schemas, generated protocol files, migrations, Compose
files, or deployment behavior, also run:

```sh
make serverpod-ops-check
```

Integration tests that require PostgreSQL are intentionally separate:

```sh
make server-integration-test
```

Changes to local game creation or persistence, multiplayer authentication,
match lifecycle, command dispatch, or reconnect behavior must also run the
real-boundary journeys:

```sh
make critical-e2e-test
```

The live journey requires local PostgreSQL. The release-safe wrapper starts
and resets the dedicated test database before running both Serverpod layers:

```sh
tool/run_postgres_smoke.sh
```

See [Critical End-to-End Journeys](docs/critical-e2e.md) for the covered
contracts, isolated ports, and failure ownership.

### Test Coverage

Run the complete line-coverage gate with:

```sh
make coverage-check
```

It measures the legacy Flutter app (`lib/`), legacy Dart scope, and
server unit-test scopes. The root
Flutter suite runs serially, and the generated Serverpod client remains a smoke
test without a percentage target. PostgreSQL integration tests stay outside
coverage collection and must still be run separately when relevant.

Use `make coverage` to collect all reports, or `make flutter-coverage`,
`make core-coverage`, and `make server-coverage` for a focused scope. Diff
coverage uses `origin/main` unless `COVERAGE_BASE_REF=<git-ref>` is supplied.
The baseline ratchet and incremental diff independently use the trusted
previous revision (the branch upstream locally and the PR base or pre-push SHA
in CI).

The committed snapshot keeps exact instrumented totals and portable minimum
covered counts. It is protected by a historical ratchet: per layer, the ratio
cannot decrease, uncovered counts cannot increase, and the missing-file set may
only shrink. Changed eligible lines require at least 90% coverage. Do not add
inline ignore annotations or relax the centralized generated-code exclusions
to make the gate pass. See
[Test Coverage](docs/test-coverage.md) before updating the baseline or policy.

Run `make architecture` for the repository-wide Dart census and AST size
and complexity budget. New files, types, and callables must meet their
role-specific targets; existing debt in file/type size, callable length,
nesting, cyclomatic complexity, and cognitive complexity may only shrink. Read
[Architecture Budgets](docs/architecture-budgets.md) before changing the
policy or baseline.

### Performance Benchmarks

Run the portable engine performance gate with:

```sh
make engine-performance-check
```

The harness covers movement, authoritative transitions, projection, wire,
persistence/replay, turn finalization and exact-budget AI. CI compares
deterministic work metrics and result signatures; shared-runner timings remain
diagnostic. Use `make engine-performance-report` for the full report and
`make engine-performance-snapshot` only to create a candidate for review.
Release qualification additionally runs `make
engine-transition-performance-check` on the pinned reference Mac and
`make flutter-client-performance-check` for the renderer. Read [Performance
Benchmarks](docs/performance-benchmarks.md) before changing a workload, policy,
baseline, or device budget.

### Mutation Testing

Run the deterministic critical-code gate with:

```sh
make mutation
```

It mutates the combat wire serializer, unit-command validator, and server auth
input validator one site at a time in an isolated workspace. Only a focused
user-test failure kills a mutant; analysis errors, crashes, timeouts, and suite
load failures fail the gate itself.

After an intentional target or assertion change, generate and review a
candidate rather than editing the baseline manually:

```sh
make mutation-snapshot
diff -u tool/mutation_baseline.json /tmp/aonw-mutation-baseline.json
```

Every census change must follow from the reviewed source or tests, introduce no
surviving mutant, and preserve the historical ratchet. Read
[Mutation Testing](docs/mutation-testing.md) before updating the baseline or
policy.

## Generated Code

The drift gate only verifies generated artifacts. When their sources change,
regenerate the relevant artifacts deliberately in the real checkout:

```sh
flutter pub run build_runner build
flutter gen-l10n
(cd server && dart pub global run serverpod_cli:serverpod_cli generate)
(cd server && dart pub global run serverpod_cli:serverpod_cli create-migration)
```

Review every generated diff, commit the expected output, and rerun
`make generated-code-check`.

## Rust Engine Migration

Read the [Rust Engine Migration Plan](docs/rust-engine-migration.md) and
[ADR 0008](docs/adr/0008-rust-engine-ownership-and-strangler-migration.md)
before introducing or changing Rust engine code, a Flutter native bridge, or
the Godot AoNW2 client.

The Rust Cargo workspace will be introduced directly at `engine/`; do not
create a parallel temporary `rust/` root. Keep the existing Flutter project at
the repository root until the migration plan's Dart retirement gate passes.

Migration changes must preserve these rules:

- port existing behavior before redesigning it;
- keep the legacy Dart implementation fixable, tested, and releasable while it
  remains a production/rollback compatibility engine;
- use `test/fixtures/reducer_parity/` as the shared, independently reviewed
  oracle; neither Dart nor Rust may calculate or bless `expected` during CI;
- select one complete primary engine for a session or match; shadow execution
  may compare a second engine but never persist its result;
- keep domain and engine crates independent of Flutter, Godot, Serverpod, I/O,
  networking, clocks, and localization;
- keep gameplay rules out of Dart bridge code, GDScript, Godot scenes, and
  Serverpod endpoints;
- change a fixture, schema, behavior version, or public protocol only through
  its existing review and compatibility policy.

Once `engine/Cargo.toml` exists, Rust changes run formatting, Clippy with
warnings denied, workspace tests, documentation, relevant target compilation,
and the shared parity suite in addition to the existing `make ci` gate. Native
and WASM checks are required according to the platforms affected by the change.
Do not weaken an existing Flutter/Dart gate to make room for the new workspace.

## Localization

English is the source language. `lib/l10n/app_en.arb` is the template that
defines the canonical key set and placeholder metadata; the other locales
(`app_pl.arb`, `app_de.arb`, `app_es.arb`, `app_nl.arb`, `app_fr.arb`)
translate it and fall back to English for any missing key.

When you add or change user-facing text:

1. Add the key and English value (plus any `@key` placeholder metadata) to
   `app_en.arb`.
2. Mirror the key into the other locale files with a translation, or leave it to
   fall back to English until a translation is provided.
3. Regenerate with `flutter gen-l10n` and reference it via
   `AppLocalizations.of(context)`.

Production Dart sources must not contain user-facing literals; this is enforced
by `test/.../localization_hardcode_guard_test.dart`.

## Guidelines

- Keep changes focused and update docs when behavior, persistence, APIs, game
  rules, or build/deploy flows change.
- Keep generated files in sync with their source annotations and Serverpod
  definitions.
- Do not commit `.env`, signing keys, local IDE state, traces, build outputs, or
  benchmark artifacts.
- Keep architecture boundaries intact. If a dependency crosses layers, update
  the architecture test and docs in the same change.
- Follow accepted [Architecture Decision Records](docs/adr/README.md). A change
  to a binding decision requires a new superseding ADR, index/docs updates, and
  the corresponding architecture guards in the same pull request.
- Prefer small comments that explain intent or invariants.
