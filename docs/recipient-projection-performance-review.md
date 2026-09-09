# Recipient projection performance review — 2026-09-12

The portable baseline now covers the recipient projections and Client API 24.
This review compares commit `70742b6` with the engine at `1398b42` (subsequent
commits through `2735364` change only Flutter). It accepts the measured cost of
expanded recipient views, without changing workloads or adding percentage headroom.

## Reproduction and acceptance

- Extracted `git archive 70742b6 engine` into an isolated temporary directory and
  ran the current performance report tool against that Rust workspace. All 210
  historical rows exactly reproduced the existing baseline, including signatures,
  allocations, bytes, payloads, iteration counts, and search work.
- Ran the current workspace report twice. All 210 stable rows matched exactly
  across both runs. Timing measurements remain diagnostic only.
- Both versions use Rust/Cargo 1.97.1 and stats_alloc 0.1.10, one benchmark thread,
  three warmups, setup outside measurement, and the original sample counts.
- The AI and runtime benchmark files are unchanged. The movement benchmark only
  adds exhaustive matches for new query variants; its workloads are unchanged.
- 131 rows change; 79 remain byte-for-byte identical. No workload, sample count,
  frontier pop, expanded tile, examined edge, heap push, or route-record budget
  changes. There are 112 changed result signatures.
- The complete Rust compiler, all-target Clippy, workspace tests, architecture
  checks, Dart protocol tests (89), and native smoke tests (10) passed before this
  review. The previous combined gate stopped on the outdated performance signature.
- Each new ceiling equals the repeated observation exactly. No multiplier or
  blanket tolerance has been added. Result-signature and regression rejection
  remain mandatory; negative checker fixtures must continue to pass.

## Cost attribution

Canonical turn mode was separated from session mode in `f951907`, and durable
and client documents gained explicit recipient data. State digests therefore
change even when a benchmark chooses the same action. AI plan fingerprints hash
`SessionStamp.state_digest` (`aonw_ai/src/fingerprint.rs`); runtime signatures hash
stamps and serialized responses. The new digest/version/response content must
remain part of these signatures.

The roster, fog, economy, research, victory, forecasts, and expanded unit fields
were added between `2bb05b2` and Client API 24. Recipient projection now allocates
those owned read models during runtime opening and accepted transitions; larger
query variants and canonical fields also increase retained bytes. The immutable
snapshot benchmark adds no allocations, while opening and accepted dispatch do.
These costs are included rather than hidden by moving projection outside timing.

MCTS retains its existing benchmark budget of 8 iterations, 8 nodes, and depth 2.
It repeatedly executes candidate transitions, so projection allocations recur.
The one-unit MCTS plan adds 2240 allocations but only 143952 allocated bytes;
its 512-unit case adds 10416 allocations and 760480 bytes. This review accepts
those bounded projection costs; it does not enlarge search budgets. A future
projection optimization must preserve disclosure, patch parity, and these outputs.

Combat response payloads now include recipient combat details and participant
identities. The largest proportional payload change is 2622 → 3340 bytes for
`runtime/client_json_combat_attack/1200/512` (+718 bytes, 27.4%). Runtime opening
has the largest allocation-count ratio, 35 → 173 for one unit, but allocated bytes
increase 97184 → 105946 (+8762 bytes, 9.0%). At 512 units opening adds the same
138 allocations, while total allocated bytes rise 858022 → 891240 (3.9%).

This is a portable structural budget review. It does not certify pinned-device
frame time, all-map culling, idle behavior, or complete multiplayer E2E coverage;
those remain separate release gates.

## Re-run

From the repository root, `make engine-performance-check` runs the negative
fixtures and rebuilds the reports against the reviewed baseline. For historical
reproduction, extract the commit above and run
`tool/check_engine_performance.py report --repo-root <extracted-root>`.
The stable columns in `engine/quality/performance_baseline.json` are the accepted
current results; the same file at `70742b6` contains the prior results.

## Changed rows

Only changed fields are listed below. `signature` retains exact equality checks;
all numeric columns retain upper bounds, except unchanged minimum sample counts.
The arrow denotes old → reviewed measurement. Work counters and sample counts
are omitted because all are unchanged.

| Workload | Changes |
| --- | --- |
| `ai/baseline_plan/1200/1` | signature: `f73f5061a1332f90` → `05752cff00bad7b7`; maxAllocatedBytes: `9593` → `9753` |
| `ai/baseline_plan/1200/512` | signature: `5b4b7deb101ec348` → `c3894bbce1bfe179`; maxAllocatedBytes: `875818` → `878378` |
| `ai/baseline_plan/1200/64` | signature: `a20b7eb9d38ae823` → `4721ea1819fa8fac`; maxAllocatedBytes: `239850` → `242410` |
| `ai/baseline_plan_execute/1200/1` | signature: `53c526e4e9f9d363` → `00f32b4e3d7c8a42`; maxAllocations: `126` → `266`; maxReallocations: `40` → `42`; maxAllocatedBytes: `869826` → `878949` |
| `ai/baseline_plan_execute/1200/512` | signature: `400a3f6c6445d50b` → `022d29f3990c1ee8`; maxAllocations: `10837` → `11488`; maxReallocations: `354` → `362`; maxAllocatedBytes: `2261030` → `2309736` |
| `ai/baseline_plan_execute/1200/64` | signature: `e47077c2750871c6` → `d93073f424c222f7`; maxAllocations: `3170` → `3373`; maxReallocations: `308` → `313`; maxAllocatedBytes: `1164070` → `1180072` |
| `ai/mcts_plan/1200/1` | signature: `820635c1998966b8` → `abc79236ce687b8b`; maxAllocations: `1204` → `3444`; maxReallocations: `185` → `217`; maxAllocatedBytes: `13723637` → `13867589` |
| `ai/mcts_plan/1200/512` | signature: `f78218330cc9f76e` → `d71114d549e913e3`; maxAllocations: `122102` → `132518`; maxReallocations: `3267` → `3395`; maxAllocatedBytes: `28896412` → `29656892` |
| `ai/mcts_plan/1200/64` | signature: `58dcbff1625cb151` → `54c1163caf7ce962`; maxAllocations: `32796` → `36044`; maxReallocations: `2523` → `2603`; maxAllocatedBytes: `16615196` → `16852412` |
| `ai/mcts_plan_execute/1200/1` | signature: `79f410f7e4798c5b` → `4c98fd20bb89eb7e`; maxAllocations: `1288` → `3668`; maxReallocations: `226` → `260`; maxAllocatedBytes: `14587966` → `14740881` |
| `ai/mcts_plan_execute/1200/512` | signature: `5c068dbebb2f719d` → `5b1a486c970cc906`; maxAllocations: `126274` → `137341`; maxReallocations: `3309` → `3445`; maxAllocatedBytes: `30281624` → `31088250` |
| `ai/mcts_plan_execute/1200/64` | signature: `5bcb772a23814af0` → `81022c1e31409339`; maxAllocations: `33384` → `36835`; maxReallocations: `2562` → `2647`; maxAllocatedBytes: `17539416` → `17790074` |
| `ai/random_plan/1200/1` | signature: `28c61dfa24e624b5` → `3384cf15149e32ca`; maxAllocatedBytes: `11614` → `11774` |
| `ai/random_plan/1200/512` | signature: `83f56530f824577e` → `88195975df985894`; maxAllocatedBytes: `1092095` → `1094655` |
| `ai/random_plan/1200/64` | signature: `e1f4904c90c36b25` → `18913a345bfab9c1`; maxAllocatedBytes: `456127` → `458687` |
| `ai/random_plan_execute/1200/1` | signature: `2ec9a40cb3105ddc` → `28deabd208d04ef1`; maxAllocations: `129` → `269`; maxReallocations: `56` → `58`; maxAllocatedBytes: `883079` → `892202` |
| `ai/random_plan_execute/1200/512` | signature: `5e527135a5c0accd` → `db6b984aefde852f`; maxAllocations: `10841` → `11492`; maxReallocations: `376` → `384`; maxAllocatedBytes: `2488475` → `2537181` |
| `ai/random_plan_execute/1200/64` | signature: `b5fc5619fc0f0e2c` → `b97fa6f84b09a140`; maxAllocations: `3174` → `3377`; maxReallocations: `330` → `335`; maxAllocatedBytes: `1391515` → `1407517` |
| `ai/strategic_plan/1200/1` | signature: `a607446cf68e4a3e` → `beeeebc4f2e100e9`; maxAllocatedBytes: `18446` → `18606` |
| `ai/strategic_plan/1200/512` | signature: `4940001858fc2a00` → `2693d9229bae6624`; maxAllocatedBytes: `902532` → `905092` |
| `ai/strategic_plan/1200/64` | signature: `afb30fd66f121f45` → `ed7755c2b40fb4da`; maxAllocatedBytes: `250884` → `253444` |
| `ai/strategic_plan_execute/1200/1` | signature: `aca38426f3c8290d` → `50fb87a8b4548a38`; maxAllocations: `341` → `481`; maxReallocations: `40` → `42`; maxAllocatedBytes: `879697` → `888814` |
| `ai/strategic_plan_execute/1200/512` | signature: `73ea2a5f347b5fb3` → `3ba01ace895790df`; maxAllocations: `12585` → `13236`; maxReallocations: `361` → `369`; maxAllocatedBytes: `2288762` → `2337462` |
| `ai/strategic_plan_execute/1200/64` | signature: `9f632d5ebbcb208c` → `917b94d7f6b05021`; maxAllocations: `3574` → `3777`; maxReallocations: `312` → `317`; maxAllocatedBytes: `1176122` → `1192118` |
| `engine/city_expansion_options/100/1` | maxAllocatedBytes: `1998` → `2126` |
| `engine/city_expansion_options/100/10` | maxAllocatedBytes: `1998` → `2126` |
| `engine/city_expansion_options/1200/1` | maxAllocatedBytes: `1998` → `2126` |
| `engine/city_expansion_options/1200/512` | maxAllocatedBytes: `1998` → `2126` |
| `engine/city_expansion_options/1200/64` | maxAllocatedBytes: `1998` → `2126` |
| `engine/city_expansion_options/600/1` | maxAllocatedBytes: `1998` → `2126` |
| `engine/city_expansion_options/600/64` | maxAllocatedBytes: `1998` → `2126` |
| `engine/city_found_apply/100/1` | signature: `000059000000973b` → `00006e000000baea` |
| `engine/city_found_apply/100/10` | signature: `00000f000000197d` → `00000b00000012b1` |
| `engine/city_found_apply/1200/1` | signature: `000088000000e718` → `0000aa00000120de` |
| `engine/city_found_apply/1200/512` | signature: `0000a20000011346` → `00008b000000ec31` |
| `engine/city_found_apply/1200/64` | signature: `0000c30000014b59` → `0000c40000014d0c` |
| `engine/city_found_apply/600/1` | signature: `0000e4000001836c` → `0000c60000015072` |
| `engine/city_found_apply/600/64` | signature: `000045000000753f` → `0000ee000001946a` |
| `engine/city_founding_options/100/1` | maxAllocations: `31` → `32`; maxAllocatedBytes: `1804` → `1852` |
| `engine/city_founding_options/100/10` | maxAllocations: `31` → `32`; maxAllocatedBytes: `1804` → `1852` |
| `engine/city_founding_options/1200/1` | maxAllocations: `31` → `32`; maxAllocatedBytes: `1804` → `1852` |
| `engine/city_founding_options/1200/512` | maxAllocations: `31` → `32`; maxAllocatedBytes: `1804` → `1852` |
| `engine/city_founding_options/1200/64` | maxAllocations: `31` → `32`; maxAllocatedBytes: `1804` → `1852` |
| `engine/city_founding_options/600/1` | maxAllocations: `31` → `32`; maxAllocatedBytes: `1804` → `1852` |
| `engine/city_founding_options/600/64` | maxAllocations: `31` → `32`; maxAllocatedBytes: `1804` → `1852` |
| `engine/combat_apply/100/10` | signature: `0000f40000019e9c` → `0000520000008b56` |
| `engine/combat_apply/1200/512` | signature: `00001e00000032fa` → `00006c000000b784` |
| `engine/combat_apply/1200/64` | signature: `00008f000000f2fd` → `0000ed00000192b7` |
| `engine/combat_apply/600/64` | signature: `000063000000a839` → `0000480000007a58` |
| `engine/combat_mass_turn/100/10` | signature: `00009a00000105ae` → `0000410000006e73`; maxAllocations: `962` → `964`; maxAllocatedBytes: `48214` → `48438` |
| `engine/combat_mass_turn/1200/512` | signature: `0000e5000001851f` → `0000070000000be5`; maxAllocations: `66472` → `66474`; maxAllocatedBytes: `3034857` → `3035081` |
| `engine/combat_mass_turn/1200/64` | signature: `0000540000008ebc` → `000091000000f663`; maxAllocations: `14462` → `14464`; maxAllocatedBytes: `635929` → `636153` |
| `engine/combat_mass_turn/600/64` | signature: `0000b700000136f5` → `00006d000000b937`; maxAllocations: `14408` → `14410`; maxAllocatedBytes: `616337` → `616561` |
| `engine/logistics_auto_apply/100/1` | signature: `0000000000000062` → `000000000000004b` |
| `engine/logistics_auto_apply/100/10` | signature: `00000000000000b4` → `00000000000000b2` |
| `engine/logistics_auto_apply/1200/1` | signature: `00000000000000dc` → `0000000000000099` |
| `engine/logistics_auto_apply/1200/512` | signature: `00000000000000ff` → `00000000000000c5` |
| `engine/logistics_auto_apply/1200/64` | signature: `00000000000000a0` → `000000000000009b` |
| `engine/logistics_auto_apply/600/1` | signature: `000000000000004d` → `000000000000009a` |
| `engine/logistics_auto_apply/600/64` | signature: `000000000000005d` → `00000000000000d1` |
| `engine/logistics_merchant_long_route/100/1` | signature: `00000000000000ab` → `00000000000000d8` |
| `engine/logistics_merchant_long_route/100/10` | signature: `000000000000008c` → `000000000000009c` |
| `engine/logistics_merchant_long_route/1200/1` | signature: `00000000000000bc` → `0000000000000086` |
| `engine/logistics_merchant_long_route/1200/512` | signature: `000000000000000b` → `00000000000000d5` |
| `engine/logistics_merchant_long_route/1200/64` | signature: `0000000000000003` → `00000000000000ac` |
| `engine/logistics_merchant_long_route/600/1` | signature: `00000000000000b7` → `0000000000000072` |
| `engine/logistics_merchant_long_route/600/64` | signature: `000000000000009e` → `000000000000003f` |
| `engine/prepared_apply_rejected/100/1` | signature: `0000000000000000` → `0000000000000045` |
| `engine/prepared_apply_rejected/100/10` | signature: `0000000000000093` → `00000000000000e7` |
| `engine/prepared_apply_rejected/1200/1` | signature: `00000000000000f7` → `000000000000004c` |
| `engine/prepared_apply_rejected/1200/512` | signature: `00000000000000ee` → `00000000000000ba` |
| `engine/prepared_apply_rejected/1200/64` | signature: `000000000000006b` → `00000000000000fc` |
| `engine/prepared_apply_rejected/600/1` | signature: `0000000000000078` → `00000000000000ed` |
| `engine/prepared_apply_rejected/600/64` | signature: `00000000000000b1` → `00000000000000e0` |
| `engine/worker_automation_apply/100/99` | signature: `00000000000000f0` → `00000000000000c9` |
| `engine/worker_automation_apply/1200/1199` | signature: `000000000000009f` → `0000000000000071` |
| `engine/worker_automation_apply/600/599` | signature: `0000000000000044` → `00000000000000b6` |
| `engine/worker_turn_jobs/100/99` | signature: `00116b00000f2904` → `00117100000f3336` |
| `engine/worker_turn_jobs/1200/1199` | signature: `00624800005344b3` → `0062e000005446fb` |
| `engine/worker_turn_jobs/600/599` | signature: `002c850000261cea` → `002c260000257b7d` |
| `runtime/client_json_combat_attack/1200/512` | signature: `3e227fc01dc9cf58` → `5c1ea5b1d119358f`; maxAllocations: `5824` → `6511`; maxReallocations: `65` → `81`; maxAllocatedBytes: `744224` → `806447`; maxPayloadBytes: `2622` → `3340` |
| `runtime/client_json_combat_attack/1200/64` | signature: `47d52c3161916bd6` → `6ae155f2cb305e9a`; maxAllocations: `896` → `1135`; maxReallocations: `62` → `72`; maxAllocatedBytes: `116728` → `135085`; maxPayloadBytes: `2622` → `3339` |
| `runtime/client_json_combat_preview/1200/512` | signature: `4664b1b0b9eaeec5` → `3c32662582f2d919`; maxAllocatedBytes: `4866` → `5762`; maxPayloadBytes: `764` → `765` |
| `runtime/client_json_combat_preview/1200/64` | signature: `f2557295fd5665e3` → `eab5983959a16af4`; maxAllocatedBytes: `4866` → `5762`; maxPayloadBytes: `764` → `765` |
| `runtime/client_json_dispatch_accepted/1200/1` | signature: `454a9c9c9dd46b12` → `6be86036eec259ce`; maxAllocations: `106` → `246`; maxReallocations: `50` → `52`; maxAllocatedBytes: `866119` → `876527`; maxPayloadBytes: `1439` → `1566` |
| `runtime/client_json_dispatch_accepted/1200/512` | signature: `d08af9d189a5433d` → `a3efa7cdf397a3a2`; maxAllocations: `4194` → `4845`; maxReallocations: `55` → `63`; maxAllocatedBytes: `1388857` → `1435829`; maxPayloadBytes: `1439` → `1566` |
| `runtime/client_json_dispatch_accepted/1200/64` | signature: `985e54fc7214964b` → `e6dac08a051be834`; maxAllocations: `610` → `813`; maxReallocations: `52` → `57`; maxAllocatedBytes: `929317` → `944069`; maxPayloadBytes: `1439` → `1566` |
| `runtime/client_json_open/1200/1` | signature: `b147c3b57c9b28b1` → `7e8ecab627939e65`; maxAllocations: `24092` → `24230`; maxReallocations: `8450` → `8451`; maxAllocatedBytes: `1206445` → `1215943`; maxPayloadBytes: `345` → `346` |
| `runtime/client_json_open/1200/512` | signature: `a5d21fe2adad37fd` → `a313efa705ce39f7`; maxAllocations: `32268` → `32406`; maxReallocations: `8475` → `8476`; maxAllocatedBytes: `2304621` → `2338575`; maxPayloadBytes: `345` → `346` |
| `runtime/client_json_open/1200/64` | signature: `073c4e9e38f33ba7` → `b45ee83bdd1b0fee`; maxAllocations: `25100` → `25238`; maxReallocations: `8463` → `8464`; maxAllocatedBytes: `1336632` → `1349082`; maxPayloadBytes: `345` → `346` |
| `runtime/client_json_reachable/1200/1` | signature: `def90b9e8154facd` → `d786599bbbb6327c`; maxAllocatedBytes: `15240` → `16136`; maxPayloadBytes: `2303` → `2355` |
| `runtime/client_json_reachable/1200/512` | signature: `2f7fed63fe07fc40` → `e0dfed66d4628a35`; maxAllocatedBytes: `10680` → `11576`; maxPayloadBytes: `784` → `836` |
| `runtime/client_json_reachable/1200/64` | signature: `4a98c9ea22375a32` → `df4c65a4186576da`; maxAllocatedBytes: `10680` → `11576`; maxPayloadBytes: `784` → `836` |
| `runtime/client_json_turn_submit_partial/1200/1` | signature: `ae9d8d2bd7da1de9` → `2004c279e54ade81`; maxAllocations: `99` → `247`; maxReallocations: `43` → `46`; maxAllocatedBytes: `16323` → `27822`; maxPayloadBytes: `1096` → `1180` |
| `runtime/client_json_turn_submit_partial/1200/512` | signature: `608977832cc9d53b` → `97e68f00b0bd9c39`; maxAllocations: `5209` → `5868`; maxReallocations: `50` → `59`; maxAllocatedBytes: `701324` → `751942`; maxPayloadBytes: `1096` → `1180` |
| `runtime/client_json_turn_submit_partial/1200/64` | signature: `ab4efd64f16af001` → `a37ab64f82d6e55a`; maxAllocations: `729` → `940`; maxReallocations: `47` → `53`; maxAllocatedBytes: `99804` → `115962`; maxPayloadBytes: `1096` → `1180` |
| `runtime/client_json_unit_logistics_options/1200/1` | signature: `6e795c8961b7b8da` → `48faf5fec938c4c2`; maxAllocatedBytes: `3552` → `4448`; maxPayloadBytes: `495` → `496` |
| `runtime/client_json_unit_logistics_options/1200/512` | signature: `20ff9a8fe5816ffa` → `8d1434d023f66b5c`; maxAllocatedBytes: `3552` → `4448`; maxPayloadBytes: `495` → `496` |
| `runtime/client_json_unit_logistics_options/1200/64` | signature: `0c99456619b0c98c` → `8659b15ed7dbf8f1`; maxAllocatedBytes: `3552` → `4448`; maxPayloadBytes: `495` → `496` |
| `runtime/client_json_worker_options/1200/1` | signature: `b3d68b8768de7fce` → `7ef2020f80327c56`; maxAllocatedBytes: `3560` → `4456`; maxPayloadBytes: `496` → `497` |
| `runtime/client_json_worker_options/1200/512` | signature: `8c12a652ef97e0fa` → `692db0c710ea3ad0`; maxAllocatedBytes: `3560` → `4456`; maxPayloadBytes: `496` → `497` |
| `runtime/client_json_worker_options/1200/64` | signature: `51e02bd166be9346` → `9d4833e52a7e09e0`; maxAllocatedBytes: `3560` → `4456`; maxPayloadBytes: `496` → `497` |
| `runtime/runtime_combat_attack/1200/512` | signature: `000a710000091488` → `000a2d000008a0fc`; maxAllocations: `5788` → `6466`; maxReallocations: `50` → `66`; maxAllocatedBytes: `735994` → `796207` |
| `runtime/runtime_combat_attack/1200/64` | signature: `000a8b00000940b6` → `000a5e000008f43f`; maxAllocations: `860` → `1090`; maxReallocations: `47` → `57`; maxAllocatedBytes: `108498` → `124845` |
| `runtime/runtime_combat_preview/1200/512` | maxAllocatedBytes: `2047` → `2207` |
| `runtime/runtime_combat_preview/1200/64` | maxAllocatedBytes: `2047` → `2207` |
| `runtime/runtime_dispatch_accepted/1200/1` | signature: `00009a00000105ae` → `000060000000a320`; maxAllocations: `84` → `224`; maxReallocations: `37` → `39`; maxAllocatedBytes: `860566` → `869526` |
| `runtime/runtime_dispatch_accepted/1200/512` | signature: `0000da000001726e` → `0000c100000147f3`; maxAllocations: `4172` → `4823`; maxReallocations: `42` → `50`; maxAllocatedBytes: `1383304` → `1428828` |
| `runtime/runtime_dispatch_accepted/1200/64` | signature: `0000bb0000013dc1` → `0000d70000016d55`; maxAllocations: `588` → `791`; maxReallocations: `39` → `44`; maxAllocatedBytes: `923764` → `937068` |
| `runtime/runtime_dispatch_hidden_noop/1200/2` | signature: `00001800000028c8` → `0000a5000001185f`; maxAllocations: `75` → `223`; maxReallocations: `35` → `37`; maxAllocatedBytes: `858079` → `867143` |
| `runtime/runtime_dispatch_rejected/1200/1` | signature: `0000020000000366` → `0000d900000170bb`; maxAllocatedBytes: `7957` → `7981` |
| `runtime/runtime_dispatch_rejected/1200/512` | signature: `0000b700000136f5` → `0000970000010095`; maxAllocatedBytes: `212760` → `212784` |
| `runtime/runtime_dispatch_rejected/1200/64` | signature: `00001500000023af` → `00000d0000001617`; maxAllocatedBytes: `33148` → `33172` |
| `runtime/runtime_open/1200/1` | signature: `0000020000000366` → `0000d900000170bb`; maxAllocations: `35` → `173`; maxReallocations: `8` → `9`; maxAllocatedBytes: `97184` → `105946` |
| `runtime/runtime_open/1200/512` | signature: `0000b700000136f5` → `0000970000010095`; maxAllocations: `3101` → `3239`; maxReallocations: `21` → `22`; maxAllocatedBytes: `858022` → `891240` |
| `runtime/runtime_open/1200/64` | signature: `00001500000023af` → `00000d0000001617`; maxAllocations: `413` → `551`; maxReallocations: `15` → `16`; maxAllocatedBytes: `186990` → `198704` |
| `runtime/runtime_snapshot/1200/1` | signature: `0006cd000005c805` → `02e1750002728c0e` |
| `runtime/runtime_snapshot/1200/512` | signature: `026bea00020cfc4f` → `02032a0001b7632f` |
| `runtime/runtime_snapshot/1200/64` | signature: `00479e00003d0f1d` → `002c6e000025f5d5` |
| `runtime/runtime_turn_kick_participant/1200/1` | signature: `00000c0000001464` → `0000c200000149a6`; maxAllocations: `93` → `249`; maxReallocations: `31` → `33`; maxAllocatedBytes: `13999` → `23798` |
| `runtime/runtime_turn_kick_participant/1200/512` | signature: `00001a0000002c2e` → `00001d0000003147`; maxAllocations: `5203` → `5870`; maxReallocations: `38` → `46`; maxAllocatedBytes: `699000` → `747918` |
| `runtime/runtime_turn_kick_participant/1200/64` | signature: `0000350000005a0f` → `0000cd0000015c57`; maxAllocations: `723` → `942`; maxReallocations: `35` → `40`; maxAllocatedBytes: `97480` → `111938` |
| `runtime/runtime_turn_submit_partial/1200/1` | signature: `0000d60000016ba2` → `0000ee000001946a`; maxAllocations: `86` → `234`; maxReallocations: `30` → `33`; maxAllocatedBytes: `12000` → `22083` |
| `runtime/runtime_turn_submit_partial/1200/512` | signature: `000085000000e1ff` → `0000fd000001ade7`; maxAllocations: `5196` → `5855`; maxReallocations: `37` → `46`; maxAllocatedBytes: `697001` → `746203` |
| `runtime/runtime_turn_submit_partial/1200/64` | signature: `00009c0000010914` → `0000d30000016689`; maxAllocations: `716` → `927`; maxReallocations: `34` → `40`; maxAllocatedBytes: `95481` → `110223` |
| `runtime/runtime_turn_timeout_finalization/1200/1` | signature: `000b1800000a304d` → `000b0000000a0785`; maxAllocations: `325` → `473`; maxReallocations: `48` → `51`; maxAllocatedBytes: `59174` → `70257` |
| `runtime/runtime_turn_timeout_finalization/1200/512` | signature: `000a38000008b3ad` → `000a1e000008877f`; maxAllocations: `13148` → `13807`; maxReallocations: `77` → `85`; maxAllocatedBytes: `1064725` → `1112879` |
| `runtime/runtime_turn_timeout_finalization/1200/64` | signature: `000a7e0000092a9f` → `000aff00000a05d2`; maxAllocations: `1906` → `2117`; maxReallocations: `62` → `67`; maxAllocatedBytes: `180593` → `194287` |
| `runtime/turn_replay_verify/1200/1` | maxAllocations: `3052` → `3494`; maxReallocations: `167` → `176`; maxAllocatedBytes: `278446` → `311668`; maxPayloadBytes: `4949` → `4998` |
| `runtime/turn_replay_verify/1200/512` | maxAllocations: `26095` → `27559`; maxReallocations: `240` → `259`; maxAllocatedBytes: `2834021` → `2965841`; maxPayloadBytes: `211160` → `211209` |
| `runtime/turn_replay_verify/1200/64` | maxAllocations: `5893` → `6461`; maxReallocations: `205` → `218`; maxAllocatedBytes: `584965` → `626361`; maxPayloadBytes: `30238` → `30287` |
