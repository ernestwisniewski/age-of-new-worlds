# Changelog

## 1.1.16 - 2026-08-20

Added the shared Rust engine foundation for authoritative maps, movement, unit
actions, saves, replays, and client contracts, with Flutter and Godot
integration plus deterministic parity and rollback gates.

- Added the Godot map workbench, runtime map preview, and versioned map content
  workflow for developing the next presentation client against shared rules.
- Added a deterministic runtime asset pipeline with atlases, manifests,
  reproducibility checks, and explicit memory and frame-budget validation.
- Added a radial hex-selection palette and improved graphic-map clouds,
  markers, routes, cities, resources, and hover or movement feedback.
- Improved local single-player and hot-seat turn ownership so AI players wait
  for the human submission, consecutive AI turns resolve in order, and input
  remains blocked only until the human turn is fully ready.
- Fixed AI handoff lifecycle failures caused by late provider writes and
  disposed HUD widgets by keeping stateful overlay subscribers mounted and
  cancelling asynchronous publication after disposal.
- Hardened authored terrain semantics and updated performance fixtures so
  generated river tiles always retain a valid base yield terrain.
- Expanded command, renderer, HUD, provider, architecture, performance,
  coverage, protocol, and mutation regression gates while reducing oversized
  production and test libraries without relaxing quality thresholds.

## 1.1.15 - 2026-08-13

- Added a complete strategic-resource economy with revealed deposits,
  extraction improvements, per-player stockpiles, production costs, refunds,
  and resource-aware unit availability.
- Added deterministic strategic-resource placement around player starts for
  new local and multiplayer matches while avoiding occupied map features and
  keeping deposits on terrain where workers can reach them.
- Added strategic-resource summaries, breakdowns, value cards, production
  choices, and diplomacy flows for gold-for-resource and resource-for-resource
  agreements across all supported languages.
- Kept initial resource distribution, stockpiles, production reservations, and
  trade agreements authoritative and consistent across saves, replays,
  multiplayer projections, reconnects, turn timeouts, and server reduction.
- Improved AI planning and simulation so computer players evaluate strategic
  deposits, extraction, stockpiles, production requirements, and resource
  trades without using hidden opponent information.
- Improved movement precision and road-aware routing, including deterministic
  fixed-point movement migration and merchant routes that replan when the
  transport network changes and prefer genuinely cheaper connected roads.
- Added a persistent Show animations option to the main menu and in-game
  options. It is enabled by default and can disable unit movement, idle, and
  camera-transition animations.
- Reduced repeated strategic-resource projection work in the HUD to improve
  frame stability in developed matches with many cities and units.
- Hardened resource generation and trade agreement identifiers against
  unreachable deposits, map-object collisions, and cross-agreement ID or
  exchange-group collisions.
- Versioned and tested the expanded multiplayer, save, replay, and reducer
  contracts, including resource seeding, resource trades, reconnect behavior,
  movement migration, and recipient-safe state projection.
- Documented the accepted incremental migration from the current Dart engine
  to a shared Rust rules engine and separate Flutter AoNW1 and Godot AoNW2
  presentation clients, including parity, cutover, and rollback gates.

## 1.1.14 - 2026-08-11

- Added road construction and a persistent transport network that changes
  movement costs consistently in local games, multiplayer, saves, and replays.
- Improved combat targeting with clearer attackable-hex fills, animated attack
  trajectories, and unit-bound attacker, defender, and fortification markers.
- Fixed combat retreat markers so red and blue hex cues follow the unit from
  its rendered origin and settle exactly on the retreat destination.
- Improved late-game turn processing, map rendering, marker synchronization,
  and combat presentation performance on larger matches.
- Split large gameplay, renderer, HUD, editor, AI, reporting, and protocol
  components into focused modules with enforced architecture budgets.
- Versioned the road-aware multiplayer contract and durable snapshots, added
  compatibility fixtures, and documented coordinated rollout and rollback.
- Added a native single-player release smoke covering end turn, save, and a
  fresh reload, and expanded protocol, renderer, coverage, and mutation gates.

## 1.1.13 - 2026-08-10

- Stabilized turn-start action prompts and the handoff from automated players
  back to the human player so the HUD focuses the next required action once.
- Updated Flutter and Dart dependencies, including Flame, audio, sharing,
  image-picking, package metadata, code generation, and serialization tooling.
- Refreshed pinned GitHub Actions and Steam build workflows while preserving
  exact source identity checks for Windows and Linux release artifacts.
- Refreshed the pinned Dart builder and Debian runtime images used by the
  production server.
- Reconciled architecture and coverage ratchets with the reviewed dependency
  and presentation changes without lowering quality thresholds.

## 1.1.12 - 2026-08-09

- Added Dravonia, a new four-player map with balanced starting regions,
  strategic resources, luxuries, and contested objectives.
- Added connected city founding, automatic worker planning, and persistent
  desktop fullscreen preferences.
- Improved multiplayer lobby presence, reconnect, abandonment, and stale
  session cleanup across client and server lifecycle boundaries.
- Kept authoritative multiplayer audio, renderer state, and visual effects on
  one ordered presentation timeline, including renderer startup and late data.
- Correlated command acknowledgements by client message ID and versioned the
  incompatible wire contract so delayed responses cannot complete newer work.
- Hardened Steam, Google, and Apple browser authentication cleanup and
  cancellation when polling fails, expires, or the network client closes.
- Restored sound effects and music for debug iOS and macOS launches, including
  simulator and Android Studio run configurations.
- Fixed distant unit routes in single-player and multiplayer so the first
  legal boundary step exhausts any remaining movement instead of leaving an
  unusable point behind.
- Added a server-enforced multiplayer compatibility boundary so unsupported
  clients cannot enter a lobby or match during a rolling release, while
  compatible running-match history remains readable and preserved without
  rewriting durable events or snapshots.
- Stabilized Linux Steam packaging and headless runtime checks, and expanded
  domain, protocol, architecture, and release-gate coverage.

## 1.1.10 - 2026-08-02

- Unified Steam, Google, Apple, and email sign-in across web, iOS, Android,
  macOS, Windows, and Linux, including browser-based Apple authentication for
  Developer ID builds distributed through Steam and itch.io.
- Separated Mac App Store and Developer ID signing entitlements so native Apple
  sign-in remains available in store builds while notarized Steam and itch.io
  packages use the supported browser flow.
- Added server-managed Apple and Google browser callbacks with expiring state,
  PKCE verification, polling, rate limits, and cleanup of expired requests.
- Repaired Steam OpenID response verification, bounded provider traffic, and
  added actionable server diagnostics for rejected signatures and HTTP errors.
- Fixed Flutter WASM startup on the demo site by passing the multiplayer
  protocol version explicitly instead of invoking an incompatible tear-off.
- Expanded social-auth integration coverage and kept release architecture and
  coverage baselines aligned with the cross-platform authentication flow.

## 1.1.9 - 2026-08-01

- Completed the canonical state and world-map migration so gameplay, AI,
  multiplayer, replay, persistence, and rendering share one immutable map and
  one authoritative domain state without transitional command or map models.
- Versioned multiplayer compatibility explicitly and added a translated update
  notice for clients that must wait for or install a compatible release.
- Fixed observed multiplayer movement so exact and visibility-safe coarse
  movement remain ordered, animate once, and do not leak hidden path details.
- Made manual movement immediately available for fortified units and cancel
  fortification when a route is chosen, while keeping movement targeting and
  route reachability consistent after turn and snapshot reconciliation.
- Anchored excavation and artifact-transfer notifications above their unit or
  city on the map instead of presenting them as detached HUD messages.
- Strengthened root coverage around web persistence composition, lobby map
  capacity, movement and merchant HUD commands, cultural outcomes, map assets,
  release notices, and AI trace diagnostics.

## 1.1.8 - 2026-07-30

- Unified local games, multiplayer, AI simulations, and replay around one
  authoritative game engine so accepted commands follow the same rules and
  emit the same ordered domain events in every runtime.
- Separated presentation-only intents from serializable domain and server
  commands, preventing selection, focus, and tap interactions from crossing
  the multiplayer wire boundary.
- Rebuilt movement, combat, city economy, research, diplomacy, unit actions,
  turn finalization, and match outcomes on the shared engine while preserving
  deterministic local/server parity.
- Added a typed match lifecycle for matchmaking, active play, resignations,
  timeouts, completion, reconnects, and concurrent lifecycle transitions.
- Projected renderer and HUD effects from authoritative event batches with
  stable identities so reconnects do not repeat already displayed effects.
- Changed fortified-unit threat alerts so the unit remains fortified and idle
  while the camera focuses it and blue markers identify only visible enemies
  detected in its sight.
- Strengthened command, snapshot, presentation, lifecycle, performance, and
  architecture guards around the shared engine and strict current schemas.

## 1.1.7 - 2026-07-28

- Unified the map, save, replay, AI, and local-command read paths around the
  canonical snapshot model while preserving the existing save and replay
  formats.
- Improved early-turn AI responsiveness and movement previews by removing
  short-lived persistence isolates from frequent snapshot writes and small
  save-catalog reads.
- Kept local movement previews outside persistent command work so route
  feedback remains responsive while authoritative commands retain their
  existing replay and snapshot guarantees.
- Made event-log offset lookup constant-cost for desktop and web saves instead
  of scanning the complete command history.
- Preserved forward-compatible snapshot fields and stabilized turn timing when
  older or externally extended snapshots are decoded and written again.
- Expanded parity, architecture, persistence, and performance coverage around
  canonical state transitions and lightweight AI unit actions.

## 1.1.6 - 2026-07-26

- Improved multiplayer movement playback so acting players, opponents, and
  reconnecting observers preserve the exact server-approved path without
  duplicate, inferred, or out-of-order movement effects.
- Improved chained movement and auto-explore animations so intermediate steps
  remain visible and renderer cancellation, disposal, and late callbacks no
  longer leave ghost movement or visual jumps behind.
- Kept city panels stable while automatic actions continue and kept the camera
  focused on attacking units throughout combat playback.
- Unified local and server command rules across movement, city actions,
  diplomacy, research, workers, units, artifacts, and resource trades so the
  same command produces the same authoritative result in every game mode.
- Made turn economy, combat, automatic movement, timeout handling,
  resignations, and match outcomes use the same canonical state transitions.
- Improved save, replay, and running-match snapshot consistency with lossless
  state boundaries and stricter validation of authoritative multiplayer data.
- Improved large-map and AI performance with indexed map views, bounded
  traversal, and fewer full-map projections during movement, fog, production,
  city management, and turn resolution.
- Strengthened fog-of-war handling so multiplayer movement and event details
  are projected separately for each recipient and fail closed when visibility
  evidence is incomplete.
- Hardened development and release checks with pinned toolchains,
  local/server parity fixtures, deterministic performance budgets, mutation
  tests, generated-code validation, and critical end-to-end multiplayer
  journeys.
- Removed the obsolete Game Jolt release integration from code and
  documentation.

## 1.1.5 - 2026-07-12

- Added a public multiplayer statistics page with aggregate match activity,
  outcomes, turn counts, and recent online-session trends.
- Improved multiplayer result handling so victories, resignations, timeouts,
  and abandoned matches are recorded from the authoritative server state.
- Improved end-of-match summaries in multiplayer games so the HUD shows clearer
  synchronized outcomes for all players.
- Improved online session recovery so reconnects and multiplayer actions use
  the latest credentials after an access token expires.
- Made multiplayer sign-out more reliable when a session refresh or network
  request is already in progress.
- Made long multiplayer histories load across multiple pages so established
  matches can resume and replay beyond the first history page.
- Improved matchmaking and multiplayer match-list stability under larger
  queues by bounding how much stale-lobby and discovery work one request does.

## 1.1.4 - 2026-07-08

- Improved multiplayer synchronization so live matches recover more reliably
  after reconnects, delayed updates, duplicate messages, or stale snapshots.
- Preserved visible multiplayer action effects during sync updates so opponent
  moves, attacks, and other turn events are easier to follow.
- Hardened turn handling around timeouts, resignations, leaving matches, and
  reconnecting players so stalled multiplayer games are less likely to get
  stuck.
- Improved matchmaking and connection cleanup for stale lobbies and active
  multiplayer sessions.
- Expanded multiplayer smoke tests and protocol coverage to reduce regressions
  in online matches.

## 1.1.3 - 2026-07-08

- Added the first version of world wonders, including unique wonder projects,
  requirements, completion effects, map-ready artwork, and localized names.
- Expanded city production with dedicated wonder details, clearer production
  sections, and better explanations for why buildings, units, or wonders are
  available or locked.
- Improved technology details so unlocks, wonder requirements, and future
  production options are easier to understand before choosing research.
- Improved AI production planning so computer players can reason about wonder
  opportunities alongside units, buildings, and economy needs.
- Made saved games and multiplayer command handling preserve more production
  and wonder state across turns.
- Added clearer event messages for production, rush actions, wonder completion,
  and visibility-limited activity updates.
- Improved asset loading for wonder artwork and kept release packaging aligned
  with the latest public download builds.

## 1.1.2 - 2026-07-07

- Expanded the civilization roster to 24 playable countries, each with
  localized country and ruler names.
- Added civilization-specific city names and AI tendencies so new matches feel
  less uniform.
- Improved new-game setup around choosing a civilization and reading the match
  plan before starting.
- Expanded gamepad options with persistent settings for input enablement,
  deadzone, camera sensitivity, inverted camera Y, and button/axis bindings.
- Improved gamepad navigation across diplomacy popups, technology discoveries,
  city production, first-turn guidance, HUD actions, and end-turn flow.
- Made first-turn guidance clearer so founding the capital, choosing research,
  assigning production, and clearing pending actions are easier to follow.

## 1.1.1 - 2026-07-05

- Fixed controller targeting so unit move mode stays active while moving the
  hex cursor and confirming a destination.
- Improved gamepad navigation across the HUD, city production, technology tree,
  main menu, and load-game cards.
- Improved controller focus feedback so selected panels, rows, and cards are
  easier to follow after gamepad input.
- Prevented held controller input from accidentally carrying into newly opened
  panels.
- Fixed a turn-start panel flicker that could appear while the game state was
  updating.

## 1.1.0 - 2026-07-05

- Added gamepad controls for moving around the map, selecting tiles, confirming
  primary actions, opening key panels, and playing more comfortably from a
  couch or handheld-style setup.
- Added in-game manual guidance for gamepad controls across supported
  languages.
- Improved HUD economy breakdown performance so gold, science, and city
  economy details are calculated more efficiently when opened.
- Improved combat fog handling so combat updates reveal only the affected
  visibility changes instead of doing unnecessary full-map work.
- Tightened city production and ruleset calculations behind the HUD so economy
  forecasts stay clearer and cheaper to update.

## 1.0.9 - 2026-07-04

- Added the first version of empire stability, cohesion, and war-weariness
  systems, including clearer city and empire readouts in the HUD.
- Deepened combat with point-blank ranged retaliation, counter-battery fire,
  tuned damage variance, and a more distinct rifleman battlefield role.
- Improved combat previews and battle notifications so retaliation, modifiers,
  and combat outcomes are easier to understand before and after an attack.
- Improved AI tactical choices around retaliation, city defense, expansion, and
  long-term stability so computer players behave more consistently.
- Made multiplayer and saved-game snapshots preserve more empire state,
  including stability and war-weariness data.
- Improved HUD performance by deferring detailed resource breakdown work until
  it is actually opened.
- Reduced map and unit rendering overhead with incremental fog updates, cached
  unit badge text, and lighter preferred unit sprite atlases.
- Tightened unit rules, production data, and upkeep handling so unit behavior is
  more consistent across gameplay, AI planning, and UI previews.

## 1.0.8 - 2026-06-30

- Expanded diplomacy with clearer relationship information, better proposal
  feedback, gold gifts, shared-war context, and visible reasons behind diplomatic
  reactions.
- Improved AI turn planning so computer players defend cities and important
  units more reliably, avoid wasting idle military actions, and make steadier
  strategic choices.
- Made game popups less disruptive so outcome screens, guidance, and modal
  messages no longer dim or hide the map unnecessarily.
- Improved city and production requirement labels across supported languages,
  including clearer missing-resource messages.
- Strengthened map validation to catch broken or incomplete map data before it
  can cause confusing in-game behavior.
- Added Linux release support for Steam and itch.io.

## 1.0.7 - 2026-06-28

- Prepared the repository for open-source publication.
- Added MIT license, contribution guidance, security policy, and third-party
  notice files.
- Added a project code of conduct.
- Removed local development-agent planning notes and benchmark traces from the
  tracked source tree.
- Moved store icon collateral into `docs/marketing/`.
- Scrubbed public deployment documentation and Makefile defaults so private
  infrastructure values must be supplied explicitly.
- Removed tracked iOS build-time dart-define state.
- Removed the internal Serverpod multiplayer refactor plan from `docs/`.
- Added GitHub issue and pull-request templates and a funding placeholder.
