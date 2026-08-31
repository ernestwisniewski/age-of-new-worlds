import 'package:aonw_server_native/aonw_server_native.dart';
import 'package:test/test.dart';

void main() {
  test('packaged native artifact identity fails closed and is exact', () {
    final identity = AonwServerNativeIdentity.read();
    expect(identity.status, AonwServerNativeIdentityStatus.exactMatch);
    expect(identity.apiVersion, aonwServerHostApiVersion);
    expect(identity.buildIdentity, aonwExpectedServerNativeBuildIdentity);
  });
}
