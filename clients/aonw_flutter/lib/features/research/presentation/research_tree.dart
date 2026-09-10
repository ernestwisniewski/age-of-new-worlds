import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../read_model/research_view.dart';
import 'research_copy.dart';
import 'research_tree_layout.dart';

part 'research_tree_edges.dart';
part 'research_tree_geometry.dart';

final class ResearchTree extends StatefulWidget {
  const ResearchTree({
    required this.options,
    required this.onInspect,
    required this.fallback,
    super.key,
  });

  final List<ResearchOptionView> options;
  final ValueChanged<TechnologyIdView> onInspect;
  final Widget fallback;

  @override
  State<ResearchTree> createState() => _ResearchTreeState();
}

final class _ResearchTreeState extends State<ResearchTree> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _canvas(context, constraints.maxWidth),
  );

  Widget _canvas(BuildContext context, double width) {
    final options = widget.options;
    final layout = ResearchTreeLayout.fromOptions(options);
    if (layout == null || layout.columns.isEmpty) return widget.fallback;
    final scale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(14) / 14,
    );
    final nodeWidth = math
        .min(260 * scale, math.max(160, width - 8))
        .toDouble();
    final nodeSize = Size(nodeWidth, _nodeHeight(context, options, nodeWidth));
    final bounds = _nodeBounds(layout, nodeSize);
    final size = Size(
      layout.columns.length * (nodeSize.width + 48),
      layout.columns.map((column) => column.length).reduce(math.max) *
          (nodeSize.height + 20),
    );
    return Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      child: ClipRect(
        child: SingleChildScrollView(
          controller: _horizontal,
          key: const ValueKey('research-tree-horizontal'),
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            key: const ValueKey('research-tree-vertical'),
            child: RepaintBoundary(
              child: SizedBox.fromSize(
                size: size,
                child: CustomPaint(
                  painter: _ResearchTreeEdges(
                    options: options,
                    bounds: bounds,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  child: Stack(
                    children: [
                      for (final column in layout.columns)
                        for (final option in column)
                          Positioned.fromRect(
                            rect: bounds[option.technology]!,
                            child: _ResearchTreeNode(
                              option: option,
                              onInspect: widget.onInspect,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Map<TechnologyIdView, Rect> _nodeBounds(
  ResearchTreeLayout layout,
  Size nodeSize,
) => {
  for (var column = 0; column < layout.columns.length; column++)
    for (var row = 0; row < layout.columns[column].length; row++)
      layout.columns[column][row].technology: Rect.fromLTWH(
        column * (nodeSize.width + 48) + 4,
        row * (nodeSize.height + 20) + 4,
        nodeSize.width,
        nodeSize.height,
      ),
};

final class _ResearchTreeNode extends StatelessWidget {
  const _ResearchTreeNode({required this.option, required this.onInspect});

  final ResearchOptionView option;
  final ValueChanged<TechnologyIdView> onInspect;

  @override
  Widget build(BuildContext context) {
    final copy = ResearchCopy.of(context);
    final colors = Theme.of(context).colorScheme;
    final border = switch (option.availability) {
      TechnologyAvailabilityView.active => colors.secondary,
      TechnologyAvailabilityView.available => colors.primary,
      TechnologyAvailabilityView.unlocked => colors.tertiary,
      _ => colors.outline,
    };
    return OutlinedButton(
      key: ValueKey(('research-tree-node', option.technology.name)),
      onPressed: () => onInspect(option.technology),
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).cardTheme.color ?? colors.surface,
        foregroundColor: colors.onSurface,
        side: BorderSide(color: border, width: 2),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodySmall!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.technology(option.technology),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(copy.availability(option.availability)),
              Text(
                '${copy.text(ResearchText.progress)}: '
                '${option.progress} / ${option.effectiveCost}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
