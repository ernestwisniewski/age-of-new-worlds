import 'package:aonw_flutter/features/settings/presentation/performance_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('zoom alone stays idle and follows the provided value', (
    tester,
  ) async {
    await tester.pumpWidget(_counter(fps: false, zoom: 1.25));
    await tester.pumpAndSettle();
    expect(find.text('1.25Z'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(_counter(fps: false, zoom: 2.5));
    await tester.pumpAndSettle();
    expect(find.text('2.50Z'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(_counter(fps: false));
    expect(find.byKey(const ValueKey('performance-counter')), findsNothing);
  });

  testWidgets('FPS samples active frames and stops when disabled or inactive', (
    tester,
  ) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await tester.pumpWidget(_counter(fps: true));
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    final label = tester.widget<Text>(find.textContaining(' FPS')).data!;
    expect(int.parse(label.split(' ').first), inInclusiveRange(45, 55));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pumpWidget(_counter(fps: false, zoom: 1));
    await tester.pumpAndSettle();
    expect(find.text('1.00Z'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

Widget _counter({required bool fps, double? zoom}) => MaterialApp(
  home: Scaffold(
    body: PerformanceCounter(showFps: fps, zoom: zoom),
  ),
);
