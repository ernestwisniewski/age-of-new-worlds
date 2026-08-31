import 'package:flutter/material.dart';

import '../../design_system/widgets/aonw_panel.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/local_game/presentation/new_game_screen.dart';
import '../../features/main_menu/presentation/main_menu_screen.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../../features/map/presentation/map_presentation_controller.dart';
import '../../features/map/presentation/widgets/map_screen.dart';
import '../../features/multiplayer/presentation/multiplayer_controller.dart';
import '../../features/multiplayer/presentation/multiplayer_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/replay/application/replay_state.dart';
import '../../features/replay/presentation/replay_presentation_controller.dart';
import '../../features/replay/presentation/replay_screen.dart';
import '../../features/settings/presentation/client_settings_controller.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../game/aonw_flame_game.dart';
import '../../l10n/l10n.dart';

enum AonwRoute {
  menu('/'),
  help('/help'),
  onboarding('/onboarding'),
  newGame('/new-game'),
  multiplayer('/multiplayer'),
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
    this.multiplayerController,
    this.mapInputSource,
    this.autoLoadMap = false,
  });

  final MapPresentationController mapController;
  final ClientSettingsController settingsController;
  final AonwFlameGameFactory flameGameFactory;
  final RouteObserver<ModalRoute<void>> routeObserver;
  final ReplayPresentationController? replayController;
  final MultiplayerController? multiplayerController;
  final MapInputSource? mapInputSource;
  final bool autoLoadMap;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final route = AonwRoute.fromLocation(settings.name);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: switch (route) {
        AonwRoute.menu => (context) => MainMenuScreen(
          onNewGame: () =>
              Navigator.of(context).pushNamed(AonwRoute.newGame.location),
          onOpenSettings: () =>
              Navigator.of(context).pushNamed(AonwRoute.settings.location),
          onOpenHelp: () =>
              Navigator.of(context).pushNamed(AonwRoute.help.location),
          onOpenMultiplayer: multiplayerController == null
              ? null
              : () => Navigator.of(
                  context,
                ).pushNamed(AonwRoute.multiplayer.location),
          hasLocalSave: mapController.hasLocalSave,
          resumeLocalGame: mapController.resumeLatestLocalGame,
          onResumed: () => Navigator.of(
            context,
          ).pushReplacementNamed(AonwRoute.map.location),
          hasLocalReplay: replayController?.hasReplay ?? () async => false,
          openReplay:
              replayController?.openLatest ??
              () async => const ReplayOpenResultView.failed(
                ReplayFailureViewCode.unavailable,
              ),
          onReplayOpened: () =>
              Navigator.of(context).pushNamed(AonwRoute.replay.location),
        ),
        AonwRoute.help => (context) => HelpScreen(
          onStartOnboarding: () => Navigator.of(
            context,
          ).pushReplacementNamed(AonwRoute.onboarding.location),
        ),
        AonwRoute.onboarding => (context) => OnboardingScreen(
          onFinished: () => Navigator.of(
            context,
          ).pushReplacementNamed(AonwRoute.newGame.location),
        ),
        AonwRoute.newGame => (context) => NewGameScreen(
          mapController: mapController,
          onStarted: () => Navigator.of(
            context,
          ).pushReplacementNamed(AonwRoute.map.location),
        ),
        AonwRoute.multiplayer =>
          (_) => multiplayerController == null
              ? const _UnavailableMultiplayer()
              : MultiplayerScreen(controller: multiplayerController!),
        AonwRoute.map => (context) => Scaffold(
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
        ),
        AonwRoute.replay =>
          (_) => replayController == null
              ? const _UnavailableReplay()
              : ReplayScreen(
                  controller: replayController!,
                  flameGameFactory: flameGameFactory,
                ),
        AonwRoute.settings => (_) => SettingsScreen(
          controller: settingsController,
        ),
        null => (_) => _UnknownRoute(location: settings.name),
      },
    );
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
