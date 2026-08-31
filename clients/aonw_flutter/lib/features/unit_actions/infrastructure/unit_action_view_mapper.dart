import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/read_model/map_view.dart';
import '../read_model/unit_action_view.dart';

final class UnitActionViewMapper {
  const UnitActionViewMapper();

  UnitActionRejectionCodeView? validateCommand(
    AonwCommandResult command, {
    required MapView map,
    required int expectedRevision,
    required int currentRevision,
  }) {
    final nextRevision = command.accepted
        ? expectedRevision + 1
        : currentRevision;
    _validateStamp(command.stamp, map: map, expectedRevision: nextRevision);
    if (command.events.isNotEmpty || command.evidence != null) {
      throw const FormatException(
        'Unit action returned unsupported execution details.',
      );
    }
    final rejection = command.rejection;
    if (command.accepted) {
      if (rejection != null) {
        throw const FormatException('Accepted unit action has a rejection.');
      }
      return null;
    }
    if (rejection == null) {
      throw const FormatException(
        'Rejected unit action has no rejection code.',
      );
    }
    return _rejectionCode(rejection);
  }

  static UnitActionRejectionCodeView _rejectionCode(
    AonwCommandRejectionCode value,
  ) => switch (value) {
    AonwCommandRejectionCode.staleRevision =>
      UnitActionRejectionCodeView.staleRevision,
    AonwCommandRejectionCode.matchFinished =>
      UnitActionRejectionCodeView.matchFinished,
    AonwCommandRejectionCode.unitNotFound =>
      UnitActionRejectionCodeView.unitNotFound,
    AonwCommandRejectionCode.unitNotControlled =>
      UnitActionRejectionCodeView.unitNotControlled,
    AonwCommandRejectionCode.unitBusy => UnitActionRejectionCodeView.unitBusy,
    AonwCommandRejectionCode.unitDefinitionMissing =>
      UnitActionRejectionCodeView.unitDefinitionMissing,
    AonwCommandRejectionCode.stateRevisionOverflow =>
      UnitActionRejectionCodeView.stateRevisionOverflow,
    _ => throw const FormatException(
      'Unit action returned an unrelated rejection code.',
    ),
  };

  static void _validateStamp(
    AonwSessionStamp value, {
    required MapView map,
    required int expectedRevision,
  }) {
    final digest = RegExp(r'^[0-9a-f]{64}$');
    if (!digest.hasMatch(value.stateDigest) ||
        !digest.hasMatch(value.mapHash) ||
        !digest.hasMatch(value.rulesetHash) ||
        value.mapHash != map.contentHash ||
        value.revision != expectedRevision) {
      throw const FormatException('Unit action session identity is stale.');
    }
  }
}
