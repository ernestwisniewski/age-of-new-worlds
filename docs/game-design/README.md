# Gameplay and UX contracts

These notes describe behavior shared by several layers or easy to break during refactors. Current values live in rulesets and catalogs; generated reports live under `build/`.

## Core rules

- [Pace profiles](pace-profiles.md)
- [Scoring and outcomes](scoring-and-outcomes.md)
- [Strategic resource economy](strategic-resource-economy.md)
- [World wonders](world-wonders.md)
- [Yield unification](yield-unification.md)
- [Map validation](map-validation.md)

## Player guidance

- [Objective chain](objective-chain.md)
- [Turn flow and action focus](turn-flow-and-action-focus.md)
- [Per-system ETA](per-system-eta.md)
- [Balance telemetry](balance-telemetry.md)
- [Resource value cards](resource-value-cards.md)

## Input and presentation

- [Movement and route preview](movement-and-route-preview.md)
- [Combat preview](combat-preview.md)
- [Combat feedback](combat-feedback.md)
- [Mobile automation](mobile-qol-automation.md)
- [Gamepad controls](gamepad-controls.md)
- [Event notifications and popups](event-notifications-and-popups.md)
- [Desktop display mode](desktop-display-mode.md)
- [Map display preferences](map-display-preferences.md)
- [Asset icon rendering](asset-icon-rendering.md)

When a document and the implementation disagree, treat the code and tests as the immediate source of truth and fix the documentation in the same change. Do not add a second balance table here to repair drift.
