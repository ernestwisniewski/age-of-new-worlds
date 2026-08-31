part of 'map_test_fixture.dart';

mixin FakeLocalGameSessionFixture implements LocalGameSessionPort {
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
