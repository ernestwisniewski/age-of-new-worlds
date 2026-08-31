import 'dart:typed_data';

import 'package:aonw_server/src/auth/auth_maintenance_serverpod_store.dart';
import 'package:aonw_server/src/auth/auth_maintenance_service.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/scheduling/reconciled_future_call_scheduler.dart';
import 'package:serverpod/protocol.dart' show FutureCallEntry;
import 'package:serverpod/serverpod.dart' show Session, UuidValue;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/core.dart' as auth_idp;
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'AuthMaintenanceService',
    (sessionBuilder, _) {
      test('deletes only retained, expired rows in bounded batches', () async {
        final session = sessionBuilder.build();
        final now = DateTime.utc(2026, 7, 10, 12);
        const refreshLifetime = Duration(days: 14);
        await _seedMaintenanceRows(
          session,
          now: now,
          refreshLifetime: refreshLifetime,
        );

        final result =
            await const AuthMaintenanceService(
              batchSize: 2,
              maxBatchesPerTable: 3,
            ).run(
              store: ServerpodAuthMaintenanceStore(session),
              now: now,
              refreshTokenLifetime: refreshLifetime,
            );

        expect(result.deletedRefreshTokens, 3);
        expect(result.deletedSteamAuthRequests, 3);
        expect(result.deletedExternalAuthRequests, 3);
        expect(result.deletedRateLimitAttempts, 3);
        expect(result.failures, isEmpty);
        expect(await auth_core.RefreshToken.db.count(session), 1);
        expect(await SteamAuthRequest.db.count(session), 1);
        expect(await ExternalAuthRequest.db.count(session), 1);
        expect(
          await auth_idp.RateLimitedRequestAttempt.db.count(
            session,
            where: (table) => table.domain.equals(aonwAuthRateLimitDomain),
          ),
          1,
        );
        expect(
          await auth_idp.RateLimitedRequestAttempt.db.count(
            session,
            where: (table) => table.domain.equals('another_auth_provider'),
          ),
          1,
        );
      });

      test('reconciles duplicate schedules and accelerates in place', () async {
        const identifier = 'auth-maintenance-integration-test';
        const scheduler = ReconciledFutureCallScheduler(
          callName: 'authMaintenance',
          identifier: identifier,
          lockName: 'auth_maintenance_integration_test',
        );
        final session = sessionBuilder.build();
        final now = DateTime.utc(2026, 7, 10, 12);
        await scheduler.scheduleNoLaterThan(
          session,
          serverId: 'test-server',
          notAfter: now.add(const Duration(hours: 6)),
        );
        await FutureCallEntry.db.insertRow(
          session,
          FutureCallEntry(
            name: 'authMaintenance',
            time: now.add(const Duration(hours: 8)),
            serverId: 'test-server',
            identifier: identifier,
          ),
        );

        final accelerated = await scheduler.scheduleNoLaterThan(
          session,
          serverId: 'test-server',
          notAfter: now.add(const Duration(minutes: 1)),
        );
        final entries = await FutureCallEntry.db.find(
          session,
          where: (table) => table.identifier.equals(identifier),
        );

        expect(accelerated.accelerated, isTrue);
        expect(accelerated.duplicatesRemoved, 1);
        expect(entries, hasLength(1));
        expect(entries.single.time, now.add(const Duration(minutes: 1)));
      });
    },
    rollbackDatabase: RollbackDatabase.afterEach,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

Future<void> _seedMaintenanceRows(
  Session session, {
  required DateTime now,
  required Duration refreshLifetime,
}) async {
  final oldRefreshTimestamp = now
      .subtract(refreshLifetime)
      .subtract(expiredRefreshTokenRetention)
      .subtract(const Duration(days: 1));
  final retainedRefreshTimestamp = now
      .subtract(refreshLifetime)
      .subtract(expiredRefreshTokenRetention);
  final oldExpiry = now
      .subtract(expiredSteamAuthRequestRetention)
      .subtract(const Duration(days: 1));
  final retainedExpiry = now.subtract(expiredSteamAuthRequestRetention);
  final oldExternalExpiry = now
      .subtract(expiredExternalAuthRequestRetention)
      .subtract(const Duration(days: 1));
  final retainedExternalExpiry = now.subtract(
    expiredExternalAuthRequestRetention,
  );
  final oldAttempt = now
      .subtract(expiredAuthRateLimitAttemptRetention)
      .subtract(const Duration(days: 1));
  final retainedAttempt = now.subtract(expiredAuthRateLimitAttemptRetention);

  final authUser = await auth_core.AuthUser.db.insertRow(
    session,
    auth_core.AuthUser(scopeNames: const <String>{}),
  );
  await auth_core.RefreshToken.db.insert(session, [
    for (var index = 0; index < 3; index += 1)
      _refreshToken(
        authUserId: authUser.id!,
        lastUpdatedAt: oldRefreshTimestamp,
      ),
    _refreshToken(
      authUserId: authUser.id!,
      lastUpdatedAt: retainedRefreshTimestamp,
    ),
  ]);
  await SteamAuthRequest.db.insert(session, [
    for (var index = 0; index < 3; index += 1)
      SteamAuthRequest(
        requestId: 'expired-$index',
        status: 'expired',
        expiresAt: oldExpiry,
      ),
    SteamAuthRequest(
      requestId: 'retained',
      status: 'expired',
      expiresAt: retainedExpiry,
    ),
  ]);
  await ExternalAuthRequest.db.insert(session, [
    for (var index = 0; index < 3; index += 1)
      ExternalAuthRequest(
        requestId: 'external-expired-$index',
        state: 'external-expired-state-$index',
        provider: 'apple',
        status: 'expired',
        expiresAt: oldExternalExpiry,
      ),
    ExternalAuthRequest(
      requestId: 'external-retained',
      state: 'external-retained-state',
      provider: 'apple',
      status: 'expired',
      expiresAt: retainedExternalExpiry,
    ),
  ]);
  await auth_idp.RateLimitedRequestAttempt.db.insert(session, [
    for (var index = 0; index < 3; index += 1)
      auth_idp.RateLimitedRequestAttempt(
        domain: aonwAuthRateLimitDomain,
        source: 'login',
        nonce: 'expired-$index',
        attemptedAt: oldAttempt,
      ),
    auth_idp.RateLimitedRequestAttempt(
      domain: aonwAuthRateLimitDomain,
      source: 'login',
      nonce: 'retained',
      attemptedAt: retainedAttempt,
    ),
    auth_idp.RateLimitedRequestAttempt(
      domain: 'another_auth_provider',
      source: 'login',
      nonce: 'foreign-domain',
      attemptedAt: oldAttempt,
    ),
  ]);
}

auth_core.RefreshToken _refreshToken({
  required UuidValue authUserId,
  required DateTime lastUpdatedAt,
}) {
  return auth_core.RefreshToken(
    authUserId: authUserId,
    scopeNames: const <String>{},
    method: 'test',
    fixedSecret: ByteData(16),
    rotatingSecretHash: 'not-used-by-maintenance',
    lastUpdatedAt: lastUpdatedAt,
    createdAt: lastUpdatedAt,
  );
}
