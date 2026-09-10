part of 'replay_presentation_controller.dart';

extension ReplayOnlineOpening on ReplayPresentationController {
  bool get canOpenOnlineReplay => _networkSession != null && _session != null;

  Future<ReplayOpenResultView> openOnline(
    MatchHistoryEntryView entry,
    String userId,
  ) async {
    pause();
    final generation = ++_generation;
    _waitingForEffects = false;
    _networkUserId = userId;
    _setState(const ReplayLoading());
    final network = _networkSession;
    final catalog = LocalGameCatalog.entries
        .where(
          (candidate) =>
              candidate.mapId == entry.match.mapId &&
              candidate.rulesetId == entry.match.rulesetId,
        )
        .firstOrNull;
    if (network == null ||
        _session == null ||
        catalog == null ||
        !entry.replayAvailable) {
      return _failOpen(generation, ReplayFailureViewCode.unavailable);
    }
    return _openNetworkEntry(network, catalog, entry, userId, generation);
  }

  Future<ReplayOpenResultView> _openNetworkEntry(
    NetworkReplaySessionPort network,
    LocalGameCatalogEntryView catalog,
    MatchHistoryEntryView entry,
    String userId,
    int generation,
  ) async {
    try {
      final viewMode = await _initialMapViewMode();
      if (!_isCurrent(generation)) {
        return const ReplayOpenResultView.failed(
          ReplayFailureViewCode.unavailable,
        );
      }
      _viewMode = viewMode;
      final frame = await network.openNetworkReplay(
        userId: userId,
        matchId: entry.match.matchId,
        mapHash: entry.match.mapHash,
        rulesetHash: entry.match.rulesetHash,
        assets: MapAssetPaths(
          document: catalog.assets.document,
          bundleManifest: catalog.assets.bundleManifest,
          scenarioDocument: catalog.assets.scenarioDocument,
          actorPlayerId: entry.playerId,
        ),
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
      _diagnosticReporter('online_replay_open_failed', error, stackTrace);
    }
    return _failOpen(generation, ReplayFailureViewCode.incompatible);
  }

  /// Removes a previous account's displayed and pending online replay frames.
  void updateOnlineAccount(String? userId) {
    if (_networkUserId == null || _networkUserId == userId) return;
    pause();
    _generation++;
    _networkUserId = null;
    _waitingForEffects = false;
    _setState(const ReplayIdle());
  }
}
