import 'dart:async';
import 'dart:math';

import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/audio/infrastructure/audio_asset_catalog.dart';
import 'package:aonw_flutter/features/audio/infrastructure/game_audio_runtime.dart';
import 'package:aonw_flutter/features/settings/application/client_audio_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_audio_device.dart';

void main() {
  test(
    'suspension cancels queued cues even after an immediate resume',
    () async {
      final gate = Completer<void>();
      final device = FakeAudioDevice()..preparationGate = gate.future;
      final runtime = GameAudioRuntime(device: device);
      addTearDown(runtime.dispose);
      final start = runtime.configure(
        const ClientAudioSettings(),
        active: true,
        mapActive: false,
      );
      await device.preparationStarted.future;
      final sound = runtime.play(GameSoundCue.attack);
      final pause = runtime.configure(
        const ClientAudioSettings(),
        active: false,
        mapActive: false,
      );
      final resume = runtime.configure(
        const ClientAudioSettings(),
        active: true,
        mapActive: false,
      );
      gate.complete();
      await Future.wait([start, sound, pause, resume]);
      expect(runtime.debugMusicAsset, isNotNull);
      expect(runtime.debugActiveEffectCount, 0);
      expect(
        device.voices
            .where((voice) => voice.asset!.endsWith('attack.wav'))
            .every((voice) => voice.starts == 0),
        isTrue,
      );
    },
  );

  test(
    'failed stops dispose affected voices and still silence every channel',
    () async {
      final device = FakeAudioDevice();
      final errors = <String>[];
      final runtime = GameAudioRuntime(
        device: device,
        reportError: (operation, _, _) => errors.add(operation),
      );
      addTearDown(runtime.dispose);
      await runtime.configure(
        const ClientAudioSettings(),
        active: true,
        mapActive: true,
      );
      await runtime.play(GameSoundCue.attack);
      await runtime.play(GameSoundCue.menuBack);
      final music = device.voices.first..failStop = true;
      final attack = device.voices.firstWhere(
        (voice) => voice.asset!.endsWith('attack.wav'),
      )..failStop = true;
      await runtime.configure(
        const ClientAudioSettings(),
        active: false,
        mapActive: true,
      );
      expect(music.disposed, isTrue);
      expect(attack.disposed, isTrue);
      expect(device.voices.any((voice) => voice.playing), isFalse);
      expect(errors, hasLength(2));
      await runtime.configure(
        const ClientAudioSettings(),
        active: true,
        mapActive: true,
      );
      expect(runtime.debugMusicAsset, isNotNull);
      expect(runtime.debugNatureAsset, isNotNull);
    },
  );

  test('cycles every music track and keeps nature tied to the map', () async {
    final device = FakeAudioDevice();
    final runtime = GameAudioRuntime(device: device, random: Random(7));
    addTearDown(runtime.dispose);
    await runtime.configure(
      const ClientAudioSettings(),
      active: true,
      mapActive: false,
    );
    expect(device.voices, hasLength(21));
    final music = device.voices.first;
    final first = music.asset;
    final played = <String>{};
    for (var index = 0; index < 8; index++) {
      played.add(runtime.debugMusicAsset!);
      music.complete();
      await runtime.debugSettled;
    }
    expect(played, AudioAssetCatalog.music.toSet());
    expect(runtime.debugMusicAsset, first);
    expect(runtime.debugNatureAsset, isNull);
    expect(music.volume, 0.2);
    await runtime.configure(
      const ClientAudioSettings(),
      active: true,
      mapActive: true,
    );
    final nature = device.voices.last;
    expect(runtime.debugNatureAsset, AudioAssetCatalog.nature.single);
    expect(nature.volume, 0.4);
    nature.complete();
    await runtime.debugSettled;
    expect(nature.starts, 2);
    await runtime.configure(
      const ClientAudioSettings(),
      active: true,
      mapActive: false,
    );
    expect(nature.playing, isFalse);
    expect(music.playing, isTrue);
    expect(music.starts, 9);
    expect(device.voices, hasLength(22));
  });

  test('applies live levels and stops every channel while suspended', () async {
    final device = FakeAudioDevice();
    final runtime = GameAudioRuntime(device: device);
    addTearDown(runtime.dispose);
    await runtime.configure(
      const ClientAudioSettings(),
      active: true,
      mapActive: true,
    );
    await runtime.play(GameSoundCue.attack);
    final music = device.voices.first;
    const changed = ClientAudioSettings(
      soundVolume: 0.55,
      musicVolume: 0.65,
      natureVolume: 0.75,
    );
    await runtime.configure(changed, active: true, mapActive: true);
    expect(music.volume, 0.65);
    expect(music.starts, 1);
    expect(
      device.voices
          .where((voice) => voice.asset!.endsWith('attack.wav'))
          .first
          .volume,
      0.55,
    );
    await runtime.configure(changed, active: false, mapActive: true);
    expect(device.voices.any((voice) => voice.playing), isFalse);
    expect(runtime.debugActiveEffectCount, 0);
    await runtime.play(GameSoundCue.attack);
    expect(device.voices.any((voice) => voice.playing), isFalse);
    await runtime.configure(changed, active: true, mapActive: true);
    expect(music.starts, 2);
    expect(device.focus.last, isTrue);
    await runtime.configure(
      changed.copyWith(musicEnabled: false),
      active: true,
      mapActive: true,
    );
    expect(runtime.debugMusicAsset, isNull);
    expect(runtime.debugNatureAsset, isNotNull);
    expect(device.focus.last, isFalse);
  });

  test('shares aliased cues and bounds concurrent voices per sound', () async {
    final device = FakeAudioDevice();
    final runtime = GameAudioRuntime(device: device);
    addTearDown(runtime.dispose);
    await runtime.configure(
      const ClientAudioSettings(musicEnabled: false),
      active: true,
      mapActive: false,
    );
    await runtime.play(GameSoundCue.uiPanelClose);
    await runtime.play(GameSoundCue.menuBack);
    final back = device.voices
        .where((voice) => voice.asset!.endsWith('menu_back.wav'))
        .toList();
    expect(back, hasLength(2));
    expect(back.every((voice) => voice.playing), isTrue);
    for (var index = 0; index < 7; index++) {
      await runtime.play(GameSoundCue.attack);
    }
    final attacks = device.voices
        .where((voice) => voice.asset!.endsWith('attack.wav'))
        .toList();
    expect(attacks, hasLength(6));
    expect(runtime.debugActiveEffectCount, 8);
    attacks.first.complete();
    await runtime.play(GameSoundCue.attack);
    expect(attacks.first.starts, 2);
    expect(device.voices, hasLength(24));
    await runtime.configure(
      const ClientAudioSettings(soundsEnabled: false, musicEnabled: false),
      active: true,
      mapActive: false,
    );
    expect(runtime.debugActiveEffectCount, 0);
    expect(device.voices.any((voice) => voice.playing), isFalse);
  });

  for (final action in ['mute', 'suspend', 'dispose']) {
    test('$action while a track loads prevents late playback', () async {
      final gate = Completer<void>();
      final device = FakeAudioDevice()..preparationGate = gate.future;
      final runtime = GameAudioRuntime(device: device);
      addTearDown(runtime.dispose);
      final pending = runtime.configure(
        const ClientAudioSettings(),
        active: true,
        mapActive: false,
      );
      await device.preparationStarted.future;
      final stopped = switch (action) {
        'dispose' => runtime.dispose(),
        'suspend' => runtime.configure(
          const ClientAudioSettings(),
          active: false,
          mapActive: false,
        ),
        _ => runtime.configure(
          const ClientAudioSettings(musicEnabled: false, soundsEnabled: false),
          active: true,
          mapActive: false,
        ),
      };
      gate.complete();
      await Future.wait([pending, stopped]);
      expect(device.voices.every((voice) => voice.starts == 0), isTrue);
      expect(runtime.debugMusicAsset, isNull);
      await runtime.dispose();
      expect(device.voices.every((voice) => voice.disposed), isTrue);
      expect(device.disposed, isTrue);
    });
  }

  test(
    'a failed track releases its voice while other channels continue',
    () async {
      final device = FakeAudioDevice()
        ..failedAssets.addAll(AudioAssetCatalog.music);
      final errors = <String>[];
      final runtime = GameAudioRuntime(
        device: device,
        reportError: (operation, _, _) => errors.add(operation),
      );
      addTearDown(runtime.dispose);
      await runtime.configure(
        const ClientAudioSettings(),
        active: true,
        mapActive: true,
      );
      expect(runtime.debugMusicAsset, isNull);
      expect(runtime.debugNatureAsset, isNotNull);
      expect(device.voices.first.disposed, isTrue);
      expect(errors, ['configure music']);
      await runtime.configure(
        const ClientAudioSettings(),
        active: true,
        mapActive: true,
      );
      expect(errors, hasLength(1));
      device.failedAssets.clear();
      await runtime.configure(
        const ClientAudioSettings(),
        active: true,
        mapActive: true,
      );
      expect(runtime.debugMusicAsset, isNotNull);
      device.failNextResume = true;
      await runtime.play(GameSoundCue.attack);
      expect(errors.last, 'play attack');
      await runtime.play(GameSoundCue.attack);
      expect(runtime.debugActiveEffectCount, 1);
      await runtime.dispose();
      expect(device.voices.every((voice) => voice.disposed), isTrue);
    },
  );
}
