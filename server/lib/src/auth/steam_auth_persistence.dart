part of 'steam_auth_service.dart';

extension _SteamAuthPersistence on SteamAuthService {
  Future<_SteamCallbackCommit> _commitVerifiedCallback(
    Session session, {
    required String requestId,
    required String steamId,
  }) async {
    for (var attempt = 0; attempt < 3; attempt += 1) {
      try {
        return await session.db.transaction((transaction) async {
          final lockedRequest = await SteamAuthRequest.db.findFirstRow(
            session,
            where: (table) => table.requestId.equals(requestId),
            transaction: transaction,
            lockMode: LockMode.forUpdate,
            lockBehavior: LockBehavior.wait,
          );
          if (lockedRequest == null) return _SteamCallbackCommit.rejected;
          if (lockedRequest.status == SteamAuthService._statusCompleted ||
              lockedRequest.status == SteamAuthService._statusConsumed) {
            return _SteamCallbackCommit.alreadyCompleted;
          }
          if (lockedRequest.status != SteamAuthService._statusPending) {
            return _SteamCallbackCommit.rejected;
          }
          final now = DateTime.now().toUtc();
          if (lockedRequest.expiresAt.isBefore(now)) {
            await SteamAuthRequest.db.updateRow(
              session,
              lockedRequest.copyWith(status: SteamAuthService._statusExpired),
              transaction: transaction,
            );
            return _SteamCallbackCommit.expired;
          }

          final authUserId = await _upsertSteamAccount(
            session,
            steamId: steamId,
            transaction: transaction,
          );
          await SteamAuthRequest.db.updateRow(
            session,
            lockedRequest.copyWith(
              status: SteamAuthService._statusCompleted,
              authUserId: authUserId,
              steamId: steamId,
              completedAt: now,
            ),
            transaction: transaction,
          );
          return _SteamCallbackCommit.completed;
        });
      } on DatabaseQueryException catch (error) {
        final steamAccountRace =
            error.code == '23505' &&
            error.constraintName == 'aonw_steam_account_steam_id_idx';
        if (!steamAccountRace) rethrow;
      }
    }
    return _SteamCallbackCommit.rejected;
  }

  Future<void> _failRequest(
    Session session,
    String requestId,
    String error,
  ) async {
    await session.db.transaction((transaction) async {
      final request = await SteamAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.requestId.equals(requestId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null ||
          request.status != SteamAuthService._statusPending) {
        return;
      }
      await SteamAuthRequest.db.updateRow(
        session,
        request.copyWith(status: SteamAuthService._statusFailed, error: error),
        transaction: transaction,
      );
    });
  }

  Future<UuidValue> _upsertSteamAccount(
    Session session, {
    required String steamId,
    required Transaction transaction,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await SteamAccount.db.findFirstRow(
      session,
      where: (table) => table.steamId.equals(steamId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
      lockBehavior: LockBehavior.wait,
    );
    if (existing != null) {
      await SteamAccount.db.updateRow(
        session,
        existing.copyWith(lastSeenAt: now),
        transaction: transaction,
      );
      return existing.authUserId;
    }

    final authUser = await auth_core.AuthServices.instance.authUsers.create(
      session,
      transaction: transaction,
    );
    final profileName = _profileName(steamId);
    await auth_core.AuthServices.instance.userProfiles.createUserProfile(
      session,
      authUser.id,
      auth_core.UserProfileData(userName: profileName, fullName: profileName),
      transaction: transaction,
    );
    await SteamAccount.db.insertRow(
      session,
      SteamAccount(
        steamId: steamId,
        authUserId: authUser.id,
        createdAt: now,
        lastSeenAt: now,
      ),
      transaction: transaction,
    );
    return authUser.id;
  }

  String _profileName(String steamId) {
    final suffix = steamId.length > 4
        ? steamId.substring(steamId.length - 4)
        : steamId;
    return 'Steam $suffix';
  }
}
