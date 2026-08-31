import 'dart:convert';

import 'package:aonw_server/src/auth/auth_rate_limit_client_identity.dart';
import 'package:aonw_server/src/auth/auth_rate_limit_constants.dart';
import 'package:aonw_server/src/auth/refresh_token_parser.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

enum AuthRateLimitAction {
  emailLogin,
  emailCreate,
  steamStart,
  steamPoll,
  steamCallback,
  externalAuthStart,
  externalAuthPoll,
  externalAuthCallback,
  jwtRefresh,
  sessionLogout,
}

final class AuthRateLimitPolicy {
  const AuthRateLimitPolicy({
    required this.timeframe,
    required this.maxIpAttempts,
    this.maxCredentialAttempts,
  });

  final Duration timeframe;
  final int maxIpAttempts;
  final int? maxCredentialAttempts;
}

abstract interface class AuthRequestLimiter {
  Future<void> enforce(
    Session session, {
    required AuthRateLimitAction action,
    String? credential,
  });
}

/// Persistent authentication abuse limits shared by every server instance.
final class DatabaseAuthRateLimiter implements AuthRequestLimiter {
  static const _policies = <AuthRateLimitAction, AuthRateLimitPolicy>{
    AuthRateLimitAction.emailLogin: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 15),
      maxIpAttempts: 60,
      maxCredentialAttempts: 10,
    ),
    AuthRateLimitAction.emailCreate: AuthRateLimitPolicy(
      timeframe: Duration(hours: 1),
      maxIpAttempts: 10,
      maxCredentialAttempts: 3,
    ),
    AuthRateLimitAction.steamStart: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 10),
      maxIpAttempts: 20,
    ),
    AuthRateLimitAction.steamPoll: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 15),
      maxIpAttempts: 2000,
      maxCredentialAttempts: 700,
    ),
    AuthRateLimitAction.steamCallback: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 15),
      maxIpAttempts: 60,
      maxCredentialAttempts: 5,
    ),
    AuthRateLimitAction.externalAuthStart: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 10),
      maxIpAttempts: 20,
    ),
    AuthRateLimitAction.externalAuthPoll: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 15),
      maxIpAttempts: 2000,
      maxCredentialAttempts: 700,
    ),
    AuthRateLimitAction.externalAuthCallback: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 15),
      maxIpAttempts: 60,
      maxCredentialAttempts: 5,
    ),
    AuthRateLimitAction.jwtRefresh: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 15),
      maxIpAttempts: 120,
      maxCredentialAttempts: 12,
    ),
    AuthRateLimitAction.sessionLogout: AuthRateLimitPolicy(
      timeframe: Duration(minutes: 15),
      maxIpAttempts: 120,
      maxCredentialAttempts: 6,
    ),
  };

  DatabaseAuthRateLimiter({
    ServerOperationalEventSink Function(Session session)? operationalEventsFor,
    AuthRateLimitClientIdentityResolver clientIdentityResolver =
        const AuthRateLimitClientIdentityResolver(),
  }) : _operationalEventsFor =
           operationalEventsFor ?? ServerpodOperationalEventSink.new,
       _clientIdentityResolver = clientIdentityResolver;

  final Map<String, DatabaseRateLimitedRequestAttemptUtil<String>> _limits = {};
  final ServerOperationalEventSink Function(Session session)
  _operationalEventsFor;
  final AuthRateLimitClientIdentityResolver _clientIdentityResolver;

  @override
  Future<void> enforce(
    Session session, {
    required AuthRateLimitAction action,
    String? credential,
  }) async {
    final policy = policyFor(action);
    final pepper = _pepper();
    final ipLimited = await _hasTooManyAttempts(
      session,
      source: '${action.name}_ip',
      nonce: ipNonceFor(session.request, pepper: pepper),
      maxAttempts: policy.maxIpAttempts,
      timeframe: policy.timeframe,
    );
    if (ipLimited) {
      _operationalEventsFor(session).authRateLimited(action: action);
      throw _rateLimited();
    }

    final maxCredentialAttempts = policy.maxCredentialAttempts;
    if (credential == null || maxCredentialAttempts == null) return;
    final credentialLimited = await _hasTooManyAttempts(
      session,
      source: '${action.name}_credential',
      nonce: fingerprint('credential:$credential', pepper: pepper),
      maxAttempts: maxCredentialAttempts,
      timeframe: policy.timeframe,
    );
    if (credentialLimited) {
      _operationalEventsFor(session).authRateLimited(action: action);
      throw _rateLimited();
    }
  }

  Future<bool> _hasTooManyAttempts(
    Session session, {
    required String source,
    required String nonce,
    required int maxAttempts,
    required Duration timeframe,
  }) {
    final key = '$source:$maxAttempts:${timeframe.inSeconds}';
    final limiter = _limits.putIfAbsent(
      key,
      () => DatabaseRateLimitedRequestAttemptUtil<String>(
        RateLimitedRequestAttemptConfig<String>(
          domain: aonwAuthRateLimitDomain,
          source: source,
          maxAttempts: maxAttempts,
          timeframe: timeframe,
        ),
      ),
    );
    return limiter.hasTooManyAttempts(session, nonce: nonce);
  }

  String _pepper() {
    const key = 'emailSecretHashPepper';
    final pepper = Serverpod.instance.getPassword(key);
    if (pepper == null || pepper.isEmpty) {
      throw StateError('Missing authentication rate-limit pepper.');
    }
    return pepper;
  }

  static AuthRateLimitPolicy policyFor(AuthRateLimitAction action) {
    return _policies[action]!;
  }

  static String refreshTokenCredential(String refreshToken) {
    final parsed = parseRefreshTokenId(refreshToken);
    if (parsed != null) return 'refresh-id:${parsed.encoded}';
    return 'malformed-refresh:$refreshToken';
  }

  String ipNonceFor(Request? request, {required String pepper}) {
    final clientIdentity = _clientIdentityResolver.resolve(request);
    return fingerprint('ip:$clientIdentity', pepper: pepper);
  }

  static String fingerprint(String value, {required String pepper}) {
    final digest = Hmac(
      sha256,
      utf8.encode('aonw-auth-rate-limit:$pepper'),
    ).convert(utf8.encode(value));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  AccountAuthException _rateLimited() {
    return AccountAuthException(
      code: 'rate_limited',
      message: 'Too many authentication attempts. Please try again later.',
    );
  }
}
