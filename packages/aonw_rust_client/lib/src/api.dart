abstract interface class AonwRustSession {
  Future<String> requestJson(String request);

  Future<void> close();
}
