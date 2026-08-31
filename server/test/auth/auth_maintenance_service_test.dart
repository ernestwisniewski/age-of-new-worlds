import 'package:aonw_server/src/auth/auth_maintenance_service.dart';
import 'package:test/test.dart';

void main() {
  const refreshLifetime = Duration(days: 14);
  final now = DateTime.utc(2026, 7, 10, 12);

  test(
    'uses conservative retention cutoffs and the configured batch size',
    () async {
      final store = _FakeAuthMaintenanceStore();

      await const AuthMaintenanceService().run(
        store: store,
        now: now,
        refreshTokenLifetime: refreshLifetime,
      );

      expect(store.refreshCalls, [
        _DeleteCall(
          cutoff: now
              .subtract(refreshLifetime)
              .subtract(expiredRefreshTokenRetention),
          limit: authMaintenanceBatchSize,
        ),
      ]);
      expect(store.steamCalls, [
        _DeleteCall(
          cutoff: now.subtract(expiredSteamAuthRequestRetention),
          limit: authMaintenanceBatchSize,
        ),
      ]);
      expect(store.externalCalls, [
        _DeleteCall(
          cutoff: now.subtract(expiredExternalAuthRequestRetention),
          limit: authMaintenanceBatchSize,
        ),
      ]);
      expect(store.rateLimitCalls, [
        _DeleteCall(
          cutoff: now.subtract(expiredAuthRateLimitAttemptRetention),
          limit: authMaintenanceBatchSize,
        ),
      ]);
    },
  );

  test(
    'continues full batches and stops each table on a short batch',
    () async {
      final store = _FakeAuthMaintenanceStore(
        refreshResults: [2, 2, 1],
        steamResults: [0],
        rateLimitResults: [2, 0],
      );

      final result = await const AuthMaintenanceService(
        batchSize: 2,
        maxBatchesPerTable: 10,
      ).run(store: store, now: now, refreshTokenLifetime: refreshLifetime);

      expect(result.deletedRefreshTokens, 5);
      expect(result.deletedSteamAuthRequests, 0);
      expect(result.deletedExternalAuthRequests, 0);
      expect(result.deletedRateLimitAttempts, 2);
      expect(result.totalDeleted, 7);
      expect(result.failures, isEmpty);
      expect(result.backlogRemaining, isFalse);
      expect(store.refreshCalls, hasLength(3));
      expect(store.steamCalls, hasLength(1));
      expect(store.externalCalls, hasLength(1));
      expect(store.rateLimitCalls, hasLength(2));
    },
  );

  test('caps work independently for every table', () async {
    final store = _FakeAuthMaintenanceStore(
      refreshResults: [2, 2, 2, 2],
      steamResults: [2, 2, 2, 2],
      externalResults: [2, 2, 2, 2],
      rateLimitResults: [2, 2, 2, 2],
    );

    final result = await const AuthMaintenanceService(
      batchSize: 2,
      maxBatchesPerTable: 3,
    ).run(store: store, now: now, refreshTokenLifetime: refreshLifetime);

    expect(result.deletedRefreshTokens, 6);
    expect(result.deletedSteamAuthRequests, 6);
    expect(result.deletedExternalAuthRequests, 6);
    expect(result.deletedRateLimitAttempts, 6);
    expect(result.backlogTargets, AuthMaintenanceTarget.values.toSet());
    expect(
      authMaintenanceFollowUpDelay(result),
      authMaintenanceBacklogFollowUpInterval,
    );
    expect(store.refreshCalls, hasLength(3));
    expect(store.steamCalls, hasLength(3));
    expect(store.externalCalls, hasLength(3));
    expect(store.rateLimitCalls, hasLength(3));
  });

  test(
    'isolates a table failure and continues remaining maintenance',
    () async {
      final failure = StateError('refresh storage unavailable');
      final store = _FakeAuthMaintenanceStore(
        refreshResults: [failure],
        steamResults: [1],
        rateLimitResults: [1],
      );

      final result = await const AuthMaintenanceService(
        batchSize: 2,
        maxBatchesPerTable: 3,
      ).run(store: store, now: now, refreshTokenLifetime: refreshLifetime);

      expect(result.deletedRefreshTokens, 0);
      expect(result.deletedSteamAuthRequests, 1);
      expect(result.deletedExternalAuthRequests, 0);
      expect(result.deletedRateLimitAttempts, 1);
      expect(result.failures, hasLength(1));
      expect(
        result.failures.single.target,
        AuthMaintenanceTarget.refreshTokens,
      );
      expect(
        result.failures.single.kind,
        AuthMaintenanceErrorKind.invalidState,
      );
      expect(result.failures.single.deletedBeforeFailure, 0);
      expect(
        authMaintenanceFollowUpDelay(result),
        authMaintenanceFailureFollowUpInterval,
      );
    },
  );

  test('rejects a store result larger than the requested batch', () async {
    final store = _FakeAuthMaintenanceStore(
      refreshResults: [3],
      steamResults: [0],
      rateLimitResults: [0],
    );

    final result = await const AuthMaintenanceService(
      batchSize: 2,
      maxBatchesPerTable: 3,
    ).run(store: store, now: now, refreshTokenLifetime: refreshLifetime);

    expect(result.failures, hasLength(1));
    expect(result.failures.single.target, AuthMaintenanceTarget.refreshTokens);
    expect(result.failures.single.kind, AuthMaintenanceErrorKind.invalidState);
    expect(store.steamCalls, hasLength(1));
    expect(store.rateLimitCalls, hasLength(1));
  });

  test('preserves successful batch counts when a later batch fails', () async {
    final store = _FakeAuthMaintenanceStore(
      refreshResults: [2, StateError('second batch failed')],
      steamResults: [0],
      rateLimitResults: [0],
    );

    final result = await const AuthMaintenanceService(
      batchSize: 2,
      maxBatchesPerTable: 3,
    ).run(store: store, now: now, refreshTokenLifetime: refreshLifetime);

    expect(result.deletedRefreshTokens, 2);
    expect(result.totalDeleted, 2);
    expect(result.failures, hasLength(1));
    expect(result.failures.single.deletedBeforeFailure, 2);
    expect(result.failures.single.kind, AuthMaintenanceErrorKind.invalidState);
  });

  test('maps unknown failures to a fixed privacy-safe category', () {
    expect(
      authMaintenanceErrorKind(_SensitiveError()),
      AuthMaintenanceErrorKind.unexpected,
    );
  });
}

final class _SensitiveError implements Exception {
  @override
  String toString() => 'must-not-be-logged';
}

final class _DeleteCall {
  const _DeleteCall({required this.cutoff, required this.limit});

  final DateTime cutoff;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is _DeleteCall && other.cutoff == cutoff && other.limit == limit;

  @override
  int get hashCode => Object.hash(cutoff, limit);
}

final class _FakeAuthMaintenanceStore implements AuthMaintenanceStore {
  _FakeAuthMaintenanceStore({
    List<Object>? refreshResults,
    List<Object>? steamResults,
    List<Object>? externalResults,
    List<Object>? rateLimitResults,
  }) : _refreshResults = [...?refreshResults],
       _steamResults = [...?steamResults],
       _externalResults = [...?externalResults],
       _rateLimitResults = [...?rateLimitResults];

  final List<Object> _refreshResults;
  final List<Object> _steamResults;
  final List<Object> _externalResults;
  final List<Object> _rateLimitResults;

  final List<_DeleteCall> refreshCalls = [];
  final List<_DeleteCall> steamCalls = [];
  final List<_DeleteCall> externalCalls = [];
  final List<_DeleteCall> rateLimitCalls = [];

  @override
  Future<int> deleteExpiredRefreshTokens({
    required DateTime cutoff,
    required int limit,
  }) async {
    refreshCalls.add(_DeleteCall(cutoff: cutoff, limit: limit));
    return _next(_refreshResults);
  }

  @override
  Future<int> deleteExpiredSteamAuthRequests({
    required DateTime cutoff,
    required int limit,
  }) async {
    steamCalls.add(_DeleteCall(cutoff: cutoff, limit: limit));
    return _next(_steamResults);
  }

  @override
  Future<int> deleteExpiredExternalAuthRequests({
    required DateTime cutoff,
    required int limit,
  }) async {
    externalCalls.add(_DeleteCall(cutoff: cutoff, limit: limit));
    return _next(_externalResults);
  }

  @override
  Future<int> deleteExpiredRateLimitAttempts({
    required DateTime cutoff,
    required int limit,
  }) async {
    rateLimitCalls.add(_DeleteCall(cutoff: cutoff, limit: limit));
    return _next(_rateLimitResults);
  }

  int _next(List<Object> results) {
    if (results.isEmpty) return 0;
    final result = results.removeAt(0);
    if (result case final int count) return count;
    throw result;
  }
}
