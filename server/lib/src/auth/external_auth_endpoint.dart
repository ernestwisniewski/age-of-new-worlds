import 'package:aonw_server/src/auth/external_auth_service.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class ExternalAuthEndpoint extends Endpoint {
  final _service = ExternalAuthService();

  @unauthenticatedClientCall
  Future<ExternalAuthStart> start(Session session, {required String provider}) {
    return _service.start(session, provider: provider);
  }

  @unauthenticatedClientCall
  Future<ExternalAuthPollResult> poll(
    Session session, {
    required String requestId,
  }) {
    return _service.poll(session, requestId: requestId);
  }
}
