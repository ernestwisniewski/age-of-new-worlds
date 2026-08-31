import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

Future<void> main(List<String> args) async {
  late final _CriticalE2eConfig config;
  try {
    config = _CriticalE2eConfig.fromArgs(args);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_CriticalE2eConfig.usage);
    exitCode = 64;
    return;
  }

  try {
    await _CriticalE2e(config).run();
  } on TimeoutException catch (error) {
    stderr.writeln('Critical Serverpod E2E timed out: ${error.message}');
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr
      ..writeln('Critical Serverpod E2E failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}

final class _CriticalE2e {
  _CriticalE2e(this.config);

  final _CriticalE2eConfig config;
  final List<sp.Client> _clients = [];

  Future<void> run() async {
    final host = _normalizeHost(config.host);
    final loopbackProof = await _verifyLoopbackOnly(Uri.parse(host));
    final runId = DateTime.now().toUtc().microsecondsSinceEpoch;
    final suffix = (runId % 1000000).toString().padLeft(6, '0');
    final password = 'AonwCritical-$runId-password';
    final ownerEmail = 'critical-owner-$runId@example.test';
    final guestEmail = 'critical-guest-$runId@example.test';
    final publicClient = _client(host);

    try {
      final registeredOwner = await _request(
        publicClient.emailIdp.createAccount(
          email: ownerEmail,
          password: password,
          displayName: 'Critical Owner $suffix',
        ),
      );
      final registeredGuest = await _request(
        publicClient.emailIdp.createAccount(
          email: guestEmail,
          password: password,
          displayName: 'Critical Guest $suffix',
        ),
      );
      final ownerLogin = await _request(
        publicClient.emailIdp.login(email: ownerEmail, password: password),
      );
      final guestLogin = await _request(
        publicClient.emailIdp.login(email: guestEmail, password: password),
      );
      _expect(
        ownerLogin.authUserId == registeredOwner.authUserId &&
            guestLogin.authUserId == registeredGuest.authUserId,
        'Email login must return the accounts created at the public boundary.',
      );
      _requireRefreshToken(ownerLogin, 'owner login');
      _requireRefreshToken(guestLogin, 'guest login');

      final ownerClient = _authenticatedClient(host, ownerLogin);
      final guestClient = _authenticatedClient(host, guestLogin);
      final mapId = 'critical-game-$runId';
      final created = await _request(
        ownerClient.game.createMatch(
          sp.GameCreateMatchRequest(
            mapId: mapId,
            mapDocument: _mapDocument(mapId),
            scenarioDocument: _scenarioDocument(mapId),
            rulesetId: 'aonw-standard',
            matchIdentityJson: _matchIdentityDocument(),
            fogEnabled: true,
            creatorPlayerId: 'player-1',
          ),
        ),
      );
      _expect(
        created.mapId == mapId &&
            created.revision >= 0 &&
            created.eventOffset == 0,
        'Engine match creation must return the current content identity at offset 0.',
      );

      final ownerInitial = await _request(
        ownerClient.game.resync(created.matchId),
      );
      final guestInitial = await _request(
        guestClient.game.joinMatch(
          sp.GameJoinMatchRequest(
            matchId: created.matchId,
            playerId: 'player-2',
          ),
        ),
      );
      _expectPrivateSnapshot(ownerInitial, 'player-1');
      _expectPrivateSnapshot(guestInitial, 'player-2');

      final commandId = 'owner-submit-$runId';
      final accepted = await _request(
        ownerClient.game.submitTurn(
          sp.GameSubmitTurnRequest(
            matchId: created.matchId,
            clientCommandId: commandId,
            expectedRevision: created.revision,
          ),
        ),
      );
      final duplicate = await _request(
        ownerClient.game.submitTurn(
          sp.GameSubmitTurnRequest(
            matchId: created.matchId,
            clientCommandId: commandId,
            expectedRevision: created.revision,
          ),
        ),
      );
      _expect(
        !accepted.duplicate &&
            duplicate.duplicate &&
            duplicate.initialEventOffset == accepted.initialEventOffset &&
            duplicate.finalEventOffset == accepted.finalEventOffset &&
            duplicate.outcomeJson == accepted.outcomeJson,
        'A retried clientCommandId must reuse one persisted engine outcome.',
      );
      final ownerRevision = _expectRecipientOutcome(
        accepted.outcomeJson,
        'player-1',
      );

      final rotatedGuest = await _rotate(
        publicClient,
        guestLogin,
        context: 'guest',
      );
      final resumedGuest = _authenticatedClient(host, rotatedGuest);
      final guestResync = await _request(
        resumedGuest.game.resync(created.matchId),
      );
      _expect(
        guestResync.eventOffset == accepted.finalEventOffset,
        'A refreshed guest must resync to the durable owner-command offset.',
      );
      _expectPrivateSnapshot(guestResync, 'player-2');

      final guestAccepted = await _request(
        resumedGuest.game.submitTurn(
          sp.GameSubmitTurnRequest(
            matchId: created.matchId,
            clientCommandId: 'guest-submit-$runId',
            expectedRevision: ownerRevision,
          ),
        ),
      );
      _expect(!guestAccepted.duplicate, 'The guest command must be new.');
      final finalRevision = _expectRecipientOutcome(
        guestAccepted.outcomeJson,
        'player-2',
      );

      final rotatedOwner = await _rotate(
        publicClient,
        ownerLogin,
        context: 'owner',
      );
      final resumedOwner = _authenticatedClient(host, rotatedOwner);
      final ownerResync = await _request(
        resumedOwner.game.resync(created.matchId),
      );
      _expect(
        ownerResync.eventOffset == guestAccepted.finalEventOffset,
        'A refreshed owner must resync to the durable final offset.',
      );
      _expectPrivateSnapshot(ownerResync, 'player-1');
      final ownerMatches = await _request(resumedOwner.game.listMatches());
      final guestMatches = await _request(resumedGuest.game.listMatches());
      _expect(
        ownerMatches.any((match) => match.matchId == created.matchId) &&
            guestMatches.any((match) => match.matchId == created.matchId),
        'Both authenticated participants must list the persisted match.',
      );

      stdout
        ..writeln('Critical Serverpod E2E passed.')
        ..writeln('  match: ${created.matchId}')
        ..writeln('  owner: ${ownerLogin.authUserId}')
        ..writeln('  guest: ${guestLogin.authUserId}')
        ..writeln('  idempotent offset: ${duplicate.finalEventOffset}')
        ..writeln('  resync offset: ${ownerResync.eventOffset}')
        ..writeln('  final revision: $finalRevision')
        ..writeln('  listener isolation: $loopbackProof');
    } finally {
      for (final client in _clients.reversed) {
        client.close();
      }
    }
  }

  sp.Client _client(String host) {
    final client = sp.Client(host, connectionTimeout: config.requestTimeout);
    _clients.add(client);
    return client;
  }

  sp.Client _authenticatedClient(String host, sp_auth.AuthSuccess auth) {
    return _client(host)..authKeyProvider = _BearerTokenProvider(auth.token);
  }

  Future<sp_auth.AuthSuccess> _rotate(
    sp.Client publicClient,
    sp_auth.AuthSuccess current, {
    required String context,
  }) async {
    final previous = _requireRefreshToken(current, context);
    final rotated = await _request(
      publicClient.jwtRefresh.refreshAccessToken(refreshToken: previous),
    );
    _expect(
      rotated.authUserId == current.authUserId &&
          _requireRefreshToken(rotated, '$context refresh') != previous,
      'The $context refresh token must rotate for the same account.',
    );
    return rotated;
  }

  Future<T> _request<T>(Future<T> request) =>
      request.timeout(config.requestTimeout);
}

final class _BearerTokenProvider implements sp.ClientAuthKeyProvider {
  const _BearerTokenProvider(this.token);

  final String token;

  @override
  Future<String?> get authHeaderValue async =>
      sp.wrapAsBearerAuthHeaderValue(token);
}

String _requireRefreshToken(sp_auth.AuthSuccess auth, String context) {
  final token = auth.refreshToken;
  if (token == null || token.isEmpty) {
    throw StateError('Expected a refresh token for $context.');
  }
  return token;
}

void _expectPrivateSnapshot(sp.GameResync resync, String playerId) {
  _expect(resync.playerId == playerId, 'Resync must identify its recipient.');
  final snapshot = _object(jsonDecode(resync.snapshotJson));
  final units = _list(snapshot['units']).map(_object).toList();
  _expect(units.isNotEmpty, 'Recipient snapshot must include its own unit.');
  for (final unit in units) {
    _expect(
      unit['ownerPlayerId'] == playerId && unit['ownedDetails'] != null,
      'Fogged recipient snapshot leaked another participant or hid own data.',
    );
  }
}

int _expectRecipientOutcome(String document, String playerId) {
  final outcome = _object(jsonDecode(document));
  _expect(
    outcome.keys.toSet().containsAll({'stamp', 'rejection', 'recipient'}) &&
        outcome.length == 3,
    'Client outcome must not contain a canonical envelope.',
  );
  final recipient = _object(outcome['recipient']);
  _expect(
    recipient['recipientPlayerId'] == playerId,
    'Command outcome must contain only the authenticated recipient.',
  );
  return _nonNegativeInt(_object(outcome['stamp'])['revision']);
}

String _mapDocument(String mapId) => jsonEncode({
  'schemaVersion': 1,
  'gridLayout': 'oddQFlatTop',
  'cols': 5,
  'rows': 5,
  'mapName': mapId,
  'defaultZoom': 1.0,
  'objectives': <Object?>[],
  'tiles': [
    for (var col = 0; col < 5; col++)
      for (var row = 0; row < 5; row++)
        {
          'col': col,
          'row': row,
          'terrainTags': ['plains'],
          'resources': <Object?>[],
          'height': 0,
        },
  ],
});

String _scenarioDocument(String mapId) => jsonEncode({
  'schemaVersion': 1,
  'scenarioId': '$mapId-scenario',
  'mapId': mapId,
  'rulesetId': 'aonw-standard',
  'initialUnits': [
    {
      'id': 'unit-1',
      'ownerPlayerId': 'player-1',
      'kind': 'commander',
      'name': 'One',
      'col': 0,
      'row': 0,
    },
    {
      'id': 'unit-2',
      'ownerPlayerId': 'player-2',
      'kind': 'commander',
      'name': 'Two',
      'col': 4,
      'row': 4,
    },
  ],
});

String _matchIdentityDocument() => jsonEncode({
  'matchRules': {
    'gameLength': {
      'kind': 'unlimited',
      'targetMinutes': null,
      'turnLimit': null,
      'paceProfile': 'unlimited',
      'scoreFallbackEnabled': false,
    },
    'victory': {
      'conquestEnabled': true,
      'dominationEnabled': true,
      'dominationControlPercent': 60,
      'dominationHoldTurns': 5,
      'scoreFallbackEnabled': false,
      'turnLimit': null,
      'hardTimeLimitMinutes': null,
      'culturalEnabled': true,
      'culturalRequiredArtifacts': 6,
      'culturalHoldTurns': 5,
    },
    'balance': <String, Object?>{},
  },
  'participants': [
    {
      'id': 'player-1',
      'name': 'One',
      'colorValue': 0xff0000ff,
      'country': 'poland',
      'kind': 'human',
      'ai': null,
    },
    {
      'id': 'player-2',
      'name': 'Two',
      'colorValue': 0x00ff00ff,
      'country': 'germany',
      'kind': 'human',
      'ai': null,
    },
  ],
  'gameMode': 'multiplayer',
});

Map<String, Object?> _object(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected an object, got ${value.runtimeType}.');
}

List<Object?> _list(Object? value) {
  if (value is List<Object?>) return value;
  throw FormatException('Expected an array, got ${value.runtimeType}.');
}

int _nonNegativeInt(Object? value) {
  if (value is int && value >= 0) return value;
  throw FormatException('Expected a non-negative integer, got $value.');
}

String _normalizeHost(String host) => host.endsWith('/') ? host : '$host/';

Future<String> _verifyLoopbackOnly(Uri host) async {
  if (host.scheme != 'http' ||
      host.host != InternetAddress.loopbackIPv4.address ||
      host.userInfo.isNotEmpty ||
      host.path != '/' ||
      host.hasQuery ||
      host.hasFragment) {
    throw StateError(
      'The critical E2E host must be an HTTP IPv4-loopback origin; got $host.',
    );
  }
  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );
  final addresses = <InternetAddress>{
    for (final interface in interfaces)
      for (final address in interface.addresses)
        if (!address.isLoopback) address,
  }.toList()..sort((left, right) => left.address.compareTo(right.address));
  if (addresses.isEmpty) {
    return 'runtime probe skipped (no non-loopback IPv4 interface)';
  }
  for (final address in addresses) {
    for (final port in [host.port, host.port + 1, host.port + 2]) {
      final socket = await _tryConnect(address, port);
      if (socket == null) continue;
      socket.destroy();
      throw StateError(
        'Critical E2E listener $port is reachable through non-loopback '
        '${address.address}.',
      );
    }
  }
  return 'verified across ${addresses.length} non-loopback IPv4 '
      '${addresses.length == 1 ? 'address' : 'addresses'}';
}

Future<Socket?> _tryConnect(InternetAddress address, int port) async {
  try {
    return await Socket.connect(
      address,
      port,
      timeout: const Duration(seconds: 2),
    );
  } on SocketException {
    return null;
  } on TimeoutException {
    return null;
  }
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}

final class _CriticalE2eConfig {
  const _CriticalE2eConfig({required this.host, required this.requestTimeout});

  final String host;
  final Duration requestTimeout;

  static const usage = '''
Usage:
  dart run tool/critical_e2e.dart [options]

Options:
  --host URL   Serverpod API host. Default: http://127.0.0.1:18080/
''';

  factory _CriticalE2eConfig.fromArgs(List<String> args) {
    var host = 'http://127.0.0.1:18080/';
    for (var index = 0; index < args.length; index++) {
      final argument = args[index];
      if (argument == '--help' || argument == '-h') {
        stdout.write(usage);
        exit(0);
      }
      if (argument.startsWith('--host=')) {
        host = argument.substring('--host='.length);
        continue;
      }
      if (argument == '--host' && index + 1 < args.length) {
        host = args[++index];
        continue;
      }
      throw FormatException('Unexpected argument: $argument');
    }
    return _CriticalE2eConfig(
      host: host,
      requestTimeout: const Duration(seconds: 20),
    );
  }
}
