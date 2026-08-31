# Rust engine migration

- Status: active strangler migration (final architecture target is Rust-first)
- Governing decision: [ADR 0008](adr/0008-rust-engine-ownership-and-strangler-migration.md)
- Current production reference: legacy Dart compatibility boundary, target production authority: `engine/`
- Successor implementation: `engine/`

Age of New Worlds is moving authoritative gameplay rules from Dart to Rust so
the same engine can serve Flutter, Godot, AI, replay, and Serverpod. Required
game semantics remain deliberate, but Rust is free to use a simpler, safer, or
more efficient design instead of copying Dart line for line.

```mermaid
flowchart LR
  Contracts["1. Stabilize deterministic contracts"] --> Slices["2. Port complete vertical slices"]
  Slices --> Clients["3. Prove Flutter and Godot boundaries"]
  Clients --> Modes["4. Add complete backend modes"]
  Modes --> Cutover["5. Cut over new saves and matches"]
  Cutover --> Retire["6. Retire Dart authority"]

  Dart["Legacy Dart compatibility reference"] -. parity fixtures .-> Slices
  Slices -. accepted/rejected output, digests, events, evidence .-> Dart
  Modes -. kill switch / rollback .-> Dart
```

## Current checkpoint

The Rust workspace now owns the complete reviewed engine inventory through
E0-PS11: strict content and canonical state, all current command families and
queries, integrated turn processing, recipient-safe projection, deterministic
strategic AI, current save/replay, local sessions, persistence recovery, and
thin native boundaries. The active work is the final engine completion gate,
not another gameplay family.

This does **not** make Rust the immediate production backend. Flutter local play and
Serverpod still use Dart by default until their later migration and cutover.

The current crate inventory and commands are documented in [`../engine/README.md`](../engine/README.md).

## Engine-to-client handoff

The handoff is intentionally smaller than production cutover. New clean clients
may start when one reviewed commit has complete E0-PS11 behavior, one current
recipient-safe client/native contract, and a green `make
rust-engine-completion-check` (or green pinned fast, evidence, deep, and security
jobs for that same commit).

Client platform coverage, packaging, Serverpod hosting, shadow/canary modes,
retiring Dart authority, and the final Web transport are not prerequisites for
starting the clients. They are delivered later by client qualification and
server cutover. No extra readiness framework or parallel compatibility adapter
is required. Focused checks are used while developing; the full completion gate
runs only at the handoff checkpoint and in CI.

## Rules that do not change during migration

1. The Flutter application stays buildable and releasable at the repository root.
2. The legacy Dart compatibility boundary remains behavioral evidence and a frozen compatibility checkpoint until explicit cutover gates pass; it is not a runtime architecture dependency for new clients.
3. Preserve required game behavior, but prefer a simpler, safer, or more efficient Rust design over a line-for-line Dart port.
4. One save or match uses one primary engine for its entire lifetime.
5. Command families are never split between Dart and Rust inside an active session.
6. Fixtures are an independently reviewed oracle. Neither implementation may generate and bless its own expected result in CI.
7. Flutter, Godot, bridge code, and Serverpod endpoints do not own movement, combat, economy, fog, AI, or save rules.
8. Public protocol and durable schema changes follow their existing compatibility process; a language port does not imply a version bump.

## Target ownership

```mermaid
flowchart TB
  subgraph Pure["Pure deterministic Rust"]
    Domain["Domain + engine"]
    Contracts["Content + versioned contracts"]
    Projection["Recipient projection"]
    Contracts --> Domain
    Domain --> Projection
  end

  Runtime["Local runtime"] --> Domain
  Runtime --> Projection
  Flutter["Flutter adapter"] --> Runtime
  Godot["Godot adapter"] --> Runtime
  Serverpod["Serverpod host"] --> Domain
  Serverpod --> Projection
  Serverpod --> DB[(PostgreSQL)]

```

| Component | Responsibility |
| --- | --- |
| Rust domain and engine | Pure deterministic state transitions and queries. No I/O, framework, clock, localization, or database dependencies. |
| Rust content/contracts | Strict versioned maps, scenarios, state, save, replay, and client protocol models. |
| Local runtime | Session lifecycle, revision checks, command/query dispatch, recipient snapshots, and view patches. |
| Flutter/Godot adapters | Marshal the shared client protocol and render recipient-safe results. |
| Serverpod | Authentication, lobby/match lifecycle, locking, transactions, persistence, offsets, post-commit delivery, and reconnect. |
| PostgreSQL | Durable online source of truth. |

Recipient projection is a rules-sensitive policy and belongs with the engine. A remote client never reconstructs canonical `DomainState` from projected data.

## Migration sequence

### 1. Stabilize contracts

Keep the Dart engine boundary deterministic and explicit. Every external rule input must be carried in state, command, or context. Presentation effects stay outside authoritative results.

### 2. Port complete vertical slices

For each slice:

- read all supported current inputs;
- produce the same accepted/rejected result, state digest, events, evidence, and RNG position;
- cover round trips and rejection-without-mutation;
- keep the Dart path releasable;
- add a measured performance case when the slice is performance-sensitive.

Do not create empty crates for planned responsibilities. Add a crate when its first behavior and tests are ready.

### 3. Prove native client boundaries

Godot and Flutter consume the same coarse, versioned client protocol. Raw canonical state does not cross the client boundary. Native panics are contained in the adapter and reported as stable errors.

Required checks:

```sh
make rust-check
make rust-flutter-test
make godot-check
```

### 4. Add complete backend modes

The rollout model needs complete-engine selections such as:

- Dart only;
- Dart primary with Rust shadow;
- Rust primary with Dart shadow;
- Rust primary with Dart standby;
- Rust only.

Shadow output is comparison data only. It is never persisted, broadcast, or shown as authoritative.

### 5. Cut over new work

A kill switch may change the default engine for new saves or matches after parity, packaging, observability, and rollback drills pass. Existing work remains pinned unless an explicit versioned migration proves it safe to move.

Readers and writers for the single current Rust contract ship together. New
Flutter and Godot clients consume that contract directly; no Dart bridge or
rollback adapter is introduced. Development artifacts are unsupported until
the first production writer establishes the compatibility-support boundary.

### 6. Retire Dart authority

The Dart engine can be removed only when all of the following use Rust:

- every player and system command;
- queries and legality previews;
- turn processing, AI, and simulation;
- canonical saves and replay;
- recipient projection;
- Flutter and Godot local sessions;
- Serverpod authoritative transitions and recovery;
- every supported platform, including a deliberate Flutter Web solution.

No active server match may remain pinned to Dart. A reader/upcaster is added
only when a second real production format is deliberately supported; there is
no speculative compatibility layer for pre-cutover development artifacts. The
rollback window and drills must be complete.

Only after retirement should the repository be reorganized mechanically into final client/service directories. Do not mix that move with behavior migration.

## Rust quality baseline

The successor engine has three deliberately separate quality layers. `make
successor-engine-check` is the fast merge gate and combines the frozen-boundary
checks, all-feature Rust format/Clippy/test/doc/build checks, the exact crate and
unsafe architecture census, pinned license/source/duplicate policy, and
debug/release determinism. `make successor-engine-evidence-check` runs the
current capability-gated parity corpus and publishes LLVM coverage JSON, LCOV,
and structural performance evidence. `make successor-engine-deep-check` adds
release-mode workspace tests on its scheduled pinned Linux runner. Native
adapter/platform smokes remain separate jobs because unsupported rows must be
reported as unsupported, never replaced with a successful stub.

Coverage measurement is delegated to pinned `cargo-llvm-cov 0.9.0`. The local
checker supplies repository policy that the measurement tool does not know:
the complete crate-role census, explicit exclusions, per-authoritative-crate
and local-runtime ratios, uncovered-line ceilings, and a missing-file set that
may only shrink. Adapter coverage is deliberately not folded into the Linux
pure-engine denominator. Line coverage is the primary gated metric. Instead of
a fragile diff-only percentage, every changed line is constrained by full-crate
ratio, uncovered-line, and executable missing-file ratchets. Branch coverage is
diagnostic until LLVM source attribution is stable enough for a reviewed
baseline. Renames require an explicit baseline migration, macro lines keep LLVM
attribution, generated/test/support files may be excluded only by reviewed
globs, and small crates follow the same per-crate ratchets. No arbitrary global
percentage threshold or internal coverage format version is introduced.

Structural performance measurement uses pinned `stats_alloc 0.1.10` around a
single-threaded measured region after setup and warm-up. The gate ratchets exact
result signatures, work counters, allocations, allocated bytes, payload bytes,
and soak count. Host-local timing remains diagnostic. Criterion and Divan are
appropriate for statistical timing exploration, while Iai-Callgrind may later
add Linux-only instruction/cache diagnostics to the deep workflow; none of
them replaces the portable domain counters and allocation contract required
for this migration.

Dependency policy uses `cargo-deny 0.20.2` from crates.io. Licenses and sources
fail closed. The only current duplicate exception is the exact `syn` 2/3 pair
introduced by the EXR/zerocopy and serde proc-macro chains; it is owned by the
engine foundation, expires on 2027-08-24, and must be removed or re-reviewed at
expiry. OSV continues to scan every committed lockfile independently.

Release metadata is generated, not handwritten. Pinned OWASP
`cargo-cyclonedx 0.5.9` emits target-specific CycloneDX 1.5 JSON with
`SOURCE_DATE_EPOCH` bound to the source commit; pinned `cargo-about 0.9.2` with
the explicit `cli` feature emits matching third-party notices while excluding
dev/build-only dependencies. The gate works in an isolated engine copy because
the upstream CycloneDX workspace command writes beside every member manifest.
Only the current Flutter cdylib, Godot cdylib, and map-compiler CLI outputs are
published. Environment-specific local workspace paths in CycloneDX `bom-ref`
values are normalized to the stable virtual `/aonw/engine` root without changing
the generated dependency graph. Two independent generations must be
byte-identical, and the uploaded manifest records each SHA-256. Repository code
validates and orchestrates these external generators; it does not implement an
SBOM or license scanner.

Security-oriented test tooling is also external and pinned. `cargo-mutants
27.1.0` runs 19 focused mutations across codec bounds, state digest finalization,
turn finalization, and persistence identity validation with zero survivors.
`cargo-fuzz 0.13.2` and `libfuzzer-sys 0.4.13` run bounded ASan smokes for strict
persistence codecs, canonical DTO/domain mapping, and the live Flutter C ABI.
Miri runs the feasible pure contract/domain boundary on
`nightly-2026-08-24`. A separate C17 consumer harness links the actual Flutter
cdylib and runs valid lifecycle/null cases plus intentional response/session
double-free cases under Clang ASan/UBSan. The latter must fail with a sanitizer
diagnostic; stale handles remain invalid by contract and are not hidden behind a
runtime registry. CI pins Ubuntu 24.04 and Clang 18 for that gate. The strict
repository policy validates tool provenance, exact target census, bounds, and
outcomes; it does not implement its own mutation engine, fuzzer, sanitizer, or
interpreter. Expensive execution is a separate scheduled/manual workflow, while
policy drift fails fast CI.

These quality artifacts describe the single current greenfield engine and
successor-client contract. They introduce no legacy reader, adapter, upcaster,
or redundant internal format version. Shared API, map, fixture, and other real
multi-component versions remain unchanged.

## Verification and fixtures

Historical reducer corpora under `test/fixtures/` are frozen, read-only
migration evidence. Rust does not read or regenerate them. Active Rust behavior
coverage lives under `engine/fixtures/` and uses only the strict current
canonical contract.

A slice is complete only when the canonical fixture owns the full typed input
and Rust returns the full expected state, events, evidence, and rejection—not
just the visible destination or a projected subset of fields.

Run Rust performance diagnostics separately:

```sh
make rust-benchmark
```

Wall-clock numbers are host-local observations. Stable signatures and work counters are the regression evidence.

## Known transitional boundaries

- Flutter network state is recipient-projected by Serverpod but still passes through a Dart canonical compatibility envelope. Replace it with nominal recipient types before remote-replica cutover.
- The Rust client/save/replay contracts are current-only. Historical upcasters are deferred until a second schema exists.
- Atomic native writes, current-format backup promotion, and transactional restore are documented in [`rust-engine-persistence.md`](rust-engine-persistence.md).
- Rust is not yet the Serverpod production engine or the default Flutter local engine.

Keep this page at milestone level. Detailed crate behavior belongs in `engine/README.md`, Godot authoring behavior in `clients/aonw_godot/README.md`, and durable decisions in ADRs.
