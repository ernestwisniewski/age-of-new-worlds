# Critical end-to-end journeys

Unit tests are complemented by two real-boundary journeys.

| Journey | Boundary | Command |
| --- | --- | --- |
| Native local client | Flutter integration runner, packaged Native Assets engine, production composition, and secure storage | `make flutter-client-device-test` |
| Public multiplayer | Serverpod authentication, PostgreSQL transactions, generated client, idempotent engine command, reconnect, and recipient resync | `make server-integration-test` |

The local integration test is
`clients/aonw_flutter/integration_test/inspect_map_native_test.dart`. It loads
the packaged native artifact rather than a fake Dart gateway.

Server integration tests run serially with the integration profile and exercise
the database-backed host. For a running local product journey, OrbStack or
Docker Desktop must be available:

```sh
make local-start
make local-multiplayer-smoke
make local-down
```

`local-multiplayer-smoke` invokes
`packages/aonw_server_client/tool/critical_e2e.dart` against the public local
API. The actor comes from the authenticated session; retries preserve command
idempotency and recipient projections remain private.

## Failure ownership

- native local failure: artifact loading, session creation, projection, secure
  storage, or command dispatch;
- auth or HTTP failure: Serverpod session boundary;
- command outcome/history mismatch: transaction or idempotency layer;
- reconnect/resync mismatch: recipient projection, catch-up, or token rotation.

Keep focused unit tests for narrow behavior, but retain these journeys at the
real native, persistence, and transport boundaries.
