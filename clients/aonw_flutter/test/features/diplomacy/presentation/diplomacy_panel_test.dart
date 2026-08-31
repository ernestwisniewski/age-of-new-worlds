import 'package:aonw_flutter/features/diplomacy/application/diplomacy_state.dart';
import 'package:aonw_flutter/features/diplomacy/presentation/diplomacy_overlay.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets(
    'shows only projected private records and dispatches exact actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final actions = <DiplomacyActionView>[];
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        LocalizedTestApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
              child: DiplomacyPanel(
                actorPlayerId: 'player-1',
                view: _view(),
                state: const DiplomacyState(),
                onAction: actions.add,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('player-2'), findsWidgets);
      expect(find.textContaining('Avoid escalation'), findsOneWidget);
      expect(find.textContaining('Marble · trade-1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('submit-diplomacy-action')));
      expect(actions.single, isA<DeclareWarActionView>());

      final accept = find.byKey(
        const ValueKey(('accept-proposal', 'proposal-1')),
      );
      await tester.scrollUntilVisible(accept, 180);
      await tester.tap(accept);
      expect(actions.last, isA<RespondDiplomaticProposalActionView>());
      expect(
        (actions.last as RespondDiplomaticProposalActionView).accepted,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

DiplomacyView _view() => DiplomacyView(
  relations: const [
    DiplomaticRelationView(
      counterpartPlayerId: 'player-2',
      status: DiplomaticRelationStatusView.truce,
      relationScore: 12,
      statusExpiresOnTurn: 8,
      lastChangedTurn: 4,
      lastChangeReason: DiplomaticRelationChangeReasonView.proposalAccepted,
    ),
  ],
  proposals: const [
    DiplomaticProposalView(
      id: 'proposal-1',
      fromPlayerId: 'player-2',
      toPlayerId: 'player-1',
      kind: DiplomaticProposalKindView.truce,
      createdTurn: 4,
      expiresOnTurn: 8,
      goldPayment: 7,
    ),
  ],
  messages: const [
    DiplomaticMessageView(
      id: 'message-1',
      fromPlayerId: 'player-2',
      toPlayerId: 'player-1',
      topic: DiplomaticMessageTopicView.avoidEscalation,
      category: DiplomaticMessageCategoryView.cooperation,
      createdTurn: 4,
      expiresOnTurn: 8,
      response: null,
      respondedTurn: null,
      relationScoreDelta: 0,
      relationScoreAfter: null,
      promiseDueTurn: null,
      promiseBroken: false,
    ),
  ],
  resourceTradeAgreements: const [
    ResourceTradeAgreementView(
      id: 'trade-1',
      exporterPlayerId: 'player-2',
      importerPlayerId: 'player-1',
      resource: MapResource.marble,
      goldPerTurn: 3,
      remainingTurns: 5,
      amountPerTurn: 1,
      exchangeGroupId: null,
    ),
  ],
);
