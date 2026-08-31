# Canonical state rejection fixtures

These files are strict current `GameStateDto` payloads that must deserialize as
the current wire shape and then fail domain validation. They contain no older
state representation or compatibility metadata.

`unit-out-of-bounds.json` records the reviewed disposition of the former
invalid-origin command case. A canonical `GameState` cannot contain a unit
outside its own bounds, so `unit_out_of_bounds` is now an ingestion invariant,
not a reachable command rejection. Keeping it as a command fixture would
weaken the aggregate solely to reproduce an impossible historical state.
