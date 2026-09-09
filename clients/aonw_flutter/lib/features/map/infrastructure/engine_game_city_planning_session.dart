part of 'engine_game_session_gateway.dart';

final class _EngineGameCityPlanningSession implements CityPlanningSessionPort {
  const _EngineGameCityPlanningSession(this._owner);
  final EngineGameSessionGateway _owner;

  @override
  Future<CityPlanningView> cityPlanning({required int expectedRevision}) =>
      _owner._serialize(
        () => const EngineCityPlanningGateway().query(
          readContext: _owner._context,
          expectedRevision: expectedRevision,
          send: _owner._send,
        ),
      );
}
