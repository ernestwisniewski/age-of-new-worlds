import 'package:flutter/material.dart';

import '../../design_system/widgets/aonw_panel.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/local_game/presentation/local_game_launch_mode.dart';
import '../../features/local_game/presentation/new_game_screen.dart';
import '../../features/main_menu/presentation/main_menu_screen.dart';
import '../../features/main_menu/presentation/main_menu_support_screens.dart';
import '../../features/map/application/network_game_session_port.dart';
import '../../features/map/presentation/input/map_gamepad_input.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/map/presentation/widgets/map_screen.dart';
import '../../features/multiplayer/application/multiplayer_state.dart';
import '../../features/multiplayer/presentation/multiplayer_access_controller.dart';
import '../../features/multiplayer/presentation/multiplayer_controller.dart';
import '../../features/multiplayer/presentation/multiplayer_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/replay/application/replay_state.dart';
import '../../features/replay/presentation/replay_presentation_controller.dart';
import '../../features/replay/presentation/replay_screen.dart';
import '../../features/save_game/presentation/load_game_screen.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../game/aonw_flame_game.dart';
import '../../l10n/l10n.dart';
import '../platform/app_platform_actions.dart';
import 'aonw_menu_navigation.dart';

enum AonwRoute {
  menu('/'),
  help('/help'),
  onboarding('/onboarding'),
  newGame('/new-game'),
  hotseat('/hotseat'),
  multiplayer('/multiplayer'),
  loadGame('/load-game'),
  credits('/credits'),
  feedback('/feedback'),
  map('/map'),
  replay('/replay'),
  settings('/settings');

  const AonwRoute(this.location);

  final String location;

  static AonwRoute? fromLocation(String? location) {
    for (final route in values) {
      if (route.location == location) return route;
    }
    return null;
  }
}

final class AonwRouter {
  const AonwRouter({
    required this.mapController,
    required this.settingsController,
    required this.flameGameFactory,
    required this.routeObserver,
    this.replayController,
    this.multiplayerAccessController,
    this.multiplayerController,
    this.mapInputSource,
    this.onExit,
    this.openExternalUri,
    this.autoLoadMap = false,
  });

  final MapPresentationController mapController;
  final ClientSettingsController settingsController;
  final AonwFlameGameFactory flameGameFactory;
  final RouteObserver<ModalRoute<void>> routeObserver;
  final ReplayPresentationController? replayController;
  final MultiplayerAccessController? multiplayerAccessController;
  final MultiplayerController? multiplayerController;
  final MapInputSource? mapInputSource;
  final AppExitRequest? onExit;
  final ExternalUriOpen? openExternalUri;
  final bool autoLoadMap;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final route = AonwRoute.fromLocation(settings.name);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        final screen = route == null
            ? _UnknownRoute(location: settings.name)
            : _routeBuilders[route]!(context);
        return _withMenuNavigation(route, screen);
      },
    );
  }

  Widget _withMenuNavigation(AonwRoute? route, Widget child) {
    if (route == AonwRoute.map || route == AonwRoute.replay) return child;
    final input = switch (mapInputSource) {
      final ContinuousMapInputSource source => source.continuousInputs,
      _ => null,
    };
    return AonwMenuNavigation(input: input, child: child);
  }

  Map<AonwRoute, WidgetBuilder> get _routeBuilders => {
    AonwRoute.menu: _menuScreen,
    AonwRoute.help: _helpScreen,
    AonwRoute.onboarding: _onboardingScreen,
    AonwRoute.newGame: _newGameScreen,
    AonwRoute.hotseat: _hotseatScreen,
    AonwRoute.multiplayer: _multiplayerScreen,
    AonwRoute.loadGame: _loadGameScreen,
    AonwRoute.credits: _creditsScreen,
    AonwRoute.feedback: _feedbackScreen,
    AonwRoute.map: _mapScreen,
    AonwRoute.replay: _replayScreen,
    AonwRoute.settings: _settingsScreen,
  };

  Widget _menuScreen(BuildContext context) {
    Widget buildMenu() => MainMenuScreen(
      onOpenSinglePlayer: () =>
          Navigator.of(context).pushNamed(AonwRoute.newGame.location),
      onOpenMultiplayer: _multiplayerAvailable()
          ? () =>
                Navigator.of(context).pushNamed(AonwRoute.multiplayer.location)
          : null,
      onOpenHotseat: () =>
          Navigator.of(context).pushNamed(AonwRoute.hotseat.location),
      onOpenLoadGame: () =>
          Navigator.of(context).pushNamed(AonwRoute.loadGame.location),
      onOpenSettings: () =>
          Navigator.of(context).pushNamed(AonwRoute.settings.location),
      onOpenInstructions: () =>
          Navigator.of(context).pushNamed(AonwRoute.help.location),
      onOpenCredits: () =>
          Navigator.of(context).pushNamed(AonwRoute.credits.location),
      onOpenFeedback: () =>
          Navigator.of(context).pushNamed(AonwRoute.feedback.location),
      onExit: onExit,
      serverUpdateRequired: _serverUpdateRequired(),
    );

    final listenables = <Listenable>[
      ?multiplayerAccessController,
      ?multiplayerController,
    ];
    if (listenables.isEmpty) return buildMenu();
    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, child) => buildMenu(),
    );
  }

  Widget _helpScreen(BuildContext context) => HelpScreen(
    onStartOnboarding: () => Navigator.of(
      context,
    ).pushReplacementNamed(AonwRoute.onboarding.location),
  );

  Widget _onboardingScreen(BuildContext context) => OnboardingScreen(
    onFinished: () =>
        Navigator.of(context).pushReplacementNamed(AonwRoute.newGame.location),
  );

  Widget _newGameScreen(BuildContext context) => NewGameScreen(
    mapController: mapController,
    initialMode: LocalGameLaunchModeView.singlePlayer,
    onStarted: () =>
        Navigator.of(context).pushReplacementNamed(AonwRoute.map.location),
  );

  Widget _hotseatScreen(BuildContext context) => NewGameScreen(
    mapController: mapController,
    initialMode: LocalGameLaunchModeView.hotseat,
    onStarted: () =>
        Navigator.of(context).pushReplacementNamed(AonwRoute.map.location),
  );

  Widget _multiplayerScreen(BuildContext context) =>
      multiplayerController == null
      ? const _UnavailableMultiplayer()
      : MultiplayerScreen(
          controller: multiplayerController!,
          onOpenGame: (projection) async {
            final opened = await mapController.startNetworkMatch(
              NetworkMatchSetupView(
                matchId: projection.matchId,
                playerId: projection.playerId,
              ),
            );
            if (opened && context.mounted) {
              await Navigator.of(context).pushNamed(AonwRoute.map.location);
              if (context.mounted) {
                await multiplayerController!.reconnect();
              }
            }
          },
        );

  Widget _loadGameScreen(BuildContext context) => LoadGameScreen(
    hasLocalSave: mapController.hasLocalSave,
    resumeLocalGame: mapController.resumeLatestLocalGame,
    onResumed: () =>
        Navigator.of(context).pushReplacementNamed(AonwRoute.map.location),
    hasLocalReplay: replayController?.hasReplay ?? () async => false,
    openReplay:
        replayController?.openLatest ??
        () async => const ReplayOpenResultView.failed(
          ReplayFailureViewCode.unavailable,
        ),
    onReplayOpened: () =>
        Navigator.of(context).pushNamed(AonwRoute.replay.location),
    onStartSinglePlayer: () =>
        Navigator.of(context).pushReplacementNamed(AonwRoute.newGame.location),
  );

  Widget _creditsScreen(BuildContext context) =>
      CreditsScreen(openExternalUri: openExternalUri);

  Widget _feedbackScreen(BuildContext context) =>
      FeedbackScreen(openExternalUri: openExternalUri);

  Widget _mapScreen(BuildContext context) => Scaffold(
    body: SafeArea(
      child: MapScreen(
        controller: mapController,
        inputSource: mapInputSource,
        flameGameFactory: flameGameFactory,
        routeObserver: routeObserver,
        autoLoad: autoLoadMap,
        onOpenSettings: () =>
            Navigator.of(context).pushNamed(AonwRoute.settings.location),
      ),
    ),
  );

  Widget _replayScreen(BuildContext context) => replayController == null
      ? const _UnavailableReplay()
      : ReplayScreen(
          controller: replayController!,
          flameGameFactory: flameGameFactory,
        );

  Widget _settingsScreen(BuildContext context) =>
      SettingsScreen(controller: settingsController);

  bool _serverUpdateRequired() {
    if (multiplayerAccessController?.updateRequired ?? false) return true;
    final state = multiplayerController?.state;
    final failure = switch (state) {
      MultiplayerSignedOut(:final failureCode) => failureCode,
      MultiplayerLobby(:final failureCode) => failureCode,
      MultiplayerInMatch(:final failureCode) => failureCode,
      _ => null,
    };
    return failure == 'client_update_required';
  }

  bool _multiplayerAvailable() {
    if (multiplayerController == null) return false;
    final access = multiplayerAccessController;
    if (access != null && !access.allowsConnection) return false;
    return !_serverUpdateRequired();
  }
}

final class _UnavailableMultiplayer extends StatelessWidget {
  const _UnavailableMultiplayer();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: AonwMessagePanel(
          semanticLabel: context.aonwL10n.multiplayerUnavailable,
          title: context.aonwL10n.multiplayerTitle,
          message: context.aonwL10n.multiplayerUnavailable,
        ),
      ),
    ),
  );
}

final class _UnavailableReplay extends StatelessWidget {
  const _UnavailableReplay();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: AonwMessagePanel(
          semanticLabel: context.aonwL10n.replayUnavailable,
          title: context.aonwL10n.replayTitle,
          message: context.aonwL10n.replayUnavailable,
        ),
      ),
    ),
  );
}

final class _UnknownRoute extends StatelessWidget {
  const _UnknownRoute({required this.location});

  final String? location;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AonwMessagePanel(
            key: const ValueKey('unknown-route'),
            semanticLabel: l10n.unknownRouteLabel,
            title: l10n.pageUnavailable,
            message: l10n.unknownRouteMessage(
              location ?? l10n.missingRouteLocation,
            ),
          ),
        ),
      ),
    );
  }
}
