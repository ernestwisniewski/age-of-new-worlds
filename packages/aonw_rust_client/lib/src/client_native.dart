import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:aonw_rust_client/aonw_rust_client_bindings.dart' as bindings;
import 'package:aonw_rust_client/src/api.dart';
import 'package:aonw_rust_client/src/native_identity.dart';
import 'package:ffi/ffi.dart';

AonwNativeIdentity get aonwRustClientIdentity {
  try {
    final length = bindings.aonwFlutterBuildIdentityLen();
    final data = bindings.aonwFlutterBuildIdentityData();
    if (length != 0 && data == ffi.nullptr) {
      return const AonwNativeIdentity.unreadable();
    }
    return AonwNativeIdentity.evaluate(
      runtimeAvailable: bindings.aonwFlutterIsAvailable() == 1,
      clientApiVersion: bindings.aonwFlutterClientApiVersion(),
      buildIdentity: length == 0 ? '' : utf8.decode(data.asTypedList(length)),
    );
  } on Object {
    return const AonwNativeIdentity.unreadable();
  }
}

bool get aonwRustClientAvailable => aonwRustClientIdentity.isCompatible;

Future<AonwRustSession?> createAonwRustSession() async {
  if (!aonwRustClientIdentity.isCompatible) return null;
  return _NativeAonwRustSession.start();
}

final class _NativeAonwRustSession implements AonwRustSession {
  _NativeAonwRustSession._(this._commands, this._responses) {
    _responses.listen(_receive);
  }

  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<String>> _pending = {};
  var _nextRequestId = 0;
  var _closed = false;

  static Future<_NativeAonwRustSession> start() async {
    final ready = ReceivePort();
    final responses = ReceivePort();
    await Isolate.spawn(
      _sessionWorker,
      _WorkerPorts(ready.sendPort, responses.sendPort),
    );
    final result = await ready.first as _WorkerReady;
    ready.close();
    final commands = result.commands;
    if (commands == null) {
      responses.close();
      throw StateError(result.error ?? 'Rust session startup failed.');
    }
    return _NativeAonwRustSession._(commands, responses);
  }

  @override
  Future<String> requestJson(String request) {
    if (_closed) throw StateError('Rust session is closed.');
    final requestId = _nextRequestId++;
    final completer = Completer<String>();
    _pending[requestId] = completer;
    _commands.send(_NativeRequest(requestId, request));
    return completer.future;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final requestId = _nextRequestId++;
    final completer = Completer<String>();
    _pending[requestId] = completer;
    _commands.send(_NativeClose(requestId));
    await completer.future;
    _responses.close();
  }

  void _receive(Object? message) {
    if (message is! _NativeResponse) return;
    final completer = _pending.remove(message.id);
    if (completer == null) return;
    if (message.error case final error?) {
      completer.completeError(StateError(error));
    } else {
      completer.complete(message.json!);
    }
  }
}

final class _NativeRequest {
  const _NativeRequest(this.id, this.json);

  final int id;
  final String json;
}

final class _NativeClose {
  const _NativeClose(this.id);

  final int id;
}

final class _NativeResponse {
  const _NativeResponse.success(this.id, this.json) : error = null;
  const _NativeResponse.failure(this.id, this.error) : json = null;

  final int id;
  final String? json;
  final String? error;
}

final class _WorkerPorts {
  const _WorkerPorts(this.ready, this.responses);

  final SendPort ready;
  final SendPort responses;
}

final class _WorkerReady {
  const _WorkerReady.success(this.commands) : error = null;
  const _WorkerReady.failure(this.error) : commands = null;

  final SendPort? commands;
  final String? error;
}

void _sessionWorker(_WorkerPorts ports) {
  final session = bindings.aonwFlutterSessionNew();
  if (session == ffi.nullptr) {
    ports.ready.send(
      const _WorkerReady.failure('Rust session allocation failed.'),
    );
    return;
  }
  final requests = ReceivePort();
  ports.ready.send(_WorkerReady.success(requests.sendPort));
  requests.listen((message) {
    if (message is _NativeRequest) {
      try {
        ports.responses.send(
          _NativeResponse.success(message.id, _dispatch(session, message.json)),
        );
      } on Object catch (error) {
        ports.responses.send(
          _NativeResponse.failure(message.id, error.toString()),
        );
      }
      return;
    }
    if (message is _NativeClose) {
      bindings.aonwFlutterSessionFree(session);
      requests.close();
      ports.responses.send(_NativeResponse.success(message.id, ''));
    }
  });
}

String _dispatch(ffi.Pointer<ffi.Void> session, String request) {
  final bytes = utf8.encode(request);
  final input = calloc<ffi.Uint8>(bytes.isEmpty ? 1 : bytes.length);
  input.asTypedList(bytes.length).setAll(0, bytes);
  try {
    final response = bindings.aonwFlutterSessionRequest(
      session,
      input,
      bytes.length,
    );
    if (response == ffi.nullptr) {
      throw StateError('Rust returned no response.');
    }
    try {
      final length = bindings.aonwFlutterResponseLen(response);
      final data = bindings.aonwFlutterResponseData(response);
      if (data == ffi.nullptr && length != 0) {
        throw StateError('Rust returned an invalid response.');
      }
      return utf8.decode(data.asTypedList(length));
    } finally {
      bindings.aonwFlutterResponseFree(response);
    }
  } finally {
    calloc.free(input);
  }
}
