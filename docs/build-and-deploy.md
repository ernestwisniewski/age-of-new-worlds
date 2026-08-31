# Build and deployment runbook

Run commands from the repository root. The Makefile is the executable contract
for local development, verification, and the supported Compose deployments.
Credentials, signing material, and populated `.env` files do not belong in Git.

## Release verification

Install the pinned dependencies and run the complete qualification gate:

```sh
make bootstrap
make release-check
```

Focused checks are available when iterating:

| Change | Command |
| --- | --- |
| Repository CI | `make ci` |
| Generated Serverpod code | `make generated-code-check` |
| Compose overlays | `make compose-check` |
| Docker build context | `make docker-context-check` |
| Serverpod deployment inputs | `make serverpod-ops-check` |
| PostgreSQL-backed multiplayer | `make server-integration-test` |

When Serverpod generator inputs change, regenerate the output, review it, and
commit the input and generated changes together:

```sh
(cd server && dart pub global run serverpod_cli:serverpod_cli generate)
(cd server && dart pub global run serverpod_cli:serverpod_cli create-migration)
make generated-code-check
```

## Local environment

Create a local environment file and replace every placeholder secret:

```sh
cp .env.example .env
make local-start
make local-multiplayer-smoke
```

The API listens on `http://localhost:8080`. `make local` starts the same stack
and launches the Flutter client on macOS; set `FLUTTER_CLIENT_DEVICE` to choose
another supported device. Stop the stack with:

```sh
make local-down
```

Removing the database volume is a deliberate data reset and is not part of the
normal shutdown procedure.

## Server image and deployment profiles

Build the server image locally with `make docker-build`. Staging and production
must use their matching Compose overlays; the server rejects an absent or mixed
overlay:

```sh
# staging
make up PROFILE=staging
docker compose -f compose.yml -f compose.staging.yml --profile staging up -d --build

# production
make up PROFILE=prod
docker compose -f compose.yml -f compose.prod.yml --profile prod up -d --build
```

The overlays own the Serverpod run mode. Do not place `SERVERPOD_RUN_MODE` in
the root deployment environment file. Keep Serverpod ports private behind
Caddy or another trusted reverse proxy.

The public operational probes are:

- `/startupz` — application startup completed;
- `/livez` — the process is alive;
- `/readyz` — PostgreSQL and Redis are ready.

Use readiness as the deployment gate:

```sh
make health PROFILE=staging HEALTH_URL=https://api.aonw.net/readyz
make health PROFILE=prod HEALTH_URL=https://api.aonw.net/readyz
```

The Docker build context is default-deny. After changing Docker inputs, maps,
migrations, or `.dockerignore`, run `make docker-context-check` instead of
broadening the context.

## Database changes and recovery

Create schema changes with the pinned Serverpod CLI and keep generated code,
the migration registry, and migration SQL in the same reviewed commit. Apply
migrations deliberately with `SERVERPOD_APPLY_MIGRATIONS=true` for the selected
deployment operation.

Back up PostgreSQL before a schema or application release that changes durable
data. The procedures and verification commands are documented in
[postgres-backup.md](postgres-backup.md). Prefer a forward fix when data written
by the running version is not readable by an older version.

Record the source commit, image identity, migration registry state, selected
Compose overlay, and health evidence for every staging and production release.
