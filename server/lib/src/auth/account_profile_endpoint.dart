import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;

/// Keeps the game account table in sync with Serverpod Auth users.
class AccountProfileEndpoint extends Endpoint {
  Future<String> ensureAccount(Session session) async {
    final user = _requireUser(session);
    for (var attempt = 0; attempt < 3; attempt += 1) {
      try {
        final account = await _provisionAccount(session, user);
        return account.displayName;
      } on DatabaseQueryException catch (error) {
        if (!_isProvisioningConflict(error)) rethrow;
        final winner = await AonwAccount.db.findFirstRow(
          session,
          where: (table) => table.authUserId.equals(user.authUserId),
        );
        if (winner != null) return winner.displayName;
      }
    }
    throw AccountAuthException(
      code: 'account_provisioning_failed',
      message: 'Account provisioning could not be completed.',
    );
  }

  Future<AonwAccount> _provisionAccount(
    Session session,
    AuthenticationInfo user,
  ) {
    return session.db.transaction((transaction) async {
      final existing = await AonwAccount.db.findFirstRow(
        session,
        where: (table) => table.authUserId.equals(user.authUserId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (existing != null) return existing;

      final profile = await auth_core.AuthServices.instance.userProfiles
          .maybeFindUserProfileByUserId(
            session,
            user.authUserId,
            transaction: transaction,
          );
      final displayName = await _uniqueDisplayName(
        session,
        transaction: transaction,
        candidate: _displayNameCandidate(profile, user.authUserId),
        authUserId: user.authUserId,
      );
      return AonwAccount.db.insertRow(
        session,
        AonwAccount(
          authUserId: user.authUserId,
          email: 'external:${user.authUserId}',
          displayName: displayName,
          displayNameKey: _displayNameKey(displayName),
          passwordHash: '',
          createdAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
  }

  bool _isProvisioningConflict(DatabaseQueryException error) {
    return error.code == '23505' &&
        const {
          'aonw_account_auth_user_idx',
          'aonw_account_email_idx',
          'aonw_account_display_name_idx',
        }.contains(error.constraintName);
  }

  AuthenticationInfo _requireUser(Session session) {
    final user = session.authenticated;
    if (user == null) {
      throw AccountAuthException(
        code: 'auth_required',
        message: 'Authentication is required.',
      );
    }
    return user;
  }

  String _displayNameCandidate(
    auth_core.UserProfileModel? profile,
    UuidValue authUserId,
  ) {
    for (final value in [
      profile?.userName,
      profile?.fullName,
      profile?.email?.split('@').first,
    ]) {
      final sanitized = _sanitizeDisplayName(value ?? '');
      if (_validDisplayName(sanitized)) return sanitized;
    }
    return 'Player ${_shortId(authUserId)}';
  }

  Future<String> _uniqueDisplayName(
    Session session, {
    required Transaction transaction,
    required String candidate,
    required UuidValue authUserId,
  }) async {
    final base = _sanitizeDisplayName(candidate);
    final suffix = _shortId(authUserId);

    for (var attempt = 0; attempt < 100; attempt += 1) {
      final displayName = switch (attempt) {
        0 => base,
        1 => _withSuffix(base, suffix),
        _ => _withSuffix(base, '$suffix$attempt'),
      };
      final existing = await AonwAccount.db.findFirstRow(
        session,
        where: (table) =>
            table.displayNameKey.equals(_displayNameKey(displayName)),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (existing == null) return displayName;
    }

    return 'Player ${DateTime.now().microsecondsSinceEpoch % 100000}';
  }

  String _withSuffix(String base, String suffix) {
    final addition = ' $suffix';
    final maxBaseLength = 24 - addition.length;
    final trimmedBase = base.length <= maxBaseLength
        ? base
        : base.substring(0, maxBaseLength).trimRight();
    return '$trimmedBase$addition';
  }

  String _sanitizeDisplayName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^\p{L}\p{N} _-]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 24) return normalized;
    return normalized.substring(0, 24).trimRight();
  }

  String _displayNameKey(String displayName) {
    return _sanitizeDisplayName(displayName).toLowerCase();
  }

  bool _validDisplayName(String displayName) {
    if (displayName.length < 3 || displayName.length > 24) return false;
    return RegExp(r'^[\p{L}\p{N} _-]+$', unicode: true).hasMatch(displayName);
  }

  String _shortId(UuidValue authUserId) {
    final compact = authUserId.toString().replaceAll('-', '');
    if (compact.length <= 4) return compact.toUpperCase();
    return compact.substring(compact.length - 4).toUpperCase();
  }
}
