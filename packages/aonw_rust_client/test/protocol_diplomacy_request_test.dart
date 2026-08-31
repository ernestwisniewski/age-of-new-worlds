import 'dart:convert';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:test/test.dart';

void main() {
  test('serializes every current diplomacy command exactly', () {
    expect(
      _request(
        AonwDiplomacyRequest.declareWar(
          expectedRevision: 1,
          targetPlayerId: 'p2',
        ),
      ),
      _command('declareWar', 1, {'targetPlayerId': 'p2'}),
    );
    expect(
      _request(
        AonwDiplomacyRequest.sendGoldGift(
          expectedRevision: 2,
          targetPlayerId: 'p2',
          amount: 10,
        ),
      ),
      _command('sendGoldGift', 2, {'targetPlayerId': 'p2', 'amount': 10}),
    );
    expect(
      _request(
        AonwDiplomacyRequest.openResourceTrade(
          expectedRevision: 3,
          targetPlayerId: 'p2',
          resource: AonwResourceType.marble,
          goldPerTurn: 3,
          durationTurns: 5,
        ),
      ),
      _command('openResourceTrade', 3, {
        'targetPlayerId': 'p2',
        'resource': 'marble',
        'goldPerTurn': 3,
        'durationTurns': 5,
        'agreementId': null,
      }),
    );
    expect(
      _request(
        AonwDiplomacyRequest.openResourceExchange(
          expectedRevision: 4,
          targetPlayerId: 'p2',
          offeredResource: AonwResourceType.iron,
          requestedResource: AonwResourceType.marble,
          durationTurns: 6,
          agreementId: 'exchange-1',
        ),
      ),
      _command('openResourceExchange', 4, {
        'targetPlayerId': 'p2',
        'offeredResource': 'iron',
        'requestedResource': 'marble',
        'durationTurns': 6,
        'agreementId': 'exchange-1',
      }),
    );
    expect(
      _request(
        AonwDiplomacyRequest.sendProposal(
          expectedRevision: 5,
          targetPlayerId: 'p2',
          kind: AonwDiplomaticProposalKind.truce,
          goldPayment: 7,
        ),
      ),
      _command('sendDiplomaticProposal', 5, {
        'targetPlayerId': 'p2',
        'kind': 'truce',
        'proposalId': null,
        'goldPayment': 7,
      }),
    );
    expect(
      _request(
        AonwDiplomacyRequest.respondProposal(
          expectedRevision: 6,
          proposalId: 'proposal-1',
          accepted: true,
        ),
      ),
      _command('respondDiplomaticProposal', 6, {
        'proposalId': 'proposal-1',
        'accepted': true,
      }),
    );
    expect(
      _request(
        AonwDiplomacyRequest.sendMessage(
          expectedRevision: 7,
          targetPlayerId: 'p2',
          topic: AonwDiplomaticMessageTopic.withdrawScouts,
        ),
      ),
      _command('sendDiplomaticMessage', 7, {
        'targetPlayerId': 'p2',
        'topic': 'withdrawScouts',
        'messageId': null,
      }),
    );
    expect(
      _request(
        AonwDiplomacyRequest.respondMessage(
          expectedRevision: 8,
          messageId: 'message-1',
          response: AonwDiplomaticMessageResponse.conciliatory,
        ),
      ),
      _command('respondDiplomaticMessage', 8, {
        'messageId': 'message-1',
        'response': 'conciliatory',
      }),
    );
  });
}

Map<String, Object?> _request(AonwClientRequest request) =>
    (jsonDecode(request.toJson()) as Map<String, Object?>)['request']!
        as Map<String, Object?>;

Map<String, Object?> _command(
  String type,
  int expectedRevision,
  Map<String, Object?> fields,
) => {
  'type': 'dispatch',
  'command': {'type': type, 'expectedRevision': expectedRevision, ...fields},
};
