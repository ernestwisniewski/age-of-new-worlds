import '../read_model/multiplayer_view.dart';

sealed class MultiplayerState {
  const MultiplayerState();
}

final class MultiplayerStarting extends MultiplayerState {
  const MultiplayerStarting();
}

final class MultiplayerSignedOut extends MultiplayerState {
  const MultiplayerSignedOut({this.failureCode});

  final String? failureCode;
}

final class MultiplayerAuthenticating extends MultiplayerState {
  const MultiplayerAuthenticating();
}

final class MultiplayerLobby extends MultiplayerState {
  const MultiplayerLobby({
    required this.account,
    required this.matches,
    this.busy = false,
    this.failureCode,
  });

  final MultiplayerAccountView account;
  final List<MultiplayerMatchView> matches;
  final bool busy;
  final String? failureCode;

  MultiplayerLobby copyWith({
    List<MultiplayerMatchView>? matches,
    bool? busy,
    String? failureCode,
    bool clearFailure = false,
  }) => MultiplayerLobby(
    account: account,
    matches: matches ?? this.matches,
    busy: busy ?? this.busy,
    failureCode: clearFailure ? null : failureCode ?? this.failureCode,
  );
}

final class MultiplayerInMatch extends MultiplayerState {
  const MultiplayerInMatch({
    required this.account,
    required this.phase,
    required this.projection,
    this.commandPending = false,
    this.failureCode,
  });

  final MultiplayerAccountView account;
  final NetworkSessionPhase phase;
  final MultiplayerProjectionView projection;
  final bool commandPending;
  final String? failureCode;

  MultiplayerInMatch copyWith({
    NetworkSessionPhase? phase,
    MultiplayerProjectionView? projection,
    bool? commandPending,
    String? failureCode,
    bool clearFailure = false,
  }) => MultiplayerInMatch(
    account: account,
    phase: phase ?? this.phase,
    projection: projection ?? this.projection,
    commandPending: commandPending ?? this.commandPending,
    failureCode: clearFailure ? null : failureCode ?? this.failureCode,
  );
}
