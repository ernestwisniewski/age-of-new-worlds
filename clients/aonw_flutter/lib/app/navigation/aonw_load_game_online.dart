import '../../features/multiplayer/application/multiplayer_state.dart';
import '../../features/multiplayer/presentation/multiplayer_controller.dart';
import '../../features/multiplayer/read_model/multiplayer_view.dart';
import '../../features/save_game/application/local_save_summary.dart';

typedef OnlineProjectionOpen =
    Future<bool> Function(MultiplayerProjectionView projection);
typedef OnlineWaitingRoomOpen = Future<void> Function();

final class AonwLoadGameOnline {
  const AonwLoadGameOnline(this._controller);

  final MultiplayerController _controller;

  OnlineSaveIndexView index({required bool available}) {
    if (!available) {
      return const OnlineSaveIndexView(
        phase: OnlineSaveIndexPhaseView.unavailable,
      );
    }
    return switch (_controller.state) {
      MultiplayerStarting() || MultiplayerAuthenticating() =>
        const OnlineSaveIndexView(phase: OnlineSaveIndexPhaseView.loading),
      MultiplayerSignedOut(:final failureCode) => OnlineSaveIndexView(
        phase: OnlineSaveIndexPhaseView.signedOut,
        failureCode: failureCode,
      ),
      MultiplayerLobby(:final matches, :final failureCode) =>
        OnlineSaveIndexView(
          phase: OnlineSaveIndexPhaseView.ready,
          saves: _activeSaves(matches),
          failureCode: failureCode,
        ),
      MultiplayerWaitingRoom(:final lobby, :final failureCode) =>
        OnlineSaveIndexView(
          phase: OnlineSaveIndexPhaseView.ready,
          saves: _activeSaves([lobby.match]),
          failureCode: failureCode,
        ),
      MultiplayerInMatch(:final lobby, :final failureCode) =>
        OnlineSaveIndexView(
          phase: OnlineSaveIndexPhaseView.ready,
          saves: _activeSaves([lobby.match]),
          failureCode: failureCode,
        ),
    };
  }

  Future<bool> resume({
    required String matchId,
    required bool available,
    required OnlineProjectionOpen openGame,
    required OnlineWaitingRoomOpen openWaitingRoom,
  }) async {
    if (!available) return false;
    final current = _controller.state;
    if (current case MultiplayerInMatch(
      :final projection,
      :final lobby,
    ) when projection.matchId == matchId && _isActive(lobby.match)) {
      await _controller.reconnect();
      return _openResolvedState(matchId, openGame, openWaitingRoom);
    }
    if (current case MultiplayerWaitingRoom(
      :final lobby,
    ) when lobby.match.matchId == matchId && _isActive(lobby.match)) {
      await openWaitingRoom();
      return true;
    }
    if (current is! MultiplayerLobby) return false;
    final match = _findActiveMatch(current.matches, matchId);
    if (match == null) return false;
    await _controller.openMatch(match);
    return _openResolvedState(matchId, openGame, openWaitingRoom);
  }

  Future<bool> _openResolvedState(
    String matchId,
    OnlineProjectionOpen openGame,
    OnlineWaitingRoomOpen openWaitingRoom,
  ) async {
    final resolved = _controller.state;
    if (resolved case MultiplayerInMatch(
      :final projection,
      :final lobby,
    ) when projection.matchId == matchId && _isActive(lobby.match)) {
      return openGame(projection);
    }
    if (resolved case MultiplayerWaitingRoom(
      :final lobby,
    ) when lobby.match.matchId == matchId && _isActive(lobby.match)) {
      await openWaitingRoom();
      return true;
    }
    return false;
  }

  static List<OnlineSaveSummaryView> _activeSaves(
    List<MultiplayerMatchView> matches,
  ) => [
    for (final match in matches)
      if (_isActive(match)) _save(match),
  ];

  static MultiplayerMatchView? _findActiveMatch(
    List<MultiplayerMatchView> matches,
    String matchId,
  ) {
    for (final match in matches) {
      if (match.matchId == matchId && _isActive(match)) return match;
    }
    return null;
  }

  static bool _isActive(MultiplayerMatchView match) =>
      match.phase == MultiplayerMatchPhase.lobby ||
      match.phase == MultiplayerMatchPhase.running;

  static OnlineSaveSummaryView _save(MultiplayerMatchView match) =>
      OnlineSaveSummaryView(
        matchId: match.matchId,
        mapId: match.mapId,
        phase: switch (match.phase) {
          MultiplayerMatchPhase.lobby => OnlineSavePhaseView.lobby,
          _ => OnlineSavePhaseView.running,
        },
      );
}
