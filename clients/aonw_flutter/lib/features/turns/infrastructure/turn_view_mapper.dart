import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/read_model/map_view.dart';
import '../read_model/turn_activity_view.dart';
import '../read_model/turn_command_view.dart';

final class TurnViewMapper {
  const TurnViewMapper();

  ({List<TurnActivityView> activities, TurnKernelEvidenceView evidence})
  accepted(
    AonwCommandResult command, {
    required MapView map,
    required int expectedRevision,
  }) {
    _validateStamp(
      command.stamp,
      map: map,
      expectedRevision: expectedRevision + 1,
      allowPreviousRevision: true,
    );
    if (!command.accepted || command.rejection != null) {
      throw const FormatException('Expected an accepted turn result.');
    }
    final evidence = command.evidence;
    if (evidence is! AonwTurnKernelEvidence) {
      throw const FormatException('Accepted turn has no turn-kernel evidence.');
    }
    return (
      activities: [
        for (var index = 0; index < command.events.length; index++)
          TurnActivityView(
            identity: TurnActivityIdentityView(
              revision: command.stamp.revision,
              eventIndex: index,
            ),
            kind: TurnActivityKindView.values.byName(
              command.events[index].kind.name,
            ),
          ),
      ],
      evidence: TurnKernelEvidenceView(
        processors: evidence.processors,
        foundedCityIds: evidence.foundedCityIds,
        combatExecutionCount: evidence.combatExecutions.length,
        resetUnitIds: evidence.resetUnitIds,
        movementExecutionCount: evidence.movementExecutions.length,
        invalidatedOrderUnitIds: evidence.invalidatedOrderUnitIds,
        finishedAutoExploreUnitIds: evidence.finishedAutoExploreUnitIds,
      ),
    );
  }

  TurnRejectionCodeView rejected(
    AonwCommandResult command, {
    required MapView map,
    required int currentRevision,
  }) {
    _validateStamp(command.stamp, map: map, expectedRevision: currentRevision);
    if (command.accepted ||
        command.rejection == null ||
        command.events.isNotEmpty ||
        command.evidence != null) {
      throw const FormatException('Rejected turn has execution details.');
    }
    final rejection = _turnRejections[command.rejection!];
    if (rejection == null) {
      throw const FormatException(
        'Turn command returned an unrelated rejection code.',
      );
    }
    return rejection;
  }

  static void _validateStamp(
    AonwSessionStamp value, {
    required MapView map,
    required int expectedRevision,
    bool allowPreviousRevision = false,
  }) {
    final digest = RegExp(r'^[0-9a-f]{64}$');
    final revisionMatches =
        value.revision == expectedRevision ||
        allowPreviousRevision && value.revision == expectedRevision - 1;
    if (!digest.hasMatch(value.stateDigest) ||
        !digest.hasMatch(value.mapHash) ||
        !digest.hasMatch(value.rulesetHash) ||
        value.mapHash != map.contentHash ||
        !revisionMatches) {
      throw const FormatException('Turn session identity is stale.');
    }
  }
}

const _turnRejections = <AonwCommandRejectionCode, TurnRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision: TurnRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.matchFinished: TurnRejectionCodeView.matchFinished,
  AonwCommandRejectionCode.turnPlayerNotControlled:
      TurnRejectionCodeView.playerNotControlled,
  AonwCommandRejectionCode.turnPlayerNotActive:
      TurnRejectionCodeView.playerNotActive,
  AonwCommandRejectionCode.turnScopeInvalid: TurnRejectionCodeView.scopeInvalid,
  AonwCommandRejectionCode.turnProcessorUnsupported:
      TurnRejectionCodeView.processorUnsupported,
  AonwCommandRejectionCode.turnNumberOverflow:
      TurnRejectionCodeView.numberOverflow,
  AonwCommandRejectionCode.stateRevisionOverflow:
      TurnRejectionCodeView.stateRevisionOverflow,
};
