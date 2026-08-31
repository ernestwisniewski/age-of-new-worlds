import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:aonw_server/src/auth/external_auth_service.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'ExternalAuthService',
    (sessionBuilder, _) {
      test('completes Apple browser auth and consumes it once', () async {
        final capturedCredentials = <String, String>{};
        final service = _service(
          authenticator: (session, provider, credentials) async {
            expect(provider, ExternalAuthService.appleProvider);
            capturedCredentials.addAll(credentials);
            return _authSuccess(strategy: provider);
          },
        );
        final session = sessionBuilder.build();
        final started = await service.start(
          session,
          provider: ExternalAuthService.appleProvider,
        );
        final authUri = Uri.parse(started.authUrl);
        final state = authUri.queryParameters['state'];

        expect(authUri.host, 'appleid.apple.com');
        expect(authUri.queryParameters['response_mode'], 'form_post');
        expect(
          authUri.queryParameters['redirect_uri'],
          'https://api.example/auth/apple/callback',
        );

        final callback = await service.handleAppleCallback(session, {
          'state': state!,
          'id_token': 'apple-id-token',
          'code': 'apple-code',
          'user': '{"name":{"firstName":"Alice","lastName":"Example"}}',
        });
        final poll = await service.poll(session, requestId: started.requestId);
        final replay = await service.poll(
          session,
          requestId: started.requestId,
        );
        final request = await ExternalAuthRequest.db.findFirstRow(
          session,
          where: (table) => table.requestId.equals(started.requestId),
        );

        expect(callback.success, isTrue);
        expect(capturedCredentials, {
          'identityToken': 'apple-id-token',
          'authorizationCode': 'apple-code',
          'firstName': 'Alice',
          'lastName': 'Example',
        });
        expect(poll.status, 'authenticated');
        expect(poll.auth?.authStrategy, 'apple');
        expect(poll.auth?.refreshToken, 'refresh-token');
        expect(replay.status, 'consumed');
        expect(request?.token, isNull);
        expect(request?.refreshToken, isNull);
      });

      test('exchanges Google code with PKCE before completing auth', () async {
        Map<String, String>? tokenRequest;
        Map<String, String>? authenticatedCredentials;
        final service = _service(
          tokenExchange: (uri, body) async {
            expect(uri.toString(), 'https://oauth2.googleapis.com/token');
            tokenRequest = body;
            return {
              'id_token': 'google-id-token',
              'access_token': 'google-access-token',
            };
          },
          authenticator: (session, provider, credentials) async {
            expect(provider, ExternalAuthService.googleProvider);
            authenticatedCredentials = credentials;
            return _authSuccess(strategy: provider);
          },
        );
        final session = sessionBuilder.build();
        final started = await service.start(
          session,
          provider: ExternalAuthService.googleProvider,
        );
        final authUri = Uri.parse(started.authUrl);

        expect(authUri.host, 'accounts.google.com');
        expect(authUri.queryParameters['code_challenge_method'], 'S256');
        expect(authUri.queryParameters['code_challenge'], isNotEmpty);

        final callback = await service.handleGoogleCallback(session, {
          'state': authUri.queryParameters['state']!,
          'code': 'google-code',
        });
        final poll = await service.poll(session, requestId: started.requestId);

        expect(callback.success, isTrue);
        expect(tokenRequest?['code'], 'google-code');
        expect(tokenRequest?['code_verifier'], isNotEmpty);
        expect(
          tokenRequest?['redirect_uri'],
          'https://api.example/auth/google/callback',
        );
        expect(authenticatedCredentials, {
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        });
        expect(poll.status, 'authenticated');
        expect(poll.auth?.authStrategy, 'google');
      });

      test('rejects a callback state issued for another provider', () async {
        var authenticatorCalls = 0;
        final service = _service(
          authenticator: (session, provider, credentials) async {
            authenticatorCalls += 1;
            return _authSuccess(strategy: provider);
          },
        );
        final session = sessionBuilder.build();
        final started = await service.start(
          session,
          provider: ExternalAuthService.googleProvider,
        );
        final state = Uri.parse(started.authUrl).queryParameters['state']!;

        final callback = await service.handleAppleCallback(session, {
          'state': state,
          'id_token': 'apple-id-token',
          'code': 'apple-code',
        });

        expect(callback.success, isFalse);
        expect(authenticatorCalls, 0);
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

ExternalAuthService _service({
  ExternalAuthProviderAuthenticator? authenticator,
  ExternalAuthTokenExchange? tokenExchange,
}) {
  return ExternalAuthService(
    rateLimiter: const _NoopRateLimiter(),
    configurationResolver: (provider) => switch (provider) {
      ExternalAuthService.appleProvider => (
        clientId: 'apple-service-id',
        clientSecret: null,
        redirectUri: 'https://api.example/auth/apple/callback',
      ),
      ExternalAuthService.googleProvider => (
        clientId: 'google-client-id',
        clientSecret: 'google-client-secret',
        redirectUri: 'https://api.example/auth/google/callback',
      ),
      _ => throw StateError('Unexpected provider.'),
    },
    authenticator:
        authenticator ??
        (session, provider, credentials) async =>
            _authSuccess(strategy: provider),
    tokenExchange:
        tokenExchange ??
        (uri, body) async => {
          'id_token': 'id-token',
          'access_token': 'access-token',
        },
  );
}

auth_core.AuthSuccess _authSuccess({required String strategy}) {
  return auth_core.AuthSuccess(
    authStrategy: strategy,
    token: 'access-token',
    tokenExpiresAt: DateTime.utc(2026, 8, 2, 15),
    refreshToken: 'refresh-token',
    authUserId: UuidValue.fromString('018f4f7a-6b5c-7d8e-9f01-23456789abcd'),
    scopeNames: {'user'},
  );
}

final class _NoopRateLimiter implements AuthRequestLimiter {
  const _NoopRateLimiter();

  @override
  Future<void> enforce(
    Session session, {
    required AuthRateLimitAction action,
    String? credential,
  }) async {}
}
