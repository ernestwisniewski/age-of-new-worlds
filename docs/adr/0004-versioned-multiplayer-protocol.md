# ADR 0004: Versioned Multiplayer Protocol

- Status: Accepted
- Date: 2026-07-12
- Implementation: Implemented

## Context

Player-visible multiplayer behavior, transient peer envelopes, and durable stored snapshots evolve on different schedules. One version number either blocks safe additive rollout or hides incompatible storage changes.

## Decision

Multiplayer has three independent compatibility axes:

| Constant | Owns |
| --- | --- |
| `kCurrentMultiplayerVersion` | Functional online behavior: rules, projection, ordering, retry, matchmaking, and transport semantics. |
| `kProtocolVersion` | Transient command, ACK, and match envelope schema. |
| `kSnapshotEventVersion` | Durable snapshot and event schema. |

```mermaid
flowchart TB
  Change["Multiplayer change"] --> Functional["Functional revision"]
  Change --> Wire{"Transient envelope changed?"}
  Change --> Durable{"Stored snapshot/event changed?"}
  Wire -- yes --> Protocol["Command / ACK / match schema"]
  Wire -- no --> KeepProtocol["Keep transient schema"]
  Durable -- yes --> Snapshot["Snapshot / event schema"]
  Durable -- no --> KeepSnapshot["Keep durable schema"]
  Functional --> Readers["Deploy compatible readers and status-aware server first"]
  Protocol --> Readers
  KeepProtocol --> Readers
  Snapshot --> Readers
  KeepSnapshot --> Readers
  Readers --> Client["Require the new client revision only after rollout is safe"]
```

Current values are defined by the generated Serverpod protocol and shared
engine contracts. Each independently deployed consumer advertises the exact
versions it supports.

The binding rules are:

- every multiplayer behavior change increments the functional revision, even when JSON remains additive;
- older functional revisions stay accepted only when fixture-tested as safe;
- each envelope carries its own schema version and fails closed for missing, malformed, future, or retired values;
- supporting an older schema requires an explicit bounded reader/upcaster and, when needed, peer-specific encoder;
- functional compatibility never weakens fog, audience filtering, offset order, or command idempotency;
- save schema and multiplayer schemas remain independent;
- shared DTOs and compatibility constants are owned by the active protocol
  boundary and must remain consistent across the engine, server, and generated
  client;
- generated Serverpod output changes in the same commit as its source model or endpoint.

## Rollout

For every multiplayer change:

1. increment the functional revision;
2. classify each previously accepted revision as compatible or not;
3. bump only the incompatible envelope family;
4. add status, codec, retry, reconnect, projection, and rollout fixtures;
5. deploy the status-aware server before requiring the new client;
6. retain stored matches only when their schema and semantics remain readable or have an explicit conversion plan.

Readers precede writers. A durable writer is enabled only with a backup and a rollback/forward-fix plan for older servers.

## Consequences

Compatible releases can roll out without making wire and storage conversion implicit. The cost is explicit review of compatibility on every online change.

## Verification

Contract tests cover current, removed, undeclared, and future functional
revisions; strict wire readers; command retry; recipient projection; reconnect;
and generated-code drift.

See [multiplayer-protocol.md](../multiplayer-protocol.md) for the active runtime contract.

## Related Decisions And Documentation

- [Multiplayer protocol](../multiplayer-protocol.md)
- [Multiplayer scale-out](../multiplayer-scale-out.md)
- [ADR 0003: Command boundaries](0003-command-boundaries.md)
- [ADR 0008: Engine ownership](0008-engine-ownership.md)

## Rejected alternatives:

- Using one version number for functional behavior, transient envelopes, and durable state.
- Accepting every older client revision without compatibility fixtures.
- Enabling a new durable writer before compatible readers and a rollback plan are deployed.
