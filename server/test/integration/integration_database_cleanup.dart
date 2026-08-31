import 'package:aonw_server/src/auth/auth_rate_limit_constants.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart' as auth_idp;

Future<void> clearAonwAuthRateLimitAttempts(Session session) async {
  await auth_idp.RateLimitedRequestAttempt.db.deleteWhere(
    session,
    where: (table) => table.domain.equals(aonwAuthRateLimitDomain),
  );
}
