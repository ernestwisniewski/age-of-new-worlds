import '../../../l10n/generated/aonw_localizations.dart';
import '../read_model/map_feedback_view.dart';

final class MapFeedbackLabels {
  const MapFeedbackLabels.empty() : _labels = const {};

  MapFeedbackLabels(Map<MapEventIdentityView, String> labels)
    : _labels = Map.unmodifiable(labels);

  final Map<MapEventIdentityView, String> _labels;

  String? labelFor(MapEventIdentityView identity) => _labels[identity];
}

MapFeedbackLabels buildMapFeedbackLabels(
  List<MapFeedbackCueView> cues,
  AonwLocalizations l10n,
) => MapFeedbackLabels({
  for (final cue in cues.whereType<MapFloatingTextCueView>())
    cue.identity: switch (cue.content) {
      MapMessageTextView(:final message) => l10n.mapFeedbackText(message.name),
      MapImprovementYieldTextView() => _improvementLabel(
        cue.content as MapImprovementYieldTextView,
        l10n,
      ),
    },
});

String _improvementLabel(
  MapImprovementYieldTextView value,
  AonwLocalizations l10n,
) {
  final delta = value.yieldDelta;
  final yields = {
    'food': delta.food,
    'production': delta.production,
    'gold': delta.gold,
    'defense': delta.defense,
  };
  final parts = [
    for (final entry in yields.entries)
      if (entry.value > 0) '+${entry.value} ${l10n.mapYieldShort(entry.key)}',
  ];
  return parts.isEmpty
      ? '+${l10n.presentationName(value.improvement.name)}'
      : parts.join(' ');
}
