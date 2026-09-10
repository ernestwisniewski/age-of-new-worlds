part of 'research_overlay_test.dart';

void researchTreeCases() {
  test(
    'tree layout preserves projected edges and tolerates invalid graphs',
    () {
      final options = _treeOptions().options;
      final layout = ResearchTreeLayout.fromOptions(options)!;
      expect(layout.columns.map((column) => column.length), [2, 2, 2]);
      expect(layout.columns[2].last.technology, TechnologyIdView.fishing);
      expect(
        ResearchTreeLayout.fromOptions([options.first, options.first]),
        isNull,
      );
      expect(ResearchTreeLayout.fromOptions([options.last]), isNull);
      expect(
        ResearchTreeLayout.fromOptions([
          _treeOption(TechnologyIdView.agriculture, [TechnologyIdView.fishing]),
          _treeOption(TechnologyIdView.fishing, [TechnologyIdView.agriculture]),
        ]),
        isNull,
      );
    },
  );

  testWidgets('tree details preserve authority and Escape returns to tree', (
    tester,
  ) async {
    final selected = <TechnologyIdView>[];
    await tester.pumpWidget(_treeApp(_treeOptions(), selected.add));
    await tester.tap(find.byKey(const ValueKey('research-view-mode')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey(('research-tree-node', 'agriculture'))),
    );
    await tester.pump();
    expect(selected, isEmpty);
    final choose = find.byKey(
      const ValueKey(('select-technology', 'agriculture')),
    );
    expect(tester.widget<FilledButton>(choose).onPressed, isNotNull);
    await tester.tap(choose);
    expect(selected, [TechnologyIdView.agriculture]);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('research-tree-horizontal')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey(('research-tree-node', 'woodworking'))),
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey(('select-technology', 'woodworking'))),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'gamepad backs out of details and tree without closing research',
    (tester) async {
      var returnedToMap = 0;
      final navigation = MapGamepadNavigation(
        onOwnerChanged: () {},
        returnToMap: () => returnedToMap++,
      );
      addTearDown(navigation.dispose);
      await tester.pumpWidget(
        MapGamepadNavigationScope(
          navigation: navigation,
          child: _treeApp(_treeOptions(), (_) {}),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('research-view-mode')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey(('research-tree-node', 'agriculture'))),
      );
      await tester.pump();
      expect(navigation.handleCommand(MapInputCommand.cancel), isTrue);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('research-tree-horizontal')),
        findsOneWidget,
      );
      expect(navigation.handleCommand(MapInputCommand.cancel), isTrue);
      await tester.pump();
      expect(find.byKey(const ValueKey('research-options')), findsOneWidget);
      expect(returnedToMap, 0);
    },
  );

  testWidgets(
    'recipient change removes tree details and pending blocks selection',
    (tester) async {
      final options = _treeOptions();
      await tester.pumpWidget(_treeApp(options, (_) {}, pending: true));
      await tester.tap(find.byKey(const ValueKey('research-view-mode')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey(('research-tree-node', 'agriculture'))),
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey(('select-technology', 'agriculture'))),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(
        _treeApp(_treeOptions(player: 'other-player'), (_) {}),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('research-options')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('research-tree-horizontal')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(1024, 768),
    const Size(1440, 900),
  ]) {
    testWidgets('tree scrolls and stays idle at ${size.width}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_treeApp(_treeOptions(), (_) {}, size: size));
      await tester.tap(find.byKey(const ValueKey('research-view-mode')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('tree-golden')),
        matchesGoldenFile('goldens/tree_${size.width.toInt()}.png'),
      );
      final target = find.byKey(
        const ValueKey(('research-tree-node', 'fishing')),
      );
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey(('research-tree-details', TechnologyIdView.fishing)),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('research-view-mode')));
      await tester.pumpAndSettle();
      expect(tester.getRect(target).right, lessThanOrEqualTo(size.width - 60));
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    testWidgets('full tree fits doubled $language text on phone', (
      tester,
    ) async {
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _treeApp(_options(), (_) {}, size: size, language: language, scale: 2),
      );
      await tester.tap(find.byKey(const ValueKey('research-view-mode')));
      await tester.pumpAndSettle();
      expect(
        find.byType(OutlinedButton),
        findsNWidgets(TechnologyIdView.values.length),
      );
      final last = find.byKey(
        const ValueKey(('research-tree-node', 'nuclearPhysics')),
      );
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey((
            'research-tree-details',
            TechnologyIdView.nuclearPhysics,
          )),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _treeApp(
  ResearchOptionsView options,
  ValueChanged<TechnologyIdView> onSelect, {
  bool pending = false,
  Size size = const Size(800, 600),
  String language = 'de',
  double scale = 1.3,
}) => LocalizedTestApp(
  theme: AonwTheme.dark,
  locale: Locale(language),
  home: RepaintBoundary(
    key: const ValueKey('tree-golden'),
    child: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: ResearchOverlay(
          state: ResearchState(
            requestedRevision: 0,
            options: options,
            inFlightTechnology: pending ? TechnologyIdView.agriculture : null,
          ),
          selectionRequired: false,
          open: true,
          trailingReserve: 60,
          onOpenChanged: (_) {},
          onSelect: onSelect,
          onRetry: () {},
        ),
      ),
    ),
  ),
);

ResearchOptionsView _treeOptions({String player = 'preview-player'}) {
  final base = testResearchOptionsView();
  return ResearchOptionsView(
    stamp: base.stamp,
    playerId: player,
    activeTechnology: null,
    scienceOverflow: 3,
    scienceYield: base.scienceYield,
    options: [
      _treeOption(TechnologyIdView.agriculture, []),
      _treeOption(TechnologyIdView.woodworking, []),
      _treeOption(TechnologyIdView.mining, [TechnologyIdView.agriculture]),
      _treeOption(TechnologyIdView.animalHusbandry, [
        TechnologyIdView.woodworking,
      ]),
      _treeOption(TechnologyIdView.hunting, [TechnologyIdView.mining]),
      _treeOption(TechnologyIdView.fishing, [
        TechnologyIdView.mining,
        TechnologyIdView.animalHusbandry,
      ]),
    ],
  );
}

ResearchOptionView _treeOption(
  TechnologyIdView id,
  List<TechnologyIdView> parents,
) => ResearchOptionView(
  technology: id,
  availability: id == TechnologyIdView.agriculture
      ? TechnologyAvailabilityView.available
      : TechnologyAvailabilityView.lockedByPrerequisites,
  effectiveCost: 12,
  progress: 3,
  boostDiscountBasisPoints: 0,
  prerequisites: parents,
  blockedBy: [],
  unlocks: [],
);
