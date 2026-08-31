# Performance benchmarks

The performance gate protects deterministic work, not shared-runner timing. CI compares operation counts and output fingerprints; wall-clock samples are diagnostic because host load and VM warm-up are not portable.

## Workloads

The harness covers the paths most likely to scale badly:

- indexed world-map lookup and movement planning;
- authoritative movement and combat commands;
- fog reveal and auto-explore;
- turn finalization;
- event and snapshot persistence;
- replay;
- MCTS with exact iteration budgets;
- headless Flame rendering.

Fixtures are generated deterministically. Their construction and warm-up are outside the measured section where possible.

## Commands

```sh
make performance
```

Equivalent focused commands:

```sh
make performance-report
make performance-check
make performance-snapshot
make rust-benchmark
```

Reports default to `/tmp/aonw-performance-report.json`. Generated reports are local artifacts; only the reviewed policy and stable baseline belong in Git.

A stable-value change needs an explanation. It may be an optimization, a regression in work complexity, or an intentional workload change.

## Frame budget

Real frame timing is a separate manual gate. It must come from a Flutter profile build on the pinned reference device, using bundled assets and at least 600 measured frames for the controlled `renderer.frame.1000` scenario.

```sh
make performance-frame-check \
  PERFORMANCE_FRAME_REPORT_PATH=/absolute/path/to/report.json \
  PERFORMANCE_FRAME_DEVICE_ID=<pinned-device-id>
```

The current 60 FPS budgets are defined in `tool/check_frame_budget.dart`. Do not apply them to headless runs or shared CI workers.

## Updating the baseline

```sh
make performance-snapshot
diff -u tool/performance_baseline.json /tmp/aonw-performance-baseline.json
```

Review workload code, policy, and the candidate baseline together. Never replace the baseline solely because timings changed.
