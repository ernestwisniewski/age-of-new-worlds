import '../../local_game/application/local_game_catalog.dart';
import '../../local_game/application/local_game_session_port.dart';
import '../../map/read_model/map_scene.dart';
import 'game_save_session_port.dart';
import 'local_save_state.dart';
import 'local_save_store.dart';
import 'local_save_summary.dart';

typedef LocalSaveDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class LocalResumeAttemptView {
  const LocalResumeAttemptView.started({
    required this.entry,
    required this.scene,
    required this.controlPlan,
  }) : failure = null;

  const LocalResumeAttemptView.failed(this.failure)
    : entry = null,
      scene = null,
      controlPlan = null;

  final LocalGameCatalogEntryView? entry;
  final MapScene? scene;
  final LocalMatchControlPlanView? controlPlan;
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

  Future<List<LocalSaveSummaryView>> listSaves() async {
    final store = _store;
    if (store == null) return const [];
    final summaries = <LocalSaveSummaryView>[];
    for (final entry in LocalGameCatalog.entries) {
      final summary = await _inspectEntry(store, entry);
      if (summary != null) summaries.add(summary);
    }
    return List.unmodifiable(summaries);
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

  Future<LocalResumeAttemptView> resume(LocalGameScenarioView scenario) =>
      _resumeEntries([
        LocalGameCatalog.entries.singleWhere((entry) => entry.id == scenario),
      ]);

  Future<LocalResumeAttemptView> resumeLatest() =>
      _resumeEntries(LocalGameCatalog.entries);

  Future<LocalResumeAttemptView> _resumeEntries(
    Iterable<LocalGameCatalogEntryView> entries,
  ) async {
    final session = _session;
    final store = _store;
    if (session == null || store == null) {
      return const LocalResumeAttemptView.failed(
        LocalResumeFailureViewCode.unavailable,
      );
    }
    var foundDocument = false;
    var readFailed = false;
    for (final entry in entries) {
      for (final copy in LocalSaveCopyView.values) {
        final read = await _readSaveDocument(store, entry.id, copy);
        readFailed = readFailed || read.failed;
        final document = read.document;
        if (document == null) continue;
        foundDocument = true;
        final opened = await _openSave(session, entry, document);
        if (opened != null) {
          return LocalResumeAttemptView.started(
            entry: entry,
            scene: opened.scene,
            controlPlan: opened.controlPlan,
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

  Future<OpenedGameSaveView?> _openSave(
    GameSaveSessionPort session,
    LocalGameCatalogEntryView entry,
    String document,
  ) async {
    try {
      return await session.openSaveDocument(
        assets: entry.assets,
        document: document,
      );
    } on GameSaveSessionException catch (error, stackTrace) {
      _reportSessionFailure(error, stackTrace);
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_save_open_failure', error, stackTrace);
    }
    return null;
  }

  Future<LocalSaveSummaryView?> _inspectEntry(
    LocalSaveStore store,
    LocalGameCatalogEntryView entry,
  ) async {
    try {
      if (!await store.contains(entry.id)) return null;
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('save_lookup_failed', error, stackTrace);
      return null;
    }
    final session = _session;
    if (session == null) {
      return LocalSaveSummaryView.incompatible(scenario: entry.id);
    }
    for (final copy in LocalSaveCopyView.values) {
      final document = (await _readSaveDocument(
        store,
        entry.id,
        copy,
      )).document;
      if (document == null) continue;
      try {
        final inspected = await session.inspectSaveDocument(
          assets: entry.assets,
          document: document,
        );
        return LocalSaveSummaryView.ready(
          scenario: entry.id,
          gameMode: inspected.controlPlan.requiresPrivateHandoff
              ? LocalSaveGameModeView.hotseat
              : LocalSaveGameModeView.singlePlayer,
          turnMode: inspected.player.turnMode,
          turn: inspected.player.turn,
          recoveredFromBackup: copy == LocalSaveCopyView.backup,
        );
      } on GameSaveSessionException catch (error, stackTrace) {
        _reportSessionFailure(error, stackTrace);
      } on Object catch (error, stackTrace) {
        _diagnosticReporter(
          'unexpected_save_inspection_failure',
          error,
          stackTrace,
        );
      }
    }
    return LocalSaveSummaryView.incompatible(scenario: entry.id);
  }

  Future<({String? document, bool failed})> _readSaveDocument(
    LocalSaveStore store,
    LocalGameScenarioView scenario,
    LocalSaveCopyView copy,
  ) async {
    try {
      return (document: await store.read(scenario, copy), failed: false);
    } on LocalSaveStoreException catch (error, stackTrace) {
      _reportStoreFailure(error, stackTrace);
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_save_read_failure', error, stackTrace);
    }
    return (document: null, failed: true);
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
