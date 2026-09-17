import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/application/production_state.dart';
import 'package:aonw_flutter/features/production/presentation/production_panel.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';

ProductionOptionsView bannerOptions({
  bool project = false,
  bool blocked = false,
  bool unaffordable = false,
}) {
  if (project) return _projectOptions();
  if (blocked) return _blockedOptions();
  const option = ProductionOptionView(
    availability: ProductionAvailabilityView(
      requiredTechnology: null,
      technologyUnlocked: true,
      completedInCity: false,
    ),
    target: BuildingProductionTargetView('workshop'),
    cost: 100,
    blocker: null,
    forecast: ProductionForecastView(
      investedProduction: 37,
      productionPerTurn: 7,
      estimatedTurns: 11,
      projectOutput: null,
      spawnBlocked: false,
    ),
  );
  return _options(
    option,
    ProductionRushQuoteView(
      production: 3,
      goldCost: 19,
      blocker: unaffordable
          ? ProductionRejectionCodeView.rushProductionUnavailable
          : null,
    ),
    buildings: [option],
  );
}

ProductionOptionsView _projectOptions() {
  const option = ProductionOptionView(
    availability: ProductionAvailabilityView(
      requiredTechnology: null,
      technologyUnlocked: true,
      completedInCity: false,
    ),
    target: ProjectProductionTargetView('research'),
    cost: 0,
    blocker: null,
    forecast: ProductionForecastView(
      investedProduction: 37,
      productionPerTurn: 7,
      estimatedTurns: null,
      projectOutput: 4,
      spawnBlocked: false,
    ),
  );
  return _options(
    option,
    const ProductionRushQuoteView(
      production: 0,
      goldCost: 0,
      blocker: ProductionRejectionCodeView.projectCannotBeRushed,
    ),
    projects: [option],
  );
}

ProductionOptionsView _blockedOptions() {
  const option = ProductionOptionView(
    availability: ProductionAvailabilityView(
      requiredTechnology: null,
      technologyUnlocked: true,
      completedInCity: false,
    ),
    target: UnitProductionTargetView(VisibleUnitKind.warrior),
    cost: 100,
    blocker: null,
    forecast: ProductionForecastView(
      investedProduction: 100,
      productionPerTurn: 7,
      estimatedTurns: null,
      projectOutput: null,
      spawnBlocked: true,
    ),
  );
  return _options(
    option,
    const ProductionRushQuoteView(
      production: 0,
      goldCost: 0,
      blocker: ProductionRejectionCodeView.rushProductionUnavailable,
    ),
    units: [
      UnitProductionOptionView(
        option: option,
        resourceOptions: [],
        affordableResourceOptionIndices: {},
      ),
    ],
  );
}

ProductionOptionsView _options(
  ProductionOptionView option,
  ProductionRushQuoteView quote, {
  List<ProductionOptionView> buildings = const [],
  List<UnitProductionOptionView> units = const [],
  List<ProductionOptionView> projects = const [],
}) => ProductionOptionsView(
  stamp: testSessionStamp(),
  cityId: 'preview-city',
  currentTarget: option.target,
  investedProduction: option.forecast.investedProduction,
  productionOverflow: 5,
  rushQuote: quote,
  buildings: buildings,
  units: units,
  projects: projects,
  wonders: [],
  specializations: [],
);

Widget bannerApp({
  required ProductionOptionsView options,
  ValueChanged<ProductionActionView>? onAction,
  bool enabled = true,
  bool pending = false,
  String locale = 'en',
  double scale = 1,
  Size size = const Size(390, 844),
}) => LocalizedTestApp(
  locale: Locale(locale),
  theme: AonwTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(scale),
      disableAnimations: true,
    ),
    child: Scaffold(
      body: RepaintBoundary(
        key: const ValueKey('production-banner-golden'),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ProductionPanel(
                state: ProductionState(
                  cityId: options.cityId,
                  options: options,
                  inFlightAction: pending
                      ? RushProductionActionView(cityId: options.cityId)
                      : null,
                ),
                treasury: 150,
                enabled: enabled,
                onAction: onAction ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
