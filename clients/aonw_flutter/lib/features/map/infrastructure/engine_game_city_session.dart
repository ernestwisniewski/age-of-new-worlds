part of 'engine_game_session_gateway.dart';

final class _EngineGameCitySession implements CitySessionPort {
  const _EngineGameCitySession(this._owner);

  final EngineGameSessionGateway _owner;

  @override
  Future<CityFoundingOptionsView> cityFoundingOptions({
    required int expectedRevision,
    required String founderUnitId,
  }) => _owner._serialize(
    () => _owner._cityGateway.foundingOptions(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      founderUnitId: founderUnitId,
      send: _owner._send,
    ),
  );

  @override
  Future<CityInspectionView> inspectCity({
    required int expectedRevision,
    required String cityId,
  }) => _owner._serialize(
    () => _owner._cityGateway.inspect(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      cityId: cityId,
      send: _owner._send,
    ),
  );

  @override
  Future<CityCommandResultView> executeCityAction({
    required int expectedRevision,
    required CityActionView action,
  }) => _owner._serialize(
    () => _owner._cityGateway.execute(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      action: action,
      send: _owner._send,
      applyPatch: _owner._applyCommandPatch,
    ),
  );
}
