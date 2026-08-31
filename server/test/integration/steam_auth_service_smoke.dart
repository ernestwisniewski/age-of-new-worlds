import 'dart:async';

import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:aonw_server/src/auth/steam_auth_service.dart';
import 'package:aonw_server/src/auth/steam_open_id_verifier.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'SteamAuthService',
    (sessionBuilder, _) {
      test('concurrent callbacks converge on one Steam account', () async {
        _ensureAuthServices();
        final service = SteamAuthService(
          openIdVerifier: const _AcceptingVerifier(),
          rateLimiter: const _NoopRateLimiter(),
        );
        final firstSession = sessionBuilder.build();
        final secondSession = sessionBuilder.build();
        final first = await service.start(firstSession);
        final second = await service.start(secondSession);

        final results = await Future.wait([
          service.handleCallback(firstSession, _callbackUri(first)),
          service.handleCallback(secondSession, _callbackUri(second)),
        ]);
        final accounts = await SteamAccount.db.find(
          sessionBuilder.build(),
          where: (table) => table.steamId.equals(_steamId),
        );
        final requests = await SteamAuthRequest.db.find(
          sessionBuilder.build(),
          where: (table) =>
              table.requestId.equals(first.requestId) |
              table.requestId.equals(second.requestId),
        );

        expect(results.map((result) => result.success), everyElement(isTrue));
        expect(accounts, hasLength(1));
        expect(requests, hasLength(2));
        expect(requests.map((request) => request.authUserId).toSet(), {
          accounts.single.authUserId,
        });
      });

      test('reports expiry when state changes during verification', () async {
        _ensureAuthServices();
        final verifier = _BlockingVerifier();
        final service = SteamAuthService(
          openIdVerifier: verifier,
          rateLimiter: const _NoopRateLimiter(),
        );
        final session = sessionBuilder.build();
        final started = await service.start(session);
        final callback = service.handleCallback(session, _callbackUri(started));
        await verifier.entered.future;
        final request = await SteamAuthRequest.db.findFirstRow(
          session,
          where: (table) => table.requestId.equals(started.requestId),
        );
        await SteamAuthRequest.db.updateRow(
          session,
          request!.copyWith(
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            ),
          ),
        );
        verifier.release.complete();

        final result = await callback;
        final updated = await SteamAuthRequest.db.findFirstRow(
          session,
          where: (table) => table.requestId.equals(started.requestId),
        );
        expect(result.success, isFalse);
        expect(result.title, 'Steam sign-in expired');
        expect(updated?.status, 'expired');
      });

      test('rejects return_to values with extra parameters', () async {
        final verifier = _CountingVerifier();
        final service = SteamAuthService(
          openIdVerifier: verifier,
          rateLimiter: const _NoopRateLimiter(),
        );
        final session = sessionBuilder.build();
        final started = await service.start(session);
        final validCallback = _callbackUri(started);
        final originalReturnTo =
            validCallback.queryParameters['openid.return_to']!;
        final modifiedReturnTo = Uri.parse(originalReturnTo).replace(
          queryParameters: {
            ...Uri.parse(originalReturnTo).queryParameters,
            'redirect': 'https://attacker.example',
          },
        );
        final callback = validCallback.replace(
          queryParameters: {
            ...validCallback.queryParameters,
            'openid.return_to': modifiedReturnTo.toString(),
          },
        );

        final result = await service.handleCallback(session, callback);
        final request = await SteamAuthRequest.db.findFirstRow(
          session,
          where: (table) => table.requestId.equals(started.requestId),
        );
        expect(result.success, isFalse);
        expect(verifier.calls, 0);
        expect(request?.status, 'failed');
        expect(request?.error, 'invalid_return_to');
      });
    },
    // Callback races intentionally overlap database transactions. The smoke
    // runner recreates the test database before every integration run.
    rollbackDatabase: RollbackDatabase.disabled,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

const _steamId = '12345678901234567';

Uri _callbackUri(SteamAuthStart start) {
  final authUri = Uri.parse(start.authUrl);
  final returnTo = authUri.queryParameters['openid.return_to']!;
  final callback = Uri.parse(returnTo);
  const identity = 'https://steamcommunity.com/openid/id/$_steamId';
  return callback.replace(
    queryParameters: {
      ...callback.queryParameters,
      'openid.ns': 'http://specs.openid.net/auth/2.0',
      'openid.mode': 'id_res',
      'openid.op_endpoint': SteamOpenIdVerifier.steamEndpoint.toString(),
      'openid.claimed_id': identity,
      'openid.identity': identity,
      'openid.return_to': returnTo,
      'openid.response_nonce': '2026-07-10T10:00:00Znonce',
      'openid.assoc_handle': 'assoc',
      'openid.signed': 'signed-fields',
      'openid.sig': 'signature',
    },
  );
}

final class _AcceptingVerifier implements SteamOpenIdVerification {
  const _AcceptingVerifier();

  @override
  Future<SteamOpenIdVerificationResult> verify(
    Map<String, String> query,
  ) async => const SteamOpenIdVerificationResult.valid();
}

final class _BlockingVerifier implements SteamOpenIdVerification {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<SteamOpenIdVerificationResult> verify(
    Map<String, String> query,
  ) async {
    entered.complete();
    await release.future;
    return const SteamOpenIdVerificationResult.valid();
  }
}

final class _CountingVerifier implements SteamOpenIdVerification {
  var calls = 0;

  @override
  Future<SteamOpenIdVerificationResult> verify(
    Map<String, String> query,
  ) async {
    calls += 1;
    return const SteamOpenIdVerificationResult.valid();
  }
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

void _ensureAuthServices() {
  try {
    auth_core.AuthServices.instance;
  } on StateError {
    auth_core.AuthServices.set(
      tokenManagerBuilders: [auth_core.JwtConfigFromPasswords()],
    );
  }
}
