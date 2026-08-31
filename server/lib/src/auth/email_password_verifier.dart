typedef PasswordHashFactory = Future<String> Function(String secret);
typedef PasswordHashValidator =
    Future<bool> Function(String secret, String hashString);

/// Verifies email passwords without a fast path for unknown accounts.
final class EmailPasswordVerifier {
  EmailPasswordVerifier({
    required PasswordHashFactory createHash,
    required PasswordHashValidator validateHash,
  }) : _createHash = createHash,
       _validateHash = validateHash;

  static const _dummySecret = 'aonw-non-account-password-placeholder';

  final PasswordHashFactory _createHash;
  final PasswordHashValidator _validateHash;
  Future<String>? _dummyHash;

  Future<bool> matches({
    required String password,
    required String? storedHash,
  }) async {
    if (storedHash == null || storedHash.isEmpty) {
      await _validateDummy(password);
      return false;
    }
    try {
      return await _validateHash(password, storedHash);
    } catch (_) {
      await _validateDummy(password);
      return false;
    }
  }

  Future<void> _validateDummy(String password) async {
    final dummyHash = await (_dummyHash ??= _createHash(_dummySecret));
    try {
      await _validateHash(password, dummyHash);
    } catch (_) {
      // A failure in a process-local dummy hash must remain an authentication
      // failure and must never reveal whether an account exists.
    }
  }
}
