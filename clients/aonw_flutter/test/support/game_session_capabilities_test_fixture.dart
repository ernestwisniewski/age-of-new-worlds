part of 'map_test_fixture.dart';

GameSessionCapabilities testGameSessionCapabilities(
  FakeGameSession session, {
  HexInspectionSessionPort? hexInspection,
  CitySessionPort? cities,
  MovementSessionPort? movement,
  GameSaveSessionPort? save,
}) => GameSessionCapabilities(
  map: session,
  hexInspection:
      hexInspection ??
      FakeHexInspectionSession(scene: session.scene ?? testMapScene()),
  movement: movement ?? session,
  combat: session,
  cities: cities ?? session,
  logistics: session,
  workers: session,
  production: session,
  artifacts: session,
  research: session,
  diplomacy: session,
  unitActions: session,
  turns: session,
  localGame: session,
  save: save,
);
