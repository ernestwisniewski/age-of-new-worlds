import 'package:aonw_server/src/auth/auth_maintenance_serverpod_store.dart';
import 'package:aonw_server/src/auth/auth_maintenance_service.dart';
import 'package:aonw_server/src/scheduling/background_task_support.dart';
import 'package:aonw_server/src/scheduling/reconciled_future_call_scheduler.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;

const authMaintenanceFutureCallName = 'authMaintenance';
const authMaintenanceFutureCallIdentifier = 'auth-maintenance';
const authMaintenanceScheduleReconcileInterval = Duration(minutes: 15);
const authMaintenanceReconcilerShutdownTaskId =
    'auth-maintenance-schedule-reconciler';

const _authMaintenanceScheduler = ReconciledFutureCallScheduler(
  callName: authMaintenanceFutureCallName,
  identifier: authMaintenanceFutureCallIdentifier,
  lockName: 'aonw_auth_maintenance_schedule',
);

final class AuthMaintenanceFutureCall extends FutureCall<SerializableModel> {
  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    final now = DateTime.now().toUtc();
    final followUpScheduled = await _trySchedule(
      session,
      now: now,
      delay: authMaintenanceInterval,
    );
    var followUpDelay = authMaintenanceInterval;

    try {
      final jwtManager =
          auth_core.AuthServices.getTokenManager<auth_core.JwtTokenManager>();
      final result = await const AuthMaintenanceService().run(
        store: ServerpodAuthMaintenanceStore(session),
        now: now,
        refreshTokenLifetime: jwtManager.jwt.config.refreshTokenLifetime,
      );
      followUpDelay = authMaintenanceFollowUpDelay(result);

      for (final failure in result.failures) {
        _logFailure(
          session,
          target: failure.target.name,
          kind: failure.kind,
          stackTrace: failure.stackTrace,
        );
      }
      if (result.backlogRemaining) {
        final targets = result.backlogTargets
            .map((target) => target.name)
            .join(',');
        session.log(
          'event=auth_maintenance_backlog targets=$targets '
          'follow_up_seconds=${followUpDelay.inSeconds}',
          level: LogLevel.warning,
        );
      }
      if (result.totalDeleted > 0) {
        _logMaintenanceCompletion(session, result);
      }
    } catch (error, stackTrace) {
      followUpDelay = authMaintenanceFailureFollowUpInterval;
      _logFailure(
        session,
        target: 'orchestration',
        kind: authMaintenanceErrorKind(error),
        stackTrace: stackTrace,
      );
    }

    if (!followUpScheduled || followUpDelay < authMaintenanceInterval) {
      await _trySchedule(session, now: now, delay: followUpDelay);
    }
  }
}

void _logMaintenanceCompletion(Session session, AuthMaintenanceResult result) {
  session.log(
    'event=auth_maintenance_completed '
    'refresh_tokens=${result.deletedRefreshTokens} '
    'steam_requests=${result.deletedSteamAuthRequests} '
    'external_auth_requests=${result.deletedExternalAuthRequests} '
    'rate_limit_attempts=${result.deletedRateLimitAttempts}',
    level: LogLevel.info,
  );
}

final class AuthMaintenanceScheduleReconciler {
  AuthMaintenanceScheduleReconciler(Serverpod pod)
    : _delegate = FutureCallScheduleReconciler(
        reconcileInterval: authMaintenanceScheduleReconcileInterval,
        initialDelay: authMaintenanceScheduleReconcileInterval,
        recoveryDelay: authMaintenanceScheduleReconcileInterval,
        ensureScheduled: ({required delay, required accelerateExisting}) =>
            ensureAuthMaintenanceScheduled(
              pod,
              delay: delay,
              accelerateExisting: accelerateExisting,
            ),
      );

  final FutureCallScheduleReconciler _delegate;

  Future<void> start() => _delegate.start();

  Future<void> close() => _delegate.close();
}

Future<bool> ensureAuthMaintenanceScheduled(
  Serverpod pod, {
  Duration delay = authMaintenanceInterval,
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
    final result = await _authMaintenanceScheduler.scheduleNoLaterThan(
      session,
      serverId: session.serverpod.serverId,
      notAfter: now.add(delay),
      accelerateExisting: accelerateExisting,
    );
    if (result.duplicatesRemoved > 0 || result.repaired) {
      session.log(
        'event=auth_maintenance_schedule_reconciled '
        'duplicates_removed=${result.duplicatesRemoved} '
        'repaired=${result.repaired}',
        level: LogLevel.warning,
      );
    }
    return true;
  } catch (error, stackTrace) {
    _logFailure(
      session,
      target: 'scheduler',
      kind: authMaintenanceErrorKind(error),
      stackTrace: stackTrace,
    );
    return false;
  }
}

void _logFailure(
  Session session, {
  required String target,
  required AuthMaintenanceErrorKind kind,
  required StackTrace stackTrace,
}) {
  session.log(
    'event=auth_maintenance_failure target=$target error_kind=${kind.name}',
    level: LogLevel.error,
    stackTrace: stackTrace,
  );
}
