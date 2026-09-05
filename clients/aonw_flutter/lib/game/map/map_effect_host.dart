import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/aonw_tokens.dart';
import '../presentation/flame_scene_patch.dart';
import 'gameplay_map_layers.dart';
import 'map_interaction_geometry.dart';
import 'static_map_layers.dart';

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
      effect.start(
        attackerCenter: mapProjectedTopFaceCenter(cache, combat.attacker),
        defenderCenter: mapProjectedTopFaceCenter(cache, combat.defender),
        attackerPath: mapProjectedTopFacePath(
          cache,
          combat.attacker,
          scale: 0.98,
        ),
        defenderPath: mapProjectedTopFacePath(
          cache,
          combat.defender,
          scale: 0.98,
        ),
        reducedMotion: _reducedMotion,
      );
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
      combat.reducedMotion = enabled;
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
      combat.render(canvas);
    }
  }

  bool get _hasActiveEffects =>
      _movements.isNotEmpty || _combatPool.any((effect) => effect.active);

  void _notifyActivity() => onActivityChanged?.call(_hasActiveEffects);
}

final class _ActiveCombatIntent {
  var active = false;
  var attackerCenter = ui.Offset.zero;
  var defenderCenter = ui.Offset.zero;
  var attackerPath = ui.Path();
  var defenderPath = ui.Path();
  var reducedMotion = false;
  var elapsed = 0.0;
  final _curve = ui.Path();
  final _dash = ui.Path();
  var _control = ui.Offset.zero;
  final _threadPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.65
    ..strokeCap = ui.StrokeCap.round
    ..color = AonwColorTokens.danger.withAlpha(238);
  final _dashPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.15
    ..strokeCap = ui.StrokeCap.round
    ..color = AonwColorTokens.textBright;
  final _attackerFillPaint = ui.Paint()..style = ui.PaintingStyle.fill;
  final _attackerBloomPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeJoin = ui.StrokeJoin.round
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6.4);
  final _defenderGlowPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeJoin = ui.StrokeJoin.round
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.2);
  final _defenderStrokePaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;

  void start({
    required ui.Offset attackerCenter,
    required ui.Offset defenderCenter,
    required ui.Path attackerPath,
    required ui.Path defenderPath,
    required bool reducedMotion,
  }) {
    active = true;
    this.attackerCenter = attackerCenter;
    this.defenderCenter = defenderCenter;
    this.attackerPath = attackerPath;
    this.defenderPath = defenderPath;
    this.reducedMotion = reducedMotion;
    elapsed = 0;
    _rebuildCurve();
  }

  void complete() {
    active = false;
    elapsed = 0;
  }

  double get pulse {
    if (reducedMotion) return 0.55;
    final radians = (elapsed / 0.92) * math.pi * 2;
    return (0.5 + math.sin(radians) * 0.5).clamp(0.0, 1.0);
  }

  void render(ui.Canvas canvas) {
    _rebuildDash();
    canvas
      ..drawPath(_curve, _threadPaint)
      ..drawPath(_dash, _dashPaint);
    _renderAttackerAlert(canvas);
    _renderDefenderAlert(canvas);
  }

  void _renderAttackerAlert(ui.Canvas canvas) {
    final value = pulse;
    final coreAlpha = reducedMotion ? 60 : (60 + value * 26).round();
    final glowAlpha = reducedMotion ? 60 : (30 + value * 28).round();
    final bounds = attackerPath.getBounds();
    _attackerFillPaint.shader = ui.Gradient.radial(
      attackerCenter,
      math.max(bounds.width, bounds.height) / 2,
      [
        AonwColorTokens.danger.withAlpha(coreAlpha),
        AonwColorTokens.danger.withAlpha(30),
        AonwColorTokens.danger.withAlpha(0),
      ],
      const [0, 0.48, 1],
    );
    _attackerBloomPaint
      ..strokeWidth = 11 + value * 2.8
      ..color = AonwColorTokens.danger.withAlpha(glowAlpha);
    canvas
      ..save()
      ..clipPath(attackerPath)
      ..drawPath(attackerPath, _attackerFillPaint)
      ..drawPath(attackerPath, _attackerBloomPaint)
      ..restore();
  }

  void _renderDefenderAlert(ui.Canvas canvas) {
    final value = pulse;
    final glowAlpha = reducedMotion ? 90 : (60 + value * 130).round();
    final strokeAlpha = reducedMotion ? 180 : (130 + value * 125).round();
    _defenderGlowPaint
      ..strokeWidth = 6.2 + value * 2
      ..color = AonwColorTokens.danger.withAlpha(glowAlpha);
    _defenderStrokePaint
      ..strokeWidth = reducedMotion ? 2 : 2.8 + value * 1.15
      ..color = AonwColorTokens.danger.withAlpha(strokeAlpha);
    canvas
      ..drawPath(defenderPath, _defenderGlowPaint)
      ..drawPath(defenderPath, _defenderStrokePaint);
  }

  void _rebuildCurve() {
    final delta = defenderCenter - attackerCenter;
    final distance = delta.distance;
    final bend = math.min(30.0, math.max(8.0, distance * 0.13));
    final perpendicular = distance <= 0.001
        ? const ui.Offset(0, -1)
        : ui.Offset(-delta.dy / distance, delta.dx / distance);
    _control = (attackerCenter + defenderCenter) / 2 + perpendicular * bend;
    _curve
      ..reset()
      ..moveTo(attackerCenter.dx, attackerCenter.dy)
      ..quadraticBezierTo(
        _control.dx,
        _control.dy,
        defenderCenter.dx,
        defenderCenter.dy,
      );
  }

  void _rebuildDash() {
    final progress = reducedMotion ? 0.72 : (elapsed / 0.82) % 1;
    final inverse = 1 - progress;
    final point =
        attackerCenter * (inverse * inverse) +
        _control * (2 * inverse * progress) +
        defenderCenter * (progress * progress);
    final tangent =
        (_control - attackerCenter) * (2 * inverse) +
        (defenderCenter - _control) * (2 * progress);
    final half = tangent.distance <= 0.001
        ? const ui.Offset(5, 0)
        : tangent * (5 / tangent.distance);
    _dash
      ..reset()
      ..moveTo(point.dx - half.dx, point.dy - half.dy)
      ..lineTo(point.dx + half.dx, point.dy + half.dy);
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
