import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../application/city_planning_session_port.dart';
import '../read_model/city_planning_view.dart';
import 'city_planning_view_mapper.dart';
import 'engine_game_session_context.dart';
import 'engine_game_session_operations.dart';
import 'engine_query_identity.dart';

final class EngineCityPlanningGateway {
  const EngineCityPlanningGateway({
    CityPlanningViewMapper mapper = const CityPlanningViewMapper(),
  }) : _mapper = mapper;
  final CityPlanningViewMapper _mapper;

  Future<CityPlanningView> query({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      final response = await send(
        context,
        AonwClientRequest.cityPlanning(expectedRevision: expectedRevision),
      );
      ensureEngineQueryContext(context, readContext());
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwCityPlanningResult) {
        throw const FormatException('Expected city planning response.');
      }
      return _mapper.fromWire(
        result,
        map: context.map,
        player: context.player,
        expectedRevision: expectedRevision,
      );
    } on EngineSessionTransportException catch (error) {
      throw CityPlanningSessionException(
        code: error.code,
        message: 'The city planning request could not be completed.',
        diagnosticCause: error.diagnosticCause,
        diagnosticStackTrace: error.diagnosticStackTrace,
        resyncedPlayer: error.resyncedPlayer,
      );
    } on FormatException catch (error, stackTrace) {
      throw CityPlanningSessionException(
        code: 'invalid_session_protocol',
        message: 'The city planning response is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }
}
