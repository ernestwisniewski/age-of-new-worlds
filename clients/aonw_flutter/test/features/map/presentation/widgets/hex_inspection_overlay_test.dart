import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/hex_inspection_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/hex_inspection_overlay.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/hex_inspection_placement.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:aonw_flutter/features/map/read_model/hex_inspection_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Cinzel')..addFont(
          rootBundle.load('assets/fonts/Cinzel-VariableFont_wght.ttf'),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'Lato',
    )..addFont(rootBundle.load('assets/fonts/Lato-Regular.ttf'))).load();
  });

  test('placement stays inside narrow and short viewports on both sides', () {
    for (final size in [
      const Size(900, 700),
      const Size(220, 140),
      const Size(1, 1),
    ]) {
      for (final anchor in [
        Offset.zero,
        size.bottomRight(Offset.zero),
        size.center(Offset.zero),
      ]) {
        final placement = HexInspectionPlacement.inViewport(size, anchor);
        expect(placement.bounds.left, greaterThanOrEqualTo(0));
        expect(placement.bounds.top, greaterThanOrEqualTo(0));
        expect(placement.bounds.right, lessThanOrEqualTo(size.width));
        expect(placement.bounds.bottom, lessThanOrEqualTo(size.height));
      }
    }
    expect(
      HexInspectionPlacement.inViewport(
        const Size(900, 700),
        const Offset(20, 20),
      ).arrowOnLeft,
      isTrue,
    );
    expect(
      HexInspectionPlacement.inViewport(
        const Size(900, 700),
        const Offset(880, 20),
      ).arrowOnLeft,
      isFalse,
    );
  });

  for (final locale in ['en', 'pl']) {
    testWidgets(
      'renders localized assessment and technology requirements ($locale)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: Locale(locale),
            theme: AonwTheme.dark,
            home: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey('inspection-capture'),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    HexInspectionOverlay(
                      state: HexInspectionReady(_view()),
                      scene: testMapScene(),
                      anchor: (x: 80, y: 85),
                      onClose: () {},
                      onRetry: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = tester.element(find.byType(HexInspectionOverlay)).aonwL10n;
        expect(
          find.text(l10n.hexInspectionKind('forestForge')),
          findsOneWidget,
        );
        expect(
          find.text(l10n.hexInspectionRecommendation('defendHere')),
          findsOneWidget,
        );
        expect(find.text(l10n.presentationName('coal')), findsOneWidget);
        expect(find.text(l10n.presentationName('oil')), findsNothing);
        expect(
          find.textContaining(l10n.technologyName('woodworking')),
          findsOneWidget,
        );
        expect(
          find.textContaining(l10n.hexInspectionText('locked')),
          findsOneWidget,
        );
        expect(find.text(l10n.hexInspectionText('riverBonus')), findsOneWidget);
        expect(
          find.text(l10n.hexInspectionText('defenseBonus')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('inspection-capture')),
          matchesGoldenFile('goldens/hex_inspection_$locale.png'),
        );
      },
    );
  }

  testWidgets('popup captures scroll and B before the underlying panel', (
    tester,
  ) async {
    var closed = 0;
    var panelClosed = 0;
    final navigation = MapGamepadNavigation(
      onOwnerChanged: () {},
      returnToMap: () {},
    );
    addTearDown(navigation.dispose);
    await tester.binding.setSurfaceSize(const Size(280, 250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MapGamepadNavigationScope(
            navigation: navigation,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HexInspectionOverlay(
                  state: HexInspectionReady(_view()),
                  scene: testMapScene(),
                  anchor: (x: 100, y: 80),
                  onClose: () => closed++,
                  onRetry: () {},
                ),
                // Registering a panel later cannot steal the popup's input.
                MapGamepadRegion(
                  section: MapHudSection.menu,
                  priority: MapGamepadPriority.panel,
                  onCancel: () => panelClosed++,
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(HexInspectionOverlay),
        matching: find.byType(Scrollable),
      ),
    );
    final beforeScroll = scroll.position.pixels;
    navigation.handleCommand(MapInputCommand.cursorDown);
    await tester.pump();
    expect(scroll.position.pixels, greaterThan(beforeScroll));
    navigation.handleCommand(MapInputCommand.cancel);
    expect(closed, 1);
    expect(panelClosed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows authored objective rules only at the inspected coordinate',
    (tester) async {
      final objective = MapObjectiveView(
        id: 'pass',
        type: MapObjectiveType.strategicPass,
        coordinate: (col: 0, row: 0),
        requiredHoldTurns: 4,
        victoryPoints: 7,
        goldPerTurn: 2,
      );
      await tester.pumpWidget(
        LocalizedTestApp(
          home: Scaffold(
            body: Stack(
              children: [
                HexInspectionOverlay(
                  state: HexInspectionReady(_view()),
                  scene: testMapScene(objectives: [objective]),
                  anchor: null,
                  onClose: () {},
                  onRetry: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = tester.element(find.byType(HexInspectionOverlay)).aonwL10n;
      expect(find.text(l10n.objectiveType('strategicPass')), findsOneWidget);
      expect(find.text(l10n.objectiveDetails(0, 0, 4, 7, 2)), findsOneWidget);
    },
  );

  testWidgets('loading and failure remain dismissible and retryable', (
    tester,
  ) async {
    var closes = 0;
    var retries = 0;
    Future<void> show(HexInspectionState state) async {
      await tester.pumpWidget(
        LocalizedTestApp(
          home: Scaffold(
            body: Stack(
              children: [
                HexInspectionOverlay(
                  state: state,
                  scene: testMapScene(),
                  anchor: null,
                  onClose: () => closes++,
                  onRetry: () => retries++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await show(const HexInspectionLoading((col: 0, row: 0)));
    await tester.tap(find.byKey(const ValueKey('close-hex-inspection')));
    expect(closes, 1);
    await show(
      const HexInspectionFailure((
        col: 0,
        row: 0,
      ), HexInspectionFailureCode.requestFailed),
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('all classification and recommendation copy is translated', (
    tester,
  ) async {
    for (final locale in ['en', 'pl']) {
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: Locale(locale),
          theme: AonwTheme.dark,
          home: const Scaffold(),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = tester.element(find.byType(Scaffold)).aonwL10n;
      for (final kind in HexAssessmentKindView.values) {
        expect(l10n.hexInspectionKind(kind.name), isNotEmpty);
        expect(l10n.hexInspectionDescription(kind.name), isNotEmpty);
        if (kind != HexAssessmentKindView.mapTile) {
          expect(
            l10n.hexInspectionKind(kind.name),
            isNot(l10n.hexInspectionKind('mapTile')),
          );
        }
      }
      for (final value in HexRecommendationView.values) {
        expect(l10n.hexInspectionRecommendation(value.name), isNotEmpty);
        expect(l10n.hexInspectionRecommendationDetail(value.name), isNotEmpty);
      }
    }
  });
}

HexInspectionView _view() => HexInspectionView(
  stamp: testSessionStamp(),
  coordinate: (col: 0, row: 0),
  baseTerrain: MapTerrain.forest,
  terrainTags: [MapTerrain.forest, MapTerrain.river],
  resources: [MapResource.coal],
  height: 2,
  hasRiver: true,
  canFoundCityOnTerrain: true,
  yieldValue: const YieldValueView(food: 2, production: 3, gold: 0, defense: 1),
  score: const HexAssessmentScoreView(city: 5, defense: 5, economy: 4),
  kind: HexAssessmentKindView.forestForge,
  recommendation: HexRecommendationView.defendHere,
  tags: const [],
  improvementAccess: const HexOutsideControlledCityView(),
  improvements: [
    const HexImprovementOptionView(
      kind: FieldImprovementKind.lumberMill,
      requiredTechnology: TechnologyIdView.woodworking,
      technologyUnlocked: false,
      buildTurns: 3,
      yieldDelta: YieldValueView(food: 0, production: 1, gold: 0, defense: 0),
    ),
    const HexImprovementOptionView(
      kind: FieldImprovementKind.coalShaft,
      requiredTechnology: TechnologyIdView.coalMining,
      technologyUnlocked: true,
      buildTurns: 5,
      yieldDelta: YieldValueView(food: 0, production: 3, gold: 0, defense: 0),
    ),
  ],
);
