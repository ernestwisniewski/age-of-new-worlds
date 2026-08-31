import 'package:serverpod/serverpod.dart';

const criticalE2ePortEnvironmentKey = 'AONW_SERVERPOD_CRITICAL_E2E_PORT';
const criticalE2eDatabasePortEnvironmentKey = 'AONW_TEST_DATABASE_PORT';
const criticalE2eReadyNonceEnvironmentKey =
    'AONW_SERVERPOD_CRITICAL_E2E_READY_NONCE';
const criticalE2eReadyMarkerPrefix = 'AONW_CRITICAL_E2E_READY';
const _defaultBasePort = 18080;
const _defaultDatabasePort = 5432;
const _minimumBasePort = 1024;
const _maximumBasePort = 65533;
const _minimumDatabasePort = 1;
const _maximumDatabasePort = 65535;
final _monolithRole = ServerpodConfig.defaultConfig().role;

int parseCriticalE2eBasePort(String? raw) {
  if (raw == null) return _defaultBasePort;
  if (!RegExp(r'^\d{4,5}$').hasMatch(raw)) {
    throw const FormatException(
      '$criticalE2ePortEnvironmentKey must be an integer from '
      '$_minimumBasePort to $_maximumBasePort so all three listeners fit.',
    );
  }
  final port = int.parse(raw);
  _requireSafeBasePort(port);
  return port;
}

int parseCriticalE2eDatabasePort(String? raw) {
  if (raw == null) return _defaultDatabasePort;
  if (!RegExp(r'^\d{1,5}$').hasMatch(raw)) {
    throw const FormatException(
      '$criticalE2eDatabasePortEnvironmentKey must be an integer from '
      '$_minimumDatabasePort to $_maximumDatabasePort.',
    );
  }
  final port = int.parse(raw);
  if (port < _minimumDatabasePort || port > _maximumDatabasePort) {
    throw const FormatException(
      '$criticalE2eDatabasePortEnvironmentKey must be an integer from '
      '$_minimumDatabasePort to $_maximumDatabasePort.',
    );
  }
  return port;
}

String parseCriticalE2eReadyNonce(String? raw) {
  if (raw == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(raw)) {
    throw const FormatException(
      '$criticalE2eReadyNonceEnvironmentKey must be 64 lowercase hexadecimal '
      'characters.',
    );
  }
  return raw;
}

void validateCriticalE2eServerConfig({
  required ServerpodConfig source,
  required int basePort,
  required int databasePort,
}) {
  _requireSafeBasePort(basePort);
  final validatedDatabasePort = parseCriticalE2eDatabasePort(
    databasePort.toString(),
  );
  _require(
    source.runMode == 'test',
    'run mode must be test, got ${source.runMode}.',
  );
  _require(
    source.serverId == 'critical-e2e',
    'server id must be critical-e2e, got ${source.serverId}.',
  );
  _require(
    source.role == _monolithRole,
    'server role must be monolith, got ${source.role.name}.',
  );
  _require(
    source.loggingMode == ServerpodLoggingMode.normal,
    'logging mode must be normal, got ${source.loggingMode.name}.',
  );
  _require(source.applyMigrations, 'database migrations must be enabled.');
  _require(
    !source.applyRepairMigration,
    'database repair migrations must be disabled.',
  );
  _requireServer(source.apiServer, basePort, 'API');
  _requireServer(source.insightsServer, basePort + 1, 'Insights');
  _requireServer(source.webServer, basePort + 2, 'web');

  final database = source.database;
  _require(database != null, 'database configuration is required.');
  _require(
    database!.dialect == DatabaseDialect.postgres &&
        database.host == 'localhost' &&
        database.port == validatedDatabasePort &&
        database.name == 'aonw_test' &&
        database.user == 'aonw' &&
        !database.requireSsl &&
        !database.isUnixSocket &&
        database.searchPaths == null,
    'database must be PostgreSQL '
    'aonw@localhost:$validatedDatabasePort/aonw_test without SSL, Unix '
    'sockets, or search-path overrides.',
  );
  _require(
    source.redis == null,
    'Redis configuration must be absent for the critical E2E server.',
  );
  _require(
    !source.futureCallExecutionEnabled,
    'future-call execution must be disabled.',
  );
}

void _requireServer(ServerConfig? server, int port, String name) {
  _require(server != null, '$name listener configuration is required.');
  _require(
    server!.port == port &&
        server.publicHost == '127.0.0.1' &&
        server.publicPort == port &&
        server.publicScheme == 'http',
    '$name listener must be http://127.0.0.1:$port.',
  );
}

void _requireSafeBasePort(int? port) {
  if (port == null || port < _minimumBasePort || port > _maximumBasePort) {
    throw const FormatException(
      '$criticalE2ePortEnvironmentKey must be an integer from '
      '$_minimumBasePort to $_maximumBasePort so all three listeners fit.',
    );
  }
}

void _require(bool condition, String message) {
  if (!condition) {
    throw StateError('Unsafe critical E2E configuration: $message');
  }
}
