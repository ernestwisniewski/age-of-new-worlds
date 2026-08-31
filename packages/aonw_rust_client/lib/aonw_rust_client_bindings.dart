import 'dart:ffi' as ffi;

const _assetId = 'package:aonw_rust_client/aonw_rust_client_bindings.dart';

@ffi.Native<ffi.Uint8 Function()>(
  symbol: 'aonw_flutter_is_available',
  assetId: _assetId,
)
external int aonwFlutterIsAvailable();

@ffi.Native<ffi.Uint16 Function()>(
  symbol: 'aonw_flutter_client_api_version',
  assetId: _assetId,
)
external int aonwFlutterClientApiVersion();

@ffi.Native<ffi.UintPtr Function()>(
  symbol: 'aonw_flutter_build_identity_len',
  assetId: _assetId,
)
external int aonwFlutterBuildIdentityLen();

@ffi.Native<ffi.Pointer<ffi.Uint8> Function()>(
  symbol: 'aonw_flutter_build_identity_data',
  assetId: _assetId,
)
external ffi.Pointer<ffi.Uint8> aonwFlutterBuildIdentityData();

@ffi.Native<ffi.Pointer<ffi.Void> Function()>(
  symbol: 'aonw_flutter_session_new',
  assetId: _assetId,
)
external ffi.Pointer<ffi.Void> aonwFlutterSessionNew();

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_flutter_session_free',
  assetId: _assetId,
)
external void aonwFlutterSessionFree(ffi.Pointer<ffi.Void> session);

@ffi.Native<
  ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.UintPtr,
  )
>(symbol: 'aonw_flutter_session_request', assetId: _assetId)
external ffi.Pointer<ffi.Void> aonwFlutterSessionRequest(
  ffi.Pointer<ffi.Void> session,
  ffi.Pointer<ffi.Uint8> request,
  int requestLength,
);

@ffi.Native<ffi.UintPtr Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_flutter_response_len',
  assetId: _assetId,
)
external int aonwFlutterResponseLen(ffi.Pointer<ffi.Void> response);

@ffi.Native<ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_flutter_response_data',
  assetId: _assetId,
)
external ffi.Pointer<ffi.Uint8> aonwFlutterResponseData(
  ffi.Pointer<ffi.Void> response,
);

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_flutter_response_free',
  assetId: _assetId,
)
external void aonwFlutterResponseFree(ffi.Pointer<ffi.Void> response);
