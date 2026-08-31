import '../../artifacts/application/artifact_session_port.dart';
import '../../cities/application/city_session_port.dart';
import '../../combat/application/combat_session_port.dart';
import '../../diplomacy/application/diplomacy_session_port.dart';
import '../../local_game/application/local_game_session_port.dart';
import '../../logistics/application/unit_logistics_session_port.dart';
import '../../production/application/production_session_port.dart';
import '../../research/application/research_session_port.dart';
import '../../save_game/application/game_save_session_port.dart';
import '../../turns/application/turn_session_port.dart';
import '../../unit_actions/application/unit_action_session_port.dart';
import '../../workers/application/worker_session_port.dart';
import 'map_session_port.dart';
import 'movement_session_port.dart';

/// Complete compile-time session wiring required by the gameplay application.
final class GameSessionCapabilities {
  const GameSessionCapabilities({
    required this.map,
    required this.movement,
    required this.combat,
    required this.cities,
    required this.logistics,
    required this.workers,
    required this.production,
    required this.artifacts,
    required this.research,
    required this.diplomacy,
    required this.unitActions,
    required this.turns,
    this.localGame,
    this.save,
  });

  final MapSessionPort map;
  final MovementSessionPort movement;
  final CombatSessionPort combat;
  final CitySessionPort cities;
  final UnitLogisticsSessionPort logistics;
  final WorkerSessionPort workers;
  final ProductionSessionPort production;
  final ArtifactSessionPort artifacts;
  final ResearchSessionPort research;
  final DiplomacySessionPort diplomacy;
  final UnitActionSessionPort unitActions;
  final TurnSessionPort turns;
  final LocalGameSessionPort? localGame;
  final GameSaveSessionPort? save;
}
