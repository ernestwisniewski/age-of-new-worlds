import '../../map/read_model/map_view.dart';

enum DiplomaticRelationStatusView { friendly, neutral, hostile, truce, war }

enum DiplomaticRelationChangeReasonView {
  manual,
  unitAttack,
  cityAttack,
  declarationOfWar,
  proposalAccepted,
  truceExpired,
  messageResponse,
  promiseBroken,
}

enum DiplomaticProposalKindView { friendship, truce }

enum DiplomaticMessageCategoryView {
  warning,
  complaint,
  request,
  praise,
  threat,
  cooperation,
}

enum DiplomaticMessageTopicView {
  troopsNearCities,
  citiesTooClose,
  blockedRoutes,
  withdrawScouts,
  avoidEscalation,
  commonEnemy,
  expansionProvocation,
  peacefulPraise,
}

enum DiplomaticMessageResponseView {
  conciliatory,
  neutral,
  evasive,
  aggressive,
}

final class DiplomacyView {
  const DiplomacyView.empty()
    : relations = const [],
      proposals = const [],
      messages = const [],
      resourceTradeAgreements = const [];

  DiplomacyView({
    required List<DiplomaticRelationView> relations,
    required List<DiplomaticProposalView> proposals,
    required List<DiplomaticMessageView> messages,
    required List<ResourceTradeAgreementView> resourceTradeAgreements,
  }) : relations = List.unmodifiable(relations),
       proposals = List.unmodifiable(proposals),
       messages = List.unmodifiable(messages),
       resourceTradeAgreements = List.unmodifiable(resourceTradeAgreements);

  final List<DiplomaticRelationView> relations;
  final List<DiplomaticProposalView> proposals;
  final List<DiplomaticMessageView> messages;
  final List<ResourceTradeAgreementView> resourceTradeAgreements;

  DiplomaticRelationView? relationWith(String playerId) {
    for (final relation in relations) {
      if (relation.counterpartPlayerId == playerId) return relation;
    }
    return null;
  }
}

final class DiplomaticRelationView {
  const DiplomaticRelationView({
    required this.counterpartPlayerId,
    required this.status,
    required this.relationScore,
    required this.statusExpiresOnTurn,
    required this.lastChangedTurn,
    required this.lastChangeReason,
  });

  final String counterpartPlayerId;
  final DiplomaticRelationStatusView status;
  final int relationScore;
  final int? statusExpiresOnTurn;
  final int? lastChangedTurn;
  final DiplomaticRelationChangeReasonView? lastChangeReason;
}

final class DiplomaticProposalView {
  const DiplomaticProposalView({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.kind,
    required this.createdTurn,
    required this.expiresOnTurn,
    required this.goldPayment,
  });

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticProposalKindView kind;
  final int createdTurn;
  final int expiresOnTurn;
  final int goldPayment;
}

final class DiplomaticMessageView {
  const DiplomaticMessageView({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.topic,
    required this.category,
    required this.createdTurn,
    required this.expiresOnTurn,
    required this.response,
    required this.respondedTurn,
    required this.relationScoreDelta,
    required this.relationScoreAfter,
    required this.promiseDueTurn,
    required this.promiseBroken,
  });

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticMessageTopicView topic;
  final DiplomaticMessageCategoryView category;
  final int createdTurn;
  final int expiresOnTurn;
  final DiplomaticMessageResponseView? response;
  final int? respondedTurn;
  final int relationScoreDelta;
  final int? relationScoreAfter;
  final int? promiseDueTurn;
  final bool promiseBroken;
}

final class ResourceTradeAgreementView {
  const ResourceTradeAgreementView({
    required this.id,
    required this.exporterPlayerId,
    required this.importerPlayerId,
    required this.resource,
    required this.goldPerTurn,
    required this.remainingTurns,
    required this.amountPerTurn,
    required this.exchangeGroupId,
  });

  final String id;
  final String exporterPlayerId;
  final String importerPlayerId;
  final MapResource resource;
  final int goldPerTurn;
  final int remainingTurns;
  final int amountPerTurn;
  final String? exchangeGroupId;
}

sealed class DiplomacyActionView {
  const DiplomacyActionView();
}

final class DeclareWarActionView extends DiplomacyActionView {
  const DeclareWarActionView(this.targetPlayerId);

  final String targetPlayerId;
}

final class SendGoldGiftActionView extends DiplomacyActionView {
  const SendGoldGiftActionView({
    required this.targetPlayerId,
    required this.amount,
  });

  final String targetPlayerId;
  final int amount;
}

final class OpenResourceTradeActionView extends DiplomacyActionView {
  const OpenResourceTradeActionView({
    required this.targetPlayerId,
    required this.resource,
    required this.goldPerTurn,
    required this.durationTurns,
  });

  final String targetPlayerId;
  final MapResource resource;
  final int goldPerTurn;
  final int durationTurns;
}

final class OpenResourceExchangeActionView extends DiplomacyActionView {
  const OpenResourceExchangeActionView({
    required this.targetPlayerId,
    required this.offeredResource,
    required this.requestedResource,
    required this.durationTurns,
  });

  final String targetPlayerId;
  final MapResource offeredResource;
  final MapResource requestedResource;
  final int durationTurns;
}

final class SendDiplomaticProposalActionView extends DiplomacyActionView {
  const SendDiplomaticProposalActionView({
    required this.targetPlayerId,
    required this.kind,
    required this.goldPayment,
  });

  final String targetPlayerId;
  final DiplomaticProposalKindView kind;
  final int goldPayment;
}

final class RespondDiplomaticProposalActionView extends DiplomacyActionView {
  const RespondDiplomaticProposalActionView({
    required this.proposalId,
    required this.accepted,
  });

  final String proposalId;
  final bool accepted;
}

final class SendDiplomaticMessageActionView extends DiplomacyActionView {
  const SendDiplomaticMessageActionView({
    required this.targetPlayerId,
    required this.topic,
  });

  final String targetPlayerId;
  final DiplomaticMessageTopicView topic;
}

final class RespondDiplomaticMessageActionView extends DiplomacyActionView {
  const RespondDiplomaticMessageActionView({
    required this.messageId,
    required this.response,
  });

  final String messageId;
  final DiplomaticMessageResponseView response;
}

enum DiplomacyRejectionCodeView {
  staleRevision,
  matchFinished,
  stateRevisionOverflow,
  diplomacyPlayerNotControlled,
  diplomacyTargetNotDiscovered,
  diplomacyProposalNotAllowed,
  diplomacyDuplicateProposal,
  diplomacyProposalNotFound,
  diplomacyProposalPaymentUnavailable,
  diplomacyMessageCooldown,
  diplomacyDuplicateMessage,
  diplomacyMessageNotFound,
  diplomacyMessageUnavailable,
  diplomacyTruceActive,
  diplomacyWarAlreadyActive,
  diplomacyInvalidGoldAmount,
  diplomacyGoldGiftBlockedByRelation,
  diplomacyGoldUnavailable,
  diplomacyGoldGiftUnavailable,
  invalidResourceTradeTarget,
  invalidResourceTradeResource,
  invalidResourceTradeTerms,
  resourceTradeBlockedByWar,
  resourceTradeGoldUnavailable,
  resourceTradeAlreadyActive,
  invalidResourceTradeAgreementId,
  resourceTradeAgreementIdConflict,
  resourceTradeExportUnavailable,
  resourceTradeOfferUnavailable,
  resourceTradeRequestUnavailable,
}
