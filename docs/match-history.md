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

New matches retain their initial canonical state, its digest and revision, and
the Rust engine behavior fingerprint in server-only fields. The native host
protocol is version 2; its match creation response provides the same fingerprint
used by local Rust saves and replay archives. The fingerprint value is unchanged.

Each accepted command that advances canonical revision adds a server-only
`GameReplayEntry` in the same transaction as state, events and snapshots. It
records the actual player or trusted system command, authenticated player when
applicable, resulting state digest, revision and event offsets. Timeouts retain
their exact participant scope and next-turn timestamp. Rejected/no-op commands
and duplicate delivery do not add steps. A failed replay insert rolls back the
gameplay transaction; the initial checkpoint remains unchanged.

The additive `online-replay` migration follows the existing migration chain.
Earlier matches retain null checkpoint fields; no initial state is fabricated
from a final state. The replay journal is separate from the client idempotency
ledger, so recording timeouts does not alter command retry or statistics logic.

Load Game loads this history when its section is expanded. The Flutter client
retains one page, supports backward/forward navigation and refresh, and preserves
the previous page after a failed request. Each request captures authentication;
account changes discard outstanding responses and remove the previous account's
history. The history view does not offer gameplay resume for completed matches.
