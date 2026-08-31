import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:test/test.dart';

void main() {
  test('accepts only the expected available native build', () {
    final identity = AonwNativeIdentity.evaluate(
      runtimeAvailable: true,
      clientApiVersion: aonwClientApiVersion,
      buildIdentity: aonwExpectedNativeBuildIdentity,
    );

    expect(identity.status, AonwNativeIdentityStatus.compatible);
    expect(identity.isCompatible, isTrue);
  });

  test('rejects an unavailable runtime before inspecting its versions', () {
    final identity = AonwNativeIdentity.evaluate(
      runtimeAvailable: false,
      clientApiVersion: aonwClientApiVersion + 1,
      buildIdentity: 'foreign/build',
    );

    expect(identity.status, AonwNativeIdentityStatus.unavailable);
    expect(identity.isCompatible, isFalse);
  });

  test('rejects a foreign client contract', () {
    final identity = AonwNativeIdentity.evaluate(
      runtimeAvailable: true,
      clientApiVersion: aonwClientApiVersion + 1,
      buildIdentity: aonwExpectedNativeBuildIdentity,
    );

    expect(identity.status, AonwNativeIdentityStatus.contractMismatch);
    expect(identity.isCompatible, isFalse);
  });

  test('rejects a foreign native build', () {
    final identity = AonwNativeIdentity.evaluate(
      runtimeAvailable: true,
      clientApiVersion: aonwClientApiVersion,
      buildIdentity: 'aonw_flutter/foreign',
    );

    expect(identity.status, AonwNativeIdentityStatus.buildMismatch);
    expect(identity.isCompatible, isFalse);
  });
}
