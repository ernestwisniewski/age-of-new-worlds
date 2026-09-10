# Flutter parity reference catalog

The target combines the presentation of `flame_4x` with the menu flows in `.codex/ui-screens` and authoritative Rust rules. This catalog records observed presentation, identifies the corresponding recipient-safe data, and keeps unimplemented behavior visible.

## Captured reference

Source revision: `flame_4x` `c6473641e57eb4337218234669c361db01c45d6e`. Captured on 2026-09-12 with Flutter 3.44.2, Dart 3.12.2, bundled Cinzel/Lato/Material Icons, English, and pixel ratio 1.0. All 15 widget scenarios passed.

These images render the source project's `PumpGameHudTest`, `FakeHudRepository`, and empty `GameClientState(activePlayerId: 'player_1')`. They document the HUD and panel geometry. The pale background comes from the fixture's Scaffold; it is not a map, fog, or an intended game background. The fixture has no cities or recorded events. It does not establish populated empire/log behavior, full-screen game parity, native-device performance, or mobile platform compatibility. The avatar glyph in the fixture is not a target asset.

| State | Phone 390×844 | Tablet 1024×768 | Desktop 1440×900 |
| --- | --- | --- | --- |
| HUD | [Image](reference-hud/phone_hud.png) | [Image](reference-hud/tablet_hud.png) | [Image](reference-hud/desktop_hud.png) |
| Objectives | [Image](reference-hud/phone_objectives.png) | [Image](reference-hud/tablet_objectives.png) | [Image](reference-hud/desktop_objectives.png) |
| Research recommendations | [Image](reference-hud/phone_research.png) | [Image](reference-hud/tablet_research.png) | [Image](reference-hud/desktop_research.png) |
| Empty empire | [Image](reference-hud/phone_empire.png) | [Image](reference-hud/tablet_empire.png) | [Image](reference-hud/desktop_empire.png) |
| Empty activity log | [Image](reference-hud/phone_activityLog.png) | [Image](reference-hud/tablet_activityLog.png) | [Image](reference-hud/desktop_activityLog.png) |

[Manifest](reference-hud/manifest.json) records dimensions and SHA-256 hashes. The [capture template](../../tool/reference/capture_hud_test.dart.template) is intended to be copied to an unused test filename in the reference checkout, run with `flutter test --no-pub`, and removed afterwards. `AONW_REFERENCE_OUTPUT` can select an output directory through `--dart-define`. Running the template does not require signing in or touching real saves. Preserve existing files in the reference checkout.

## Source decisions

| Source behavior | Decision | Target |
| --- | --- | --- |
| Illustrated menu, gold accents, headings and compact actions | Retain presentation | Shared design tokens and menu shell |
| One New Game entry and direct resume on the main menu | Overridden by menu specification | Separate Single, Multiplayer, Hotseat, Load Game, Settings and Exit; no direct resume entry |
| Setup content and navigation | Overridden by setup specifications | Civilizations, participant configuration, map, victory paths, settlement options, summary; Online proceeds to lobby |
| Turn progression selected through session kind | Retire coupling | Separate Rust turn mode; selectable Single, sequential Hotseat, simultaneous Online |
| Source Dart reducers, AI, economy calculators and save format | Retire implementation | Rust commands, queries, canonical save and replay; current-engine imports only |
| Map, HUD, camera and panel presentation | Retain behavior | Shared Flame renderer, recipient-safe state, accessible input |
| Settings grouping | Overridden by settings specification | Profile, accessibility, language, window, map, markings, camera, animations, automation, audio, AI, performance, collapsed gamepad and keyboard |
| Audio, AI battery saver and performance controls | Retain controls | Three sound channels/volumes, Rust AI effort, FPS and map zoom |
| Load Game list | Overridden by load specification | Single/Hotseat/Online, resume/replay/export, import; Online history remains unfinished |

## Panel and data inventory

Paths below are relative to `flame_4x/lib/game/presentation/widgets` for the reference and `clients/aonw_flutter/lib/features` for the target. A present data field does not certify visual parity.

| Presentation | Reference location | Current recipient-safe source | Remaining work |
| --- | --- | --- | --- |
| Top resources and details | `hud/resources` | `PlayerMapView.economy`, `research`, `victory`, `turnView` | Rust-backed bankruptcy/shortage warnings and compact victory summary |
| Avatars and Online status | `hud/game_hud_chrome.dart` | Participants, own submission, known diplomacy and aggregate submissions | Final full-map visual comparison |
| Action deck and selection | `hud/action_deck`, `selection` | Selected visible unit/city, typed action options and Rust pending-turn query | Integrated command/selection deck, expansion and detail behavior |
| Research | `technology/technology_tree_dialog.dart` | `ResearchOptionsView`: availability, costs, progress, prerequisites, exclusions and unlocks | Responsive panel, tree navigation, selected details; recommendation ranking/reasons require Rust policy |
| City and production | `city` | City inspection, founding/growth/production queries and own city projection | Full panel composition and comparative visual audit |
| Workers and improvements | `hud/action_deck`, `selection` | Worker options and accepted command feedback | Detail layout and popup/gamepad audit |
| Diplomacy | `diplomacy` | Known relations, own proposals/messages, typed commands | Full message/trade composition and visual audit |
| Objectives and victory | `options`, `hud/overlay` | Map objectives and projected victory progress/outcome | Prioritized guidance needs explicit authoritative policy; full outcome comparison |
| Empire and statistics | `empire/empire_overview_dialog.dart` | Own projected units/cities/resources and score | Aggregate readiness definitions and complete overview UI |
| Activity log and notifications | `activity_log`, `hud/notifications` | Bounded recipient event journal and turn activities | Detailed event read model, filtering, focus targets and replay integration |
| Hotseat handoff | `hud/game_hud_handoff.dart` | Local control plan and authoritative actor switch | Native complete-session and visual checks |
| Online history and replay | Load Game and profile flows | Server participants, command ledger, current state | Initial replay checkpoint and recipient-safe server replay transport; canonical state must remain server-only |

## Observed layout constraints

- Research recommendations use three columns on a large panel and a scrolling single column on the phone. The panel has a title/science header, mode control and independently scrolling body. The tree view is a separate state, not captured here.
- Empire uses readiness/composition and city comparisons. The phone reference has a cramped composition column; preserve the information and responsive intent while avoiding the clipping in the fixture.
- Activity log uses category tabs and a centered empty state. On a phone the diplomacy label wraps; target controls must remain accessible at increased text scale.
- Objectives can remain beside the side menu, whereas broad research/empire panels use much more of the viewport. A hard-coded 640-pixel child cannot fit the phone target.
- Opening a read-only panel must preserve authoritative required actions and recipient privacy. Styling is not permission to copy source Dart decision rules.

## Still required for reference completion

Native desktop/phone/tablet runs; menu, setup and lobby captures; populated city, production, worker, diplomacy, technology tree, battle, log, handoff and terminal states; terrain/fog/camera captures and recordings; complete field-level mappings for all remaining presentation policies. This catalog does not mark M0 or M7 complete.
