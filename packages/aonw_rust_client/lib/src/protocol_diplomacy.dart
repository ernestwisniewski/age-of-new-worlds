import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

enum AonwDiplomaticRelationStatus {
  friendly,
  neutral,
  hostile,
  truce,
  war;

  factory AonwDiplomaticRelationStatus.fromJson(Object? source) =>
      _readEnum(source, values, 'diplomatic relation status');
}

enum AonwDiplomaticRelationChangeReason {
  manual,
  unitAttack,
  cityAttack,
  declarationOfWar,
  proposalAccepted,
  truceExpired,
  messageResponse,
  promiseBroken;

  factory AonwDiplomaticRelationChangeReason.fromJson(Object? source) =>
      _readEnum(source, values, 'diplomatic relation change reason');
}

enum AonwDiplomaticProposalKind {
  friendship,
  truce;

  factory AonwDiplomaticProposalKind.fromJson(Object? source) =>
      _readEnum(source, values, 'diplomatic proposal kind');
}

enum AonwDiplomaticMessageCategory {
  warning,
  complaint,
  request,
  praise,
  threat,
  cooperation;

  factory AonwDiplomaticMessageCategory.fromJson(Object? source) =>
      _readEnum(source, values, 'diplomatic message category');
}

enum AonwDiplomaticMessageTopic {
  troopsNearCities,
  citiesTooClose,
  blockedRoutes,
  withdrawScouts,
  avoidEscalation,
  commonEnemy,
  expansionProvocation,
  peacefulPraise;

  factory AonwDiplomaticMessageTopic.fromJson(Object? source) =>
      _readEnum(source, values, 'diplomatic message topic');
}

enum AonwDiplomaticMessageResponse {
  conciliatory,
  neutral,
  evasive,
  aggressive;

  factory AonwDiplomaticMessageResponse.fromJson(Object? source) =>
      _readEnum(source, values, 'diplomatic message response');
}

final class AonwPlayerDiplomacyView {
  const AonwPlayerDiplomacyView({
    required this.relations,
    required this.proposals,
    required this.messages,
    required this.resourceTradeAgreements,
  });

  factory AonwPlayerDiplomacyView.fromJson(Object? source) {
    final value = readObject(source, 'player diplomacy view');
    requireKeys(value, const {
      'relations',
      'proposals',
      'messages',
      'resourceTradeAgreements',
    }, 'player diplomacy view');
    return AonwPlayerDiplomacyView(
      relations: _views(
        value['relations'],
        'diplomatic relations',
        AonwPlayerDiplomaticRelationView.fromJson,
      ),
      proposals: _views(
        value['proposals'],
        'diplomatic proposals',
        AonwPlayerDiplomaticProposalView.fromJson,
      ),
      messages: _views(
        value['messages'],
        'diplomatic messages',
        AonwPlayerDiplomaticMessageView.fromJson,
      ),
      resourceTradeAgreements: _views(
        value['resourceTradeAgreements'],
        'resource trade agreements',
        AonwPlayerResourceTradeAgreementView.fromJson,
      ),
    );
  }

  final List<AonwPlayerDiplomaticRelationView> relations;
  final List<AonwPlayerDiplomaticProposalView> proposals;
  final List<AonwPlayerDiplomaticMessageView> messages;
  final List<AonwPlayerResourceTradeAgreementView> resourceTradeAgreements;
}

final class AonwPlayerDiplomaticRelationView {
  const AonwPlayerDiplomaticRelationView({
    required this.counterpartPlayerId,
    required this.status,
    required this.relationScore,
    required this.statusExpiresOnTurn,
    required this.lastChangedTurn,
    required this.lastChangeReason,
  });

  factory AonwPlayerDiplomaticRelationView.fromJson(Object? source) {
    final value = readObject(source, 'player diplomatic relation');
    requireKeys(value, const {
      'counterpartPlayerId',
      'status',
      'relationScore',
      'statusExpiresOnTurn',
      'lastChangedTurn',
      'lastChangeReason',
    }, 'player diplomatic relation');
    return AonwPlayerDiplomaticRelationView(
      counterpartPlayerId: readString(
        value['counterpartPlayerId'],
        'diplomatic counterpart player id',
      ),
      status: AonwDiplomaticRelationStatus.fromJson(value['status']),
      relationScore: readInt(
        value['relationScore'],
        'diplomatic relation score',
      ),
      statusExpiresOnTurn: _nullableUnsigned(
        value['statusExpiresOnTurn'],
        'diplomatic status expiry turn',
      ),
      lastChangedTurn: _nullableUnsigned(
        value['lastChangedTurn'],
        'diplomatic last changed turn',
      ),
      lastChangeReason: value['lastChangeReason'] == null
          ? null
          : AonwDiplomaticRelationChangeReason.fromJson(
              value['lastChangeReason'],
            ),
    );
  }

  final String counterpartPlayerId;
  final AonwDiplomaticRelationStatus status;
  final int relationScore;
  final int? statusExpiresOnTurn;
  final int? lastChangedTurn;
  final AonwDiplomaticRelationChangeReason? lastChangeReason;
}

final class AonwPlayerDiplomaticProposalView {
  const AonwPlayerDiplomaticProposalView({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.kind,
    required this.createdTurn,
    required this.expiresOnTurn,
    required this.goldPayment,
  });

  factory AonwPlayerDiplomaticProposalView.fromJson(Object? source) {
    final value = readObject(source, 'player diplomatic proposal');
    requireKeys(value, const {
      'id',
      'fromPlayerId',
      'toPlayerId',
      'kind',
      'createdTurn',
      'expiresOnTurn',
      'goldPayment',
    }, 'player diplomatic proposal');
    return AonwPlayerDiplomaticProposalView(
      id: readString(value['id'], 'diplomatic proposal id'),
      fromPlayerId: readString(value['fromPlayerId'], 'proposal sender'),
      toPlayerId: readString(value['toPlayerId'], 'proposal recipient'),
      kind: AonwDiplomaticProposalKind.fromJson(value['kind']),
      createdTurn: readUnsigned(value['createdTurn'], 'proposal created turn'),
      expiresOnTurn: readUnsigned(
        value['expiresOnTurn'],
        'proposal expiry turn',
      ),
      goldPayment: readInt(value['goldPayment'], 'proposal gold payment'),
    );
  }

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final AonwDiplomaticProposalKind kind;
  final int createdTurn;
  final int expiresOnTurn;
  final int goldPayment;
}

final class AonwPlayerDiplomaticMessageView {
  const AonwPlayerDiplomaticMessageView({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.topic,
    required this.category,
    required this.createdTurn,
    required this.expiresOnTurn,
    required this.response,
    required this.respondedTurn,
    required this.relationScoreDelta,
    required this.relationScoreAfter,
    required this.promiseDueTurn,
    required this.promiseBroken,
  });

  factory AonwPlayerDiplomaticMessageView.fromJson(Object? source) {
    final value = readObject(source, 'player diplomatic message');
    requireKeys(value, const {
      'id',
      'fromPlayerId',
      'toPlayerId',
      'topic',
      'category',
      'createdTurn',
      'expiresOnTurn',
      'response',
      'respondedTurn',
      'relationScoreDelta',
      'relationScoreAfter',
      'promiseDueTurn',
      'promiseBroken',
    }, 'player diplomatic message');
    return AonwPlayerDiplomaticMessageView(
      id: readString(value['id'], 'diplomatic message id'),
      fromPlayerId: readString(value['fromPlayerId'], 'message sender'),
      toPlayerId: readString(value['toPlayerId'], 'message recipient'),
      topic: AonwDiplomaticMessageTopic.fromJson(value['topic']),
      category: AonwDiplomaticMessageCategory.fromJson(value['category']),
      createdTurn: readUnsigned(value['createdTurn'], 'message created turn'),
      expiresOnTurn: readUnsigned(
        value['expiresOnTurn'],
        'message expiry turn',
      ),
      response: value['response'] == null
          ? null
          : AonwDiplomaticMessageResponse.fromJson(value['response']),
      respondedTurn: _nullableUnsigned(
        value['respondedTurn'],
        'message response turn',
      ),
      relationScoreDelta: readInt(
        value['relationScoreDelta'],
        'message relation score delta',
      ),
      relationScoreAfter: _nullableInt(
        value['relationScoreAfter'],
        'message relation score after',
      ),
      promiseDueTurn: _nullableUnsigned(
        value['promiseDueTurn'],
        'message promise due turn',
      ),
      promiseBroken: readBool(value['promiseBroken'], 'message promise state'),
    );
  }

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final AonwDiplomaticMessageTopic topic;
  final AonwDiplomaticMessageCategory category;
  final int createdTurn;
  final int expiresOnTurn;
  final AonwDiplomaticMessageResponse? response;
  final int? respondedTurn;
  final int relationScoreDelta;
  final int? relationScoreAfter;
  final int? promiseDueTurn;
  final bool promiseBroken;
}

final class AonwPlayerResourceTradeAgreementView {
  const AonwPlayerResourceTradeAgreementView({
    required this.id,
    required this.exporterPlayerId,
    required this.importerPlayerId,
    required this.resource,
    required this.goldPerTurn,
    required this.remainingTurns,
    required this.amountPerTurn,
    required this.exchangeGroupId,
  });

  factory AonwPlayerResourceTradeAgreementView.fromJson(Object? source) {
    final value = readObject(source, 'player resource trade agreement');
    requireKeys(value, const {
      'id',
      'exporterPlayerId',
      'importerPlayerId',
      'resource',
      'goldPerTurn',
      'remainingTurns',
      'amountPerTurn',
      'exchangeGroupId',
    }, 'player resource trade agreement');
    return AonwPlayerResourceTradeAgreementView(
      id: readString(value['id'], 'resource trade agreement id'),
      exporterPlayerId: readString(
        value['exporterPlayerId'],
        'resource exporter player id',
      ),
      importerPlayerId: readString(
        value['importerPlayerId'],
        'resource importer player id',
      ),
      resource: AonwResourceType.fromJson(value['resource']),
      goldPerTurn: readInt(
        value['goldPerTurn'],
        'resource trade gold per turn',
      ),
      remainingTurns: readUnsigned(
        value['remainingTurns'],
        'resource trade remaining turns',
      ),
      amountPerTurn: readUnsigned(
        value['amountPerTurn'],
        'resource trade amount per turn',
      ),
      exchangeGroupId: readNullableString(
        value['exchangeGroupId'],
        'resource trade exchange group id',
      ),
    );
  }

  final String id;
  final String exporterPlayerId;
  final String importerPlayerId;
  final AonwResourceType resource;
  final int goldPerTurn;
  final int remainingTurns;
  final int amountPerTurn;
  final String? exchangeGroupId;
}

T _readEnum<T extends Enum>(Object? source, List<T> values, String label) {
  final name = readString(source, label);
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => throw FormatException('Unknown AoNW $label $name.'),
  );
}

int? _nullableUnsigned(Object? value, String label) =>
    value == null ? null : readUnsigned(value, label);

int? _nullableInt(Object? value, String label) =>
    value == null ? null : readInt(value, label);

List<T> _views<T>(
  Object? value,
  String label,
  T Function(Object? value) parse,
) => readList(value, label, (item, _) => parse(item));
