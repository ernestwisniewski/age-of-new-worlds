import 'dart:async';

import 'package:aonw_flutter/features/audio/presentation/game_audio_host.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/research/application/research_session_port.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/recording_game_audio.dart';

void main() {
  testWidgets('routes held buttons to HUD and panel without moving the map', (
    tester,
  ) async {
    final harness = await _Harness.mount(tester);
    harness.controller.selectUnit('preview-commander');
    await tester.pumpAndSettle();
    final selected = harness.ready.interaction.selected;
    final cursor = harness.controller.cursor.value;
    final camera = harness.game.mapCamera.debugTransform!;
    await harness.press(tester, GamepadButton.leftStick);
    harness.expectFocus(tester, 'open-settings');
    await harness.press(tester, GamepadButton.dpadDown);
    harness.expectFocus(tester, 'open-objectives');
    await harness.press(tester, GamepadButton.a, hold: true);
    expect(find.byKey(const ValueKey('close-objectives')), findsOneWidget);
    harness.expectFocus(tester, 'close-objectives');
    harness.axis(GamepadAxis.rightStickX, 1);
    harness.axis(GamepadAxis.rightTrigger, 1);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('close-objectives')), findsOneWidget);
    expect(
      harness.game.mapCamera.debugTransform!.worldCenter,
      camera.worldCenter,
    );
    expect(harness.game.mapCamera.debugTransform!.zoom, camera.zoom);
    expect(harness.controller.cursor.value, cursor);
    expect(harness.ready.interaction.selected, selected);
    harness.release(GamepadButton.a);
    harness.axis(GamepadAxis.rightStickX, 0);
    harness.axis(GamepadAxis.rightTrigger, 0);
    await tester.pump();
    await harness.press(tester, GamepadButton.b, hold: true);
    expect(find.byKey(const ValueKey('close-objectives')), findsNothing);
    expect(harness.navigation(tester).capturesInput, isTrue);
    expect(harness.ready.interaction.selectedUnitId, 'preview-commander');
    expect(harness.audio.cues, [
      GameSoundCue.uiPanelOpen,
      GameSoundCue.uiPanelClose,
    ]);
    harness.release(GamepadButton.b);
    await tester.pump();
    await harness.press(tester, GamepadButton.b);
    expect(harness.navigation(tester).capturesInput, isFalse);
    expect(harness.ready.interaction.selectedUnitId, 'preview-commander');
    await harness.press(tester, GamepadButton.b);
    expect(harness.ready.interaction.moveTargeting, isFalse);
    expect(harness.ready.interaction.selectedUnitId, 'preview-commander');
    await harness.press(tester, GamepadButton.b);
    expect(harness.ready.interaction.selectedUnitId, isNull);
    expect(harness.session.endTurnCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('X and the movement chip share targeting and cursor behavior', (
    tester,
  ) async {
    final harness = await _Harness.mount(tester);
    harness.controller.selectUnit('preview-commander');
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('unit-move-targeting'));
    expect(tester.widget<FilterChip>(toggle).selected, isTrue);
    await harness.press(tester, GamepadButton.x, hold: true);
    expect(harness.ready.interaction.moveTargeting, isFalse);
    expect(harness.ready.interaction.selectedUnitId, 'preview-commander');
    expect(tester.widget<FilterChip>(toggle).selected, isFalse);
    harness.release(GamepadButton.x);
    await tester.pump();
    await tester.tap(toggle);
    await tester.pump();
    expect(harness.ready.interaction.moveTargeting, isTrue);
    await harness.press(tester, GamepadButton.dpadRight);
    final target = harness.controller.cursor.value;
    expect(target, isNot(harness.ready.interaction.selected));
    expect(harness.ready.interaction.selectedUnitId, 'preview-commander');
    expect(harness.ready.interaction.route, isNull);
    await harness.press(tester, GamepadButton.x);
    await harness.press(tester, GamepadButton.dpadLeft);
    expect(harness.ready.interaction.selected, harness.controller.cursor.value);
    expect(harness.ready.interaction.selectedUnitId, isNull);
    expect(harness.ready.interaction.route, isNull);
    harness.controller.moveMapCursor((col: 0, row: 0));
    await tester.pump();
    expect(harness.ready.interaction.selectedUnitId, isNull);
    await harness.press(tester, GamepadButton.a);
    await tester.pumpAndSettle();
    expect(harness.ready.interaction.selectedUnitId, 'preview-commander');
    expect(harness.ready.interaction.moveTargeting, isTrue);
    expect(harness.audio.cues, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HUD and panels consume X without toggling or moving focus', (
    tester,
  ) async {
    final harness = await _Harness.mount(tester);
    harness.controller.selectUnit('preview-commander');
    await tester.pumpAndSettle();
    await harness.press(tester, GamepadButton.leftStick);
    final focus = harness.navigation(tester).highlighted;
    await harness.press(tester, GamepadButton.x);
    expect(harness.navigation(tester).highlighted, same(focus));
    expect(harness.ready.interaction.moveTargeting, isTrue);
    await tester.tap(find.byKey(const ValueKey('open-objectives')));
    await tester.pumpAndSettle();
    await harness.press(tester, GamepadButton.x, hold: true);
    expect(harness.ready.interaction.moveTargeting, isTrue);
    expect(find.byKey(const ValueKey('close-objectives')), findsOneWidget);
    harness.release(GamepadButton.x);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final panel in ['objectives', 'research', 'diplomacy']) {
    testWidgets('captures $panel opened by pointer and closes with Escape', (
      tester,
    ) async {
      final harness = await _Harness.mount(tester);
      harness.controller.selectUnit('preview-commander');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('open-$panel')));
      await tester.pumpAndSettle();
      expect(harness.navigation(tester).capturesInput, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('close-$panel')), findsNothing);
      expect(harness.ready.interaction.selectedUnitId, 'preview-commander');
      expect(harness.audio.cues, [
        panel == 'research'
            ? GameSoundCue.technology
            : GameSoundCue.uiPanelOpen,
        GameSoundCue.uiPanelClose,
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'required research captures B and allows one technology command',
    (tester) async {
      final harness = await _Harness.mount(tester, requiredResearch: true);
      expect(
        find.byKey(const ValueKey('research-selection-required')),
        findsOneWidget,
      );
      await harness.press(tester, GamepadButton.b);
      expect(harness.navigation(tester).capturesInput, isTrue);
      expect(
        find.byKey(const ValueKey('research-selection-required')),
        findsOneWidget,
      );
      expect(harness.session.researchCommandCalls, 0);
      await harness.press(tester, GamepadButton.a, hold: true);
      expect(harness.session.researchCommandCalls, 1);
      expect(harness.ready.interaction.selected, isNull);
      expect(harness.session.endTurnCalls, 0);
      harness.release(GamepadButton.a);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('releases HUD on route suspension and primes held A on return', (
    tester,
  ) async {
    final harness = await _Harness.mount(tester);
    await harness.press(tester, GamepadButton.leftStick);
    final context = tester.element(find.byType(MapScreen));
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => const AlertDialog(title: Text('Pause')),
      ),
    );
    await tester.pumpAndSettle();
    expect(harness.navigation(tester).capturesInput, isFalse);
    await harness.press(tester, GamepadButton.a, hold: true);
    Navigator.of(context).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(harness.ready.interaction.selected, isNull);
    harness.release(GamepadButton.a);
    await tester.pump();
    await harness.press(tester, GamepadButton.a);
    expect(harness.ready.interaction.selected, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primes buttons held while the application is inactive', (
    tester,
  ) async {
    final harness = await _Harness.mount(tester);
    await harness.press(tester, GamepadButton.leftStick);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await harness.press(tester, GamepadButton.a, hold: true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 600));
    expect(harness.ready.interaction.selected, isNull);
    expect(harness.navigation(tester).capturesInput, isFalse);
    harness.release(GamepadButton.a);
    await tester.pump();
    await harness.press(tester, GamepadButton.a);
    expect(harness.ready.interaction.selected, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

final class _Harness {
  _Harness({required bool requiredResearch}) {
    input = GamepadMapInputSource(events: events.stream);
    session = FakeGameSession.success(
      testMapScene(
        cols: 7,
        rows: 7,
        units: [testVisibleUnit()],
        pendingAction: requiredResearch
            ? const PendingResearchSelectionView()
            : null,
      ),
      reachableResult: testReachableView(),
      researchResult: ResearchCommandResultView.accepted(
        player: PlayerMapView.preview(
          actorPlayerId: 'preview-player',
          stamp: testSessionStamp(revision: 1),
          turn: 1,
          pendingAction: null,
          units: const [],
        ),
      ),
    );
    controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
  }
  final events = StreamController<NormalizedGamepadEvent>(sync: true);
  late final GamepadMapInputSource input;
  late final FakeGameSession session;
  late final MapPresentationController controller;
  final audio = RecordingGameAudio();
  final settings = ClientSettingsController.ephemeral();
  final game = AonwFlameGame();
  final routeObserver = RouteObserver<ModalRoute<void>>();
  GameSessionReady get ready => controller.state as GameSessionReady;

  static Future<_Harness> mount(
    WidgetTester tester, {
    bool requiredResearch = false,
  }) async {
    final harness = _Harness(requiredResearch: requiredResearch);
    addTearDown(harness.controller.dispose);
    addTearDown(harness.settings.dispose);
    addTearDown(harness.input.close);
    addTearDown(harness.events.close);
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GameAudioHost(
        settings: harness.settings,
        settingsReady: Future<void>.value(),
        audio: harness.audio,
        child: LocalizedTestApp(
          navigatorObservers: [harness.routeObserver],
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1000, 800),
              disableAnimations: true,
            ),
            child: MapScreen(
              controller: harness.controller,
              inputSource: harness.input,
              routeObserver: harness.routeObserver,
              flameGameFactory: () => harness.game,
              onOpenSettings: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> press(
    WidgetTester tester,
    GamepadButton button, {
    bool hold = false,
  }) async {
    _button(button, 1);
    await tester.pump();
    if (hold) {
      await tester.pump(const Duration(milliseconds: 600));
    } else {
      release(button);
      await tester.pump();
    }
  }

  void release(GamepadButton button) => _button(button, 0);
  void _button(GamepadButton button, double value) => events.add(
    NormalizedGamepadEvent(
      gamepadId: 'hud-pad',
      timestamp: 1,
      button: button,
      value: value,
      rawEvent: GamepadEvent(
        gamepadId: 'hud-pad',
        timestamp: 1,
        type: KeyType.button,
        key: button.name,
        value: value,
      ),
    ),
  );
  void axis(GamepadAxis axis, double value) => events.add(
    NormalizedGamepadEvent(
      gamepadId: 'hud-pad',
      timestamp: 1,
      axis: axis,
      value: value,
      rawEvent: GamepadEvent(
        gamepadId: 'hud-pad',
        timestamp: 1,
        type: KeyType.analog,
        key: axis.name,
        value: value,
      ),
    ),
  );
  MapGamepadNavigation navigation(WidgetTester tester) => tester
      .widget<MapGamepadNavigationScope>(find.byType(MapGamepadNavigationScope))
      .navigation;
  void expectFocus(WidgetTester tester, String key) {
    final rect = navigation(tester).highlighted!.rect;
    expect(
      tester.getRect(find.byKey(ValueKey(key))).contains(rect.center),
      isTrue,
    );
  }
}
