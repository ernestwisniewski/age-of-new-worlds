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
tests. The transport-stage Flutter suite passes 1,424 tests, analysis, architecture,
map contracts and boundary checks. Performance acceptance is recorded separately
in `city-production-performance.md`.


## Active production presentation

The city panel now shows the authoritative investment, total cost, production
rate and estimated completion time. Continuous projects show their gold or
science output; a completed unit without a spawn position explains why it waits.
The rush button displays the quoted increment and price, including unaffordable
quotes, and sends the existing city intent once. Read-only, loading, pending and
rejected states disable that action. The player's current treasury and stored
production overflow remain visible.

All six localizations cover the new copy. Twenty focused interaction/layout
tests cover exact quoted values, keyboard activation, pending/read-only states,
continuous output, blocked units and every language at 200% text scaling in phone
portrait and landscape. Four reviewed goldens cover phone, tablet, desktop and
large text. The complete Flutter suite passes 1,447 tests, with map contracts,
analyzer, generated-code and architecture checks. The architecture baseline's
existing production build method shrinks from 78 to 70 lines; no limit increases.

This completes the active banner. The full production modal, catalog grouping,
building/unit/wonder details and city/worker panels remain separate work.

## Catalog availability

`ProductionAvailability` separates the owner's research capability, unlocking
technology and completion in the queried city from the first command rejection.
A built granary, a locked workshop and an inland port can share the same generic
rejection while belonging to different catalog groups. Local wonder completion
never identifies another owner's city or queue. Units and continuous projects
are never classified as completed buildings.

Twenty-eight production acceptance tests pass, including research-versus-command
agreement and independent completion/research flags. The catalog assembly is
split into target-specific helpers, with no additional architecture or Clippy
exceptions. Canonical state, save/replay and production command behavior remain
unchanged. The transport and presentation follow this engine stage.
