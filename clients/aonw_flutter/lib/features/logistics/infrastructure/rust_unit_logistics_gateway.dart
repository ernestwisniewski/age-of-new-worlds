import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/infrastructure/rust_game_session_context.dart';
import '../../map/infrastructure/rust_game_session_operations.dart';
import '../application/unit_logistics_session_port.dart';
import '../read_model/unit_logistics_view.dart';
import 'unit_logistics_view_mapper.dart';

final class RustUnitLogisticsGateway {
  const RustUnitLogisticsGateway({
    UnitLogisticsViewMapper mapper = const UnitLogisticsViewMapper(),
  }) : _mapper = mapper;

  final UnitLogisticsViewMapper _mapper;

  Future<UnitLogisticsOptionsView> options({
    required RustGameSessionContext context,
    required int expectedRevision,
    required String unitId,
    required RustRequestSender send,
  }) async {
    try {
      requireControlledUnit(context, unitId);
      final response = await send(
        context.session,
        AonwClientRequest.unitLogisticsOptions(
          expectedRevision: expectedRevision,
          unitId: unitId,
        ),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwUnitLogisticsOptionsResult) {
        throw const FormatException('Expected unit logistics options.');
      }
      return _mapper.options(
        result,
        map: context.map,
        unitId: unitId,
        expectedRevision: expectedRevision,
      );
    } on UnitLogisticsSessionException {
      rethrow;
    } on RustSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  Future<UnitLogisticsCommandResultView> execute({
    required RustGameSessionContext context,
    required int expectedRevision,
    required UnitLogisticsActionView action,
    required RustRequestSender send,
    required RustPatchApplier applyPatch,
  }) async {
    try {
      requireControlledUnit(context, action.unitId);
      final response = await send(
        context.session,
        _request(action, expectedRevision),
      );
      final command = response.require<AonwCommandResponse>().result;
      final mapped = _mapper.command(
        command,
        map: context.map,
        action: action,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await applyPatch(context, command);
      final rejection = mapped.rejection;
      return rejection == null
          ? UnitLogisticsCommandResultView.accepted(
              player: player,
              execution: mapped.execution!,
            )
          : UnitLogisticsCommandResultView.rejected(rejectionCode: rejection);
    } on UnitLogisticsSessionException {
      rethrow;
    } on RustSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  static AonwClientRequest _request(
    UnitLogisticsActionView action,
    int expectedRevision,
  ) => switch (action) {
    AutoExploreActionView(:final unitId) => AonwClientRequest.autoExploreUnit(
      expectedRevision: expectedRevision,
      unitId: unitId,
    ),
    AssignMerchantRouteActionView(:final unitId, :final destinationCityId) =>
      AonwClientRequest.assignMerchantTradeRoute(
        expectedRevision: expectedRevision,
        unitId: unitId,
        destinationCityId: destinationCityId,
      ),
    MoveMerchantToCityActionView(:final unitId, :final destinationCityId) =>
      AonwClientRequest.moveMerchantToCity(
        expectedRevision: expectedRevision,
        unitId: unitId,
        destinationCityId: destinationCityId,
      ),
    DetachTroopActionView(:final unitId, :final troopKind) =>
      AonwClientRequest.detachTroop(
        expectedRevision: expectedRevision,
        unitId: unitId,
        troopKind: troopKind.name,
      ),
  };
}

UnitLogisticsSessionException _transportFailure(
  RustSessionTransportException error,
) => UnitLogisticsSessionException(
  code: error.code,
  message: 'The unit logistics request could not be completed.',
  diagnosticCause: error.diagnosticCause,
  diagnosticStackTrace: error.diagnosticStackTrace,
  resyncedPlayer: error.resyncedPlayer,
);

UnitLogisticsSessionException _protocolFailure(
  FormatException error,
  StackTrace stackTrace,
) => UnitLogisticsSessionException(
  code: 'invalid_session_protocol',
  message: 'The unit logistics response is incompatible with this client.',
  diagnosticCause: error,
  diagnosticStackTrace: stackTrace,
);
