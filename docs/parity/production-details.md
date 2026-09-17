# Production detail and ranking rules

Reference revision: `flame_4x` `c6473641e57eb4337218234669c361db01c45d6e`.
Relevant reference files are `city_building_details_content.dart`,
`city_building_sorting.dart`, `city_production_dialog_view_model_helpers.dart`,
`unit_details_panel.dart` and `wonder_details_content.dart`.

The engine exposes `GameEngine::production_details` and
`GameEngine::production_building_ranks` as revision-bound, read-only queries of a
controlled city. This stage supplies the Rust core. Client API transport,
revision/recipient guards in the adapters and the complete presentation follow
separately. Canonical state, command behavior and save/replay identity do not
change.

## Target details

Every detail uses the same target-specific catalog helper for cost, forecast and
availability. Unresearched, completed and site-blocked content can be inspected.
Technology status is separate from individual location requirements. Requirement
flags call the command's own predicate; they never infer a cause from the first
generic rejection. The result contains no foreign city, construction progress,
spawn position or hidden unit.

Building content includes flat and river yields, the river application cap and
current application count, nominal science, territory capacity and the
food-deposit multiplier. The city impact compares current passive output with
output from an immutable copy of the city containing the completed building.
An already completed building produces equal before/after values.

Both outputs use the settlement's economy calculation and research calculation.
They distinguish gross yields from deposited food, modified production and gold,
and passive science after diminishing returns and the city cap. Artifact and
owned wonder effects remain included. Population, worked tiles, owner technology,
stability and the rest of the world are held constant. Queue-specific production
bonuses and continuous-project conversion are described by the target forecast;
they are not added to the passive city output. This corrects the reference's
simple baseline-plus-flat-effect illustration without moving domain arithmetic
into Flutter.

Unit details distinguish base content statistics from persistent owner-technology
statistics for a fresh unit. The latter reuse combat's modifier enumeration and
application order, excluding terrain, opponent, garrison, army and veterancy.
Movement is the standard full allowance without an artifact. Upkeep is the base
amount before empire free-unit allocation. Supply capacity and usage reuse the
production command's budget; usage excludes the queue being replaced in this
city. Presence-resource and coast flags retain the current command semantics.
Strategic alternatives and affordability retain canonical order.

Wonder details contain public content effects and the current owned city's site
requirements. They expose host and empire yields, science, basis-point bonuses,
stability, completion research, production burst and gold grants. They never
identify the city or progress of another player's wonder. Continuous projects
need no additional effect object beyond their existing output forecast.

## Building ranking

The eight reference modes are recommended, fastest impact, best return, growth,
industry, science, defense/military and economy. Rankings remain distinct from
legality: all 59 buildings receive scores in canonical content order, and Flutter
may group them by research/completion using existing metadata.

The strategic weighting is food 120, production 120, science 115, gold 90,
defense 75, territory capacity 60 and food-deposit bonus percent 4. Best return
is strategic score times 100 divided by completion turns. Recommended adds twice
best return, strategic score and integer speed (1000 divided by turns).
The five specialized modes preserve the reference's integer weights.

Flat and currently applicable river contributions use the same helper as city
settlement. Nominal science and territory/deposit effects come from ruleset
content. These priorities are the reference policy, not a promise of net future
yield after growth, caps, stability changes or other player actions.

A positive authoritative ETA takes precedence. Otherwise the reference falls
back to remaining cost, or full cost for a completed target, at the current
production rate; zero output uses its `1 << 30` sentinel. Checked arithmetic and
quotient/remainder ceiling avoid integer overflow. Higher priorities sort first,
then fewer turns, then localized display names only when the authoritative keys
are equal. No score or completion-time calculation belongs in Flutter.

## Core verification

The focused suite passes 36 production, 13 combat, 13 economy and 10 research
acceptance tests, plus two score/rounding/overflow unit tests. It verifies every
catalog target, read-only inspection, stale/foreign rejection, local requirements,
completed-city economy/research/production equality, river effects, technology
territory capacity, science diminishing returns and repeatable ranking.
All-target Clippy, unchanged architecture budgets and workspace doctests pass.
The documentation build and release adapter smoke build are being completed
before the Client API is extended.
