import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/aonw_tokens.dart';
import '../presentation/flame_scene_patch.dart';
import 'gameplay_map_layers.dart';
import 'map_combat_feedback.dart';
import 'map_interaction_geometry.dart';
import 'static_map_layers.dart';

part 'map_combat_intent.dart';

typedef MapEffectActivitySink = void Function(bool active);

final class MapEffectHostComponent extends Component {
  MapEffectHostComponent({required MapUnitLayerComponent units})
    : _units = units,
      super(priority: 70);

  static const _movementDurationSeconds = 0.24;
  static const _combatDurationSeconds = 1.28;
  static const _maximumCombatEffects = 4;

  final MapUnitLayerComponent _units;
  final _movements = <String, _ActiveUnitMovement>{};
  final _combatPool = List.generate(
    _maximumCombatEffects,
    (_) => _ActiveCombatIntent(),
  );
  MapEffectActivitySink? onActivityChanged;
  var _reducedMotion = false;
  var _playbackSpeed = 1.0;
  var _activeUpdateCount = 0;
  var _completedMovementCount = 0;

  @visibleForTesting
  int get debugActiveEffectCount =>
      _movements.length + debugActiveCombatEffectCount;

  @visibleForTesting
  int get debugActiveCombatEffectCount =>
      _combatPool.where((effect) => effect.active).length;

  @visibleForTesting
  int get debugActiveDamageLabelCount => _combatPool.fold(
    0,
    (count, effect) =>
        count +
        (effect.active && effect.elapsed < 1.08
            ? effect.feedback.labelCount
            : 0),
  );

  @visibleForTesting
  int get debugActiveParticleCount => _combatPool.fold(
    0,
    (count, effect) =>
        count +
        (effect.active
            ? effect.feedback.activeParticleCount(effect.elapsed)
            : 0),
  );

  @visibleForTesting
  int get debugMaximumCombatEffectCount => _maximumCombatEffects;

  @visibleForTesting
  ({ui.Offset attacker, ui.Offset defender})? get debugCombatEndpoints {
    for (final effect in _combatPool) {
      if (effect.active) {
        return (
          attacker: effect.attackerCenter,
          defender: effect.defenderCenter,
        );
      }
    }
    return null;
  }

  @visibleForTesting
  double? get debugCombatPulse {
    for (final effect in _combatPool) {
      if (effect.active) return effect.pulse;
    }
    return null;
  }

  @visibleForTesting
  int get debugActiveUpdateCount => _activeUpdateCount;

  @visibleForTesting
  int get debugCompletedMovementCount => _completedMovementCount;

  @visibleForTesting
  double get debugPlaybackSpeed => _playbackSpeed;

  @visibleForTesting
  bool get debugReducedMotion => _reducedMotion;

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    _discardInterruptedMovements(patch);
    _startMovements(patch, cache);
    _startCombats(patch, cache);
    _notifyActivity();
  }

  void _discardInterruptedMovements(FlameScenePatch patch) {
    final transitionedIds = {
      for (final movement in patch.movements) movement.unitId,
    };
    for (final unitId in patch.removedUnitIds) {
      _movements.remove(unitId);
    }
    for (final unit in patch.unitUpserts) {
      if (!transitionedIds.contains(unit.id)) _movements.remove(unit.id);
    }
  }

  void _startMovements(FlameScenePatch patch, MapStaticRenderCache cache) {
    for (final movement in patch.movements) {
      final unit = _units.componentForUnit(movement.unitId);
      if (unit == null) continue;
      final target = _units.visualCenterFor(
        cache,
        movement.unitId,
        movement.to,
      );
      if (_reducedMotion) {
        unit.setVisualCenter(target);
        _completedMovementCount += 1;
      } else {
        _movements[movement.unitId] = _ActiveUnitMovement(
          unit: unit,
          start: unit.visualCenter,
          target: target,
        );
      }
    }
  }

  void _startCombats(FlameScenePatch patch, MapStaticRenderCache cache) {
    for (final combat in patch.combats) {
      final effect = _availableCombatEffect();
      if (effect == null) return;
      effect.start(combat, cache, reducedMotion: _reducedMotion);
    }
  }

  _ActiveCombatIntent? _availableCombatEffect() {
    for (final effect in _combatPool) {
      if (!effect.active) return effect;
    }
    return null;
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    for (final combat in _combatPool) {
      combat.setReducedMotion(enabled);
    }
    if (enabled) _finishMovements();
    _notifyActivity();
  }

  void setPlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'must be finite and positive');
    }
    _playbackSpeed = speed;
  }

  void skipAll() {
    if (!_hasActiveEffects) return;
    _finishMovements();
    _clearCombatEffects();
    _notifyActivity();
  }

  void _finishMovements() {
    for (final movement in _movements.values) {
      movement.unit.setVisualCenter(movement.target);
      _completedMovementCount += 1;
    }
    _movements.clear();
  }

  void clearEffects() {
    _movements.clear();
    _clearCombatEffects(dispose: true);
    _notifyActivity();
  }

  void _clearCombatEffects({bool dispose = false}) {
    for (final combat in _combatPool) {
      combat.complete();
      if (dispose) combat.feedback.dispose();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_hasActiveEffects) return;
    _activeUpdateCount += 1;
    final movementCompleted = _updateMovements(dt);
    final combatCompleted = _updateCombats(dt);
    if (movementCompleted || combatCompleted) _notifyActivity();
  }

  bool _updateMovements(double dt) {
    final completed = <String>[];
    for (final entry in _movements.entries) {
      final movement = entry.value;
      movement.elapsed += dt * _playbackSpeed;
      final linear = (movement.elapsed / _movementDurationSeconds).clamp(
        0.0,
        1.0,
      );
      final eased = linear * linear * (3 - 2 * linear);
      movement.unit.setVisualCenter(
        ui.Offset.lerp(movement.start, movement.target, eased)!,
      );
      if (linear >= 1) completed.add(entry.key);
    }
    for (final unitId in completed) {
      _movements.remove(unitId);
      _completedMovementCount += 1;
    }
    return completed.isNotEmpty;
  }

  bool _updateCombats(double dt) {
    var completed = false;
    for (final combat in _combatPool) {
      if (!combat.active) continue;
      combat.elapsed += dt * _playbackSpeed;
      if (combat.elapsed >= _combatDurationSeconds) {
        combat.complete();
        completed = true;
      }
    }
    return completed;
  }

  @override
  void render(ui.Canvas canvas) {
    for (final combat in _combatPool) {
      if (!combat.active) continue;
      combat.render(canvas);
    }
  }

  bool get _hasActiveEffects =>
      _movements.isNotEmpty || _combatPool.any((effect) => effect.active);

  void _notifyActivity() => onActivityChanged?.call(_hasActiveEffects);
}

final class _ActiveUnitMovement {
  _ActiveUnitMovement({
    required this.unit,
    required this.start,
    required this.target,
  });

  final MapUnitComponent unit;
  final ui.Offset start;
  final ui.Offset target;
  var elapsed = 0.0;
}
