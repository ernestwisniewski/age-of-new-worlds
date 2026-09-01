import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/map/application/game_session_capabilities.dart';
import '../../features/map/infrastructure/engine_game_session_gateway.dart';
import '../../features/map/infrastructure/gamepad_map_input_source.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/multiplayer/application/multiplayer_coordinator.dart';
import '../../features/multiplayer/infrastructure/auth_token_store.dart';
import '../../features/multiplayer/infrastructure/multiplayer_match_document_source.dart';
import '../../features/multiplayer/infrastructure/server_connection_config.dart';
import '../../features/multiplayer/infrastructure/serverpod_game_session_gateway.dart';
import '../../features/multiplayer/infrastructure/serverpod_multiplayer_session.dart';
import '../../features/multiplayer/presentation/multiplayer_controller.dart';
import '../../features/replay/infrastructure/atomic_local_replay_store.dart';
import '../../features/replay/presentation/replay_presentation_controller.dart';
import '../../features/save_game/application/local_save_store.dart';
import '../../features/save_game/infrastructure/atomic_local_save_store.dart';
import '../../features/settings/application/client_settings_store.dart';
import '../../features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../game/aonw_flame_game.dart';
import '../navigation/aonw_app.dart';
import '../navigation/aonw_router.dart';
import '../platform/app_platform_actions.dart';
import '../telemetry/client_telemetry.dart';

final class AppComposition {
  AppComposition({
    required GameSessionCapabilities capabilities,
    LocalSaveStore? saveStore,
    ReplayPresentationController? replayController,
    MapInputSource? mapInputSource,
    ClientSettingsStore? settingsStore,
    AonwFlameGameFactory flameGameFactory = AonwFlameGame.new,
    ClientTelemetry telemetry = const NoOpClientTelemetry(),
    MultiplayerController? multiplayerController,
    AppExitRequest? onExit,
    ExternalUriOpen? openExternalUri,
    AonwRoute initialRoute = AonwRoute.menu,
  }) : root = AonwApp(
         mapController: MapPresentationController(
           capabilities: capabilities,
           saveStore: saveStore,
           replayCapture: replayController,
         ),
         mapInputSource: mapInputSource,
         flameGameFactory: flameGameFactory,
         telemetry: telemetry,
         multiplayerController: multiplayerController,
         onExit: onExit,
         openExternalUri: openExternalUri,
         replayController: replayController,
         initialRoute: initialRoute,
         settingsController: settingsStore == null
             ? ClientSettingsController.ephemeral()
             : ClientSettingsController(store: settingsStore),
       );

  factory AppComposition.production({
    ClientTelemetry telemetry = const DebugClientTelemetry(),
  }) {
    final gateway = EngineGameSessionGateway(assets: rootBundle);
    final replayController = ReplayPresentationController(
      session: gateway.replaySession,
      store: AtomicLocalReplayStore.production(),
    );
    final multiplayerSession = ServerpodMultiplayerSession(
      config: ServerConnectionConfig.production(),
      tokenStore: const SecureAuthTokenStore(),
    );
    final multiplayerController = MultiplayerController(
      MultiplayerCoordinator(
        session: multiplayerSession,
        documents: AssetMultiplayerMatchDocumentSource(assets: rootBundle),
      ),
    );
    final networkGame = ServerpodGameSessionGateway(
      gameplay: gateway,
      multiplayer: multiplayerSession,
    );
    return AppComposition(
      capabilities: gateway.capabilities.withNetworkGame(networkGame),
      saveStore: AtomicLocalSaveStore.production(),
      replayController: replayController,
      mapInputSource: GamepadMapInputSource(),
      settingsStore: SharedPreferencesClientSettingsStore(),
      multiplayerController: multiplayerController,
      onExit: SystemNavigator.pop,
      openExternalUri: _openExternalUri,
      telemetry: telemetry,
    );
  }

  final AonwApp root;
}

Future<bool> _openExternalUri(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
