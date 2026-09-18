import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/design_system/aonw_tokens.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/application/production_inspection_state.dart';
import 'package:aonw_flutter/features/production/application/production_state.dart';
import 'package:aonw_flutter/features/production/presentation/production_overlay.dart';
import 'package:aonw_flutter/features/production/presentation/production_panel.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';
import 'production_details_effects_fixture.dart';

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
  bool modal = false,
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
        child: ColoredBox(
          color: AonwColorTokens.background,
          child: _BannerContent(
            options: options,
            modal: modal,
            pending: pending,
            enabled: enabled,
            onAction: onAction ?? (_) {},
          ),
        ),
      ),
    ),
  ),
);

final class _BannerContent extends StatefulWidget {
  const _BannerContent({
    required this.options,
    required this.modal,
    required this.pending,
    required this.enabled,
    required this.onAction,
  });
  final ProductionOptionsView options;
  final bool modal;
  final bool pending;
  final bool enabled;
  final ValueChanged<ProductionActionView> onAction;

  @override
  State<_BannerContent> createState() => _BannerContentState();
}

final class _BannerContentState extends State<_BannerContent> {
  ProductionTargetView? target;

  @override
  void didUpdateWidget(_BannerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.cityId != widget.options.cityId) target = null;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final selected = target;
    final state = ProductionState(
      cityId: options.cityId,
      options: options,
      inFlightAction: widget.pending
          ? RushProductionActionView(cityId: options.cityId)
          : null,
      inspection: selected == null
          ? null
          : ProductionInspectionState(
              target: selected,
              correlationId: 1,
              loading: false,
              details: detailFixture(options, selected),
            ),
    );
    void inspect(ProductionTargetView? value) => setState(() => target = value);
    if (widget.modal) {
      return ProductionOverlay(
        state: state,
        cityName: 'Warszawa',
        treasury: 150,
        enabled: widget.enabled,
        onAction: widget.onAction,
        onClose: () {},
        onInspect: inspect,
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ProductionPanel(
            state: state,
            treasury: 150,
            enabled: widget.enabled,
            onAction: widget.onAction,
            onInspect: inspect,
          ),
        ),
      ),
    );
  }
}
