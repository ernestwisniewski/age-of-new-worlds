# Canonical command fixtures

This corpus exercises the Rust engine contract directly. Every JSON
file is a self-contained, independently reviewed artifact with these exact
sections:

- `fixtureVersion`: shared fixture artifact version;
- `id` and `capability`: stable test identity and engine surface;
- `input`: actor, ruleset identity, validated canonical logical map, complete
  `GameStateDto`, and one `ReplayCommandDto`;
- `expected`: acceptance/rejection, complete returned `GameStateDto`, ordered
  `ReplayEventDto` values, and optional `ReplayEvidenceDto`.

Fixtures never contain another state envelope, save metadata, wall-clock values,
duplicated ticks, omission defaults, aliases, or generated expected output.

The corpus contains 44 reviewed movement and unit-action cases. Invalid aggregate
state is covered in `../canonical_state_rejections/`, because it cannot reach
command dispatch.
