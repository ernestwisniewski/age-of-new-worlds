# Authoritative route presentation

`TerrainMovementPlan::step_turns` provides a calendar turn for each planned
coordinate, including origin turn one. Entering a tile with a positive remainder
consumes that remainder even when its entry cost is larger. A fully spent current
turn therefore puts the first travel step in turn two. Each later exhausted
remainder starts another turn with the unit's engine-defined maximum movement.
The total estimate and per-step iterator share one implementation; it does not
allocate an additional step collection or modify the canonical saved path.

Client API 26 requires `stepTurns` in each route-plan response. The local
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

Stored and merchant paths still need recipient-safe timing, and all routes
need movement-domain road classification. This document does not mark route
parity complete.
