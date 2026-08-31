import 'package:aonw_server/src/auth/auth_input_validator.dart';
import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:aonw_server/src/auth/refresh_token_rotation_service.dart';
import 'package:serverpod/serverpod.dart';

/// Manages the lifecycle of authenticated sessions.
///
/// Serverpod Auth already exposes access-token based sign-out through its
/// status endpoint. This endpoint covers clients that only have a persisted
/// refresh token, or whose short-lived access token expired.
class AuthStatusEndpoint extends Endpoint {
  AuthStatusEndpoint({
    AuthRequestLimiter? rateLimiter,
    RefreshTokenRotationService rotationService =
        const RefreshTokenRotationService(),
  }) : _rateLimiter = rateLimiter ?? DatabaseAuthRateLimiter(),
       _rotationService = rotationService;

  final AuthRequestLimiter _rateLimiter;
  final RefreshTokenRotationService _rotationService;

  /// Revokes the session represented by [refreshToken].
  ///
  /// Rotating the token first proves possession of its complete secret. Merely
  /// decoding its public id and deleting that row would allow anyone holding an
  /// old access token to sign another device out.
  @unauthenticatedClientCall
  Future<void> signOutRefreshToken(
    Session session, {
    required String refreshToken,
  }) async {
    const AuthInputValidator().refreshToken(refreshToken);
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.sessionLogout,
      credential: DatabaseAuthRateLimiter.refreshTokenCredential(refreshToken),
    );
    await _rotationService.refresh(
      session,
      refreshToken: refreshToken,
      revokeRotatedToken: true,
    );
  }
}
