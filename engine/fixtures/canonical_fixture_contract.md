# Canonical fixture contract

`canonical_commands/` is the executable command corpus for the Rust engine.
Every file contains one complete canonical state, one authenticated command and
the exact expected state, events, evidence or rejection code. The corpus is
loaded with strict DTOs and executed directly through `GameEngine`.

`canonical_state_rejections/` covers aggregate states that must fail before
command dispatch. Keeping boundary rejections separate ensures that command
fixtures always begin with a valid domain aggregate.

The contract is intentionally small and permanent:

- `fixtureVersion` versions the independently stored fixture artifact;
- `id` and `capability` identify the behavior under test;
- `input` contains the actor, ruleset, logical map, state and command;
- `expected` contains the complete authoritative result.

Fixtures do not contain alternate state envelopes, optional aliases, omitted
defaults or generated expected output. Any contract change updates the typed
DTOs, executor and affected fixtures atomically.
