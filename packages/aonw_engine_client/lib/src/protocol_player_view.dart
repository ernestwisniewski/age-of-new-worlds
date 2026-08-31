import 'package:aonw_engine_client/src/protocol_artifact.dart';
import 'package:aonw_engine_client/src/protocol_city_view.dart';
import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_diplomacy.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_match.dart';
import 'package:aonw_engine_client/src/protocol_outcome.dart';
import 'package:aonw_engine_client/src/protocol_pending_action.dart';
import 'package:aonw_engine_client/src/protocol_player_economy.dart';
import 'package:aonw_engine_client/src/protocol_player_research.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

part 'protocol_player_details.dart';

final class AonwPlayerUnitView {
  const AonwPlayerUnitView({
    required this.id,
    required this.ownerPlayerId,
    required this.kind,
    required this.name,
    required this.coordinate,
    required this.movementUnits,
    required this.posture,
    required this.workerBuildCharges,
    required this.workerJob,
    required this.workerAssignment,
    this.hitPoints,
    this.carriedArtifactId,
    this.ownedDetails,
  });

  factory AonwPlayerUnitView.fromJson(Object? source) {
    final value = readObject(source, 'player unit view');
    requireKeys(value, const {
      'id',
      'ownerPlayerId',
      'kind',
      'name',
      'coordinate',
      'movementUnits',
      'posture',
      'hitPoints',
      'carriedArtifactId',
      'ownedDetails',
    }, 'player unit view');
    final ownedDetails = value['ownedDetails'] == null
        ? null
        : AonwOwnedUnitDetails.fromJson(value['ownedDetails']);
    return AonwPlayerUnitView(
      id: readString(value['id'], 'unit id'),
      ownerPlayerId: readString(value['ownerPlayerId'], 'unit owner'),
      kind: AonwUnitKind.fromJson(value['kind']),
      name: readString(value['name'], 'unit name'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      movementUnits: readUnsigned(value['movementUnits'], 'unit movement'),
      posture: AonwUnitPosture.fromJson(value['posture']),
      workerBuildCharges: ownedDetails?.workerBuildCharges ?? 0,
      workerJob: ownedDetails?.workerJob,
      workerAssignment: ownedDetails?.workerAssignment,
      hitPoints: value['hitPoints'] == null
          ? null
          : readUnsigned(value['hitPoints'], 'unit hit points'),
      carriedArtifactId: readNullableString(
        value['carriedArtifactId'],
        'carried artifact id',
      ),
      ownedDetails: ownedDetails,
    );
  }

  final String id;
  final String ownerPlayerId;
  final AonwUnitKind kind;
  final String name;
  final AonwCoordinate coordinate;
  final int movementUnits;
  final AonwUnitPosture posture;
  final int workerBuildCharges;
  final AonwWorkerJobView? workerJob;
  final AonwCoordinate? workerAssignment;
  final int? hitPoints;
  final String? carriedArtifactId;
  final AonwOwnedUnitDetails? ownedDetails;
}

final class AonwPlayerParticipantView {
  const AonwPlayerParticipantView({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.country,
    required this.kind,
  });

  factory AonwPlayerParticipantView.fromJson(Object? source) {
    final value = readObject(source, 'player participant view');
    requireKeys(value, const {
      'id',
      'name',
      'colorValue',
      'country',
      'kind',
    }, 'player participant view');
    final colorValue = readUnsigned(
      value['colorValue'],
      'participant color value',
    );
    if (colorValue > 0xffffffff) {
      throw const FormatException('Invalid AoNW participant color value.');
    }
    return AonwPlayerParticipantView(
      id: readString(value['id'], 'participant id'),
      name: readString(value['name'], 'participant name'),
      colorValue: colorValue,
      country: AonwPlayerCountry.fromJson(value['country']),
      kind: AonwPlayerKind.fromJson(value['kind']),
    );
  }

  final String id;
  final String name;
  final int colorValue;
  final AonwPlayerCountry country;
  final AonwPlayerKind kind;
}

final class AonwPlayerFogView {
  const AonwPlayerFogView({
    required this.enabled,
    required this.discoveredHexes,
    required this.visibleHexes,
  });

  factory AonwPlayerFogView.fromJson(Object? source) {
    final value = readObject(source, 'player fog view');
    requireKeys(value, const {
      'enabled',
      'discoveredHexes',
      'visibleHexes',
    }, 'player fog view');
    return AonwPlayerFogView(
      enabled: readBool(value['enabled'], 'fog enabled state'),
      discoveredHexes: _coordinates(
        value['discoveredHexes'],
        'discovered fog coordinates',
      ),
      visibleHexes: _coordinates(
        value['visibleHexes'],
        'visible fog coordinates',
      ),
    );
  }

  final bool enabled;
  final List<AonwCoordinate> discoveredHexes;
  final List<AonwCoordinate> visibleHexes;
}

final class AonwPlayerViewSnapshot {
  const AonwPlayerViewSnapshot({
    required this.stamp,
    required this.turn,
    required this.turnMode,
    required this.participants,
    required this.fog,
    required this.economy,
    required this.research,
    required this.outcome,
    required this.turnLifecycle,
    required this.pendingAction,
    required this.cityFoundingDraft,
    required this.diplomacy,
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fieldImprovements,
    required this.roads,
  });

  factory AonwPlayerViewSnapshot.fromJson(Object? source) {
    final value = readObject(source, 'player snapshot');
    _requirePlayerViewSnapshotKeys(value);
    return AonwPlayerViewSnapshot(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      turn: readUnsigned(value['turn'], 'snapshot turn'),
      turnMode: AonwTurnMode.fromJson(value['turnMode']),
      participants: _views(
        value['participants'],
        'snapshot participants',
        AonwPlayerParticipantView.fromJson,
      ),
      fog: AonwPlayerFogView.fromJson(value['fog']),
      economy: AonwPlayerEconomyView.fromJson(value['economy']),
      research: AonwPlayerResearchView.fromJson(value['research']),
      outcome: AonwGameOutcome.fromJson(value['outcome']),
      turnLifecycle: AonwPlayerTurnLifecycle.fromJson(value['turnLifecycle']),
      pendingAction: value['pendingAction'] == null
          ? null
          : AonwPendingActionView.fromJson(value['pendingAction']),
      cityFoundingDraft: value['cityFoundingDraft'] == null
          ? null
          : AonwCityFoundingDraft.fromJson(value['cityFoundingDraft']),
      diplomacy: AonwPlayerDiplomacyView.fromJson(value['diplomacy']),
      units: _views(
        value['units'],
        'snapshot units',
        AonwPlayerUnitView.fromJson,
      ),
      cities: _views(
        value['cities'],
        'snapshot cities',
        AonwPlayerCityView.fromJson,
      ),
      artifacts: _views(
        value['artifacts'],
        'snapshot artifacts',
        AonwPlayerArtifactView.fromJson,
      ),
      fieldImprovements: _views(
        value['fieldImprovements'],
        'snapshot field improvements',
        AonwFieldImprovementView.fromJson,
      ),
      roads: _views(value['roads'], 'snapshot roads', AonwRoadView.fromJson),
    );
  }

  final AonwSessionStamp stamp;
  final int turn;
  final AonwTurnMode turnMode;
  final List<AonwPlayerParticipantView> participants;
  final AonwPlayerFogView fog;
  final AonwPlayerEconomyView economy;
  final AonwPlayerResearchView research;
  final AonwGameOutcome outcome;
  final AonwPlayerTurnLifecycle turnLifecycle;
  final AonwPendingActionView? pendingAction;
  final AonwCityFoundingDraft? cityFoundingDraft;
  final AonwPlayerDiplomacyView diplomacy;
  final List<AonwPlayerUnitView> units;
  final List<AonwPlayerCityView> cities;
  final List<AonwPlayerArtifactView> artifacts;
  final List<AonwFieldImprovementView> fieldImprovements;
  final List<AonwRoadView> roads;
}

void _requirePlayerViewSnapshotKeys(Map<String, Object?> value) {
  requireKeys(value, const {
    'stamp',
    'turn',
    'turnMode',
    'participants',
    'fog',
    'economy',
    'research',
    'outcome',
    'turnLifecycle',
    'pendingAction',
    'cityFoundingDraft',
    'diplomacy',
    'units',
    'cities',
    'artifacts',
    'fieldImprovements',
    'roads',
  }, 'player snapshot');
}

final class AonwPlayerViewPatch {
  const AonwPlayerViewPatch({
    required this.fromRevision,
    required this.toRevision,
    required this.turn,
    required this.turnMode,
    this.fog,
    this.economy,
    this.research,
    required this.turnLifecycle,
    required this.outcome,
    required this.upsertedUnits,
    required this.removedUnitIds,
    required this.upsertedCities,
    required this.removedCityIds,
    required this.upsertedArtifacts,
    required this.removedArtifactIds,
    required this.upsertedFieldImprovements,
    required this.removedFieldImprovementCoordinates,
    required this.upsertedRoads,
    required this.removedRoadCoordinates,
    required this.pendingAction,
    required this.cityFoundingDraft,
    required this.diplomacy,
  });

  factory AonwPlayerViewPatch.fromJson(Object? source) {
    final value = readObject(source, 'player view patch');
    _requirePlayerViewPatchKeys(value);
    final entities = _playerEntityPatch(value);
    final mapFeatures = _playerMapFeaturePatch(value);
    return AonwPlayerViewPatch(
      fromRevision: readUnsigned(value['fromRevision'], 'source revision'),
      toRevision: readUnsigned(value['toRevision'], 'patch target revision'),
      turn: readUnsigned(value['turn'], 'patch turn'),
      turnMode: AonwTurnMode.fromJson(value['turnMode']),
      fog: _optional(value['fog'], AonwPlayerFogView.fromJson),
      economy: _optional(value['economy'], AonwPlayerEconomyView.fromJson),
      research: _optional(value['research'], AonwPlayerResearchView.fromJson),
      turnLifecycle: _optional(
        value['turnLifecycle'],
        AonwPlayerTurnLifecycle.fromJson,
      ),
      outcome: _optional(value['outcome'], AonwGameOutcome.fromJson),
      upsertedUnits: entities.units,
      removedUnitIds: entities.removedUnitIds,
      upsertedCities: entities.cities,
      removedCityIds: entities.removedCityIds,
      upsertedArtifacts: mapFeatures.artifacts,
      removedArtifactIds: mapFeatures.removedArtifactIds,
      upsertedFieldImprovements: mapFeatures.fieldImprovements,
      removedFieldImprovementCoordinates:
          mapFeatures.removedFieldImprovementCoordinates,
      upsertedRoads: mapFeatures.roads,
      removedRoadCoordinates: mapFeatures.removedRoadCoordinates,
      pendingAction: _optional(
        value['pendingAction'],
        AonwPendingActionView.fromJson,
      ),
      cityFoundingDraft: _optional(
        value['cityFoundingDraft'],
        AonwCityFoundingDraft.fromJson,
      ),
      diplomacy: _optional(
        value['diplomacy'],
        AonwPlayerDiplomacyView.fromJson,
      ),
    );
  }

  final int fromRevision;
  final int toRevision;
  final int turn;
  final AonwTurnMode turnMode;
  final AonwPlayerFogView? fog;
  final AonwPlayerEconomyView? economy;
  final AonwPlayerResearchView? research;
  final AonwPlayerTurnLifecycle? turnLifecycle;
  final AonwGameOutcome? outcome;
  final List<AonwPlayerUnitView> upsertedUnits;
  final List<String> removedUnitIds;
  final List<AonwPlayerCityView> upsertedCities;
  final List<String> removedCityIds;
  final List<AonwPlayerArtifactView> upsertedArtifacts;
  final List<String> removedArtifactIds;
  final List<AonwFieldImprovementView> upsertedFieldImprovements;
  final List<AonwCoordinate> removedFieldImprovementCoordinates;
  final List<AonwRoadView> upsertedRoads;
  final List<AonwCoordinate> removedRoadCoordinates;
  final AonwPendingActionView? pendingAction;
  final AonwCityFoundingDraft? cityFoundingDraft;
  final AonwPlayerDiplomacyView? diplomacy;
}

({
  List<AonwPlayerUnitView> units,
  List<String> removedUnitIds,
  List<AonwPlayerCityView> cities,
  List<String> removedCityIds,
})
_playerEntityPatch(Map<String, Object?> value) => (
  units: _views(
    value['upsertedUnits'],
    'upserted units',
    AonwPlayerUnitView.fromJson,
  ),
  removedUnitIds: _ids(value['removedUnitIds'], 'removed unit ids'),
  cities: _views(
    value['upsertedCities'],
    'upserted cities',
    AonwPlayerCityView.fromJson,
  ),
  removedCityIds: _ids(value['removedCityIds'], 'removed city ids'),
);

({
  List<AonwPlayerArtifactView> artifacts,
  List<String> removedArtifactIds,
  List<AonwFieldImprovementView> fieldImprovements,
  List<AonwCoordinate> removedFieldImprovementCoordinates,
  List<AonwRoadView> roads,
  List<AonwCoordinate> removedRoadCoordinates,
})
_playerMapFeaturePatch(Map<String, Object?> value) => (
  artifacts: _views(
    value['upsertedArtifacts'],
    'upserted artifacts',
    AonwPlayerArtifactView.fromJson,
  ),
  removedArtifactIds: _ids(value['removedArtifactIds'], 'removed artifact ids'),
  fieldImprovements: _views(
    value['upsertedFieldImprovements'],
    'upserted field improvements',
    AonwFieldImprovementView.fromJson,
  ),
  removedFieldImprovementCoordinates: _coordinates(
    value['removedFieldImprovementCoordinates'],
    'removed field improvement coordinates',
  ),
  roads: _views(
    value['upsertedRoads'],
    'upserted roads',
    AonwRoadView.fromJson,
  ),
  removedRoadCoordinates: _coordinates(
    value['removedRoadCoordinates'],
    'removed road coordinates',
  ),
);

void _requirePlayerViewPatchKeys(Map<String, Object?> value) {
  requireKeys(value, const {
    'fromRevision',
    'toRevision',
    'turn',
    'turnMode',
    'fog',
    'economy',
    'research',
    'turnLifecycle',
    'outcome',
    'upsertedUnits',
    'removedUnitIds',
    'upsertedCities',
    'removedCityIds',
    'upsertedArtifacts',
    'removedArtifactIds',
    'upsertedFieldImprovements',
    'removedFieldImprovementCoordinates',
    'upsertedRoads',
    'removedRoadCoordinates',
    'pendingAction',
    'cityFoundingDraft',
    'diplomacy',
  }, 'player view patch');
}

List<AonwCoordinate> _coordinates(Object? value, String label) =>
    _views(value, label, AonwCoordinate.fromJson);

List<String> _ids(Object? value, String label) =>
    readList(value, label, (item, _) => readString(item, 'identifier'));

T? _optional<T>(Object? value, T Function(Object? value) parse) =>
    value == null ? null : parse(value);

List<T> _views<T>(
  Object? value,
  String label,
  T Function(Object? value) parse,
) => readList(value, label, (item, _) => parse(item));
