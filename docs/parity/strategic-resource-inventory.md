# Strategic resource inventory

Reference: `flame_4x` at `c6473641e57eb4337218234669c361db01c45d6e`,
`hud_strategic_resource_summary.dart` and `strategic_resource_economy_dialog.dart`.

The engine owns the seven strategic balance rows, city reservations, revealed
deposits, availability/shortage counts and attention indicators. The read model
does not reserve, refund, extract or deliver resources. Turn settlement and
production commands remain authoritative.

| Display | Authoritative meaning |
| --- | --- |
| Available oil/aluminium | Current free stockpile, excluding city reservations |
| Other available resources | Revealed controlled deposits plus active import agreements |
| Allocated | Current recipient-owned production queue reservations |
| Stored total | Available plus allocated, using checked arithmetic |
| Domestic production | Existing extraction query, including technology and improvement ownership |
| Imports/exports | Agreed quantities per turn; delivery can still fail at settlement |
| Net flow | Domestic production plus imports minus exports |
| Source count | Producing extraction sources for stockpiled resources; revealed deposits otherwise |
| Deposits | Recipient territory only, including unimproved or non-producing deposits |
| Shortage | Existing unlocked-unit alternative-cost policy; reservations and future imports are excluded |
| No free stock | Zero available with a positive production reservation |
| Expiring trade | Own agreement with at most two turns remaining |

Presence availability counts import agreements, while the flow column counts
their quantities. This distinction follows the reference's `visibleCountFor` and
`_importedCountsFor`; exports do not remove domestic presence from the display.
The separate production presence gate currently checks domestic resources only.
Its treatment of imported resources requires a command/replay behavior review
in the diplomacy stage; this presentation change does not modify that rule.

Zero rows remain visible, including resource kinds not yet revealed. Hidden
deposits, other participants' research, stockpiles, allocations and unrelated
agreements are excluded. Map and generated resource placements are deduplicated.
Territory uniqueness comes from validated canonical state; inventory traversal
does not allocate a temporary set for each tile.

Core acceptance coverage includes seven-row order, foreign research isolation,
unimproved deposits, duplicated generated/map oil, extraction ownership, stock
versus reservations, trade quantity versus presence, alternative costs, expiration
boundaries, repeatable reads, overflow and unknown participants.

Client API 29 carries required `economy.strategicResourceInventory` in the shared
snapshot/patch encoder. Its balances have a fixed seven-element wire shape;
deposit improvement and extraction amount are required nullable fields. Rust and
Dart reject missing/unknown fields. Flutter additionally validates ordering,
owned-city references, territory bounds, extraction evidence, reservation totals,
summary counts and agreement references before mapping the inventory.

The native turn regression compares the entire inventory in the accepted-command
patch with a fresh snapshot and checks that extraction changes free oil from two
to three. Contract coverage includes 18 existing round trips and three strict
inventory cases; the Dart package has 100 passing tests. The full responsive
resource panel is the next stage. Canonical save/replay state and engine behavior
identity are unchanged; API 29 performance review is tracked separately.
