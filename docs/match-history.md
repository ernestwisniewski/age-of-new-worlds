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
protocol is version 3; its match creation response provides the same fingerprint
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

The host replay operation evaluates at most 256 journal transitions per request.
It verifies the behavior fingerprint, immutable content, checkpoint digest,
recipient membership, contiguous revisions, resulting digests, and both event
offsets. Player and trusted system entries use the same command paths as live
execution. A rejection, no-op, missing transition or evidence mismatch fails the
whole batch. A previously verified result can serve as the next checkpoint.

Replay host output contains a canonical continuation for trusted server use and
one recipient-safe snapshot with the last command's filtered events, evidence and
patch. It must never be forwarded wholesale to a client. An empty batch returns
the checkpoint projection with no command. Host API 3 rejects older native
libraries before the new replay symbol is used; Client API remains 24. The C ABI
uses the existing bounded buffers, immutable world borrow and owned response
lifetime, with null-world and Dart artifact round-trip coverage. No new file is
allowed to contain unsafe code.
