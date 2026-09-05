import 'dart:async';

import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/audio/presentation/game_audio_host.dart';
import 'package:aonw_flutter/features/audio/presentation/game_audio_scope.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'waits for stored settings and follows map ownership and lifecycle',
    (tester) async {
      final settings = ClientSettingsController.ephemeral();
      addTearDown(settings.dispose);
      await settings.update(
        ClientSettings.defaults.copyWith(
          audio: const ClientAudioSettings(musicEnabled: false),
        ),
      );
      final ready = Completer<void>();
      final audio = _Audio();
      final navigator = GlobalKey<NavigatorState>();
      late GameAudioSession session;
      await tester.pumpWidget(
        GameAudioHost(
          audio: audio,
          settings: settings,
          settingsReady: ready.future,
          child: MaterialApp(
            navigatorKey: navigator,
            home: Builder(
              builder: (context) {
                session = GameAudioScope.maybeOf(context)!;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(audio.configurations, isEmpty);
      session.play(GameSoundCue.menuClick);
      expect(audio.cues, isEmpty);
      ready.complete();
      await tester.pump();
      expect(audio.configurations.single, (
        settings.settings.audio,
        true,
        false,
      ));
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const GameAudioMap(child: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(audio.configurations.last.$3, isTrue);
      final release = session.acquireMap();
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(audio.configurations.last.$3, isTrue);
      release();
      release();
      expect(audio.configurations.last.$3, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(audio.configurations.last.$2, isFalse);
      session.play(GameSoundCue.attack);
      expect(audio.cues, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      session.play(GameSoundCue.menuBack);
      expect(audio.cues, [GameSoundCue.menuBack]);
      await settings.update(
        ClientSettings.defaults.copyWith(
          audio: const ClientAudioSettings(natureVolume: 0.7),
        ),
      );
      expect(audio.configurations.last.$1.natureVolume, 0.7);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(audio.disposals, 1);
    },
  );

  testWidgets('finishes disposal before handing audio to a replacement', (
    tester,
  ) async {
    final settings = ClientSettingsController.ephemeral();
    addTearDown(settings.dispose);
    final disposal = Completer<void>();
    final first = _Audio()..disposal = disposal.future;
    final second = _Audio();
    final ready = Future<void>.value();
    Widget host(_Audio audio) => GameAudioHost(
      audio: audio,
      settings: settings,
      settingsReady: ready,
      child: const GameAudioMap(child: SizedBox.shrink()),
    );
    await tester.pumpWidget(host(first));
    await tester.pump();
    expect(first.configurations.single.$3, isTrue);
    await tester.pumpWidget(host(second));
    expect(first.disposals, 1);
    expect(second.configurations, isEmpty);
    disposal.complete();
    await tester.pump();
    expect(second.configurations.single.$3, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.disposals, 1);
  });

  testWidgets('unmount during settings load never starts audio afterwards', (
    tester,
  ) async {
    final settings = ClientSettingsController.ephemeral();
    addTearDown(settings.dispose);
    final ready = Completer<void>();
    final audio = _Audio();
    await tester.pumpWidget(
      GameAudioHost(
        audio: audio,
        settings: settings,
        settingsReady: ready.future,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    ready.complete();
    await tester.pump();
    expect(audio.configurations, isEmpty);
    expect(audio.disposals, 1);
  });
}

final class _Audio implements GameAudioPort {
  final configurations = <(ClientAudioSettings, bool, bool)>[];
  final cues = <GameSoundCue>[];
  int disposals = 0;
  Future<void>? disposal;

  @override
  Future<void> configure(
    ClientAudioSettings settings, {
    required bool active,
    required bool mapActive,
  }) async => configurations.add((settings, active, mapActive));

  @override
  Future<void> play(GameSoundCue cue) async => cues.add(cue);

  @override
  Future<void> dispose() async {
    disposals++;
    await disposal;
  }
}
