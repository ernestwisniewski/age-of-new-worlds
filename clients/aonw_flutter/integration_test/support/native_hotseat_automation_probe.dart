import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'native_turn_automation_probe.dart';

extension NativeHotseatAutomationProbe on NativeTurnAutomationProbe {
  Future<void> awaitPrivateHandoff(String actor, int turn) async {
    await until(
      () =>
          ready.localHandoff.phase == LocalHandoffPhase.awaitingConfirmation &&
          ready.recipient.actorPlayerId == actor &&
          ready.recipient.turnView.number == turn,
      'private handoff to $actor in turn $turn',
    );
    expect(ready.localHandoff.playerId, actor);
    expect(ready.interaction.selectedUnitId, isNull);
    expect(ready.interaction.researchFocused, isFalse);
    final overlay = find.byKey(const ValueKey('local-handoff-overlay'));
    final barrier = find.descendant(
      of: overlay,
      matching: find.byType(ModalBarrier),
    );
    final curtain = tester.widget<ModalBarrier>(barrier);
    expect(curtain.dismissible, isFalse);
    expect(curtain.color!.a, 1);
    expect(tester.getSize(barrier), tester.getSize(find.byType(MapScreen)));
    expect(
      find.byKey(const ValueKey('open-research')).hitTestable(),
      findsNothing,
    );
    await idle();
    final before = requests.length;
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapAt(tester.getTopLeft(barrier) + const Offset(8, 8));
    await idle();
    expect(requests.length, before);
    expect(ready.localHandoff.blocksGameplay, isTrue);
    expect(ready.interaction.selectedUnitId, isNull);
    expect(ready.interaction.researchFocused, isFalse);
  }

  Future<void> confirmPrivateHandoff(String actor) async {
    await tap(const ValueKey('confirm-local-handoff'));
    await until(
      () =>
          !ready.localHandoff.blocksGameplay &&
          ready.recipient.actorPlayerId == actor &&
          ready.interaction.selectedUnitId == '$actor-commander',
      'automatic unit focus for $actor after confirmation',
    );
    expect(find.byKey(const ValueKey('local-handoff-overlay')), findsNothing);
    await idle();
  }

  Future<void> skipAndChooseResearch() async {
    await tap(const ValueKey(('unit-action', 'skip')));
    await until(
      () => ready.interaction.researchFocused,
      'research focus for the next human participant',
    );
    await selectResearch();
  }
}
