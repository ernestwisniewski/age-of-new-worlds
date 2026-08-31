part of 'rust_game_session_gateway.dart';

final class _RustGameCitySession implements CitySessionPort {
  const _RustGameCitySession(this._owner);

  final RustGameSessionGateway _owner;

  @override
  Future<CityFoundingOptionsView> cityFoundingOptions({
    required int expectedRevision,
    required String founderUnitId,
  }) => _owner._serialize(
    () => _owner._cityGateway.foundingOptions(
      context: _owner._context(),
      expectedRevision: expectedRevision,
      founderUnitId: founderUnitId,
      send: RustGameSessionGateway._send,
    ),
  );

  @override
  Future<CityInspectionView> inspectCity({
    required int expectedRevision,
    required String cityId,
  }) => _owner._serialize(
    () => _owner._cityGateway.inspect(
      context: _owner._context(),
      expectedRevision: expectedRevision,
      cityId: cityId,
      send: RustGameSessionGateway._send,
    ),
  );

  @override
  Future<CityCommandResultView> executeCityAction({
    required int expectedRevision,
    required CityActionView action,
  }) => _owner._serialize(
    () => _owner._cityGateway.execute(
      context: _owner._context(),
      expectedRevision: expectedRevision,
      action: action,
      send: RustGameSessionGateway._send,
      applyPatch: _owner._applyCommandPatch,
    ),
  );
}
