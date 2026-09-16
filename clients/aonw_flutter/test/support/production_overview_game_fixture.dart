part of 'map_test_fixture.dart';

extension _MapProductionFixture on FakeGameSession {
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
