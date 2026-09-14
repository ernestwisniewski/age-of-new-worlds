# Authoritative route presentation

`TerrainMovementPlan::step_turns` provides a calendar turn for each planned
coordinate, including origin turn one. Entering a tile with a positive remainder
consumes that remainder even when its entry cost is larger. A fully spent current
turn therefore puts the first travel step in turn two. Each later exhausted
remainder starts another turn with the unit's engine-defined maximum movement.
The total estimate and per-step iterator share one implementation; it does not
allocate an additional step collection or modify the canonical saved path.

Client API 27 requires `stepTurns` and `roadStepIndices` in each route-plan response. The local
runtime and server query encoder transport the engine iterator unchanged.
Flutter validates one turn per coordinate, origin turn one, consecutive
nondecreasing turns and agreement with the total estimate. It retains an
immutable copy without reconstructing movement allowances or terrain rules.
Shared Rust/Dart fixtures and native tests cover rough entry, an exhausted
current turn, future turns, malformed responses and local/server parity.

The renderer highlights steps assigned to turn one, including an entry that
exhausts a smaller positive movement balance. It draws a marker at every
interior turn boundary, also between future turns when the current turn is
spent. Timing participates in geometry identity; an equal refresh keeps cached
paths and animation phase. Boundary markers remain visible with motion disabled.
The route-timing golden and a regression that failed before this change cover
these rules.

`stored_route_step_turns` supplies the engine foundation for stored queue and
merchant itineraries. Already traversed steps are zero, the unit's current
position is turn one, and the remaining itinerary uses the same iterator as a
fresh query. It skips the entry cost of the current position and uses the unit's
movement allowance, including the carried-artifact limit. An itinerary that no
longer contains the unit returns no timing. This calculation allocates no new
step collection and changes neither the persisted route nor canonical state.
It describes stored costs; it does not predict future replanning.

Stored queue and merchant itineraries now carry this metadata in owner-only
projection DTOs, separately from persistence DTOs. A route missing the unit's
current position is omitted. Native save/resume tests verify stable metadata;
projection tests verify that visible foreign units disclose no private orders.
The renderer dims the traversed prefix and draws all remaining turn boundaries.
Both timing and road metadata participate in cache identity.

Rust classifies road destination indices for land units only. Fresh plans expose
the operational road cost selected by the movement engine. Stored itineraries
use the current recipient-known network: operational road–road and road–city
edges, excluding city–city edges, pillaged roads and hidden foreign nodes.
Air and naval units never acquire road styling. The client validates sorted,
unique, in-range indices and copies them without inferring movement rules.

The engine performance review covers all 210 existing workloads. Client API 26
changes 22 client JSON response signatures; all non-JSON signatures, sample
floors and allocation, byte, payload and work ceilings remain unchanged. The
native route probe exercises 39 segments and 38 turn boundaries while checking
cached geometry, six walking frames and a stopped animation after disable.

The September 19 macOS profile capture is recorded in
`clients/aonw_flutter/performance/flame_route_baseline.json`: build/raster p99
0.927/3.438 ms, no missed frame budgets, RSS growth 138,084,352 bytes, no geometry
rebuilds and no updates after disabling animation. These pass the existing
16.667 ms and 192 MiB limits. The subsequent city-production scenario failed
its frame-time limit (build/raster p99 62.769/101.014 ms); this capture establishes
route performance only, not a pass for the entire native performance suite.
