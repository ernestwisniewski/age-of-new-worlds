part of 'map_test_fixture.dart';

mixin FakeLocalGameSessionFixture implements LocalGameSessionPort {
  MapScene? get scene;
  MapLoadException? get failure;
  int get localStartCalls;
  set localStartCalls(int value);
  LocalMatchSetupView? get lastLocalMatchSetup;
  set lastLocalMatchSetup(LocalMatchSetupView? value);

  @override
  Future<MapScene> startLocalMatch(LocalMatchSetupView setup) async {
    localStartCalls += 1;
    lastLocalMatchSetup = setup;
    final error = failure;
    if (error != null) {
      throw LocalGameSessionException(
        code: error.code,
        message: error.message,
        diagnosticCause: error.diagnosticCause,
        diagnosticStackTrace: error.diagnosticStackTrace,
      );
    }
    return scene!;
  }

  List<LocalAiTurnExecutionView> get aiTurnResults;

  LocalGameSessionException? get aiTurnFailure;

  int get aiTurnCalls;

  set aiTurnCalls(int value);

  List<LocalAiTurnRequestView> get aiTurnRequests;

  Map<String, PlayerMapView> get handoffPlayers;

  List<String> get handoffRequests;

  @override
  Future<LocalAiTurnExecutionView> advanceAiTurn(
    LocalAiTurnRequestView request,
  ) async {
    aiTurnCalls += 1;
    aiTurnRequests.add(request);
    final error = aiTurnFailure;
    if (error != null) throw error;
    if (aiTurnResults.isEmpty) throw StateError('No AI turn fixture.');
    final index = aiTurnCalls <= aiTurnResults.length
        ? aiTurnCalls - 1
        : aiTurnResults.length - 1;
    return aiTurnResults[index];
  }

  @override
  Future<PlayerMapView> handoffLocalActor(String playerId) async {
    handoffRequests.add(playerId);
    return handoffPlayers[playerId] ??
        (throw StateError('No local handoff fixture for $playerId.'));
  }
}
