import '../../local_game/application/local_game_catalog.dart';
import '../../map/read_model/map_scene.dart';
import 'game_save_session_port.dart';
import 'local_save_state.dart';
import 'local_save_store.dart';

typedef LocalSaveDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class LocalResumeAttemptView {
  const LocalResumeAttemptView.started({
    required this.entry,
    required this.scene,
  }) : failure = null;

  const LocalResumeAttemptView.failed(this.failure)
    : entry = null,
      scene = null;

  final LocalGameCatalogEntryView? entry;
  final MapScene? scene;
  final LocalResumeFailureViewCode? failure;

  bool get started => entry != null && scene != null;
}

final class LocalSaveWorkflow {
  const LocalSaveWorkflow({
    required GameSaveSessionPort? session,
    required LocalSaveStore? store,
    required LocalSaveDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _store = store,
       _diagnosticReporter = diagnosticReporter;

  final GameSaveSessionPort? _session;
  final LocalSaveStore? _store;
  final LocalSaveDiagnosticReporter _diagnosticReporter;

  Future<bool> hasSave() async {
    final store = _store;
    if (store == null) return false;
    try {
      for (final entry in LocalGameCatalog.entries) {
        if (await store.contains(entry.id)) return true;
      }
      return false;
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('save_lookup_failed', error, stackTrace);
      return false;
    }
  }

  Future<LocalSaveFailureViewCode?> save(
    LocalGameCatalogEntryView entry,
  ) async {
    final session = _session;
    final store = _store;
    if (session == null || store == null) {
      return LocalSaveFailureViewCode.unavailable;
    }
    String document;
    try {
      document = await session.exportSaveDocument();
    } on GameSaveSessionException catch (error, stackTrace) {
      _reportSessionFailure(error, stackTrace);
      return LocalSaveFailureViewCode.exportFailed;
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_save_export_failure', error, stackTrace);
      return LocalSaveFailureViewCode.exportFailed;
    }
    try {
      await store.write(entry.id, document);
      return null;
    } on LocalSaveStoreException catch (error, stackTrace) {
      _reportStoreFailure(error, stackTrace);
      return LocalSaveFailureViewCode.writeFailed;
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_save_write_failure', error, stackTrace);
      return LocalSaveFailureViewCode.writeFailed;
    }
  }

  Future<LocalResumeAttemptView> resumeLatest() async {
    final session = _session;
    final store = _store;
    if (session == null || store == null) {
      return const LocalResumeAttemptView.failed(
        LocalResumeFailureViewCode.unavailable,
      );
    }
    var foundDocument = false;
    var readFailed = false;
    for (final entry in LocalGameCatalog.entries) {
      for (final copy in LocalSaveCopyView.values) {
        String? document;
        try {
          document = await store.read(entry.id, copy);
        } on LocalSaveStoreException catch (error, stackTrace) {
          readFailed = true;
          _reportStoreFailure(error, stackTrace);
          continue;
        } on Object catch (error, stackTrace) {
          readFailed = true;
          _diagnosticReporter(
            'unexpected_save_read_failure',
            error,
            stackTrace,
          );
          continue;
        }
        if (document == null) continue;
        foundDocument = true;
        try {
          final scene = await session.openSaveDocument(
            assets: entry.assets,
            document: document,
          );
          return LocalResumeAttemptView.started(entry: entry, scene: scene);
        } on GameSaveSessionException catch (error, stackTrace) {
          _reportSessionFailure(error, stackTrace);
        } on Object catch (error, stackTrace) {
          _diagnosticReporter(
            'unexpected_save_open_failure',
            error,
            stackTrace,
          );
        }
      }
    }
    return LocalResumeAttemptView.failed(
      foundDocument
          ? LocalResumeFailureViewCode.incompatible
          : readFailed
          ? LocalResumeFailureViewCode.unreadable
          : LocalResumeFailureViewCode.missing,
    );
  }

  void _reportSessionFailure(
    GameSaveSessionException error,
    StackTrace stackTrace,
  ) {
    _diagnosticReporter(
      error.code,
      error.diagnosticCause ?? error,
      error.diagnosticStackTrace ?? stackTrace,
    );
  }

  void _reportStoreFailure(
    LocalSaveStoreException error,
    StackTrace stackTrace,
  ) {
    _diagnosticReporter(
      error.code,
      error.diagnosticCause ?? error,
      error.diagnosticStackTrace ?? stackTrace,
    );
  }
}
