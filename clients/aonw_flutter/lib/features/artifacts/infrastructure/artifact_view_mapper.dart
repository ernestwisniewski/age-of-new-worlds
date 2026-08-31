import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/read_model/map_view.dart';
import '../read_model/artifact_view.dart';

final class ArtifactViewMapper {
  const ArtifactViewMapper();

  ArtifactRejectionCodeView? command(
    AonwCommandResult wire, {
    required MapView map,
    required ArtifactActionView action,
    required int expectedRevision,
    required int currentRevision,
  }) {
    _validateStamp(
      wire.stamp,
      map: map,
      revision: wire.accepted ? expectedRevision + 1 : currentRevision,
    );
    if (wire.accepted) {
      final expectedEvent = switch (action) {
        StartArtifactExcavationActionView() =>
          AonwClientEventKind.artifactExcavationStarted,
        StoreArtifactInCityActionView() ||
        TradeArtifactActionView() => AonwClientEventKind.artifactStored,
      };
      if (wire.rejection != null ||
          wire.evidence != null ||
          wire.events.length != 1 ||
          wire.events.single.kind != expectedEvent) {
        throw const FormatException('Accepted artifact result is malformed.');
      }
      return null;
    }
    if (wire.rejection == null ||
        wire.events.isNotEmpty ||
        wire.evidence != null) {
      throw const FormatException('Rejected artifact result has residue.');
    }
    final rejection = _rejections[wire.rejection];
    if (rejection == null) {
      throw const FormatException('Unrelated artifact rejection code.');
    }
    return rejection;
  }
}

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
    throw const FormatException('Artifact session identity is stale.');
  }
}

const _rejections = <AonwCommandRejectionCode, ArtifactRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision:
      ArtifactRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.matchFinished:
      ArtifactRejectionCodeView.matchFinished,
  AonwCommandRejectionCode.unitNotFound: ArtifactRejectionCodeView.unitNotFound,
  AonwCommandRejectionCode.unitNotControlled:
      ArtifactRejectionCodeView.unitNotControlled,
  AonwCommandRejectionCode.unitUnavailable:
      ArtifactRejectionCodeView.unitUnavailable,
  AonwCommandRejectionCode.unitAlreadyCarryingArtifact:
      ArtifactRejectionCodeView.unitAlreadyCarryingArtifact,
  AonwCommandRejectionCode.artifactNotFound:
      ArtifactRejectionCodeView.artifactNotFound,
  AonwCommandRejectionCode.unitNotCarryingArtifact:
      ArtifactRejectionCodeView.unitNotCarryingArtifact,
  AonwCommandRejectionCode.cityNotFound: ArtifactRejectionCodeView.cityNotFound,
  AonwCommandRejectionCode.cityNotControlled:
      ArtifactRejectionCodeView.cityNotControlled,
  AonwCommandRejectionCode.unitNotInCity:
      ArtifactRejectionCodeView.unitNotInCity,
  AonwCommandRejectionCode.cityArtifactSlotFull:
      ArtifactRejectionCodeView.cityArtifactSlotFull,
  AonwCommandRejectionCode.artifactTradeActorUnavailable:
      ArtifactRejectionCodeView.artifactTradeActorUnavailable,
  AonwCommandRejectionCode.artifactTradeTargetInvalid:
      ArtifactRejectionCodeView.artifactTradeTargetInvalid,
  AonwCommandRejectionCode.artifactTradeGoldInvalid:
      ArtifactRejectionCodeView.artifactTradeGoldInvalid,
  AonwCommandRejectionCode.artifactTradeBlockedByWar:
      ArtifactRejectionCodeView.artifactTradeBlockedByWar,
  AonwCommandRejectionCode.artifactTradeGoldUnavailable:
      ArtifactRejectionCodeView.artifactTradeGoldUnavailable,
  AonwCommandRejectionCode.offeredArtifactUnavailable:
      ArtifactRejectionCodeView.offeredArtifactUnavailable,
  AonwCommandRejectionCode.targetArtifactSlotUnavailable:
      ArtifactRejectionCodeView.targetArtifactSlotUnavailable,
  AonwCommandRejectionCode.stateRevisionOverflow:
      ArtifactRejectionCodeView.stateRevisionOverflow,
};
