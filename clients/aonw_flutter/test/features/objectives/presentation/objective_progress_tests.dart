part of 'objective_overlay_test.dart';

void objectiveProgressTests() {
  for (final language in ['en', 'pl', 'fr', 'de', 'es', 'nl']) {
    testWidgets('objective progress uses disclosed facts in $language', (
      tester,
    ) async {
      Future<void> show(List<MapObjectiveProgressView> progress) =>
          tester.pumpWidget(
            LocalizedTestApp(
              locale: Locale(language),
              home: Scaffold(
                body: ObjectiveOverlay(
                  objectives: const [
                    MapObjectiveView(
                      id: 'holy-site-1',
                      type: MapObjectiveType.holySite,
                      coordinate: (col: 2, row: 3),
                      requiredHoldTurns: 4,
                      victoryPoints: 7,
                      goldPerTurn: 2,
                    ),
                  ],
                  progress: progress,
                  playerNames: const {'player-2': 'Aleksandra'},
                  outcome: _ongoing(),
                  open: true,
                  onOpenChanged: (_) {},
                ),
              ),
            ),
          );
      await show(const [
        MapObjectiveProgressView(
          objectiveId: 'holy-site-1',
          controllerPlayerId: 'player-2',
          holdTurns: 9,
        ),
      ]);
      final copy = tester.element(find.byType(ObjectiveOverlay)).aonwL10n;
      expect(
        find.text(copy.objectiveControlProgress('Aleksandra', 9, 4)),
        findsOneWidget,
        reason: 'presentation must not cap authoritative hold turns',
      );
      await show(const [
        MapObjectiveProgressView(
          objectiveId: 'holy-site-1',
          controllerPlayerId: null,
          holdTurns: 999,
        ),
      ]);
      expect(find.text(copy.objectiveControlUnknown), findsOneWidget);
      expect(find.textContaining('Aleksandra'), findsNothing);
      expect(find.textContaining('999'), findsNothing);
      await show(const [
        MapObjectiveProgressView(
          objectiveId: 'another-objective',
          controllerPlayerId: 'player-2',
          holdTurns: 5,
        ),
      ]);
      expect(
        find.byKey(const ValueKey(('objective-progress', 'holy-site-1'))),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
