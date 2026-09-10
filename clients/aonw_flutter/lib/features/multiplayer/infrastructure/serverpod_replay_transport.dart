import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;

import 'server_projection_decoder.dart';

typedef ServerpodReplayFrameRead =
    Future<server.GameReplayFrame> Function(int position);
typedef ServerpodReplayQueryRead =
    Future<server.GamePlayerQueryOutcome> Function(
      server.GamePlayerQueryRequest request,
      int position,
    );

/// Read-only replay transport using the shared Rust client response contract.
final class ServerpodReplayTransport implements AonwEngineSession {
  ServerpodReplayTransport({
    required this.matchId,
    required this.playerId,
    required this.mapHash,
    required this.rulesetHash,
    required ServerpodReplayFrameRead frame,
    required ServerpodReplayQueryRead query,
    required void Function() requireAuthorized,
    required void Function() release,
  }) : _frame = frame,
       _query = query,
       _requireAuthorized = requireAuthorized,
       _release = release;

  final String matchId;
  final String playerId;
  final String mapHash;
  final String rulesetHash;
  final ServerpodReplayFrameRead _frame;
  final ServerpodReplayQueryRead _query;
  final void Function() _requireAuthorized;
  final void Function() _release;
  Map<String, Object?>? _current;
  AonwReplayFrameResponse? _currentFrame;
  bool _closed = false;
  bool _busy = false;

  @override
  Future<String> requestJson(String request) async {
    _ensureOpen();
    if (_busy) throw StateError('A replay request is already in progress.');
    if (utf8.encode(request).length > 128 * 1024) {
      throw const FormatException('The replay request is too large.');
    }
    final envelope = _object(jsonDecode(request));
    _keys(envelope, {'apiVersion', 'request'});
    if (envelope['apiVersion'] != aonwClientApiVersion) {
      throw const FormatException('Unsupported client API version.');
    }
    final body = _object(envelope['request']);
    _busy = true;
    try {
      return await switch (body['type']) {
        'snapshot' => _snapshot(body),
        'seekReplay' => _seek(body),
        'query' => _executeQuery(body),
        _ => throw const FormatException(
          'Replay accepts only read operations.',
        ),
      };
    } finally {
      _busy = false;
    }
  }

  Future<String> _snapshot(Map<String, Object?> body) async {
    _keys(body, {'type'});
    if (_current == null) await _seek({'type': 'seekReplay', 'position': 0});
    return _success({'type': 'snapshot', 'snapshot': _current!['snapshot']});
  }

  Future<String> _seek(Map<String, Object?> body) async {
    _keys(body, {'type', 'position'});
    final previous = _currentFrame;
    final position = _requestedPosition(body['position'], previous);
    final response = await _frame(position);
    _ensureOpen();
    if (response.matchId != matchId ||
        response.playerId != playerId ||
        utf8.encode(response.frameJson).length > 64 * 1024 * 1024) {
      throw const FormatException(
        'Replay response identity or size is invalid.',
      );
    }
    final value = _object(jsonDecode(response.frameJson));
    final frame = AonwClientResponse.parse(
      _success(value),
    ).require<AonwReplayFrameResponse>();
    _validateFrame(frame, position, previous);
    final advancing = previous != null && position == previous.position + 1;
    final presented = {...value, if (!advancing) 'command': null};
    final encoded = _success(presented);
    _current = presented;
    _currentFrame = frame;
    return encoded;
  }

  void _validateFrame(
    AonwReplayFrameResponse frame,
    int position,
    AonwReplayFrameResponse? previous,
  ) {
    final stamp = frame.snapshot.stamp;
    if (frame.position != position ||
        frame.recipientPlayerId != playerId ||
        stamp.mapHash != mapHash ||
        stamp.rulesetHash != rulesetHash ||
        (previous != null && frame.entryCount != previous.entryCount)) {
      throw const FormatException('Replay frame identity changed.');
    }
    if (previous != null && position == previous.position + 1) {
      _validateAdvance(frame, previous);
    }
  }

  Future<String> _executeQuery(Map<String, Object?> body) async {
    _keys(body, {'type', 'query'});
    final current = _currentFrame;
    if (current == null) throw StateError('Replay is not open.');
    final response = await _query(
      server.GamePlayerQueryRequest(
        matchId: matchId,
        queryJson: jsonEncode(_object(body['query'])),
      ),
      current.position,
    );
    _ensureOpen();
    if (response.matchId != matchId ||
        utf8.encode(response.outcomeJson).length > 64 * 1024 * 1024) {
      throw const FormatException('Replay query belongs to another match.');
    }
    return const ServerProjectionDecoder().queryResponseJson(response);
  }

  void _ensureOpen() {
    if (_closed) throw StateError('The replay transport is closed.');
    _requireAuthorized();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _current = null;
    _currentFrame = null;
    _release();
  }
}

Map<String, Object?> _object(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw const FormatException('Expected a replay JSON object.');
}

void _keys(Map<String, Object?> value, Set<String> keys) {
  if (value.length != keys.length || !value.keys.every(keys.contains)) {
    throw const FormatException('Unexpected replay request fields.');
  }
}

String _success(Map<String, Object?> body) {
  final encoded = jsonEncode({
    'apiVersion': aonwClientApiVersion,
    'outcome': {'status': 'success', 'response': body},
  });
  return encoded;
}

int _requestedPosition(Object? value, AonwReplayFrameResponse? previous) {
  if (value is! int || value < 0) {
    throw const FormatException('Invalid replay position.');
  }
  if ((previous == null && value != 0) ||
      (previous != null && value > previous.entryCount)) {
    throw const FormatException('Replay position is outside the open archive.');
  }
  return value;
}

void _validateAdvance(
  AonwReplayFrameResponse frame,
  AonwReplayFrameResponse previous,
) {
  if (frame.command == null ||
      frame.command!.viewPatch.fromRevision !=
          previous.snapshot.stamp.revision) {
    throw const FormatException(
      'Replay command does not continue the previous frame.',
    );
  }
}
