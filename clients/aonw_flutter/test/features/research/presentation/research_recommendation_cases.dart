part of 'research_overlay_test.dart';

void researchRecommendationCases() {
  testWidgets('recommendations preserve supplied order, ETA and selection', (
    tester,
  ) async {
    final selected = <TechnologyIdView>[];
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _treeApp(_recommendedOptions(), selected.add, language: 'en', scale: 1),
    );
    expect(
      find.byKey(const ValueKey('research-recommendations')),
      findsOneWidget,
    );
    expect(find.text('Estimated turns: 17'), findsOneWidget);
    expect(find.text('Worker yields'), findsOneWidget);
    final cards = tester.widgetList<Card>(find.byType(Card)).toList();
    expect(cards.map((card) => card.key), [
      const ValueKey(('research-option', 'mining')),
      const ValueKey(('research-option', 'fishing')),
      const ValueKey(('research-option', 'agriculture')),
    ]);
    await tester.tap(
      find.byKey(const ValueKey('research-recommendations-mode')),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('research-options')), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('research-recommendations-mode')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('research-view-mode')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('research-recommendations')),
      findsOneWidget,
    );
    expect(selected, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey(('select-technology', 'mining'))),
    );
    expect(selected, [TechnologyIdView.mining]);
    expect(tester.takeException(), isNull);
  });

  for (final sample in [
    (size: const Size(390, 844), language: 'pl', scale: 1.3),
    (size: const Size(1024, 768), language: 'de', scale: 1.0),
    (size: const Size(1440, 900), language: 'en', scale: 1.0),
  ]) {
    testWidgets('recommendations golden ${sample.language}', (tester) async {
      await tester.binding.setSurfaceSize(sample.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _treeApp(
          _recommendedOptions(),
          (_) {},
          size: sample.size,
          language: sample.language,
          scale: sample.scale,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('tree-golden')),
        matchesGoldenFile('goldens/recommendations_${sample.language}.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['pl', 'en', 'de', 'fr', 'es', 'nl']) {
    testWidgets('recommendations at 200 percent in $language', (tester) async {
      const size = Size(740, 360);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _treeApp(
          _recommendedOptions(),
          (_) {},
          size: size,
          language: language,
          scale: 2,
          pending: true,
        ),
      );
      await tester.pump();
      final select = find.byKey(
        const ValueKey(('select-technology', 'mining')),
      );
      await tester.ensureVisible(select);
      expect(tester.widget<FilledButton>(select).onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}

ResearchOptionsView _recommendedOptions() {
  final base = testResearchOptionsView();
  return ResearchOptionsView(
    stamp: base.stamp,
    playerId: base.playerId,
    activeTechnology: null,
    scienceOverflow: base.scienceOverflow,
    scienceYield: base.scienceYield,
    options: base.options,
    recommendations: [
      ResearchRecommendationView(
        technology: TechnologyIdView.mining,
        score: 90,
        turnsRemaining: 17,
        reasons: [ResearchRecommendationReasonView.workerYields],
      ),
      ResearchRecommendationView(
        technology: TechnologyIdView.fishing,
        score: 80,
        turnsRemaining: null,
        reasons: [ResearchRecommendationReasonView.unlocks],
      ),
      ResearchRecommendationView(
        technology: TechnologyIdView.agriculture,
        score: 70,
        turnsRemaining: 2,
        reasons: [ResearchRecommendationReasonView.nearCompletion],
      ),
    ],
  );
}
