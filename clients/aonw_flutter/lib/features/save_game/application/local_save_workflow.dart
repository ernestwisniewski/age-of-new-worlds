import 'dart:convert';

import '../../local_game/application/local_game_catalog.dart';
import '../../local_game/application/local_game_session_port.dart';
import '../../map/read_model/map_scene.dart';
import 'game_save_session_port.dart';
import 'local_save_state.dart';
import 'local_save_store.dart';
import 'local_save_summary.dart';
import 'local_save_transfer.dart';

part 'local_save_transfer_workflow.dart';

typedef LocalSaveDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class LocalResumeAttemptView {
  const LocalResumeAttemptView.started({
    required this.entry,
    required this.slot,
    required this.scene,
    required this.controlPlan,
  }) : failure = null;

  const LocalResumeAttemptView.failed(this.failure)
    : entry = null,
      slot = null,
      scene = null,
      controlPlan = null;

  final LocalGameCatalogEntryView? entry;
  final LocalSaveSlotView? slot;
  final MapScene? scene;
  final LocalMatchControlPlanView? controlPlan;
  final LocalResumeFailureViewCode? failure;

  bool get started => entry != null && scene != null;
}

final class LocalSaveWriteResultView {
  const LocalSaveWriteResultView.saved(this.slot) : failure = null;

  const LocalSaveWriteResultView.failed(this.failure) : slot = null;

  final LocalSaveSlotView? slot;
  final LocalSaveFailureViewCode? failure;

  bool get saved => slot != null;
}

final class LocalSaveWorkflow {
  const LocalSaveWorkflow({
    required GameSaveSessionPort? session,
    required LocalSaveStore? store,
    LocalSaveTransferPort? transfer,
    required LocalSaveDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _store = store,
       _transfer = transfer,
       _diagnosticReporter = diagnosticReporter;

  final GameSaveSessionPort? _session;
  final LocalSaveStore? _store;
  final LocalSaveTransferPort? _transfer;
  final LocalSaveDiagnosticReporter _diagnosticReporter;

  Future<bool> hasSave() async {
    final store = _store;
    if (store == null) return false;
    try {
      return (await store.list()).isNotEmpty;
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('save_lookup_failed', error, stackTrace);
      return false;
    }
  }

  Future<List<LocalSaveSummaryView>> listSaves() async {
    final store = _store;
    if (store == null) return const [];
    final summaries = <LocalSaveSummaryView>[];
    List<LocalSaveSlotView> slots;
    try {
      slots = await store.list();
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('save_index_failed', error, stackTrace);
      return const [];
    }
    for (final slot in slots) {
      final summary = await _inspectSlot(store, slot);
      if (summary != null) summaries.add(summary);
    }
    return List.unmodifiable(summaries);
  }

  Future<LocalSaveWriteResultView> save(
    LocalGameCatalogEntryView entry, {
    required LocalSaveSlotView? slot,
  }) async {
    final session = _session;
    final store = _store;
    if (session == null || store == null) {
      return const LocalSaveWriteResultView.failed(
        LocalSaveFailureViewCode.unavailable,
      );
    }
    String document;
    try {
      document = await session.exportSaveDocument();
    } on GameSaveSessionException catch (error, stackTrace) {
      _reportSessionFailure(error, stackTrace);
      return const LocalSaveWriteResultView.failed(
        LocalSaveFailureViewCode.exportFailed,
      );
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_save_export_failure', error, stackTrace);
      return const LocalSaveWriteResultView.failed(
        LocalSaveFailureViewCode.exportFailed,
      );
    }
    try {
      final updated = slot == null
          ? await store.create(
              scenario: entry.id,
              name: null,
              document: document,
            )
          : await store.write(slot, document);
      return LocalSaveWriteResultView.saved(updated);
    } on LocalSaveStoreException catch (error, stackTrace) {
      _reportStoreFailure(error, stackTrace);
      return const LocalSaveWriteResultView.failed(
        LocalSaveFailureViewCode.writeFailed,
      );
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_save_write_failure', error, stackTrace);
      return const LocalSaveWriteResultView.failed(
        LocalSaveFailureViewCode.writeFailed,
      );
    }
  }

  Future<LocalResumeAttemptView> resume(LocalSaveSlotView slot) =>
      _resumeSlots([slot]);

  Future<LocalResumeAttemptView> resumeLatest() async {
    final store = _store;
    if (store == null) {
      return const LocalResumeAttemptView.failed(
        LocalResumeFailureViewCode.unavailable,
      );
    }
    try {
      return _resumeSlots(await store.list());
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('save_index_failed', error, stackTrace);
      return const LocalResumeAttemptView.failed(
        LocalResumeFailureViewCode.unreadable,
      );
    }
  }

  Future<LocalResumeAttemptView> _resumeSlots(
    Iterable<LocalSaveSlotView> slots,
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
    for (final slot in slots) {
      final entry = LocalGameCatalog.entries.singleWhere(
        (candidate) => candidate.id == slot.scenario,
      );
      for (final copy in LocalSaveCopyView.values) {
        final read = await _readSaveDocument(store, slot, copy);
        readFailed = readFailed || read.failed;
        final document = read.document;
        if (document == null) continue;
        foundDocument = true;
        final opened = await _openSave(session, entry, document);
        if (opened != null) {
          return LocalResumeAttemptView.started(
            entry: entry,
            slot: slot,
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

  Future<LocalSaveSummaryView?> _inspectSlot(
    LocalSaveStore store,
    LocalSaveSlotView slot,
  ) async {
    final entry = LocalGameCatalog.entries.singleWhere(
      (candidate) => candidate.id == slot.scenario,
    );
    final session = _session;
    if (session == null) {
      return LocalSaveSummaryView.incompatible(slot: slot);
    }
    for (final copy in LocalSaveCopyView.values) {
      final document = (await _readSaveDocument(store, slot, copy)).document;
      if (document == null) continue;
      try {
        final inspected = await session.inspectSaveDocument(
          assets: entry.assets,
          document: document,
        );
        return LocalSaveSummaryView.ready(
          slot: slot,
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
    return LocalSaveSummaryView.incompatible(slot: slot);
  }

  Future<({String? document, bool failed})> _readSaveDocument(
    LocalSaveStore store,
    LocalSaveSlotView slot,
    LocalSaveCopyView copy,
  ) async {
    try {
      return (document: await store.read(slot, copy), failed: false);
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
