import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:aonw_server/src/auth/steam_auth_service.dart';
import 'package:aonw_server/src/auth/steam_open_id_verifier.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:test/test.dart';

import '../support/fake_database.dart';

part 'steam_auth_service_test_support.dart';

void main() {
  late Serverpod pod;

  setUpAll(() {
    _ensureAuthServices();
    pod = Serverpod(
      const [],
      Protocol(),
      _EmptyEndpoints(),
      config: ServerpodConfig(apiServer: _serverConfig('api.example', 8443)),
    );
  });
  tearDownAll(() => pod.shutdown(exitProcess: false));

  late FakeDatabase database;
  late FakeSession session;
  late SteamAuthService service;

  setUp(() {
    database = FakeDatabase();
    session = FakeSession(database);
    service = SteamAuthService(
      openIdVerifier: const _AcceptingVerifier(),
      rateLimiter: const _NoopRateLimiter(),
      publicWebBaseUri: _publicBaseUri,
    );
  });

  test('starts against the configured public origin', () async {
    final started = await service.start(session);
    final authUri = Uri.parse(started.authUrl);
    final inserted = database.callsFor('insertRow').single.rows.single;

    expect(started.requestId, hasLength(43));
    expect(authUri.queryParameters['openid.realm'], 'https://auth.example/');
    expect(
      authUri.queryParameters['openid.return_to'],
      'https://auth.example/auth/steam/callback?requestId=${started.requestId}',
    );
    expect(inserted, isA<SteamAuthRequest>());
    expect((inserted as SteamAuthRequest).status, 'pending');
  });

  test('uses Serverpod public config with default dependencies', () async {
    expect(SteamAuthService(), isA<SteamAuthService>());
    final configuredService = SteamAuthService(
      openIdVerifier: const _AcceptingVerifier(),
      rateLimiter: const _NoopRateLimiter(),
    );

    final started = await configuredService.start(session);
    final authUri = Uri.parse(started.authUrl);

    expect(
      authUri.queryParameters['openid.realm'],
      'https://api.example:8443/',
    );
    expect(
      authUri.queryParameters['openid.return_to'],
      startsWith('https://api.example:8443/auth/steam/callback?requestId='),
    );
  });

  test('rejects an invalid poll request before database access', () async {
    final result = await service.poll(session, requestId: 'invalid');

    expect(result.status, 'failed');
    expect(result.error, 'not_found');
    expect(database.calls, isEmpty);
  });

  test('poll reports a missing request', () async {
    database.queueFindFirst<SteamAuthRequest>(null);

    final result = await service.poll(session, requestId: _requestId);

    expect(result.status, 'failed');
    expect(result.error, 'not_found');
  });

  test('poll expires an unfinished request', () async {
    database.queueFindFirst<SteamAuthRequest>(
      _pendingRequest(
        expiresAt: DateTime.now().toUtc().subtract(_second),
      ).copyWith(error: 'timeout'),
    );

    final result = await service.poll(session, requestId: _requestId);

    expect(result.status, 'expired');
    expect(result.error, 'timeout');
    expect(
      (database.callsFor('updateRow').single.rows.single as SteamAuthRequest)
          .status,
      'expired',
    );
  });

  test(
    'poll consumes a completed request and returns its auth token',
    () async {
      final authUserId = UuidValue.fromString(
        '10000000-0000-0000-0000-000000000010',
      );
      database.queueFindFirst<SteamAuthRequest>(
        _pendingRequest(status: 'completed').copyWith(authUserId: authUserId),
      );

      final result = await service.poll(session, requestId: _requestId);

      expect(result.status, 'authenticated');
      expect(result.auth?.authUserId, authUserId);
      expect(
        (database.callsFor('updateRow').single.rows.single as SteamAuthRequest)
            .status,
        'consumed',
      );
    },
  );

  test('poll preserves a non-terminal status', () async {
    database.queueFindFirst<SteamAuthRequest>(
      _pendingRequest(status: 'failed').copyWith(error: 'cancelled'),
    );

    final result = await service.poll(session, requestId: _requestId);

    expect(result.status, 'failed');
    expect(result.error, 'cancelled');
  });

  test('completes a callback with an existing Steam account', () async {
    final accountId = UuidValue.fromString(
      '10000000-0000-0000-0000-000000000001',
    );
    _queueCallbackRequest(database);
    database
      ..queueFindFirst<SteamAuthRequest>(_pendingRequest())
      ..queueFindFirst<SteamAccount>(
        SteamAccount(
          steamId: _steamId,
          authUserId: accountId,
          lastSeenAt: DateTime.utc(2026),
        ),
      );

    final result = await service.handleCallback(session, _callbackUri());

    expect(result.success, isTrue);
    final updates = database.callsFor('updateRow').toList();
    expect(updates, hasLength(2));
    expect(
      (updates.last.rows.single as SteamAuthRequest).authUserId,
      accountId,
    );
  });

  test('creates the auth user, profile, and Steam account once', () async {
    final authUserId = UuidValue.fromString(
      '10000000-0000-0000-0000-000000000002',
    );
    _queueCallbackRequest(database);
    database
      ..queueFindFirst<SteamAuthRequest>(_pendingRequest())
      ..queueFindFirst<SteamAccount>(null)
      ..queueInsertRow<auth_core.AuthUser>(
        auth_core.AuthUser(id: authUserId, scopeNames: const {}),
      )
      ..queueInsertRow<auth_core.UserProfile>(
        auth_core.UserProfile(
          id: UuidValue.fromString('20000000-0000-0000-0000-000000000002'),
          authUserId: authUserId,
          userName: 'Steam 4567',
          fullName: 'Steam 4567',
        ),
      );

    final result = await service.handleCallback(session, _callbackUri());

    expect(result.success, isTrue);
    final insertedRows = database
        .callsFor('insertRow')
        .expand((call) => call.rows);
    expect(insertedRows.whereType<auth_core.AuthUser>(), hasLength(1));
    expect(
      insertedRows.whereType<auth_core.UserProfile>().single.userName,
      'Steam 4567',
    );
    expect(
      insertedRows.whereType<SteamAccount>().single.authUserId,
      authUserId,
    );
  });

  test('reports expiry detected while committing the callback', () async {
    _queueCallbackRequest(database);
    database.queueFindFirst<SteamAuthRequest>(
      _pendingRequest(expiresAt: DateTime.now().toUtc().subtract(_second)),
    );

    final result = await service.handleCallback(session, _callbackUri());

    expect(result.success, isFalse);
    expect(result.title, 'Steam sign-in expired');
    expect(
      (database.callsFor('updateRow').single.rows.single as SteamAuthRequest)
          .status,
      'expired',
    );
  });

  test('accepts a callback completed by a concurrent request', () async {
    _queueCallbackRequest(database);
    database.queueFindFirst<SteamAuthRequest>(
      _pendingRequest(status: 'completed'),
    );

    final result = await service.handleCallback(session, _callbackUri());

    expect(result.success, isTrue);
    expect(database.callsFor('updateRow'), isEmpty);
  });

  test('rejects callback when the locked request disappeared', () async {
    _queueCallbackRequest(database);
    database.queueFindFirst<SteamAuthRequest>(null);

    final result = await service.handleCallback(session, _callbackUri());

    expect(result.success, isFalse);
    expect(result.title, 'Steam sign-in failed');
  });

  test('marks a pending request failed for an invalid callback mode', () async {
    _queueCallbackRequest(database);
    database.queueFindFirst<SteamAuthRequest>(_pendingRequest());

    final result = await service.handleCallback(
      session,
      _callbackUri(mode: 'cancel'),
    );

    expect(result.success, isFalse);
    expect(
      (database.callsFor('updateRow').single.rows.single as SteamAuthRequest)
          .error,
      'cancelled',
    );
  });

  test('rejects a callback without a valid request id', () async {
    final missing = await service.handleCallback(
      session,
      Uri.parse('https://auth.example/auth/steam/callback'),
    );
    final invalid = await service.handleCallback(
      session,
      Uri.parse('https://auth.example/auth/steam/callback?requestId=bad'),
    );

    expect(missing.message, 'Invalid authentication request id.');
    expect(invalid.message, 'Invalid authentication request id.');
  });

  test(
    'maps callback rate limiting and rethrows unrelated auth errors',
    () async {
      final limited = SteamAuthService(
        openIdVerifier: const _AcceptingVerifier(),
        rateLimiter: const _ThrowingRateLimiter('rate_limited'),
        publicWebBaseUri: _publicBaseUri,
      );
      final broken = SteamAuthService(
        openIdVerifier: const _AcceptingVerifier(),
        rateLimiter: const _ThrowingRateLimiter('backend_error'),
        publicWebBaseUri: _publicBaseUri,
      );

      final result = await limited.handleCallback(session, _callbackUri());

      expect(result.title, 'Too many Steam sign-in attempts');
      await expectLater(
        broken.handleCallback(session, _callbackUri()),
        throwsA(
          isA<AccountAuthException>().having(
            (error) => error.code,
            'code',
            'backend_error',
          ),
        ),
      );
    },
  );

  test('rejects a callback for an unknown request', () async {
    database.queueFindFirst<SteamAuthRequest>(null);

    final result = await service.handleCallback(session, _callbackUri());

    expect(result.message, 'The authentication request was not found.');
  });

  test('returns the stored outcome for a non-pending callback', () async {
    database.queueFindFirst<SteamAuthRequest>(
      _pendingRequest(status: 'completed'),
    );
    final completed = await service.handleCallback(session, _callbackUri());
    database.queueFindFirst<SteamAuthRequest>(
      _pendingRequest(status: 'failed'),
    );
    final failed = await service.handleCallback(session, _callbackUri());

    expect(completed.success, isTrue);
    expect(failed.success, isFalse);
  });

  test('expires a callback before OpenID verification', () async {
    database
      ..queueFindFirst<SteamAuthRequest>(
        _pendingRequest(expiresAt: DateTime.now().toUtc().subtract(_second)),
      )
      ..queueFindFirst<SteamAuthRequest>(_pendingRequest());

    final result = await service.handleCallback(session, _callbackUri());

    expect(result.title, 'Steam sign-in expired');
    expect(
      (database.callsFor('updateRow').single.rows.single as SteamAuthRequest)
          .error,
      'expired',
    );
  });

  test('rejects a callback with the wrong return target', () async {
    _queueCallbackRequest(database);
    database.queueFindFirst<SteamAuthRequest>(_pendingRequest());
    final callback = _callbackUri().replace(
      queryParameters: {
        ..._callbackUri().queryParameters,
        'openid.return_to': 'not a uri',
      },
    );

    final result = await service.handleCallback(session, callback);

    expect(result.message, 'Steam returned an invalid sign-in target.');
  });

  test('rejects a callback without a valid Steam identity', () async {
    _queueCallbackRequest(database);
    database.queueFindFirst<SteamAuthRequest>(_pendingRequest());
    final callback = _callbackUri().replace(
      queryParameters: {
        ..._callbackUri().queryParameters,
        'openid.claimed_id': 'invalid',
        'openid.identity': 'invalid',
      },
    );

    final result = await service.handleCallback(session, callback);

    expect(result.message, 'Steam did not return a valid Steam ID.');
  });

  test('rejects and logs an invalid Steam signature', () async {
    final rejecting = SteamAuthService(
      openIdVerifier: const _RejectingVerifier(),
      rateLimiter: const _NoopRateLimiter(),
      publicWebBaseUri: _publicBaseUri,
    );
    _queueCallbackRequest(database);
    database.queueFindFirst<SteamAuthRequest>(_pendingRequest());

    final result = await rejecting.handleCallback(session, _callbackUri());

    expect(result.message, 'Steam could not validate this sign-in response.');
    expect(
      (database.callsFor('updateRow').single.rows.single as SteamAuthRequest)
          .error,
      'invalid_signature',
    );
  });

  test('retries the account uniqueness race', () async {
    final authUserId = UuidValue.fromString(
      '10000000-0000-0000-0000-000000000003',
    );
    _queueCallbackRequest(database);
    database
      ..queueTransactionError(
        FakeDatabaseQueryException(
          code: '23505',
          constraintName: 'aonw_steam_account_steam_id_idx',
        ),
      )
      ..queueFindFirst<SteamAuthRequest>(_pendingRequest())
      ..queueFindFirst<SteamAccount>(
        SteamAccount(
          steamId: _steamId,
          authUserId: authUserId,
          lastSeenAt: DateTime.utc(2026),
        ),
      );

    final result = await service.handleCallback(session, _callbackUri());

    expect(result.success, isTrue);
    expect(database.callsFor('transaction'), hasLength(2));
  });

  test('does not swallow unrelated database failures', () async {
    _queueCallbackRequest(database);
    database.queueTransactionError(
      FakeDatabaseQueryException(code: '40001', constraintName: 'other'),
    );

    await expectLater(
      service.handleCallback(session, _callbackUri()),
      throwsA(isA<DatabaseQueryException>()),
    );
  });
}
