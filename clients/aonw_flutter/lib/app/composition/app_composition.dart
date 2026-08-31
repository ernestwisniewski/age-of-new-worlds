import 'package:flutter/services.dart';

import '../../features/map/application/game_session_capabilities.dart';
import '../../features/map/infrastructure/engine_game_session_gateway.dart';
import '../../features/map/infrastructure/gamepad_map_input_source.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/multiplayer/application/multiplayer_coordinator.dart';
import '../../features/multiplayer/infrastructure/auth_token_store.dart';
import '../../features/multiplayer/infrastructure/multiplayer_match_document_source.dart';
import '../../features/multiplayer/infrastructure/server_connection_config.dart';
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
    final multiplayerController = MultiplayerController(
      MultiplayerCoordinator(
        session: ServerpodMultiplayerSession(
          config: ServerConnectionConfig.production(),
          tokenStore: const SecureAuthTokenStore(),
        ),
        documents: AssetMultiplayerMatchDocumentSource(assets: rootBundle),
      ),
    );
    return AppComposition(
      capabilities: gateway.capabilities,
      saveStore: AtomicLocalSaveStore.production(),
      replayController: replayController,
      mapInputSource: GamepadMapInputSource(),
      settingsStore: SharedPreferencesClientSettingsStore(),
      multiplayerController: multiplayerController,
      telemetry: telemetry,
    );
  }

  final AonwApp root;
}
