const aonwExpectedNativeBuildIdentity = 'aonw_flutter/0.1.0';

enum AonwNativeIdentityStatus {
  compatible,
  unavailable,
  contractMismatch,
  buildMismatch,
  unreadable,
}

final class AonwNativeIdentity {
  const AonwNativeIdentity({
    required this.status,
    required this.clientApiVersion,
    required this.buildIdentity,
  });

  factory AonwNativeIdentity.evaluate({
    required bool runtimeAvailable,
    required int clientApiVersion,
    required String buildIdentity,
  }) {
    final status = !runtimeAvailable
        ? AonwNativeIdentityStatus.unavailable
        : clientApiVersion != aonwClientApiVersion
        ? AonwNativeIdentityStatus.contractMismatch
        : buildIdentity != aonwExpectedNativeBuildIdentity
        ? AonwNativeIdentityStatus.buildMismatch
        : AonwNativeIdentityStatus.compatible;
    return AonwNativeIdentity(
      status: status,
      clientApiVersion: clientApiVersion,
      buildIdentity: buildIdentity,
    );
  }

  const AonwNativeIdentity.unreadable()
    : status = AonwNativeIdentityStatus.unreadable,
      clientApiVersion = 0,
      buildIdentity = '';

  final AonwNativeIdentityStatus status;
  final int clientApiVersion;
  final String buildIdentity;

  bool get isCompatible => status == AonwNativeIdentityStatus.compatible;
}

const aonwClientApiVersion = 14;
