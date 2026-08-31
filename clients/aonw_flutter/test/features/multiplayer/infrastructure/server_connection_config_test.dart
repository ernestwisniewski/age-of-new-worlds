import 'package:aonw_flutter/features/multiplayer/infrastructure/server_connection_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a secure absolute API origin', () {
    final config = ServerConnectionConfig.checked(
      source: 'https://api.aonw.example',
      platform: 'macos',
      buildNumber: 7,
      isRelease: true,
    );

    expect(config.host, 'https://api.aonw.example/');
    expect(config.platform, 'macos');
    expect(config.buildNumber, 7);
  });

  test('accepts HTTP loopback for local development', () {
    final config = ServerConnectionConfig.checked(
      source: 'http://127.0.0.1:8123',
      platform: 'macos',
      buildNumber: 1,
      isRelease: false,
    );

    expect(config.host, 'http://127.0.0.1:8123/');
  });

  test('rejects cleartext remote origins', () {
    expect(
      () => ServerConnectionConfig.checked(
        source: 'http://api.aonw.example',
        platform: 'macos',
        buildNumber: 1,
        isRelease: false,
      ),
      throwsStateError,
    );
  });

  test('rejects loopback in release mode', () {
    expect(
      () => ServerConnectionConfig.checked(
        source: 'http://localhost:8080',
        platform: 'macos',
        buildNumber: 1,
        isRelease: true,
      ),
      throwsStateError,
    );
  });

  test('rejects origins carrying path, credentials, query, or fragment', () {
    for (final source in [
      'https://api.aonw.example/v1',
      'https://user@api.aonw.example',
      'https://api.aonw.example?mode=test',
      'https://api.aonw.example#fragment',
    ]) {
      expect(
        () => ServerConnectionConfig.checked(
          source: source,
          platform: 'macos',
          buildNumber: 1,
          isRelease: false,
        ),
        throwsStateError,
        reason: source,
      );
    }
  });
}
