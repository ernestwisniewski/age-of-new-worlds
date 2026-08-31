import 'package:aonw_flutter/features/logistics/application/unit_logistics_state.dart';
import 'package:aonw_flutter/features/logistics/read_model/unit_logistics_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/unit_actions/application/action_deck_state.dart';
import 'package:aonw_flutter/features/unit_actions/presentation/unit_action_deck.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('renders localized focusable actions and dispatches one intent', (
    tester,
  ) async {
    UnitActionKindView? dispatched;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: UnitActionDeck(
            state: const ActionDeckViewState(unitId: 'unit-1'),
            logistics: null,
            onAction: (action) => dispatched = action,
            onLogisticsAction: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Unit actions'), findsOneWidget);
    expect(find.text('Fortify'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Cancel action'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey(('unit-action', 'fortify'))));
    expect(dispatched, UnitActionKindView.fortify);
  });

  testWidgets('blocks actions while pending and exposes a typed failure', (
    tester,
  ) async {
    var dispatches = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: UnitActionDeck(
              state: const ActionDeckViewState(
                unitId: 'unit-1',
                inFlightAction: UnitActionKindView.skip,
                failure: UnitActionFailure.rejected(
                  UnitActionRejectionCodeView.unitBusy,
                ),
              ),
              logistics: null,
              onAction: (_) => dispatches += 1,
              onLogisticsAction: (_) {},
            ),
          ),
        ),
      ),
    );

    final fortify = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey(('unit-action', 'fortify'))),
    );
    expect(fortify.onPressed, isNull);
    expect(find.bySemanticsLabel('Executing unit action'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    expect(
      find.text('That unit is busy and cannot perform this action now.'),
      findsOneWidget,
    );
    expect(dispatches, 0);
  });

  testWidgets('renders only engine-provided logistics options at large text', (
    tester,
  ) async {
    UnitLogisticsActionView? dispatched;
    final logistics = UnitLogisticsState(
      unitId: 'unit-1',
      options: UnitLogisticsOptionsView(
        stamp: const SessionStampView(
          revision: 0,
          stateDigest:
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          mapHash:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          rulesetHash:
              'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        ),
        unitId: 'unit-1',
        autoExplore: const AutoExploreOptionView(
          target: (col: 1, row: 0),
          totalCostUnits: 8,
        ),
        merchantRouteDestinations: const [
          MerchantDestinationOptionView(cityId: 'city-2', totalCostUnits: 12),
        ],
        merchantTravelDestinations: const [],
        detachments: const [
          DetachmentOptionView(
            troopKind: LogisticsTroopKindView.warrior,
            destination: (col: 0, row: 1),
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: UnitActionDeck(
                state: const ActionDeckViewState(unitId: 'unit-1'),
                logistics: logistics,
                onAction: (_) {},
                onLogisticsAction: (action) => dispatched = action,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Logistics'), findsOneWidget);
    expect(find.textContaining('Assign trade route · city-2'), findsOneWidget);
    expect(find.textContaining('Detach troop · Warrior'), findsOneWidget);
    await tester.tap(find.textContaining('Auto explore · 8'));
    expect(dispatched, isA<AutoExploreActionView>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables unit actions while a logistics command is pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: UnitActionDeck(
            state: const ActionDeckViewState(unitId: 'unit-1'),
            logistics: const UnitLogisticsState(
              unitId: 'unit-1',
              inFlightAction: AutoExploreActionView(unitId: 'unit-1'),
            ),
            onAction: (_) {},
            onLogisticsAction: (_) {},
          ),
        ),
      ),
    );

    final fortify = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey(('unit-action', 'fortify'))),
    );
    expect(fortify.onPressed, isNull);
  });
}
