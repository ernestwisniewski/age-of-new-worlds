import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/aonw_theme.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/multiplayer/presentation/multiplayer_controller.dart';
import '../../features/replay/presentation/replay_presentation_controller.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../features/settings/presentation/client_settings_scope.dart';
import '../../game/aonw_flame_game.dart';
import '../../l10n/l10n.dart';
import '../telemetry/client_telemetry.dart';
import 'aonw_router.dart';

final class AonwApp extends StatefulWidget {
  const AonwApp({
    required this.mapController,
    this.mapInputSource,
    this.flameGameFactory = AonwFlameGame.new,
    this.settingsController,
    this.replayController,
    this.multiplayerController,
    this.telemetry = const NoOpClientTelemetry(),
    this.locale,
    this.initialRoute = AonwRoute.menu,
    super.key,
  });

  final MapPresentationController mapController;
  final MapInputSource? mapInputSource;
  final AonwFlameGameFactory flameGameFactory;
  final ClientSettingsController? settingsController;
  final ReplayPresentationController? replayController;
  final MultiplayerController? multiplayerController;
  final ClientTelemetry telemetry;
  final Locale? locale;
  final AonwRoute initialRoute;

  @override
  State<AonwApp> createState() => _AonwAppState();
}

final class _AonwAppState extends State<AonwApp> with WidgetsBindingObserver {
  late ClientSettingsController _settingsController;
  late AppLifecycleState _lifecycleState;
  final _routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    widget.telemetry.record(ClientTelemetryEvent.appStarted);
    _installSettingsController();
    _synchronizeInputLifecycle();
  }

  @override
  void didUpdateWidget(AonwApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController != widget.mapController) {
      oldWidget.mapController.dispose();
    }
    if (oldWidget.replayController != widget.replayController) {
      oldWidget.replayController?.dispose();
    }
    if (oldWidget.multiplayerController != widget.multiplayerController) {
      oldWidget.multiplayerController?.dispose();
    }
    if (oldWidget.mapInputSource != widget.mapInputSource) {
      _setInputActive(oldWidget.mapInputSource, false);
      unawaited(oldWidget.mapInputSource?.close());
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
    _setInputActive(widget.mapInputSource, false);
    widget.mapController.dispose();
    widget.replayController?.dispose();
    widget.multiplayerController?.dispose();
    unawaited(widget.mapInputSource?.close());
    _settingsController.dispose();
    super.dispose();
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
      settingsController: _settingsController,
      replayController: widget.replayController,
      multiplayerController: widget.multiplayerController,
      autoLoadMap: widget.initialRoute == AonwRoute.map,
    );
    return ClientSettingsScope(
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
          locale: widget.locale,
          localizationsDelegates: AonwLocalizations.localizationsDelegates,
          supportedLocales: AonwLocalizations.supportedLocales,
          initialRoute: widget.initialRoute.location,
          onGenerateRoute: router.onGenerateRoute,
          navigatorObservers: [_routeObserver],
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                disableAnimations:
                    media.disableAnimations ||
                    _settingsController.settings.reducedMotion,
                highContrast:
                    media.highContrast ||
                    _settingsController.settings.highContrast,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  void _installSettingsController() {
    _settingsController =
        widget.settingsController ?? ClientSettingsController.ephemeral();
    unawaited(_settingsController.load());
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
