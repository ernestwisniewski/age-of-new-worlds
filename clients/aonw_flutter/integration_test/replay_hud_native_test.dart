import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/replay/application/replay_state.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_presentation_controller.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_screen.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/localized_test_app.dart';
import 'support/native_replay_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  testWidgets('native replay shares HUD queries without issuing commands', (
    tester,
  ) async {
    final requests = <String>[];
    final gateway = EngineGameSessionGateway(
      assets: rootBundle,
      sessionFactory: () async =>
          ReplayRecordingSession((await createAonwEngineSession())!, requests),
    );
    final settings = ClientSettingsController.ephemeral();
    ReplayPresentationController? replay;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    try {
      final archive = await recordNativeReplay(gateway);
      final store = NativeReplayStore(archive.document);
      replay = ReplayPresentationController(
        session: gateway.replaySession,
        viewerCapabilities: gateway.capabilities,
        store: store,
      );
      expect((await replay.openLatest()).started, isTrue);
      final opened = replay.state as ReplayReady;
      requests.clear();
      final game = AonwFlameGame();
      await settings.update(
        settings.settings.copyWith(
          reducedMotion: true,
          showUnitIdleAnimations: false,
        ),
      );
      await tester.pumpWidget(
        LocalizedTestApp(
          theme: AonwTheme.dark,
          home: ClientSettingsScope(
            controller: settings,
            child: ReplayScreen(
              controller: replay,
              flameGameFactory: () => game,
            ),
          ),
        ),
      );
      await _until(tester, () => find.byType(MapScreen).evaluate().isNotEmpty);
      final first = tester.widget<MapScreen>(find.byType(MapScreen)).controller;
      await _until(
        tester,
        () => !(first.state as GameSessionReady).research.loading,
      );
      expect((first.state as GameSessionReady).research.failure, isNull);
      expect((first.state as GameSessionReady).research.options, isNotNull);
      expect(first.readOnly, isTrue);
      await tester.tap(find.byKey(const ValueKey('open-research')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('close-research')), findsOneWidget);
      first.endTurn();
      first.selectTechnology(
        (first.state as GameSessionReady)
            .research
            .options!
            .options
            .first
            .technology,
      );
      first.saveLocalGame();
      final world = game.world;
      replay.seek(opened.frame.entryCount);
      await _until(
        tester,
        () =>
            replay!.state is ReplayReady &&
            !(replay.state as ReplayReady).isSeeking,
      );
      await _until(
        tester,
        () => !identical(
          tester.widget<MapScreen>(find.byType(MapScreen)).controller,
          first,
        ),
      );
      final last = tester.widget<MapScreen>(find.byType(MapScreen)).controller;
      await _until(
        tester,
        () => !(last.state as GameSessionReady).research.loading,
      );
      final ready = last.state as GameSessionReady;
      expect(last, isNot(same(first)));
      expect(game.world, same(world));
      expect(ready.recipient.stamp.stateDigest, archive.finalDigest);
      expect(
        ready.research.options!.stamp.stateDigest,
        ready.recipient.stamp.stateDigest,
      );
      expect(
        ready.research.options!.stamp.revision,
        ready.recipient.stamp.revision,
      );
      expect(ready.research.failure, isNull);
      expect(find.byKey(const ValueKey('close-research')), findsNothing);
      expect(find.byKey(const ValueKey('save-game')), findsNothing);
      expect(find.byKey(const ValueKey('turn-hud')), findsNothing);
      expect(
        requests.where(
          (type) => !{'researchOptions', 'seekReplay'}.contains(type),
        ),
        isEmpty,
      );
      expect(requests.where((type) => type == 'researchOptions').length, 2);
      binding.reportData = {
        'replayEntries': opened.frame.entryCount,
        'queryRequests': requests,
        'finalDigestMatches': true,
      };
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      replay?.dispose();
      settings.dispose();
      await gateway.close();
      await tester.binding.setSurfaceSize(null);
    }
  });
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (ready()) return;
  }
  fail('Native replay HUD did not become ready within 10 seconds.');
}
