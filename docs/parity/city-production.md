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
