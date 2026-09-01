import 'package:aonw_server/src/game/service/game_turn_timeout_policy.dart';
import 'package:aonw_server/src/game/service/game_turn_timeout_service.dart';
import 'package:aonw_server/src/scheduling/background_task_support.dart';
import 'package:aonw_server/src/scheduling/reconciled_future_call_scheduler.dart';
import 'package:serverpod/serverpod.dart';

const gameTurnTimeoutFutureCallName = 'gameTurnTimeout';
const gameTurnTimeoutFutureCallIdentifier = 'game-turn-timeout';
const gameTurnTimeoutReconcilerShutdownTaskId =
    'game-turn-timeout-schedule-reconciler';

const _gameTurnTimeoutScheduler = ReconciledFutureCallScheduler(
  callName: gameTurnTimeoutFutureCallName,
  identifier: gameTurnTimeoutFutureCallIdentifier,
  lockName: 'aonw_game_turn_timeout_schedule',
);

final class GameTurnTimeoutFutureCall extends FutureCall<SerializableModel> {
  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    final now = DateTime.now().toUtc();
    final followUpScheduled = await _trySchedule(
      session,
      now: now,
      delay: gameTurnTimeoutScanInterval,
    );
    var followUpDelay = gameTurnTimeoutScanInterval;
    try {
      final result = await const GameTurnTimeoutService().run(
        session,
        now: now,
      );
      if (result.backlogRemaining) followUpDelay = gameTurnTimeoutBacklogDelay;
      for (final failure in result.failures) {
        session.log(
          'event=game_turn_timeout_failed match_id=${failure.matchId} '
          'kind=${failure.kind.name}',
          level: LogLevel.error,
          stackTrace: failure.stackTrace,
        );
      }
      if (result.finalized > 0 || result.backlogRemaining) {
        session.log(
          'event=game_turn_timeout_completed '
          'candidates=${result.candidates} finalized=${result.finalized} '
          'backlog=${result.backlogRemaining}',
          level: result.failures.isEmpty ? LogLevel.info : LogLevel.warning,
        );
      }
    } catch (error, stackTrace) {
      followUpDelay = gameTurnTimeoutBacklogDelay;
      session.log(
        'event=game_turn_timeout_orchestration_failed '
        'kind=${backgroundTaskErrorKind(error).name}',
        level: LogLevel.error,
        exception: error,
        stackTrace: stackTrace,
      );
    }
    if (!followUpScheduled || followUpDelay < gameTurnTimeoutScanInterval) {
      await _trySchedule(session, now: now, delay: followUpDelay);
    }
  }
}

final class GameTurnTimeoutScheduleReconciler {
  GameTurnTimeoutScheduleReconciler(Serverpod pod)
    : _delegate = FutureCallScheduleReconciler(
        reconcileInterval: gameTurnTimeoutScanInterval,
        initialDelay: gameTurnTimeoutScanInterval,
        recoveryDelay: gameTurnTimeoutScanInterval,
        ensureScheduled: ({required delay, required accelerateExisting}) =>
            ensureGameTurnTimeoutScheduled(
              pod,
              delay: delay,
              accelerateExisting: accelerateExisting,
            ),
      );

  final FutureCallScheduleReconciler _delegate;

  Future<void> start() => _delegate.start();

  Future<void> close() => _delegate.close();
}

bool registerGameTurnTimeout(Serverpod pod) {
  try {
    pod.registerFutureCall(
      GameTurnTimeoutFutureCall(),
      gameTurnTimeoutFutureCallName,
    );
    return true;
  } on StateError {
    return false;
  }
}

Future<bool> ensureGameTurnTimeoutScheduled(
  Serverpod pod, {
  Duration delay = gameTurnTimeoutScanInterval,
  bool accelerateExisting = true,
}) async {
  final session = await pod.createSession(enableLogging: true);
  try {
    return await _trySchedule(
      session,
      now: DateTime.now().toUtc(),
      delay: delay,
      accelerateExisting: accelerateExisting,
    );
  } finally {
    await session.close();
  }
}

Future<bool> _trySchedule(
  Session session, {
  required DateTime now,
  required Duration delay,
  bool accelerateExisting = true,
}) async {
  try {
    final result = await _gameTurnTimeoutScheduler.scheduleNoLaterThan(
      session,
      serverId: session.serverpod.serverId,
      notAfter: now.add(delay),
      accelerateExisting: accelerateExisting,
    );
    if (result.duplicatesRemoved > 0 || result.repaired) {
      session.log(
        'event=game_turn_timeout_schedule_reconciled '
        'duplicates_removed=${result.duplicatesRemoved} '
        'repaired=${result.repaired}',
        level: LogLevel.warning,
      );
    }
    return true;
  } catch (error, stackTrace) {
    session.log(
      'event=game_turn_timeout_schedule_failed '
      'kind=${backgroundTaskErrorKind(error).name}',
      level: LogLevel.error,
      exception: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}
