import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_banner_fixture.dart';

void main() {
  testWidgets(
    'copies the forecast and exact rush quote and sends one city intent',
    (tester) async {
      final actions = <ProductionActionView>[];
      await tester.pumpWidget(
        bannerApp(options: bannerOptions(), onAction: actions.add),
      );
      expect(find.text('37 / 100 production'), findsOneWidget);
      expect(find.text('About 11 turns'), findsOneWidget);
      expect(find.text('7 production / turn'), findsOneWidget);
      expect(find.text('Rush +3 production · 19 gold'), findsOneWidget);
      expect(find.text('Available gold: 150'), findsOneWidget);
      final rush = find.byKey(const ValueKey('production-rush'));
      await tester.tap(rush);
      expect(actions.single, isA<RushProductionActionView>());
      expect(actions.single.cityId, 'preview-city');
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('unaffordable quote keeps its price and cannot dispatch', (
    tester,
  ) async {
    await tester.pumpWidget(
      bannerApp(options: bannerOptions(unaffordable: true)),
    );
    final button = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('production-rush')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Rush +3 production · 19 gold'), findsOneWidget);
    expect(find.text('Rush production is unavailable.'), findsOneWidget);
  });

  testWidgets(
    'continuous projects show output and omit rush and finite progress',
    (tester) async {
      await tester.pumpWidget(bannerApp(options: bannerOptions(project: true)));
      expect(find.text('Continuous project'), findsOneWidget);
      expect(find.text('4 science / turn'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('production-rush')), findsNothing);
    },
  );

  testWidgets(
    'completed unit reports blocked spawn and full progress without an ETA',
    (tester) async {
      await tester.pumpWidget(bannerApp(options: bannerOptions(blocked: true)));
      expect(find.text('Waiting for a free tile'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('production-rush')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  for (final pending in [false, true]) {
    testWidgets(
      'read-only or pending production disables rush (pending=$pending)',
      (tester) async {
        await tester.pumpWidget(
          bannerApp(
            options: bannerOptions(),
            enabled: pending,
            pending: pending,
          ),
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(const ValueKey('production-rush')),
              )
              .onPressed,
          isNull,
        );
      },
    );
  }

  testWidgets('keyboard activation uses the rush button focus', (tester) async {
    final actions = <ProductionActionView>[];
    await tester.pumpWidget(
      bannerApp(options: bannerOptions(), onAction: actions.add),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(actions.single, isA<RushProductionActionView>());
  });

  for (final language in ['pl', 'en', 'fr', 'de', 'es', 'nl']) {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets('$language forecast fits $size with text 200 percent', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          bannerApp(
            options: bannerOptions(),
            locale: language,
            scale: 2,
            size: size,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('production-rush')),
        );
        expect(tester.takeException(), isNull);
        expect(tester.hasRunningAnimations, isFalse);
      });
    }
  }
}
