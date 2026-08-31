import 'package:flutter/foundation.dart';

final class ServerConnectionConfig {
  const ServerConnectionConfig._({
    required this.host,
    required this.platform,
    required this.buildNumber,
    required this.requestTimeout,
  });

  factory ServerConnectionConfig.production() => ServerConnectionConfig.checked(
    source: const String.fromEnvironment(
      'AONW_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8080',
    ),
    platform: defaultTargetPlatform.name,
    buildNumber: const int.fromEnvironment(
      'AONW_BUILD_NUMBER',
      defaultValue: 1,
    ),
    isRelease: kReleaseMode,
  );

  factory ServerConnectionConfig.checked({
    required String source,
    required String platform,
    required int buildNumber,
    required bool isRelease,
    Duration requestTimeout = const Duration(seconds: 15),
  }) {
    final uri = Uri.tryParse(source);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw StateError('AONW_API_BASE_URL must be an absolute origin.');
    }
    final loopback = uri.host == '127.0.0.1' || uri.host == 'localhost';
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) {
      throw StateError(
        'The AoNW API must use HTTPS outside the local loopback.',
      );
    }
    if (isRelease && loopback) {
      throw StateError(
        'A release build requires a non-loopback AONW_API_BASE_URL.',
      );
    }
    if (buildNumber <= 0) {
      throw StateError('AONW_BUILD_NUMBER must be positive.');
    }
    if (platform.trim().isEmpty) {
      throw StateError('The client platform must not be empty.');
    }
    if (requestTimeout <= Duration.zero) {
      throw StateError('The request timeout must be positive.');
    }
    return ServerConnectionConfig._(
      host: uri.replace(path: '/').toString(),
      platform: platform,
      buildNumber: buildNumber,
      requestTimeout: requestTimeout,
    );
  }

  final String host;
  final String platform;
  final int buildNumber;
  final Duration requestTimeout;
}
