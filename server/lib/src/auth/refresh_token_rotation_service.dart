import 'package:aonw_server/src/auth/refresh_token_parser.dart'
    as refresh_token_parser;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;

/// Serializes refresh-token rotation across requests and server instances.
final class RefreshTokenRotationService {
  const RefreshTokenRotationService();

  Future<auth_core.AuthSuccess> refresh(
    Session session, {
    required String refreshToken,
    bool revokeRotatedToken = false,
  }) async {
    final jwt =
        auth_core.AuthServices.getTokenManager<auth_core.JwtTokenManager>().jwt;
    final refreshTokenId = parseRefreshTokenId(refreshToken);
    if (refreshTokenId == null) {
      return jwt.refreshAccessToken(session, refreshToken: refreshToken);
    }

    final observed = await auth_core.RefreshToken.db.findById(
      session,
      refreshTokenId,
    );
    return session.db.transaction((transaction) async {
      final locked = await auth_core.RefreshToken.db.findById(
        session,
        refreshTokenId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (_changedWhileWaiting(observed, locked)) {
        throw auth_core.RefreshTokenInvalidSecretException();
      }

      final rotated = await jwt.refreshAccessToken(
        session,
        refreshToken: refreshToken,
        transaction: transaction,
      );
      if (revokeRotatedToken) {
        await jwt.revokeRefreshToken(
          session,
          refreshTokenId: rotated.jwtRefreshTokenId,
          transaction: transaction,
        );
      }
      return rotated;
    });
  }

  static UuidValue? parseRefreshTokenId(String refreshToken) {
    return refresh_token_parser.parseRefreshTokenId(refreshToken)?.value;
  }

  bool _changedWhileWaiting(
    auth_core.RefreshToken? observed,
    auth_core.RefreshToken? locked,
  ) {
    if (observed == null || locked == null) return false;
    return observed.lastUpdatedAt != locked.lastUpdatedAt ||
        observed.rotatingSecretHash != locked.rotatingSecretHash;
  }
}
