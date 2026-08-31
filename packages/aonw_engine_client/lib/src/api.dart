abstract interface class AonwEngineSession {
  Future<String> requestJson(String request);

  Future<void> close();
}
