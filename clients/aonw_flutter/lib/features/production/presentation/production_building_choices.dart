import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../read_model/production_ranking_view.dart';
import '../read_model/production_view.dart';
import 'production_building_sort.dart';
import 'production_building_sort_control.dart';
import 'production_copy.dart';

/// Lazy building groups inside the production catalog's single viewport.
final class ProductionBuildingChoices extends StatefulWidget {
  const ProductionBuildingChoices({
    required this.cityId,
    required this.options,
    required this.choice,
    this.ranks = const [],
    super.key,
  });

  final String cityId;
  final List<ProductionBuildingRankView> ranks;
  final List<ProductionOptionView> options;
  final Widget Function(ProductionOptionView) choice;

  @override
  State<ProductionBuildingChoices> createState() =>
      _ProductionBuildingChoicesState();
}

final class _ProductionBuildingChoicesState
    extends State<ProductionBuildingChoices> {
  ProductionBuildingSort _sort = ProductionBuildingSort.recommended;
  bool _futureOpen = false;
  bool _completedOpen = false;

  @override
  void didUpdateWidget(ProductionBuildingChoices oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityId != widget.cityId) {
      _futureOpen = false;
      _completedOpen = false;
      _sort = ProductionBuildingSort.recommended;
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    final current = <ProductionOptionView>[];
    final future = <ProductionOptionView>[];
    final completed = <ProductionOptionView>[];
    for (final option in _sort.order(
      widget.options,
      widget.ranks,
      copy.target,
    )) {
      if (option.availability.completedInCity) {
        completed.add(option);
      } else if (option.availability.technologyUnlocked) {
        current.add(option);
      } else {
        future.add(option);
      }
    }
    return SliverMainAxisGroup(
      slivers: [
        if (widget.options.isNotEmpty)
          SliverToBoxAdapter(
            child: ProductionBuildingHeader(
              title: copy.text(ProductionText.buildings),
              sort: widget.ranks.isEmpty ? null : _sort,
              onChanged: (mode) => setState(() => _sort = mode),
            ),
          ),
        if (current.isNotEmpty) _choices(current),
        if (future.isNotEmpty) ...[
          _disclosure(
            'production-future-buildings',
            copy.text(ProductionText.futureBuildings),
            copy.text(ProductionText.futureBuildingsHint),
            (open) => setState(() => _futureOpen = open),
          ),
          if (_futureOpen) _choices(future),
        ],
        if (completed.isNotEmpty) ...[
          _disclosure(
            'production-completed-buildings',
            copy.text(ProductionText.completedBuildings),
            null,
            (open) => setState(() => _completedOpen = open),
          ),
          if (_completedOpen) _choices(completed),
        ],
      ],
    );
  }

  Widget _disclosure(
    String key,
    String title,
    String? hint,
    ValueChanged<bool> onChanged,
  ) => SliverToBoxAdapter(
    child: ExpansionTile(
      key: ValueKey((key, widget.cityId)),
      tilePadding: EdgeInsets.zero,
      title: Text(title, style: AonwTextStyles.bodyStrong),
      subtitle: hint == null
          ? null
          : Text(hint, style: AonwTextStyles.bodySmall),
      onExpansionChanged: onChanged,
    ),
  );

  Widget _choices(List<ProductionOptionView> values) => SliverList.builder(
    itemCount: values.length,
    itemBuilder: (context, index) => widget.choice(values[index]),
  );
}
