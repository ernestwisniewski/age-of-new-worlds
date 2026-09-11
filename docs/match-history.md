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

History includes `replayAvailable` when the completed match retains all required
checkpoint fields. Older matches without those fields remain visible in history.

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
libraries before the new replay symbol is used; the client protocol is now version 25. The C ABI
uses the existing bounded buffers, immutable world borrow and owned response
lifetime, with null-world and Dart artifact round-trip coverage. No new file is
allowed to contain unsafe code.

`game.replayFrame(matchId, position)` and `game.replayQuery(request, position)`
authorize durable account membership on each read, including resigned and kicked
participants. Lobby/running matches, missing checkpoints, departed lobby seats,
and positions outside the journal fail closed. The caller cannot choose another
recipient. These endpoints do not restore command or gameplay-resync access.

Before returning any position, the reader traverses the complete journal in
bounded SQL/native batches. It validates the total row count, final revision,
event offset, persisted recipient digest, and final canonical state against
Rust. An invalid later command therefore also blocks opening position zero.
Only the selected frame's snapshot and filtered command enter `frameJson`;
canonical continuations and other recipients stay server-side. Queries use the
same verified historical state through the existing Rust query dispatcher.

The reader currently performs full verification on every frame/query request
and retains no canonical cache. Memory is bounded by checkpoint/selected/current
states and one journal page; latency grows with archive length. The integration
suite covers 261 accepted transitions and seeks on both sides of the 256-step
boundary, private reads for both participants, historical city planning,
corrupted evidence, unavailable older matches, and account isolation. Long-archive
performance review remains open.


Load Game offers replay for available history entries. Opening pins the account,
match, recipient and content hashes, then initializes the same engine gateway,
map renderer, queries and playback controller used by local replay. The transport
accepts only snapshot, seek and historical queries. A single forward step retains
command feedback; repeated positions and jumps clear it. Snapshot reads reuse
the validated current frame without another network request.

Account changes clear the replay presentation and invalidate both cached reads
and in-flight responses. Network authentication is captured per replay transport;
a later token rotation invalidates that transport. Old callbacks cannot navigate
the new account into a replay. Failures remain visible through the shared replay
error state. Online replay does not expose a canonical export.

Coverage includes transport identity/bounds/continuity, historical queries,
account changes during opening and navigation, shared playback, and a native Rust
replay round-trip with identical final digest. The native Flutter test uses Rust
behind a transport fixture; the separate PostgreSQL suite covers the real server
reader. Three reviewed history goldens cover phone, tablet and desktop. The full
Flutter gate passes 1140 tests, analysis and existing architecture budgets.
