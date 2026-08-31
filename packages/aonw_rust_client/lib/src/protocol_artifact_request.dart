part of 'protocol.dart';

/// Artifact-specific request constructors for the strict client protocol.
abstract final class AonwArtifactRequest {
  static AonwClientRequest startExcavation({
    required int expectedRevision,
    required String unitId,
  }) => _artifactCommand('startArtifactExcavation', expectedRevision, {
    'unitId': unitId,
  });

  static AonwClientRequest storeInCity({
    required int expectedRevision,
    required String unitId,
    String? cityId,
  }) => _artifactCommand('storeArtifactInCity', expectedRevision, {
    'unitId': unitId,
    'cityId': cityId,
  });

  static AonwClientRequest trade({
    required int expectedRevision,
    required String targetPlayerId,
    required String offeredArtifactId,
    required int offeredGold,
  }) => _artifactCommand('tradeArtifact', expectedRevision, {
    'targetPlayerId': targetPlayerId,
    'offeredArtifactId': offeredArtifactId,
    'offeredGold': offeredGold,
  });

  static AonwClientRequest _artifactCommand(
    String type,
    int expectedRevision,
    Map<String, Object?> fields,
  ) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {'type': type, 'expectedRevision': expectedRevision, ...fields},
  });
}
