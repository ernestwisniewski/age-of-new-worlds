# Completed match history

`game.matchHistory` reads completed matches for the authenticated account using
durable participant membership. Resigned and kicked participants retain access
to these summaries. Active gameplay, lobby, resync and command authorization
remain independent; history does not restore participation.

Each page contains at most 50 entries, ordered by descending participant id
(membership order). `nextBeforeParticipantId` requests older memberships; a
null cursor ends pagination. Both the account predicate and completed-match
predicate apply before the database limit, so active matches cannot hide older
history. A cursor never selects another account's records.

Entries expose the existing match identity, own player id, final turn and result,
completion time, and own resignation/kick time. Canonical state, map documents,
other account identities, kick reasons, command ledgers and recipient snapshots
are not part of the response. The models are transport-only and add no database
schema migration.

The integration test seeds 52 completed own matches, 100 active own matches and
one foreign match. It verifies complete pagination, account isolation, metadata
serialization and unchanged rejection of gameplay resync after resignation.

This endpoint supplies history metadata. Recipient-safe online replay requires
an initial authoritative checkpoint and a separate replay transport.
