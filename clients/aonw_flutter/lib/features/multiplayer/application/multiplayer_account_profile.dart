part of 'multiplayer_coordinator.dart';

extension MultiplayerAccountProfile on MultiplayerCoordinator {
  Future<AccountProfileView> readProfile() async {
    if (_state is MultiplayerStarting) await initialize();
    return _requestProfile((port) => port.readProfile());
  }

  Future<AccountProfileView> updateDisplayName(String displayName) =>
      _requestProfile((port) => port.updateDisplayName(displayName));

  Future<AccountProfileView> _requestProfile(
    Future<AccountProfileView> Function(AccountProfilePort) request,
  ) async {
    final id = _profileUserId;
    final session = _session;
    if (_closed || id == null) {
      throw const MultiplayerSessionException(
        code: 'authentication_required',
        message: 'Authentication is required to access the profile.',
      );
    }
    if (session is! AccountProfilePort) {
      throw const MultiplayerSessionException(
        code: 'profile_unavailable',
        message: 'The account profile is unavailable.',
      );
    }
    final generation = _generation;
    final result = await request(session as AccountProfilePort);
    if (!_isCurrent(generation) || _profileUserId != id) {
      throw const MultiplayerSessionException(
        code: 'profile_session_changed',
        message: 'The account changed during the profile request.',
      );
    }
    if (result.userId != id || result.displayName.trim().isEmpty) {
      throw const MultiplayerSessionException(
        code: 'invalid_profile_response',
        message: 'The profile response does not match the account.',
      );
    }
    return result;
  }

  String? get _profileUserId => switch (_state) {
    MultiplayerLobby(:final account) ||
    MultiplayerWaitingRoom(:final account) ||
    MultiplayerInMatch(:final account) => account.userId,
    _ => null,
  };
}
