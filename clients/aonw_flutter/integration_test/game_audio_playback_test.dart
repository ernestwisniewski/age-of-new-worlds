import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/audio/infrastructure/audioplayers_device.dart';
import 'package:aonw_flutter/features/audio/infrastructure/game_audio_runtime.dart';
import 'package:aonw_flutter/features/audio/presentation/game_audio_host.dart';
import 'package:aonw_flutter/features/audio/presentation/game_audio_scope.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plays all audio channels and releases native voices and cache', (
    tester,
  ) async {
    final rssBefore = ProcessInfo.currentRss;
    final device = AudioplayersDevice();
    final errors = <String>[];
    final runtime = GameAudioRuntime(
      device: device,
      random: Random(4),
      reportError: (operation, error, _) => errors.add('$operation: $error'),
    );
    addTearDown(runtime.dispose);
    final settings = ClientSettingsController.ephemeral();
    addTearDown(settings.dispose);
    await settings.update(
      ClientSettings.defaults.copyWith(
        audio: const ClientAudioSettings(
          soundVolume: 0.02,
          musicVolume: 0.02,
          natureVolume: 0.02,
        ),
      ),
    );
    final ready = Future<void>.value();
    Widget host(bool map) => GameAudioHost(
      audio: runtime,
      settings: settings,
      settingsReady: ready,
      child: map
          ? const GameAudioMap(child: SizedBox.shrink())
          : const SizedBox.shrink(),
    );
    await tester.pumpWidget(host(false));
    await runtime.debugSettled;
    await tester.pump();
    await runtime.debugSettled;
    expect(errors, isEmpty);
    expect(runtime.debugMusicAsset, isNotNull);
    expect(runtime.debugNatureAsset, isNull);
    expect(device.debugVoiceCount, 21);
    await tester.pump(const Duration(milliseconds: 350));
    final positions = await device.debugPositions();
    expect(
      positions.any((position) => position != null && position > Duration.zero),
      isTrue,
    );
    final music = runtime.debugMusicAsset;
    await tester.pumpWidget(host(true));
    await runtime.debugSettled;
    expect(runtime.debugMusicAsset, music);
    expect(runtime.debugNatureAsset, isNotNull);
    expect(device.debugVoiceCount, 22);
    for (final cue in GameSoundCue.values) {
      await runtime.play(cue);
    }
    expect(runtime.debugActiveEffectCount, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await runtime.debugSettled;
    expect(runtime.debugMusicAsset, isNull);
    expect(runtime.debugNatureAsset, isNull);
    expect(runtime.debugActiveEffectCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await runtime.debugSettled;
    expect(runtime.debugMusicAsset, music);
    expect(runtime.debugNatureAsset, isNotNull);
    await tester.pumpWidget(host(false));
    await runtime.debugSettled;
    expect(runtime.debugNatureAsset, isNull);
    expect(runtime.debugMusicAsset, music);
    final rssDelta = ProcessInfo.currentRss - rssBefore;
    final cached = device.debugCachedAssetCount;
    await tester.pumpWidget(const SizedBox.shrink());
    await runtime.dispose();
    expect(device.debugVoiceCount, 0);
    expect(device.debugCachedAssetCount, 0);
    expect(errors, isEmpty);
    final record = {
      'schemaVersion': 1,
      'capturedAt': DateTime.now().toUtc().toIso8601String(),
      'cachedAssets': cached,
      'nativePositionAdvanced': true,
      'playedCues': GameSoundCue.values.length,
      'nativeVoicesReleased': true,
      'audioCacheReleased': true,
      'residentMemoryDeltaBytes': rssDelta,
    };
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['gameAudioPlayback'] = record;
    // ignore: avoid_print
    print('AONW_GAME_AUDIO_PLAYBACK ${jsonEncode(record)}');
    expect(rssDelta, lessThanOrEqualTo(192 * 1024 * 1024));
  });
}
