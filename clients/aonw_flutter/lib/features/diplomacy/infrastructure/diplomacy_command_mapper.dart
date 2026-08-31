import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/read_model/map_view.dart';
import '../read_model/diplomacy_view.dart';

final class DiplomacyCommandMapper {
  const DiplomacyCommandMapper();

  DiplomacyRejectionCodeView? command(
    AonwCommandResult wire, {
    required MapView map,
    required DiplomacyActionView action,
    required int expectedRevision,
    required int currentRevision,
  }) {
    _validateStamp(
      wire.stamp,
      map: map,
      revision: wire.accepted ? expectedRevision + 1 : currentRevision,
    );
    if (wire.accepted) {
      if (wire.rejection != null || wire.evidence != null) {
        throw const FormatException('Accepted diplomacy result is malformed.');
      }
      _validateEvents(wire.events, action);
      return null;
    }
    if (wire.rejection == null ||
        wire.events.isNotEmpty ||
        wire.evidence != null) {
      throw const FormatException('Rejected diplomacy result has residue.');
    }
    final rejection = _rejections[wire.rejection];
    if (rejection == null) {
      throw const FormatException('Unrelated diplomacy rejection code.');
    }
    return rejection;
  }
}

void _validateEvents(List<AonwClientEvent> events, DiplomacyActionView action) {
  final kinds = events.map((event) => event.kind).toList(growable: false);
  final valid = switch (action) {
    OpenResourceTradeActionView() ||
    OpenResourceExchangeActionView() => kinds.isEmpty,
    SendDiplomaticProposalActionView() => _exact(kinds, const [
      AonwClientEventKind.diplomaticProposalSent,
    ]),
    SendDiplomaticMessageActionView() => _exact(kinds, const [
      AonwClientEventKind.diplomaticMessageSent,
    ]),
    RespondDiplomaticMessageActionView() => _exact(kinds, const [
      AonwClientEventKind.diplomaticMessageResponded,
      AonwClientEventKind.diplomaticScoreChanged,
    ]),
    SendGoldGiftActionView() =>
      kinds.isNotEmpty &&
          kinds.every(
            (kind) => kind == AonwClientEventKind.diplomaticScoreChanged,
          ),
    DeclareWarActionView() =>
      kinds.length >= 2 &&
          kinds.first == AonwClientEventKind.diplomaticRelationChanged &&
          kinds
              .skip(1)
              .every(
                (kind) => kind == AonwClientEventKind.diplomaticScoreChanged,
              ),
    RespondDiplomaticProposalActionView() =>
      kinds.length >= 2 &&
          kinds.length <= 3 &&
          kinds.first == AonwClientEventKind.diplomaticProposalResponded &&
          kinds
              .skip(1)
              .every(
                (kind) =>
                    kind == AonwClientEventKind.diplomaticRelationChanged ||
                    kind == AonwClientEventKind.diplomaticScoreChanged,
              ) &&
          kinds.contains(AonwClientEventKind.diplomaticScoreChanged),
  };
  if (!valid) {
    throw const FormatException('Diplomacy event sequence is malformed.');
  }
}

bool _exact(
  List<AonwClientEventKind> actual,
  List<AonwClientEventKind> value,
) =>
    actual.length == value.length &&
    List.generate(
      actual.length,
      (index) => actual[index] == value[index],
    ).every((same) => same);

void _validateStamp(
  AonwSessionStamp value, {
  required MapView map,
  required int revision,
}) {
  final digest = RegExp(r'^[0-9a-f]{64}$');
  if (value.revision != revision ||
      value.mapHash != map.contentHash ||
      !digest.hasMatch(value.stateDigest) ||
      !digest.hasMatch(value.mapHash) ||
      !digest.hasMatch(value.rulesetHash)) {
    throw const FormatException('Diplomacy session identity is stale.');
  }
}

const _rejections = <AonwCommandRejectionCode, DiplomacyRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision:
      DiplomacyRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.matchFinished:
      DiplomacyRejectionCodeView.matchFinished,
  AonwCommandRejectionCode.stateRevisionOverflow:
      DiplomacyRejectionCodeView.stateRevisionOverflow,
  AonwCommandRejectionCode.diplomacyPlayerNotControlled:
      DiplomacyRejectionCodeView.diplomacyPlayerNotControlled,
  AonwCommandRejectionCode.diplomacyTargetNotDiscovered:
      DiplomacyRejectionCodeView.diplomacyTargetNotDiscovered,
  AonwCommandRejectionCode.diplomacyProposalNotAllowed:
      DiplomacyRejectionCodeView.diplomacyProposalNotAllowed,
  AonwCommandRejectionCode.diplomacyDuplicateProposal:
      DiplomacyRejectionCodeView.diplomacyDuplicateProposal,
  AonwCommandRejectionCode.diplomacyProposalNotFound:
      DiplomacyRejectionCodeView.diplomacyProposalNotFound,
  AonwCommandRejectionCode.diplomacyProposalPaymentUnavailable:
      DiplomacyRejectionCodeView.diplomacyProposalPaymentUnavailable,
  AonwCommandRejectionCode.diplomacyMessageCooldown:
      DiplomacyRejectionCodeView.diplomacyMessageCooldown,
  AonwCommandRejectionCode.diplomacyDuplicateMessage:
      DiplomacyRejectionCodeView.diplomacyDuplicateMessage,
  AonwCommandRejectionCode.diplomacyMessageNotFound:
      DiplomacyRejectionCodeView.diplomacyMessageNotFound,
  AonwCommandRejectionCode.diplomacyMessageUnavailable:
      DiplomacyRejectionCodeView.diplomacyMessageUnavailable,
  AonwCommandRejectionCode.diplomacyTruceActive:
      DiplomacyRejectionCodeView.diplomacyTruceActive,
  AonwCommandRejectionCode.diplomacyWarAlreadyActive:
      DiplomacyRejectionCodeView.diplomacyWarAlreadyActive,
  AonwCommandRejectionCode.diplomacyInvalidGoldAmount:
      DiplomacyRejectionCodeView.diplomacyInvalidGoldAmount,
  AonwCommandRejectionCode.diplomacyGoldGiftBlockedByRelation:
      DiplomacyRejectionCodeView.diplomacyGoldGiftBlockedByRelation,
  AonwCommandRejectionCode.diplomacyGoldUnavailable:
      DiplomacyRejectionCodeView.diplomacyGoldUnavailable,
  AonwCommandRejectionCode.diplomacyGoldGiftUnavailable:
      DiplomacyRejectionCodeView.diplomacyGoldGiftUnavailable,
  AonwCommandRejectionCode.invalidResourceTradeTarget:
      DiplomacyRejectionCodeView.invalidResourceTradeTarget,
  AonwCommandRejectionCode.invalidResourceTradeResource:
      DiplomacyRejectionCodeView.invalidResourceTradeResource,
  AonwCommandRejectionCode.invalidResourceTradeTerms:
      DiplomacyRejectionCodeView.invalidResourceTradeTerms,
  AonwCommandRejectionCode.resourceTradeBlockedByWar:
      DiplomacyRejectionCodeView.resourceTradeBlockedByWar,
  AonwCommandRejectionCode.resourceTradeGoldUnavailable:
      DiplomacyRejectionCodeView.resourceTradeGoldUnavailable,
  AonwCommandRejectionCode.resourceTradeAlreadyActive:
      DiplomacyRejectionCodeView.resourceTradeAlreadyActive,
  AonwCommandRejectionCode.invalidResourceTradeAgreementId:
      DiplomacyRejectionCodeView.invalidResourceTradeAgreementId,
  AonwCommandRejectionCode.resourceTradeAgreementIdConflict:
      DiplomacyRejectionCodeView.resourceTradeAgreementIdConflict,
  AonwCommandRejectionCode.resourceTradeExportUnavailable:
      DiplomacyRejectionCodeView.resourceTradeExportUnavailable,
  AonwCommandRejectionCode.resourceTradeOfferUnavailable:
      DiplomacyRejectionCodeView.resourceTradeOfferUnavailable,
  AonwCommandRejectionCode.resourceTradeRequestUnavailable:
      DiplomacyRejectionCodeView.resourceTradeRequestUnavailable,
};
