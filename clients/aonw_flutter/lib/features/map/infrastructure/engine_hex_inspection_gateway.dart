import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../application/hex_inspection_session_port.dart';
import '../read_model/hex_inspection_view.dart';
import '../read_model/map_view.dart';
import 'engine_game_session_context.dart';
import 'engine_game_session_operations.dart';
import 'hex_inspection_view_mapper.dart';

final class EngineHexInspectionGateway {
  const EngineHexInspectionGateway({
    HexInspectionViewMapper mapper = const HexInspectionViewMapper(),
  }) : _mapper = mapper;
  final HexInspectionViewMapper _mapper;

  Future<HexInspectionView> inspect({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required MapHexCoordinate coordinate,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      final response = await send(
        context,
        AonwClientRequest.inspectHex(
          expectedRevision: expectedRevision,
          coordinate: AonwCoordinate(col: coordinate.col, row: coordinate.row),
        ),
      );
      _ensureRecipient(context, readContext());
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwHexInspectionResult) {
        throw const FormatException('Expected hex inspection response.');
      }
      return _mapper.fromWire(
        result,
        map: context.map,
        player: context.player,
        expectedRevision: expectedRevision,
        coordinate: coordinate,
      );
    } on EngineSessionTransportException catch (error) {
      throw HexInspectionSessionException(
        code: error.code,
        message: 'The hex inspection request could not be completed.',
        diagnosticCause: error.diagnosticCause,
        diagnosticStackTrace: error.diagnosticStackTrace,
        resyncedPlayer: error.resyncedPlayer,
      );
    } on FormatException catch (error, stackTrace) {
      throw HexInspectionSessionException(
        code: 'invalid_session_protocol',
        message:
            'The hex inspection response is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }
}

void _ensureRecipient(
  EngineGameSessionContext before,
  EngineGameSessionContext after,
) {
  final first = before.player.stamp;
  final last = after.player.stamp;
  if (!identical(before.session, after.session) ||
      (
            before.generation,
            before.actorPlayerId,
            before.map.mapId,
            before.map.contentHash,
          ) !=
          (
            after.generation,
            after.actorPlayerId,
            after.map.mapId,
            after.map.contentHash,
          ) ||
      (first.revision, first.stateDigest, first.mapHash, first.rulesetHash) !=
          (last.revision, last.stateDigest, last.mapHash, last.rulesetHash)) {
    throw const EngineSessionTransportException(
      code: 'session_superseded',
      message: 'The inspected recipient state was replaced.',
    );
  }
}
