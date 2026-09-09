import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/city_planning_session_port.dart';
import '../read_model/city_planning_view.dart';
import '../read_model/player_map_view.dart';

/// Fetches optional markings once per recipient state, without an idle loop.
final class CityPlanningPresentation {
  CityPlanningPresentation({required this.onChanged});

  final void Function(CityPlanningView?) onChanged;
  Object? _identity;
  var _generation = 0;
  var _disposed = false;
  CityPlanningView? _value;

  void synchronize({
    required CityPlanningSessionPort? session,
    required PlayerMapView? player,
    required bool enabled,
    required Object epoch,
  }) {
    if (_disposed) return;
    final stamp = player?.stamp;
    final identity = enabled && session != null && player != null
        ? (
            session,
            epoch,
            player.actorPlayerId,
            stamp!.revision,
            stamp.stateDigest,
            stamp.mapHash,
            stamp.rulesetHash,
          )
        : null;
    if (_identity == identity) {
      onChanged(_value);
      return;
    }
    _identity = identity;
    final generation = ++_generation;
    _value = null;
    onChanged(null);
    if (identity != null) {
      unawaited(_query(session!, player!, generation));
    }
  }

  Future<void> _query(
    CityPlanningSessionPort session,
    PlayerMapView player,
    int generation,
  ) async {
    try {
      final value = await session.cityPlanning(
        expectedRevision: player.stamp.revision,
      );
      if (_disposed || generation != _generation) return;
      final first = value.stamp;
      final second = player.stamp;
      if (value.actorPlayerId != player.actorPlayerId ||
          (
                first.revision,
                first.stateDigest,
                first.mapHash,
                first.rulesetHash,
              ) !=
              (
                second.revision,
                second.stateDigest,
                second.mapHash,
                second.rulesetHash,
              )) {
        return;
      }
      _value = value;
      onChanged(value);
    } on Object catch (error, stackTrace) {
      if (_disposed || generation != _generation) return;
      debugPrintStack(
        label: 'City planning diagnostic: $error',
        stackTrace: stackTrace,
      );
      // Optional markings stay absent until a new state or explicit toggle.
      // The transport owns connection failure and resynchronization reporting.
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _value = null;
  }
}
