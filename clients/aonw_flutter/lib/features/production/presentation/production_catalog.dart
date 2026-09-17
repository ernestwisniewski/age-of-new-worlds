import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../map/read_model/map_view.dart';
import '../read_model/production_view.dart';
import 'production_building_choices.dart';
import 'production_choice_card.dart';
import 'production_copy.dart';

final class ProductionCatalog extends StatelessWidget {
  const ProductionCatalog({
    required this.options,
    required this.enabled,
    required this.onAction,
    this.header,
    super.key,
  });

  final ProductionOptionsView options;
  final bool enabled;
  final ValueChanged<ProductionActionView> onAction;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    return CustomScrollView(
      key: const ValueKey('production-catalog-scroll'),
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        ProductionBuildingChoices(
          cityId: options.cityId,
          options: options.buildings,
          choice: (option) => _choice(
            option,
            StartBuildingActionView(
              cityId: options.cityId,
              building:
                  (option.target as BuildingProductionTargetView).building,
            ),
          ),
        ),
        _section(copy.text(ProductionText.units), _units(copy)),
        _section(copy.text(ProductionText.projects), [
          for (final option in options.projects)
            (_) => _choice(
              option,
              StartCityProjectActionView(
                cityId: options.cityId,
                project: (option.target as ProjectProductionTargetView).project,
              ),
            ),
        ]),
        _section(copy.text(ProductionText.wonders), [
          for (final option in options.wonders)
            (_) => _choice(
              option,
              StartWonderActionView(
                cityId: options.cityId,
                wonder: (option.target as WonderProductionTargetView).wonder,
              ),
            ),
        ]),
        _section(copy.text(ProductionText.specializations), [
          for (final option in options.specializations)
            (_) => _specialization(copy, option),
        ]),
      ],
    );
  }

  Widget _choice(
    ProductionOptionView option,
    ProductionActionView action, {
    String? resourceCost,
    ProductionRejectionCodeView? blocker,
  }) => ProductionChoiceCard(
    key: ValueKey((
      'production-choice',
      action.runtimeType,
      _targetKey(option.target),
      resourceCost,
    )),
    option: option,
    active: options.isCurrent(option.target),
    resourceCost: resourceCost,
    blocker: blocker,
    onProduce: enabled && option.blocker == null && blocker == null
        ? () => onAction(action)
        : null,
  );

  List<WidgetBuilder> _units(ProductionCopy copy) => [
    for (final unit in options.units)
      if (unit.resourceOptions.isEmpty)
        (_) => _choice(
          unit.option,
          StartUnitProductionActionView(
            cityId: options.cityId,
            unit: (unit.option.target as UnitProductionTargetView).unit,
            resourceOptionIndex: null,
          ),
        )
      else
        for (var index = 0; index < unit.resourceOptions.length; index++)
          (_) => _choice(
            unit.option,
            StartUnitProductionActionView(
              cityId: options.cityId,
              unit: (unit.option.target as UnitProductionTargetView).unit,
              resourceOptionIndex: index,
            ),
            resourceCost: _stockpile(copy, unit.resourceOptions[index]),
            blocker: unit.affordableResourceOptionIndices.contains(index)
                ? null
                : ProductionRejectionCodeView
                      .unitProductionMissingStrategicResource,
          ),
  ];

  Widget _specialization(
    ProductionCopy copy,
    CitySpecializationOptionView option,
  ) {
    final reason = copy.rejection(option.blocker);
    return Padding(
      padding: const EdgeInsets.only(bottom: AonwSpacing.sm),
      child: OutlinedButton(
        onPressed: enabled && option.blocker == null
            ? () => onAction(
                SetCitySpecializationActionView(
                  cityId: options.cityId,
                  specialization: option.specialization,
                ),
              )
            : null,
        child: Text(
          '${copy.cityContent(option.specialization)} · '
          '${copy.text(ProductionText.requires)} ${copy.cityContent(option.requiredBuilding)}'
          '${reason == null ? '' : ' · $reason'}',
        ),
      ),
    );
  }
}

Widget _section(String title, List<WidgetBuilder> rows) => SliverMainAxisGroup(
  slivers: [
    if (rows.isNotEmpty) ...[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
          child: Text(title, style: AonwTextStyles.sectionHeader),
        ),
      ),
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) => rows[index](context),
      ),
    ],
  ],
);

String _targetKey(ProductionTargetView target) => switch (target) {
  BuildingProductionTargetView(:final building) => building,
  UnitProductionTargetView(:final unit) => unit.name,
  WonderProductionTargetView(:final wonder) => wonder,
  ProjectProductionTargetView(:final project) => project,
};

String _stockpile(ProductionCopy copy, Map<MapResource, int> value) => value
    .entries
    .map((entry) => '${copy.resource(entry.key)} ${entry.value}')
    .join(' + ');
