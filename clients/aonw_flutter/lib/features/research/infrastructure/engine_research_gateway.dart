import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../application/research_session_port.dart';
import '../read_model/research_view.dart';
import 'research_view_mapper.dart';

final class EngineResearchGateway {
  const EngineResearchGateway({
    ResearchViewMapper mapper = const ResearchViewMapper(),
  }) : _mapper = mapper;

  final ResearchViewMapper _mapper;

  Future<ResearchOptionsView> options({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      final response = await send(
        context,
        AonwResearchRequest.options(expectedRevision: expectedRevision),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwResearchOptionsResult) {
        throw const FormatException('Expected research options response.');
      }
      return _mapper.options(
        result,
        map: context.map,
        player: context.player,
        expectedRevision: expectedRevision,
      );
    } on ResearchSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  Future<ResearchCommandResultView> select({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required TechnologyIdView technology,
    required EngineRequestSender send,
    required EnginePatchApplier applyPatch,
  }) async {
    try {
      final context = readContext();
      final response = await send(
        context,
        AonwResearchRequest.select(
          expectedRevision: expectedRevision,
          technology: AonwTechnologyId.values.byName(technology.name),
        ),
      );
      final command = response.require<AonwCommandResponse>().result;
      final rejection = _mapper.command(
        command,
        map: context.map,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await applyPatch(context, command);
      return rejection == null
          ? ResearchCommandResultView.accepted(player: player)
          : ResearchCommandResultView.rejected(rejectionCode: rejection);
    } on ResearchSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }
}

ResearchSessionException _transportFailure(
  EngineSessionTransportException error,
) => ResearchSessionException(
  code: error.code,
  message: 'The research request could not be completed.',
  diagnosticCause: error.diagnosticCause,
  diagnosticStackTrace: error.diagnosticStackTrace,
  resyncedPlayer: error.resyncedPlayer,
);

ResearchSessionException _protocolFailure(
  FormatException error,
  StackTrace stackTrace,
) => ResearchSessionException(
  code: 'invalid_session_protocol',
  message: 'The research response is incompatible with this client.',
  diagnosticCause: error,
  diagnosticStackTrace: stackTrace,
);
