import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:test/test.dart';

import 'integration_database_cleanup.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'EmailIdpEndpoint concurrency',
    (sessionBuilder, endpoints) {
      tearDown(() async {
        await clearAonwAuthRateLimitAttempts(sessionBuilder.build());
      });

      test('maps a concurrent email conflict to account_exists', () async {
        _ensureAuthServices();
        final results = await Future.wait([
          _capture(
            endpoints.emailIdp.createAccount(
              sessionBuilder,
              email: 'race@example.test',
              password: 'long-password',
              displayName: 'Race One',
            ),
          ),
          _capture(
            endpoints.emailIdp.createAccount(
              sessionBuilder,
              email: 'race@example.test',
              password: 'long-password',
              displayName: 'Race Two',
            ),
          ),
        ]);

        expect(results.whereType<auth_core.AuthSuccess>(), hasLength(1));
        expect(
          results.whereType<AccountAuthException>().single.code,
          'account_exists',
        );
      });

      test(
        'maps a concurrent nickname conflict to display_name_taken',
        () async {
          _ensureAuthServices();
          final results = await Future.wait([
            _capture(
              endpoints.emailIdp.createAccount(
                sessionBuilder,
                email: 'nickname-one@example.test',
                password: 'long-password',
                displayName: 'Shared Nickname',
              ),
            ),
            _capture(
              endpoints.emailIdp.createAccount(
                sessionBuilder,
                email: 'nickname-two@example.test',
                password: 'long-password',
                displayName: 'Shared Nickname',
              ),
            ),
          ]);

          expect(results.whereType<auth_core.AuthSuccess>(), hasLength(1));
          expect(
            results.whereType<AccountAuthException>().single.code,
            'display_name_taken',
          );
        },
      );

      test('persists account creation limits across calls', () async {
        _ensureAuthServices();
        final results = <Object>[];
        for (var attempt = 0; attempt < 4; attempt += 1) {
          results.add(
            await _capture(
              endpoints.emailIdp.createAccount(
                sessionBuilder,
                email: 'limited@example.test',
                password: 'long-password',
                displayName: 'Limited $attempt',
              ),
            ),
          );
        }

        expect(results.first, isA<auth_core.AuthSuccess>());
        expect(
          results.whereType<AccountAuthException>().map((error) => error.code),
          ['account_exists', 'account_exists', 'rate_limited'],
        );
      });
    },
    // Conflict tests intentionally overlap database transactions. The smoke
    // runner recreates the test database before every integration run.
    rollbackDatabase: RollbackDatabase.disabled,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

Future<Object> _capture(Future<Object> operation) async {
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
