# City production

Reference: `flame_4x` at `c6473641e57eb4337218234669c361db01c45d6e`,
`city_production_panel_view.dart` and `city_active_production_banner.dart`.

The production panel needs authoritative progress, target-specific output,
completion estimates, continuous-project yield, availability and rush pricing.
Flutter displays these values and sends the existing revision-bound commands.

## Rush quote

`ProductionOptions::rush_quote` exposes the next bounded production increment,
its exact gold cost and the first production-specific blocker. The command and
query share the calculation, including target cost, production bonuses and the
remaining amount. Insufficient gold keeps the price available for display.
Empty, continuous and completed queues return zero amounts with their existing
command rejection. Ownership and expected revision are checked before the query.

The quote changes neither commands nor canonical save/replay state. Transport
and presentation are a subsequent stage. Twenty production tests, Clippy for all
engine targets and the architecture gate pass. Coverage compares quoted prices
and increments with accepted building, unit and wonder commands, final-point
rounding, insufficient funds and queues that cannot be rushed.

## Production forecasts

Every target now includes the investment retained by its start command, its
current production rate, nullable remaining turns, continuous-project output and
the completed active unit's spawn-blocked status. Remaining turns are a
current-rate estimate: subsequent growth, work assignments, technology, world
wonder races and occupancy can change the result. Zero means the finite target
already has enough production; a blocked completed unit has no finite estimate.

Forecasts share the command's overflow cap, specialization and technology rules,
the turn processor's project conversion and the spawn selector. The city's base
output and unit technology rate are prepared once for the entire catalog. The
rush quote reuses that prepared rate. No simulation or mutation occurs during
inspection, and spawn diagnostics expose neither positions nor other units.

Twenty-five production acceptance tests and seven focused unit tests pass,
including retained versus capped investment, technology and specialization
bonuses, project output, blocked completion, foreign ownership, stale revisions
and overflow-safe ceiling arithmetic. All-target Clippy and architecture checks
pass without increasing limits. Client API transport and visual acceptance are
still pending at this stage.

## Client API 30

Production queries now require a `rushQuote` and a `forecast` on every target.
The nullable estimate, project yield and rush rejection must be present on the
wire, including explicit null values. A shared production encoder serves local
and authenticated server queries. Dart copies the engine values into immutable
read models and rejects missing, extra, mistyped or inconsistent metadata.
Prices and completion estimates are never reconstructed in Flutter.

The two checked-in production response fixtures are identical and verified by
Rust and Dart. Native coverage checks the quoted final increment against actual
gold spending, unchanged state after inspection and identical forecasts after
save/resume. The existing production replay checks and local/server query
equality pass. Canonical persistence and engine behavior identity stay unchanged.

Focused acceptance: 20 client-contract tests, three production runtime tests,
three server-query tests, 104 Dart protocol tests and six Flutter production
tests. The full Flutter suite passes 1,424 tests; its remaining quality gates and
the performance review are tracked separately while the panel is completed.
