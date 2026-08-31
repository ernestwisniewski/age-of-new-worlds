import 'dart:async';
import 'dart:io';

import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

Future<void> main(List<String> args) async {
  final config = _SeedConfig.fromArgs(args);
  try {
    await _SeedTestUsers(config).run();
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_SeedConfig.usage);
    exitCode = 64;
  } on TimeoutException catch (error) {
    stderr.writeln('Serverpod test user seed timed out: ${error.message}');
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr
      ..writeln('Serverpod test user seed failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}

class _SeedTestUsers {
  const _SeedTestUsers(this.config);

  final _SeedConfig config;

  Future<void> run() async {
    final host = _normalizeHost(config.host);
    final publicClient = sp.Client(host);
    stdout
      ..writeln('Serverpod test user seed')
      ..writeln('  host: $host');

    try {
      for (final user in config.users) {
        final auth = await _createOrLogin(publicClient, user);
        final authenticatedClient = sp.Client(host)
          ..authKeyProvider = _BearerTokenProvider(auth.token);
        try {
          final displayName = await authenticatedClient.emailIdp
              .updateDisplayName(displayName: user.displayName)
              .timeout(config.requestTimeout);
          stdout.writeln('  ${user.email} / ${config.password} / $displayName');
        } finally {
          authenticatedClient.close();
        }
      }
    } finally {
      publicClient.close();
    }

    stdout.writeln('Seeded ${config.users.length} test users.');
  }

  Future<sp_auth.AuthSuccess> _createOrLogin(
    sp.Client client,
    _SeedUser user,
  ) async {
    try {
      return await client.emailIdp
          .login(email: user.email, password: config.password)
          .timeout(config.requestTimeout);
    } on sp.AccountAuthException catch (error) {
      if (error.code != 'invalid_credentials') rethrow;
      try {
        return await client.emailIdp
            .createAccount(
              email: user.email,
              password: config.password,
              displayName: user.displayName,
            )
            .timeout(config.requestTimeout);
      } on sp.AccountAuthException catch (createError) {
        if (createError.code != 'account_exists') rethrow;
        return client.emailIdp
            .login(email: user.email, password: config.password)
            .timeout(config.requestTimeout);
      }
    }
  }

  static String _normalizeHost(String host) {
    return host.endsWith('/') ? host : '$host/';
  }
}

final class _BearerTokenProvider implements sp.ClientAuthKeyProvider {
  const _BearerTokenProvider(this.token);

  final String token;

  @override
  Future<String?> get authHeaderValue async =>
      sp.wrapAsBearerAuthHeaderValue(token);
}

class _SeedConfig {
  const _SeedConfig({
    required this.host,
    required this.password,
    required this.users,
    required this.requestTimeout,
  });

  final String host;
  final String password;
  final List<_SeedUser> users;
  final Duration requestTimeout;

  static const usage = '''
Usage:
  dart run tool/seed_test_users.dart [options]

Options:
  --host URL            Serverpod API host. Default: env AONW_SERVERPOD_SEED_HOST or http://127.0.0.1:8080/
  --password TEXT      Password for seeded accounts. Default: env AONW_SERVERPOD_SEED_PASSWORD or AonwTest123!
  --email-domain TEXT  Email domain for test accounts. Default: env AONW_SERVERPOD_SEED_EMAIL_DOMAIN or example.test
''';

  factory _SeedConfig.fromArgs(List<String> args) {
    final options = <String, String>{};
    for (var i = 0; i < args.length; i += 1) {
      final arg = args[i];
      if (arg == '--help' || arg == '-h') {
        stdout.write(usage);
        exit(0);
      }
      if (!arg.startsWith('--')) {
        throw FormatException('Unexpected argument: $arg');
      }
      final equals = arg.indexOf('=');
      if (equals != -1) {
        options[arg.substring(2, equals)] = arg.substring(equals + 1);
        continue;
      }
      if (i + 1 >= args.length || args[i + 1].startsWith('--')) {
        throw FormatException('Missing value for $arg');
      }
      options[arg.substring(2)] = args[i + 1];
      i += 1;
    }

    String option(String key, String envKey, String fallback) {
      return options[key] ?? Platform.environment[envKey] ?? fallback;
    }

    final domain = option(
      'email-domain',
      'AONW_SERVERPOD_SEED_EMAIL_DOMAIN',
      'example.test',
    );
    return _SeedConfig(
      host: option(
        'host',
        'AONW_SERVERPOD_SEED_HOST',
        'http://127.0.0.1:8080/',
      ),
      password: option(
        'password',
        'AONW_SERVERPOD_SEED_PASSWORD',
        'AonwTest123!',
      ),
      users: [
        _SeedUser(email: 'test1@$domain', displayName: 'Tester One'),
        _SeedUser(email: 'test2@$domain', displayName: 'Tester Two'),
        _SeedUser(email: 'test3@$domain', displayName: 'Tester Three'),
        _SeedUser(email: 'test4@$domain', displayName: 'Tester Four'),
      ],
      requestTimeout: const Duration(seconds: 10),
    );
  }
}

class _SeedUser {
  const _SeedUser({required this.email, required this.displayName});

  final String email;
  final String displayName;
}
