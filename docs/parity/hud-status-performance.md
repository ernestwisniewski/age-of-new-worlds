# HUD status performance review — 2026-09-19

Client API 28 adds required treasury warnings, unlocked-unit resource shortages,
and recipient-safe compact victory status. This review follows the API 27
baseline and covers the engine through `6b49b93`.

Two complete measurements produced identical stable results for all 210 workloads
(`/tmp/aonw-hud-api28-fixed-storage-performance.json` and
`/tmp/aonw-hud-api28-fixed-storage-repeat.json`). Both pass the production validator
against this reviewed baseline. The Rust toolchain, allocator, setup boundaries,
three warmups, single benchmark thread and sample counts are unchanged. Timings
remain diagnostic. All search-work ceilings remain unchanged.

Exactly 22 client JSON signatures change with API 28 and its response fields.
The other 188 signatures are unchanged. No percentage headroom is introduced:
only the 20 exceeded counters below move to their repeated observed value.
Existing ceilings are retained everywhere else, including workloads improved by
removing temporary exact-decimal allocations and fixed shortage storage.

## Cost review

- The combat response's newly required domination status adds exactly 76 JSON
  bytes (`kind`, `critical`, and the disclosed `leaderPlayerId`). The numeric
  payload ceiling changes only in the two combat JSON workloads.
- The shared boxed client response enum grows by 64 bytes because its snapshot
  variant contains the new warning, shortage and victory fields. Eleven small
  query responses therefore allocate 64 additional bytes each, while their
  payload and allocation-count ceilings remain unchanged.
- The five combat/kick runtime workloads retain one additional measured
  allocation; the two combat JSON workloads retain two. These are explicit
  per-workload allowances for the expanded HUD projection and response; no
  other allocation-count ceiling changes. These counts include all projection
  and patch construction, not just JSON serialization.
- Exact threshold comparisons use bounded stack storage and preserve exact
  decimal semantics. Shortages use two fixed flags and static result slices;
  neither policy requires a temporary heap collection. Victory leader identity
  reuses the projection's existing sorted score keys.
- Canonical saves, replay documents, workload definitions, iteration counts and
  structural search-work limits are unchanged. This is a HUD transport baseline,
  not acceptance of the still-open native renderer memory/frame-time gates.

## Exact ceiling changes

| Workload | Counter | API 27 ceiling | API 28 observed ceiling |
| --- | --- | ---: | ---: |
| `runtime/client_json_combat_attack/1200/512` | `maxAllocations` | 6511 | 6513 |
| `runtime/client_json_combat_attack/1200/512` | `maxPayloadBytes` | 3340 | 3416 |
| `runtime/client_json_combat_attack/1200/64` | `maxAllocations` | 1135 | 1137 |
| `runtime/client_json_combat_attack/1200/64` | `maxPayloadBytes` | 3339 | 3415 |
| `runtime/client_json_combat_preview/1200/512` | `maxAllocatedBytes` | 5762 | 5826 |
| `runtime/client_json_combat_preview/1200/64` | `maxAllocatedBytes` | 5762 | 5826 |
| `runtime/client_json_reachable/1200/1` | `maxAllocatedBytes` | 16136 | 16200 |
| `runtime/client_json_reachable/1200/512` | `maxAllocatedBytes` | 11576 | 11640 |
| `runtime/client_json_reachable/1200/64` | `maxAllocatedBytes` | 11576 | 11640 |
| `runtime/client_json_unit_logistics_options/1200/1` | `maxAllocatedBytes` | 4448 | 4512 |
| `runtime/client_json_unit_logistics_options/1200/512` | `maxAllocatedBytes` | 4448 | 4512 |
| `runtime/client_json_unit_logistics_options/1200/64` | `maxAllocatedBytes` | 4448 | 4512 |
| `runtime/client_json_worker_options/1200/1` | `maxAllocatedBytes` | 4456 | 4520 |
| `runtime/client_json_worker_options/1200/512` | `maxAllocatedBytes` | 4456 | 4520 |
| `runtime/client_json_worker_options/1200/64` | `maxAllocatedBytes` | 4456 | 4520 |
| `runtime/runtime_combat_attack/1200/512` | `maxAllocations` | 6466 | 6467 |
| `runtime/runtime_combat_attack/1200/64` | `maxAllocations` | 1090 | 1091 |
| `runtime/runtime_turn_kick_participant/1200/1` | `maxAllocations` | 249 | 250 |
| `runtime/runtime_turn_kick_participant/1200/512` | `maxAllocations` | 5870 | 5871 |
| `runtime/runtime_turn_kick_participant/1200/64` | `maxAllocations` | 942 | 943 |
