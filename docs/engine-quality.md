# Engine quality

The Rust workspace under `engine/` is the single gameplay implementation for
Flutter, Godot, AI, replay, and Serverpod. This page describes its current
quality contract. Historical implementation comparisons are not part of that
contract.

## Ownership

- `aonw_domain` and `aonw_engine` own canonical state, validation, rules,
  deterministic transitions, events, and execution evidence.
- `aonw_content` and `aonw_contracts` own strict content and externally consumed
  documents.
- `aonw_projection` produces recipient-safe views.
- `aonw_local_runtime` owns local session lifecycle, revisions, save, replay,
  snapshots, and patches.
- Flutter and Godot adapters marshal one client protocol. They do not implement
  gameplay rules.
- Serverpod owns authentication, durable transport, transactionality, offsets,
  and reconnect; it calls the stateless engine host for every authoritative
  transition.

Pure engine crates do not read the filesystem, network, wall clock, system
randomness, or presentation state. A command receives every authoritative input
explicitly. Rejections leave canonical state unchanged.

## AI planning effort

`AiRuntimeProfile` is an explicit input to each Rust AI turn. Client API 23
requires `runtimeProfile` (`standard` or `batterySaver`) on `advanceAiTurn`;
unknown, absent, or malformed values fail before actor handoff or execution. `Standard` keeps
its difficulty's reviewed tactical budget. `BatterySaver` halves MCTS iterations,
retained nodes, and depth, retaining at least one iteration, two nodes, and one
level. Easy play continues without tactical search. Difficulty weights, persona,
seed, legal commands, and the complete-turn command budget retain their values.
Each selected command still passes through the authoritative runtime. Save and
replay preserve those commands and their outcomes; the runtime profile is not
canonical match state. Tests check actual search work, deterministic decisions,
profile changes between requests, and complete games across save and replay.

## City planning markings

Client API 24 adds the revision-bound `cityPlanning` query to the shared local
and server protocol. It returns sorted potential city centers and growth tiles
on discovered terrain. City centers use the same terrain predicate as founding
and the configured minimum center distance. Territory growth itself permits all
terrain. Only owned cities and foreign cities whose centers are known affect
these optional markings; an undiscovered foreign city cannot remove a candidate
on a neighboring discovered tile. The result does not authorize a command:
founding and expansion still validate the complete canonical state. Local query
caching includes the recipient, expected revision, and authoritative identities.

## Read-only replay queries

The local client boundary permits recipient-safe queries while replay playback
is open. Queries use the runtime at the selected entry boundary and retain its
recipient, revision, digest and existing query cache rules. They do not advance
the archive or mutate canonical state. Gameplay commands, actor handoff, AI
advancement and save export remain blocked during playback. This allows the
shared map/HUD to refresh city planning and other read-only details after seeks.
The Client API version and canonical behavior fingerprint are unchanged.

## Quality gates

Run the focused checks from the repository root:

```sh
make rust-check
make engine-architecture-check
make engine-performance-check
make engine-runtime-performance-check
make engine-client-test
make godot-check
```

`make engine-quality-check` combines the Rust compiler/test gate, engine
architecture policy, the shared Dart client contract, and the portable engine
performance budget. `make ci` adds both clients, generated-code drift checks,
and the Serverpod host.

Architecture rules are stored in `engine/quality/architecture_policy.json`.
They cap file size, function size, nesting, dependency direction, unsafe code,
and crate responsibility. Negative fixtures prove each rule fails closed.

Portable performance evidence is stored in
`engine/quality/performance_baseline.json`. It measures deterministic work,
allocations, payload sizes, and soak signatures without treating shared-runner
wall time as stable evidence. The pinned-device runtime gate is defined by
`engine/quality/runtime_performance_policy.json`; it measures complete accepted
operations and dispatch paths on the reviewed MacBookPro18,2 host.

## Determinism and persistence

Canonical fixtures contain complete typed inputs and expected state, events,
evidence, and rejections. The implementation never generates and approves its
own expected result inside CI. Save and replay documents are bounded, strictly
decoded, content-bound, and verified before replacing a live session.

A format or protocol version exists only when independently deployed consumers
or durable supported data require it. Supporting a second durable format
requires an explicit reader and review; speculative aliases, fallback readers,
and parallel state models are not allowed.

See [engine persistence](engine-persistence.md),
[performance benchmarks](performance-benchmarks.md), and
[ADR 0008](adr/0008-engine-ownership.md) for the durable boundaries.
