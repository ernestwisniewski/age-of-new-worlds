import 'dart:ffi' as ffi;

const _assetId = 'package:aonw_server_native/aonw_server_native_bindings.dart';

@ffi.Native<ffi.Uint8 Function()>(
  symbol: 'aonw_server_native_is_available',
  assetId: _assetId,
)
external int aonwServerNativeIsAvailable();

@ffi.Native<ffi.Uint16 Function()>(
  symbol: 'aonw_server_native_api_version',
  assetId: _assetId,
)
external int aonwServerNativeApiVersion();

@ffi.Native<ffi.UintPtr Function()>(
  symbol: 'aonw_server_native_build_identity_len',
  assetId: _assetId,
)
external int aonwServerNativeBuildIdentityLen();

@ffi.Native<ffi.Pointer<ffi.Uint8> Function()>(
  symbol: 'aonw_server_native_build_identity_data',
  assetId: _assetId,
)
external ffi.Pointer<ffi.Uint8> aonwServerNativeBuildIdentityData();

@ffi.Native<
  ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, ffi.UintPtr)
>(symbol: 'aonw_server_native_prepare_world', assetId: _assetId)
external ffi.Pointer<ffi.Void> aonwServerNativePrepareWorld(
  ffi.Pointer<ffi.Uint8> request,
  int requestLength,
);

@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_server_native_response_take_world',
  assetId: _assetId,
)
external ffi.Pointer<ffi.Void> aonwServerNativeResponseTakeWorld(
  ffi.Pointer<ffi.Void> response,
);

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_server_native_world_free',
  assetId: _assetId,
)
external void aonwServerNativeWorldFree(ffi.Pointer<ffi.Void> world);

@ffi.Native<
  ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.UintPtr,
  )
>(symbol: 'aonw_server_native_project_state', assetId: _assetId)
external ffi.Pointer<ffi.Void> aonwServerNativeProjectState(
  ffi.Pointer<ffi.Void> world,
  ffi.Pointer<ffi.Uint8> request,
  int requestLength,
);

@ffi.Native<
  ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.UintPtr,
  )
>(symbol: 'aonw_server_native_create_match', assetId: _assetId)
external ffi.Pointer<ffi.Void> aonwServerNativeCreateMatch(
  ffi.Pointer<ffi.Void> world,
  ffi.Pointer<ffi.Uint8> request,
  int requestLength,
);

@ffi.Native<
  ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.UintPtr,
  )
>(symbol: 'aonw_server_native_submit_turn', assetId: _assetId)
external ffi.Pointer<ffi.Void> aonwServerNativeSubmitTurn(
  ffi.Pointer<ffi.Void> world,
  ffi.Pointer<ffi.Uint8> request,
  int requestLength,
);

@ffi.Native<ffi.UintPtr Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_server_native_response_len',
  assetId: _assetId,
)
external int aonwServerNativeResponseLen(ffi.Pointer<ffi.Void> response);

@ffi.Native<ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_server_native_response_data',
  assetId: _assetId,
)
external ffi.Pointer<ffi.Uint8> aonwServerNativeResponseData(
  ffi.Pointer<ffi.Void> response,
);

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'aonw_server_native_response_free',
  assetId: _assetId,
)
external void aonwServerNativeResponseFree(ffi.Pointer<ffi.Void> response);
