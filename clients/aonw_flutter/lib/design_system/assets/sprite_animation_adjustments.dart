import 'dart:convert';

import 'package:flutter/services.dart';

import 'sprite_frame_adjustment.dart';
import 'sprite_frame_id.dart';

final class SpriteAnimationAdjustments {
  const SpriteAnimationAdjustments._(this._frames, this._durations);
  static const empty = SpriteAnimationAdjustments._({}, {});
  static const assetPath =
      'assets/runtime/metadata/animation_frame_adjustments.json';
  static Future<SpriteAnimationAdjustments>? _pending;

  final Map<String, SpriteFrameAdjustment> _frames;
  final Map<String, double> _durations;

  static Future<SpriteAnimationAdjustments> load() => _pending ??= _read();

  static Future<SpriteAnimationAdjustments> _read() async =>
      SpriteAnimationAdjustments.fromJson(
        jsonDecode(await rootBundle.loadString(assetPath)),
      );

  factory SpriteAnimationAdjustments.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 2) {
      throw const FormatException('Unsupported sprite animation adjustments');
    }
    final frames = value['frames'] as Map<String, dynamic>;
    final animations = value['animations'] as Map<String, dynamic>? ?? {};
    return SpriteAnimationAdjustments._(
      Map.unmodifiable({
        for (final entry in frames.entries)
          entry.key: SpriteFrameAdjustment.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      }),
      Map.unmodifiable({
        for (final entry in animations.entries)
          entry.key: _duration(entry.value),
      }),
    );
  }

  SpriteFrameAdjustment forFrame(SpriteSequenceId sequence, int index) =>
      _frames['${sequence.value}|$index'] ?? const SpriteFrameAdjustment();

  double frameDuration(SpriteSequenceId sequence, double fallback) =>
      _durations[sequence.value] ?? fallback;

  static double _duration(Object? value) {
    final number = value is Map ? value['frameDuration'] : value;
    if (number is! num || !number.isFinite || number <= 0) {
      throw const FormatException('Invalid sprite animation frame duration');
    }
    return number.toDouble();
  }
}
