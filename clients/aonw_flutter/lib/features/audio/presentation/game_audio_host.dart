import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../settings/presentation/client_settings_controller.dart';
import '../application/game_audio_port.dart';
import 'game_audio_scope.dart';

final class GameAudioHost extends StatefulWidget {
  const GameAudioHost({
    required this.settings,
    required this.settingsReady,
    required this.child,
    this.audio,
    super.key,
  });

  final ClientSettingsController settings;
  final Future<void> settingsReady;
  final GameAudioPort? audio;
  final Widget child;

  @override
  State<GameAudioHost> createState() => _GameAudioHostState();
}

final class _GameAudioHostState extends State<GameAudioHost>
    with WidgetsBindingObserver
    implements GameAudioSession {
  var _ready = false;
  var _active = true;
  var _maps = 0;
  var _generation = 0;
  Future<void> _handover = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _active =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
    widget.settings.addListener(_configure);
    _awaitSettings();
  }

  @override
  void didUpdateWidget(GameAudioHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio != widget.audio) {
      _handover = Future.wait([_handover, ?oldWidget.audio?.dispose()]);
    }
    if (oldWidget.settings != widget.settings) {
      oldWidget.settings.removeListener(_configure);
      widget.settings.addListener(_configure);
    }
    if (oldWidget.settingsReady != widget.settingsReady ||
        oldWidget.audio != widget.audio) {
      _awaitSettings();
    } else {
      _configure();
    }
  }

  void _awaitSettings() {
    _ready = false;
    final generation = ++_generation;
    unawaited(
      Future.wait([widget.settingsReady, _handover]).then(
        (_) {
          if (!mounted || generation != _generation) return;
          _ready = true;
          _configure();
        },
        onError: (Object error, StackTrace stack) {
          if (!mounted || generation != _generation) return;
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'AoNW audio',
              context: ErrorDescription('while preparing audio settings'),
            ),
          );
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _configure();
  }

  void _configure() {
    if (!_ready || !mounted) return;
    unawaited(
      widget.audio?.configure(
        widget.settings.settings.audio,
        active: _active,
        mapActive: _maps > 0,
      ),
    );
  }

  @override
  void play(GameSoundCue cue) {
    if (_ready && _active && mounted) unawaited(widget.audio?.play(cue));
  }

  @override
  VoidCallback acquireMap() {
    _maps++;
    _configure();
    var released = false;
    return () {
      if (released) return;
      released = true;
      _maps--;
      _configure();
    };
  }

  @override
  void dispose() {
    _generation++;
    _ready = false;
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_configure);
    unawaited(widget.audio?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      GameAudioScope(session: this, child: widget.child);
}
