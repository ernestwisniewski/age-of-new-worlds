import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/read_model/map_view.dart';
import '../read_model/diplomacy_view.dart';

final class DiplomacyViewMapper {
  const DiplomacyViewMapper();

  DiplomacyView fromWire(
    AonwPlayerDiplomacyView wire, {
    required String actorPlayerId,
  }) {
    if (actorPlayerId.isEmpty) {
      throw const FormatException('Diplomacy actor is empty.');
    }
    final relations = <DiplomaticRelationView>[];
    final counterparts = <String>{};
    String? previousRelation;
    for (final value in wire.relations) {
      final id = value.counterpartPlayerId;
      if (id.isEmpty ||
          id == actorPlayerId ||
          (previousRelation != null && previousRelation.compareTo(id) >= 0) ||
          (value.lastChangedTurn == null) != (value.lastChangeReason == null)) {
        throw const FormatException('Diplomatic relation is malformed.');
      }
      previousRelation = id;
      counterparts.add(id);
      relations.add(
        DiplomaticRelationView(
          counterpartPlayerId: id,
          status: DiplomaticRelationStatusView.values.byName(value.status.name),
          relationScore: value.relationScore,
          statusExpiresOnTurn: value.statusExpiresOnTurn,
          lastChangedTurn: value.lastChangedTurn,
          lastChangeReason: value.lastChangeReason == null
              ? null
              : DiplomaticRelationChangeReasonView.values.byName(
                  value.lastChangeReason!.name,
                ),
        ),
      );
    }
    return DiplomacyView(
      relations: relations,
      proposals: _ordered(
        wire.proposals,
        id: (value) => value.id,
        map: (value) => _proposal(value, actorPlayerId, counterparts),
      ),
      messages: _ordered(
        wire.messages,
        id: (value) => value.id,
        map: (value) => _message(value, actorPlayerId, counterparts),
      ),
      resourceTradeAgreements: _ordered(
        wire.resourceTradeAgreements,
        id: (value) => value.id,
        map: (value) => _agreement(value, actorPlayerId, counterparts),
      ),
    );
  }
}

DiplomaticProposalView _proposal(
  AonwPlayerDiplomaticProposalView value,
  String actor,
  Set<String> counterparts,
) {
  _validateParticipants(
    value.fromPlayerId,
    value.toPlayerId,
    actor,
    counterparts,
  );
  if (value.expiresOnTurn <= value.createdTurn || value.goldPayment < 0) {
    throw const FormatException('Diplomatic proposal is malformed.');
  }
  return DiplomaticProposalView(
    id: value.id,
    fromPlayerId: value.fromPlayerId,
    toPlayerId: value.toPlayerId,
    kind: DiplomaticProposalKindView.values.byName(value.kind.name),
    createdTurn: value.createdTurn,
    expiresOnTurn: value.expiresOnTurn,
    goldPayment: value.goldPayment,
  );
}

DiplomaticMessageView _message(
  AonwPlayerDiplomaticMessageView value,
  String actor,
  Set<String> counterparts,
) {
  _validateParticipants(
    value.fromPlayerId,
    value.toPlayerId,
    actor,
    counterparts,
  );
  final answered = value.response != null;
  if (value.expiresOnTurn <= value.createdTurn ||
      answered != (value.respondedTurn != null) ||
      answered != (value.relationScoreAfter != null) ||
      (!answered && value.relationScoreDelta != 0) ||
      (value.promiseBroken && value.promiseDueTurn == null)) {
    throw const FormatException('Diplomatic message is malformed.');
  }
  return DiplomaticMessageView(
    id: value.id,
    fromPlayerId: value.fromPlayerId,
    toPlayerId: value.toPlayerId,
    topic: DiplomaticMessageTopicView.values.byName(value.topic.name),
    category: DiplomaticMessageCategoryView.values.byName(value.category.name),
    createdTurn: value.createdTurn,
    expiresOnTurn: value.expiresOnTurn,
    response: value.response == null
        ? null
        : DiplomaticMessageResponseView.values.byName(value.response!.name),
    respondedTurn: value.respondedTurn,
    relationScoreDelta: value.relationScoreDelta,
    relationScoreAfter: value.relationScoreAfter,
    promiseDueTurn: value.promiseDueTurn,
    promiseBroken: value.promiseBroken,
  );
}

ResourceTradeAgreementView _agreement(
  AonwPlayerResourceTradeAgreementView value,
  String actor,
  Set<String> counterparts,
) {
  _validateParticipants(
    value.exporterPlayerId,
    value.importerPlayerId,
    actor,
    counterparts,
  );
  if (value.goldPerTurn < 0 ||
      value.remainingTurns < 1 ||
      value.amountPerTurn < 1 ||
      value.exchangeGroupId == '') {
    throw const FormatException('Resource trade agreement is malformed.');
  }
  return ResourceTradeAgreementView(
    id: value.id,
    exporterPlayerId: value.exporterPlayerId,
    importerPlayerId: value.importerPlayerId,
    resource: MapResource.values.byName(value.resource.name),
    goldPerTurn: value.goldPerTurn,
    remainingTurns: value.remainingTurns,
    amountPerTurn: value.amountPerTurn,
    exchangeGroupId: value.exchangeGroupId,
  );
}

void _validateParticipants(
  String first,
  String second,
  String actor,
  Set<String> counterparts,
) {
  if (first.isEmpty ||
      second.isEmpty ||
      first == second ||
      (first != actor && second != actor)) {
    throw const FormatException('Private diplomacy record escaped recipient.');
  }
  final counterpart = first == actor ? second : first;
  if (!counterparts.contains(counterpart)) {
    throw const FormatException(
      'Diplomacy record references an unknown contact.',
    );
  }
}

List<R> _ordered<T, R>(
  List<T> values, {
  required String Function(T value) id,
  required R Function(T value) map,
}) {
  final result = <R>[];
  String? previous;
  for (final value in values) {
    final current = id(value);
    if (current.isEmpty ||
        (previous != null && previous.compareTo(current) >= 0)) {
      throw const FormatException('Diplomacy identifiers are not ordered.');
    }
    previous = current;
    result.add(map(value));
  }
  return result;
}
