import 'package:aonw_server/src/auth/email_password_verifier.dart';
import 'package:test/test.dart';

void main() {
  test(
    'unknown accounts perform dummy validation with a cached hash',
    () async {
      var hashesCreated = 0;
      final validatedHashes = <String>[];
      final verifier = EmailPasswordVerifier(
        createHash: (secret) async {
          hashesCreated += 1;
          return 'dummy-hash-for-$secret';
        },
        validateHash: (secret, hashString) async {
          validatedHashes.add(hashString);
          return false;
        },
      );

      expect(
        await verifier.matches(password: 'first', storedHash: null),
        isFalse,
      );
      expect(
        await verifier.matches(password: 'second', storedHash: ''),
        isFalse,
      );
      expect(hashesCreated, 1);
      expect(validatedHashes, hasLength(2));
      expect(validatedHashes.toSet(), hasLength(1));
    },
  );

  test('valid stored hashes do not create the dummy hash', () async {
    var hashesCreated = 0;
    final verifier = EmailPasswordVerifier(
      createHash: (_) async {
        hashesCreated += 1;
        return 'dummy';
      },
      validateHash: (secret, hashString) async =>
          secret == 'correct' && hashString == 'stored',
    );

    expect(
      await verifier.matches(password: 'correct', storedHash: 'stored'),
      isTrue,
    );
    expect(hashesCreated, 0);
  });

  test('malformed stored hashes fall back to dummy validation', () async {
    final validatedHashes = <String>[];
    final verifier = EmailPasswordVerifier(
      createHash: (_) async => 'dummy',
      validateHash: (secret, hashString) async {
        validatedHashes.add(hashString);
        if (hashString == 'malformed') throw const FormatException('hash');
        return false;
      },
    );

    expect(
      await verifier.matches(password: 'password', storedHash: 'malformed'),
      isFalse,
    );
    expect(validatedHashes, ['malformed', 'dummy']);
  });
}
