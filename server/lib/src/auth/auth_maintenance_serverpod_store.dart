import 'package:aonw_server/src/auth/auth_maintenance_service.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/core.dart' as auth_idp;

/// Serverpod-backed maintenance store. Candidate IDs are selected first and
/// the expiry predicate is checked again during deletion. This bounds returned
/// rows and prevents refresh-token rotation racing with maintenance from
/// deleting a newly refreshed token.
final class ServerpodAuthMaintenanceStore implements AuthMaintenanceStore {
  ServerpodAuthMaintenanceStore(this._session);

  final Session _session;

  @override
  Future<int> deleteExpiredRefreshTokens({
    required DateTime cutoff,
    required int limit,
  }) async {
    final candidates = await auth_core.RefreshToken.db.find(
      _session,
      where: (table) => table.lastUpdatedAt < cutoff,
      orderBy: (table) => table.lastUpdatedAt,
      limit: limit,
    );
    final ids = _requiredIds(candidates.map((row) => row.id));
    if (ids.isEmpty) return 0;

    final deleted = await auth_core.RefreshToken.db.deleteWhere(
      _session,
      where: (table) => table.id.inSet(ids) & (table.lastUpdatedAt < cutoff),
    );
    return deleted.length;
  }

  @override
  Future<int> deleteExpiredSteamAuthRequests({
    required DateTime cutoff,
    required int limit,
  }) async {
    final candidates = await SteamAuthRequest.db.find(
      _session,
      where: (table) => table.expiresAt < cutoff,
      orderBy: (table) => table.expiresAt,
      limit: limit,
    );
    final ids = _requiredIds(candidates.map((row) => row.id));
    if (ids.isEmpty) return 0;

    final deleted = await SteamAuthRequest.db.deleteWhere(
      _session,
      where: (table) => table.id.inSet(ids) & (table.expiresAt < cutoff),
    );
    return deleted.length;
  }

  @override
  Future<int> deleteExpiredExternalAuthRequests({
    required DateTime cutoff,
    required int limit,
  }) async {
    final candidates = await ExternalAuthRequest.db.find(
      _session,
      where: (table) => table.expiresAt < cutoff,
      orderBy: (table) => table.expiresAt,
      limit: limit,
    );
    final ids = _requiredIds(candidates.map((row) => row.id));
    if (ids.isEmpty) return 0;

    final deleted = await ExternalAuthRequest.db.deleteWhere(
      _session,
      where: (table) => table.id.inSet(ids) & (table.expiresAt < cutoff),
    );
    return deleted.length;
  }

  @override
  Future<int> deleteExpiredRateLimitAttempts({
    required DateTime cutoff,
    required int limit,
  }) async {
    // Serverpod verifies module-owned table indexes exactly against the module
    // protocol. A downstream (domain, attemptedAt) index would make startup
    // integrity checks fail. Returned/deleted work remains batch-capped, and
    // the coordinator schedules one-minute follow-ups when the cap is reached.
    final candidates = await auth_idp.RateLimitedRequestAttempt.db.find(
      _session,
      where: (table) =>
          table.domain.equals(aonwAuthRateLimitDomain) &
          (table.attemptedAt < cutoff),
      orderBy: (table) => table.attemptedAt,
      limit: limit,
    );
    final ids = _requiredIds(candidates.map((row) => row.id));
    if (ids.isEmpty) return 0;

    final deleted = await auth_idp.RateLimitedRequestAttempt.db.deleteWhere(
      _session,
      where: (table) =>
          table.id.inSet(ids) &
          table.domain.equals(aonwAuthRateLimitDomain) &
          (table.attemptedAt < cutoff),
    );
    return deleted.length;
  }
}

Set<UuidValue> _requiredIds(Iterable<UuidValue?> values) {
  final ids = <UuidValue>{};
  for (final value in values) {
    if (value == null) {
      throw StateError('A persisted auth maintenance candidate has no ID.');
    }
    ids.add(value);
  }
  return ids;
}
