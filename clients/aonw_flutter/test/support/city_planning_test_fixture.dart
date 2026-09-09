import 'package:aonw_flutter/features/map/application/city_planning_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/city_planning_view.dart';

mixin class FakeCityPlanningSession implements CityPlanningSessionPort {
  @override
  Future<CityPlanningView> cityPlanning({required int expectedRevision}) =>
      Future.error(StateError('This fixture does not provide city planning.'));
}
