# Settings coverage

The functional inventory follows `.codex/ui-screens/main-menu-options.md`.
All sections are mounted by
[`SettingsScreen`](../../clients/aonw_flutter/lib/features/settings/presentation/settings_screen.dart).
Preferences use `ClientSettingsController`, immutable settings values and the
platform preference store; window operations use their separate asynchronous
controller. Display preferences do not change canonical game state.

Paths in the table are relative to
`clients/aonw_flutter/lib/features/settings/presentation/`.

| Requested controls | Implementation | Consumer / authority |
| --- | --- | --- |
| Profile name; retain match history | `account_profile_settings.dart` | Authenticated profile endpoint; match membership retains the stable account ID |
| Text size and high contrast | `settings_text_scale.dart`, `settings_screen.dart` | App text scaling and theme; system scaling is preserved |
| Language | `settings_language.dart` | PL/EN/FR/DE/ES/NL plus system locale; immediate app localization |
| Fullscreen / windowed | `settings_window.dart`, `window_settings_host.dart` | Platform window adapter, serialized transitions and reported failures |
| Graphic / tile map, hex grid, elevation walls | `settings_map.dart` | Map presentation settings and Flame layers |
| Resource icons, elevation labels, city sites, city growth | `settings_map.dart` | Display toggles; city planning candidates remain a recipient-safe Rust query |
| Focus/follow own and foreign movement | `settings_movement_camera.dart` | Camera consumes disclosed movement effects only |
| Zoom sensitivity, smooth and cinematic camera | `settings_screen.dart` | Camera presentation controller |
| Idle, movement, planned-route and combat animations | `settings_animations.dart` | Flame animation/effect settings; reduced motion remains independently available |
| Advance to action and finish turn automatically | `settings_automation.dart` | Shared action flow follows the Rust pending-action queue and submits normal commands |
| Research discovery notifications | `settings_automation.dart` | Recipient event inbox and persistent popup suppression |
| Sound, music and nature; independent enable/volume | `settings_audio.dart` | Audio ports and lifecycle routing |
| AI battery saving | `settings_ai.dart` | Explicit Rust runtime planning profile; Flutter does not plan moves |
| FPS and map zoom indicators | `settings_performance.dart` | Measurements stop when their indicators are disabled |
| Collapsed gamepad section; enable, deadzone, sensitivity, invert Y | `settings_gamepad.dart` | Shared map/menu input bindings and generation guards |
| Remap buttons/axes; conflicts and reset | `settings_gamepad_bindings.dart` | Typed persisted bindings; picker participates in gamepad focus routing |
| Collapsed keyboard section; common shortcuts | `settings_keyboard.dart` | Camera, select/move/inspect, map mode, pending actions, primary action, cancel and focus navigation |
| Restore defaults | `settings_screen.dart` | Resets preferences and the supported desktop window mode |

The corresponding presentation tests live in
[`test/features/settings`](../../clients/aonw_flutter/test/features/settings).
They cover edits, reset, persistence, locale variants, collapsed sections,
remapping and profile/session guards. Map consumers are covered by
`map_settings_test.dart`, `map_screen_audio_test.dart`,
`map_gamepad_settings_test.dart` and the settings binding tests. The native
`turn_automation_native_test.dart` covers Single turn modes, private Hotseat
handoff and loss/restoration of window activity.

The complete Flutter gate passed with 1165 tests after the discovery changes.
This closes the functional Settings inventory. Full-screen visual comparison
and physical-controller coverage remain in the cross-screen QA inventory;
this audit does not claim either from widget tests.
