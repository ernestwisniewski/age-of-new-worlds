part of 'replay_presentation_controller.dart';

extension _ReplayLocalOpening on ReplayPresentationController {
  Future<ReplayOpenResultView> _openEntries(
    Iterable<LocalGameCatalogEntryView> entries,
  ) async {
    pause();
    _networkUserId = null;
    final generation = ++_generation;
    _waitingForEffects = false;
    _setState(const ReplayLoading());
    final viewMode = await _initialMapViewMode();
    if (!_isCurrent(generation)) {
      return const ReplayOpenResultView.failed(
        ReplayFailureViewCode.unavailable,
      );
    }
    _viewMode = viewMode;
    final session = _session;
    final store = _store;
    if (session == null || store == null) {
      return _failOpen(generation, ReplayFailureViewCode.unavailable);
    }
    return _openStoredEntries(entries, session, store, generation);
  }

  Future<ReplayOpenResultView> _openStoredEntries(
    Iterable<LocalGameCatalogEntryView> entries,
    ReplaySessionPort session,
    LocalReplayStore store,
    int generation,
  ) async {
    var readFailed = false;
    var found = false;
    for (final entry in entries) {
      for (final copy in LocalReplayCopyView.values) {
        final read = await _readReplay(store, entry.id, copy);
        readFailed = readFailed || read.failed;
        final document = read.document;
        if (document == null) continue;
        found = true;
        final opened = await _tryOpenReplay(
          session,
          entry,
          document,
          generation,
        );
        if (opened != null) return opened;
      }
    }
    return _failOpen(
      generation,
      found
          ? ReplayFailureViewCode.incompatible
          : readFailed
          ? ReplayFailureViewCode.unreadable
          : ReplayFailureViewCode.missing,
    );
  }

  Future<({String? document, bool failed})> _readReplay(
    LocalReplayStore store,
    LocalGameScenarioView scenario,
    LocalReplayCopyView copy,
  ) async {
    try {
      return (document: await store.read(scenario, copy), failed: false);
    } on LocalReplayStoreException catch (error, stackTrace) {
      _reportStore(error, stackTrace);
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_replay_read_failure', error, stackTrace);
    }
    return (document: null, failed: true);
  }

  Future<ReplayOpenResultView?> _tryOpenReplay(
    ReplaySessionPort session,
    LocalGameCatalogEntryView entry,
    String document,
    int generation,
  ) async {
    try {
      final frame = await session.openReplayDocument(
        assets: entry.assets,
        document: document,
      );
      if (!_isCurrent(generation)) {
        return const ReplayOpenResultView.failed(
          ReplayFailureViewCode.unavailable,
        );
      }
      _setState(
        ReplayReady(
          frame: frame,
          speed: ReplaySpeedView.normal,
          isPlaying: false,
          isSeeking: false,
        ),
      );
      return const ReplayOpenResultView.started();
    } on ReplaySessionException catch (error, stackTrace) {
      _reportSession(error, stackTrace);
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_replay_open_failure', error, stackTrace);
    }
    return null;
  }
}
