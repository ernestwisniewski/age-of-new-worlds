part of 'steam_auth_service_test.dart';

const _requestId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _steamId = '12345678901234567';
const _second = Duration(seconds: 1);
final _publicBaseUri = Uri.parse('https://auth.example');

ServerConfig _serverConfig(String host, int publicPort) => ServerConfig(
  port: 0,
  publicScheme: 'https',
  publicHost: host,
  publicPort: publicPort,
);

SteamAuthRequest _pendingRequest({
  String status = 'pending',
  DateTime? expiresAt,
}) => SteamAuthRequest(
  requestId: _requestId,
  status: status,
  expiresAt: expiresAt ?? DateTime.now().toUtc().add(_second),
);

void _queueCallbackRequest(FakeDatabase database) {
  database.queueFindFirst<SteamAuthRequest>(_pendingRequest());
}

Uri _callbackUri({String mode = 'id_res'}) {
  final returnTo = _publicBaseUri.replace(
    path: SteamAuthService.callbackPath,
    queryParameters: const {'requestId': _requestId},
  );
  const identity = 'https://steamcommunity.com/openid/id/$_steamId';
  return returnTo.replace(
    queryParameters: {
      'requestId': _requestId,
      'openid.ns': 'http://specs.openid.net/auth/2.0',
      'openid.mode': mode,
      'openid.op_endpoint': SteamOpenIdVerifier.steamEndpoint.toString(),
      'openid.claimed_id': identity,
      'openid.identity': identity,
      'openid.return_to': returnTo.toString(),
      'openid.response_nonce': '2026-08-11T10:00:00Znonce',
      'openid.assoc_handle': 'assoc',
      'openid.signed': 'signed-fields',
      'openid.sig': 'signature',
    },
  );
}

void _ensureAuthServices() {
  try {
    auth_core.AuthServices.instance;
  } on StateError {
    auth_core.AuthServices.set(
      tokenManagerBuilders: [
        const auth_core.PreBuiltTokenManagerBuilder(_UnusedTokenManager()),
      ],
    );
  }
}

final class _AcceptingVerifier implements SteamOpenIdVerification {
  const _AcceptingVerifier();

  @override
  Future<SteamOpenIdVerificationResult> verify(
    Map<String, String> query,
  ) async => const SteamOpenIdVerificationResult.valid();
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

final class _ThrowingRateLimiter implements AuthRequestLimiter {
  const _ThrowingRateLimiter(this.code);

  final String code;

  @override
  Future<void> enforce(
    Session session, {
    required AuthRateLimitAction action,
    String? credential,
  }) => throw AccountAuthException(code: code, message: 'test');
}

final class _RejectingVerifier implements SteamOpenIdVerification {
  const _RejectingVerifier();

  @override
  Future<SteamOpenIdVerificationResult> verify(
    Map<String, String> query,
  ) async => const SteamOpenIdVerificationResult.rejected(
    'test rejection',
    httpStatus: 400,
  );
}

final class _UnusedTokenManager implements auth_core.TokenManager {
  const _UnusedTokenManager();

  @override
  Future<auth_core.AuthSuccess> issueToken(
    Session session, {
    required UuidValue authUserId,
    required String method,
    Set<Scope>? scopes,
    Transaction? transaction,
  }) async => auth_core.AuthSuccess(
    authStrategy: 'test',
    token: 'token',
    authUserId: authUserId,
    scopeNames: const {},
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Token management is outside this test.');
}

final class _EmptyEndpoints extends EndpointDispatch {
  @override
  void initializeEndpoints(Server server) {}
}
