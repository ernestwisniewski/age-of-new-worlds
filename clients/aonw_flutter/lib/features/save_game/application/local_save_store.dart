import '../../local_game/application/local_game_catalog.dart';

const maxLocalSaveDocumentBytes = 16 * 1024 * 1024;

enum LocalSaveCopyView { primary, backup }

abstract interface class LocalSaveStore {
  Future<bool> contains(LocalGameScenarioView scenario);

  Future<String?> read(LocalGameScenarioView scenario, LocalSaveCopyView copy);

  Future<void> write(LocalGameScenarioView scenario, String document);
}

final class LocalSaveStoreException implements Exception {
  const LocalSaveStoreException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;

  @override
  String toString() => 'LocalSaveStoreException($code): $message';
}
