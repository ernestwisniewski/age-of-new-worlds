part of 'map_screen.dart';

final class _ReadyMap extends StatelessWidget {
  const _ReadyMap({
    required this.scene,
    required this.interaction,
    required this.turnPresentations,
    required this.turnAction,
    required this.research,
    required this.diplomacy,
    required this.localAiTurn,
    required this.localHandoff,
    required this.localSave,
    required this.controller,
    required this.onInput,
    required this.onOpenSettings,
    required this.flameGame,
    required this.flameGeneration,
    required this.flameFocusNode,
    required this.onRetryFlame,
  });

  final MapScene scene;
  final MapInteractionState interaction;
  final TurnPresentationQueue turnPresentations;
  final TurnActionState turnAction;
  final ResearchState research;
  final DiplomacyState diplomacy;
  final LocalAiTurnState localAiTurn;
  final LocalHandoffState localHandoff;
  final LocalSaveState localSave;
  final MapPresentationController controller;
  final ValueChanged<MapInputCommand> onInput;
  final VoidCallback? onOpenSettings;
  final AonwFlameGame flameGame;
  final int flameGeneration;
  final FocusNode flameFocusNode;
  final VoidCallback onRetryFlame;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: FlameMapViewport(
          scene: scene,
          interaction: interaction,
          onInput: onInput,
          game: flameGame,
          generation: flameGeneration,
          focusNode: flameFocusNode,
          onRetry: onRetryFlame,
        ),
      ),
      const Positioned.fill(child: AonwHudMapVignette()),
      const Positioned.fill(child: AonwHudTopFade()),
      TurnBanner(
        presentation: turnPresentations.active,
        onFinished: controller.completeTurnPresentation,
      ),
      Positioned.fill(
        child: TurnPresentationOverlays(
          turn: scene.player.turnView,
          action: turnAction,
          presentations: turnPresentations,
          localAiTurn: localAiTurn,
          onEndTurn: controller.endTurn,
        ),
      ),
      ..._mapActions(context),
      MapSelectionOverlay(
        scene: scene,
        interaction: interaction,
        controller: controller,
      ),
      ..._featureOverlays(),
      NetworkGameStatusOverlay(
        connection: controller.networkConnection,
        onReconnect: controller.reconnectNetworkMatch,
      ),
    ],
  );

  List<Widget> _mapActions(BuildContext context) => [
    if (onOpenSettings case final openSettings?)
      Positioned(
        top: AonwHudSideMenuLayout.top(context),
        left: AonwHudSideMenuLayout.left(context),
        child: AonwHudIconButton(
          key: const ValueKey('open-settings'),
          tooltip: context.aonwL10n.openSettings,
          onPressed: openSettings,
          icon: const Icon(Icons.settings),
        ),
      ),
    Positioned(
      top:
          AonwHudSideMenuLayout.top(context) +
          AonwHudSideMenuLayout.extent +
          AonwHudSideMenuLayout.itemGap,
      left: AonwHudSideMenuLayout.left(context),
      child: const AonwHudSideMenuSeparator(),
    ),
    Positioned(
      top: AonwHudSideMenuLayout.actionTop(context, 3),
      left: AonwHudSideMenuLayout.left(context),
      child: _SaveAction(
        localSave: localSave,
        localAiTurn: localAiTurn,
        localHandoff: localHandoff,
        onSave: controller.saveLocalGame,
      ),
    ),
    Positioned(
      top: AonwHudSideMenuLayout.actionTop(context, 4),
      left: AonwHudSideMenuLayout.left(context),
      child: MapViewModeToggle(
        value: interaction.viewMode.effectiveFor(
          hasReference: scene.reference.pages.isNotEmpty,
        ),
        allowGraphicMode: scene.reference.pages.isNotEmpty,
        onChanged: controller.setMapViewMode,
      ),
    ),
  ];

  List<Widget> _featureOverlays() => [
    Positioned.fill(
      child: MapHudPanels(
        scene: scene,
        research: research,
        diplomacy: diplomacy,
        controller: controller,
      ),
    ),
    Positioned.fill(
      child: LocalHandoffOverlay(
        state: localHandoff,
        onConfirm: controller.confirmLocalHandoff,
        onRetry: controller.retryLocalHandoff,
      ),
    ),
  ];
}
