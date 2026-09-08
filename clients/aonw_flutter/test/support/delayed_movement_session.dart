import 'dart:async';

import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';

import 'map_test_fixture.dart';

final class DelayedMovementSession implements MovementSessionPort {
  final requests = <Completer<RoutePlanView>>[];
  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) async => testReachableView();
  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) {
    final completion = Completer<RoutePlanView>();
    requests.add(completion);
    return completion.future;
  }

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();
}
