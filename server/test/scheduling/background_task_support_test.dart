import 'dart:async';

import 'package:aonw_server/src/scheduling/background_task_support.dart';
import 'package:test/test.dart';

void main() {
  test('close during start cannot install a timer after shutdown', () async {
    final initialStarted = Completer<void>();
    final releaseInitial = Completer<void>();
    var calls = 0;
    final reconciler = FutureCallScheduleReconciler(
      reconcileInterval: const Duration(hours: 1),
      initialDelay: const Duration(seconds: 1),
      recoveryDelay: const Duration(seconds: 2),
      ensureScheduled: ({required delay, required accelerateExisting}) async {
        calls += 1;
        initialStarted.complete();
        await releaseInitial.future;
        return true;
      },
    );

    final start = reconciler.start();
    await initialStarted.future;
    var closeCompleted = false;
    final close = reconciler.close().then((_) => closeCompleted = true);
    await Future<void>.delayed(Duration.zero);

    expect(closeCompleted, isFalse);
    releaseInitial.complete();
    await Future.wait([start, close]);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(calls, 1);
  });

  test('concurrent start calls share the initial reconciliation', () async {
    final initialStarted = Completer<void>();
    final releaseInitial = Completer<void>();
    var calls = 0;
    final reconciler = FutureCallScheduleReconciler(
      reconcileInterval: const Duration(hours: 1),
      initialDelay: const Duration(seconds: 1),
      recoveryDelay: const Duration(seconds: 2),
      ensureScheduled: ({required delay, required accelerateExisting}) async {
        calls += 1;
        initialStarted.complete();
        await releaseInitial.future;
        return true;
      },
    );

    final first = reconciler.start();
    final second = reconciler.start();
    await initialStarted.future;
    expect(calls, 1);

    releaseInitial.complete();
    await Future.wait([first, second]);
    await reconciler.close();
    expect(calls, 1);
  });
}
