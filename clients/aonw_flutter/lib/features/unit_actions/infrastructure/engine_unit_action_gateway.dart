import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../../map/infrastructure/player_map_view_mapper.dart';
import '../../map/read_model/player_map_view.dart';
import '../application/unit_action_session_port.dart';
import '../read_model/unit_action_view.dart';
import 'unit_action_view_mapper.dart';

typedef EngineSessionGuard = void Function(EngineGameSessionContext context);
typedef PlayerViewRetainer =
    void Function(EngineGameSessionContext context, PlayerMapView player);

final class EngineUnitActionGateway {
  const EngineUnitActionGateway({
    required PlayerMapViewMapper playerMapper,
    required UnitActionViewMapper mapper,
  }) : _playerMapper = playerMapper,
       _mapper = mapper;

  final PlayerMapViewMapper _playerMapper;
  final UnitActionViewMapper _mapper;

  Future<UnitActionResultView> execute({
    required EngineGameSessionContext context,
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
    required EngineRequestSender send,
    required EngineSessionGuard ensureCurrent,
    required PlayerViewRetainer retainPlayer,
  }) async {
    try {
      requireControlledUnit(context, unitId);
      final response = await send(
        context,
        _request(action, expectedRevision: expectedRevision, unitId: unitId),
      );
      final command = response.require<AonwCommandResponse>().result;
      final rejection = _mapper.validateCommand(
        command,
        map: context.map,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await _applyPatch(
        context,
        command,
        send: send,
        ensureCurrent: ensureCurrent,
        retainPlayer: retainPlayer,
      );
      return rejection == null
          ? UnitActionResultView.accepted(
              action: action,
              unitId: unitId,
              player: player,
            )
          : UnitActionResultView.rejected(
              action: action,
              unitId: unitId,
              code: rejection,
            );
    } on UnitActionSessionException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw UnitActionSessionException(
        code: 'invalid_session_protocol',
        message: 'The unit action response is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  Future<PlayerMapView> _applyPatch(
    EngineGameSessionContext context,
    AonwCommandResult command, {
    required EngineRequestSender send,
    required EngineSessionGuard ensureCurrent,
    required PlayerViewRetainer retainPlayer,
  }) async {
    ensureCurrent(context);
    try {
      final snapshot = context.cache.apply(command);
      return _mapPlayer(context, snapshot, retainPlayer);
    } on FormatException catch (error, stackTrace) {
      final resyncedPlayer = await _resync(
        context,
        send: send,
        ensureCurrent: ensureCurrent,
        retainPlayer: retainPlayer,
      );
      throw UnitActionSessionException(
        code: 'recipient_resynchronized',
        message:
            'The recipient view was resynchronized after an invalid patch.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
        resyncedPlayer: resyncedPlayer,
      );
    }
  }

  Future<PlayerMapView> _resync(
    EngineGameSessionContext context, {
    required EngineRequestSender send,
    required EngineSessionGuard ensureCurrent,
    required PlayerViewRetainer retainPlayer,
  }) async {
    ensureCurrent(context);
    final response = await send(context, AonwClientRequest.snapshot());
    ensureCurrent(context);
    final snapshot = response.require<AonwSnapshotResponse>().snapshot;
    context.cache.replaceAfterResync(snapshot);
    return _mapPlayer(context, snapshot, retainPlayer);
  }

  PlayerMapView _mapPlayer(
    EngineGameSessionContext context,
    AonwPlayerViewSnapshot snapshot,
    PlayerViewRetainer retainPlayer,
  ) {
    final player = _playerMapper.fromWire(
      snapshot,
      map: context.map,
      actorPlayerId: context.actorPlayerId,
    );
    retainPlayer(context, player);
    return player;
  }

  static AonwClientRequest _request(
    UnitActionKindView action, {
    required int expectedRevision,
    required String unitId,
  }) => switch (action) {
    UnitActionKindView.cancel => AonwClientRequest.cancelUnitAction(
      expectedRevision: expectedRevision,
      unitId: unitId,
    ),
    UnitActionKindView.skip => AonwClientRequest.skipUnitTurn(
      expectedRevision: expectedRevision,
      unitId: unitId,
    ),
    UnitActionKindView.fortify => AonwClientRequest.fortifyUnit(
      expectedRevision: expectedRevision,
      unitId: unitId,
    ),
  };
}
