import 'package:aonw_server/src/auth/auth_input_validator.dart';
import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:aonw_server/src/auth/email_password_verifier.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;

/// Email/password account endpoint backed by Serverpod Auth Core.
class EmailIdpEndpoint extends Endpoint {
  EmailIdpEndpoint({
    EmailPasswordVerifier? passwordVerifier,
    AuthRequestLimiter? rateLimiter,
  }) : _passwordVerifier = passwordVerifier,
       _rateLimiter = rateLimiter ?? DatabaseAuthRateLimiter();

  static const _authMethod = 'email';
  static const _hashSaltLength = 16;
  static const _inputValidator = AuthInputValidator();
  EmailPasswordVerifier? _passwordVerifier;
  final AuthRequestLimiter _rateLimiter;

  @unauthenticatedClientCall
  Future<auth_core.AuthSuccess> login(
    Session session, {
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _inputValidator.loginEmail(email);
    _inputValidator.loginPassword(password);
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.emailLogin,
      credential: normalizedEmail,
    );
    final account = await AonwAccount.db.findFirstRow(
      session,
      where: (table) => table.email.equals(normalizedEmail),
    );
    final passwordMatches = await _passwordVerifierForServer().matches(
      password: password,
      storedHash: account?.passwordHash,
    );
    if (account == null || !passwordMatches) {
      throw _authError('invalid_credentials', 'Invalid email or password.');
    }

    return auth_core.AuthServices.instance.tokenManager.issueToken(
      session,
      authUserId: account.authUserId,
      method: _authMethod,
    );
  }

  @unauthenticatedClientCall
  Future<auth_core.AuthSuccess> createAccount(
    Session session, {
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalized = _inputValidator.newAccountEmail(email);
    _inputValidator.newAccountPassword(password);
    final normalizedDisplayName = _inputValidator.displayName(displayName);
    final displayNameKey = _displayNameKey(normalizedDisplayName);
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.emailCreate,
      credential: normalized,
    );

    final passwordHash = await _hashUtil().createHashFromString(
      secret: password,
    );
    try {
      return await session.db.transaction((transaction) async {
        final existing = await AonwAccount.db.findFirstRow(
          session,
          where: (table) => table.email.equals(normalized),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
          lockBehavior: LockBehavior.wait,
        );
        if (existing != null) {
          throw _authError('account_exists', 'Account already exists.');
        }
        final existingDisplayName = await AonwAccount.db.findFirstRow(
          session,
          where: (table) => table.displayNameKey.equals(displayNameKey),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
          lockBehavior: LockBehavior.wait,
        );
        if (existingDisplayName != null) {
          throw _authError(
            'display_name_taken',
            'This nickname is already taken.',
          );
        }

        final authUser = await auth_core.AuthServices.instance.authUsers.create(
          session,
          transaction: transaction,
        );
        await auth_core.AuthServices.instance.userProfiles.createUserProfile(
          session,
          authUser.id,
          auth_core.UserProfileData(
            userName: normalizedDisplayName,
            fullName: normalizedDisplayName,
            email: normalized,
          ),
          transaction: transaction,
        );
        await AonwAccount.db.insertRow(
          session,
          AonwAccount(
            authUserId: authUser.id,
            email: normalized,
            displayName: normalizedDisplayName,
            displayNameKey: displayNameKey,
            passwordHash: passwordHash,
            createdAt: DateTime.now().toUtc(),
          ),
          transaction: transaction,
        );
        return auth_core.AuthServices.instance.tokenManager.issueToken(
          session,
          authUserId: authUser.id,
          method: _authMethod,
          transaction: transaction,
        );
      });
    } on DatabaseQueryException catch (error) {
      if (error.code == '23505') {
        if (error.constraintName == 'aonw_account_email_idx') {
          throw _authError('account_exists', 'Account already exists.');
        }
        if (error.constraintName == 'aonw_account_display_name_idx') {
          throw _authError(
            'display_name_taken',
            'This nickname is already taken.',
          );
        }
      }
      rethrow;
    }
  }

  Future<String> displayName(Session session) async {
    final account = await _requireAccount(session);
    return account.displayName;
  }

  Future<String> updateDisplayName(
    Session session, {
    required String displayName,
  }) async {
    final user = _requireUser(session);
    final normalizedDisplayName = _inputValidator.displayName(displayName);
    final displayNameKey = _displayNameKey(normalizedDisplayName);
    try {
      return await session.db.transaction((transaction) async {
        final account = await _requireAccountForUser(
          session,
          user,
          transaction: transaction,
          lock: true,
        );
        final existing = await AonwAccount.db.findFirstRow(
          session,
          where: (table) => table.displayNameKey.equals(displayNameKey),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
          lockBehavior: LockBehavior.wait,
        );
        if (existing != null && existing.authUserId != account.authUserId) {
          throw _authError(
            'display_name_taken',
            'This nickname is already taken.',
          );
        }
        final updated = await AonwAccount.db.updateRow(
          session,
          account.copyWith(
            displayName: normalizedDisplayName,
            displayNameKey: displayNameKey,
          ),
          transaction: transaction,
        );
        await _syncUserProfileDisplayName(
          session,
          account: updated,
          transaction: transaction,
        );
        return updated.displayName;
      });
    } on DatabaseQueryException catch (error) {
      if (error.code == '23505' &&
          error.constraintName == 'aonw_account_display_name_idx') {
        throw _authError(
          'display_name_taken',
          'This nickname is already taken.',
        );
      }
      rethrow;
    }
  }

  Future<bool> hasAccount(Session session) async {
    final user = session.authenticated;
    if (user == null) return false;
    final account = await AonwAccount.db.findFirstRow(
      session,
      where: (table) => table.authUserId.equals(_authUserId(user)),
    );
    return account != null;
  }

  Future<AonwAccount> _requireAccount(Session session) async {
    final user = _requireUser(session);
    return _requireAccountForUser(session, user);
  }

  Future<AonwAccount> _requireAccountForUser(
    Session session,
    AuthenticationInfo user, {
    Transaction? transaction,
    bool lock = false,
  }) async {
    final account = await AonwAccount.db.findFirstRow(
      session,
      where: (table) => table.authUserId.equals(user.authUserId),
      transaction: transaction,
      lockMode: lock ? LockMode.forUpdate : null,
      lockBehavior: lock ? LockBehavior.wait : null,
    );
    if (account == null) {
      throw _authError('account_not_found', 'Account not found.');
    }
    return account;
  }

  AuthenticationInfo _requireUser(Session session) {
    final user = session.authenticated;
    if (user == null) {
      throw _authError('auth_required', 'Authentication is required.');
    }
    return user;
  }

  auth_core.Argon2HashUtil _hashUtil() {
    const key = 'emailSecretHashPepper';
    final hashPepper = Serverpod.instance.getPassword(key);
    if (hashPepper == null) {
      throw auth_core.PasswordNotFoundException(key);
    }
    return auth_core.Argon2HashUtil(
      hashPepper: hashPepper,
      hashSaltLength: _hashSaltLength,
    );
  }

  EmailPasswordVerifier _passwordVerifierForServer() {
    final existing = _passwordVerifier;
    if (existing != null) return existing;
    final hashUtil = _hashUtil();
    return _passwordVerifier = EmailPasswordVerifier(
      createHash: (secret) => hashUtil.createHashFromString(secret: secret),
      validateHash: (secret, hashString) => hashUtil.validateHashFromString(
        secret: secret,
        hashString: hashString,
      ),
    );
  }

  Future<void> _syncUserProfileDisplayName(
    Session session, {
    required AonwAccount account,
    required Transaction transaction,
  }) async {
    final userProfiles = auth_core.AuthServices.instance.userProfiles;
    final profile = await userProfiles.maybeFindUserProfileByUserId(
      session,
      account.authUserId,
      transaction: transaction,
    );
    if (profile == null) {
      await userProfiles.createUserProfile(
        session,
        account.authUserId,
        auth_core.UserProfileData(
          userName: account.displayName,
          fullName: account.displayName,
          email: account.email,
        ),
        transaction: transaction,
      );
      return;
    }

    await userProfiles.changeUserName(
      session,
      account.authUserId,
      account.displayName,
      transaction: transaction,
    );
  }

  UuidValue _authUserId(AuthenticationInfo user) {
    return UuidValue.withValidation(user.userIdentifier);
  }

  String _displayNameKey(String displayName) {
    return displayName.toLowerCase();
  }

  AccountAuthException _authError(String code, String message) {
    return AccountAuthException(code: code, message: message);
  }
}
