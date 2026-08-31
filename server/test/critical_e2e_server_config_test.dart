import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'support/critical_e2e_server_config.dart';

void main() {
  group('critical E2E server config', () {
    test('accepts the exact environment-derived test configuration', () {
      final config = ServerpodConfig.loadFromMap(
        'test',
        'critical-e2e',
        const {
          'database': 'test-database-password',
          'serviceSecret': 'test-service-secret',
        },
        _baseConfigMap(),
        environment: _environment(basePort: 19000, databasePort: 32768),
      );

      expect(
        () => validateCriticalE2eServerConfig(
          source: config,
          basePort: 19000,
          databasePort: 32768,
        ),
        returnsNormally,
      );
      _expectServer(config.apiServer, 19000);
      _expectServer(config.insightsServer!, 19001);
      _expectServer(config.webServer!, 19002);
      expect(config.database?.port, 32768);
      expect(config.redis, isNull);
      expect(config.futureCallExecutionEnabled, isFalse);
    });

    final unsafeConfigs =
        <({String name, ServerpodConfig source, String message})>[
          (
            name: 'non-test run mode',
            source: _sourceConfig(runMode: 'production'),
            message: 'run mode must be test',
          ),
          (
            name: 'wrong server id',
            source: _sourceConfig(serverId: 'other'),
            message: 'server id must be critical-e2e',
          ),
          (
            name: 'non-monolith role',
            source: _sourceConfig(roleSource: _roleConfig('maintenance')),
            message: 'server role must be monolith',
          ),
          (
            name: 'verbose logging',
            source: _sourceConfig(loggingMode: ServerpodLoggingMode.verbose),
            message: 'logging mode must be normal',
          ),
          (
            name: 'disabled migrations',
            source: _sourceConfig(applyMigrations: false),
            message: 'database migrations must be enabled',
          ),
          (
            name: 'repair migration',
            source: _sourceConfig(applyRepairMigration: true),
            message: 'database repair migrations must be disabled',
          ),
          (
            name: 'wrong API listener',
            source: _sourceConfig(apiServer: _server(18079)),
            message: 'API listener must be http://127.0.0.1:18080',
          ),
          (
            name: 'missing Insights listener',
            source: _sourceConfig(includeInsightsServer: false),
            message: 'Insights listener configuration is required',
          ),
          (
            name: 'wrong web listener',
            source: _sourceConfig(webServer: _server(18083)),
            message: 'web listener must be http://127.0.0.1:18082',
          ),
          (
            name: 'missing database',
            source: _sourceConfig(includeDatabase: false),
            message: 'database configuration is required',
          ),
          (
            name: 'remote database host',
            source: _sourceConfig(database: _database(host: 'db.example.test')),
            message: 'database must be PostgreSQL',
          ),
          (
            name: 'wrong database port',
            source: _sourceConfig(database: _database(port: 5433)),
            message: 'database must be PostgreSQL',
          ),
          (
            name: 'wrong database name',
            source: _sourceConfig(database: _database(name: 'aonw')),
            message: 'database must be PostgreSQL',
          ),
          (
            name: 'wrong database user',
            source: _sourceConfig(database: _database(user: 'postgres')),
            message: 'database must be PostgreSQL',
          ),
          (
            name: 'database SSL',
            source: _sourceConfig(database: _database(requireSsl: true)),
            message: 'database must be PostgreSQL',
          ),
          (
            name: 'database Unix socket',
            source: _sourceConfig(database: _database(isUnixSocket: true)),
            message: 'database must be PostgreSQL',
          ),
          (
            name: 'database search path',
            source: _sourceConfig(
              database: _database(searchPaths: const ['private']),
            ),
            message: 'database must be PostgreSQL',
          ),
          (
            name: 'configured Redis',
            source: _sourceConfig(
              redis: RedisConfig(enabled: false, host: 'localhost', port: 6379),
            ),
            message: 'Redis configuration must be absent',
          ),
          (
            name: 'future calls enabled',
            source: _sourceConfig(futureCallExecutionEnabled: true),
            message: 'future-call execution must be disabled',
          ),
        ];

    for (final unsafe in unsafeConfigs) {
      test('rejects ${unsafe.name}', () {
        expect(
          () => validateCriticalE2eServerConfig(
            source: unsafe.source,
            basePort: 18080,
            databasePort: 5432,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains(unsafe.message),
            ),
          ),
        );
      });
    }

    test('accepts only base ports that leave room for three listeners', () {
      expect(parseCriticalE2eBasePort(null), 18080);
      expect(parseCriticalE2eBasePort('1024'), 1024);
      expect(parseCriticalE2eBasePort('65533'), 65533);

      for (final raw in [
        '',
        '123',
        'not-a-port',
        '+1024',
        ' 1024',
        '1023',
        '65534',
      ]) {
        expect(() => parseCriticalE2eBasePort(raw), throwsFormatException);
      }
      for (final port in [1023, 65534]) {
        expect(
          () => validateCriticalE2eServerConfig(
            source: _sourceConfig(),
            basePort: port,
            databasePort: 5432,
          ),
          throwsFormatException,
        );
      }
    });

    test('accepts and enforces the dedicated PostgreSQL port', () {
      expect(parseCriticalE2eDatabasePort(null), 5432);
      expect(parseCriticalE2eDatabasePort('32768'), 32768);
      expect(parseCriticalE2eDatabasePort('1'), 1);
      expect(parseCriticalE2eDatabasePort('65535'), 65535);

      expect(
        () => validateCriticalE2eServerConfig(
          source: _sourceConfig(database: _database(port: 32768)),
          basePort: 18080,
          databasePort: 32768,
        ),
        returnsNormally,
      );
      expect(
        () => validateCriticalE2eServerConfig(
          source: _sourceConfig(database: _database(port: 32768)),
          basePort: 18080,
          databasePort: 5432,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('aonw@localhost:5432/aonw_test'),
          ),
        ),
      );

      for (final raw in ['', 'not-a-port', '0', '65536', '+5432', ' 5432']) {
        expect(
          () => parseCriticalE2eDatabasePort(raw),
          throwsFormatException,
          reason: raw,
        );
      }
      for (final port in [0, 65536]) {
        expect(
          () => validateCriticalE2eServerConfig(
            source: _sourceConfig(),
            basePort: 18080,
            databasePort: port,
          ),
          throwsFormatException,
        );
      }
    });

    test('accepts only a cryptographic ready nonce', () {
      final nonce = 'a' * 64;
      expect(parseCriticalE2eReadyNonce(nonce), nonce);
      for (final raw in <String?>[null, '', 'a' * 63, 'A' * 64, 'g' * 64]) {
        expect(() => parseCriticalE2eReadyNonce(raw), throwsFormatException);
      }
    });
  });
}

ServerpodConfig _sourceConfig({
  String runMode = 'test',
  String serverId = 'critical-e2e',
  ServerpodConfig? roleSource,
  ServerpodLoggingMode loggingMode = ServerpodLoggingMode.normal,
  bool applyMigrations = true,
  bool applyRepairMigration = false,
  ServerConfig? apiServer,
  bool includeInsightsServer = true,
  ServerConfig? insightsServer,
  ServerConfig? webServer,
  bool includeDatabase = true,
  DatabaseConfig? database,
  RedisConfig? redis,
  bool futureCallExecutionEnabled = false,
}) => ServerpodConfig(
  apiServer: apiServer ?? _server(18080),
  runMode: runMode,
  serverId: serverId,
  role: roleSource?.role ?? ServerpodConfig.defaultConfig().role,
  loggingMode: loggingMode,
  applyMigrations: applyMigrations,
  applyRepairMigration: applyRepairMigration,
  maxRequestSize: 1048576,
  insightsServer: includeInsightsServer
      ? insightsServer ?? _server(18081)
      : null,
  webServer: webServer ?? _server(18082),
  database: includeDatabase ? database ?? _database() : null,
  redis: redis,
  serviceSecret: 'test-service-secret',
  futureCallExecutionEnabled: futureCallExecutionEnabled,
  websocketPingInterval: const Duration(seconds: 20),
);

ServerpodConfig _roleConfig(String role) => ServerpodConfig.loadFromMap(
  'test',
  null,
  const {},
  const {},
  environment: {'SERVERPOD_SERVER_ROLE': role},
);

DatabaseConfig _database({
  String host = 'localhost',
  int port = 5432,
  String name = 'aonw_test',
  String user = 'aonw',
  bool requireSsl = false,
  bool isUnixSocket = false,
  List<String>? searchPaths,
}) => DatabaseConfig(
  host: host,
  port: port,
  user: user,
  password: 'test-database-password',
  name: name,
  requireSsl: requireSsl,
  isUnixSocket: isUnixSocket,
  searchPaths: searchPaths,
);

ServerConfig _server(int port) => ServerConfig(
  port: port,
  publicHost: '127.0.0.1',
  publicPort: port,
  publicScheme: 'http',
);

Map<String, Object?> _baseConfigMap() => {
  'apiServer': {
    'port': 8080,
    'publicHost': 'unsafe.example.test',
    'publicPort': 8080,
    'publicScheme': 'https',
  },
  'insightsServer': {
    'port': 8081,
    'publicHost': 'unsafe.example.test',
    'publicPort': 8081,
    'publicScheme': 'https',
  },
  'webServer': {
    'port': 8082,
    'publicHost': 'unsafe.example.test',
    'publicPort': 8082,
    'publicScheme': 'https',
  },
  'database': {
    'host': 'unsafe.example.test',
    'port': 5432,
    'name': 'unsafe',
    'user': 'unsafe',
    'requireSsl': true,
    'isUnixSocket': true,
  },
  'redis': {'enabled': true, 'host': 'unsafe.example.test', 'port': 6379},
  'futureCallExecutionEnabled': true,
  'sessionLogs': {'persistentEnabled': true, 'consoleEnabled': true},
};

Map<String, String> _environment({
  required int basePort,
  required int databasePort,
}) => {
  'SERVERPOD_RUN_MODE': 'test',
  'SERVERPOD_SERVER_ID': 'critical-e2e',
  'SERVERPOD_SERVER_ROLE': 'monolith',
  'SERVERPOD_LOGGING_MODE': 'normal',
  'SERVERPOD_APPLY_MIGRATIONS': 'true',
  'SERVERPOD_APPLY_REPAIR_MIGRATION': 'false',
  'SERVERPOD_API_SERVER_PORT': '$basePort',
  'SERVERPOD_API_SERVER_PUBLIC_HOST': '127.0.0.1',
  'SERVERPOD_API_SERVER_PUBLIC_PORT': '$basePort',
  'SERVERPOD_API_SERVER_PUBLIC_SCHEME': 'http',
  'SERVERPOD_INSIGHTS_SERVER_PORT': '${basePort + 1}',
  'SERVERPOD_INSIGHTS_SERVER_PUBLIC_HOST': '127.0.0.1',
  'SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT': '${basePort + 1}',
  'SERVERPOD_INSIGHTS_SERVER_PUBLIC_SCHEME': 'http',
  'SERVERPOD_WEB_SERVER_PORT': '${basePort + 2}',
  'SERVERPOD_WEB_SERVER_PUBLIC_HOST': '127.0.0.1',
  'SERVERPOD_WEB_SERVER_PUBLIC_PORT': '${basePort + 2}',
  'SERVERPOD_WEB_SERVER_PUBLIC_SCHEME': 'http',
  'SERVERPOD_DATABASE_HOST': 'localhost',
  'SERVERPOD_DATABASE_PORT': '$databasePort',
  'SERVERPOD_DATABASE_NAME': 'aonw_test',
  'SERVERPOD_DATABASE_USER': 'aonw',
  'SERVERPOD_DATABASE_DIALECT': 'postgres',
  'SERVERPOD_DATABASE_REQUIRE_SSL': 'false',
  'SERVERPOD_DATABASE_IS_UNIX_SOCKET': 'false',
  'SERVERPOD_REDIS_ENABLED': 'false',
  'SERVERPOD_FUTURE_CALL_EXECUTION_ENABLED': 'false',
  'SERVERPOD_SESSION_PERSISTENT_LOG_ENABLED': 'false',
  'SERVERPOD_SESSION_CONSOLE_LOG_ENABLED': 'false',
};

void _expectServer(ServerConfig server, int port) {
  expect(server.port, port);
  expect(server.publicHost, '127.0.0.1');
  expect(server.publicPort, port);
  expect(server.publicScheme, 'http');
}
