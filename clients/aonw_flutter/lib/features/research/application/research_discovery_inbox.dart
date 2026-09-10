import '../../map/read_model/map_feedback_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/research_discovery_view.dart';

/// Presentation acknowledgement only; research completion is supplied by Rust.
final class ResearchDiscoveryInbox {
  Object? _session;
  (String, String, String)? _recipient;
  int? _revision;
  final _seen = <MapEventIdentityView>{};
  final _pending = <ResearchDiscoveryView>[];
  bool minimized = false;

  ResearchDiscoveryView? get current => _pending.firstOrNull;

  void observe(
    PlayerMapView player, {
    required Object session,
    required bool enabled,
  }) {
    final recipient = (
      player.actorPlayerId,
      player.stamp.mapHash,
      player.stamp.rulesetHash,
    );
    final reset =
        !identical(_session, session) ||
        _recipient != recipient ||
        (_revision != null && player.stamp.revision < _revision!);
    _session = session;
    _recipient = recipient;
    _revision = player.stamp.revision;
    final journal = player.recentDiscoveries;
    if (reset || journal.isEmpty || !enabled) {
      _pending.clear();
      _seen.clear();
      _seen.addAll(journal.map((event) => event.identity));
      minimized = false;
      return;
    }
    final identities = journal.map((event) => event.identity).toSet();
    _seen.retainAll(identities);
    _pending.removeWhere((event) => !identities.contains(event.identity));
    for (final event in journal) {
      if (_seen.add(event.identity)) _pending.add(event);
    }
    if (_pending.isEmpty) minimized = false;
  }

  void dismiss() {
    if (_pending.isNotEmpty) _pending.removeAt(0);
    minimized = false;
  }
}
