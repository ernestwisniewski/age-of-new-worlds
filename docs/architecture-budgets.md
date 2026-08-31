# Architecture budgets

The architecture gate keeps new Dart code reviewable and prevents existing complexity debt from growing. It measures the repository directly; this file explains the policy, while `tool/check_architecture.dart` is the executable source of truth.

## What is measured

Every handwritten Dart file is assigned to one role: production, Flame rendering, test, or tool. Generated files are excluded only when their generator provenance is valid.

Per-file overrides and inline suppressions are only allowed when a file cannot be reduced without changing behavior; all approved exceptions are recorded in the baseline and are intended to be paid down.

New code is expected to stay within these limits:

| Role | Callable lines | Nesting | Cyclomatic | Cognitive |
| --- | ---: | ---: | ---: | ---: |
| Production | 60 | 3 | 10 | 15 |
| Flame rendering | 80 | 4 | 12 | 18 |
| Test | 120 | 4 | 15 | 20 |
| Tool | 100 | 4 | 15 | 20 |

The common file target is 500 lines and the type-declaration target is 350 lines. Existing exceptions are recorded at their exact measured value and may stay level or decrease; they may not gain extra headroom.

The aggregate gate also measures complete Dart libraries, including handwritten `part` files. Moving code into a part therefore does not reset its budget.

The aggregate baseline file (`architecture_aggregate_baseline.json`) uses schema 2 and the matching policy file (`architecture_aggregate_policy.json`) tracks the same target set.

## Commands

```sh
make architecture
```

To inspect an intentional debt reduction or policy migration:

```sh
make architecture-snapshot
diff -u tool/architecture_baseline.json /tmp/aonw-architecture-baseline.json
diff -u tool/architecture_aggregate_baseline.json /tmp/aonw-architecture-aggregate-baseline.json
```

Do not edit baseline values merely to make a regression pass. A baseline change must match the new measurement and preserve the historical ratchet against the trusted Git ref.

## Files to know

- `tool/check_architecture.dart` — census, parsing, metrics, and ratchet checks.
- `tool/architecture_policy.json` — roots, roles, targets, and schema.
- `tool/architecture_baseline.json` — current per-file and per-callable debt.
- `tool/architecture_aggregate_policy.json` — library-level policy.
- `tool/architecture_aggregate_baseline.json` — current library-level debt.
- `test/architecture/` — policy and metric-contract tests.

Changing roles, source roots, metric semantics, or rollout anchors is a policy migration, not a routine baseline refresh.
