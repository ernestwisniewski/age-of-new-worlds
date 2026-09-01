part of 'local_save_workflow.dart';

extension LocalSaveTransferWorkflow on LocalSaveWorkflow {
  bool get canTransfer =>
      _session != null && _store != null && _transfer != null;

  Future<LocalSaveTransferResultView> importSave() async {
    final session = _session;
    final store = _store;
    final transfer = _transfer;
    if (session == null || store == null || transfer == null) {
      return const LocalSaveTransferResultView.failed(
        LocalSaveTransferFailureViewCode.unavailable,
      );
    }
    final String? document;
    try {
      document = await transfer.pickSaveDocument();
    } on Object catch (error, stackTrace) {
      _reportTransferFailure('save_import_read_failed', error, stackTrace);
      return LocalSaveTransferResultView.failed(_importFailure(error));
    }
    if (document == null) {
      return const LocalSaveTransferResultView.cancelled();
    }
    if (_documentBytes(document) > maxLocalSaveDocumentBytes) {
      return const LocalSaveTransferResultView.failed(
        LocalSaveTransferFailureViewCode.tooLarge,
      );
    }
    final scenario = await _matchingScenario(session, document);
    if (scenario == null) {
      return const LocalSaveTransferResultView.failed(
        LocalSaveTransferFailureViewCode.incompatible,
      );
    }
    try {
      await store.write(scenario, document);
      return LocalSaveTransferResultView.completed(scenario: scenario);
    } on Object catch (error, stackTrace) {
      _reportTransferFailure('save_import_write_failed', error, stackTrace);
      return const LocalSaveTransferResultView.failed(
        LocalSaveTransferFailureViewCode.writeFailed,
      );
    }
  }

  Future<LocalSaveTransferResultView> exportSave(
    LocalGameScenarioView scenario,
  ) async {
    final session = _session;
    final store = _store;
    final transfer = _transfer;
    if (session == null || store == null || transfer == null) {
      return const LocalSaveTransferResultView.failed(
        LocalSaveTransferFailureViewCode.unavailable,
      );
    }
    final entry = LocalGameCatalog.entries.singleWhere(
      (candidate) => candidate.id == scenario,
    );
    final candidate = await _exportCandidate(session, store, entry);
    if (candidate.document == null) {
      return LocalSaveTransferResultView.failed(candidate.failure!);
    }
    try {
      final disposition = await transfer.exportSaveDocument(
        suggestedName: 'aonw-${scenario.name}.aonwsave',
        document: candidate.document!,
      );
      if (disposition == LocalSaveExportDisposition.cancelled) {
        return const LocalSaveTransferResultView.cancelled();
      }
      return LocalSaveTransferResultView.completed(scenario: scenario);
    } on Object catch (error, stackTrace) {
      _reportTransferFailure('save_export_transfer_failed', error, stackTrace);
      return const LocalSaveTransferResultView.failed(
        LocalSaveTransferFailureViewCode.exportFailed,
      );
    }
  }

  Future<LocalGameScenarioView?> _matchingScenario(
    GameSaveSessionPort session,
    String document,
  ) async {
    Object? lastError;
    StackTrace? lastStackTrace;
    for (final entry in LocalGameCatalog.entries) {
      try {
        final inspected = await session.inspectSaveDocument(
          assets: entry.assets,
          document: document,
        );
        if (inspected.scene.map.mapId == entry.mapId) return entry.id;
      } on Object catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }
    if (lastError != null) {
      _reportTransferFailure(
        'save_import_validation_failed',
        lastError,
        lastStackTrace!,
      );
    }
    return null;
  }

  Future<({String? document, LocalSaveTransferFailureViewCode? failure})>
  _exportCandidate(
    GameSaveSessionPort session,
    LocalSaveStore store,
    LocalGameCatalogEntryView entry,
  ) async {
    var found = false;
    var readFailed = false;
    for (final copy in LocalSaveCopyView.values) {
      final read = await _readSaveDocument(store, entry.id, copy);
      readFailed = readFailed || read.failed;
      final document = read.document;
      if (document == null) continue;
      found = true;
      if (_documentBytes(document) > maxLocalSaveDocumentBytes) continue;
      try {
        final inspected = await session.inspectSaveDocument(
          assets: entry.assets,
          document: document,
        );
        if (inspected.scene.map.mapId == entry.mapId) {
          return (document: document, failure: null);
        }
      } on Object catch (error, stackTrace) {
        _reportTransferFailure(
          'save_export_validation_failed',
          error,
          stackTrace,
        );
      }
    }
    return (
      document: null,
      failure: readFailed
          ? LocalSaveTransferFailureViewCode.unreadable
          : found
          ? LocalSaveTransferFailureViewCode.incompatible
          : LocalSaveTransferFailureViewCode.missing,
    );
  }

  LocalSaveTransferFailureViewCode _importFailure(Object error) =>
      error is LocalSaveTransferException &&
          error.code == 'save_transfer_size_invalid'
      ? LocalSaveTransferFailureViewCode.tooLarge
      : LocalSaveTransferFailureViewCode.unreadable;

  void _reportTransferFailure(
    String code,
    Object error,
    StackTrace stackTrace,
  ) {
    final cause = error is LocalSaveTransferException
        ? error.diagnosticCause ?? error
        : error;
    final trace = error is LocalSaveTransferException
        ? error.diagnosticStackTrace ?? stackTrace
        : stackTrace;
    _diagnosticReporter(code, cause, trace);
  }
}

int _documentBytes(String document) => utf8.encode(document).length;
