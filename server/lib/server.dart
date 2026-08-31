import 'package:aonw_server/src/auth/auth_maintenance_future_call.dart';
import 'package:aonw_server/src/auth/external_auth_route.dart';
import 'package:aonw_server/src/auth/external_auth_service.dart';
import 'package:aonw_server/src/auth/steam_auth_route.dart';
import 'package:aonw_server/src/auth/steam_auth_service.dart';
import 'package:aonw_server/src/game/native/game_native_runtime.dart'
    show initializeAonwGameNativeHost, shutdownAonwGameNativeHost;
import 'package:aonw_server/src/generated/endpoints.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/stats/public_game_stats_route.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/providers/apple.dart' as apple;
import 'package:serverpod_auth_idp_server/providers/google.dart' as google;

Future<void> run(List<String> args) async {
  initializeAonwGameNativeHost();
  final pod = Serverpod(args, Protocol(), Endpoints());
  pod.experimental.shutdownTasks.addTask(
    'aonwGameNativeHost',
    shutdownAonwGameNativeHost,
  );
  final authMaintenanceRegistered = _registerAuthMaintenance(pod);
  final appleConfigured = _appleIdpConfigured(pod);
  final googleConfigured = _hasPassword(pod, 'googleClientSecret');

  pod.initializeAuthServices(
    tokenManagerBuilders: [auth_core.JwtConfigFromPasswords()],
    identityProviderBuilders: [
      if (googleConfigured) google.GoogleIdpConfigFromPasswords(),
      if (appleConfigured) apple.AppleIdpConfigFromPasswords(),
    ],
  );

  if (appleConfigured) {
    pod.configureAppleIdpRoutes(webAuthenticationCallbackRoutePath: null);
    pod.webServer.addRoute(
      AppleExternalAuthCallbackRoute(
        androidPackageIdentifier: pod.getPassword(
          'appleAndroidPackageIdentifier',
        ),
        webRedirectUri: pod.getPassword('appleWebRedirectUri'),
      ),
      ExternalAuthService.appleCallbackPath,
    );
  }
  if (googleConfigured) {
    pod.webServer.addRoute(
      GoogleExternalAuthCallbackRoute(),
      ExternalAuthService.googleCallbackPath,
    );
  }
  pod.webServer.addRoute(
    SteamAuthCallbackRoute(),
    SteamAuthService.callbackPath,
  );
  pod.webServer.addRoute(PublicGameStatsRoute(), '/api/stats');
  await pod.start();
  if (authMaintenanceRegistered) {
    final authMaintenanceReconciler = AuthMaintenanceScheduleReconciler(pod);
    await authMaintenanceReconciler.start();
    pod.experimental.shutdownTasks.addTask(
      authMaintenanceReconcilerShutdownTaskId,
      authMaintenanceReconciler.close,
    );
  }
}

bool _appleIdpConfigured(Serverpod pod) {
  return _hasPassword(pod, 'appleServiceIdentifier') &&
      _hasPassword(pod, 'appleBundleIdentifier') &&
      _hasPassword(pod, 'appleRedirectUri') &&
      _hasPassword(pod, 'appleTeamId') &&
      _hasPassword(pod, 'appleKeyId') &&
      _hasPassword(pod, 'appleKey');
}

bool _hasPassword(Serverpod pod, String key) {
  final value = pod.getPassword(key);
  return value != null && value.trim().isNotEmpty;
}

bool _registerAuthMaintenance(Serverpod pod) {
  try {
    pod.registerFutureCall(
      AuthMaintenanceFutureCall(),
      authMaintenanceFutureCallName,
    );
    return true;
  } on StateError {
    // Future calls can be disabled for maintenance/test roles.
    return false;
  }
}
