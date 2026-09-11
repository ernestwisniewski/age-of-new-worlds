import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/localized_test_app.dart';

/// Measures entry into a map after the application's window and fonts exist.
/// Scene data and sprite atlases are created only after this returns.
Future<void> warmPerformanceShell(WidgetTester tester) async {
  await tester.pumpWidget(
    LocalizedTestApp(
      theme: AonwTheme.dark,
      home: Scaffold(
        body: Text('AoNW', style: AonwTheme.dark.textTheme.titleLarge),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
