import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/application/movement_session_port.dart';
import '../../map/infrastructure/rust_game_session_context.dart';
import '../../map/infrastructure/rust_game_session_operations.dart';
import '../application/city_session_port.dart';
import '../read_model/city_view.dart';
import 'city_view_mapper.dart';

final class RustCityGateway {
  const RustCityGateway({CityViewMapper mapper = const CityViewMapper()})
    : _mapper = mapper;

  final CityViewMapper _mapper;

  Future<CityFoundingOptionsView> foundingOptions({
    required RustGameSessionContext context,
    required int expectedRevision,
    required String founderUnitId,
    required RustRequestSender send,
  }) async {
    try {
      final founder = context.player.controlledUnitById(founderUnitId);
      if (founder == null) {
        throw const FormatException('City founder is not controlled.');
      }
      final response = await send(
        context.session,
        AonwCityRequest.foundingOptions(
          expectedRevision: expectedRevision,
          founderUnitId: founderUnitId,
        ),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwCityFoundingOptionsResult) {
        throw const FormatException('Expected city founding options.');
      }
      return _mapper.founding(
        result,
        map: context.map,
        founder: founder,
        expectedRevision: expectedRevision,
      );
    } on CitySessionException {
      rethrow;
    } on MovementSessionException catch (error) {
      throw _movementFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  Future<CityInspectionView> inspect({
    required RustGameSessionContext context,
    required int expectedRevision,
    required String cityId,
    required RustRequestSender send,
  }) async {
    try {
      final city = context.player.controlledCityById(cityId);
      if (city == null) {
        throw const FormatException('City inspection is not recipient-owned.');
      }
      final worked = await _query<AonwCityWorkedHexOptionsResult>(
        context,
        AonwCityRequest.workedHexOptions(
          expectedRevision: expectedRevision,
          cityId: cityId,
        ),
        send,
      );
      final expansion = await _query<AonwCityExpansionOptionsResult>(
        context,
        AonwCityRequest.expansionOptions(
          expectedRevision: expectedRevision,
          cityId: cityId,
        ),
        send,
      );
      final cityYield = await _query<AonwCityYieldResult>(
        context,
        AonwCityRequest.cityYield(
          expectedRevision: expectedRevision,
          cityId: cityId,
        ),
        send,
      );
      return _mapper.inspection(
        worked: worked,
        expansion: expansion,
        cityYield: cityYield,
        map: context.map,
        city: city,
        expectedRevision: expectedRevision,
      );
    } on CitySessionException {
      rethrow;
    } on MovementSessionException catch (error) {
      throw _movementFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  Future<CityCommandResultView> execute({
    required RustGameSessionContext context,
    required int expectedRevision,
    required CityActionView action,
    required RustRequestSender send,
    required RustPatchApplier applyPatch,
  }) async {
    try {
      final response = await send(
        context.session,
        _request(action, expectedRevision),
      );
      final command = response.require<AonwCommandResponse>().result;
      final mapped = _mapper.command(
        command,
        map: context.map,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await applyPatch(context, command);
      return mapped.rejection == null
          ? CityCommandResultView.accepted(player: player)
          : CityCommandResultView.rejected(rejectionCode: mapped.rejection!);
    } on CitySessionException {
      rethrow;
    } on MovementSessionException catch (error) {
      throw _movementFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }
}

Future<T> _query<T extends AonwQueryResult>(
  RustGameSessionContext context,
  AonwClientRequest request,
  RustRequestSender send,
) async {
  final response = await send(context.session, request);
  final result = response.require<AonwQueryResponse>().result;
  if (result is! T) throw FormatException('Expected city query result $T.');
  return result;
}

AonwClientRequest _request(CityActionView action, int expectedRevision) =>
    switch (action) {
      FoundCityActionView(:final founderUnitId, :final controlledHexes) =>
        AonwCityRequest.found(
          expectedRevision: expectedRevision,
          founderUnitId: founderUnitId,
          controlledHexes: [
            for (final coordinate in controlledHexes)
              AonwCoordinate(col: coordinate.col, row: coordinate.row),
          ],
        ),
      ToggleWorkedHexActionView(:final cityId, :final target) =>
        AonwCityRequest.toggleWorkedHex(
          expectedRevision: expectedRevision,
          cityId: cityId,
          targetCol: target.col,
          targetRow: target.row,
        ),
      SelectCityExpansionActionView(:final cityId, :final target) =>
        AonwCityRequest.selectExpansionHex(
          expectedRevision: expectedRevision,
          cityId: cityId,
          targetCol: target.col,
          targetRow: target.row,
        ),
    };

CitySessionException _movementFailure(MovementSessionException error) =>
    CitySessionException(
      code: error.code,
      message: 'The city request could not be completed.',
      diagnosticCause: error.diagnosticCause,
      diagnosticStackTrace: error.diagnosticStackTrace,
      resyncedPlayer: error.resyncedPlayer,
    );

CitySessionException _protocolFailure(
  FormatException error,
  StackTrace stackTrace,
) => CitySessionException(
  code: 'invalid_session_protocol',
  message: 'The city response is incompatible with this client.',
  diagnosticCause: error,
  diagnosticStackTrace: stackTrace,
);
