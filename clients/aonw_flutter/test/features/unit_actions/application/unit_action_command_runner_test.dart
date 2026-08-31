import 'package:aonw_flutter/features/unit_actions/application/action_deck_state.dart';
import 'package:aonw_flutter/features/unit_actions/application/unit_action_command_runner.dart';
import 'package:aonw_flutter/features/unit_actions/application/unit_action_session_port.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'maps a typed transport failure and reports its private cause',
    () async {
      final cause = StateError('private transport details');
      final diagnostics = <({String code, Object error})>[];
      final runner = UnitActionCommandRunner(
        session: _FailingUnitActionSession(
          UnitActionSessionException(
            code: 'session_not_open',
            message: 'The session is unavailable.',
            diagnosticCause: cause,
          ),
        ),
        diagnosticReporter: (code, error, _) =>
            diagnostics.add((code: code, error: error)),
      );

      final completion = await runner.execute(
        expectedRevision: 3,
        unitId: 'unit-1',
        action: UnitActionKindView.skip,
      );

      expect(
        completion.failure?.code,
        UnitActionFailureViewCode.sessionUnavailable,
      );
      expect(completion.resyncedPlayer, isNull);
      expect(diagnostics.single.code, 'session_not_open');
      expect(diagnostics.single.error, same(cause));
    },
  );

  test('fails closed for an unexpected adapter exception', () async {
    final diagnostics = <String>[];
    final runner = UnitActionCommandRunner(
      session: _FailingUnitActionSession(StateError('unexpected')),
      diagnosticReporter: (code, _, _) => diagnostics.add(code),
    );

    final completion = await runner.execute(
      expectedRevision: 3,
      unitId: 'unit-1',
      action: UnitActionKindView.cancel,
    );

    expect(completion.failure?.code, UnitActionFailureViewCode.requestFailed);
    expect(diagnostics, ['unexpected_unit_action_failure']);
  });
}

final class _FailingUnitActionSession implements UnitActionSessionPort {
  const _FailingUnitActionSession(this.error);

  final Object error;

  @override
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) => Future.error(error);
}
