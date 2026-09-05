import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_command_frame_view.dart';
import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';
import 'map_feedback_mapper.dart';
import 'player_map_view_mapper.dart';
import 'recipient_projection_cache.dart';

/// Validates a batch before presentation, retaining commands rather than a full
/// recipient snapshot for every command. Each traversal has an isolated cache.
final class ObservedCommandFrames {
  ObservedCommandFrames({
    required AonwPlayerViewSnapshot initialSnapshot,
    required PlayerMapView initialPlayer,
    required MapView map,
    required String recipientPlayerId,
    required List<AonwCommandResult> commands,
    required AonwSessionStamp finalStamp,
    PlayerMapViewMapper mapper = const PlayerMapViewMapper(),
  }) : _initialSnapshot = initialSnapshot,
       _initialPlayer = initialPlayer,
       _map = map,
       _commands = List.unmodifiable(commands),
       _mapper = mapper {
    if (recipientPlayerId != initialPlayer.actorPlayerId) {
      throw const FormatException('Observed commands changed recipient.');
    }
    validateObservedStamp(initialPlayer.stamp, initialSnapshot.stamp);
    MapCommandFrameView? last;
    for (final frame in frames) {
      last = frame;
    }
    finalPlayer = last?.player ?? initialPlayer;
    lastFrame = last;
    validateObservedStamp(finalPlayer.stamp, finalStamp);
  }

  final AonwPlayerViewSnapshot _initialSnapshot;
  final PlayerMapView _initialPlayer;
  final MapView _map;
  final List<AonwCommandResult> _commands;
  final PlayerMapViewMapper _mapper;
  late final PlayerMapView finalPlayer;
  late final MapCommandFrameView? lastFrame;

  Iterable<MapCommandFrameView> get frames sync* {
    final cache = RecipientProjectionCache.open(
      snapshot: _initialSnapshot,
      map: _map,
    );
    var previous = _initialPlayer;
    for (final command in _commands) {
      final snapshot = cache.apply(command);
      final player = _mapper.fromWire(
        snapshot,
        map: _map,
        actorPlayerId: previous.actorPlayerId,
        recentFeedback: mapCommandFeedback(
          command: command,
          snapshot: snapshot,
          previous: previous,
          map: _map,
        ),
      );
      yield MapCommandFrameView(player: player);
      previous = player;
    }
  }
}

void validateObservedStamp(SessionStampView view, AonwSessionStamp wire) {
  if (view.revision != wire.revision ||
      view.stateDigest != wire.stateDigest ||
      view.mapHash != wire.mapHash ||
      view.rulesetHash != wire.rulesetHash) {
    throw const FormatException(
      'Observed commands do not match the recipient state.',
    );
  }
}
