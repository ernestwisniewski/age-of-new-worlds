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
