# Pace profiles

Game length changes research, production, growth, flexible objectives, worker construction time, and victory pressure. It is not only a turn-limit label.

## Presets

| UI | Profile | Turn limit | Score fallback |
| --- | --- | ---: | --- |
| Short | `standard60` | 120 | yes |
| Normal | `normal90` | 180 | yes |
| Long | `long120` | 240 | yes |
| Very long | `unlimited` | none | no |

The actual multipliers live in `PaceBalance`; UI, AI, local commands, Serverpod, turn processing, and ETA must all read the pace stored in match rules.

Current profile intent:

- `standard60` lowers research, unit, building, growth, and flexible objective costs for a fast match;
- `normal90` is the default intermediate profile;
- `long120` keeps normal production/growth distance but slows research and uses a longer endgame window;
- `unlimited` preserves the no-cap reference balance and slower construction.

All positive scaled values use:

```text
max(1, ceil(baseValue * multiplier))
```

A zero-cost continuous project remains zero.

## Systems

- Research applies city/boost/era modifiers first, then pace.
- Units, buildings, and wonders scale their completion cost; city production per turn does not change.
- Growth scales the threshold; food income and upkeep remain visible real values.
- Only flexible objectives scale.
- Domination thresholds and hold windows come from the pace-specific victory rules.
- Combat, movement, vision, gold income, and rush exchange rate do not change through pace.

When adding a new cost or ETA, pass the active `PaceBalance` through the authoritative rules and the UI read model. Do not infer it from a localized preset name.

Re-run balance telemetry after changing profile multipliers, catalogs, or victory rules.
