import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/infrastructure/player_map_view_mapper.dart';
import '../../map/infrastructure/rust_game_session_context.dart';
import '../../map/read_model/player_map_view.dart';
import '../application/unit_action_session_port.dart';
import '../read_model/unit_action_view.dart';
import 'unit_action_view_mapper.dart';

typedef PlayerViewRetainer = void Function(PlayerMapView player);

final class RustUnitActionGateway {
  const RustUnitActionGateway({
    required PlayerMapViewMapper playerMapper,
    required UnitActionViewMapper mapper,
  }) : _playerMapper = playerMapper,
       _mapper = mapper;

  final PlayerMapViewMapper _playerMapper;
  final UnitActionViewMapper _mapper;

  Future<UnitActionResultView> execute({
    required RustGameSessionContext context,
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
    required PlayerViewRetainer retainPlayer,
  }) async {
    try {
      requireControlledUnit(context, unitId);
      final response = await _send(
        context.session,
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
    RustGameSessionContext context,
    AonwCommandResult command, {
    required PlayerViewRetainer retainPlayer,
  }) async {
    try {
      final snapshot = context.cache.apply(command);
      return _mapPlayer(context, snapshot, retainPlayer);
    } on FormatException catch (error, stackTrace) {
      final resyncedPlayer = await _resync(context, retainPlayer: retainPlayer);
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
    RustGameSessionContext context, {
    required PlayerViewRetainer retainPlayer,
  }) async {
    final response = await _send(context.session, AonwClientRequest.snapshot());
    final snapshot = response.require<AonwSnapshotResponse>().snapshot;
    context.cache.replaceAfterResync(snapshot);
    return _mapPlayer(context, snapshot, retainPlayer);
  }

  PlayerMapView _mapPlayer(
    RustGameSessionContext context,
    AonwPlayerViewSnapshot snapshot,
    PlayerViewRetainer retainPlayer,
  ) {
    final player = _playerMapper.fromWire(
      snapshot,
      map: context.map,
      actorPlayerId: context.actorPlayerId,
    );
    retainPlayer(player);
    return player;
  }

  static Future<AonwClientResponse> _send(
    AonwRustSession session,
    AonwClientRequest request,
  ) async {
    final response = await session.send(request);
    if (!response.isSuccess) {
      final error = response.error!;
      throw UnitActionSessionException(
        code: error.code,
        message: 'The unit action request could not be completed.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    return response;
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
