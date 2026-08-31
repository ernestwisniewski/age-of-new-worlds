import 'package:aonw_flutter/features/diplomacy/infrastructure/diplomacy_view_mapper.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DiplomacyViewMapper();

  test('maps the complete recipient-private diplomacy projection', () {
    final view = mapper.fromWire(_wire(), actorPlayerId: 'player-1');

    expect(view.relations, hasLength(2));
    expect(
      view.relationWith('player-2')?.status,
      DiplomaticRelationStatusView.truce,
    );
    expect(view.proposals.single.id, 'proposal-1');
    expect(
      view.messages.single.topic,
      DiplomaticMessageTopicView.avoidEscalation,
    );
    expect(view.messages.single.response, isNull);
    expect(view.resourceTradeAgreements.single.resource, MapResource.marble);
    expect(view.resourceTradeAgreements.single.amountPerTurn, 1);
  });

  test('rejects records outside the recipient and unordered identities', () {
    expect(
      () => mapper.fromWire(
        _wire(
          messages: const [
            AonwPlayerDiplomaticMessageView(
              id: 'message-1',
              fromPlayerId: 'player-2',
              toPlayerId: 'player-3',
              topic: AonwDiplomaticMessageTopic.avoidEscalation,
              category: AonwDiplomaticMessageCategory.cooperation,
              createdTurn: 1,
              expiresOnTurn: 3,
              response: null,
              respondedTurn: null,
              relationScoreDelta: 0,
              relationScoreAfter: null,
              promiseDueTurn: null,
              promiseBroken: false,
            ),
          ],
        ),
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(
        _wire(
          relations: const [
            AonwPlayerDiplomaticRelationView(
              counterpartPlayerId: 'player-3',
              status: AonwDiplomaticRelationStatus.neutral,
              relationScore: 0,
              statusExpiresOnTurn: null,
              lastChangedTurn: null,
              lastChangeReason: null,
            ),
            AonwPlayerDiplomaticRelationView(
              counterpartPlayerId: 'player-2',
              status: AonwDiplomaticRelationStatus.neutral,
              relationScore: 0,
              statusExpiresOnTurn: null,
              lastChangedTurn: null,
              lastChangeReason: null,
            ),
          ],
        ),
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
  });
}

AonwPlayerDiplomacyView _wire({
  List<AonwPlayerDiplomaticRelationView>? relations,
  List<AonwPlayerDiplomaticMessageView>? messages,
}) => AonwPlayerDiplomacyView(
  relations:
      relations ??
      const [
        AonwPlayerDiplomaticRelationView(
          counterpartPlayerId: 'player-2',
          status: AonwDiplomaticRelationStatus.truce,
          relationScore: 12,
          statusExpiresOnTurn: 8,
          lastChangedTurn: 4,
          lastChangeReason: AonwDiplomaticRelationChangeReason.proposalAccepted,
        ),
        AonwPlayerDiplomaticRelationView(
          counterpartPlayerId: 'player-3',
          status: AonwDiplomaticRelationStatus.neutral,
          relationScore: 0,
          statusExpiresOnTurn: null,
          lastChangedTurn: null,
          lastChangeReason: null,
        ),
      ],
  proposals: const [
    AonwPlayerDiplomaticProposalView(
      id: 'proposal-1',
      fromPlayerId: 'player-2',
      toPlayerId: 'player-1',
      kind: AonwDiplomaticProposalKind.truce,
      createdTurn: 4,
      expiresOnTurn: 8,
      goldPayment: 7,
    ),
  ],
  messages:
      messages ??
      const [
        AonwPlayerDiplomaticMessageView(
          id: 'message-1',
          fromPlayerId: 'player-2',
          toPlayerId: 'player-1',
          topic: AonwDiplomaticMessageTopic.avoidEscalation,
          category: AonwDiplomaticMessageCategory.cooperation,
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
    AonwPlayerResourceTradeAgreementView(
      id: 'trade-1',
      exporterPlayerId: 'player-2',
      importerPlayerId: 'player-1',
      resource: AonwResourceType.marble,
      goldPerTurn: 3,
      remainingTurns: 5,
      amountPerTurn: 1,
      exchangeGroupId: null,
    ),
  ],
);
