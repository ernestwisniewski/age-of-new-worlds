# Lobby participant identity

The waiting room displays the country and ARGB color of each canonical match
participant. Serverpod reads both fields from the Rust-validated match roster;
claiming or releasing a human seat changes its occupancy, not its civilization.
The client rejects unknown countries and colors outside the unsigned ARGB range.

The participant row uses the reference dark surface, gold border, colored avatar,
and localized country. At narrow widths or large text, readiness moves below the
name and country. All rows remain inside the scrolling waiting-room panel.

Validation:

- Server and generated client: 115 and 1 tests, analyzers passed.
- Isolated PostgreSQL integration: 24 tests passed, including country/color after
  seat release and reclaim and the existing host-transfer/start flows.
- Flutter waiting room, application, and router: 55 tests passed; six languages,
  both phone orientations at 200%, and four reviewed phone/tablet/desktop goldens.
- Generated-code synchronization and unchanged architecture budgets passed.

Connection presence is still separate work. A claimed seat is not evidence that
its player currently has a live connection. The UI does not invent that status.
