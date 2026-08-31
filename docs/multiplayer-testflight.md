# Multiplayer staging and TestFlight checklist

A store build must use a shared HTTPS API. Local platform defaults point to the
development server and are not suitable for TestFlight.

From `clients/aonw_flutter/`:

```sh
flutter build ipa --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

## Required services

- Serverpod API reachable over HTTPS;
- PostgreSQL and Redis reachable from Serverpod;
- the initial schema applied before the application starts;
- strong service, JWT, refresh-token, email-hash, database, and Redis secrets;
- reverse proxy forwarding the Serverpod HTTP API;
- the same engine, protocol, map, and ruleset artifacts on every API instance.

Keep all Serverpod ports private. The reverse proxy must replace untrusted
client-IP headers with one validated address before forwarding them to
authentication rate limiting.

## Local rehearsal

```sh
cp .env.example .env
make server-integration-test
make local-start
```

The local web origin is `http://localhost:7357`; the API is
`http://localhost:8080`.

## Staging

Use the staging overlay; it fixes the Serverpod run mode and must not be
replaced by a value in `.env`.

```env
SERVERPOD_SERVER_ID=staging
SERVERPOD_API_SERVER_PUBLIC_HOST=api.aonw.net
SERVERPOD_API_SERVER_PUBLIC_PORT=443
SERVERPOD_API_SERVER_PUBLIC_SCHEME=https
SERVERPOD_WEB_SERVER_PUBLIC_HOST=api.aonw.net
SERVERPOD_WEB_SERVER_PUBLIC_PORT=443
SERVERPOD_WEB_SERVER_PUBLIC_SCHEME=https
```

```sh
docker compose -f compose.yml -f compose.staging.yml --profile staging up -d --build

curl -fsS https://api.aonw.net/startupz
curl -fsS https://api.aonw.net/livez
curl -fsS https://api.aonw.net/readyz
```

For a production-like single host, use the production overlay. An external
PostgreSQL or Redis service needs an explicit deployment override that removes
the bundled service and its `depends_on`; selecting fewer services on the
command line is not enough.

```sh
docker compose -f compose.yml -f compose.prod.yml --profile prod up -d --build
```

## Two-device acceptance

Run from two fresh installs or two independent accounts:

1. Authenticate both accounts and verify refresh-token rotation.
2. Create a match on one device, join it on the other, and confirm both private
   recipient snapshots.
3. Submit a command and verify the expected state revision and event offset on
   both devices.
4. Retry the accepted command with the same id and verify that no duplicate
   event is stored or rendered.
5. Reuse the command id with another payload and verify a deterministic
   rejection.
6. Interrupt one request, return to the app, and verify `resync` convergence.
7. Restart the API and repeat resync from both devices.
8. Verify that neither account receives hidden units, commands, routes, or
   coordinates belonging only to the other recipient.

The detailed failure drills are in
[multiplayer-chaos-alerts.md](multiplayer-chaos-alerts.md). The protocol contract
is in [multiplayer-protocol.md](multiplayer-protocol.md).
