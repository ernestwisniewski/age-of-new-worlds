import 'package:flutter/foundation.dart';

@immutable
final class SpriteFrameId {
  const SpriteFrameId(this.value) : assert(value != '');

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpriteFrameId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

@immutable
final class SpriteSequenceId {
  const SpriteSequenceId(this.value) : assert(value != '');

  final String value;

  SpriteFrameId frame(int index) => SpriteFrameId('$value.$index');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpriteSequenceId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
