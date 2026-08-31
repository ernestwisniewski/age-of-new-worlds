import 'package:aonw_server/src/auth/auth_input_validator.dart';
import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:aonw_server/src/auth/refresh_token_rotation_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

/// JWT refresh endpoint used by Serverpod auth clients.
class JwtRefreshEndpoint extends RefreshJwtTokensEndpoint {
  JwtRefreshEndpoint({
    AuthRequestLimiter? rateLimiter,
    RefreshTokenRotationService rotationService =
        const RefreshTokenRotationService(),
  }) : _rateLimiter = rateLimiter ?? DatabaseAuthRateLimiter(),
       _rotationService = rotationService;

  static const _inputValidator = AuthInputValidator();
  final AuthRequestLimiter _rateLimiter;
  final RefreshTokenRotationService _rotationService;

  @override
  @unauthenticatedClientCall
  Future<AuthSuccess> refreshAccessToken(
    Session session, {
    required String refreshToken,
  }) async {
    _inputValidator.refreshToken(refreshToken);
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.jwtRefresh,
      credential: DatabaseAuthRateLimiter.refreshTokenCredential(refreshToken),
    );
    return _rotationService.refresh(session, refreshToken: refreshToken);
  }
}
