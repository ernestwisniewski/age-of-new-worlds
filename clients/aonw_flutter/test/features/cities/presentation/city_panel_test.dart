import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/cities/presentation/city_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets('shows exact city yield and opens map management mode', (
    tester,
  ) async {
    CityManagementMode? managementMode;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: CityPanel(
              state: CityState(
                cityId: 'preview-city',
                inspection: testCityInspectionView(),
              ),
              city: testCityView(),
              onToggleFoundingHex: (_) {},
              onConfirmFounding: () {},
              onCancelFounding: () {},
              onStartManagement: (value) => managementMode = value,
              onCancelManagement: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Preview City'), findsOneWidget);
    expect(find.textContaining('Food 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('start-worked-hex-management')));
    expect(managementMode, CityManagementMode.workedHexes);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps founding choices accessible and exact', (tester) async {
    var confirms = 0;
    var cancels = 0;
    final options = testCityFoundingOptionsView();
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: CityPanel(
            state: CityState(
              founderUnitId: options.founderUnitId,
              foundingOptions: options,
              foundingSelection: const [(col: 1, row: 0)],
            ),
            city: null,
            onToggleFoundingHex: (_) {},
            onConfirmFounding: () => confirms += 1,
            onCancelFounding: () => cancels += 1,
            onStartManagement: (_) {},
            onCancelManagement: () {},
          ),
        ),
      ),
    );

    expect(find.text('Initial territory: 1/1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-city-founding')));
    expect(confirms, 1);
    await tester.tap(find.byKey(const ValueKey('cancel-city-founding')));
    expect(cancels, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders feature copy through the Polish ARB catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      LocalizedTestApp(
        locale: const Locale('pl'),
        home: Scaffold(
          body: CityPanel(
            state: CityState(
              cityId: 'preview-city',
              inspection: testCityInspectionView(),
            ),
            city: testCityView(),
            onToggleFoundingHex: (_) {},
            onConfirmFounding: () {},
            onCancelFounding: () {},
            onStartManagement: (_) {},
            onCancelManagement: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Właściciel:'), findsOneWidget);
    expect(find.textContaining('Żywność 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
