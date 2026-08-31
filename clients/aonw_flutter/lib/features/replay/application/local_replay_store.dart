import '../../local_game/application/local_game_catalog.dart';

const maxLocalReplayDocumentBytes = 64 * 1024 * 1024;

enum LocalReplayCopyView { primary, backup }

abstract interface class LocalReplayStore {
  Future<bool> contains(LocalGameScenarioView scenario);

  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalReplayCopyView copy,
  );

  Future<void> write(LocalGameScenarioView scenario, String document);
}

final class LocalReplayStoreException implements Exception {
  const LocalReplayStoreException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;
}
