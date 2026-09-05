import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../design_system/aonw_tokens.dart';

/// Transient presentation of accepted damage and destruction evidence.
final class MapCombatFeedback {
  final _attackerLabel = _DamageLabel();
  final _defenderLabel = _DamageLabel();
  final _particles = <_CombatParticle>[];
  final _particlePaint = ui.Paint()
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.2);

  int get labelCount => _attackerLabel.count + _defenderLabel.count;
  int get particleCount => _particles.length;

  int activeParticleCount(double elapsed) =>
      _particles.where((particle) => elapsed < particle.lifespan).length;

  void start({
    required ui.Offset attacker,
    required ui.Offset defender,
    required int outgoingDamage,
    required int retaliationDamage,
    required bool attackerKilled,
    required bool defenderKilled,
    required bool defenderIsCity,
    required int seed,
    bool reducedMotion = false,
  }) {
    _attackerLabel.setDamage(retaliationDamage, attacker.translate(0, -28));
    _defenderLabel.setDamage(outgoingDamage, defender.translate(0, -28));
    _particles.clear();
    if (reducedMotion) return;
    final random = math.Random(seed);
    if (attackerKilled) _addBurst(attacker, random, city: false);
    if (defenderIsCity && outgoingDamage > 0) {
      _addBurst(defender, random, city: true);
    } else if (defenderKilled) {
      _addBurst(defender, random, city: false);
    }
  }

  void clearParticles() => _particles.clear();

  void clear() {
    _attackerLabel.clear();
    _defenderLabel.clear();
    clearParticles();
  }

  void dispose() {
    _attackerLabel.dispose();
    _defenderLabel.dispose();
    clearParticles();
  }

  void render(ui.Canvas canvas, double elapsed, {required bool reducedMotion}) {
    if (!reducedMotion) _renderParticles(canvas, elapsed);
    if (elapsed >= 1.08) return;
    _attackerLabel.render(canvas, elapsed, reducedMotion: reducedMotion);
    _defenderLabel.render(canvas, elapsed, reducedMotion: reducedMotion);
  }

  void _addBurst(ui.Offset center, math.Random random, {required bool city}) {
    for (var index = 0; index < (city ? 34 : 28); index++) {
      _particles.add(_CombatParticle.generate(center, random, city: city));
    }
  }

  void _renderParticles(ui.Canvas canvas, double elapsed) {
    for (final particle in _particles) {
      if (elapsed >= particle.lifespan) continue;
      final progress = (elapsed / particle.lifespan).clamp(0.0, 1.0);
      final position =
          particle.origin +
          particle.velocity * elapsed +
          ui.Offset(0, particle.gravity * elapsed * elapsed / 2);
      _particlePaint.color = particle.color.withValues(alpha: 1 - progress);
      canvas.drawCircle(
        position,
        (particle.radius * (1 + progress) * 4).round() / 4,
        _particlePaint,
      );
    }
  }
}

final class _DamageLabel {
  static const _rasterScale = 3.0;
  static const _padding = 6.0;
  ui.Image? _image;
  ui.Size _textSize = ui.Size.zero;
  int? _damage;
  var _active = false;
  ui.Offset _position = ui.Offset.zero;
  final _opacityPaint = ui.Paint()..filterQuality = ui.FilterQuality.medium;

  int get count => _active ? 1 : 0;

  void setDamage(int damage, ui.Offset position) {
    clear();
    if (damage <= 0) return;
    _position = position;
    _active = true;
    if (_damage == damage) return;
    _image?.dispose();
    _damage = damage;
    final text = TextPainter(
      text: TextSpan(
        text: '-$damage HP',
        style: const TextStyle(
          color: ui.Color(0xfff87171),
          fontSize: 15,
          fontFamily: AonwTypography.bodyFamily,
          fontWeight: ui.FontWeight.w900,
          shadows: [
            ui.Shadow(
              color: ui.Color(0xbf000000),
              offset: ui.Offset(0, 1.5),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    _textSize = text.size;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(_rasterScale);
    text.paint(canvas, const ui.Offset(_padding, _padding));
    final picture = recorder.endRecording();
    _image = picture.toImageSync(
      ((_textSize.width + _padding * 2) * _rasterScale).ceil(),
      ((_textSize.height + _padding * 2) * _rasterScale).ceil(),
    );
    picture.dispose();
    text.dispose();
  }

  void clear() => _active = false;

  void dispose() {
    clear();
    _image?.dispose();
    _image = null;
    _damage = null;
  }

  void render(ui.Canvas canvas, double elapsed, {required bool reducedMotion}) {
    final image = _image;
    if (!_active || image == null) return;
    final progress = (elapsed / 1.05).clamp(0.0, 1.0);
    final rise = reducedMotion ? 0.0 : -34 * (1 - math.pow(1 - progress, 3));
    final origin = _position.translate(
      -_textSize.width / 2 - _padding,
      -_textSize.height / 2 - _padding + rise,
    );
    final opacity = reducedMotion
        ? 1.0
        : (1 - (elapsed - 0.45) / 0.55).clamp(0.0, 1.0);
    _opacityPaint.color = const ui.Color(0xffffffff).withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(1 / _rasterScale)
      ..drawImage(image, ui.Offset.zero, _opacityPaint)
      ..restore();
  }
}

final class _CombatParticle {
  const _CombatParticle({
    required this.origin,
    required this.velocity,
    required this.gravity,
    required this.lifespan,
    required this.radius,
    required this.color,
  });

  factory _CombatParticle.generate(
    ui.Offset center,
    math.Random random, {
    required bool city,
  }) {
    final angle = city
        ? -math.pi * 0.9 + random.nextDouble() * math.pi * 0.8
        : random.nextDouble() * math.pi * 2;
    final speed = city
        ? 24 + random.nextDouble() * 82
        : 35 + random.nextDouble() * 70;
    final shade = 45 + random.nextInt(55);
    return _CombatParticle(
      origin: center.translate(
        city ? -12 + random.nextDouble() * 24 : 0,
        -10 + (city ? -8 + random.nextDouble() * 10 : 0),
      ),
      velocity: ui.Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed - (city ? 24 : 10),
      ),
      gravity: city ? 72 : -18,
      lifespan: city ? 1.05 : 0.85,
      radius: 2 + random.nextDouble() * (city ? 2.4 : 2.2),
      color: city
          ? ui.Color.lerp(
              const ui.Color(0xfff87171),
              AonwColorTokens.warning,
              0.28,
            )!
          : ui.Color.fromARGB(255, shade, shade, shade),
    );
  }

  final ui.Offset origin;
  final ui.Offset velocity;
  final double gravity;
  final double lifespan;
  final double radius;
  final ui.Color color;
}
