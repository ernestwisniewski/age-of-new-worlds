part of 'map_screen.dart';

final class _ReadyMap extends StatelessWidget {
  const _ReadyMap({
    required this.scene,
    required this.inspection,
    required this.interaction,
    required this.turnPresentations,
    required this.turnAction,
    required this.research,
    required this.diplomacy,
    required this.localAiTurn,
    required this.localHandoff,
    required this.localSave,
    required this.controller,
    required this.interactionEnabled,
    required this.onInput,
    required this.onTurnShortcut,
    required this.onNavigateTurn,
    required this.canPanKeyboard,
    required this.onOpenSettings,
    required this.flameGame,
    required this.flameGeneration,
    required this.flameFocusNode,
    required this.gamepadNavigation,
    required this.onRetryFlame,
  });

  final MapScene scene;
  final HexInspectionState? inspection;
  final MapInteractionState interaction;
  final TurnPresentationQueue turnPresentations;
  final TurnActionState turnAction;
  final ResearchState research;
  final DiplomacyState diplomacy;
  final LocalAiTurnState localAiTurn;
  final LocalHandoffState localHandoff;
  final LocalSaveState localSave;
  final MapPresentationController controller;
  final bool interactionEnabled;
  final ValueChanged<MapInputCommand> onInput;
  final ValueChanged<MapTurnShortcut> onTurnShortcut;
  final ValueChanged<int> onNavigateTurn;
  final bool Function() canPanKeyboard;
  final VoidCallback? onOpenSettings;
  final AonwFlameGame flameGame;
  final int flameGeneration;
  final FocusNode flameFocusNode;
  final MapGamepadNavigation gamepadNavigation;
  final VoidCallback onRetryFlame;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: FlameMapViewport(
          scene: scene,
          interaction: interaction,
          onInput: onInput,
          onTurnShortcut: onTurnShortcut,
          canPan: canPanKeyboard,
          game: flameGame,
          generation: flameGeneration,
          focusNode: flameFocusNode,
          onRetry: onRetryFlame,
        ),
      ),
      const Positioned.fill(child: AonwHudMapVignette()),
      const Positioned.fill(child: AonwHudTopFade()),
      if (!controller.readOnly)
        TurnBanner(
          presentation: turnPresentations.active,
          onFinished: controller.completeTurnPresentation,
        ),
      if (!controller.readOnly)
        Positioned.fill(
          child: TurnPresentationOverlays(
            turn: scene.player.turnView,
            turnMode: scene.player.turnMode,
            action: turnAction,
            presentations: turnPresentations,
            localAiTurn: localAiTurn,
            onEndTurn: controller.endTurn,
            onNavigateTurn: onNavigateTurn,
          ),
        ),
      ..._mapActions(context),
      if (interactionEnabled)
        MapSelectionOverlay(
          scene: scene,
          interaction: interaction,
          controller: controller,
        ),
      ..._featureOverlays(),
      if (inspection case final value? when interactionEnabled)
        HexInspectionOverlay(
          state: value,
          scene: scene,
          anchor: flameGame.mapCamera.screenForHex(value.coordinate),
          onClose: controller.closeHexInspection,
          onRetry: () => controller.inspectHex(value.coordinate),
        ),
      NetworkGameStatusOverlay(
        connection: controller.networkConnection,
        onReconnect: controller.reconnectNetworkMatch,
      ),
      Positioned.fill(
        child: MapGamepadFocusRing(navigation: gamepadNavigation),
      ),
    ],
  );

  List<Widget> _mapActions(BuildContext context) => [
    if (onOpenSettings case final openSettings?)
      Positioned(
        top: AonwHudSideMenuLayout.top(context),
        left: AonwHudSideMenuLayout.left(context),
        child: MapGamepadRegion(
          section: MapHudSection.menu,
          child: AonwHudIconButton(
            key: const ValueKey('open-settings'),
            tooltip: context.aonwL10n.openSettings,
            onPressed: openSettings,
            icon: const Icon(Icons.settings),
          ),
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
    if (!controller.readOnly)
      Positioned(
        top: AonwHudSideMenuLayout.actionTop(context, 3),
        left: AonwHudSideMenuLayout.left(context),
        child: MapGamepadRegion(
          section: MapHudSection.globalActions,
          child: _SaveAction(
            localSave: localSave,
            localAiTurn: localAiTurn,
            localHandoff: localHandoff,
            onSave: controller.saveLocalGame,
          ),
        ),
      ),
    Positioned(
      top: AonwHudSideMenuLayout.actionTop(context, 4),
      left: AonwHudSideMenuLayout.left(context),
      child: MapGamepadRegion(
        section: MapHudSection.globalActions,
        child: MapViewModeToggle(
          value: interaction.viewMode.effectiveFor(
            hasReference: scene.reference.pages.isNotEmpty,
          ),
          allowGraphicMode: scene.reference.pages.isNotEmpty,
          onChanged: controller.setMapViewMode,
        ),
      ),
    ),
  ];

  List<Widget> _featureOverlays() => [
    Positioned.fill(
      child: MapGamepadRegion(
        section: MapHudSection.globalActions,
        child: MapHudPanels(
          blocked: !interactionEnabled,
          scene: scene,
          research: research,
          diplomacy: diplomacy,
          controller: controller,
        ),
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
