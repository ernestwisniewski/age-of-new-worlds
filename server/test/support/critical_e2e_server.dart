import 'dart:io';

import 'package:aonw_server/server.dart';
import 'package:serverpod/serverpod.dart';

import 'critical_e2e_loopback_io_overrides.dart';
import 'critical_e2e_server_config.dart';

Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    throw const FormatException(
      'The critical E2E server accepts configuration only through its '
      'sanitized environment.',
    );
  }
  final basePort = parseCriticalE2eBasePort(
    Platform.environment[criticalE2ePortEnvironmentKey],
  );
  final databasePort = parseCriticalE2eDatabasePort(
    Platform.environment[criticalE2eDatabasePortEnvironmentKey],
  );
  final readyNonce = parseCriticalE2eReadyNonce(
    Platform.environment[criticalE2eReadyNonceEnvironmentKey],
  );
  final config = ServerpodConfig.load('test', 'critical-e2e', {
    'database': _requiredEnvironment('SERVERPOD_PASSWORD_database'),
    'serviceSecret': _requiredEnvironment('SERVERPOD_SERVICE_SECRET'),
  });
  validateCriticalE2eServerConfig(
    source: config,
    basePort: basePort,
    databasePort: databasePort,
  );
  await IOOverrides.runWithIOOverrides(
    () => run(const []),
    CriticalE2eLoopbackIoOverrides(basePort: basePort),
  );
  stdout.writeln('$criticalE2eReadyMarkerPrefix $readyNonce');
}

String _requiredEnvironment(String key) {
  final value = Platform.environment[key];
  if (value == null || value.isEmpty) {
    throw FormatException('$key must not be empty.');
  }
  return value;
}
