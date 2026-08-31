import 'package:aonw_server/src/auth/auth_input_validator.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  const validator = AuthInputValidator();

  test('keeps the reviewed authentication input bounds', () {
    expect(AuthInputValidator.maxEmailLength, 254);
    expect(AuthInputValidator.minNewPasswordLength, 8);
    expect(AuthInputValidator.maxPasswordLength, 128);
    expect(AuthInputValidator.maxRefreshTokenLength, 2048);
    expect(AuthInputValidator.maxRawDisplayNameLength, 64);
    expect(AuthInputValidator.minDisplayNameLength, 3);
    expect(AuthInputValidator.maxDisplayNameLength, 24);
    expect(AuthInputValidator.steamRequestIdLength, 43);
  });

  test('normalizes practical email addresses', () {
    expect(
      validator.newAccountEmail(' Player+test@Example.COM '),
      'player+test@example.com',
    );
    expect(
      validator.loginEmail(' Player+test@Example.COM '),
      'player+test@example.com',
    );
  });

  test('rejects malformed and oversized account email addresses', () {
    for (final email in [
      'missing-at.example.com',
      'two@@example.com',
      '@example.com',
      '.leading@example.com',
      'trailing.@example.com',
      'double..dot@example.com',
      'user@localhost',
      'user@-example.com',
      'user@example-.com',
      'user@example..com',
    ]) {
      expect(
        () => validator.newAccountEmail(email),
        throwsA(_error('invalid_email')),
      );
    }
  });

  test('enforces exact email and component length boundaries', () {
    final nearMaxEmail = _longEmail(lastDomainLabelLength: 60);
    final maxEmail = _longEmail(lastDomainLabelLength: 61);
    final oversizedEmail = _longEmail(lastDomainLabelLength: 62);
    expect(nearMaxEmail.length, AuthInputValidator.maxEmailLength - 1);
    expect(maxEmail.length, AuthInputValidator.maxEmailLength);
    expect(oversizedEmail.length, AuthInputValidator.maxEmailLength + 1);
    expect(validator.newAccountEmail(nearMaxEmail), nearMaxEmail);
    expect(validator.newAccountEmail(maxEmail), maxEmail);
    expect(
      () => validator.newAccountEmail(oversizedEmail),
      throwsA(_error('invalid_email')),
    );

    final oversizedRawEmail = '${_repeat(' ', 120)}a@b.co${_repeat(' ', 129)}';
    expect(oversizedRawEmail.length, AuthInputValidator.maxEmailLength + 1);
    expect(
      () => validator.newAccountEmail(oversizedRawEmail),
      throwsA(_error('invalid_email')),
    );

    final nearMaxLocalPart = '${_repeat('l', 63)}@example.com';
    final maxLocalPart = '${_repeat('l', 64)}@example.com';
    final oversizedLocalPart = '${_repeat('l', 65)}@example.com';
    expect(validator.newAccountEmail(nearMaxLocalPart), nearMaxLocalPart);
    expect(validator.newAccountEmail(maxLocalPart), maxLocalPart);
    expect(
      () => validator.newAccountEmail(oversizedLocalPart),
      throwsA(_error('invalid_email')),
    );

    final nearMaxDomainLabel = 'user@${_repeat('d', 62)}.com';
    final maxDomainLabel = 'user@${_repeat('d', 63)}.com';
    final oversizedDomainLabel = 'user@${_repeat('d', 64)}.com';
    expect(validator.newAccountEmail(nearMaxDomainLabel), nearMaxDomainLabel);
    expect(validator.newAccountEmail(maxDomainLabel), maxDomainLabel);
    expect(
      () => validator.newAccountEmail(oversizedDomainLabel),
      throwsA(_error('invalid_email')),
    );
  });

  test('uses generic credential errors for malformed login input', () {
    expect(() => validator.loginPassword('x'), returnsNormally);
    expect(
      () => validator.loginPassword(
        _repeat('x', AuthInputValidator.maxPasswordLength - 1),
      ),
      returnsNormally,
    );
    expect(
      () => validator.loginPassword(
        _repeat('x', AuthInputValidator.maxPasswordLength),
      ),
      returnsNormally,
    );
    final emailError = _captureAuthError(() => validator.loginEmail('invalid'));
    final passwordError = _captureAuthError(() => validator.loginPassword(''));
    expect(emailError.code, 'invalid_credentials');
    expect(passwordError.code, emailError.code);
    expect(emailError.message, isNotEmpty);
    expect(passwordError.message, emailError.message);
    expect(
      () => validator.loginPassword(
        _repeat('x', AuthInputValidator.maxPasswordLength + 1),
      ),
      throwsA(_error('invalid_credentials')),
    );
  });

  test('bounds new passwords before Argon2 work', () {
    expect(
      () => validator.newAccountPassword(
        _repeat('x', AuthInputValidator.minNewPasswordLength),
      ),
      returnsNormally,
    );
    expect(
      () => validator.newAccountPassword(
        _repeat('x', AuthInputValidator.minNewPasswordLength + 1),
      ),
      returnsNormally,
    );
    expect(
      () => validator.newAccountPassword(
        _repeat('x', AuthInputValidator.maxPasswordLength - 1),
      ),
      returnsNormally,
    );
    expect(
      () => validator.newAccountPassword(
        _repeat('x', AuthInputValidator.maxPasswordLength),
      ),
      returnsNormally,
    );

    for (final password in [
      _repeat('x', AuthInputValidator.minNewPasswordLength - 1),
      _repeat('x', AuthInputValidator.maxPasswordLength + 1),
    ]) {
      expect(
        () => validator.newAccountPassword(password),
        throwsA(_error('weak_password')),
      );
    }
  });

  test('bounds refresh tokens before cryptographic work', () {
    expect(() => validator.refreshToken('x'), returnsNormally);
    expect(
      () => validator.refreshToken(
        _repeat('x', AuthInputValidator.maxRefreshTokenLength - 1),
      ),
      returnsNormally,
    );
    expect(
      () => validator.refreshToken(
        _repeat('x', AuthInputValidator.maxRefreshTokenLength),
      ),
      returnsNormally,
    );
    expect(
      () => validator.refreshToken(''),
      throwsA(_error('invalid_session')),
    );
    expect(
      () => validator.refreshToken(
        _repeat('x', AuthInputValidator.maxRefreshTokenLength + 1),
      ),
      throwsA(_error('invalid_session')),
    );
  });

  test('normalizes and bounds display names before database work', () {
    expect(validator.displayName('  Player   One  '), 'Player One');
    expect(validator.displayName('Żółty_Gracz-2'), 'Żółty_Gracz-2');
    expect(
      validator.displayName(
        _repeat('x', AuthInputValidator.minDisplayNameLength),
      ),
      _repeat('x', AuthInputValidator.minDisplayNameLength),
    );
    expect(
      validator.displayName(
        _repeat('x', AuthInputValidator.minDisplayNameLength + 1),
      ),
      _repeat('x', AuthInputValidator.minDisplayNameLength + 1),
    );
    expect(
      validator.displayName(
        _repeat('x', AuthInputValidator.maxDisplayNameLength - 1),
      ),
      _repeat('x', AuthInputValidator.maxDisplayNameLength - 1),
    );
    expect(
      validator.displayName(
        _repeat('x', AuthInputValidator.maxDisplayNameLength),
      ),
      _repeat('x', AuthInputValidator.maxDisplayNameLength),
    );
    for (final displayName in [
      _repeat('x', AuthInputValidator.minDisplayNameLength - 1),
      _repeat('x', AuthInputValidator.maxDisplayNameLength + 1),
      'bad<script>',
    ]) {
      expect(
        () => validator.displayName(displayName),
        throwsA(_error('invalid_display_name')),
      );
    }

    final nearMaxRawDisplayName = 'Player${_repeat(' ', 57)}';
    final maxRawDisplayName = 'Player${_repeat(' ', 58)}';
    final oversizedRawDisplayName = 'Player${_repeat(' ', 59)}';
    expect(
      nearMaxRawDisplayName.length,
      AuthInputValidator.maxRawDisplayNameLength - 1,
    );
    expect(validator.displayName(nearMaxRawDisplayName), 'Player');
    expect(
      maxRawDisplayName.length,
      AuthInputValidator.maxRawDisplayNameLength,
    );
    expect(validator.displayName(maxRawDisplayName), 'Player');
    expect(
      () => validator.displayName(oversizedRawDisplayName),
      throwsA(_error('invalid_display_name')),
    );
  });

  test('accepts only server-generated Steam request id shapes', () {
    final valid = List.filled(
      AuthInputValidator.steamRequestIdLength,
      'A',
    ).join();

    expect(validator.isValidSteamRequestId(valid), isTrue);
    expect(
      validator.isValidSteamRequestId(
        _repeat('A', AuthInputValidator.steamRequestIdLength - 1),
      ),
      isFalse,
    );
    expect(
      validator.isValidSteamRequestId(
        _repeat('A', AuthInputValidator.steamRequestIdLength + 1),
      ),
      isFalse,
    );
    expect(validator.isValidSteamRequestId('short'), isFalse);
    expect(validator.isValidSteamRequestId('${valid.substring(1)}!'), isFalse);
  });
}

Matcher _error(String code) {
  return isA<AccountAuthException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

AccountAuthException _captureAuthError(void Function() action) {
  Object? caught;
  try {
    action();
  } on Object catch (error) {
    caught = error;
  }
  expect(caught, isA<AccountAuthException>());
  return caught! as AccountAuthException;
}

String _longEmail({required int lastDomainLabelLength}) {
  return '${_repeat('l', 64)}@'
      '${_repeat('a', 63)}.'
      '${_repeat('b', 63)}.'
      '${_repeat('c', lastDomainLabelLength)}';
}

String _repeat(String value, int count) => List.filled(count, value).join();
