# City presentation field map

Reference revision: `flame_4x` `c6473641e57eb4337218234669c361db01c45d6e`.
Sources are `city_selection_view_model_factory.dart`,
`city_cohesion_selection_item.dart`, `city_objective_selection_items_factory.dart`
and `city_yield_breakdown_view_model.dart` with its rows/text parts.

| Field or action | Recipient-safe source | Current state / remaining work |
| --- | --- | --- |
| Name, owner identity/color, location, disclosed HP | City and participant projection | City panel exists; replace raw owner ID with disclosed participant identity |
| Own population, food storage, specialization, completed buildings/wonders, queue | Own city details | Transport exists; reference summary and completed-item inspection remain |
| City illustration and player accent | Existing city art catalog, own population and disclosed technology visuals | Map sprites exist; illustrated selection summary remains |
| Territory count and effective capacity | Own territory plus Rust `city::territory_capacity` | Panel currently shows stored base capacity; technology-adjusted capacity must come from Rust |
| Founding center, required count, available and recommended fields | `CityFoundingOptions` | Commands and animated map selection connected |
| Manual/automatic/idle worked fields, allowed selection limit | `CityWorkedHexOptions` | Commands and map overlay connected |
| Expansion candidate order, score, distance, tile yields and preferred choice | `CityExpansionOptions` | Commands and map overlay connected |
| Tile contributions: center, population, worker, passive improvement, artifact | `CityYieldQuery` | Exact contribution transport exists; current panel only displays the tile total |
| Building, river, specialization, technology and wonder contributions | Shared Rust city settlement calculation | Missing aggregate city inspection contract and breakdown UI |
| Gross food, population upkeep, net food and actual food deposit | Rust city settlement calculation | Missing contract; tile food must not be labelled deposited food |
| Growth threshold and ETA/stagnation | Paced Rust growth cost, current storage and actual deposit | Missing contract and presentation; no Dart growth formula |
| Gold and production modifiers, stability and rounding adjustments | Rust settlement, in its actual operation order | Missing exact breakdown contract; rows must reconcile with returned totals |
| City science: base, diminished building yield, specialization, technology, cap, artifacts, wonders, active project | Shared Rust research settlement and production forecast | Missing complete per-city breakdown; production inspection already exposes passive before/after totals |
| Core city, distance, connected territory and cohesion charge | Shared Rust stability settlement | Only empire-wide cohesion is projected; add own-city detail without deriving it in Flutter |
| Stored artifact title, illustration and authored bonus description | Recipient-filtered artifact projection plus existing catalog | Transport exists; city summary remains |
| Objectives on owned city territory, hold/contested/completed state and public rewards | Own territory, authored objectives and recipient objective progress | Objective panel already has safe live progress; city summary must reuse it |
| Production catalog, target inspection, sorting, rush and specialization actions | Production queries/commands | Connected; see `production-field-map.md` |
| Field selection, expansion and founding confirmation/cancellation | Revision-bound city commands and workflow | Connected; preserve panel/inner-overlay input ownership |

## Required authoritative breakdown

`CityYieldQuery` describes tile contributions, not final city settlement. Keep that
meaning intact. A separate own-city inspection can return source rows, adjustments,
final totals, growth and cohesion under the existing full recipient/state stamp.
It must share the arithmetic used by `economy/turn/city_output.rs`, research and
stability settlement, rather than reconstructing these values in a widget.

Gold applies technology and wonder additions before stability. Production applies
stability before the wonder bonus. Population food is subtracted and clamped before
sequential building deposit multipliers and the stability food bonus; a growth halt
sets deposited food to zero. Preserve each integer rounding boundary. Science
buildings use descending amounts and per-building rounded diminishing multipliers;
the base/technology/specialization/building subtotal is capped before artifact and
wonder contributions. Active project science is a separate production output.

The core city is selected by Rust's existing founding-owner rule and fallback,
not the first visible city or a client-side coordinate calculation. Opponent city
inspection must not expose private food, production, science or cohesion, even
when its center is visible. Changing actor, revision, digest, map or ruleset must
invalidate previously loaded details and reject late responses.

This audit identifies remaining work; it does not mark the city panel complete.
Validation must include reconciliation with actual turn settlement, research caps,
river/technology capacity, disconnected or captured cities, foreign recipients,
local/server equality and save/replay, followed by the three screen sizes and six
locales at 200% text.
