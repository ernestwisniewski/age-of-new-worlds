import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../application/diplomacy_session_port.dart';
import '../read_model/diplomacy_view.dart';
import 'diplomacy_command_mapper.dart';

final class EngineDiplomacyGateway {
  const EngineDiplomacyGateway({
    DiplomacyCommandMapper mapper = const DiplomacyCommandMapper(),
  }) : _mapper = mapper;

  final DiplomacyCommandMapper _mapper;

  Future<DiplomacyCommandResultView> execute({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required DiplomacyActionView action,
    required EngineRequestSender send,
    required EnginePatchApplier applyPatch,
  }) async {
    try {
      final context = readContext();
      final response = await send(context, _request(expectedRevision, action));
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
          ? DiplomacyCommandResultView.accepted(player: player)
          : DiplomacyCommandResultView.rejected(rejectionCode: rejection);
    } on DiplomacySessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }
}

AonwClientRequest _request(int revision, DiplomacyActionView action) =>
    switch (action) {
      DeclareWarActionView(:final targetPlayerId) =>
        AonwDiplomacyRequest.declareWar(
          expectedRevision: revision,
          targetPlayerId: targetPlayerId,
        ),
      SendGoldGiftActionView(:final targetPlayerId, :final amount) =>
        AonwDiplomacyRequest.sendGoldGift(
          expectedRevision: revision,
          targetPlayerId: targetPlayerId,
          amount: amount,
        ),
      OpenResourceTradeActionView(
        :final targetPlayerId,
        :final resource,
        :final goldPerTurn,
        :final durationTurns,
      ) =>
        AonwDiplomacyRequest.openResourceTrade(
          expectedRevision: revision,
          targetPlayerId: targetPlayerId,
          resource: AonwResourceType.values.byName(resource.name),
          goldPerTurn: goldPerTurn,
          durationTurns: durationTurns,
        ),
      OpenResourceExchangeActionView(
        :final targetPlayerId,
        :final offeredResource,
        :final requestedResource,
        :final durationTurns,
      ) =>
        AonwDiplomacyRequest.openResourceExchange(
          expectedRevision: revision,
          targetPlayerId: targetPlayerId,
          offeredResource: AonwResourceType.values.byName(offeredResource.name),
          requestedResource: AonwResourceType.values.byName(
            requestedResource.name,
          ),
          durationTurns: durationTurns,
        ),
      SendDiplomaticProposalActionView(
        :final targetPlayerId,
        :final kind,
        :final goldPayment,
      ) =>
        AonwDiplomacyRequest.sendProposal(
          expectedRevision: revision,
          targetPlayerId: targetPlayerId,
          kind: AonwDiplomaticProposalKind.values.byName(kind.name),
          goldPayment: goldPayment,
        ),
      RespondDiplomaticProposalActionView(:final proposalId, :final accepted) =>
        AonwDiplomacyRequest.respondProposal(
          expectedRevision: revision,
          proposalId: proposalId,
          accepted: accepted,
        ),
      SendDiplomaticMessageActionView(:final targetPlayerId, :final topic) =>
        AonwDiplomacyRequest.sendMessage(
          expectedRevision: revision,
          targetPlayerId: targetPlayerId,
          topic: AonwDiplomaticMessageTopic.values.byName(topic.name),
        ),
      RespondDiplomaticMessageActionView(:final messageId, :final response) =>
        AonwDiplomacyRequest.respondMessage(
          expectedRevision: revision,
          messageId: messageId,
          response: AonwDiplomaticMessageResponse.values.byName(response.name),
        ),
    };

DiplomacySessionException _transportFailure(
  EngineSessionTransportException error,
) => DiplomacySessionException(
  code: error.code,
  message: 'The diplomacy request could not be completed.',
  diagnosticCause: error.diagnosticCause,
  diagnosticStackTrace: error.diagnosticStackTrace,
  resyncedPlayer: error.resyncedPlayer,
);

DiplomacySessionException _protocolFailure(
  FormatException error,
  StackTrace stackTrace,
) => DiplomacySessionException(
  code: 'invalid_session_protocol',
  message: 'The diplomacy response is incompatible with this client.',
  diagnosticCause: error,
  diagnosticStackTrace: stackTrace,
);
