part of 'map_test_fixture.dart';

mixin FakeProductionSessionFixture implements ProductionSessionPort {
  ProductionSessionException? get productionFailure;
  ProductionOverviewFixture? get productionOverviewResult;
  List<ProductionOverviewFixture> get productionOverviewResults;
  ProductionCommandResultView? get productionResult;
  MapScene? get scene;
  var productionOverviewCalls = 0;
  var productionCommandCalls = 0;
  ProductionActionView? lastProductionAction;
  int? lastProductionExpectedRevision;

  Future<ProductionDetailsView> Function(
    int revision,
    String cityId,
    ProductionTargetView target,
  )?
  productionDetailsHandler;
  @override
  Future<ProductionOverviewFixture> productionOverview({
    required int expectedRevision,
    required String cityId,
  }) async => _productionOverview(expectedRevision, cityId);

  @override
  Future<ProductionDetailsView> productionDetails({
    required int expectedRevision,
    required String cityId,
    required ProductionTargetView target,
  }) =>
      productionDetailsHandler?.call(expectedRevision, cityId, target) ??
      (throw StateError("No production details fixture."));

  @override
  Future<ProductionCommandResultView> executeProductionAction({
    required int expectedRevision,
    required ProductionActionView action,
  }) async {
    productionCommandCalls += 1;
    lastProductionExpectedRevision = expectedRevision;
    lastProductionAction = action;
    final error = productionFailure;
    if (error != null) throw error;
    return productionResult ??
        (throw StateError('No production result fixture.'));
  }

  ProductionOverviewFixture _productionOverview(
    int expectedRevision,
    String cityId,
  ) {
    productionOverviewCalls += 1;
    final error = productionFailure;
    if (error != null) throw error;
    if (productionOverviewResults.isNotEmpty) {
      final index = productionOverviewCalls <= productionOverviewResults.length
          ? productionOverviewCalls - 1
          : productionOverviewResults.length - 1;
      return productionOverviewResults[index];
    }
    return productionOverviewResult ??
        (
          options: ProductionOptionsView(
            stamp: testSessionStamp(revision: expectedRevision),
            cityId: cityId,
            currentTarget: null,
            investedProduction: 0,
            productionOverflow: 0,
            rushQuote: const ProductionRushQuoteView(
              production: 0,
              goldCost: 0,
              blocker: ProductionRejectionCodeView.productionQueueEmpty,
            ),
            buildings: const [],
            units: const [],
            projects: const [],
            wonders: const [],
            specializations: const [],
          ),
          resources: StrategicResourceProjectionView(
            stamp: testSessionStamp(revision: expectedRevision),
            playerId: scene?.player.actorPlayerId ?? 'preview-player',
            output: const [],
            sources: const [],
          ),
        );
  }
}
