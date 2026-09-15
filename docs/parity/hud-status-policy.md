# Authoritative HUD status

The engine owns treasury warnings, unlocked-unit stockpile shortages and the
compact victory priority. These read-only policies do not mutate economy,
production, turn processing or victory resolution.

Treasury status distinguishes an already negative balance from a negative
three-turn forecast. Reaching exactly zero is not a warning. The comparison uses
wide integer arithmetic, including at the signed 64-bit limits.

A stockpile warning considers only recipient-unlocked unit production. Any
covered authored resource alternative suppresses that unit's warning. Otherwise
the first authored option supplies the missing kinds, matching the reference
`UnitStrategicResourceAvailability` policy. Existing city reservations are not
refunded in this empire-level view. Locked units and opponents' research do not
contribute warnings.

A score deadline within five turns has first priority. Otherwise the recipient's
cultural collection takes precedence over domination below its threshold. When
domination is being held, a complete own collection takes priority only if its
remaining hold is shorter. Territorial leaders are ordered by controlled tiles,
held turns, then player ID. Warnings follow the reference hold-duration policy:
90% of the required threshold for at most two hold turns, 95% for three, holding
for at most three required turns, or at most one remaining hold turn. Decimal
percentage comparisons are exact. Score ties disclose no single leader.

The reference HUD reads every player's cultural collection. This engine's
recipient contract deliberately keeps rival collections private. The priority
policy accepts only recipient-safe `VictoryProgress`, so neither the status nor
its warning can disclose rival artifacts. Public domination and public total
scores remain available. Disabled conditions and a map without passable tiles
have explicit fallbacks.

Reference sources are `top_resource_strip.dart`,
`hud_strategic_resource_summary.dart`, `unit_strategic_resource_availability.dart`,
`hud_victory_status_summary.dart`, `hud_victory_status_cultural.dart` and
`domination_progress.dart` at the revision pinned in `reference-catalog.md`.


Client API 28 requires `economy.forecast.treasuryWarning`, the ordered
`economy.strategicResourceShortages` list, and `victory.status` with a typed kind,
critical flag and explicit nullable leader. Snapshots and replacement patches
share the same encoder. Canonical state, save and replay formats do not change.
Dart rejects missing or unknown values, invalid shortage kinds/order, leaders
outside the roster and cultural summaries naming a different recipient. The UI
copies this metadata into immutable read models; it does not recalculate warning
thresholds or victory priority.

The resource strip and details expose warnings through icons, text, tooltips and
semantics in all six languages. Popup warnings use the full available width.
Golden coverage includes the three size classes; widget checks cover portrait and
landscape phones at 200% text and verify no scheduled frames after settling.
The full strategic-resource inventory and detailed victory guidance remain
separate parity work beyond this compact status contract.
