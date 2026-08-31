import 'package:aonw_flutter/features/turns/application/turn_presentation_queue.dart';
import 'package:aonw_flutter/features/turns/presentation/turn_banner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('announces the authoritative turn and completes once', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: TurnBanner(
          presentation: const TurnPresentation(turn: 7),
          duration: const Duration(milliseconds: 100),
          onFinished: () => completions += 1,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('turn-banner')), findsOneWidget);
    expect(find.text('TURN 7'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    expect(completions, 1);
  });
}
