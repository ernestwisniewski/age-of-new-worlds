part of 'map_coordinator_test.dart';

final class _CompletingGameSession
    with FakePendingTurnActionsSession
    implements
        MapSessionPort,
        MovementSessionPort,
        CombatSessionPort,
        UnitLogisticsSessionPort,
        WorkerSessionPort,
        ProductionSessionPort,
        ArtifactSessionPort,
        ResearchSessionPort,
        DiplomacySessionPort,
        TurnSessionPort,
        UnitActionSessionPort {
  var _nextRequest = Completer<Completer<MapScene>>();

  Future<Completer<MapScene>> get nextRequest => _nextRequest.future;

  @override
  Future<MapScene> load(MapAssetPaths assets) {
    final request = Completer<MapScene>();
    _nextRequest.complete(request);
    _nextRequest = Completer<Completer<MapScene>>();
    return request.future;
  }

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();

  @override
  Future<CombatPreviewView> combatPreview({
    required int expectedRevision,
    required String attackerUnitId,
    required MapHexCoordinate defender,
  }) => throw UnimplementedError();

  @override
  Future<CombatCommandResultView> attack({
    required int expectedRevision,
    required CombatAttackView attack,
  }) => throw UnimplementedError();

  @override
  Future<UnitLogisticsOptionsView> unitLogisticsOptions({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<UnitLogisticsCommandResultView> executeUnitLogistics({
    required int expectedRevision,
    required UnitLogisticsActionView action,
  }) => throw UnimplementedError();

  @override
  Future<WorkerOptionsView> workerOptions({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<WorkerCommandResultView> executeWorkerAction({
    required int expectedRevision,
    required WorkerActionView action,
  }) => throw UnimplementedError();

  @override
  Future<
    ({ProductionOptionsView options, StrategicResourceProjectionView resources})
  >
  productionOverview({required int expectedRevision, required String cityId}) =>
      throw UnimplementedError();

  @override
  Future<ProductionDetailsView> productionDetails({
    required int expectedRevision,
    required String cityId,
    required ProductionTargetView target,
  }) => throw UnimplementedError();

  @override
  Future<ProductionCommandResultView> executeProductionAction({
    required int expectedRevision,
    required ProductionActionView action,
  }) => throw UnimplementedError();

  @override
  Future<ArtifactCommandResultView> executeArtifactAction({
    required int expectedRevision,
    required ArtifactActionView action,
  }) => throw UnimplementedError();

  @override
  Future<ResearchOptionsView> researchOptions({
    required int expectedRevision,
  }) async => testResearchOptionsView(revision: expectedRevision);

  @override
  Future<ResearchCommandResultView> cancelResearchSelection({
    required int expectedRevision,
  }) => throw UnimplementedError();

  @override
  Future<ResearchCommandResultView> selectTechnology({
    required int expectedRevision,
    required TechnologyIdView technology,
  }) => throw UnimplementedError();

  @override
  Future<DiplomacyCommandResultView> executeDiplomacyAction({
    required int expectedRevision,
    required DiplomacyActionView action,
  }) => throw UnimplementedError();

  @override
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) => throw UnimplementedError();

  @override
  Future<TurnCommandResultView> endTurn({required int expectedRevision}) =>
      throw UnimplementedError();

  @override
  Future<void> close() async {}
}
