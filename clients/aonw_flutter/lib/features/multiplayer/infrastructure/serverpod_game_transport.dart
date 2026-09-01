import 'dart:convert';
import 'dart:math';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;

import 'server_projection_decoder.dart';

typedef ServerpodGameResync =
    Future<server.GameResync> Function(String matchId);
typedef ServerpodGameQuery =
    Future<server.GamePlayerQueryOutcome> Function(
      server.GamePlayerQueryRequest request,
    );
typedef ServerpodGameCommand =
    Future<server.GameCommandOutcome> Function(
      server.GamePlayerCommandRequest request,
    );
typedef ServerpodCommandIdFactory = String Function();

/// Adapts authenticated Serverpod gameplay to the shared local client protocol.
final class ServerpodGameTransport implements AonwEngineSession {
  ServerpodGameTransport({
    required String matchId,
    required ServerpodGameResync resync,
    required ServerpodGameQuery query,
    required ServerpodGameCommand command,
    ServerProjectionDecoder decoder = const ServerProjectionDecoder(),
    ServerpodCommandIdFactory? commandIdFactory,
    Random? secureRandom,
  }) : _matchId = _identifier(matchId, 'match id'),
       _resync = resync,
       _query = query,
       _command = command,
       _decoder = decoder,
       _commandIdFactory =
           commandIdFactory ??
           _UuidFactory(secureRandom ?? Random.secure()).next;

  static const _maximumRequestBytes = 128 * 1024;

  final String _matchId;
  final ServerpodGameResync _resync;
  final ServerpodGameQuery _query;
  final ServerpodGameCommand _command;
  final ServerProjectionDecoder _decoder;
  final ServerpodCommandIdFactory _commandIdFactory;
  var _closed = false;

  @override
  Future<String> requestJson(String request) async {
    if (_closed) throw StateError('The Serverpod game transport is closed.');
    if (utf8.encode(request).length > _maximumRequestBytes) {
      throw const FormatException('The client request is too large.');
    }
    final envelope = _object(jsonDecode(request), 'client request');
    _expectKeys(envelope, const {'apiVersion', 'request'}, 'client request');
    if (envelope['apiVersion'] != aonwClientApiVersion) {
      throw const FormatException('Unsupported AoNW client API version.');
    }
    final body = _object(envelope['request'], 'client request body');
    return switch (body['type']) {
      'snapshot' => _snapshot(body),
      'query' => _executeQuery(body),
      'dispatch' => _executeCommand(body),
      _ => throw const FormatException(
        'Serverpod gameplay accepts only snapshot, query, and dispatch.',
      ),
    };
  }

  Future<String> _snapshot(Map<String, Object?> request) async {
    _expectKeys(request, const {'type'}, 'snapshot request');
    final response = await _resync(_matchId);
    _requireMatch(response.matchId);
    return _decoder.snapshotResponseJson(response);
  }

  Future<String> _executeQuery(Map<String, Object?> request) async {
    _expectKeys(request, const {'type', 'query'}, 'query request');
    final response = await _query(
      server.GamePlayerQueryRequest(
        matchId: _matchId,
        queryJson: jsonEncode(_object(request['query'], 'player query')),
      ),
    );
    _requireMatch(response.matchId);
    return _decoder.queryResponseJson(response);
  }

  Future<String> _executeCommand(Map<String, Object?> request) async {
    _expectKeys(request, const {'type', 'command'}, 'dispatch request');
    final commandId = _identifier(_commandIdFactory(), 'client command id');
    final response = await _command(
      server.GamePlayerCommandRequest(
        matchId: _matchId,
        clientCommandId: commandId,
        commandJson: jsonEncode(_object(request['command'], 'player command')),
      ),
    );
    _requireMatch(response.matchId);
    if (response.clientCommandId != commandId) {
      throw const FormatException(
        'Server command identity does not match the request.',
      );
    }
    return _decoder.commandResponseJson(response);
  }

  void _requireMatch(String value) {
    if (value != _matchId) {
      throw const FormatException(
        'Server gameplay response belongs to another match.',
      );
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
  }
}

final class _UuidFactory {
  const _UuidFactory(this.random);

  final Random random;

  String next() {
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

Map<String, Object?> _object(Object? value, String label) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$label must be an object.');
}

void _expectKeys(
  Map<String, Object?> value,
  Set<String> expected,
  String label,
) {
  if (value.keys.length != expected.length ||
      !value.keys.every(expected.contains)) {
    throw FormatException('$label has an invalid field set.');
  }
}

String _identifier(String value, String label) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > 128) {
    throw FormatException('$label is invalid.');
  }
  return normalized;
}
