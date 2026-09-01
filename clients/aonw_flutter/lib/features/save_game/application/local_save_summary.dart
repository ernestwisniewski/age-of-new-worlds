import '../../local_game/application/local_game_catalog.dart';
import '../../map/read_model/player_map_view.dart';

enum LocalSaveGameModeView { singlePlayer, hotseat }

final class LocalSaveSummaryView {
  const LocalSaveSummaryView.ready({
    required this.scenario,
    required this.gameMode,
    required this.turnMode,
    required this.turn,
    required this.recoveredFromBackup,
  }) : compatible = true;

  const LocalSaveSummaryView.incompatible({required this.scenario})
    : gameMode = null,
      turnMode = null,
      turn = null,
      recoveredFromBackup = false,
      compatible = false;

  final LocalGameScenarioView scenario;
  final LocalSaveGameModeView? gameMode;
  final MatchTurnModeView? turnMode;
  final int? turn;
  final bool recoveredFromBackup;
  final bool compatible;
}

enum OnlineSavePhaseView { lobby, running }

final class OnlineSaveSummaryView {
  const OnlineSaveSummaryView({
    required this.matchId,
    required this.mapId,
    required this.phase,
  });

  final String matchId;
  final String mapId;
  final OnlineSavePhaseView phase;
}

enum OnlineSaveIndexPhaseView { unavailable, loading, signedOut, ready, failed }

final class OnlineSaveIndexView {
  const OnlineSaveIndexView({
    required this.phase,
    this.saves = const [],
    this.failureCode,
  });

  final OnlineSaveIndexPhaseView phase;
  final List<OnlineSaveSummaryView> saves;
  final String? failureCode;
}
