import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';

import '../../../support/map_test_fixture.dart';

PlayerMapView playersFixture({String actor = 'one', bool submitted = false}) {
  final source = testMapScene().player;
  return PlayerMapView(
    actorPlayerId: actor,
    stamp: source.stamp,
    turnMode: MatchTurnModeView.simultaneous,
    participants: const [
      MatchParticipantView(
        id: 'one',
        name: 'Aleksandra',
        colorValue: 0xff9b3838,
        country: MatchParticipantCountryView.poland,
        kind: MatchParticipantKindView.human,
      ),
      MatchParticipantView(
        id: 'two',
        name: 'Éléonore',
        colorValue: 0xff34639b,
        country: MatchParticipantCountryView.france,
        kind: MatchParticipantKindView.ai,
      ),
      MatchParticipantView(
        id: 'three',
        name: 'Alexandria the Great',
        colorValue: 0xff578348,
        country: MatchParticipantCountryView.greece,
        kind: MatchParticipantKindView.human,
      ),
    ],
    fog: source.fog,
    economy: source.economy,
    research: source.research,
    victory: source.victory,
    units: source.units,
    turnView: RecipientTurnView(
      number: 8,
      ownState: RecipientTurnStateView.active,
      ownSubmitted: submitted,
      requiredSubmissionCount: 3,
      submittedCount: 2,
      pendingAction: null,
      outcome: source.turnView.outcome,
    ),
    diplomacy: DiplomacyView(
      relations: const [
        DiplomaticRelationView(
          counterpartPlayerId: 'two',
          status: DiplomaticRelationStatusView.friendly,
          relationScore: 10,
          statusExpiresOnTurn: null,
          lastChangedTurn: null,
          lastChangeReason: null,
        ),
      ],
      proposals: const [],
      messages: const [],
      resourceTradeAgreements: const [],
    ),
  );
}
