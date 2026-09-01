import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/flame_map_viewport.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  testWidgets('enables only available map view mode transitions', (
    tester,
  ) async {
    var transitions = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MapViewModeToggle(
            value: MapViewMode.tile,
            allowGraphicMode: false,
            onChanged: (_) => transitions += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Graphic'));
    expect(transitions, 0);

    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MapViewModeToggle(
            value: MapViewMode.tile,
            allowGraphicMode: true,
            onChanged: (_) => transitions += 1,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Graphic'));
    expect(transitions, 1);
  });

  testWidgets('keeps every gameplay HUD control reachable on a narrow screen', (
    tester,
  ) async {
    final session = FakeGameSession.success(testMapScene(cols: 7, rows: 7));
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MapScreen(controller: controller, onOpenSettings: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.select((col: 6, row: 6));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('turn-hud')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-view-mode-toggle')), findsOneWidget);
    expect(find.byKey(const ValueKey('save-game')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-research')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-diplomacy')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-objectives')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-selection-panel')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('turn-number'))).height,
      34,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('end-turn'))),
      const Size(96, 48),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('open-settings'))),
      const Offset(8, 86),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('open-objectives'))),
      const Offset(8, 148),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('open-research'))),
      const Offset(8, 196),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('open-diplomacy'))),
      const Offset(8, 244),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('save-game'))),
      const Offset(8, 292),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('map-view-mode-toggle'))),
      const Offset(8, 340),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the left-side gameplay panels mutually exclusive', (
    tester,
  ) async {
    final session = FakeGameSession.success(testMapScene(cols: 7, rows: 7));
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(home: MapScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-objectives')));
    await tester.pump();
    expect(find.byKey(const ValueKey('close-objectives')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-research')));
    await tester.pump();
    expect(find.byKey(const ValueKey('close-objectives')), findsNothing);
    expect(find.byKey(const ValueKey('close-research')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-diplomacy')));
    await tester.pump();
    expect(find.byKey(const ValueKey('close-research')), findsNothing);
    expect(find.byKey(const ValueKey('close-diplomacy')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-diplomacy')));
    await tester.pump();
    expect(find.byKey(const ValueKey('close-diplomacy')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
