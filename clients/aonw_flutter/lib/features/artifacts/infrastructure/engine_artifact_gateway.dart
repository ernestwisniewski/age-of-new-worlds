import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../application/artifact_session_port.dart';
import '../read_model/artifact_view.dart';
import 'artifact_view_mapper.dart';

final class EngineArtifactGateway {
  const EngineArtifactGateway({
    ArtifactViewMapper mapper = const ArtifactViewMapper(),
  }) : _mapper = mapper;

  final ArtifactViewMapper _mapper;

  Future<ArtifactCommandResultView> execute({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required ArtifactActionView action,
    required EngineRequestSender send,
    required EnginePatchApplier applyPatch,
  }) async {
    try {
      final context = readContext();
      final response = await send(context, _request(action, expectedRevision));
      final command = response.require<AonwCommandResponse>().result;
      final rejection = _mapper.command(
        command,
        map: context.map,
        action: action,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await applyPatch(context, command);
      return rejection == null
          ? ArtifactCommandResultView.accepted(player: player)
          : ArtifactCommandResultView.rejected(rejectionCode: rejection);
    } on ArtifactSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw ArtifactSessionException(
        code: error.code,
        message: 'The artifact request could not be completed.',
        diagnosticCause: error.diagnosticCause,
        diagnosticStackTrace: error.diagnosticStackTrace,
        resyncedPlayer: error.resyncedPlayer,
      );
    } on FormatException catch (error, stackTrace) {
      throw ArtifactSessionException(
        code: 'invalid_session_protocol',
        message: 'The artifact response is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }
}

AonwClientRequest _request(ArtifactActionView action, int expectedRevision) =>
    switch (action) {
      StartArtifactExcavationActionView(:final unitId) =>
        AonwArtifactRequest.startExcavation(
          expectedRevision: expectedRevision,
          unitId: unitId,
        ),
      StoreArtifactInCityActionView(:final unitId, :final cityId) =>
        AonwArtifactRequest.storeInCity(
          expectedRevision: expectedRevision,
          unitId: unitId,
          cityId: cityId,
        ),
      TradeArtifactActionView(
        :final targetPlayerId,
        :final offeredArtifactId,
        :final offeredGold,
      ) =>
        AonwArtifactRequest.trade(
          expectedRevision: expectedRevision,
          targetPlayerId: targetPlayerId,
          offeredArtifactId: offeredArtifactId,
          offeredGold: offeredGold,
        ),
    };
