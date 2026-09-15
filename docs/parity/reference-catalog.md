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
| Load Game list | Overridden by load specification | Single/Hotseat/Online, resume/replay/export, import; Online history and recipient-safe playback; portable Online export remains open |

The [rendering and input inventory](rendering-and-input-inventory.md) enumerates
the reference component factory, mounted HUD surfaces and input families.

## Panel and data inventory

Paths below are relative to `flame_4x/lib/game/presentation/widgets` for the reference and `clients/aonw_flutter/lib/features` for the target. A present data field does not certify visual parity.

| Presentation | Reference location | Current recipient-safe source | Remaining work |
| --- | --- | --- | --- |
| Top resources and details | `hud/resources` | `PlayerMapView.economy`, `research`, `victory`, `turnView` | API 29 inventory and API 28 warnings/priority available; complete inventory panel remains open |
| Avatars and Online status | `hud/game_hud_chrome.dart` | Participants, own submission, known diplomacy and aggregate submissions | Final full-map visual comparison |
| Action deck and selection | `hud/action_deck`, `selection` | Selected visible unit/city, typed action options and Rust pending-turn query | Integrated command/selection deck, expansion and detail behavior |
| Research | `technology/technology_tree_dialog.dart` | `ResearchOptionsView`: availability, costs, progress, prerequisites, exclusions and unlocks | Responsive catalog, tree/details and recommendations from Rust API 25 implemented; completion popup uses own accepted events; 54 atlas illustrations and six-language authored discovery descriptions implemented |
| City and production | `city` | City inspection, founding/growth/production queries and own city projection | Full panel composition and comparative visual audit |
| Workers and improvements | `hud/action_deck`, `selection` | Worker options and accepted command feedback | Detail layout and popup/gamepad audit |
| Diplomacy | `diplomacy` | Known relations, own proposals/messages, typed commands | Full message/trade composition and visual audit |
| Objectives and victory | `options`, `hud/overlay` | Map objectives and projected victory progress/outcome | Outcome comparison/input complete in `match-outcome.md`; prioritized objective guidance remains open |
| Empire and statistics | `empire/empire_overview_dialog.dart` | Own projected units/cities/resources and score | Aggregate readiness definitions and complete overview UI |
| Activity log and notifications | `activity_log`, `hud/notifications` | Bounded recipient event journal and turn activities | Detailed event read model, filtering, focus targets and replay integration |
| Hotseat handoff | `hud/game_hud_handoff.dart` | Local control plan and authoritative actor switch | Native complete-session and visual checks |
| Online history and replay | Load Game and profile flows | Server-only checkpoint/journal, verified recipient frames and historical queries | Shared client playback implemented; portable export and long-archive performance remain open |

## Observed layout constraints

- Research recommendations use three columns on a large panel and a scrolling single column on the phone. The panel has a title/science header, mode control and independently scrolling body. The tree view is a separate state, not captured here.
- Empire uses readiness/composition and city comparisons. The phone stacks readiness and composition cards while larger views place them side by side.
- Activity log uses category tabs and a centered empty state. On a phone the diplomacy label is abbreviated; target controls must remain accessible at increased text scale.
- Objectives can remain beside the side menu, whereas broad research/empire panels use much more of the viewport. A hard-coded 640-pixel child cannot fit the phone target.
- Opening a read-only panel must preserve authoritative required actions and recipient privacy. Styling is not permission to copy source Dart decision rules.

## Still required for reference completion

Native desktop/phone/tablet runs; menu, setup and lobby captures; populated city, production, worker, diplomacy, technology tree, battle, log, handoff and terminal states; terrain/fog/camera captures and recordings; complete field-level mappings for all remaining presentation policies. This catalog does not mark M0 or M7 complete.


## Research discovery acknowledgement

The client retains at most 64 own completion events independently of map-effect
anchors. Direct commands and lazily projected AI/replay frames use the same
mapper; other recipients, rejected commands and repeated revisions add nothing.
Opening/resync clears this journal. The popup inbox deduplicates event identity,
clears on recipient/session changes and backward revisions, and acknowledges
suppressed events without redisplaying them when the preference is enabled.

Gameplay shows a scrollable completion panel, minimize/restore and a persistent
suppress preference (also available in Settings). Unlock details are shown only
from the current recipient's matching-stamp Rust research query. Closing the
popup preserves required research without a cancellation, selection or turn
command. Input ownership blocks background keyboard/gamepad actions. Six
languages and 200% landscape text pass; phone/tablet/desktop goldens are reviewed.
The full client gate passes 1165 tests with clean analysis. All 54 technology
thumbnails and authored discovery descriptions in six languages are implemented.
Full replay notification composition remains part of the final HUD audit.

## Shared replay screen regression images

The target replay now mounts the same `MapScreen` and HUD as live sessions.
[Phone](../../clients/aonw_flutter/test/features/replay/presentation/goldens/replay_phone.png),
[tablet](../../clients/aonw_flutter/test/features/replay/presentation/goldens/replay_tablet.png)
and [desktop](../../clients/aonw_flutter/test/features/replay/presentation/goldens/replay_desktop.png)
cover the full playback layout in Polish, German and English with bundled fonts,
a deterministic 12×8 tile map and four loaded commander sprites. Reduced motion
keeps captures deterministic. These are target regression images, not captured
reference matches or evidence of native archive correctness. All three images
were inspected; controls remain below the map without covering the shared HUD.

## Main menu comparison

The [menu capture template](../../tool/reference/capture_menu_test.dart.template)
reproduces the original root menu with mocked local preferences, secure storage
and package metadata. [Its manifest](reference-menu/manifest.json) records source
revision, sizes, hashes and limitations. The English reference captures cover
[phone](reference-menu/phone_menu.png), [tablet](reference-menu/tablet_menu.png)
and [desktop](reference-menu/desktop_menu.png). The reference phone has one footer below the main actions.

The target retains the source logo, gradients, 390-pixel wide panel, gold borders
and 50-pixel minimum action height. By explicit user direction, the background
uses `assets/main_menu/background2.jpg` from this repository, copied byte for byte
to the Flutter asset bundle. This supersedes the reference bay-and-city background. Six main actions,
the welcome message and update notice follow the current menu specification.
At increased text scale, labels wrap, footer links reflow and the complete menu
scrolls. A short viewport must not hide the update notice. Twelve regression
cases across six languages first failed and now exercise every action at 200%
in portrait and landscape. Target images are
[phone](../../clients/aonw_flutter/test/features/main_menu/presentation/goldens/menu_phone.png),
[tablet](../../clients/aonw_flutter/test/features/main_menu/presentation/goldens/menu_tablet.png)
and [desktop](../../clients/aonw_flutter/test/features/main_menu/presentation/goldens/menu_desktop.png).


## Objective panel regression coverage

The objective panel constrains its width to the viewport and safe right inset.
Its title, description and lazy objective list share a scroll view, keeping all
content reachable on short screens at 200% text. Twelve cases cover six languages
in both phone orientations; they failed before the layout change. The panel
bounds and close action are checked explicitly. The three populated target
images under `test/features/objectives/presentation/goldens` use actual test-view
sizes of 390×844, 1024×768 and 1440×900, bundled fonts and Polish/German/English.
They were inspected visually. These are isolated panel regressions; full-map
comparison and priority guidance remain separate work.


## Capture viewport correction

The HUD/menu references and target menu/replay goldens now set both the physical
test view and render surface to the listed dimensions, with pixel ratio 1.
Each capture asserts its effective `MediaQuery` size. Surface-only sizing had
left responsive code observing the default 800×600 view, even when the resulting
PNG had phone/tablet/desktop dimensions. All 18 reference captures were rerun and
inspected, and their manifest hashes were refreshed. The earlier apparent
phone footer overlap and cramped empire columns were artifacts of that harness.
The six target menu/replay images were regenerated and inspected as well;
33 target tests passed. These corrections do not claim native device coverage.


## Map objective progress

The shared HUD passes `PlayerVictoryView.mapObjectives` and public participant
names into the objective panel. Authored requirements remain in `MapObjectiveView`;
live entries are matched by objective ID. The card displays the supplied hold
count without clamping or predicting it. This applies to local/Online play and
the shared read-only replay HUD.

Rust's `outcome/victory_progress.rs::map_objective_progress` discloses a controller
only when it belongs to the recipient or its coordinate is visible. A null
controller can represent either absent or undisclosed control, so Flutter shows
no known controller rather than claiming the location is unoccupied. It also
omits the hold count in that case. Six language tests replace disclosed progress
with unknown control and then an unrelated objective, verifying that old names
and counts disappear. The 200% phone tests include populated progress, and the
three regression images now include both known and unknown control.

## Local setup and review coverage

Twelve target images in `test/features/local_game/presentation/goldens` cover
Single and Hotseat setup/review at 390×844 (Polish), 1024×768 (German), and
1440×900 (English). They use production fonts, the selected menu background,
and matching physical view and surface dimensions. All twelve were inspected.
Descriptions sit on the shared dark panel so bright areas of the image do not
obscure them.

Twenty-four body readability/navigation cases cover six languages, both phone
orientations and 200% text. Moving from the bottom of setup to review originally
retained the scroll offset in all cases; each step now starts with its own scroll
state. Tests reach Continue, Start and Change setup, check untruncated body text,
and retain existing creation tests. This is widget coverage, not native mobile
validation or the separate Online setup/lobby audit.

## Online layout regression coverage

The Online screen shares the selected menu backdrop. Its waiting panel respects
a 680-pixel maximum width; small screens and increased text put readiness below
the participant details. Navigation and account actions wrap, and setup selectors
allow their labels to wrap at increased text sizes. Six portrait cases first
failed in each of setup and waiting-room navigation before these corrections.

Twenty-four cases now cover setup/waiting, six languages and both phone
orientations at 200%. Waiting tests reach every action and verify the ready
transition enables Start through the controller. Four inspected target images
under `test/features/multiplayer/presentation/goldens/waiting_room_*` cover the
three standard sizes and German phone text at 200%. These regressions do not
complete reference lobby parity: participant country/connection detail, full
setup flow comparison and native multiplayer sessions remain to be audited.
