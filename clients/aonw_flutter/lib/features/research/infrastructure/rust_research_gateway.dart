import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/application/movement_session_port.dart';
import '../../map/infrastructure/rust_game_session_context.dart';
import '../../map/infrastructure/rust_game_session_operations.dart';
import '../application/research_session_port.dart';
import '../read_model/research_view.dart';
import 'research_view_mapper.dart';

final class RustResearchGateway {
  const RustResearchGateway({
    ResearchViewMapper mapper = const ResearchViewMapper(),
  }) : _mapper = mapper;

  final ResearchViewMapper _mapper;

  Future<ResearchOptionsView> options({
    required RustGameSessionContext context,
    required int expectedRevision,
    required RustRequestSender send,
  }) async {
    try {
      final response = await send(
        context.session,
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
    } on MovementSessionException catch (error) {
      throw _movementFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  Future<ResearchCommandResultView> select({
    required RustGameSessionContext context,
    required int expectedRevision,
    required TechnologyIdView technology,
    required RustRequestSender send,
    required RustPatchApplier applyPatch,
  }) async {
    try {
      final response = await send(
        context.session,
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
    } on MovementSessionException catch (error) {
      throw _movementFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }
}

ResearchSessionException _movementFailure(MovementSessionException error) =>
    ResearchSessionException(
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
