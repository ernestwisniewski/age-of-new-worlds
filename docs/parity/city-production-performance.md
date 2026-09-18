# City production query performance

Client API 30 adds authoritative forecasts and a rush quote. Two independent
reports have identical structural results across 222 workloads. The existing
210 workload ceilings retain every numeric limit and minimum sample count;
22 JSON result signatures change with the API envelope version. The remaining
188 signatures are unchanged. Timing samples are diagnostic only.

Twelve new workloads inspect the production JSON response on a 40×30 map with
one city and 1, 64 or 512 units. Each size covers an idle queue, a partially built
building, a completed unit and a continuous research project. The completed unit
can spawn at the smaller sizes and is blocked at 512 units. Each response covers
59 buildings and 17 units, with wonders, projects, specializations and pricing.
Catalog and spawn assertions run outside the measured section, as does setup.
Each workload uses three warmups and twenty measured iterations.

Idle, building and project queries use 55 allocations, 34 reallocations and
62,181 allocated bytes. Completed-unit queries use 56 allocations, 36
reallocations and 62,245 bytes: the shared spawn selector builds its bounded
center-and-neighbors candidate vector. Serialized payloads range from 22,093 to
22,297 bytes. New ceilings match the repeated measurements exactly; existing
ceilings have not been relaxed.

Both reports pass the updated baseline. Negative policy tests continue to reject
signature, allocation, payload, work-counter, sample-count, workload-census and
schema regressions. This CPU/allocation acceptance does not replace the pending
native renderer and resident-memory gate, which requires an unlocked Mac and an
active application window.


## API 31 availability review

Two subsequent reports again agree in all 222 structural results. Required
research and local completion metadata add exactly 9,074 serialized bytes to each
of the twelve production responses. Their payload ceilings increase by that
reviewed amount, to 31,167–31,371 bytes. The response still contains the same 89
targets: 59 buildings, 17 units, two projects and eleven wonders. This is the
bounded typed metadata used for catalog grouping, not hidden player state.

All allocation, reallocation, allocated-byte and work limits remain unchanged,
as do iteration counts and the other 210 payload limits. Thirty-four JSON
signatures change (22 existing envelope cases plus twelve production cases);
the remaining 188 stay identical. Both reports pass the revised baseline.


## API 32 details and ranking review

The corpus now contains 246 workloads. Twenty-four additions cover a new building,
an already completed building, a unit, a wonder, a continuous project and all 59
building ranks at 1, 64 and 512 units. Building inspection and ranking each include
a warm-cache case. Setup, cloning the prepared session, target/count assertions
and cache priming remain outside the measured section. Three warmups precede
twenty measured iterations.

Initial measurements exposed a 704-byte increase in every cold query cache:
inline production details enlarged `RuntimeQueryResult` from 288 to 464 bytes,
multiplied by the initial four-entry capacity. Indirect storage of the new detail
variant restores 288-byte entries. The 360-byte allocation is paid only for actual
production detail values and their clones; unrelated queries retain their cost.

Two final reports agree in all 246 structural results. Every existing numeric
ceiling and sample count remains unchanged. Exactly 34 existing JSON signatures
change with the API 32 envelope; the other 188 remain identical. New ceilings are
the exact repeated measurements, summarized below using the existing allocation counting policy.

| Query | Allocations | Reallocations | Allocated bytes | JSON bytes |
| --- | ---: | ---: | ---: | ---: |
| New building | 33 | 16 | 7,932 | 1,317 |
| Completed building | 26 | 15 | 7,655 | 1,323 |
| Unit | 27 | 15 | 7,992 | 1,146–1,171 |
| Wonder | 23 | 14 | 7,424 | 1,062 |
| Project | 23 | 13 | 6,400 | 726 |
| Building ranks | 22 | 22 | 33,696 | 9,576 |
| Cached building | 16 | 13 | 5,084 | 1,317 |
| Cached ranks | 15 | 16 | 27,108 | 9,576 |

Both `/tmp/aonw-production32-boxed-performance{1,2}.json` reports pass the production
validator. Architecture and performance negative controls pass. Full workspace
Clippy passes after the storage change, as do five production/save/replay cases,
the bounded query-cache case and both server/local production privacy/parity cases.
The complete engine gate had already passed on the API 32 implementation before
this storage-only adjustment (`/tmp/aonw-production32-engine-final.log`, exit 0).
Native renderer frame and resident-memory gates remain pending window access.

The final native Flutter city FFI case also passes after the storage change,
including selected production effects, all ranks, recipient secrecy and replay.
