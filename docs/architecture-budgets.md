# Architecture budgets

The architecture gate keeps new Dart code reviewable and prevents existing complexity debt from growing. It measures the repository directly; this file explains the policy, while `tool/check_architecture.dart` is the executable source of truth.

## What is measured

Every handwritten Dart file is assigned to one role: production, Flame rendering, test, or tool. Generated files are excluded only when their generator provenance is valid.

Approved exceptions are recorded at their exact measured value in the baseline
and are intended to be paid down.

New code is expected to stay within these limits:

| Role | Callable lines | Nesting | Cyclomatic | Cognitive |
| --- | ---: | ---: | ---: | ---: |
| Production | 60 | 3 | 10 | 15 |
| Flame rendering | 80 | 4 | 12 | 18 |
| Test | 120 | 4 | 15 | 20 |
| Tool | 100 | 4 | 15 | 20 |

The common file target is 500 lines and the type-declaration target is 350 lines. Existing exceptions are recorded at their exact measured value and may stay level or decrease; they may not gain extra headroom.

The engine has a separate fail-closed gate. For its current Rust implementation,
it verifies the exact workspace crate graph, pure-crate dependency and source
restrictions, workspace lint inheritance, the reviewed `unsafe` census, and a
500-line ceiling for new Rust sources. Existing longer Rust files have explicit
non-growing ceilings.

## Commands

```sh
make architecture-check
```

To inspect an intentional debt reduction or policy revision:

```sh
make dart-architecture-snapshot
diff -u tool/architecture_baseline.json /tmp/aonw-architecture-baseline.json
```

Do not edit baseline values merely to make a regression pass. A reviewed
baseline change must be generated from the current measurement and explain why
the affected debt cannot yet be removed.

## Files to know

- `tool/check_architecture.dart` — Dart census, parsing, metrics, and exact baseline checks.
- `tool/architecture_policy.json` — roots, roles, targets, and schema.
- `tool/architecture_baseline.json` — current per-file and per-callable debt.
- `tool/check_client_dependencies.sh` — Flutter and Godot layer boundaries.
- `tool/check_engine_architecture.py` — engine workspace and source policy.
- `clients/aonw_flutter/test/architecture/` — Dart metric-contract tests.
- `tool/test_client_boundaries.sh` and `tool/test_engine_architecture.py` — negative fixtures.

Changing roles, source roots, or metric semantics is a policy revision, not a
routine baseline refresh.
