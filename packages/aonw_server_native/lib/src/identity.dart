import 'dart:convert';
import 'dart:ffi' as ffi;

import 'package:aonw_server_native/aonw_server_native_bindings.dart'
    as bindings;

const aonwServerHostApiVersion = 1;
const aonwExpectedServerNativeBuildIdentity = 'aonw_server_native/0.1.0';

enum AonwServerNativeIdentityStatus {
  exactMatch,
  unavailable,
  contractMismatch,
  buildMismatch,
  unreadable,
}

final class AonwServerNativeIdentity {
  const AonwServerNativeIdentity({
    required this.status,
    required this.apiVersion,
    required this.buildIdentity,
  });

  const AonwServerNativeIdentity.unreadable()
    : status = AonwServerNativeIdentityStatus.unreadable,
      apiVersion = 0,
      buildIdentity = '';

  factory AonwServerNativeIdentity.read() {
    try {
      final length = bindings.aonwServerNativeBuildIdentityLen();
      final data = bindings.aonwServerNativeBuildIdentityData();
      if (length != 0 && data == ffi.nullptr) {
        return const AonwServerNativeIdentity.unreadable();
      }
      final available = bindings.aonwServerNativeIsAvailable() == 1;
      final apiVersion = bindings.aonwServerNativeApiVersion();
      final identity = length == 0 ? '' : utf8.decode(data.asTypedList(length));
      final status = !available
          ? AonwServerNativeIdentityStatus.unavailable
          : apiVersion != aonwServerHostApiVersion
          ? AonwServerNativeIdentityStatus.contractMismatch
          : identity != aonwExpectedServerNativeBuildIdentity
          ? AonwServerNativeIdentityStatus.buildMismatch
          : AonwServerNativeIdentityStatus.exactMatch;
      return AonwServerNativeIdentity(
        status: status,
        apiVersion: apiVersion,
        buildIdentity: identity,
      );
    } on Object {
      return const AonwServerNativeIdentity.unreadable();
    }
  }

  final AonwServerNativeIdentityStatus status;
  final int apiVersion;
  final String buildIdentity;

  bool get isExactMatch => status == AonwServerNativeIdentityStatus.exactMatch;

  void requireExactMatch() {
    if (isExactMatch) return;
    throw StateError(
      'Unexpected AoNW server native artifact: ${status.name}; '
      'apiVersion=$apiVersion, buildIdentity=$buildIdentity.',
    );
  }
}
