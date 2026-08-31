import 'dart:collection';
import 'dart:convert';

import 'package:aonw_server_native/aonw_server_native.dart';

/// Process-local owner of the verified stateless engine server host.
///
/// Only immutable prepared content is cached. Canonical match state always
/// crosses the native boundary from the transaction that locked its row.
final class GameNativeRuntime {
  GameNativeRuntime({AonwServerNativeHost? host, int worldCapacity = 16})
    : _host = host ?? AonwServerNativeHost(),
      _worldCapacity = worldCapacity {
    if (worldCapacity < 1) {
      throw ArgumentError.value(worldCapacity, 'worldCapacity');
    }
  }

  final AonwServerNativeHost _host;
  final int _worldCapacity;
  final LinkedHashMap<String, AonwPreparedServerWorld> _worlds =
      LinkedHashMap<String, AonwPreparedServerWorld>();

  String get buildIdentity => _host.identity.buildIdentity;

  PreparedGameContent prepareContent({
    required String mapDocument,
    required String rulesetId,
    String? expectedMapHash,
    String? expectedRulesetHash,
  }) {
    if (expectedMapHash != null && expectedRulesetHash != null) {
      final expectedKey = _worldKey(expectedMapHash, expectedRulesetHash);
      final cached = _worlds.remove(expectedKey);
      if (cached != null) {
        _worlds[expectedKey] = cached;
        return PreparedGameContent(cached);
      }
    }
    final prepared = _host.prepareWorld(
      mapDocument: mapDocument,
      rulesetId: rulesetId,
    );
    if ((expectedMapHash != null && prepared.mapHash != expectedMapHash) ||
        (expectedRulesetHash != null &&
            prepared.rulesetHash != expectedRulesetHash)) {
      prepared.close();
      throw const AonwServerNativeException(
        'content_identity_mismatch',
        'Persisted match content does not match the prepared native world.',
      );
    }
    final key = _worldKey(prepared.mapHash, prepared.rulesetHash);
    final existing = _worlds.remove(key);
    if (existing != null) {
      prepared.close();
      _worlds[key] = existing;
      return PreparedGameContent(existing);
    }
    _worlds[key] = prepared;
    while (_worlds.length > _worldCapacity) {
      _worlds.remove(_worlds.keys.first)?.close();
    }
    return PreparedGameContent(prepared);
  }

  Map<String, Object?> createMatch({
    required PreparedGameContent content,
    required String scenarioDocument,
    required Map<String, Object?> matchIdentity,
    required bool fogEnabled,
  }) {
    final response = _host.createMatchJson(
      content._world,
      jsonEncode({
        'apiVersion': aonwServerHostApiVersion,
        'mapHash': content.mapHash,
        'rulesetHash': content.rulesetHash,
        'scenarioDocument': scenarioDocument,
        'matchIdentity': matchIdentity,
        'fogEnabled': fogEnabled,
      }),
    );
    return _result(response, 'matchCreated');
  }

  Map<String, Object?> submitTurn({
    required PreparedGameContent content,
    required String authenticatedActorPlayerId,
    required int expectedRevision,
    required int initialEventOffset,
    required Map<String, Object?> canonicalState,
  }) {
    try {
      final response = _host.submitTurnJson(
        content._world,
        jsonEncode({
          'apiVersion': aonwServerHostApiVersion,
          'authenticatedActorPlayerId': authenticatedActorPlayerId,
          'expectedRevision': expectedRevision,
          'initialEventOffset': initialEventOffset,
          'mapHash': content.mapHash,
          'rulesetHash': content.rulesetHash,
          'state': canonicalState,
        }),
      );
      return _result(response, 'commandApplied');
    } on AonwServerNativeException catch (error) {
      if (error.code != 'invalid_request') rethrow;
      throw const AonwServerNativeException(
        'invalid_canonical_state',
        'Persisted canonical state does not match the current contract.',
      );
    }
  }

  void close() {
    for (final world in _worlds.values) {
      world.close();
    }
    _worlds.clear();
  }
}

final class PreparedGameContent {
  const PreparedGameContent(this._world);

  final AonwPreparedServerWorld _world;

  String get mapHash => _world.mapHash;
  String get rulesetHash => _world.rulesetHash;
}

Map<String, Object?> _result(
  AonwServerHostResponse response,
  String responseType,
) {
  final body = response.requireSuccess(responseType);
  return _object(body['result'], r'$.outcome.response.result');
}

Map<String, Object?> decodeGameObjectDocument(String document, String field) {
  final Object? decoded;
  try {
    decoded = jsonDecode(document);
  } on FormatException catch (error) {
    throw FormatException('$field must be valid JSON: ${error.message}');
  }
  return _object(decoded, field);
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$path must be a JSON object.');
}

String _worldKey(String mapHash, String rulesetHash) =>
    '$mapHash\u0000$rulesetHash';

GameNativeRuntime? _runtime;

/// Verifies and initializes the real native artifact before server startup.
GameNativeRuntime initializeAonwGameNativeHost() {
  return _runtime ??= GameNativeRuntime();
}

/// Releases immutable native content and permits clean host reinitialization.
Future<void> shutdownAonwGameNativeHost() async {
  _runtime?.close();
  _runtime = null;
}

GameNativeRuntime get aonwGameNativeRuntime => _runtime ??= GameNativeRuntime();
