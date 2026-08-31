import 'package:aonw_server/src/auth/steam_auth_service.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class SteamAuthEndpoint extends Endpoint {
  final _service = SteamAuthService();

  @unauthenticatedClientCall
  Future<SteamAuthStart> start(Session session) {
    return _service.start(session);
  }

  @unauthenticatedClientCall
  Future<SteamAuthPollResult> poll(
    Session session, {
    required String requestId,
  }) {
    return _service.poll(session, requestId: requestId);
  }
}
