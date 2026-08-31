# Multiplayer release smoke and failure drills

Use these checks for changes to game networking, persistence, authentication,
or engine command execution.

## Automated gate

```sh
make server-integration-test
```

The command creates an isolated PostgreSQL Compose project on a random loopback
port, creates a fresh test database, applies the initial schema, runs the
server smoke tests serially, and removes its container and volume. Run the
public HTTP journey from [critical-e2e.md](critical-e2e.md) against the local
Compose stack.

## Manual two-account checks

- create a match with one account and join it with the other;
- verify that `listMatches` exposes only matches in which the account
  participates;
- submit a command and verify that each account receives its own Rust-produced
  projection;
- retry the same command id and payload and verify that the stored outcome is
  returned without a second event;
- reuse the command id with a different payload and verify that it is rejected;
- request `resync` from both accounts and verify monotonic offsets with no
  private opponent state leakage.

## Restart drill

1. Create a match, join it, and persist at least one accepted command.
2. Stop the API process after the command response is committed.
3. Start the same server artifact against the existing database.
4. Refresh authentication if necessary and request `resync` from both accounts.
5. Verify exact state revisions, event offsets, recipient isolation, and command
   idempotency after restart.

## Contention drill

Send concurrent submissions for the same match revision from two authenticated
participants. Exactly one database transaction may advance the canonical state;
the other must observe a stale revision or the stored idempotent result. A
native-runtime error or transaction failure must leave canonical state, events,
command ledger, and recipient snapshots unchanged.

## Alerts

Starter Prometheus rules live in `deploy/prometheus/aonw-alerts.yml` and cover
API liveness and readiness probes.

The file is not a deployed monitoring system. Alerts are operational only after
Prometheus, a blackbox probe, Alertmanager, and a tested notification route are
configured. Record a successful synthetic alert before treating this as a
production control.
