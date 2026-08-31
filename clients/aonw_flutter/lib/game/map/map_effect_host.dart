import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../presentation/flame_scene_patch.dart';
import 'gameplay_map_layers.dart';
import 'static_map_layers.dart';

typedef MapEffectActivitySink = void Function(bool active);

final class MapEffectHostComponent extends Component {
  MapEffectHostComponent({required MapUnitLayerComponent units})
    : _units = units,
      super(priority: 70);

  static const _movementDurationSeconds = 0.24;
  static const _combatDurationSeconds = 0.32;
  static const _maximumCombatEffects = 4;
  static final ui.Paint _combatPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 5;

  final MapUnitLayerComponent _units;
  final _movements = <String, _ActiveUnitMovement>{};
  final _combatPool = List.generate(
    _maximumCombatEffects,
    (_) => _ActiveCombatPulse(),
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
  int get debugMaximumCombatEffectCount => _maximumCombatEffects;

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
      final target = _units.centerFor(cache, movement.to);
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
    if (_reducedMotion) return;
    for (final combat in patch.combats) {
      final effect = _availableCombatEffect();
      if (effect == null) return;
      effect.start(_units.centerFor(cache, combat.defender));
    }
  }

  _ActiveCombatPulse? _availableCombatEffect() {
    for (final effect in _combatPool) {
      if (!effect.active) return effect;
    }
    return null;
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    if (enabled) skipAll();
  }

  void setPlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'must be finite and positive');
    }
    _playbackSpeed = speed;
  }

  void skipAll() {
    if (!_hasActiveEffects) return;
    for (final movement in _movements.values) {
      movement.unit.setVisualCenter(movement.target);
      _completedMovementCount += 1;
    }
    _movements.clear();
    _clearCombatEffects();
    _notifyActivity();
  }

  void clearEffects() {
    _movements.clear();
    _clearCombatEffects();
    _notifyActivity();
  }

  void _clearCombatEffects() {
    for (final combat in _combatPool) {
      combat.complete();
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
      final progress = (combat.elapsed / _combatDurationSeconds).clamp(
        0.0,
        1.0,
      );
      _combatPaint.color = ui.Color.fromARGB(
        ((1 - progress) * 220).round(),
        255,
        92,
        72,
      );
      canvas.drawCircle(combat.center, 18 + progress * 24, _combatPaint);
    }
  }

  bool get _hasActiveEffects =>
      _movements.isNotEmpty || _combatPool.any((effect) => effect.active);

  void _notifyActivity() => onActivityChanged?.call(_hasActiveEffects);
}

final class _ActiveCombatPulse {
  var active = false;
  var center = ui.Offset.zero;
  var elapsed = 0.0;

  void start(ui.Offset target) {
    active = true;
    center = target;
    elapsed = 0;
  }

  void complete() {
    active = false;
    elapsed = 0;
  }
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
