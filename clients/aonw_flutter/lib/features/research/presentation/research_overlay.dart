import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../application/research_state.dart';
import '../read_model/research_view.dart';
import 'research_browser.dart';
import 'research_copy.dart';

part 'research_catalog.dart';
part 'research_recommendations.dart';
part 'technology_option_card.dart';

final class ResearchOverlay extends StatelessWidget {
  const ResearchOverlay({
    required this.state,
    required this.selectionRequired,
    required this.open,
    required this.onOpenChanged,
    required this.onSelect,
    required this.onRetry,
    this.trailingReserve = 0,
    super.key,
  });

  final ResearchState state;
  final bool selectionRequired;
  final bool open;
  final ValueChanged<bool>? onOpenChanged;
  final ValueChanged<TechnologyIdView> onSelect;
  final VoidCallback onRetry;
  final double trailingReserve;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final copy = ResearchCopy.of(context);
      return Stack(
        children: [
          _trigger(context, copy, open),
          if (open)
            Positioned(
              top: AonwHudSideMenuLayout.top(context),
              left: _panelMargin(constraints.maxWidth - trailingReserve),
              right:
                  _panelMargin(constraints.maxWidth - trailingReserve) +
                  trailingReserve,
              bottom: AonwSpacing.md,
              child: MapGamepadRegion(
                section: MapHudSection.globalActions,
                priority: MapGamepadPriority.panel,
                onCancel: onOpenChanged == null
                    ? null
                    : () => onOpenChanged?.call(false),
                child: SafeArea(
                  child: AonwPanel(
                    semanticLabel: copy.text(ResearchText.title),
                    liveRegion: selectionRequired,
                    maxWidth: 980,
                    padding: const EdgeInsets.all(AonwSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(context, copy),
                          if (selectionRequired)
                            Text(
                              copy.text(ResearchText.selectionRequired),
                              key: const ValueKey(
                                'research-selection-required',
                              ),
                            ),
                          Expanded(
                            child: ResearchPanel(
                              state: state,
                              onSelect: onSelect,
                              onRetry: onRetry,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _header(BuildContext context, ResearchCopy copy) => Row(
    children: [
      Expanded(
        child: Text(
          copy.text(ResearchText.title),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(
        key: const ValueKey('close-research'),
        tooltip: copy.text(ResearchText.close),
        onPressed: onOpenChanged == null ? null : () => onOpenChanged!(false),
        icon: const Icon(Icons.close),
      ),
    ],
  );

  Widget _trigger(BuildContext context, ResearchCopy copy, bool open) =>
      Positioned(
        top: AonwHudSideMenuLayout.actionTop(context, 1),
        left: AonwHudSideMenuLayout.left(context),
        child: AonwHudIconButton(
          key: const ValueKey('open-research'),
          tooltip: copy.text(ResearchText.open),
          onPressed: onOpenChanged == null ? null : () => onOpenChanged!(!open),
          active: open,
          icon: const Icon(Icons.science),
        ),
      );
}

final class ResearchPanel extends StatelessWidget {
  const ResearchPanel({
    required this.state,
    required this.onSelect,
    required this.onRetry,
    super.key,
  });

  final ResearchState state;
  final ValueChanged<TechnologyIdView> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = ResearchCopy.of(context);
    if (state.loading) {
      return Center(
        child: AonwProgressIndicator(
          semanticLabel: copy.text(ResearchText.loading),
        ),
      );
    }
    final options = state.options;
    if (options == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.failure case final failure?)
              Text(
                copy.failure(failure),
                key: const ValueKey('research-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              key: const ValueKey('retry-research'),
              onPressed: onRetry,
              child: Text(copy.text(ResearchText.retry)),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResearchSummary(options: options),
        if (state.commandPending)
          AonwProgressIndicator(
            semanticLabel: copy.text(ResearchText.selecting),
            compact: true,
          ),
        if (state.failure case final failure?)
          Text(
            copy.failure(failure),
            key: const ValueKey('research-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: AonwSpacing.sm),
        Expanded(child: _browser(options)),
      ],
    );
  }

  Widget _browser(ResearchOptionsView options) => ResearchBrowser(
    key: ValueKey((
      options.playerId,
      options.stamp.mapHash,
      options.stamp.rulesetHash,
      options.stamp.stateDigest,
    )),
    options: options.options,
    recommendations: options.recommendations.isEmpty
        ? null
        : _ResearchRecommendations(
            options: options,
            enabled: !state.commandPending,
            onSelect: onSelect,
          ),
    catalog: _ResearchCatalog(
      options: options.options,
      enabled: !state.commandPending,
      onSelect: onSelect,
    ),
    details: (option) => _TechnologyOptionCard(
      option: option,
      enabled: !state.commandPending,
      onSelect: onSelect,
    ),
  );
}

final class _ResearchSummary extends StatelessWidget {
  const _ResearchSummary({required this.options});

  final ResearchOptionsView options;

  @override
  Widget build(BuildContext context) {
    final copy = ResearchCopy.of(context);
    final active = options.activeTechnology;
    return Wrap(
      spacing: AonwSpacing.md,
      runSpacing: AonwSpacing.xs,
      children: [
        Text(
          '${copy.text(ResearchText.sciencePerTurn)}: '
          '${options.scienceYield.total}',
        ),
        Text('${copy.text(ResearchText.overflow)}: ${options.scienceOverflow}'),
        Text(
          '${copy.text(ResearchText.active)}: '
          '${active == null ? copy.text(ResearchText.none) : copy.technology(active)}',
        ),
      ],
    );
  }
}

double _panelMargin(double width) => math.max(12, (width - 980) / 2);
