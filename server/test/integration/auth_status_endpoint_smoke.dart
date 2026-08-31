import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:test/test.dart';

import 'integration_database_cleanup.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'AuthStatusEndpoint',
    (sessionBuilder, endpoints) {
      tearDown(() async {
        await clearAonwAuthRateLimitAttempts(sessionBuilder.build());
      });

      test(
        'revokes only the session represented by the refresh token',
        () async {
          _ensureAuthServices();
          final firstSession = await endpoints.emailIdp.createAccount(
            sessionBuilder,
            email: 'logout@example.test',
            password: 'long-password',
            displayName: 'Logout Tester',
          );
          final secondSession = await endpoints.emailIdp.login(
            sessionBuilder,
            email: 'logout@example.test',
            password: 'long-password',
          );
          expect(firstSession.refreshToken, isNotNull);
          expect(secondSession.refreshToken, isNotNull);
          expect(secondSession.refreshToken, isNot(firstSession.refreshToken));

          await endpoints.authStatus.signOutRefreshToken(
            sessionBuilder,
            refreshToken: firstSession.refreshToken!,
          );

          await expectLater(
            endpoints.jwtRefresh.refreshAccessToken(
              sessionBuilder,
              refreshToken: firstSession.refreshToken!,
            ),
            throwsA(isA<auth_core.RefreshTokenNotFoundException>()),
          );
          final rotatedSecondSession = await endpoints.jwtRefresh
              .refreshAccessToken(
                sessionBuilder,
                refreshToken: secondSession.refreshToken!,
              );
          expect(rotatedSecondSession.authUserId, firstSession.authUserId);
        },
      );

      test('serializes concurrent refresh-token rotation', () async {
        _ensureAuthServices();
        final session = await endpoints.emailIdp.createAccount(
          sessionBuilder,
          email: 'refresh-race@example.test',
          password: 'long-password',
          displayName: 'Refresh Race',
        );
        final refreshToken = session.refreshToken!;

        final results = await Future.wait([
          _captureRefresh(
            endpoints.jwtRefresh.refreshAccessToken(
              sessionBuilder,
              refreshToken: refreshToken,
            ),
          ),
          _captureRefresh(
            endpoints.jwtRefresh.refreshAccessToken(
              sessionBuilder,
              refreshToken: refreshToken,
            ),
          ),
        ]);

        final winner = results.whereType<auth_core.AuthSuccess>().single;
        expect(
          results.whereType<auth_core.RefreshTokenInvalidSecretException>(),
          hasLength(1),
        );
        final next = await endpoints.jwtRefresh.refreshAccessToken(
          sessionBuilder,
          refreshToken: winner.refreshToken!,
        );
        expect(next.authUserId, session.authUserId);
      });
    },
    // Refresh rotation intentionally overlaps database transactions. The
    // smoke runner recreates the test database before every integration run.
    rollbackDatabase: RollbackDatabase.disabled,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

Future<Object> _captureRefresh(Future<Object> operation) async {
  try {
    return await operation;
  } catch (error) {
    return error;
  }
}

void _ensureAuthServices() {
  try {
    auth_core.AuthServices.instance;
  } on StateError {
    auth_core.AuthServices.set(
      tokenManagerBuilders: [auth_core.JwtConfigFromPasswords()],
    );
  }
}
