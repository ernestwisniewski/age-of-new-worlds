part of 'external_auth_service.dart';

extension _ExternalAuthCallbackState on ExternalAuthService {
  Future<({bool claimed, ExternalAuthCallbackResult? result})> _prepareCallback(
    Session session, {
    required String state,
    required String provider,
  }) async {
    try {
      await _rateLimiter.enforce(
        session,
        action: AuthRateLimitAction.externalAuthCallback,
        credential: state,
      );
    } on AccountAuthException catch (error) {
      if (error.code != 'rate_limited') rethrow;
      return (
        claimed: false,
        result: _failure(
          'Too many sign-in attempts',
          'Please wait and try again.',
        ),
      );
    }

    final claim = await _claimCallback(session, state, provider);
    return switch (claim) {
      _ExternalCallbackClaim.claimed => (claimed: true, result: null),
      _ExternalCallbackClaim.completed => (
        claimed: false,
        result: _success(provider),
      ),
      _ExternalCallbackClaim.expired => (
        claimed: false,
        result: _failure(
          '${_providerLabel(provider)} sign-in expired',
          'Please return to Age of New Worlds and try again.',
        ),
      ),
      _ExternalCallbackClaim.rejected => (
        claimed: false,
        result: _failure(
          '${_providerLabel(provider)} sign-in failed',
          'The authentication request could not be completed.',
        ),
      ),
    };
  }

  Future<_ExternalCallbackClaim> _claimCallback(
    Session session,
    String state,
    String provider,
  ) {
    return session.db.transaction((transaction) async {
      final request = await ExternalAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.state.equals(state),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null || request.provider != provider) {
        return _ExternalCallbackClaim.rejected;
      }
      if (request.status == _statusCompleted ||
          request.status == _statusConsumed) {
        return _ExternalCallbackClaim.completed;
      }
      if (request.status != _statusPending) {
        return _ExternalCallbackClaim.rejected;
      }
      final now = DateTime.now().toUtc();
      if (request.expiresAt.isBefore(now)) {
        await ExternalAuthRequest.db.updateRow(
          session,
          request.copyWith(status: _statusExpired, error: 'expired'),
          transaction: transaction,
        );
        return _ExternalCallbackClaim.expired;
      }
      await ExternalAuthRequest.db.updateRow(
        session,
        request.copyWith(status: _statusProcessing),
        transaction: transaction,
      );
      return _ExternalCallbackClaim.claimed;
    });
  }

  Future<bool> _commitAuth(
    Session session,
    String state,
    auth_core.AuthSuccess auth,
  ) {
    return session.db.transaction((transaction) async {
      final request = await ExternalAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.state.equals(state),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null || request.status != _statusProcessing) return false;
      final now = DateTime.now().toUtc();
      if (request.expiresAt.isBefore(now)) {
        await ExternalAuthRequest.db.updateRow(
          session,
          request.copyWith(status: _statusExpired, error: 'expired'),
          transaction: transaction,
        );
        return false;
      }
      await ExternalAuthRequest.db.updateRow(
        session,
        request.copyWith(
          status: _statusCompleted,
          codeVerifier: null,
          authStrategy: auth.authStrategy,
          token: auth.token,
          tokenExpiresAt: auth.tokenExpiresAt,
          refreshToken: auth.refreshToken,
          authUserId: auth.authUserId,
          scopeNames: auth.scopeNames.toList(growable: false),
          completedAt: now,
        ),
        transaction: transaction,
      );
      return true;
    });
  }

  Future<void> _failByState(Session session, String state, String error) async {
    await session.db.transaction((transaction) async {
      final request = await ExternalAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.state.equals(state),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null ||
          (request.status != _statusPending &&
              request.status != _statusProcessing)) {
        return;
      }
      await ExternalAuthRequest.db.updateRow(
        session,
        request.copyWith(
          status: _statusFailed,
          codeVerifier: null,
          error: error,
        ),
        transaction: transaction,
      );
    });
  }

  Future<ExternalAuthRequest?> _requestForState(Session session, String state) {
    return ExternalAuthRequest.db.findFirstRow(
      session,
      where: (table) => table.state.equals(state),
    );
  }
}
