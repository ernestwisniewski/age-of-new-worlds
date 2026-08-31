import 'package:aonw_flutter/features/turns/application/turn_action_state.dart';
import 'package:aonw_flutter/features/turns/application/turn_command_runner.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a typed turn transport failure and reports its cause', () async {
    final cause = StateError('private transport details');
    final diagnostics = <({String code, Object error})>[];
    final runner = TurnCommandRunner(
      session: _FailingTurnSession(
        TurnSessionException(
          code: 'session_not_open',
          message: 'The session is unavailable.',
          diagnosticCause: cause,
        ),
      ),
      diagnosticReporter: (code, error, _) =>
          diagnostics.add((code: code, error: error)),
    );

    final completion = await runner.endTurn(expectedRevision: 3);

    expect(completion.failure?.code, TurnFailureViewCode.sessionUnavailable);
    expect(diagnostics.single.code, 'session_not_open');
    expect(diagnostics.single.error, same(cause));
  });

  test('fails closed for an unexpected turn adapter exception', () async {
    final diagnostics = <String>[];
    final runner = TurnCommandRunner(
      session: _FailingTurnSession(StateError('unexpected')),
      diagnosticReporter: (code, _, _) => diagnostics.add(code),
    );

    final completion = await runner.endTurn(expectedRevision: 3);

    expect(completion.failure?.code, TurnFailureViewCode.requestFailed);
    expect(diagnostics, ['unexpected_turn_failure']);
  });
}

final class _FailingTurnSession implements TurnSessionPort {
  const _FailingTurnSession(this.error);

  final Object error;

  @override
  Future<TurnCommandResultView> endTurn({required int expectedRevision}) =>
      Future.error(error);
}
