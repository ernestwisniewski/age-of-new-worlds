import 'package:serverpod/protocol.dart' show FutureCallEntry;
import 'package:serverpod/serverpod.dart';

/// Reconciles one identifier to one queued, argument-free FutureCall.
///
/// The PostgreSQL advisory transaction lock makes the read/update/insert
/// sequence safe across server instances. Existing work is never cancelled,
/// and a requested earlier deadline accelerates the queued call in place.
final class ReconciledFutureCallScheduler {
  const ReconciledFutureCallScheduler({
    required this.callName,
    required this.identifier,
    required this.lockName,
  });

  final String callName;
  final String identifier;
  final String lockName;

  Future<ReconciledFutureCallResult> scheduleNoLaterThan(
    Session session, {
    required String serverId,
    required DateTime notAfter,
    bool accelerateExisting = true,
  }) async {
    final deadline = notAfter.toUtc();
    return session.db.transaction((transaction) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtext(@lockName))',
        transaction: transaction,
        parameters: QueryParameters.named({'lockName': lockName}),
      );
      final entries = await FutureCallEntry.db.find(
        session,
        where: (table) => table.identifier.equals(identifier),
        orderBy: (table) => table.time,
        transaction: transaction,
      );
      final plan = planReconciledFutureCall(
        existing: [
          for (final entry in entries)
            ReconciledFutureCallState(
              id: _requiredId(entry),
              name: entry.name,
              time: entry.time,
              hasSerializedObject: entry.serializedObject != null,
            ),
        ],
        callName: callName,
        notAfter: deadline,
        accelerateExisting: accelerateExisting,
      );

      if (plan.insert) {
        await FutureCallEntry.db.insertRow(
          session,
          FutureCallEntry(
            name: callName,
            time: deadline,
            serverId: serverId,
            identifier: identifier,
          ),
          transaction: transaction,
        );
      } else if (plan.updateKeeper) {
        final keeper = entries.singleWhere(
          (entry) => entry.id == plan.keeperId,
        );
        await FutureCallEntry.db.updateRow(
          session,
          keeper.copyWith(
            name: callName,
            time: plan.scheduledAt,
            serializedObject: null,
          ),
          transaction: transaction,
        );
      }

      if (plan.duplicateIds.isNotEmpty) {
        await FutureCallEntry.db.deleteWhere(
          session,
          where: (table) => table.id.inSet(plan.duplicateIds),
          transaction: transaction,
        );
      }

      return ReconciledFutureCallResult(
        inserted: plan.insert,
        accelerated: plan.accelerated,
        repaired: plan.repaired,
        duplicatesRemoved: plan.duplicateIds.length,
        scheduledAt: plan.scheduledAt,
      );
    });
  }
}

final class ReconciledFutureCallResult {
  const ReconciledFutureCallResult({
    required this.inserted,
    required this.accelerated,
    required this.repaired,
    required this.duplicatesRemoved,
    required this.scheduledAt,
  });

  final bool inserted;
  final bool accelerated;
  final bool repaired;
  final int duplicatesRemoved;
  final DateTime scheduledAt;
}

final class ReconciledFutureCallState {
  const ReconciledFutureCallState({
    required this.id,
    required this.name,
    required this.time,
    required this.hasSerializedObject,
  });

  final int id;
  final String name;
  final DateTime time;
  final bool hasSerializedObject;
}

final class ReconciledFutureCallPlan {
  const ReconciledFutureCallPlan({
    required this.insert,
    required this.keeperId,
    required this.updateKeeper,
    required this.accelerated,
    required this.repaired,
    required this.duplicateIds,
    required this.scheduledAt,
  });

  final bool insert;
  final int? keeperId;
  final bool updateKeeper;
  final bool accelerated;
  final bool repaired;
  final Set<int> duplicateIds;
  final DateTime scheduledAt;
}

ReconciledFutureCallPlan planReconciledFutureCall({
  required List<ReconciledFutureCallState> existing,
  required String callName,
  required DateTime notAfter,
  bool accelerateExisting = true,
}) {
  final deadline = notAfter.toUtc();
  if (existing.isEmpty) {
    return ReconciledFutureCallPlan(
      insert: true,
      keeperId: null,
      updateKeeper: false,
      accelerated: false,
      repaired: false,
      duplicateIds: const <int>{},
      scheduledAt: deadline,
    );
  }

  final ordered = [...existing]
    ..sort((left, right) => left.time.compareTo(right.time));
  final keeper = ordered.first;
  final scheduledAt = accelerateExisting && keeper.time.isAfter(deadline)
      ? deadline
      : keeper.time.toUtc();
  final accelerated = scheduledAt.isBefore(keeper.time);
  final repaired = keeper.name != callName || keeper.hasSerializedObject;
  final duplicateIds = <int>{
    for (final duplicate in ordered.skip(1)) duplicate.id,
  };

  return ReconciledFutureCallPlan(
    insert: false,
    keeperId: keeper.id,
    updateKeeper: accelerated || repaired,
    accelerated: accelerated,
    repaired: repaired,
    duplicateIds: Set.unmodifiable(duplicateIds),
    scheduledAt: scheduledAt,
  );
}

int _requiredId(FutureCallEntry entry) {
  final id = entry.id;
  if (id == null) {
    throw StateError('A persisted FutureCall entry has no ID.');
  }
  return id;
}
