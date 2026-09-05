part of 'protocol_event.dart';

typedef _FieldReader = void Function(Object? value);

void _validatePresentationEvent(Map<String, Object?> value, String type) {
  final schema = _eventSchemas[type];
  if (schema == null) throw FormatException('Unknown AoNW client event $type.');
  requireKeys(value, {'type', ...schema.keys}, 'client event');
  for (final entry in schema.entries) {
    entry.value(value[entry.key]);
  }
}

final _eventSchemas = <String, Map<String, _FieldReader>>{
  'artifactExcavationStarted': _artifactUnitSchema,
  'artifactCarried': _artifactUnitSchema,
  'artifactStored': {
    'artifactId': _stringField,
    'ownerPlayerId': _stringField,
    'sourceUnitId': _nullableStringField,
    'cityId': _stringField,
    'coordinate': _coordinateField,
  },
  'cityFounded': {'cityId': _stringField, 'ownerPlayerId': _stringField},
  'cityBuiltBuilding': {
    'cityId': _stringField,
    'buildingType': AonwCityBuildingType.fromJson,
  },
  'cityProducedUnit': {
    'cityId': _stringField,
    'unitType': AonwUnitKind.fromJson,
    'producedUnitId': _stringField,
  },
  'cityBuiltWonder': {
    'cityId': _stringField,
    'ownerPlayerId': _stringField,
    'wonderType': AonwWonderType.fromJson,
  },
  'wonderProductionRefunded': {
    'cityId': _stringField,
    'ownerPlayerId': _stringField,
    'wonderType': AonwWonderType.fromJson,
    'refundedProduction': _intField,
  },
  'technologyResearched': {
    'playerId': _stringField,
    'technologyId': _technologyField,
  },
  'researchPointsGained': {'playerId': _stringField, 'points': _intField},
  'cityClaimedHex': {
    'cityId': _stringField,
    'col': _intField,
    'row': _intField,
  },
  'stabilityBandChanged': {
    'playerId': _stringField,
    'previousBand': _stabilityField,
    'newBand': _stabilityField,
    'net': _intField,
  },
  'mapObjectiveSecured': {
    'playerId': _stringField,
    'objectiveId': _stringField,
    'objectiveType': AonwMapObjectiveType.fromJson,
    'col': _intField,
    'row': _intField,
    'holdTurns': _unsignedField,
    'requiredHoldTurns': _unsignedField,
    'victoryPoints': _unsignedField,
    'goldPerTurn': _unsignedField,
  },
  'dominationThresholdReached': {
    'playerId': _stringField,
    'controlPercent': _finiteNumberField,
    'requiredControlPercent': _finiteNumberField,
    'holdTurns': _unsignedField,
    'requiredHoldTurns': _unsignedField,
  },
  'unitAttacked': _combatSubjectSchema,
  'cityAttacked': _combatSubjectSchema,
  'combatResolved': _combatSubjectSchema,
  'cityCaptured': _combatSubjectSchema,
  'cityDestroyed': _combatSubjectSchema,
  'diplomaticScoreChanged': {
    'playerAId': _stringField,
    'playerBId': _stringField,
    'delta': _intField,
    'scoreAfter': _intField,
    'reason': _scoreReasonField,
    'sourceId': _nullableStringField,
  },
  'diplomaticProposalSent': {
    ..._proposalSchema,
    'expiresOnTurn': _unsignedField,
  },
  'diplomaticProposalExpired': _proposalSchema,
  'diplomaticProposalResponded': {
    'proposalId': _stringField,
    'fromPlayerId': _stringField,
    'toPlayerId': _stringField,
    'kind': AonwDiplomaticProposalKind.fromJson,
    'accepted': _boolField,
  },
  'diplomaticMessageSent': {
    'messageId': _stringField,
    'fromPlayerId': _stringField,
    'toPlayerId': _stringField,
    'topic': AonwDiplomaticMessageTopic.fromJson,
    'category': AonwDiplomaticMessageCategory.fromJson,
    'expiresOnTurn': _unsignedField,
  },
  'diplomaticMessageResponded': {
    'messageId': _stringField,
    'fromPlayerId': _stringField,
    'toPlayerId': _stringField,
    'topic': AonwDiplomaticMessageTopic.fromJson,
    'response': AonwDiplomaticMessageResponse.fromJson,
    'relationDelta': _intField,
    'relationScoreAfter': _intField,
    'promiseDueTurn': _nullableUnsignedField,
  },
  'diplomaticPromiseBroken': {
    'messageId': _stringField,
    'playerAId': _stringField,
    'playerBId': _stringField,
    'delta': _intField,
    'scoreAfter': _intField,
  },
  'diplomaticRelationChanged': {
    'playerAId': _stringField,
    'playerBId': _stringField,
    'oldStatus': AonwDiplomaticRelationStatus.fromJson,
    'newStatus': AonwDiplomaticRelationStatus.fromJson,
    'reason': AonwDiplomaticRelationChangeReason.fromJson,
    'expiresOnTurn': _nullableUnsignedField,
  },
  'unitGainedExperience': _combatUnitSchema,
  'unitKilled': _combatUnitSchema,
  'unitRetreated': _combatUnitSchema,
  'autoExplorePlanned': {'unitId': _stringField, 'target': _coordinateField},
  'merchantRouteAssigned': {
    'unitId': _stringField,
    'originCityId': _stringField,
    'destinationCityId': _stringField,
  },
  'merchantTravelQueued': {
    'unitId': _stringField,
    'destinationCityId': _stringField,
  },
  'troopDetached': {
    'sourceUnitId': _stringField,
    'detachedUnitId': _stringField,
    'troopKind': AonwTroopKind.fromJson,
    'destination': _coordinateField,
  },
  'workerCompletedJob': {
    'unitId': _stringField,
    'target': _coordinateField,
    'completion': _workerCompletionField,
    'yieldDelta': AonwYieldValue.fromJson,
  },
};

final _artifactUnitSchema = <String, _FieldReader>{
  'artifactId': _stringField,
  'ownerPlayerId': _stringField,
  'unitId': _stringField,
  'coordinate': _coordinateField,
};
final _combatSubjectSchema = <String, _FieldReader>{
  'attackerUnitId': _stringField,
  'target': _combatTargetField,
};
final _combatUnitSchema = <String, _FieldReader>{
  ..._combatSubjectSchema,
  'subjectUnitId': _stringField,
};
final _proposalSchema = <String, _FieldReader>{
  'proposalId': _stringField,
  'fromPlayerId': _stringField,
  'toPlayerId': _stringField,
  'kind': AonwDiplomaticProposalKind.fromJson,
};

void _stringField(Object? value) => readString(value, 'client event field');
void _nullableStringField(Object? value) =>
    readNullableString(value, 'client event field');
void _intField(Object? value) => readInt(value, 'client event field');
void _unsignedField(Object? value) => readUnsigned(value, 'client event field');
void _nullableUnsignedField(Object? value) {
  if (value != null) readUnsigned(value, 'client event field');
}

void _boolField(Object? value) => readBool(value, 'client event field');
void _coordinateField(Object? value) => AonwCoordinate.fromJson(value);
void _technologyField(Object? value) =>
    _enumField(value, _technologyIds, 'technology id');
void _stabilityField(Object? value) =>
    _enumField(value, _stabilityBands, 'stability band');
void _scoreReasonField(Object? value) =>
    _enumField(value, _scoreReasons, 'diplomatic score reason');

void _finiteNumberField(Object? value) {
  if (value is! num || !value.toDouble().isFinite) {
    throw const FormatException('Invalid AoNW client event number.');
  }
}

void _enumField(Object? source, Set<String> values, String label) {
  final value = readString(source, label);
  if (!values.contains(value)) throw FormatException('Unknown AoNW $label.');
}

void _combatTargetField(Object? source) {
  final value = readObject(source, 'combat target');
  switch (readString(value['type'], 'combat target type')) {
    case 'unit':
      requireKeys(value, const {'type', 'unitId'}, 'combat target');
      readString(value['unitId'], 'target unit id');
    case 'city':
      requireKeys(value, const {'type', 'cityId'}, 'combat target');
      readString(value['cityId'], 'target city id');
    default:
      throw const FormatException('Unknown AoNW combat target.');
  }
}

void _workerCompletionField(Object? source) {
  final value = readObject(source, 'worker completion');
  switch (readString(value['type'], 'worker completion type')) {
    case 'fieldImprovement':
      requireKeys(value, const {'type', 'improvement'}, 'worker completion');
      AonwFieldImprovementKind.fromJson(value['improvement']);
    case 'road':
      requireKeys(value, const {'type'}, 'worker completion');
    default:
      throw const FormatException('Unknown AoNW worker completion.');
  }
}

const _stabilityBands = {'content', 'stable', 'strained', 'unrest'};
const _scoreReasons = {
  'manual',
  'unitAttack',
  'cityAttack',
  'declarationOfWar',
  'warmongerPenalty',
  'proposalAccepted',
  'proposalRejected',
  'messageResponse',
  'commonEnemyCooperation',
  'goldGift',
  'promiseBroken',
};
const _technologyIds = {
  'agriculture',
  'woodworking',
  'mining',
  'animalHusbandry',
  'hunting',
  'fishing',
  'craftsmanship',
  'trade',
  'storage',
  'waterEngineering',
  'stoneworking',
  'militaryOrganization',
  'advancedTrade',
  'construction',
  'navigation',
  'irrigation',
  'banking',
  'engineering',
  'metallurgy',
  'horsebackRiding',
  'ironWorking',
  'coalMining',
  'machinery',
  'administration',
  'logistics',
  'shipbuilding',
  'tactics',
  'economy',
  'urbanization',
  'fortifications',
  'strategy',
  'specialization',
  'writing',
  'mathematics',
  'medicine',
  'civilService',
  'siegecraft',
  'cartography',
  'guilds',
  'law',
  'education',
  'urbanPlanning',
  'navalDoctrine',
  'steel',
  'bureaucracy',
  'nationalism',
  'scientificMethod',
  'steamPower',
  'electricity',
  'combustion',
  'flight',
  'massProduction',
  'radio',
  'nuclearPhysics',
};
