import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_state.dart';
import 'package:aonw_flutter/features/workers/presentation/worker_panel.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('pl')]) {
    testWidgets(
      'improvement selection needs opening and confirmation (${locale.languageCode})',
      (tester) async {
        final unit = testVisibleUnit(kind: VisibleUnitKind.worker);
        final commands = <WorkerActionView>[];
        var state = WorkerState(
          unitId: unit.id,
          options: WorkerOptionsView(
            stamp: testSessionStamp(),
            unitId: unit.id,
            coordinate: unit.coordinate,
            improvements: const [
              WorkerImprovementOptionView(
                improvement: FieldImprovementKind.farm,
                buildTurns: 3,
              ),
            ],
            canAssign: false,
            canBuildRoad: false,
            automation: null,
          ),
        );
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: locale,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => WorkerPanel(
                  state: state,
                  unit: unit,
                  onOpenChanged: (open) => setState(
                    () => state = state.copyWith(
                      actionsOpen: open,
                      clearPreview: true,
                    ),
                  ),
                  onPreview: (kind) => setState(
                    () => state = state.copyWith(previewedImprovement: kind),
                  ),
                  onAction: commands.add,
                ),
              ),
            ),
          ),
        );
        final toggle = find.byKey(const ValueKey('worker-actions-toggle'));
        final confirm = find.byKey(
          const ValueKey('worker-improvement-confirm'),
        );
        expect(
          find.text(
            locale.languageCode == 'en' ? 'Improve hex' : 'Ulepsz pole',
          ),
          findsOneWidget,
        );
        expect(find.byType(ChoiceChip), findsNothing);
        expect(confirm, findsNothing);
        await tester.tap(toggle);
        await tester.pump();
        await tester.tap(find.byType(ChoiceChip));
        await tester.pump();
        expect(commands, isEmpty);
        expect(confirm, findsOneWidget);
        Focus.of(tester.element(find.textContaining('(3)'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(confirm, findsNothing);
        expect(commands, isEmpty);
        await tester.tap(toggle);
        await tester.pump();
        expect(confirm, findsNothing);
        await tester.tap(find.byType(ChoiceChip));
        await tester.pump();
        await tester.tap(confirm);
        expect(commands, hasLength(1));
        expect(
          (commands.single as ConfirmWorkerImprovementActionView).improvement,
          FieldImprovementKind.farm,
        );
      },
    );
  }
}
