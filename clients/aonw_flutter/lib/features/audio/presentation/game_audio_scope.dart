import 'package:flutter/widgets.dart';

import '../application/game_audio_port.dart';

abstract interface class GameAudioSession {
  void play(GameSoundCue cue);
  VoidCallback acquireMap();
}

final class GameAudioScope extends InheritedWidget {
  const GameAudioScope({
    required this.session,
    required super.child,
    super.key,
  });

  final GameAudioSession session;

  static GameAudioSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameAudioScope>()?.session;

  @override
  bool updateShouldNotify(GameAudioScope oldWidget) =>
      oldWidget.session != session;
}

final class GameAudioMap extends StatefulWidget {
  const GameAudioMap({required this.child, super.key});

  final Widget child;

  @override
  State<GameAudioMap> createState() => _GameAudioMapState();
}

final class _GameAudioMapState extends State<GameAudioMap> {
  GameAudioSession? _session;
  VoidCallback? _release;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = GameAudioScope.maybeOf(context);
    if (_session == session) return;
    _release?.call();
    _session = session;
    _release = session?.acquireMap();
  }

  @override
  void dispose() {
    _release?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
