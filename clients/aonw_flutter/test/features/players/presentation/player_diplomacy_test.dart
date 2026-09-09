import 'package:aonw_flutter/features/diplomacy/application/diplomacy_state.dart';
import 'package:aonw_flutter/features/diplomacy/presentation/diplomacy_overlay.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/players/presentation/player_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import 'player_test_fixture.dart';

void main() {
  testWidgets('only a disclosed foreign contact can open diplomacy', (
    tester,
  ) async {
    String? target;
    Widget screen(String selected) => LocalizedTestApp(
      home: Scaffold(
        body: PlayerOverlay(
          player: playersFixture(),
          selectedId: selected,
          onSelect: (_) {},
          onClose: () {},
          onDiplomacy: (value) => target = value,
        ),
      ),
    );
    await tester.pumpWidget(screen('one'));
    expect(find.byKey(const ValueKey('player-open-diplomacy')), findsNothing);
    await tester.pumpWidget(screen('three'));
    expect(find.byKey(const ValueKey('player-open-diplomacy')), findsNothing);
    await tester.pumpWidget(screen('two'));
    await tester.tap(find.byKey(const ValueKey('player-open-diplomacy')));
    expect(target, 'two');
  });

  for (final target in ['two', 'three', 'undisclosed']) {
    testWidgets('diplomacy selects only a known requested target: $target', (
      tester,
    ) async {
      final actions = <DiplomacyActionView>[];
      await tester.pumpWidget(
        LocalizedTestApp(
          home: Scaffold(
            body: DiplomacyPanel(
              actorPlayerId: 'one',
              initialTargetPlayerId: target,
              view: _contacts(),
              state: const DiplomacyState(),
              onAction: actions.add,
            ),
          ),
        ),
      );
      expect(actions, isEmpty);
      final submit = find.byKey(const ValueKey('submit-diplomacy-action'));
      if (target == 'undisclosed') {
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      } else {
        await tester.tap(submit);
        expect((actions.single as DeclareWarActionView).targetPlayerId, target);
      }
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('diplomacy overlay fits $size with large German text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: const Locale('de'),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: DiplomacyOverlay(
                actorPlayerId: 'one',
                view: _contacts(),
                state: const DiplomacyState(),
                open: true,
                onOpenChanged: (_) {},
                onAction: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final panel = tester.getRect(find.byType(DiplomacyPanel));
      expect(panel.right, lessThanOrEqualTo(size.width));
      expect(panel.left, greaterThanOrEqualTo(0));
    });
  }
}

DiplomacyView _contacts() => DiplomacyView(
  relations: [
    playersFixture().diplomacy.relations.single,
    const DiplomaticRelationView(
      counterpartPlayerId: 'three',
      status: DiplomaticRelationStatusView.neutral,
      relationScore: 0,
      statusExpiresOnTurn: null,
      lastChangedTurn: null,
      lastChangeReason: null,
    ),
  ],
  proposals: const [],
  messages: const [],
  resourceTradeAgreements: const [],
);
