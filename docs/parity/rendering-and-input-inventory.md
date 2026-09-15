# Map, HUD and input inventory

Audited against `flame_4x` revision
`c6473641e57eb4337218234669c361db01c45d6e` on 2026-09-12.
Reference paths below start at `lib/game/presentation`; target map layers start
at `clients/aonw_flutter/lib/game/map`. This is a source inventory, not evidence
that each target has passed a full-screen visual comparison.

## Renderer

`engine/game_renderer_components.dart` constructs 23 visual layers and a unit
animation controller. Base map rendering additionally lives in `lib/map/rendering`.
The target composes its layers in `game/aonw_world.dart`; several source effects
share a target host rather than requiring separate components.

| Reference component | Target component/file | Authoritative input |
| --- | --- | --- |
| Base hex map, reference image, grid | `static_map_layers.dart`, `map_tile_details_layer.dart` | Immutable authored map, viewport and display preferences |
| UnitMarkerLayer | `unit_map_layer.dart` | Visible unit projection; own details only for recipient |
| UnitMovePreviewLayer | `map_route_layer.dart` | Rust turn boundaries for previews and owner-only stored routes; traversed merchant prefix dimmed |
| FieldImprovementMarkerLayer | `worker_infrastructure_layer.dart` | Visible improvement type, state and work progress |
| TransportNetworkLayer | `worker_infrastructure_layer.dart` | Visible road/city nodes; Rust classifies route road edges by movement domain |
| ArtifactMarkerLayer | `artifact_map_layer.dart` | Visible artifact projection |
| MapObjectiveMarkerLayer | `objective_map_layer.dart` | Authored objective location and projected progress |
| CityMarkerLayer | `city_map_layer.dart` | Visible city identity, ownership, population and presentation status |
| CityTerritoryOverlayLayer | `city_territory_layer.dart` | Recipient-safe city territory |
| EraTintOverlayLayer | `map_era_tint_layer.dart` | Projected era and visible territories |
| CityManagementOverlayLayer | `city_management_overlay_layer.dart` | Rust inspection/worked-hex/expansion query |
| CityFoundingPreviewLayer | `city_founding_preview_layer.dart` | Rust founding options, selected draft |
| FogOfWarOverlayLayer | `fog_map_layer.dart` | Recipient visible/discovered coordinates |
| ParticleEffectsLayer | Effect host and `map_event_feedback_layer.dart` | Accepted filtered command events and execution evidence |
| CityProductionParticleLayer | `map_city_production_layer.dart` | Own active production; display visibility preferences |
| CloudDriftLayer | `map_cloud_layer.dart` | Discovered fog region, camera and reduced motion |
| FloatingTextLayer | `map_event_feedback_layer.dart` | Filtered event values, localized labels |
| CombatHexAlertLayer | Effect host | Observed combat participants and ordered execution |
| CombatAttackTrajectoryLayer | Effect host | Observed attacker/defender anchors and counterattack evidence |
| ActionTargetHexFocusLayer | `map_selection_layer.dart` and effect host | Current target/accepted execution; no hidden actor lookup |
| ThreatOverlayLayer | `map_threat_overlay_layer.dart` | Rust movement/combat options and threat projection |
| HoverIntentMarkerLayer | `map_selection_layer.dart` | Local cursor and typed recipient-safe intent |
| ActionPaletteLayer | `map_action_palette_layer.dart` | Rust movement/worker options, preview and confirmation state |
| HexSelectionPaletteLayer | `map_hex_selection_palette_layer.dart` | Visible selectable targets on one hex |
| UnitAnimationController | Effect host and unit layer | Ordered command frames, movement/combat evidence and preferences |
| Global city-site/growth markings (base hex renderer) | `city_planning_layer.dart` | Rust cityPlanning query, recipient/stamp/fog validation |

Map geometry, interpolation, culling and visual timing belong to Flutter/Flame.
Path costs, future-turn limits, legality, ownership and visibility belong to Rust.
A map marker must not infer a hidden order or compute a domain rule from terrain.

## HUD surfaces and popups

The mounting sources are `widgets/hud/game_hud.dart`,
`widgets/hud/overlay/hud_overlay_panels.dart`,
`widgets/hud/overlay/hud_overlay_stack_slots.dart` and
`widgets/options/game_options_overlay_state_transitions.dart`.

| Surface or family | Reference subtree | Target status / source of truth |
| --- | --- | --- |
| Gold, science, stability, strategic resources, turn, victory details | `widgets/resources` | Shared strip/popovers; API 28 warnings/priority and API 29 authoritative inventory; full inventory panel remains open |
| Avatar details and Online status rail | `widgets/multiplayer` | Shared recipient-safe participants/known relations; own submission and aggregate total |
| Selection/action deck, previous/next, End/Submit | `widgets/hud/action_deck`, `widgets/selection` | Existing typed actions and Rust pending queue; integrated deck audit open |
| Movement, combat and worker confirmation | `widgets/selection` | Rust preview/options plus local confirmation state |
| City management, production, building/unit/project/wonder details | `widgets/city` | Typed Rust city and production queries; full composition audit open |
| Research recommendations, tree, technology details | `widgets/technology` | Responsive catalog/tree/details and Rust API 25 recommendation ranking implemented |
| Technology discovery, minimize/restore, suppress future popups | `widgets/technology/technology_discovery_popup_*` | Own filtered completion journal, 54 atlas thumbnails and six-language discovery prose implemented; full-screen comparison remains open |
| Civilization met, diplomatic messages/events/proposals | `widgets/diplomacy` | Known contacts, own messages/proposals; notification routing and full trade composition open |
| Objectives and guidance | `widgets/options`, `widgets/hud/overlay` | Authored requirements and recipient-safe live hold/controller data shown; priority guidance requires authoritative policy |
| Empire overview, readiness, army composition, city comparisons | `widgets/empire` | Own projected entities available; readiness definition and full panel open |
| Activity log, category tabs, notification focus | `widgets/activity_log`, `widgets/hud/notifications` | Recipient event journal available; full read model/filter/focus UI open |
| Feedback toast, turn-start banner, mode banner | `widgets/hud/feedback`, `widgets/hud/overlay`, `widgets/hud/mode_banner` | Command/turn presentation exists; reference comparison open |
| First-turn coachmarks and next-action guidance | `widgets/hud/overlay/hud_first_turn_coachmarks_slot.dart` | Rust pending queue navigation present; coachmark composition open |
| Private Hotseat handoff | `widgets/multiplayer/hot_seat_handoff_overlay.dart` | Canonical identity/turn, opaque privacy barrier and isolated pointer, keyboard and gamepad input; `hotseat-handoff.md` |
| Outcome and finished-match overlay | `widgets/hud` | Authoritative winner/metrics, four outcome tones and menu exit; four reviewed goldens, recipient privacy and input regression coverage in `match-outcome.md` |
| Options/help, minimized popup restore, resign confirmation | `widgets/options` | Existing preferences/input/resign flows; help/restore audit open |
| Reconnect/resync/errors and replay controls | Target session overlays | Required by current transport; shared renderer, recipient-scoped replay and visible failure state |

Options and help are mutually exclusive in the reference. Opening either closes
HUD side panels; collapse closes both. Broad panels and required selections must
coordinate focus rather than stacking competing interaction regions. Reading
resources or participants must preserve an outstanding required research choice.

## Input inventory

| Input | Observed reference behavior | Target boundary / verification |
| --- | --- | --- |
| Pointer tap | Select unit/city/artifact/objective or terrain; confirm current intent | Typed map selection and action ports; legality from query/command |
| Hover | Intent marker and target preview | Cursor-only updates must not rebuild the entire scene |
| Long press | Open hex target palette after readiness guard; cancel when leaving hex; suppress following tap | Hex-selection palette intent; verify drag/multitouch/cancel ownership |
| Drag, multitouch and pinch | Pan/zoom; suppress long press and unintended selection | Viewport input accumulator; preserve zoom anchor and camera preferences |
| Wheel/trackpad | Zoom/pan according to gesture | Shared zoom sensitivity and projection transform |
| Keyboard activate/cancel | Contextual confirmation, close/cancel before returning to map | Enter/Escape, focus ownership and no repeated command on key repeat |
| Keyboard map actions | View mode, movement intent, inspection, action navigation and primary turn action | R/M/I, brackets and Space in current shortcut contract; menu specification controls exposed bindings |
| Gamepad analog | Camera translation/zoom and hex cursor | Deadzone, sensitivity, inverted Y and editable bindings |
| Gamepad confirm/cancel | Confirm focused intent; cancel innermost popup/draft | Registered focus regions; B/Escape must not mutate an unrelated workflow |
| Gamepad inspect/move | Inspect cursor, toggle movement targeting | Y/X, Rust hex inspection and movement availability |
| Gamepad action navigation | Previous/next pending action, primary action | LB/RB/Start, Rust queue and current turn mode |
| Gamepad section focus | Switch between map and HUD/panel regions | L3/R3; nested resource/player regions own their buttons |
| Focus/lifecycle changes | Suspend input while inactive/modal; resume without held-button leakage | Input generation/reset and native lifecycle tests; physical controller run remains open |
| Accessibility | Semantic controls, text scale, high contrast, reduced motion | Widget tests and native full-screen audit; no looping effects in reduced motion/idle |

Input mounting sources: `engine/game_renderer_input_handler.dart`,
`engine/game_renderer_gamepad_input.dart`, the reference gamepad router and HUD
modal bindings. Current implementations live in `features/map/presentation/input`,
`features/map/presentation/widgets/map_screen_*` and shared gamepad focus regions.

## Sprite ownership near the camera

City and field-improvement components request their atlas frame when their local
visual bounds intersect the camera clip expanded by 128 world pixels. They paint
only inside the original clip. Leaving the expanded clip releases that component's
scope; other visible owners retain the shared atlas. Re-entering requests the same
frame without replacing the map component or rewriting the scene. Pending loads
cannot publish after leaving the clip, changing frame or disposing the component.
Unit animation scopes retain their existing ownership policy.

Tests cover cold offscreen components, camera exit/re-entry, shared ownership,
stale async completion and scene removal. Native frame and memory measurements
remain separate from these lifetime assertions.

## Outstanding evidence

The inventory accounts for every visual layer in the reference component factory
and the mounted HUD surface/input families. It does not claim a field-by-field
mapping of every panel: resource inventory, readiness and notification
payloads still need separate Rust contracts or audits. Route timing/roads and
compact HUD warnings now have explicit recipient-safe contracts.
Native captures, populated panels, full-screen comparisons and physical input
verification remain required by the execution plan.


A frame request with an already loaded manifest claims its atlas before yielding.
This lets an incoming scope retain the existing image when the outgoing scope
is released in the same event turn. A regression verifies image identity and one
page decode; separate cancellation cases reject a result after either its scope
or repository closes. Last-owner disposal still releases the atlas immediately.
