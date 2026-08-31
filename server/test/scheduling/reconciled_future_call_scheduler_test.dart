import 'package:aonw_server/src/scheduling/reconciled_future_call_scheduler.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 10, 12);

  test('inserts when no call is queued', () {
    final deadline = now.add(const Duration(hours: 6));

    final plan = planReconciledFutureCall(
      existing: const [],
      callName: 'authMaintenance',
      notAfter: deadline,
    );

    expect(plan.insert, isTrue);
    expect(plan.scheduledAt, deadline);
    expect(plan.duplicateIds, isEmpty);
  });

  test('keeps an existing call that is already earlier', () {
    final existingTime = now.add(const Duration(minutes: 30));

    final plan = planReconciledFutureCall(
      existing: [
        ReconciledFutureCallState(
          id: 1,
          name: 'authMaintenance',
          time: existingTime,
          hasSerializedObject: false,
        ),
      ],
      callName: 'authMaintenance',
      notAfter: now.add(const Duration(hours: 6)),
    );

    expect(plan.insert, isFalse);
    expect(plan.updateKeeper, isFalse);
    expect(plan.scheduledAt, existingTime);
  });

  test('accelerates the earliest call and removes duplicate entries', () {
    final deadline = now.add(const Duration(minutes: 1));

    final plan = planReconciledFutureCall(
      existing: [
        ReconciledFutureCallState(
          id: 2,
          name: 'authMaintenance',
          time: now.add(const Duration(hours: 8)),
          hasSerializedObject: false,
        ),
        ReconciledFutureCallState(
          id: 1,
          name: 'authMaintenance',
          time: now.add(const Duration(hours: 6)),
          hasSerializedObject: false,
        ),
        ReconciledFutureCallState(
          id: 3,
          name: 'authMaintenance',
          time: now.add(const Duration(hours: 10)),
          hasSerializedObject: false,
        ),
      ],
      callName: 'authMaintenance',
      notAfter: deadline,
    );

    expect(plan.keeperId, 1);
    expect(plan.accelerated, isTrue);
    expect(plan.updateKeeper, isTrue);
    expect(plan.scheduledAt, deadline);
    expect(plan.duplicateIds, {2, 3});
  });

  test('repairs a stale name or serialized argument', () {
    final existingTime = now.add(const Duration(hours: 1));

    final plan = planReconciledFutureCall(
      existing: [
        ReconciledFutureCallState(
          id: 1,
          name: 'oldAuthMaintenance',
          time: existingTime,
          hasSerializedObject: true,
        ),
      ],
      callName: 'authMaintenance',
      notAfter: now.add(const Duration(hours: 6)),
    );

    expect(plan.repaired, isTrue);
    expect(plan.updateKeeper, isTrue);
    expect(plan.scheduledAt, existingTime);
  });

  test('missing-call reconciliation does not accelerate existing work', () {
    final existingTime = now.add(const Duration(hours: 6));

    final plan = planReconciledFutureCall(
      existing: [
        ReconciledFutureCallState(
          id: 1,
          name: 'authMaintenance',
          time: existingTime,
          hasSerializedObject: false,
        ),
      ],
      callName: 'authMaintenance',
      notAfter: now.add(const Duration(minutes: 15)),
      accelerateExisting: false,
    );

    expect(plan.updateKeeper, isFalse);
    expect(plan.accelerated, isFalse);
    expect(plan.scheduledAt, existingTime);
  });
}
