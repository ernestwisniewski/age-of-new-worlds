import '../../local_game/application/local_game_catalog.dart';

const maxLocalSaveDocumentBytes = 16 * 1024 * 1024;

enum LocalSaveCopyView { primary, backup }

final class LocalSaveSlotView {
  const LocalSaveSlotView({
    required this.id,
    required this.scenario,
    required this.savedAt,
    this.name,
  });

  final String id;
  final LocalGameScenarioView scenario;
  final DateTime savedAt;
  final String? name;
}

abstract interface class LocalSaveStore {
  Future<List<LocalSaveSlotView>> list();

  Future<String?> read(LocalSaveSlotView slot, LocalSaveCopyView copy);

  Future<LocalSaveSlotView> create({
    required LocalGameScenarioView scenario,
    required String? name,
    required String document,
  });

  Future<LocalSaveSlotView> write(LocalSaveSlotView slot, String document);
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
