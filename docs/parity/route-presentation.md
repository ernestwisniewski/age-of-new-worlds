# Authoritative route presentation

`TerrainMovementPlan::step_turns` provides a calendar turn for each planned
coordinate, including origin turn one. Entering a tile with a positive remainder
consumes that remainder even when its entry cost is larger. A fully spent current
turn therefore puts the first travel step in turn two. Each later exhausted
remainder starts another turn with the unit's engine-defined maximum movement.
The total estimate and per-step iterator share one implementation; it does not
allocate an additional step collection or modify the canonical saved path.

Core movement tests cover rough terrain, multiple future boundaries, a spent
current turn and expensive future entries. Client API transport and renderer
consumption are the next step. Existing Flutter cumulative-cost comparisons do
not yet represent exhaustion correctly; stored and merchant paths also need
recipient-safe timing and movement-domain road classification. This document
does not mark route parity complete.
