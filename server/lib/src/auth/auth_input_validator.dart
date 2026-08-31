import 'package:aonw_server/src/generated/protocol.dart';

final class AuthInputValidator {
  const AuthInputValidator();

  static const int maxEmailLength = 254;
  static const int minNewPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxRefreshTokenLength = 2048;
  static const int maxRawDisplayNameLength = 64;
  static const int minDisplayNameLength = 3;
  static const int maxDisplayNameLength = 24;
  static const int steamRequestIdLength = 43;

  static final RegExp _emailLocalPartPattern = RegExp(
    r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]*$",
  );
  static final RegExp _emailDomainLabelPattern = RegExp(
    r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
  );
  static final RegExp _displayNamePattern = RegExp(
    r'^[\p{L}\p{N} _-]+$',
    unicode: true,
  );
  static final RegExp _steamRequestIdPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

  String loginEmail(String input) {
    final normalized = _normalizeEmail(input);
    if (normalized == null) {
      throw _error('invalid_credentials', 'Invalid email or password.');
    }
    return normalized;
  }

  String newAccountEmail(String input) {
    final normalized = _normalizeEmail(input);
    if (normalized == null) {
      throw _error('invalid_email', 'Email address is invalid.');
    }
    return normalized;
  }

  void loginPassword(String password) {
    if (password.isEmpty || password.length > maxPasswordLength) {
      throw _error('invalid_credentials', 'Invalid email or password.');
    }
  }

  void newAccountPassword(String password) {
    if (password.length < minNewPasswordLength ||
        password.length > maxPasswordLength) {
      throw _error(
        'weak_password',
        'Password must be $minNewPasswordLength-$maxPasswordLength '
            'characters long.',
      );
    }
  }

  void refreshToken(String token) {
    if (token.isEmpty || token.length > maxRefreshTokenLength) {
      throw _error('invalid_session', 'Session token is invalid.');
    }
  }

  String displayName(String input) {
    if (input.length > maxRawDisplayNameLength) {
      throw _invalidDisplayName();
    }
    final normalized = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < minDisplayNameLength ||
        normalized.length > maxDisplayNameLength ||
        !_displayNamePattern.hasMatch(normalized)) {
      throw _invalidDisplayName();
    }
    return normalized;
  }

  bool isValidSteamRequestId(String requestId) {
    return _steamRequestIdPattern.hasMatch(requestId);
  }

  String? _normalizeEmail(String input) {
    if (input.isEmpty || input.length > maxEmailLength) return null;
    final email = input.trim().toLowerCase();
    if (email.isEmpty) return null;

    final separator = email.indexOf('@');
    if (separator == -1 || separator != email.lastIndexOf('@')) return null;
    final localPart = email.substring(0, separator);
    final domain = email.substring(separator + 1);
    if (localPart.isEmpty ||
        localPart.length > 64 ||
        localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..') ||
        !_emailLocalPartPattern.hasMatch(localPart)) {
      return null;
    }

    final labels = domain.split('.');
    if (labels.length < 2) return null;
    for (final label in labels) {
      if (!_emailDomainLabelPattern.hasMatch(label)) return null;
    }
    return email;
  }

  AccountAuthException _invalidDisplayName() {
    return _error(
      'invalid_display_name',
      'Nickname must be $minDisplayNameLength-$maxDisplayNameLength '
          'characters and contain only letters, numbers, spaces, '
          'underscores, or hyphens.',
    );
  }

  AccountAuthException _error(String code, String message) {
    return AccountAuthException(code: code, message: message);
  }
}
