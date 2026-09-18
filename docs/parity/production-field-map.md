# Production presentation field map

Reference revision: `flame_4x` `c6473641e57eb4337218234669c361db01c45d6e`.
The source files are `city_production_panel_view.dart`,
`city_production_list_sections.dart`, `city_building_details_dialog.dart`,
`city_building_details_content.dart`, `city_building_sorting.dart`,
`unit_details_panel.dart` and `wonder_details_content.dart`.

| Presentation field or action | Recipient-safe source | Status / required work |
| --- | --- | --- |
| City name, local buildings and wonders | Own city projection | Connected to modal header |
| Current treasury | Own player economy | Connected to active banner |
| Target, investment, overflow | Production query | Connected |
| Target cost and current production rate | Rust production cost / `ProductionForecast` | Connected; never use the source widget's unpaced detail cost |
| Finite ETA, continuous output, completed-unit spawn blockage | `ProductionForecast` | Connected; estimates explicitly depend on current output |
| Rush increment, gold cost, first blocker | `ProductionRushQuote` | Connected; quote and command share calculation |
| Research requirement and whether it is unlocked | `ProductionAvailability` | API 31; no inference from a generic rejection |
| Completed building/wonder in this city | `ProductionAvailability` | API 31; no other city's wonder location or construction progress |
| Unit strategic alternatives and affordability | Existing production unit option | Connected to exact reservation choice |
| Current available buildings / collapsed future / completed list | Research and completion flags | Presentation grouping; completed takes precedence over research |
| Building sort modes: recommended, speed, return, growth, industry, science, defense, economy | Rust core and API 32 transport implemented | Eight checked Rust priorities, independent groups and localized tie-breaking connected |
| Building illustration, target title, authored description | Existing art catalog and localized content | Illustrated lazy cards and all 87 authored descriptions in six languages connected; numeric effects connected below |
| Building location requirements | Ruleset `ProductionRequirement` plus shared command checks | Rust typed detail core uses command predicates; API 32 transport and selected detail presentation connected |
| Flat and river yield, science, territory capacity, food-deposit modifier | `BuildingProductionDefinition` | Rust typed detail core implemented; API 32 transport and selected detail presentation connected |
| Planned / active yield effect and city totals | Rust economy city-output rules | Rust current/completed output uses settlement and science rules; API 32 transport and selected detail presentation connected |
| Unit movement and combat statistics | Unit ruleset plus existing technology modifiers | Rust fresh-unit base/effective statistics share combat rules; API 32 transport and selected detail presentation connected |
| Unit supply and base upkeep | `UnitProductionDefinition` / own supply budget | Rust base upkeep and current supply allocation implemented; API 32 transport and selected detail presentation connected |
| Wonder host/empire yields, multipliers, stability and completion grants | `WonderProductionDefinition` | Rust public effects and local requirements implemented; API 32 transport and selected detail presentation connected |
| Building, unit, wonder, project and specialization selection | Existing revision-bound production commands | Connected; details must remain readable when the command is unavailable |
| Detail close / catalog return | Local presentation state | Separate modal up to 560 px, fixed illustrated header, scrolling content, preserved catalog position; refresh/correlation and recipient invalidation connected |
| Pending operation | Production workflow | Connected; block duplicate commands while retaining feedback |
| Selection, help, close and scrolling by keyboard/gamepad | Existing map input ownership and focus scopes | Modal and nested detail routing connected; Escape/B returns to the catalog without clearing city selection |

The reference sorts buildings using integer scores derived from yields and ETA.
Those rankings are a separate presentation policy in Rust, not a replacement for
command legality. Alphabetical tie-breaking may use localized names in Flutter
only after authoritative ranks are equal. A selected-item detail query can keep
large static descriptions/effect collections out of every refreshed catalog
response. Every detail response must carry the same recipient/revision guards as
production options, and an obsolete response must not replace a newer selection.

These mappings cover the production panel. They do not complete the field audit
for city management, workers, diplomacy, empire, statistics or activity history.
