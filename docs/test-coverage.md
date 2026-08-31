# Test coverage

Coverage is a regression gate for executable lines, not a target to maximize at the expense of useful tests.

## Measured scopes

| Scope | Production source | Runner |
| --- | --- | --- |
| Legacy Flutter app (root) | `lib/` | Flutter tests, serial execution |
| Legacy Dart compatibility | legacy layer package root | Dart tests |
| Server | `server/lib/` | Server unit tests without external services |
| Rust engine | `engine/crates/` | `make rust-check` and Rust coverage/evidence gates |

The generated Serverpod client has a smoke test but no percentage target. PostgreSQL integration tests and the critical E2E journeys run separately.

## Commands

```sh
make coverage-check
```

Focused collection:

```sh
make flutter-coverage
make core-coverage
make server-coverage
```

`make coverage` is an alias for the complete collection and policy check.

## Policy

The committed baseline stores exact instrumented totals, portable covered-line floors, and eligible files missing from LCOV. The current run must keep the same census unless the source layout changed deliberately. Legacy Dart compatibility scope remains part of migration continuity and is not the target of production architecture growth.

The historical ratchet prevents a refreshed baseline from hiding a regression:

- coverage ratio may not decrease per layer;
- uncovered lines may not increase;
- the missing-file set may only shrink;
- changed eligible lines require at least 90% coverage, overall and per changed layer.

Generated files, localization output, Serverpod output, and `lib/main.dart` are excluded centrally in `tool/coverage_policy.json`. Inline coverage-ignore markers are not allowed in handwritten production code.

## Updating the baseline

```sh
make coverage-snapshot
diff -u tool/coverage_baseline.json /tmp/aonw-coverage-baseline.json
```

Review the file census and every changed count. Do not lower a floor simply because one platform collected fewer hits; the committed values must remain portable across supported environments.

Related files:

- `tool/coverage_policy.json`
- `tool/coverage_baseline.json`
- `tool/check_coverage.dart`
