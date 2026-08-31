import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../application/research_state.dart';
import '../read_model/research_view.dart';
import 'research_copy.dart';

final class ResearchOverlay extends StatefulWidget {
  const ResearchOverlay({
    required this.state,
    required this.selectionRequired,
    required this.onSelect,
    required this.onRetry,
    super.key,
  });

  final ResearchState state;
  final bool selectionRequired;
  final ValueChanged<TechnologyIdView> onSelect;
  final VoidCallback onRetry;

  @override
  State<ResearchOverlay> createState() => _ResearchOverlayState();
}

final class _ResearchOverlayState extends State<ResearchOverlay> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final copy = ResearchCopy.of(context);
    final open = _open || widget.selectionRequired;
    return Stack(
      children: [
        _trigger(context, copy, open),
        if (open)
          Positioned(
            top: AonwHudSideMenuLayout.top(context),
            left: AonwHudSideMenuLayout.panelLeft(context),
            bottom: AonwSpacing.md,
            child: SafeArea(
              child: AonwPanel(
                semanticLabel: copy.text(ResearchText.title),
                liveRegion: widget.selectionRequired,
                maxWidth: 680,
                padding: const EdgeInsets.all(AonwSpacing.md),
                child: SizedBox(
                  width: 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              copy.text(ResearchText.title),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (!widget.selectionRequired)
                            IconButton(
                              key: const ValueKey('close-research'),
                              tooltip: copy.text(ResearchText.close),
                              onPressed: () => setState(() => _open = false),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                      if (widget.selectionRequired)
                        Text(
                          copy.text(ResearchText.selectionRequired),
                          key: const ValueKey('research-selection-required'),
                        ),
                      Expanded(
                        child: ResearchPanel(
                          state: widget.state,
                          onSelect: widget.onSelect,
                          onRetry: widget.onRetry,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _trigger(BuildContext context, ResearchCopy copy, bool open) =>
      Positioned(
        top: AonwHudSideMenuLayout.actionTop(context, 1),
        left: AonwHudSideMenuLayout.left(context),
        child: AonwHudIconButton(
          key: const ValueKey('open-research'),
          tooltip: copy.text(ResearchText.open),
          onPressed: open ? null : () => setState(() => _open = true),
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
        Expanded(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: ListView.builder(
              key: const ValueKey('research-options'),
              itemCount: options.options.length,
              itemBuilder: (context, index) => _TechnologyOptionCard(
                option: options.options[index],
                enabled: !state.commandPending,
                onSelect: onSelect,
              ),
            ),
          ),
        ),
      ],
    );
  }
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

final class _TechnologyOptionCard extends StatelessWidget {
  const _TechnologyOptionCard({
    required this.option,
    required this.enabled,
    required this.onSelect,
  });

  final ResearchOptionView option;
  final bool enabled;
  final ValueChanged<TechnologyIdView> onSelect;

  @override
  Widget build(BuildContext context) {
    final copy = ResearchCopy.of(context);
    final available =
        option.availability == TechnologyAvailabilityView.available;
    String technologies(List<TechnologyIdView> values) => values.isEmpty
        ? copy.text(ResearchText.none)
        : values.map(copy.technology).join(', ');
    final unlocks = option.unlocks.isEmpty
        ? copy.text(ResearchText.none)
        : option.unlocks.map(copy.unlock).join(', ');
    final percent = option.boostDiscountBasisPoints / 100;
    return Card.outlined(
      key: ValueKey(('research-option', option.technology.name)),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.technology(option.technology),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(copy.availability(option.availability)),
            Text(
              '${copy.text(ResearchText.progress)}: ${option.progress} / '
              '${option.effectiveCost} · ${copy.text(ResearchText.boost)}: '
              '${percent.toStringAsFixed(percent.truncateToDouble() == percent ? 0 : 2)}%',
            ),
            Text(
              '${copy.text(ResearchText.prerequisites)}: '
              '${technologies(option.prerequisites)}',
            ),
            Text(
              '${copy.text(ResearchText.blockedBy)}: '
              '${technologies(option.blockedBy)}',
            ),
            Text('${copy.text(ResearchText.unlocks)}: $unlocks'),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: ValueKey(('select-technology', option.technology.name)),
                onPressed: enabled && available
                    ? () => onSelect(option.technology)
                    : null,
                child: Text(copy.text(ResearchText.choose)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
