part of 'protocol.dart';

/// Diplomacy-specific request constructors for the strict client protocol.
abstract final class AonwDiplomacyRequest {
  static AonwClientRequest declareWar({
    required int expectedRevision,
    required String targetPlayerId,
  }) => _command('declareWar', expectedRevision, {
    'targetPlayerId': targetPlayerId,
  });

  static AonwClientRequest sendGoldGift({
    required int expectedRevision,
    required String targetPlayerId,
    required int amount,
  }) => _command('sendGoldGift', expectedRevision, {
    'targetPlayerId': targetPlayerId,
    'amount': amount,
  });

  static AonwClientRequest openResourceTrade({
    required int expectedRevision,
    required String targetPlayerId,
    required AonwResourceType resource,
    required int goldPerTurn,
    required int durationTurns,
    String? agreementId,
  }) => _command('openResourceTrade', expectedRevision, {
    'targetPlayerId': targetPlayerId,
    'resource': resource.name,
    'goldPerTurn': goldPerTurn,
    'durationTurns': durationTurns,
    'agreementId': agreementId,
  });

  static AonwClientRequest openResourceExchange({
    required int expectedRevision,
    required String targetPlayerId,
    required AonwResourceType offeredResource,
    required AonwResourceType requestedResource,
    required int durationTurns,
    String? agreementId,
  }) => _command('openResourceExchange', expectedRevision, {
    'targetPlayerId': targetPlayerId,
    'offeredResource': offeredResource.name,
    'requestedResource': requestedResource.name,
    'durationTurns': durationTurns,
    'agreementId': agreementId,
  });

  static AonwClientRequest sendProposal({
    required int expectedRevision,
    required String targetPlayerId,
    required AonwDiplomaticProposalKind kind,
    required int goldPayment,
    String? proposalId,
  }) => _command('sendDiplomaticProposal', expectedRevision, {
    'targetPlayerId': targetPlayerId,
    'kind': kind.name,
    'proposalId': proposalId,
    'goldPayment': goldPayment,
  });

  static AonwClientRequest respondProposal({
    required int expectedRevision,
    required String proposalId,
    required bool accepted,
  }) => _command('respondDiplomaticProposal', expectedRevision, {
    'proposalId': proposalId,
    'accepted': accepted,
  });

  static AonwClientRequest sendMessage({
    required int expectedRevision,
    required String targetPlayerId,
    required AonwDiplomaticMessageTopic topic,
    String? messageId,
  }) => _command('sendDiplomaticMessage', expectedRevision, {
    'targetPlayerId': targetPlayerId,
    'topic': topic.name,
    'messageId': messageId,
  });

  static AonwClientRequest respondMessage({
    required int expectedRevision,
    required String messageId,
    required AonwDiplomaticMessageResponse response,
  }) => _command('respondDiplomaticMessage', expectedRevision, {
    'messageId': messageId,
    'response': response.name,
  });

  static AonwClientRequest _command(
    String type,
    int expectedRevision,
    Map<String, Object?> fields,
  ) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {'type': type, 'expectedRevision': expectedRevision, ...fields},
  });
}
