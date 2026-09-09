import '../../local_game/application/local_game_catalog.dart';
import '../../map/read_model/player_map_view.dart';
import 'local_save_store.dart';

/// Bounded automatic slots, separate from named player saves.
abstract interface class LocalAutosaveStore {
  Future<LocalSaveSlotView> writeAutomatic({
    required LocalGameScenarioView scenario,
    required bool privateHandoff,
    required MatchTurnModeView turnMode,
    required String document,
  });
}
