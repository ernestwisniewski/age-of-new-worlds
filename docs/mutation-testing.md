# Mutation testing

Mutation testing checks that focused tests detect small behavioral changes in critical code. It complements line coverage: a line can be executed without being meaningfully asserted.

The gate enforces seven reviewed operators in mutation policy and keeps scope narrowly constrained to one operatorized regression path per run.

## Migration continuity targets

| Area | Production file | Focused test |
| --- | --- | --- |
| Combat wire format | legacy combat serialization surface | legacy validation test suite |
| Unit command validation | `lib/game/domain/reducer/unit/unit_command_validator.dart` | `test/game/domain/reducer/unit_command_validator_test.dart` |
| Authentication input | `server/lib/src/auth/auth_input_validator.dart` | `server/test/auth/auth_input_validator_test.dart` |

These targets remain in the scope for migration continuity and legacy parity
regression, while Rust-owned gameplay logic is validated through Rust engine and
contract gates.

Each mutant runs alone in an isolated workspace. Only a real test failure counts as a kill. Analysis errors, crashes, timeouts, malformed output, or filesystem side effects fail the mutation tool itself.

The committed baseline records the exact target/operator census and all survivors. The accepted baseline has no survivors; there is no percentage waiver or inline suppression mechanism.

## Commands

```sh
make mutation
```

After an intentional target or assertion change:

```sh
make mutation-snapshot
diff -u tool/mutation_baseline.json /tmp/aonw-mutation-baseline.json
```

Review the complete census. Do not edit mutant identities or counts by hand.

The gate runs on POSIX hosts. Native Windows is not supported until equivalent process isolation is implemented.
