import 'package:flutter/foundation.dart';

import '../../audio/application/game_audio_port.dart';
import '../application/game_session_state.dart';

enum MapInteractionAudioAction { selectHex, selectCity, foundCity, manageCity }

/// Retains at most one user-requested query until its presentation is ready.
final class MapInteractionAudio {
  MapInteractionAudio({required this.readState, required this.play});

  final GameSessionState Function() readState;
  final void Function(GameSoundCue) play;
  _PendingSound? _pending;

  void cancelPending() => _pending = null;

  void perform(MapInteractionAudioAction intent, VoidCallback action) {
    final before = readState();
    final pending = _pending;
    _pending = null;
    action();
    final after = readState();
    if (identical(before, after)) {
      _pending = pending;
      return;
    }
    if (before is! GameSessionReady || after is! GameSessionReady) return;
    if (_scope(before) != _scope(after)) return;
    _present(intent, before, after);
  }

  void _present(
    MapInteractionAudioAction intent,
    GameSessionReady before,
    GameSessionReady after,
  ) {
    switch (intent) {
      case MapInteractionAudioAction.selectHex:
        _selectHex(before, after);
      case MapInteractionAudioAction.selectCity:
        _selectCity(after);
      case MapInteractionAudioAction.foundCity:
        _awaitFounding(after);
      case MapInteractionAudioAction.manageCity:
        final mode = after.interaction.city?.managementMode;
        if (mode != null && mode != before.interaction.city?.managementMode) {
          play(GameSoundCue.uiPanelOpen);
        }
    }
  }

  void observe(GameSessionState state) {
    final pending = _pending;
    if (pending == null) return;
    if (state is! GameSessionReady || _scope(state) != pending.scope) {
      cancelPending();
      return;
    }
    final result = pending.evaluate(state);
    if (!result.finished) return;
    cancelPending();
    if (result.cue case final cue?) play(cue);
  }

  void _selectHex(GameSessionReady before, GameSessionReady after) {
    final previousCity = before.interaction.city;
    if (previousCity?.foundingOptions != null ||
        previousCity?.managementMode != null) {
      return;
    }
    final interaction = after.interaction;
    if (interaction.selected == null) return;
    final unitId = interaction.selectedUnitId;
    if (unitId == null) {
      if (interaction.city?.cityId != null) {
        _selectCity(after);
      } else {
        play(GameSoundCue.mapTileSelect);
      }
      return;
    }
    final unit = after.recipient.controlledUnitById(unitId);
    if (interaction.movementPending &&
        before.interaction.selectedUnitId == unitId &&
        unit?.coordinate != interaction.selected) {
      _awaitRoute(after);
    }
  }

  void _selectCity(GameSessionReady state) {
    final cityId = state.interaction.city?.cityId;
    if (cityId == null) return;
    if (state.recipient.cityById(cityId)?.ownerPlayerId ==
        state.recipient.actorPlayerId) {
      play(GameSoundCue.city);
    }
  }

  void _awaitRoute(GameSessionReady state) {
    final unitId = state.interaction.selectedUnitId;
    final target = state.interaction.selected;
    _pending = _PendingSound(_scope(state), (next) {
      final interaction = next.interaction;
      if (interaction.selectedUnitId != unitId ||
          interaction.selected != target) {
        return _silent;
      }
      if (interaction.movementPending) return _waiting;
      return (
        finished: true,
        cue: interaction.movementError == null && interaction.route != null
            ? GameSoundCue.movePreview
            : null,
      );
    });
  }

  void _awaitFounding(GameSessionReady state) {
    final city = state.interaction.city;
    if (city?.founderUnitId == null) return;
    final founder = city!.founderUnitId;
    final correlation = city.correlationId;
    _pending = _PendingSound(_scope(state), (next) {
      final current = next.interaction.city;
      if (current?.founderUnitId != founder ||
          current?.correlationId != correlation) {
        return _silent;
      }
      if (current!.loading) return _waiting;
      return (
        finished: true,
        cue: current.failure == null && current.foundingOptions != null
            ? GameSoundCue.uiPanelOpen
            : null,
      );
    });
    observe(state);
  }
}

typedef _SoundResult = ({bool finished, GameSoundCue? cue});
const _silent = (finished: true, cue: null);
const _waiting = (finished: false, cue: null);

final class _PendingSound {
  const _PendingSound(this.scope, this.evaluate);
  final Object scope;
  final _SoundResult Function(GameSessionReady) evaluate;
}

Object _scope(GameSessionReady state) {
  final stamp = state.recipient.stamp;
  return (
    state.scene.map.mapId,
    state.recipient.actorPlayerId,
    stamp.revision,
    stamp.stateDigest,
    stamp.mapHash,
    stamp.rulesetHash,
  );
}
