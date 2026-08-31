import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Server operability configuration', () {
    test('deploy waits for readiness while Docker probes liveness', () {
      final makefile = File('../Makefile').readAsStringSync();
      final dockerfile = File('Dockerfile').readAsStringSync();
      final dockerProbe = dockerfile
          .split('\n')
          .singleWhere((line) => line.trimLeft().startsWith('CMD curl'));

      expect(
        RegExp(
          r'^HEALTH_URL \?= https://api\.aonw\.net/readyz$',
          multiLine: true,
        ).hasMatch(makefile),
        isTrue,
      );
      expect(dockerProbe, contains('/livez'));
      expect(dockerProbe, isNot(contains('/readyz')));
    });

    test('database-backed modes bound session log retention', () {
      for (final mode in const [
        'development',
        'staging',
        'production',
        'test',
      ]) {
        final config = _loadConfig(mode);

        expect(
          config.sessionLogs.cleanupInterval,
          const Duration(hours: 24),
          reason: mode,
        );
        expect(
          config.sessionLogs.retentionPeriod,
          const Duration(days: 90),
          reason: mode,
        );
        expect(config.sessionLogs.retentionCount, 100000, reason: mode);
      }
    });

    test('production accepts database and Redis TLS overrides', () {
      final defaults = _loadConfig('production');
      final tls = _loadConfig(
        'production',
        environment: const {
          'SERVERPOD_DATABASE_REQUIRE_SSL': 'true',
          'SERVERPOD_REDIS_REQUIRE_SSL': 'true',
        },
      );

      expect(defaults.database!.requireSsl, isFalse);
      expect(defaults.redis!.requireSsl, isFalse);
      expect(tls.database!.requireSsl, isTrue);
      expect(tls.redis!.requireSsl, isTrue);
    });

    test('Compose profiles select immutable Serverpod run modes', () {
      final base =
          loadYaml(File('../compose.yml').readAsStringSync()) as YamlMap;
      final staging = File('../compose.staging.yml').readAsStringSync();
      final production = File('../compose.prod.yml').readAsStringSync();
      final baseServices = base['services'] as YamlMap;
      final baseServer = baseServices['server'] as YamlMap;
      final baseEnvironment = (baseServer['environment'] as YamlList)
          .cast<String>();

      for (final serviceName in const ['postgres', 'redis', 'server']) {
        final service = baseServices[serviceName] as YamlMap;
        expect(
          (service['profiles'] as YamlList).cast<String>(),
          equals(const ['dev', 'tunnel']),
          reason: serviceName,
        );
      }
      expect(baseEnvironment, contains('AONW_COMPOSE_RUN_MODE=development'));
      expect(baseEnvironment.join('\n'), isNot(contains('SERVERPOD_RUN_MODE')));

      _expectRunModeOverlay(
        staging,
        profile: 'staging',
        mode: 'staging',
        marker: 'AONW_STAGING_OVERLAY',
      );
      _expectRunModeOverlay(
        production,
        profile: 'prod',
        mode: 'production',
        marker: 'AONW_PROD_OVERLAY',
      );

      final caddy = baseServices['caddy'] as YamlMap;
      expect(
        (caddy['profiles'] as YamlList).cast<String>(),
        equals(const ['staging', 'prod']),
      );

      final makefile = File('../Makefile').readAsStringSync();
      expect(
        makefile,
        contains(
          r'COMPOSE_STAGING_FILES = $(COMPOSE_BASE_FILES) -f compose.staging.yml',
        ),
      );
      expect(
        makefile,
        contains(
          r'COMPOSE_PROD_FILES = $(COMPOSE_BASE_FILES) -f compose.prod.yml',
        ),
      );
      expect(
        makefile,
        contains(
          r'COMPOSE_PROFILE = $(COMPOSE) $(COMPOSE_PROFILE_FILES) --profile "$(PROFILE)"',
        ),
      );
      expect(makefile, contains('dev|tunnel|staging|prod)'));
      expect(makefile, isNot(contains(r'$(COMPOSE) --profile "$(PROFILE)"')));
      expect(
        makefile,
        contains(r'COMPOSE="$(COMPOSE)" tool/check_compose_run_modes.sh'),
      );
      expect(makefile, contains(r'$(COMPOSE) -f compose.yml config'));

      final composeCheck = File(
        '../tool/check_compose_run_modes.sh',
      ).readAsStringSync();
      expect(composeCheck, contains('AONW_COMPOSE_RUN_MODE=test'));
      expect(composeCheck, contains('production with both overlays'));
      expect(composeCheck, contains('staging with both overlays'));

      final rootEnvironment = File('../.env.example').readAsStringSync();
      expect(
        _hasLine(rootEnvironment, 'SERVERPOD_RUN_MODE=development'),
        isFalse,
      );
      expect(
        File('.env.example').readAsStringSync(),
        contains('SERVERPOD_RUN_MODE=development'),
      );

      final deploymentDocs = [
        File('../docs/build-and-deploy.md').readAsStringSync(),
        File('../docs/multiplayer-testflight.md').readAsStringSync(),
      ].join('\n');
      final stagingRunbook = File(
        '../docs/multiplayer-testflight.md',
      ).readAsStringSync();
      _expectProfileCommandsUseOverlay(
        deploymentDocs,
        profile: 'staging',
        overlay: 'compose.staging.yml',
      );
      _expectProfileCommandsUseOverlay(
        deploymentDocs,
        profile: 'prod',
        overlay: 'compose.prod.yml',
      );
      expect(
        _hasLine(deploymentDocs, 'SERVERPOD_RUN_MODE=production'),
        isFalse,
      );
      for (final value in const [
        'SERVERPOD_SERVER_ID=staging',
        'SERVERPOD_API_SERVER_PUBLIC_HOST=api.aonw.net',
        'SERVERPOD_API_SERVER_PUBLIC_PORT=443',
        'SERVERPOD_API_SERVER_PUBLIC_SCHEME=https',
        'SERVERPOD_WEB_SERVER_PUBLIC_HOST=api.aonw.net',
        'SERVERPOD_WEB_SERVER_PUBLIC_PORT=443',
        'SERVERPOD_WEB_SERVER_PUBLIC_SCHEME=https',
      ]) {
        expect(_hasLine(stagingRunbook, value), isTrue, reason: value);
      }

      final entrypoint = File('docker-entrypoint.sh').readAsStringSync();
      expect(
        entrypoint,
        contains(
          r'mode="${AONW_COMPOSE_RUN_MODE:-${SERVERPOD_RUN_MODE:-production}}"',
        ),
      );
      expect(entrypoint, contains(r'case "$staging_overlay:$prod_overlay" in'));
      expect(entrypoint, contains('Invalid Compose overlay combination.'));
      expect(entrypoint, contains('development|test|staging|production)'));
      expect(entrypoint, contains(r'if [ "$#" -ne 0 ]; then'));
      expect(entrypoint, contains('export SERVERPOD_RUN_MODE'));
      final managedArguments = entrypoint.substring(
        entrypoint.indexOf('set --'),
        entrypoint.indexOf(
          r'if [ "${SERVERPOD_APPLY_MIGRATIONS:-false}" = "true" ]',
        ),
      );
      expect(managedArguments, isNot(contains(r'"$@"')));

      final dockerfile = File('Dockerfile').readAsStringSync();
      expect(dockerfile, contains('ENV SERVERPOD_RUN_MODE=production'));
    });

    test('Compose and env examples expose backend TLS switches', () {
      final compose =
          loadYaml(File('../compose.yml').readAsStringSync()) as YamlMap;
      final services = compose['services'] as YamlMap;
      final server = services['server'] as YamlMap;
      final environment = server['environment'] as YamlList;

      expect(
        environment,
        contains(
          'SERVERPOD_DATABASE_REQUIRE_SSL='
          r'${SERVERPOD_DATABASE_REQUIRE_SSL:-false}',
        ),
      );
      expect(
        environment,
        contains(
          'SERVERPOD_REDIS_REQUIRE_SSL='
          r'${SERVERPOD_REDIS_REQUIRE_SSL:-false}',
        ),
      );

      for (final path in const ['../.env.example', '.env.example']) {
        final example = File(path).readAsStringSync();
        expect(
          _hasLine(example, 'SERVERPOD_DATABASE_REQUIRE_SSL=false'),
          isTrue,
          reason: path,
        );
        expect(
          _hasLine(example, 'SERVERPOD_REDIS_REQUIRE_SSL=false'),
          isTrue,
          reason: path,
        );
      }
    });

    test('Insights stays on loopback and outside the public proxy', () {
      const retiredInsightsHost =
          'insights.'
          'aonw.net';
      final compose =
          loadYaml(File('../compose.yml').readAsStringSync()) as YamlMap;
      final services = compose['services'] as YamlMap;
      final server = services['server'] as YamlMap;
      final caddy = services['caddy'] as YamlMap;
      final ports = (server['ports'] as YamlList).cast<String>();
      final serverEnvironment = (server['environment'] as YamlList)
          .cast<String>();
      final caddyEnvironment = caddy['environment'] as YamlMap;

      expect(
        ports,
        equals(const [
          r'${AONW_SERVER_BIND:-127.0.0.1}:${AONW_SERVER_PUBLIC_PORT:-8080}:${SERVERPOD_API_SERVER_PORT:-8080}',
          r'127.0.0.1:${AONW_INSIGHTS_PUBLIC_PORT:-8081}:${SERVERPOD_INSIGHTS_SERVER_PORT:-8081}',
          r'${AONW_WEB_BIND:-127.0.0.1}:${AONW_WEB_PUBLIC_PORT:-8082}:${SERVERPOD_WEB_SERVER_PORT:-8082}',
        ]),
      );
      expect(ports.join('\n'), isNot(contains('AONW_INSIGHTS_BIND')));
      expect(
        serverEnvironment,
        containsAll(const [
          'SERVERPOD_INSIGHTS_SERVER_PUBLIC_HOST=127.0.0.1',
          r'SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT=${AONW_INSIGHTS_PUBLIC_PORT:-8081}',
          'SERVERPOD_INSIGHTS_SERVER_PUBLIC_SCHEME=http',
        ]),
      );
      expect(
        serverEnvironment.join('\n'),
        isNot(contains(r'${SERVERPOD_INSIGHTS_SERVER_PUBLIC_')),
      );
      expect(caddyEnvironment.containsKey('AONW_INSIGHTS_HOST'), isFalse);
      expect(caddyEnvironment.containsKey('AONW_INSIGHTS_UPSTREAM'), isFalse);

      final caddyfile = File('../deploy/caddy/Caddyfile').readAsStringSync();
      expect(caddyfile, isNot(contains('AONW_INSIGHTS')));
      expect(caddyfile, isNot(contains('server:8081')));
      expect(caddyfile, isNot(contains(retiredInsightsHost)));

      for (final mode in const ['staging', 'production']) {
        final config =
            loadYaml(File('config/$mode.yaml').readAsStringSync()) as YamlMap;
        final insights = config['insightsServer'] as YamlMap;
        expect(insights['publicHost'], '127.0.0.1', reason: mode);
        expect(insights['publicPort'], 8081, reason: mode);
        expect(insights['publicScheme'], 'http', reason: mode);
      }
    });

    test('proxy identity headers cross only the private ingress boundary', () {
      final compose =
          loadYaml(File('../compose.yml').readAsStringSync()) as YamlMap;
      final services = compose['services'] as YamlMap;
      final server = services['server'] as YamlMap;
      final cloudflared = services['cloudflared'] as YamlMap;
      final ports = (server['ports'] as YamlList).cast<String>();

      expect(
        ports,
        containsAll(const [
          r'${AONW_SERVER_BIND:-127.0.0.1}:${AONW_SERVER_PUBLIC_PORT:-8080}:${SERVERPOD_API_SERVER_PORT:-8080}',
          r'127.0.0.1:${AONW_INSIGHTS_PUBLIC_PORT:-8081}:${SERVERPOD_INSIGHTS_SERVER_PORT:-8081}',
          r'${AONW_WEB_BIND:-127.0.0.1}:${AONW_WEB_PUBLIC_PORT:-8082}:${SERVERPOD_WEB_SERVER_PORT:-8082}',
        ]),
      );

      final caddyfile = File('../deploy/caddy/Caddyfile').readAsStringSync();
      final proxyBlocks = _reverseProxyBlocks(caddyfile);

      expect(caddyfile, contains('client_ip_headers CF-Connecting-IP'));
      expect(caddyfile, contains('trusted_proxies_strict'));
      final trustedProxyTokens = caddyfile
          .split('\n')
          .singleWhere(
            (line) => line.trimLeft().startsWith('trusted_proxies static '),
          )
          .trim()
          .split(RegExp(r'\s+'));
      expect(trustedProxyTokens.take(2), ['trusted_proxies', 'static']);
      expect(
        trustedProxyTokens.skip(2),
        unorderedEquals(_cloudflareProxyRanges),
      );
      expect(proxyBlocks, hasLength(3));
      for (final block in proxyBlocks) {
        expect(_hasLine(block, 'header_up -Forwarded'), isTrue, reason: block);
        expect(
          _hasLine(block, 'header_up -CF-Connecting-IP'),
          isTrue,
          reason: block,
        );
        expect(
          _hasLine(block, 'header_up X-Forwarded-For {client_ip}'),
          isTrue,
          reason: block,
        );
      }
      expect(
        cloudflared['command'],
        'tunnel --no-autoupdate --url '
        r'http://server:${SERVERPOD_API_SERVER_PORT:-8080}',
      );
      expect(cloudflared.containsKey('ports'), isFalse);
    });
  });
}

void _expectProfileCommandsUseOverlay(
  String source, {
  required String profile,
  required String overlay,
}) {
  final commands = source
      .split('\n')
      .where(
        (line) =>
            line.contains('docker compose') &&
            line.contains('--profile $profile'),
      );
  expect(commands, isNotEmpty, reason: profile);
  for (final command in commands) {
    expect(command, contains('-f compose.yml'), reason: command);
    expect(command, contains('-f $overlay'), reason: command);
  }
}

void _expectRunModeOverlay(
  String overlay, {
  required String profile,
  required String mode,
  required String marker,
}) {
  expect(
    RegExp('profiles: !override \\["$profile"\\]').allMatches(overlay),
    hasLength(3),
  );
  expect(overlay, contains('AONW_COMPOSE_RUN_MODE: $mode'));
  expect(overlay, contains('$marker: "1"'));
  expect(overlay, isNot(contains('SERVERPOD_RUN_MODE')));
}

ServerpodConfig _loadConfig(
  String mode, {
  Map<String, String> environment = const {},
}) {
  final source = File('config/$mode.yaml').readAsStringSync();
  final yaml = loadYaml(source) as YamlMap;
  return ServerpodConfig.loadFromMap(
    mode,
    'operability-test',
    const {
      'database': 'test-database-password',
      'redis': 'test-redis-password',
      'serviceSecret': 'test-service-secret-long-enough',
    },
    yaml,
    environment: environment,
  );
}

bool _hasLine(String source, String expected) {
  return source.split('\n').any((line) => line.trim() == expected);
}

List<String> _reverseProxyBlocks(String source) {
  final lines = source.split('\n');
  final blocks = <String>[];

  for (var index = 0; index < lines.length; index++) {
    if (!lines[index].trimLeft().startsWith('reverse_proxy ')) continue;

    final block = <String>[lines[index]];
    var depth = _braceDelta(lines[index]);
    while (depth > 0 && index + 1 < lines.length) {
      index++;
      block.add(lines[index]);
      depth += _braceDelta(lines[index]);
    }
    blocks.add(block.join('\n'));
  }

  return blocks;
}

int _braceDelta(String line) {
  return '{'.allMatches(line).length - '}'.allMatches(line).length;
}

const _cloudflareProxyRanges = <String>{
  '173.245.48.0/20',
  '103.21.244.0/22',
  '103.22.200.0/22',
  '103.31.4.0/22',
  '141.101.64.0/18',
  '108.162.192.0/18',
  '190.93.240.0/20',
  '188.114.96.0/20',
  '197.234.240.0/22',
  '198.41.128.0/17',
  '162.158.0.0/15',
  '104.16.0.0/13',
  '104.24.0.0/14',
  '172.64.0.0/13',
  '131.0.72.0/22',
  '2400:cb00::/32',
  '2606:4700::/32',
  '2803:f800::/32',
  '2405:b500::/32',
  '2405:8100::/32',
  '2a06:98c0::/29',
  '2c0f:f248::/32',
};
