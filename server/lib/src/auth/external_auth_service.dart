import 'dart:convert';
import 'dart:math';

import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/providers/apple.dart';
import 'package:serverpod_auth_idp_server/providers/google.dart';

part 'external_auth_callback_flow.dart';
part 'external_auth_callback_state.dart';
part 'external_auth_provider_support.dart';

typedef ExternalAuthProviderConfiguration = ({
  String clientId,
  String? clientSecret,
  String redirectUri,
});

typedef ExternalAuthConfigurationResolver =
    ExternalAuthProviderConfiguration Function(String provider);

typedef ExternalAuthProviderAuthenticator =
    Future<auth_core.AuthSuccess> Function(
      Session session,
      String provider,
      Map<String, String> credentials,
    );

typedef ExternalAuthTokenExchange =
    Future<Map<String, dynamic>> Function(Uri uri, Map<String, String> body);

typedef ExternalAuthCallbackResult = ({
  bool success,
  String title,
  String message,
});

enum _ExternalCallbackClaim { claimed, completed, expired, rejected }

const _desktopStatePrefix = 'aonw-desktop.';
const _statusPending = 'pending';
const _statusProcessing = 'processing';
const _statusCompleted = 'completed';
const _statusConsumed = 'consumed';
const _statusFailed = 'failed';
const _statusExpired = 'expired';
const _statusAuthenticated = 'authenticated';

/// Browser-based identity-provider handoff for installed desktop builds.
///
/// The provider callback is completed by the server, while the application
/// receives the resulting Serverpod session through short-lived polling. This
/// avoids platform URL schemes and unsupported native Apple entitlements in
/// Developer ID distributions.
class ExternalAuthService {
  ExternalAuthService({
    AuthRequestLimiter? rateLimiter,
    ExternalAuthConfigurationResolver? configurationResolver,
    ExternalAuthProviderAuthenticator? authenticator,
    ExternalAuthTokenExchange? tokenExchange,
  }) : _rateLimiter = rateLimiter ?? DatabaseAuthRateLimiter(),
       _configurationResolver = configurationResolver ?? _defaultConfiguration,
       _authenticator = authenticator ?? _defaultAuthenticator,
       _tokenExchange = tokenExchange ?? _defaultTokenExchange;

  static const appleProvider = 'apple';
  static const googleProvider = 'google';
  static const appleCallbackPath = '/auth/apple/callback';
  static const googleCallbackPath = '/auth/google/callback';

  final AuthRequestLimiter _rateLimiter;
  final ExternalAuthConfigurationResolver _configurationResolver;
  final ExternalAuthProviderAuthenticator _authenticator;
  final ExternalAuthTokenExchange _tokenExchange;

  static bool isDesktopState(String? state) =>
      state != null && state.startsWith(_desktopStatePrefix);

  Future<ExternalAuthStart> start(
    Session session, {
    required String provider,
  }) async {
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.externalAuthStart,
    );
    if (provider != appleProvider && provider != googleProvider) {
      throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
    }

    final configuration = _configurationResolver(provider);
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(minutes: 10));
    final requestId = _secureToken(32);
    final state = '$_desktopStatePrefix${_secureToken(32)}';
    final codeVerifier = provider == googleProvider ? _secureToken(48) : null;
    final authUrl = switch (provider) {
      appleProvider => _appleAuthorizationUri(configuration, state),
      googleProvider => _googleAuthorizationUri(
        configuration,
        state,
        codeVerifier!,
      ),
      _ => throw StateError('Unsupported external auth provider.'),
    };

    await ExternalAuthRequest.db.insertRow(
      session,
      ExternalAuthRequest(
        requestId: requestId,
        state: state,
        provider: provider,
        status: _statusPending,
        codeVerifier: codeVerifier,
        createdAt: now,
        expiresAt: expiresAt,
      ),
    );

    return ExternalAuthStart(
      requestId: requestId,
      authUrl: authUrl.toString(),
      expiresAt: expiresAt,
    );
  }

  Future<ExternalAuthPollResult> poll(
    Session session, {
    required String requestId,
  }) async {
    final validRequestId = _isValidToken(requestId);
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.externalAuthPoll,
      credential: validRequestId ? requestId : null,
    );
    if (!validRequestId) {
      return ExternalAuthPollResult(status: _statusFailed, error: 'not_found');
    }

    final now = DateTime.now().toUtc();
    return session.db.transaction((transaction) async {
      final request = await ExternalAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.requestId.equals(requestId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null) {
        return ExternalAuthPollResult(
          status: _statusFailed,
          error: 'not_found',
        );
      }

      if (request.expiresAt.isBefore(now) && request.consumedAt == null) {
        await ExternalAuthRequest.db.updateRow(
          session,
          request.copyWith(status: _statusExpired, error: 'expired'),
          transaction: transaction,
        );
        return ExternalAuthPollResult(status: _statusExpired, error: 'expired');
      }

      if (request.status == _statusCompleted &&
          request.authStrategy != null &&
          request.token != null &&
          request.authUserId != null &&
          request.scopeNames != null &&
          request.consumedAt == null) {
        final auth = auth_core.AuthSuccess(
          authStrategy: request.authStrategy!,
          token: request.token!,
          tokenExpiresAt: request.tokenExpiresAt,
          refreshToken: request.refreshToken,
          authUserId: request.authUserId!,
          scopeNames: request.scopeNames!.toSet(),
        );
        await ExternalAuthRequest.db.updateRow(
          session,
          request.copyWith(
            status: _statusConsumed,
            codeVerifier: null,
            token: null,
            refreshToken: null,
            consumedAt: now,
          ),
          transaction: transaction,
        );
        return ExternalAuthPollResult(status: _statusAuthenticated, auth: auth);
      }

      return ExternalAuthPollResult(
        status: request.status,
        error: request.error,
      );
    });
  }

  Future<ExternalAuthCallbackResult> handleAppleCallback(
    Session session,
    Map<String, String> parameters,
  ) => _handleAppleCallback(session, parameters);

  Future<ExternalAuthCallbackResult> handleGoogleCallback(
    Session session,
    Map<String, String> parameters,
  ) => _handleGoogleCallback(session, parameters);
}
