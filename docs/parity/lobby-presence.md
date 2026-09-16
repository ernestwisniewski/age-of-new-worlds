# Lobby presence

The authenticated `game.watchLobby` stream owns one expiring database lease per
subscription. Every two seconds it checks the caller's active membership, renews
the lease for fifteen seconds, and sends a recipient-specific lobby view. Normal
cancellation removes that lease; expiry bounds stale presence after a server
failure. Multiple windows have independent leases. Closing an old window cannot
disconnect a newer one.

Each lease includes the participant row, account identifier and membership join
time. Leaving and reclaiming the same seat invalidates previous leases, including
ones from the same account. Lease rows and relation fields are server-only;
clients receive the public `isConnected` boolean. Presence never changes the Rust
canonical state, revision, event offset, save or replay journal.

Starting a match requires every human seat to be claimed, connected and ready.
The server rechecks this inside the existing locked start transaction. This keeps
the existing readiness requirement and restores the source roster's distinction
between membership and live connections. Computer seats need no network lease.
The source policy is `packages/aonw_core/lib/protocol/lobby_roster_policy.dart` at
reference revision `c6473641e57eb4337218234669c361db01c45d6e`.

The Flutter coordinator starts observation in the waiting room and cancels it
when leaving, signing out, disposing the screen or suspending the application.
Transient failures trigger authenticated retries after 2, 4, 8, 16 and then
30 seconds. Account, match, player and observation generations reject stale
callbacks. A host-start notification opens gameplay only after a fresh resync.
Commands retain their own busy state; the stream does not overwrite a command
response in flight. Invalid recipient data stops automatic retry.

Participant rows show open, connecting, connected, ready, reconnecting or offline
states in six languages. Ready/start actions remain disabled while the local
observation is unavailable. The last known peer roster remains visible.

Validation for this stage:

- 28 isolated PostgreSQL integration cases passed. Presence cases cover access
  control, disconnect/start gating, multiple windows, expiry, reclaimed seats,
  unchanged canonical state and completion after match start. Tests using the
  rollback harness pause subscriptions between requests to avoid concurrent
  queries on its shared test transaction.
- 115 server unit tests and the generated client protocol test passed.
- 114 focused Flutter tests passed, including retries, stale callbacks,
  recipient validation, six languages at 200% and four reviewed waiting-room
  goldens. Architecture budgets remain unchanged.
- The complete Flutter gate passed: 1423 tests, map/asset contracts, dependency
  boundaries, analyzer and unchanged architecture budgets.
- Generated protocol, localizations, test tools and schema were checked for
  reproducibility. Apply migration `20260919155523413-lobby-presence` before
  deploying the matching server and client.

Public browsing, private invitations, quickplay and native multi-device QA remain
separate parity work.
