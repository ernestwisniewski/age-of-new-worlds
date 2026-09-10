part of 'map_feedback_mapper.dart';

const maximumRecentResearchDiscoveries = 64;

/// Completion facts have no map anchor: a recipient can finish research even
/// without a currently visible city or unit. Resync/open start an empty journal.
List<ResearchDiscoveryView> mapResearchDiscoveries({
  required AonwCommandResult command,
  required AonwPlayerViewSnapshot snapshot,
  required PlayerMapView previous,
  required MapView map,
}) {
  if (!command.accepted || command.stamp.revision == previous.stamp.revision) {
    return previous.recentDiscoveries;
  }
  _validateFeedbackIdentity(command, snapshot, previous, map);
  final next = [...previous.recentDiscoveries];
  for (var index = 0; index < command.events.length; index++) {
    final event = command.events[index];
    if (event is! AonwTechnologyResearchedEvent ||
        event.playerId != previous.actorPlayerId) {
      continue;
    }
    next.add(
      ResearchDiscoveryView(
        identity: (revision: command.stamp.revision, eventIndex: index),
        technology: TechnologyIdView.values.byName(event.technology.name),
      ),
    );
  }
  return List.unmodifiable(
    next.length <= maximumRecentResearchDiscoveries
        ? next
        : next.sublist(next.length - maximumRecentResearchDiscoveries),
  );
}
