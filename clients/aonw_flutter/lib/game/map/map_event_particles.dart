import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';

import '../../features/map/read_model/map_feedback_view.dart';
import 'map_canvas_clip.dart';

/// One reusable burst with the geometry and timing of map event feedback.
final class MapEventParticleBurst {
  final _particles = <_Particle>[];
  final _paint = ui.Paint()
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.2);
  MapParticleKindView _kind = MapParticleKindView.cityFounded;
  ui.Offset _center = ui.Offset.zero;
  ui.Color _color = const ui.Color(0x00000000);
  double _duration = 0;
  double elapsed = 0;
  MapParticleCueView? cue;

  bool get active => _particles.isNotEmpty;
  int get particleCount => _particles.length;

  void start(MapParticleCueView cue, ui.Offset center) {
    clear();
    this.cue = cue;
    _kind = cue.kind;
    _center = center.translate(0, -10);
    final color = ui.Color(cue.colorValue);
    _color = switch (_kind) {
      MapParticleKindView.technologyResearched => const ui.Color(0xffd2a856),
      MapParticleKindView.unitProduced => ui.Color.lerp(
        color,
        const ui.Color(0xfff8f2e4),
        0.35,
      )!,
      _ => color,
    };
    final (count, duration) = switch (_kind) {
      MapParticleKindView.cityFounded => (36, 1.35),
      MapParticleKindView.unitProduced => (18, 0.7),
      MapParticleKindView.hexClaimed => (24, 0.95),
      MapParticleKindView.technologyResearched => (32, 1.45),
    };
    _duration = duration;
    final random = math.Random(
      cue.identity.revision * 397 ^ cue.identity.eventIndex,
    );
    for (var index = 0; index < count; index++) {
      _particles.add(_particle(_kind, random));
    }
  }

  void clear() {
    _particles.clear();
    elapsed = 0;
    cue = null;
  }

  void update(double dt) {
    if (!active) return;
    elapsed += dt;
    if (elapsed >= _duration) clear();
  }

  void render(ui.Canvas canvas) {
    if (!active ||
        !mapCanvasClipBounds(
          canvas,
        ).overlaps(ui.Rect.fromCircle(center: _center, radius: 300))) {
      return;
    }
    final progress = (elapsed / _duration).clamp(0.0, 1.0);
    _paint.color = _color.withAlpha(((1 - progress) * 220).round());
    for (final particle in _particles) {
      final offset = switch (_kind) {
        MapParticleKindView.hexClaimed =>
          particle.velocity * Curves.easeOutCubic.transform(progress),
        MapParticleKindView.unitProduced =>
          particle.velocity * Curves.easeOutBack.transform(progress),
        _ =>
          particle.velocity * elapsed +
              ui.Offset(0, particle.gravity * elapsed * elapsed / 2),
      };
      canvas.drawCircle(
        _center + particle.origin + offset,
        (particle.radius * (1 + progress) * 4).round() / 4,
        _paint,
      );
    }
  }
}

_Particle _particle(MapParticleKindView kind, math.Random random) {
  if (kind == MapParticleKindView.technologyResearched) {
    final origin = ui.Offset(
      -28 + random.nextDouble() * 56,
      -46 - random.nextDouble() * 28,
    );
    final speedY = 35 + random.nextDouble() * 55;
    return _Particle(
      origin,
      ui.Offset(-12 + random.nextDouble() * 24, speedY),
      38,
      1.8 + random.nextDouble() * 2,
    );
  }
  final angle = random.nextDouble() * math.pi * 2;
  return switch (kind) {
    MapParticleKindView.cityFounded => _foundedParticle(angle, random),
    MapParticleKindView.hexClaimed => _Particle(
      ui.Offset.zero,
      ui.Offset(
        math.cos(angle) * (16 + random.nextDouble() * 28),
        math.sin(angle) * 12,
      ),
      0,
      2.1,
    ),
    MapParticleKindView.unitProduced => _producedParticle(angle, random),
    MapParticleKindView.technologyResearched => throw StateError(
      'Research particles were handled above.',
    ),
  };
}

_Particle _foundedParticle(double angle, math.Random random) {
  final speed = 55 + random.nextDouble() * 85;
  return _Particle(
    ui.Offset.zero,
    ui.Offset(math.cos(angle) * speed, math.sin(angle) * speed - 35),
    95,
    2.2 + random.nextDouble() * 2.6,
  );
}

_Particle _producedParticle(double angle, math.Random random) {
  final distance = 10 + random.nextDouble() * 20;
  return _Particle(
    ui.Offset.zero,
    ui.Offset(math.cos(angle) * distance, math.sin(angle) * distance),
    0,
    1.6 + random.nextDouble() * 1.4,
  );
}

final class _Particle {
  const _Particle(this.origin, this.velocity, this.gravity, this.radius);
  final ui.Offset origin;
  final ui.Offset velocity;
  final double gravity;
  final double radius;
}
