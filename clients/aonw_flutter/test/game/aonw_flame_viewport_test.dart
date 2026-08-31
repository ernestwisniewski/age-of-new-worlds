import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized_test_app.dart';
import '../support/map_test_fixture.dart';

void main() {
  testWidgets('embeds one clipped interactive Flame world with semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final games = <AonwFlameGame>[];
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        home: MapScreen(
          controller: controller,
          flameGameFactory: () {
            final game = AonwFlameGame();
            games.add(game);
            return game;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(games, hasLength(1));
    expect(games.single.debugMountCount, 1);
    expect(games.single.world.debugScene?.map.mapId, 'test-map');
    expect(games.single.inputSurface.isMounted, isTrue);
    expect(games.single.inputSurface.isEnabled, isTrue);
    expect(games.single.world.terrainLayer.isVisible, isTrue);
    expect(games.single.paused, isTrue, reason: 'the loaded world stays idle');
    expect(find.byKey(const ValueKey('flame-viewport-clip')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('flame-viewport-repaint-boundary')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Map test-map, 3 by 2 hexes'), findsOneWidget);

    final gameFinder = find.byWidgetPredicate(
      (widget) => widget is GameWidget<AonwFlameGame>,
    );
    final gameWidget = tester.widget<GameWidget<AonwFlameGame>>(gameFinder);
    expect(gameWidget.game, same(games.single));
    expect(gameWidget.autofocus, isFalse);
    expect(gameWidget.focusNode, isNull);
    expect(gameWidget.addRepaintBoundary, isFalse);
    expect(gameWidget.behavior, HitTestBehavior.opaque);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(games.single.debugRemoveCount, 1);
    expect(games.single.debugDisposed, isTrue);
    expect(games.single.world.debugScene, isNull);
    semantics.dispose();
  });

  testWidgets('converts an onLoad failure into Flutter recovery UI', (
    tester,
  ) async {
    final games = <AonwFlameGame>[];
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        home: MapScreen(
          controller: controller,
          flameGameFactory: () {
            final game = games.isEmpty
                ? _FailingAonwFlameGame()
                : AonwFlameGame();
            games.add(game);
            return game;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('flame-load-error')), findsOneWidget);
    expect(find.text('Map unavailable'), findsOneWidget);
    expect(find.text('sensitive renderer failure'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(games, hasLength(2));
    expect(games.first.debugDisposed, isTrue);
    expect(games.last.debugMountCount, 1);
    expect(find.byKey(const ValueKey('flame-load-error')), findsNothing);
    expect(
      find.byKey(const ValueKey('flame-viewport-repaint-boundary')),
      findsOneWidget,
    );
  });
}

final class _FailingAonwFlameGame extends AonwFlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    throw StateError('sensitive renderer failure');
  }
}
