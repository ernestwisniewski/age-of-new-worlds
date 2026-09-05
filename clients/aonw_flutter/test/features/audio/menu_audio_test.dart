import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';
import '../../support/recording_game_audio.dart';

void main() {
  testWidgets('menu sounds follow enabled pointer actions and actual returns', (
    tester,
  ) async {
    final audio = await _openApp(tester);
    expect(audio.cues, isEmpty);
    await tester.tap(find.byKey(const ValueKey('multiplayer')));
    await tester.pumpAndSettle();
    expect(audio.cues, isEmpty);
    await _tap(tester, 'menu-settings');
    expect(audio.cues, [GameSoundCue.menuClick]);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(audio.cues, [GameSoundCue.menuClick, GameSoundCue.menuBack]);
    final menu = tester.element(find.byKey(const ValueKey('main-menu-panel')));
    expect(await Navigator.of(menu).maybePop(), isFalse);
    expect(audio.cues.length, 2);
  });

  testWidgets('setup controls and review have one sound per action', (
    tester,
  ) async {
    final audio = await _openApp(tester);
    await _tap(tester, 'single-player');
    audio.cues.clear();
    await _tap(tester, 'fog-of-war');
    expect(audio.cues, [GameSoundCue.menuClick]);
    final country = find
        .byType(DropdownButtonFormField<LocalPlayerCountryView>)
        .first;
    await Scrollable.ensureVisible(tester.element(country), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(country);
    await tester.pumpAndSettle();
    expect(audio.cues.length, 1);
    final japan = find.descendant(
      of: find.byType(Scrollable).last,
      matching: find.text('Japan'),
    );
    await tester.scrollUntilVisible(
      japan,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(japan);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<LocalPlayerCountryView>>(country)
          .initialValue,
      LocalPlayerCountryView.japan,
    );
    expect(audio.cues, [GameSoundCue.menuClick, GameSoundCue.menuClick]);
    await _tap(tester, 'continue-to-summary');
    await _tap(tester, 'back-to-setup');
    expect(audio.cues, [
      GameSoundCue.menuClick,
      GameSoundCue.menuClick,
      GameSoundCue.menuClick,
      GameSoundCue.menuBack,
    ]);
  });

  testWidgets('settings sound toggles and reset while sliders stay silent', (
    tester,
  ) async {
    final audio = await _openApp(tester);
    await _tap(tester, 'menu-settings');
    audio.cues.clear();
    await _tap(tester, 'nature-enabled-setting');
    expect(audio.cues, [GameSoundCue.menuClick]);
    final slider = find.descendant(
      of: find.byKey(const ValueKey('music-volume-setting')),
      matching: find.byType(Slider),
    );
    await Scrollable.ensureVisible(tester.element(slider), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(slider);
    await tester.pumpAndSettle();
    expect(audio.cues.length, 1);
    await _tap(tester, 'reset-settings');
    expect(audio.cues, [GameSoundCue.menuClick, GameSoundCue.menuClick]);
  });

  testWidgets(
    'blocked returns and popup dismissals do not sound a page return',
    (tester) async {
      final audio = await _openApp(tester);
      final menu = tester.element(
        find.byKey(const ValueKey('main-menu-panel')),
      );
      final navigator = Navigator.of(menu);
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const PopScope<void>(
            canPop: false,
            child: Scaffold(body: Text('Blocked')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Blocked'), findsOneWidget);
      expect(audio.cues, isEmpty);
      showDialog<void>(context: menu, builder: (_) => const AlertDialog());
      await tester.pumpAndSettle();
      navigator.pop();
      await tester.pumpAndSettle();
      expect(audio.cues, isEmpty);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(audio.cues, [GameSoundCue.menuBack]);
    },
  );
}

Future<RecordingGameAudio> _openApp(WidgetTester tester) async {
  final audio = RecordingGameAudio();
  final controller = MapPresentationController(
    capabilities: testGameSessionCapabilities(
      FakeGameSession.success(testMapScene()),
    ),
  );
  final settings = ClientSettingsController.ephemeral();
  addTearDown(settings.dispose);
  await tester.pumpWidget(
    AonwApp(
      mapController: controller,
      settingsController: settings,
      audio: audio,
    ),
  );
  await tester.pumpAndSettle();
  return audio;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final control = find.byKey(ValueKey(key));
  await Scrollable.ensureVisible(tester.element(control), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
}
