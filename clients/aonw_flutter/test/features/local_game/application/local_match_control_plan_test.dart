import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps participant order and wraps after the current actor', () {
    final plan = LocalMatchControlPlanView([
      _participant('player-1', LocalPlayerControlView.human),
      _participant('player-2', LocalPlayerControlView.ai),
      _participant('player-3', LocalPlayerControlView.human),
    ]);

    expect(plan.after('player-2').map((participant) => participant.id), [
      'player-3',
      'player-1',
      'player-2',
    ]);
    expect(plan.requiresPrivateHandoff, isTrue);
    expect(plan.humanParticipants.map((participant) => participant.id), [
      'player-1',
      'player-3',
    ]);
  });

  test('rejects duplicate participant identities', () {
    expect(
      () => LocalMatchControlPlanView([
        _participant('player-1', LocalPlayerControlView.human),
        _participant('player-1', LocalPlayerControlView.ai),
      ]),
      throwsArgumentError,
    );
  });
}

LocalParticipantControlView _participant(
  String id,
  LocalPlayerControlView control,
) => LocalParticipantControlView(id: id, name: id, control: control);
