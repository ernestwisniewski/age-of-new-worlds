# Static analysis

All handwritten Dart code uses one workspace policy. Package files add the appropriate ecosystem profile, but shared rules live in `analysis_options_base.yaml`.

| Package | Upstream profile |
| --- | --- |
| Flutter app | `flutter_lints` |
| Legacy Dart compatibility layer | `lints/recommended` |
| `packages/aonw_server_client` | `lints/recommended` |
| `server` | `lints/recommended` |

The shared policy owns strict casts, inference, raw types, async rules, import order, and API hygiene. Do not copy these rules into package-specific files.

Generated and vendored exclusions are intentionally narrow. The routing boundary between handwritten and generated code is explicit, with generated paths like `server/**`, `lib/src/protocol/**`, and `lib/src/generated/**` intentionally excluded only where required by upstream compatibility.

Serverpod output is excluded from strict analysis because the pinned generator does not satisfy every rule, but `make generated-code-check` must be able to reproduce it. Handwritten files must not hide under a generated path.

## Commands

```sh
flutter pub get --enforce-lockfile
make analyze
```

Focused targets:

```sh
make flutter-analyze
make core-analyze
make server-client-analyze
make server-analyze
```

Warnings and infos are fatal in the canonical targets.

When changing analyzer policy or an exclusion:

1. update the shared base or the narrow package exception;
2. update `test/architecture/lint_configuration_guard_test.dart`;
3. run `make analyze` and `make generated-code-check`;
4. run `make ci` before handoff.
