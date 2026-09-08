import 'package:aonw_flutter/design_system/widgets/aonw_menu_adjustable.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('enters HUD, skips unavailable sections and returns to map', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());
    await harness.frame(
      tester,
      const MapGamepadFrame(hudFocusPreviousPressed: true),
    );
    harness.expectFocus('menu');
    await harness.frame(
      tester,
      const MapGamepadFrame(hudFocusNextPressed: true),
    );
    harness.expectFocus('selection-1');
    await harness.frame(tester, const MapGamepadFrame(focusNextPressed: true));
    harness.expectFocus('global-1');
    await harness.frame(
      tester,
      const MapGamepadFrame(focusPreviousPressed: true),
    );
    harness.expectFocus('selection-1');
    await harness.frame(tester, const MapGamepadFrame(cancelPressed: true));
    expect(harness.navigation.capturesInput, isFalse);
    expect(harness.navigation.highlighted, isNull);
    expect(harness.returnedToMap, 1);
    expect(harness.ownerChanges, 2);
    expect(
      harness.navigation.handleFrame(
        const MapGamepadFrame(activatePressed: true),
      ),
      isFalse,
    );
    expect(harness.activated, isEmpty);
  });

  testWidgets('uses section directions and reaches bottom command', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());
    await harness.frame(
      tester,
      const MapGamepadFrame(hudFocusNextPressed: true, activatePressed: true),
    );
    harness.expectFocus('selection-1');
    expect(harness.activated, isEmpty);
    await harness.move(tester, MapInputCommand.cursorRight);
    harness.expectFocus('selection-2');
    await harness.move(tester, MapInputCommand.cursorDown);
    harness.expectFocus('end-turn');
    await harness.frame(tester, const MapGamepadFrame(activatePressed: true));
    expect(harness.activated, ['end-turn']);
    await harness.move(tester, MapInputCommand.cursorUp);
    harness.expectFocus('selection-1');
    await harness.move(tester, MapInputCommand.cursorLeft);
    harness.expectFocus('global-1');
    await harness.move(tester, MapInputCommand.cursorDown);
    harness.expectFocus('global-2');
    await harness.move(tester, MapInputCommand.cursorRight);
    harness.expectFocus('menu');
  });

  testWidgets('captures panel actions, adjustment and cancel before HUD', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());
    await harness.frame(
      tester,
      const MapGamepadFrame(hudFocusPreviousPressed: true),
    );
    harness.panel = true;
    await tester.pumpWidget(harness.build());
    await tester.pump();
    harness.expectFocus('panel-1');
    await harness.frame(
      tester,
      const MapGamepadFrame(hudFocusNextPressed: true),
    );
    harness.expectFocus('panel-1');
    await harness.move(tester, MapInputCommand.cursorRight);
    expect(harness.adjusted, 1);
    harness.expectFocus('panel-1');
    await harness.move(tester, MapInputCommand.cursorDown);
    harness.expectFocus('panel-2');
    await harness.frame(tester, const MapGamepadFrame(activatePressed: true));
    expect(harness.activated, ['panel-2']);
    await harness.frame(tester, const MapGamepadFrame(cancelPressed: true));
    expect(harness.panelCancellations, 1);
    expect(harness.returnedToMap, 0);
    harness.panel = false;
    await tester.pumpWidget(harness.build());
    await tester.pump();
    harness.expectFocus('menu');
    expect(tester.takeException(), isNull);
  });

  testWidgets('repairs focus when a target is disabled or removed', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());
    await harness.frame(
      tester,
      const MapGamepadFrame(hudFocusNextPressed: true),
    );
    harness.disabled.add('selection-1');
    await tester.pumpWidget(harness.build());
    await tester.pump();
    harness.expectFocus('selection-2');
    harness.selection = false;
    await tester.pumpWidget(harness.build());
    await tester.pump();
    harness.expectFocus('end-turn');
    await harness.frame(tester, const MapGamepadFrame(activatePressed: true));
    expect(harness.activated, ['end-turn']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolls focused panel actions into view', (tester) async {
    final harness = _Harness()..panel = true;
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());
    await tester.pump();
    for (var index = 0; index < 7; index++) {
      await harness.move(tester, MapInputCommand.cursorDown);
    }
    harness.expectFocus('panel-8');
    final rect = tester.getRect(find.text('panel-8'));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(200));
    await harness.frame(tester, const MapGamepadFrame(activatePressed: true));
    expect(harness.activated, ['panel-8']);
  });
  testWidgets('loading panel consumes activation after its targets disappear', (
    tester,
  ) async {
    final harness = _Harness()..panel = true;
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());
    await tester.pump();
    harness.expectFocus('panel-1');
    harness.disabled.addAll([
      for (var index = 1; index <= 10; index++) 'panel-$index',
    ]);
    await tester.pumpWidget(harness.build());
    await tester.pump();
    await harness.frame(tester, const MapGamepadFrame(activatePressed: true));
    expect(harness.navigation.highlighted, isNull);
    expect(harness.activated, isEmpty);
    expect(harness.navigation.capturesInput, isTrue);
  });

  testWidgets('scrolls panel text when the header is its only action', (
    tester,
  ) async {
    final harness = _Harness()
      ..panel = true
      ..readOnlyPanel = true;
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());
    await tester.pump();
    harness.expectFocus('panel-close');
    await harness.move(tester, MapInputCommand.cursorDown);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
    harness.expectFocus('panel-close');
    await harness.move(tester, MapInputCommand.cursorUp);
    expect(scrollable.position.pixels, 0);
  });
}

final class _Harness {
  _Harness() {
    navigation = MapGamepadNavigation(
      onOwnerChanged: () => ownerChanges++,
      returnToMap: () => returnedToMap++,
    );
  }
  late final MapGamepadNavigation navigation;
  final nodes = <String, FocusNode>{};
  final activated = <String>[];
  final disabled = <String>{'global-disabled'};
  var selection = true;
  var panel = false;
  var readOnlyPanel = false;
  var ownerChanges = 0;
  var returnedToMap = 0;
  var panelCancellations = 0;
  var adjusted = 0;

  Widget build() => MaterialApp(
    home: Material(
      child: MapGamepadNavigationScope(
        navigation: navigation,
        child: Stack(
          children: [
            Column(
              children: [
                _region(MapHudSection.menu, ['menu']),
                _region(MapHudSection.globalActions, [
                  'global-1',
                  'global-disabled',
                  'global-2',
                ]),
                if (selection)
                  _region(MapHudSection.selectionActions, [
                    'selection-1',
                    'selection-2',
                  ]),
                MapGamepadRegion(
                  section: MapHudSection.selectionActions,
                  bottomCommand: true,
                  child: _button('end-turn'),
                ),
              ],
            ),
            if (panel)
              MapGamepadRegion(
                section: MapHudSection.globalActions,
                priority: MapGamepadPriority.panel,
                onCancel: () => panelCancellations++,
                child: readOnlyPanel
                    ? _textPanel()
                    : SizedBox(
                        height: 200,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              AonwMenuAdjustable(
                                onAdjust: (delta) => adjusted += delta,
                                child: _button('panel-1'),
                              ),
                              for (var index = 2; index <= 10; index++)
                                _button('panel-$index'),
                            ],
                          ),
                        ),
                      ),
              ),
            Positioned.fill(child: MapGamepadFocusRing(navigation: navigation)),
          ],
        ),
      ),
    ),
  );

  Widget _textPanel() => SizedBox(
    height: 200,
    child: Column(
      children: [
        _button('panel-close'),
        Expanded(
          child: ListView(
            children: [
              for (var index = 0; index < 30; index++)
                SizedBox(height: 50, child: Text('Objective $index')),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _region(MapHudSection section, List<String> names) => MapGamepadRegion(
    key: ValueKey(section),
    section: section,
    child: Row(children: names.map(_button).toList()),
  );

  Widget _button(String name) => TextButton(
    focusNode: nodes.putIfAbsent(name, () => FocusNode(debugLabel: name)),
    onPressed: disabled.contains(name) ? null : () => activated.add(name),
    child: Text(name),
  );

  Future<void> frame(WidgetTester tester, MapGamepadFrame frame) async {
    expect(navigation.handleFrame(frame), isTrue);
    await tester.pump();
  }

  Future<void> move(WidgetTester tester, MapInputCommand direction) =>
      frame(tester, MapGamepadFrame(cursorStep: direction));

  void expectFocus(String name) {
    expect(navigation.highlighted, same(nodes[name]));
    expect(nodes[name]!.hasFocus, isTrue);
  }

  void dispose() {
    navigation.dispose();
    for (final node in nodes.values) {
      node.dispose();
    }
  }
}
