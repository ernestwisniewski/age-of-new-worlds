import 'package:aonw_server/src/app_status/app_status_endpoint.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  test('current app build remains current', () {
    expect(appVersionStatus(buildNumber: 80, latestBuildNumber: 80), 'current');
  });

  test('older app build still receives the update notice status', () {
    expect(appVersionStatus(buildNumber: 79, latestBuildNumber: 80), 'soon');
  });

  test('endpoint delegates the request to the version policy', () async {
    final endpoint = AppStatusEndpoint();

    expect(
      await endpoint.versionStatus(
        _UnusedSession(),
        platform: 'test',
        buildNumber: 0,
      ),
      'current',
    );
  });
}

final class _UnusedSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
