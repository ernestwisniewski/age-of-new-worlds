# Strategic inventory performance review — 2026-09-19

Client API 29 adds a required seven-resource inventory and recipient-owned
reservations, deposits and trade attention metadata. Two complete reports have
identical stable results across all 210 workloads. Only the 22 client JSON
signatures change; the remaining 188 signatures and all search-work counters,
minimum sample counts and payload ceilings remain unchanged.

## Allocation attribution

Comparison with the measured API 28 fixed-storage report (rather than its
ceilings, which retain earlier headroom) gives these exact changes:

- Opening or rebuilding one recipient projection adds one 616-byte boxed
  inventory and an eight-byte pointer in the shared economy: 624 bytes total.
  Empty deposit, allocation and agreement slices allocate nothing.
- MCTS uses eight iterations at depth two, executing sixteen public runtime
  commands. Each accepted simulated command rebuilds its projection in
  `command_dispatch::dispatch_player`. Accordingly, planning adds sixteen
  allocations and 9,984 bytes; planning plus final execution adds seventeen
  allocations and 10,608 bytes. Search signatures and work are unchanged.
- The required boxed DTO field grows the shared client response enum by eight
  bytes. Query-only JSON cases add eight allocated bytes and no allocations;
  command wrappers add sixteen bytes across their response buffers. Runtime
  JSON open adds eight bytes on top of its 624-byte projection change.
- Turn finalization constructs and clones three inventories; replay verification
  performs two such cycles. Small fixtures cross an existing JSON serialization
  buffer boundary: the small-fixture delta is 4,096 bytes above the larger
  fixture in each cycle. This attribution follows the buffer-growth pattern;
  the measured totals are authoritative. The observed finalization deltas are 5,976/1,880 bytes and replay deltas
  11,960/3,768 bytes. Existing reallocation ceilings already cover them.

The new fixed array avoids per-resource allocations. Tile traversal uses validated
territory membership and direct infrastructure lookup; it creates no temporary
set per tile. Timings remain diagnostic. This review does not accept the open
native renderer memory/frame-time gates or replace populated-panel profiling.

## Exact ceiling changes

Only the 67 exceeded allocation/byte counters below are raised, exactly to the
repeated measurement, without extra margin. All other numeric ceilings remain
unchanged. Both reports are checked by the production validator; the negative
policy tests are also required.

| Workload | Counter | API 28 ceiling | API 29 ceiling |
| --- | --- | ---: | ---: |
| `ai/baseline_plan_execute/1200/1` | `maxAllocations` | 266 | 267 |
| `ai/baseline_plan_execute/1200/1` | `maxAllocatedBytes` | 878949 | 879061 |
| `ai/baseline_plan_execute/1200/512` | `maxAllocations` | 11488 | 11489 |
| `ai/baseline_plan_execute/1200/64` | `maxAllocations` | 3373 | 3374 |
| `ai/mcts_plan/1200/1` | `maxAllocations` | 3444 | 3460 |
| `ai/mcts_plan/1200/1` | `maxAllocatedBytes` | 13867589 | 13867845 |
| `ai/mcts_plan/1200/512` | `maxAllocations` | 132518 | 132534 |
| `ai/mcts_plan/1200/64` | `maxAllocations` | 36044 | 36060 |
| `ai/mcts_plan_execute/1200/1` | `maxAllocations` | 3668 | 3685 |
| `ai/mcts_plan_execute/1200/1` | `maxAllocatedBytes` | 14740881 | 14741249 |
| `ai/mcts_plan_execute/1200/512` | `maxAllocations` | 137341 | 137358 |
| `ai/mcts_plan_execute/1200/64` | `maxAllocations` | 36835 | 36852 |
| `ai/random_plan_execute/1200/1` | `maxAllocations` | 269 | 270 |
| `ai/random_plan_execute/1200/1` | `maxAllocatedBytes` | 892202 | 892314 |
| `ai/random_plan_execute/1200/512` | `maxAllocations` | 11492 | 11493 |
| `ai/random_plan_execute/1200/64` | `maxAllocations` | 3377 | 3378 |
| `ai/strategic_plan_execute/1200/1` | `maxAllocations` | 481 | 482 |
| `ai/strategic_plan_execute/1200/1` | `maxAllocatedBytes` | 888814 | 888926 |
| `ai/strategic_plan_execute/1200/512` | `maxAllocations` | 13236 | 13237 |
| `ai/strategic_plan_execute/1200/64` | `maxAllocations` | 3777 | 3778 |
| `runtime/client_json_combat_attack/1200/512` | `maxAllocations` | 6513 | 6514 |
| `runtime/client_json_combat_attack/1200/64` | `maxAllocations` | 1137 | 1138 |
| `runtime/client_json_combat_preview/1200/512` | `maxAllocatedBytes` | 5826 | 5834 |
| `runtime/client_json_combat_preview/1200/64` | `maxAllocatedBytes` | 5826 | 5834 |
| `runtime/client_json_dispatch_accepted/1200/1` | `maxAllocations` | 246 | 247 |
| `runtime/client_json_dispatch_accepted/1200/1` | `maxAllocatedBytes` | 876527 | 876879 |
| `runtime/client_json_dispatch_accepted/1200/512` | `maxAllocations` | 4845 | 4846 |
| `runtime/client_json_dispatch_accepted/1200/64` | `maxAllocations` | 813 | 814 |
| `runtime/client_json_open/1200/1` | `maxAllocations` | 24230 | 24231 |
| `runtime/client_json_open/1200/1` | `maxAllocatedBytes` | 1215943 | 1216319 |
| `runtime/client_json_open/1200/512` | `maxAllocations` | 32406 | 32407 |
| `runtime/client_json_open/1200/64` | `maxAllocations` | 25238 | 25239 |
| `runtime/client_json_reachable/1200/1` | `maxAllocatedBytes` | 16200 | 16208 |
| `runtime/client_json_reachable/1200/512` | `maxAllocatedBytes` | 11640 | 11648 |
| `runtime/client_json_reachable/1200/64` | `maxAllocatedBytes` | 11640 | 11648 |
| `runtime/client_json_turn_submit_partial/1200/1` | `maxAllocations` | 247 | 248 |
| `runtime/client_json_turn_submit_partial/1200/1` | `maxAllocatedBytes` | 27822 | 28270 |
| `runtime/client_json_turn_submit_partial/1200/512` | `maxAllocations` | 5868 | 5869 |
| `runtime/client_json_turn_submit_partial/1200/64` | `maxAllocations` | 940 | 941 |
| `runtime/client_json_unit_logistics_options/1200/1` | `maxAllocatedBytes` | 4512 | 4520 |
| `runtime/client_json_unit_logistics_options/1200/512` | `maxAllocatedBytes` | 4512 | 4520 |
| `runtime/client_json_unit_logistics_options/1200/64` | `maxAllocatedBytes` | 4512 | 4520 |
| `runtime/client_json_worker_options/1200/1` | `maxAllocatedBytes` | 4520 | 4528 |
| `runtime/client_json_worker_options/1200/512` | `maxAllocatedBytes` | 4520 | 4528 |
| `runtime/client_json_worker_options/1200/64` | `maxAllocatedBytes` | 4520 | 4528 |
| `runtime/runtime_combat_attack/1200/512` | `maxAllocations` | 6467 | 6468 |
| `runtime/runtime_combat_attack/1200/64` | `maxAllocations` | 1091 | 1092 |
| `runtime/runtime_dispatch_accepted/1200/1` | `maxAllocations` | 224 | 225 |
| `runtime/runtime_dispatch_accepted/1200/1` | `maxAllocatedBytes` | 869526 | 869638 |
| `runtime/runtime_dispatch_accepted/1200/512` | `maxAllocations` | 4823 | 4824 |
| `runtime/runtime_dispatch_accepted/1200/64` | `maxAllocations` | 791 | 792 |
| `runtime/runtime_dispatch_hidden_noop/1200/2` | `maxAllocations` | 223 | 224 |
| `runtime/runtime_dispatch_hidden_noop/1200/2` | `maxAllocatedBytes` | 867143 | 867447 |
| `runtime/runtime_open/1200/1` | `maxAllocations` | 173 | 174 |
| `runtime/runtime_open/1200/1` | `maxAllocatedBytes` | 105946 | 106250 |
| `runtime/runtime_open/1200/512` | `maxAllocations` | 3239 | 3240 |
| `runtime/runtime_open/1200/64` | `maxAllocations` | 551 | 552 |
| `runtime/runtime_turn_kick_participant/1200/1` | `maxAllocations` | 250 | 251 |
| `runtime/runtime_turn_kick_participant/1200/1` | `maxAllocatedBytes` | 23798 | 24110 |
| `runtime/runtime_turn_kick_participant/1200/512` | `maxAllocations` | 5871 | 5872 |
| `runtime/runtime_turn_kick_participant/1200/64` | `maxAllocations` | 943 | 944 |
| `runtime/runtime_turn_submit_partial/1200/1` | `maxAllocations` | 234 | 235 |
| `runtime/runtime_turn_submit_partial/1200/1` | `maxAllocatedBytes` | 22083 | 22387 |
| `runtime/runtime_turn_submit_partial/1200/512` | `maxAllocations` | 5855 | 5856 |
| `runtime/runtime_turn_submit_partial/1200/64` | `maxAllocations` | 927 | 928 |
| `runtime/runtime_turn_timeout_finalization/1200/1` | `maxAllocatedBytes` | 70257 | 75887 |
| `runtime/turn_replay_verify/1200/1` | `maxAllocatedBytes` | 311668 | 322642 |
