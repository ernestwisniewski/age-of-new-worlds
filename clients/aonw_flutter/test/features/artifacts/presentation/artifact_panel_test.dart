import 'package:aonw_flutter/features/artifacts/application/artifact_state.dart';
import 'package:aonw_flutter/features/artifacts/presentation/artifact_panel.dart';
import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets('shows exact excavation state and dispatches its unit', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    ArtifactActionView? dispatched;
    final unit = testVisibleUnit();
    const artifact = WorldArtifactView(
      id: 'artifact-crown',
      kind: WorldArtifactKindView.ancientImperialCrown,
      location: MapArtifactLocationView((col: 0, row: 0)),
    );
    final player = testMapScene(
      units: [unit],
      artifacts: const [artifact],
    ).player;

    await tester.pumpWidget(
      _app(
        ArtifactPanel(
          state: const ArtifactState(),
          player: player,
          coordinate: unit.coordinate,
          unit: unit,
          city: null,
          onAction: (action) => dispatched = action,
        ),
      ),
    );

    expect(
      find.textContaining('Ancient Imperial Crown · On map at 0, 0'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('start-artifact-excavation')));
    expect(dispatched, isA<StartArtifactExcavationActionView>());
    expect((dispatched! as StartArtifactExcavationActionView).unitId, unit.id);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('stores and trades only exact projected artifacts', (
    tester,
  ) async {
    final city = testCityView(center: (col: 0, row: 0));
    final unit = testVisibleUnit(carriedArtifactId: 'artifact-carried');
    const carried = WorldArtifactView(
      id: 'artifact-carried',
      kind: WorldArtifactKindView.heroSword,
      location: CarriedArtifactLocationView('preview-commander'),
    );
    const stored = WorldArtifactView(
      id: 'artifact-stored',
      kind: WorldArtifactKindView.merchantsSeal,
      location: StoredArtifactLocationView('preview-city'),
    );
    final player = testMapScene(
      units: [unit],
      cities: [city],
      artifacts: const [carried, stored],
      diplomaticCounterpartPlayerIds: const ['player-two'],
    ).player;
    final dispatched = <ArtifactActionView>[];

    await tester.pumpWidget(
      _app(
        ArtifactPanel(
          state: const ArtifactState(),
          player: player,
          coordinate: city.center,
          unit: unit,
          city: city,
          onAction: dispatched.add,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('store-artifact-in-city')));
    final gold = find.byKey(
      const ValueKey(('artifact-trade-gold', 'artifact-stored')),
    );
    await tester.enterText(gold, '7');
    await tester.tap(
      find.byKey(const ValueKey(('trade-artifact', 'artifact-stored'))),
    );

    expect(dispatched.first, isA<StoreArtifactInCityActionView>());
    expect((dispatched.first as StoreArtifactInCityActionView).cityId, city.id);
    final trade = dispatched.last as TradeArtifactActionView;
    expect(trade.targetPlayerId, 'player-two');
    expect(trade.offeredArtifactId, 'artifact-stored');
    expect(trade.offeredGold, 7);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child) => LocalizedTestApp(
  home: Scaffold(
    body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
      child: SingleChildScrollView(child: child),
    ),
  ),
);
