import 'package:aonw_flutter/features/cities/application/city_session_port.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';

final class UnsupportedCitySession implements CitySessionPort {
  const UnsupportedCitySession();

  @override
  Future<CityFoundingOptionsView> cityFoundingOptions({
    required int expectedRevision,
    required String founderUnitId,
  }) => throw UnsupportedError('City founding is outside this test.');

  @override
  Future<CityInspectionView> inspectCity({
    required int expectedRevision,
    required String cityId,
  }) => throw UnsupportedError('City inspection is outside this test.');

  @override
  Future<CityCommandResultView> executeCityAction({
    required int expectedRevision,
    required CityActionView action,
  }) => throw UnsupportedError('City commands are outside this test.');
}
