import 'dart:convert';
import 'dart:ffi' as ffi;

import 'package:aonw_server_native/aonw_server_native_bindings.dart'
    as bindings;
import 'package:aonw_server_native/src/identity.dart';
import 'package:ffi/ffi.dart';

final class AonwServerNativeException implements Exception {
  const AonwServerNativeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AonwServerNativeException($code): $message';
}

final class AonwServerHostResponse {
  const AonwServerHostResponse(this.json, this.value);

  final String json;
  final Map<String, Object?> value;

  Map<String, Object?> requireSuccess(String expectedType) {
    if (value['apiVersion'] != aonwServerHostApiVersion) {
      throw const AonwServerNativeException(
        'unsupported_api_version',
        'Native response protocol version does not match the server package.',
      );
    }
    final outcome = _object(value['outcome'], r'$.outcome');
    if (outcome['status'] == 'failure') {
      final error = _object(outcome['error'], r'$.outcome.error');
      throw AonwServerNativeException(
        _string(error['code'], r'$.outcome.error.code'),
        _string(error['message'], r'$.outcome.error.message'),
      );
    }
    if (outcome['status'] != 'success') {
      throw const FormatException('Unknown native outcome status.');
    }
    final response = _object(outcome['response'], r'$.outcome.response');
    if (response['type'] != expectedType) {
      throw FormatException(
        'Expected native response type $expectedType, got ${response['type']}.',
      );
    }
    return response;
  }
}

final class AonwPreparedServerWorld {
  AonwPreparedServerWorld._({
    required ffi.Pointer<ffi.Void> handle,
    required this.mapHash,
    required this.rulesetHash,
  }) : _handle = handle;

  ffi.Pointer<ffi.Void> _handle;
  final String mapHash;
  final String rulesetHash;

  bool get isClosed => _handle == ffi.nullptr;

  void close() {
    if (isClosed) return;
    bindings.aonwServerNativeWorldFree(_handle);
    _handle = ffi.nullptr;
  }
}

final class AonwServerNativeHost {
  AonwServerNativeHost() {
    identity.requireExactMatch();
  }

  final AonwServerNativeIdentity identity = AonwServerNativeIdentity.read();

  AonwPreparedServerWorld prepareWorld({
    required String mapDocument,
    required String rulesetId,
  }) {
    final request = jsonEncode({
      'apiVersion': aonwServerHostApiVersion,
      'mapDocument': mapDocument,
      'rulesetId': rulesetId,
    });
    final native = _invoke(
      request,
      (input, length) => bindings.aonwServerNativePrepareWorld(input, length),
    );
    try {
      final response = native.response.requireSuccess('worldPrepared');
      final handle = bindings.aonwServerNativeResponseTakeWorld(native.handle);
      if (handle == ffi.nullptr) {
        throw StateError('Native world preparation returned no world handle.');
      }
      return AonwPreparedServerWorld._(
        handle: handle,
        mapHash: _string(response['mapHash'], r'$.response.mapHash'),
        rulesetHash: _string(
          response['rulesetHash'],
          r'$.response.rulesetHash',
        ),
      );
    } finally {
      native.close();
    }
  }

  AonwServerHostResponse submitTurnJson(
    AonwPreparedServerWorld world,
    String request,
  ) {
    if (world.isClosed) {
      throw StateError('Prepared server world is closed.');
    }
    final native = _invoke(
      request,
      (input, length) =>
          bindings.aonwServerNativeSubmitTurn(world._handle, input, length),
    );
    try {
      native.response.requireSuccess('commandApplied');
      return native.response;
    } finally {
      native.close();
    }
  }

  AonwServerHostResponse projectStateJson(
    AonwPreparedServerWorld world,
    String request,
  ) {
    if (world.isClosed) {
      throw StateError('Prepared server world is closed.');
    }
    final native = _invoke(
      request,
      (input, length) =>
          bindings.aonwServerNativeProjectState(world._handle, input, length),
    );
    try {
      native.response.requireSuccess('stateProjected');
      return native.response;
    } finally {
      native.close();
    }
  }

  AonwServerHostResponse createMatchJson(
    AonwPreparedServerWorld world,
    String request,
  ) {
    if (world.isClosed) {
      throw StateError('Prepared server world is closed.');
    }
    final native = _invoke(
      request,
      (input, length) =>
          bindings.aonwServerNativeCreateMatch(world._handle, input, length),
    );
    try {
      native.response.requireSuccess('matchCreated');
      return native.response;
    } finally {
      native.close();
    }
  }
}

final class _NativeResponseHandle {
  _NativeResponseHandle(this.handle, this.response);

  ffi.Pointer<ffi.Void> handle;
  final AonwServerHostResponse response;

  void close() {
    if (handle == ffi.nullptr) return;
    bindings.aonwServerNativeResponseFree(handle);
    handle = ffi.nullptr;
  }
}

_NativeResponseHandle _invoke(
  String request,
  ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, int) operation,
) {
  final bytes = utf8.encode(request);
  final input = calloc<ffi.Uint8>(bytes.isEmpty ? 1 : bytes.length);
  input.asTypedList(bytes.length).setAll(0, bytes);
  try {
    final handle = operation(input, bytes.length);
    if (handle == ffi.nullptr) {
      throw StateError('Rust server host returned no response handle.');
    }
    try {
      final length = bindings.aonwServerNativeResponseLen(handle);
      final data = bindings.aonwServerNativeResponseData(handle);
      if (length != 0 && data == ffi.nullptr) {
        throw StateError('Rust server host returned invalid response bytes.');
      }
      final json = utf8.decode(data.asTypedList(length));
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Native response must be a JSON object.');
      }
      return _NativeResponseHandle(
        handle,
        AonwServerHostResponse(json, decoded),
      );
    } on Object {
      bindings.aonwServerNativeResponseFree(handle);
      rethrow;
    }
  } finally {
    calloc.free(input);
  }
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$path must be an object.');
}

String _string(Object? value, String path) {
  if (value is String) return value;
  throw FormatException('$path must be a string.');
}
