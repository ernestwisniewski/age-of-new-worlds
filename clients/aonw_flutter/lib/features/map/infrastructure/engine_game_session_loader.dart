import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter/services.dart';

import '../../replay/read_model/replay_frame_view.dart';
import '../application/map_session_port.dart';
import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import 'map_reference_bundle_loader.dart';
import 'map_view_mapper.dart';
import 'player_map_view_mapper.dart';
import 'recipient_projection_cache.dart';

part 'engine_game_session_loader_remote.dart';

typedef EngineSessionFactory = Future<AonwEngineSession?> Function();

final class PreparedEngineGameSession {
  const PreparedEngineGameSession({
    required this.session,
    required this.scene,
    required this.cache,
    this.restoredParticipants = const [],
  });

  final AonwEngineSession session;
  final MapScene scene;
  final RecipientProjectionCache cache;
  final List<AonwParticipantControl> restoredParticipants;
}

final class PreparedEngineReplaySession {
  const PreparedEngineReplaySession({
    required this.session,
    required this.frame,
    required this.cache,
  });

  final AonwEngineSession session;
  final ReplayFrameView frame;
  final RecipientProjectionCache cache;
}

final class EngineGameSessionLoader {
  EngineGameSessionLoader({
    required AssetBundle assets,
    required EngineSessionFactory sessionFactory,
    required MapViewMapper mapMapper,
    required PlayerMapViewMapper playerMapper,
  }) : _assets = assets,
       _sessionFactory = sessionFactory,
       _mapMapper = mapMapper,
       _playerMapper = playerMapper,
       _bundleLoader = MapReferenceBundleLoader(assets);

  final AssetBundle _assets;
  final EngineSessionFactory _sessionFactory;
  final MapViewMapper _mapMapper;
  final PlayerMapViewMapper _playerMapper;
  final MapReferenceBundleLoader _bundleLoader;

  Future<PreparedEngineGameSession> prepare(MapAssetPaths assets) =>
      _prepareCandidate(assets);

  Future<PreparedEngineGameSession> prepareMatch(
    MapAssetPaths assets, {
    required AonwMatchIdentity matchIdentity,
    required bool fogEnabled,
  }) => _prepareCandidate(
    assets,
    matchIdentity: matchIdentity,
    fogEnabled: fogEnabled,
  );

  Future<PreparedEngineGameSession> prepareSave(
    MapAssetPaths assets, {
    required String saveDocument,
  }) => _prepareCandidate(assets, saveDocument: saveDocument);

  Future<PreparedEngineReplaySession> prepareReplay(
    MapAssetPaths assets, {
    required String replayDocument,
  }) async {
    final candidate = await _sessionFactory();
    if (candidate == null) {
      throw const MapLoadException(
        code: 'engine_adapter_unavailable',
        message: 'The engine map adapter is unavailable on this platform.',
      );
    }
    try {
      await _verifyCapabilities(candidate, _localReplayFeatures);
      final document = await _assets.loadString(assets.document);
      final map = await _inspectMap(candidate, document);
      final response = await candidate.send(
        AonwClientRequest.openReplay(
          mapDocument: document,
          replayDocument: replayDocument,
          recipientPlayerId: assets.actorPlayerId,
        ),
      );
      final frame = _loadResponse<AonwReplayFrameResponse>(
        response,
        'The replay could not be opened.',
      );
      final player = _playerMapper.fromWire(
        frame.snapshot,
        map: map,
        actorPlayerId: assets.actorPlayerId,
      );
      final reference = await _bundleLoader.load(
        manifestAsset: assets.bundleManifest,
        map: map,
      );
      return PreparedEngineReplaySession(
        session: candidate,
        frame: ReplayFrameView(
          position: frame.position,
          entryCount: frame.entryCount,
          scene: MapScene(map: map, reference: reference, player: player),
        ),
        cache: RecipientProjectionCache.open(
          snapshot: frame.snapshot,
          map: map,
        ),
      );
    } on MapLoadException {
      await candidate.close();
      rethrow;
    } on FormatException catch (error, stackTrace) {
      await candidate.close();
      throw MapLoadException(
        code: 'invalid_replay_protocol',
        message: 'The replay data is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    } on Object {
      await candidate.close();
      rethrow;
    }
  }

  Future<PreparedEngineGameSession> _prepareCandidate(
    MapAssetPaths assets, {
    AonwMatchIdentity? matchIdentity,
    bool fogEnabled = false,
    String? saveDocument,
  }) async {
    final candidate = await _sessionFactory();
    if (candidate == null) {
      throw const MapLoadException(
        code: 'engine_adapter_unavailable',
        message: 'The engine map adapter is unavailable on this platform.',
      );
    }
    try {
      return await _prepare(
        candidate,
        assets,
        matchIdentity: matchIdentity,
        fogEnabled: fogEnabled,
        saveDocument: saveDocument,
      );
    } on MapLoadException {
      await candidate.close();
      rethrow;
    } on FormatException catch (error, stackTrace) {
      await candidate.close();
      throw MapLoadException(
        code: 'invalid_map_protocol',
        message: 'The map data is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    } on Object {
      await candidate.close();
      rethrow;
    }
  }

  Future<PreparedEngineGameSession> _prepare(
    AonwEngineSession candidate,
    MapAssetPaths assets, {
    AonwMatchIdentity? matchIdentity,
    required bool fogEnabled,
    String? saveDocument,
  }) async {
    await _verifyCapabilities(
      candidate,
      saveDocument != null
          ? _localSaveFeatures
          : matchIdentity == null
          ? _requiredClientFeatures
          : _localMatchFeatures,
    );
    final document = await _assets.loadString(assets.document);
    final map = await _inspectMap(candidate, document);
    final restored = saveDocument == null
        ? null
        : await _openSavedPlayer(
            candidate,
            mapDocument: document,
            saveDocument: saveDocument,
          );
    final snapshot = restored == null
        ? await _openPlayer(
            candidate,
            mapDocument: document,
            scenarioDocument: await _assets.loadString(assets.scenarioDocument),
            actorPlayerId: assets.actorPlayerId,
            matchIdentity: matchIdentity,
            fogEnabled: fogEnabled,
          )
        : restored.snapshot;
    final actorPlayerId = restored?.actorPlayerId ?? assets.actorPlayerId;
    final player = _playerMapper.fromWire(
      snapshot,
      map: map,
      actorPlayerId: actorPlayerId,
    );
    final reference = await _bundleLoader.load(
      manifestAsset: assets.bundleManifest,
      map: map,
    );
    return PreparedEngineGameSession(
      session: candidate,
      scene: MapScene(map: map, reference: reference, player: player),
      cache: RecipientProjectionCache.open(snapshot: snapshot, map: map),
      restoredParticipants: restored?.participants ?? const [],
    );
  }

  Future<
    ({
      String actorPlayerId,
      List<AonwParticipantControl> participants,
      AonwPlayerViewSnapshot snapshot,
    })
  >
  _openSavedPlayer(
    AonwEngineSession candidate, {
    required String mapDocument,
    required String saveDocument,
  }) async {
    final opened = await candidate.send(
      AonwClientRequest.openSave(
        mapDocument: mapDocument,
        saveDocument: saveDocument,
      ),
    );
    final restored = _loadResponse<AonwSaveOpenedResponse>(
      opened,
      'The saved game could not be opened.',
    );
    final snapshot = await candidate.send(AonwClientRequest.snapshot());
    final player = _loadResponse<AonwSnapshotResponse>(
      snapshot,
      'The restored player view could not be loaded.',
    ).snapshot;
    return (
      actorPlayerId: restored.actorPlayerId,
      participants: restored.participants,
      snapshot: player,
    );
  }

  Future<AonwPlayerViewSnapshot> _openPlayer(
    AonwEngineSession candidate, {
    required String mapDocument,
    required String scenarioDocument,
    required String actorPlayerId,
    required AonwMatchIdentity? matchIdentity,
    required bool fogEnabled,
  }) async {
    final opened = await candidate.send(
      matchIdentity == null
          ? AonwClientRequest.openSession(
              mapDocument: mapDocument,
              scenarioDocument: scenarioDocument,
              actorPlayerId: actorPlayerId,
            )
          : AonwClientRequest.startMatch(
              mapDocument: mapDocument,
              scenarioDocument: scenarioDocument,
              actorPlayerId: actorPlayerId,
              matchIdentity: matchIdentity,
              fogEnabled: fogEnabled,
            ),
    );
    _loadResponse<AonwSessionOpenedResponse>(
      opened,
      'The local game session could not be opened.',
    );
    final snapshot = await candidate.send(AonwClientRequest.snapshot());
    return _loadResponse<AonwSnapshotResponse>(
      snapshot,
      'The player view could not be loaded.',
    ).snapshot;
  }

  Future<MapView> _inspectMap(
    AonwEngineSession candidate,
    String document,
  ) async {
    final response = await candidate.send(
      AonwClientRequest.inspectMap(mapDocument: document),
    );
    final inspected = _loadResponse<AonwMapInspectedResponse>(
      response,
      'The map could not be opened.',
    );
    return _mapMapper.fromWire(inspected.map);
  }

  static T _loadResponse<T extends AonwClientResponseBody>(
    AonwClientResponse response,
    String message,
  ) {
    if (!response.isSuccess) {
      final error = response.error!;
      throw MapLoadException(
        code: error.code,
        message: message,
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    return response.require<T>();
  }

  static Future<void> _verifyCapabilities(
    AonwEngineSession candidate,
    Set<AonwClientFeature> required,
  ) async {
    final response = await candidate.send(AonwClientRequest.capabilities());
    if (!response.isSuccess) {
      final error = response.error!;
      throw MapLoadException(
        code: 'engine_capability_mismatch',
        message: 'The native game adapter is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    final capabilities = response.require<AonwCapabilitiesResponse>();
    final missing = required.difference(capabilities.features.toSet());
    if (missing.isEmpty) return;
    throw MapLoadException(
      code: 'engine_capability_mismatch',
      message: 'The native game adapter is incompatible with this client.',
      diagnosticCause: StateError(
        'Missing engine client capabilities: '
        '${missing.map((feature) => feature.name).join(', ')}',
      ),
      diagnosticStackTrace: StackTrace.current,
    );
  }
}

const _requiredClientFeatures = <AonwClientFeature>{
  AonwClientFeature.inspectMap,
  AonwClientFeature.snapshot,
  AonwClientFeature.reachable,
  AonwClientFeature.routePlan,
  AonwClientFeature.moveUnit,
  AonwClientFeature.unitActions,
  AonwClientFeature.turnKernel,
};

const _localMatchFeatures = <AonwClientFeature>{
  ..._requiredClientFeatures,
  AonwClientFeature.matchStart,
  AonwClientFeature.actorHandoff,
  AonwClientFeature.aiTurns,
};

const _localSaveFeatures = <AonwClientFeature>{
  ..._requiredClientFeatures,
  AonwClientFeature.saveGame,
  AonwClientFeature.actorHandoff,
  AonwClientFeature.aiTurns,
};

const _localReplayFeatures = <AonwClientFeature>{
  AonwClientFeature.inspectMap,
  AonwClientFeature.snapshot,
  AonwClientFeature.replayVerification,
  AonwClientFeature.replayPlayback,
};
