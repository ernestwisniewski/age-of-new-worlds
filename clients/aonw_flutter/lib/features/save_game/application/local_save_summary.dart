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
