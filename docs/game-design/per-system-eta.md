# Per-system ETA

Research, production, and city growth use the shared `TurnEta` model so lists and detail panels agree on completion time.

```text
remaining = target - progress
turns = ceil(remaining / progressPerTurn)
completionTurn = currentTurn + turns
```

Rules:

- `remaining <= 0` shows **ready**;
- `progressPerTurn <= 0` shows a system-specific blocked label instead of a fake number;
- costs are calculated after the active pace profile and other rule modifiers;
- ETA is informational and never stored in canonical state.

| System | Progress rate | Blocked label |
| --- | --- | --- |
| Research | current science per turn | `no progress` |
| Building/unit/wonder | effective production for the target | `no production` |
| City growth | actual food deposit after modifiers | `stagnant` |

Continuous city projects show `continuous` and have no completion turn.

List views use the compact `N turns · TX` form. Detail views may spell out the same values. Use one computed read model rather than repeating the formula in each widget.
