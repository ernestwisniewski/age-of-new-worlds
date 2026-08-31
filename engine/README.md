# AoNW Engine

This workspace is the authoritative gameplay implementation for Age of New
Worlds. It owns canonical state, rules, deterministic transitions, recipient
projection, AI, save/replay, and the native boundaries used by Flutter, Godot,
and Serverpod.

## Workspace

| Area | Purpose |
| --- | --- |
| `aonw_domain` | Canonical state, entities, identifiers, topology, and fixed-point values. |
| `aonw_content` | Strict maps, scenarios, rulesets, catalogs, and content hashes. |
| `aonw_contracts` | Client API plus canonical state, save, replay, and server DTOs. |
| `aonw_contract_mapping` | Validated contract/domain conversion. |
| `aonw_engine` | Commands, queries, deterministic transitions, evidence, and turn processing. |
| `aonw_projection` | Recipient-safe projections and diffs. |
| `aonw_local_runtime` | Transactional local sessions, caches, snapshots, save, and replay. |
| `aonw_ai` | Deterministic strategic planning through public runtime transitions. |
| `aonw_flutter` | Panic-contained C ABI for Flutter Native Assets. |
| `aonw_godot` | GDExtension over the shared client protocol. |
| `aonw_server_native` | Stateless native host for Serverpod transactions. |
| `aonw_map_*` | Logical map validation, editing, generation, and compilation. |

Pure engine crates do not depend on Flutter, Godot, Serverpod, filesystem,
network, wall-clock time, system randomness, or presentation code. Adapters
translate current contracts and do not implement rules.

## Checks

Run from the repository root:

```sh
make rust-check
make engine-architecture-check
make engine-performance-check
make engine-runtime-performance-check
make engine-client-test
make godot-check
```

`make engine-quality-check` is the normal aggregate engine gate. It runs
the Rust compiler/test/documentation checks, architecture policy, Dart engine
client contract, and portable performance budget. `make release-check` adds
release-mode and pinned-device qualification.

Architecture policy is in `quality/architecture_policy.json`. Portable
structural performance is in `quality/performance_baseline.json`; accepted
runtime latency on the reviewed MacBookPro18,2 host is governed by
`quality/runtime_performance_policy.json`.

Exploratory benchmarks remain available through:

```sh
make engine-benchmark
make engine-performance-report
make engine-runtime-performance-report
```

## Contracts

One local session retains one native transport and one build/content/contract
identity. A mismatch fails closed. Rejected commands do not mutate canonical
state, revisions, replay, caches, or projections.

The engine and in-repository clients update the current local contract
atomically. Versions remain where independently deployed network consumers or
durable supported documents require them. A second reader is introduced only
for a real supported format, never speculatively.

## Documentation

- [Engine quality](../docs/engine-quality.md)
- [Save and replay contract](../docs/engine-persistence.md)
- [Performance benchmarks](../docs/performance-benchmarks.md)
- [Architecture decisions](../docs/adr/README.md)
- [Clients](../clients/README.md)
