# Balance telemetry

Balance telemetry is a deterministic development report for the opening and mid-game. It is not save data, a remote analytics pipeline, or an automatic rebalance system.

## Questions it answers

The analyzer records milestones such as:

- first technology, building, second city, contact, and combat;
- dead-turn runs where the player makes no meaningful decision or progress;
- victory turn and condition;
- final technologies, science, cities, units, gold, and net gold;
- score-pressure advice and the manual decision type it points toward.

A sample contains a turn, canonical state, optional events, meaningful command counts, optional objective-action diagnostics, and optional outcome/economy data. It lives outside the save format and can come from tests, AI simulations, or playtest tooling.

A turn is not dead when the player issued a meaningful command, received a meaningful event, or the state shows visible progress such as exploration, movement, production, growth, a new city, or an improvement. Passive science progress alone does not make an otherwise empty turn meaningful.

## Targets

Tuning targets live in `BalanceTelemetryTuningTargets` and in the selected pace profile. Do not copy generated turn results into this document; they change as maps, AI, and costs change.

Findings use stable codes such as late first technology/contact/combat, a long dead-turn streak, or final pace outside configured guardrails. Completed conquest/domination outcomes may suppress irrelevant low-economy end-state warnings.

## Generate a report

Report generation is handled by the current migration pipeline, not the legacy
report command path. Use the active reporting command from the current runtime
workspace and cite the generated artifact path and timestamp in balance reviews.
Generated evidence is operational only and is not a permanent product contract.
