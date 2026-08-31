import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../../map/read_model/map_view.dart';
import '../application/combat_session_port.dart';
import '../read_model/combat_view.dart';
import 'combat_view_mapper.dart';

final class EngineCombatGateway {
  const EngineCombatGateway({
    CombatViewMapper mapper = const CombatViewMapper(),
  }) : _mapper = mapper;

  final CombatViewMapper _mapper;

  Future<CombatPreviewView> preview({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required String attackerUnitId,
    required MapHexCoordinate defender,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      requireControlledUnit(context, attackerUnitId);
      final response = await send(
        context,
        AonwClientRequest.combatPreview(
          expectedRevision: expectedRevision,
          attackerUnitId: attackerUnitId,
          defenderCol: defender.col,
          defenderRow: defender.row,
        ),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwCombatPreviewResult) {
        throw const FormatException('Expected combat preview.');
      }
      return _mapper.preview(
        result,
        map: context.map,
        attackerUnitId: attackerUnitId,
        defender: defender,
        expectedRevision: expectedRevision,
      );
    } on CombatSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  Future<CombatCommandResultView> attack({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required CombatAttackView attack,
    required EngineRequestSender send,
    required EnginePatchApplier applyPatch,
  }) async {
    try {
      final context = readContext();
      requireControlledUnit(context, attack.preview.attackerUnitId);
      final defender = attack.preview.defenderCoordinate;
      final response = await send(
        context,
        AonwClientRequest.attackHex(
          expectedRevision: expectedRevision,
          attackerUnitId: attack.preview.attackerUnitId,
          defenderCol: defender.col,
          defenderRow: defender.row,
          cityConquestAction: AonwCityConquestAction.values.byName(
            attack.cityConquestAction.name,
          ),
        ),
      );
      final command = response.require<AonwCommandResponse>().result;
      final mapped = _mapper.command(
        command,
        map: context.map,
        attack: attack,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await applyPatch(context, command);
      final rejection = mapped.rejection;
      return rejection == null
          ? CombatCommandResultView.accepted(
              player: player,
              execution: mapped.execution!,
            )
          : CombatCommandResultView.rejected(rejectionCode: rejection);
    } on CombatSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }
}

CombatSessionException _transportFailure(
  EngineSessionTransportException error,
) => CombatSessionException(
  code: error.code,
  message: 'The combat request could not be completed.',
  diagnosticCause: error.diagnosticCause,
  diagnosticStackTrace: error.diagnosticStackTrace,
  resyncedPlayer: error.resyncedPlayer,
);

CombatSessionException _protocolFailure(
  FormatException error,
  StackTrace stackTrace,
) => CombatSessionException(
  code: 'invalid_session_protocol',
  message: 'The combat response is incompatible with this client.',
  diagnosticCause: error,
  diagnosticStackTrace: stackTrace,
);
