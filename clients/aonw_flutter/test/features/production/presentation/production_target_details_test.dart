import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_banner_fixture.dart';
import 'production_catalog_fixture.dart';
import 'production_details_fixture.dart';

void main() {
  testWidgets(
    'blocked targets remain inspectable and B returns to the catalog',
    (tester) async {
      final navigation = MapGamepadNavigation(
        onOwnerChanged: () {},
        returnToMap: () {},
      );
      addTearDown(navigation.dispose);
      final actions = <ProductionActionView>[];
      await tester.pumpWidget(
        MapGamepadNavigationScope(
          navigation: navigation,
          child: bannerApp(
            options: catalogOptions(),
            enabled: false,
            modal: true,
            onAction: actions.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Details: Port'));
      await tester.pumpAndSettle();
      final details = find.byKey(const ValueKey('production-target-details'));
      expect(details, findsOneWidget);
      expect(
        find.descendant(of: details, matching: find.text('cost: 18')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: details,
          matching: find.text('requires Navigation'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: details,
          matching: find.text('This building is unavailable.'),
        ),
        findsOneWidget,
      );
      expect(actions, isEmpty);
      navigation.handleCommand(MapInputCommand.cancel);
      await tester.pumpAndSettle();
      expect(details, findsNothing);
      expect(find.byKey(const ValueKey('production-modal')), findsOneWidget);
      expect(navigation.hasModal, isTrue);
      await tester.tap(find.byTooltip('Details: Granary'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(details, findsNothing);
      expect(find.byKey(const ValueKey('production-modal')), findsOneWidget);
      expect(actions, isEmpty);
    },
  );

  testWidgets(
    'inspection reads refreshed options and resets for another city',
    (tester) async {
      const target = BuildingProductionTargetView('workshop');
      await tester.pumpWidget(
        bannerApp(options: detailsOptions(target), modal: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Details: Workshop'));
      await tester.pumpAndSettle();
      final details = find.byKey(const ValueKey('production-target-details'));
      expect(
        find.descendant(of: details, matching: find.text('cost: 18')),
        findsOneWidget,
      );
      await tester.pumpWidget(
        bannerApp(options: detailsOptions(target, cost: 27), modal: true),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: details, matching: find.text('cost: 27')),
        findsOneWidget,
      );
      expect(find.text('cost: 18'), findsNothing);
      await tester.pumpWidget(
        bannerApp(
          options: detailsOptions(target, cityId: 'another-city'),
          modal: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(details, findsNothing);
    },
  );

  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets('$language details fit $size at 200 percent', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          bannerApp(
            options: bannerOptions(),
            modal: true,
            locale: language,
            size: size,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        final help = find.byIcon(Icons.help_outline);
        await tester.scrollUntilVisible(
          help,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final catalogPosition = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        final catalogOffset = catalogPosition.pixels;
        await tester.tap(help);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('production-target-details')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(catalogPosition.pixels, catalogOffset);
        expect(tester.hasRunningAnimations, isFalse);
        await tester.tap(
          find.byKey(const ValueKey('close-production-details')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('production-target-details')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
