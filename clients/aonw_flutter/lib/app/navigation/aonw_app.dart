import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/aonw_text_scaler.dart';
import '../../design_system/aonw_theme.dart';
import '../../features/audio/application/game_audio_port.dart';
import '../../features/audio/presentation/game_audio_host.dart';
import '../../features/local_game/application/local_game_session_port.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/map/read_model/map_view_mode.dart';
import '../../features/multiplayer/presentation/multiplayer_access_controller.dart';
import '../../features/multiplayer/presentation/multiplayer_controller.dart';
import '../../features/replay/presentation/replay_presentation_controller.dart';
import '../../features/settings/application/configurable_gamepad_input.dart';
import '../../features/settings/presentation/client_performance_host.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../features/settings/presentation/client_settings_scope.dart';
import '../../features/settings/presentation/window_settings_controller.dart';
import '../../features/settings/presentation/window_settings_host.dart';
import '../../game/aonw_flame_game.dart';
import '../../l10n/aonw_locale_resolution.dart';
import '../../l10n/l10n.dart';
import '../platform/app_platform_actions.dart';
import '../telemetry/client_telemetry.dart';
import 'aonw_load_game_online.dart';
import 'aonw_route_observer.dart';
import 'aonw_router.dart';

final class AonwApp extends StatefulWidget {
  const AonwApp({
    required this.mapController,
    this.mapInputSource,
    this.flameGameFactory = AonwFlameGame.new,
    this.settingsController,
    this.windowSettingsController,
    this.audio,
    this.replayController,
    this.multiplayerAccessController,
    this.multiplayerController,
    this.onExit,
    this.openExternalUri,
    this.telemetry = const NoOpClientTelemetry(),
    this.locale,
    this.initialRoute = AonwRoute.menu,
    super.key,
  });

  final MapPresentationController mapController;
  final MapInputSource? mapInputSource;
  final AonwFlameGame Function() flameGameFactory;
  final ClientSettingsController? settingsController;
  final WindowSettingsController? windowSettingsController;
  final GameAudioPort? audio;
  final ReplayPresentationController? replayController;
  final MultiplayerAccessController? multiplayerAccessController;
  final MultiplayerController? multiplayerController;
  final AppExitRequest? onExit;
  final ExternalUriOpen? openExternalUri;
  final ClientTelemetry telemetry;
  final Locale? locale;
  final AonwRoute initialRoute;

  @override
  State<AonwApp> createState() => _AonwAppState();
}

final class _AonwAppState extends State<AonwApp> with WidgetsBindingObserver {
  late ClientSettingsController _settingsController;
  late Future<void> _settingsReady;
  late AppLifecycleState _lifecycleState;
  final _routeObserver = AonwRouteObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    widget.telemetry.record(ClientTelemetryEvent.appStarted);
    _installSettingsController();
    widget.multiplayerController?.addListener(_synchronizeReplayAccount);
    unawaited(widget.multiplayerAccessController?.initialize());
    _synchronizeInputLifecycle();
  }

  @override
  void didUpdateWidget(AonwApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController != widget.mapController) {
      oldWidget.mapController.dispose();
      _synchronizeClientConfiguration();
    }
    if (oldWidget.replayController != widget.replayController) {
      oldWidget.replayController?.dispose();
      _synchronizeClientConfiguration();
    }
    if (oldWidget.multiplayerController != widget.multiplayerController) {
      oldWidget.multiplayerController?.removeListener(
        _synchronizeReplayAccount,
      );
      oldWidget.multiplayerController?.dispose();
      widget.multiplayerController?.addListener(_synchronizeReplayAccount);
      _synchronizeReplayAccount();
    }
    if (oldWidget.multiplayerAccessController !=
        widget.multiplayerAccessController) {
      oldWidget.multiplayerAccessController?.dispose();
      unawaited(widget.multiplayerAccessController?.initialize());
    }
    if (oldWidget.mapInputSource != widget.mapInputSource) {
      _setInputActive(oldWidget.mapInputSource, false);
      unawaited(oldWidget.mapInputSource?.close());
      _synchronizeClientConfiguration();
      _synchronizeInputLifecycle();
    }
    if (oldWidget.settingsController != widget.settingsController) {
      _settingsController.dispose();
      _installSettingsController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeObserver.menuPopups.dispose();
    _setInputActive(widget.mapInputSource, false);
    widget.mapController.dispose();
    widget.replayController?.dispose();
    widget.multiplayerAccessController?.dispose();
    widget.multiplayerController?.removeListener(_synchronizeReplayAccount);
    widget.multiplayerController?.dispose();
    unawaited(widget.mapInputSource?.close());
    _settingsController.dispose();
    super.dispose();
  }

  void _synchronizeReplayAccount() {
    final controller = widget.multiplayerController;
    final userId = controller == null
        ? null
        : AonwLoadGameOnline(controller).index(available: true).userId;
    widget.replayController?.updateOnlineAccount(userId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasResumed = _lifecycleState == AppLifecycleState.resumed;
    _lifecycleState = state;
    final isResumed = state == AppLifecycleState.resumed;
    if (wasResumed != isResumed) {
      widget.telemetry.record(
        isResumed
            ? ClientTelemetryEvent.appResumed
            : ClientTelemetryEvent.appSuspended,
      );
    }
    _synchronizeInputLifecycle();
  }

  @override
  Widget build(BuildContext context) {
    final router = AonwRouter(
      mapController: widget.mapController,
      mapInputSource: widget.mapInputSource,
      flameGameFactory: widget.flameGameFactory,
      routeObserver: _routeObserver,
      menuPopups: _routeObserver.menuPopups,
      settingsController: _settingsController,
      replayController: widget.replayController,
      multiplayerAccessController: widget.multiplayerAccessController,
      multiplayerController: widget.multiplayerController,
      onExit: widget.onExit,
      openExternalUri: widget.openExternalUri,
      autoLoadMap: widget.initialRoute == AonwRoute.map,
    );
    return WindowSettingsHost(
      controller: widget.windowSettingsController,
      child: GameAudioHost(
        audio: widget.audio,
        settings: _settingsController,
        settingsReady: _settingsReady,
        child: ClientSettingsScope(
          controller: _settingsController,
          child: ListenableBuilder(
            listenable: _settingsController,
            builder: (context, child) => MaterialApp(
              key: ValueKey(widget.mapController),
              onGenerateTitle: (context) => context.aonwL10n.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AonwTheme.darkFor(
                highContrast: _settingsController.settings.highContrast,
              ),
              locale: widget.locale ?? _settingsLocale,
              localeListResolutionCallback: resolveAonwLocale,
              localizationsDelegates: AonwLocalizations.localizationsDelegates,
              supportedLocales: AonwLocalizations.supportedLocales,
              initialRoute: widget.initialRoute.location,
              onGenerateRoute: router.onGenerateRoute,
              navigatorObservers: [_routeObserver],
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    textScaler: AonwTextScaler(
                      system: media.textScaler,
                      factor: _settingsController.settings.textScale.factor,
                    ),
                    disableAnimations:
                        media.disableAnimations ||
                        _settingsController.settings.reducedMotion,
                    highContrast:
                        media.highContrast ||
                        _settingsController.settings.highContrast,
                  ),
                  child: ClientPerformanceHost(
                    settings: _settingsController.settings.performance,
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Locale? get _settingsLocale {
    final code = _settingsController.settings.language.languageCode;
    return code == null ? null : Locale(code);
  }

  void _installSettingsController() {
    _settingsController =
        widget.settingsController ?? ClientSettingsController.ephemeral();
    _settingsController.addListener(_synchronizeClientConfiguration);
    _synchronizeClientConfiguration();
    _settingsReady = _settingsController.load();
  }

  Future<MapViewMode> _readInitialMapViewMode() async {
    while (mounted) {
      final ready = _settingsReady;
      await ready;
      if (identical(ready, _settingsReady)) {
        return _settingsController.settings.preferredMapViewMode;
      }
    }
    return MapViewMode.graphic;
  }

  void _synchronizeClientConfiguration() {
    widget.mapController.bindInitialMapViewMode(_readInitialMapViewMode);
    widget.replayController?.readInitialMapViewMode = _readInitialMapViewMode;
    widget.mapController.configureAiRuntimeProfile(
      _settingsController.settings.ai.batterySaver
          ? LocalAiRuntimeProfileView.batterySaver
          : LocalAiRuntimeProfileView.standard,
    );
    if (widget.mapInputSource case final ConfigurableGamepadInput source) {
      source.configureGamepad(_settingsController.settings.gamepad);
    }
  }

  void _synchronizeInputLifecycle() {
    _setInputActive(
      widget.mapInputSource,
      _lifecycleState == AppLifecycleState.resumed,
    );
  }

  static void _setInputActive(MapInputSource? source, bool active) {
    if (source case final LifecycleAwareMapInputSource lifecycleAware) {
      lifecycleAware.setActive(active);
    }
  }
}
