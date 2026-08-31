import 'package:aonw_flutter/features/research/application/research_state.dart';
import 'package:aonw_flutter/features/research/presentation/research_overlay.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets('shows exact research data and selects only available option', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    TechnologyIdView? selected;
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        ResearchOverlay(
          state: ResearchState(requestedRevision: 0, options: _options()),
          selectionRequired: false,
          onSelect: (technology) => selected = technology,
          onRetry: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-research')));
    await tester.pump();

    expect(find.textContaining('Science per turn: 5'), findsOneWidget);
    expect(find.textContaining('Progress: 6 / 12'), findsOneWidget);
    expect(find.textContaining('Prerequisites: Hunting'), findsOneWidget);
    expect(find.textContaining('Unlocks: Building: Granary'), findsOneWidget);
    final available = find.byKey(
      const ValueKey(('select-technology', 'agriculture')),
    );
    final locked = find.byKey(
      const ValueKey(('select-technology', 'woodworking')),
    );
    expect(tester.widget<FilledButton>(available).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(locked).onPressed, isNull);

    await tester.tap(available);
    expect(selected, TechnologyIdView.agriculture);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('forces required selection open and prevents closing it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        ResearchOverlay(
          state: ResearchState(
            requestedRevision: 0,
            options: testResearchOptionsView(),
          ),
          selectionRequired: true,
          onSelect: (_) {},
          onRetry: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('research-selection-required')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('close-research')), findsNothing);
    expect(find.byKey(const ValueKey('research-options')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('virtualizes the catalog and supports keyboard selection', (
    tester,
  ) async {
    TechnologyIdView? selected;
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: ResearchPanel(
            state: ResearchState(requestedRevision: 0, options: _options()),
            onSelect: (technology) => selected = technology,
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsWidgets);
    expect(
      find.byType(Card).evaluate().length,
      lessThan(TechnologyIdView.values.length),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, TechnologyIdView.agriculture);
    expect(tester.takeException(), isNull);
  });
}

ResearchOptionsView _options() {
  final base = testResearchOptionsView();
  return ResearchOptionsView(
    stamp: base.stamp,
    playerId: base.playerId,
    activeTechnology: null,
    scienceOverflow: 3,
    scienceYield: ScienceYieldBreakdownView(
      total: 5,
      byCityId: const {'preview-city': 5},
      sources: const [
        ScienceYieldSourceView(
          cityId: 'preview-city',
          amount: 5,
          kind: ScienceYieldSourceKindView.cityScience,
        ),
      ],
    ),
    options: [
      for (final technology in TechnologyIdView.values)
        ResearchOptionView(
          technology: technology,
          availability: technology == TechnologyIdView.agriculture
              ? TechnologyAvailabilityView.available
              : TechnologyAvailabilityView.lockedByPrerequisites,
          effectiveCost: technology == TechnologyIdView.agriculture ? 12 : 20,
          progress: technology == TechnologyIdView.agriculture ? 6 : 0,
          boostDiscountBasisPoints: technology == TechnologyIdView.agriculture
              ? 2500
              : 0,
          prerequisites: technology == TechnologyIdView.agriculture
              ? const [TechnologyIdView.hunting]
              : const [],
          blockedBy: const [],
          unlocks: technology == TechnologyIdView.agriculture
              ? const [
                  TechnologyUnlockView(
                    kind: TechnologyUnlockKindView.building,
                    target: 'granary',
                  ),
                ]
              : const [],
        ),
    ],
  );
}

Widget _app(Widget child) => LocalizedTestApp(
  home: Scaffold(
    body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
      child: child,
    ),
  ),
);
