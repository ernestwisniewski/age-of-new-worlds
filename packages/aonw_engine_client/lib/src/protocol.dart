import 'dart:convert';

import 'package:aonw_engine_client/src/api.dart';
import 'package:aonw_engine_client/src/native_identity.dart';
import 'package:aonw_engine_client/src/protocol_city_view.dart';
import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_diplomacy.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_match.dart';
import 'package:aonw_engine_client/src/protocol_pending_action.dart';
import 'package:aonw_engine_client/src/protocol_research_values.dart';
import 'package:aonw_engine_client/src/protocol_response.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

export 'protocol_artifact.dart';
export 'protocol_city_view.dart';
export 'protocol_coordinate.dart';
export 'protocol_diplomacy.dart';
export 'protocol_event.dart';
export 'protocol_evidence.dart';
export 'protocol_execution.dart';
export 'protocol_map.dart';
export 'protocol_match.dart';
export 'protocol_outcome.dart';
export 'protocol_pending_action.dart';
export 'protocol_player_economy.dart';
export 'protocol_player_research.dart';
export 'protocol_player_victory.dart';
export 'protocol_player_view.dart';
export 'protocol_query.dart';
export 'protocol_research_values.dart';
export 'protocol_response.dart';
export 'protocol_values.dart';

part 'protocol_city_request.dart';
part 'protocol_artifact_request.dart';
part 'protocol_diplomacy_request.dart';
part 'protocol_production_request.dart';
part 'protocol_research_request.dart';
part 'protocol_worker_request.dart';

final class AonwClientRequest {
  AonwClientRequest._(this.request);

  factory AonwClientRequest.capabilities() =>
      AonwClientRequest._(const {'type': 'capabilities'});

  factory AonwClientRequest.inspectMap({required String mapDocument}) =>
      AonwClientRequest._({'type': 'inspectMap', 'mapDocument': mapDocument});

  factory AonwClientRequest.openSession({
    required String mapDocument,
    required String scenarioDocument,
    required String actorPlayerId,
  }) => AonwClientRequest._({
    'type': 'openSession',
    'mapDocument': mapDocument,
    'scenarioDocument': scenarioDocument,
    'actorPlayerId': actorPlayerId,
  });

  factory AonwClientRequest.startMatch({
    required String mapDocument,
    required String scenarioDocument,
    required String actorPlayerId,
    required AonwMatchIdentity matchIdentity,
    required bool fogEnabled,
  }) => AonwClientRequest._({
    'type': 'startMatch',
    'mapDocument': mapDocument,
    'scenarioDocument': scenarioDocument,
    'actorPlayerId': actorPlayerId,
    'matchIdentity': matchIdentity.toJson(),
    'fogMode': fogEnabled ? 'enabled' : 'disabled',
  });

  factory AonwClientRequest.handoffActor({required String actorPlayerId}) =>
      AonwClientRequest._({
        'type': 'handoffActor',
        'actorPlayerId': actorPlayerId,
      });

  factory AonwClientRequest.advanceAiTurn({
    required String actorPlayerId,
    required int commandBudget,
  }) => AonwClientRequest._({
    'type': 'advanceAiTurn',
    'actorPlayerId': actorPlayerId,
    'commandBudget': commandBudget,
  });

  factory AonwClientRequest.closeSession() =>
      AonwClientRequest._(const {'type': 'closeSession'});

  factory AonwClientRequest.snapshot() =>
      AonwClientRequest._(const {'type': 'snapshot'});

  factory AonwClientRequest.reachable({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'reachable',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
    },
  });

  factory AonwClientRequest.routePlan({
    required int expectedRevision,
    required String unitId,
    required int targetCol,
    required int targetRow,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'routePlan',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
      'target': {'col': targetCol, 'row': targetRow},
    },
  });

  factory AonwClientRequest.unitLogisticsOptions({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'unitLogisticsOptions',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
    },
  });

  factory AonwClientRequest.combatPreview({
    required int expectedRevision,
    required String attackerUnitId,
    required int defenderCol,
    required int defenderRow,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'combatPreview',
      'expectedRevision': expectedRevision,
      'attackerUnitId': attackerUnitId,
      'defender': {'col': defenderCol, 'row': defenderRow},
    },
  });

  factory AonwClientRequest.moveUnit({
    required int expectedRevision,
    required String unitId,
    required int targetCol,
    required int targetRow,
  }) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': 'moveUnit',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
      'target': {'col': targetCol, 'row': targetRow},
    },
  });

  factory AonwClientRequest.autoExploreUnit({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._(
    _unitCommand('autoExploreUnit', expectedRevision, unitId),
  );

  factory AonwClientRequest.assignMerchantTradeRoute({
    required int expectedRevision,
    required String unitId,
    required String destinationCityId,
  }) => AonwClientRequest._(
    _merchantCommand(
      'assignMerchantTradeRoute',
      expectedRevision,
      unitId,
      destinationCityId,
    ),
  );

  factory AonwClientRequest.moveMerchantToCity({
    required int expectedRevision,
    required String unitId,
    required String destinationCityId,
  }) => AonwClientRequest._(
    _merchantCommand(
      'moveMerchantToCity',
      expectedRevision,
      unitId,
      destinationCityId,
    ),
  );

  factory AonwClientRequest.detachTroop({
    required int expectedRevision,
    required String unitId,
    required String troopKind,
  }) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': 'detachTroop',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
      'troopKind': troopKind,
    },
  });

  factory AonwClientRequest.attackHex({
    required int expectedRevision,
    required String attackerUnitId,
    required int defenderCol,
    required int defenderRow,
    required AonwCityConquestAction cityConquestAction,
  }) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': 'attackHex',
      'expectedRevision': expectedRevision,
      'attackerUnitId': attackerUnitId,
      'defender': {'col': defenderCol, 'row': defenderRow},
      'cityConquestAction': cityConquestAction.name,
    },
  });

  factory AonwClientRequest.cancelUnitAction({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._(
    _unitCommand('cancelUnitAction', expectedRevision, unitId),
  );

  factory AonwClientRequest.skipUnitTurn({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._(
    _unitCommand('skipUnitTurn', expectedRevision, unitId),
  );

  factory AonwClientRequest.fortifyUnit({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._(
    _unitCommand('fortifyUnit', expectedRevision, unitId),
  );

  factory AonwClientRequest.endTurn({required int expectedRevision}) =>
      AonwClientRequest._({
        'type': 'dispatch',
        'command': {'type': 'endTurn', 'expectedRevision': expectedRevision},
      });

  factory AonwClientRequest.exportSave() =>
      AonwClientRequest._(const {'type': 'exportSave'});

  factory AonwClientRequest.openSave({
    required String mapDocument,
    required String saveDocument,
  }) => AonwClientRequest._({
    'type': 'openSave',
    'mapDocument': mapDocument,
    'saveDocument': saveDocument,
  });

  factory AonwClientRequest.exportReplay() =>
      AonwClientRequest._(const {'type': 'exportReplay'});

  factory AonwClientRequest.verifyReplay({
    required String mapDocument,
    required String replayDocument,
  }) => AonwClientRequest._({
    'type': 'verifyReplay',
    'mapDocument': mapDocument,
    'replayDocument': replayDocument,
  });

  factory AonwClientRequest.openReplay({
    required String mapDocument,
    required String replayDocument,
    required String recipientPlayerId,
  }) => AonwClientRequest._({
    'type': 'openReplay',
    'mapDocument': mapDocument,
    'replayDocument': replayDocument,
    'recipientPlayerId': recipientPlayerId,
  });

  factory AonwClientRequest.seekReplay({required int position}) =>
      AonwClientRequest._({'type': 'seekReplay', 'position': position});

  final Map<String, Object?> request;

  String toJson() =>
      jsonEncode({'apiVersion': aonwClientApiVersion, 'request': request});

  static Map<String, Object?> _unitCommand(
    String type,
    int expectedRevision,
    String unitId,
  ) => {
    'type': 'dispatch',
    'command': {
      'type': type,
      'expectedRevision': expectedRevision,
      'unitId': unitId,
    },
  };

  static Map<String, Object?> _merchantCommand(
    String type,
    int expectedRevision,
    String unitId,
    String destinationCityId,
  ) => {
    'type': 'dispatch',
    'command': {
      'type': type,
      'expectedRevision': expectedRevision,
      'unitId': unitId,
      'destinationCityId': destinationCityId,
    },
  };
}

final class AonwClientResponse {
  AonwClientResponse._({this.response, this.error});

  factory AonwClientResponse.parse(String source) {
    final value = jsonDecode(source);
    final envelope = readObject(value, 'client response');
    requireKeys(envelope, const {'apiVersion', 'outcome'}, 'client response');
    if (envelope['apiVersion'] != aonwClientApiVersion) {
      throw const FormatException('Unsupported AoNW client API version.');
    }
    final outcome = readObject(envelope['outcome'], 'client outcome');
    return switch (outcome['status']) {
      'success' => _success(outcome),
      'failure' => AonwClientResponse._(error: _failure(outcome)),
      _ => throw const FormatException('Invalid AoNW client outcome.'),
    };
  }

  final AonwClientResponseBody? response;
  final AonwClientError? error;

  bool get isSuccess => response != null;

  T require<T extends AonwClientResponseBody>() {
    final value = response;
    if (value == null) {
      throw StateError(error?.message ?? 'Client request failed.');
    }
    if (value is! T) {
      throw FormatException('Expected AoNW response type $T.');
    }
    return value;
  }

  static AonwClientResponse _success(Map<String, Object?> outcome) {
    requireKeys(outcome, const {
      'status',
      'response',
    }, 'successful client outcome');
    return AonwClientResponse._(
      response: AonwClientResponseBody.fromJson(outcome['response']),
    );
  }

  static AonwClientError _failure(Map<String, Object?> outcome) {
    requireKeys(outcome, const {'status', 'error'}, 'failed client outcome');
    return AonwClientError.fromJson(
      readObject(outcome['error'], 'client failure response'),
    );
  }
}

final class AonwClientError {
  const AonwClientError({required this.code, required this.message});

  factory AonwClientError.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'code', 'message'}, 'client error');
    final code = value['code'];
    final message = value['message'];
    if (code is! String || message is! String) {
      throw const FormatException('Invalid AoNW client error.');
    }
    return AonwClientError(code: code, message: message);
  }

  final String code;
  final String message;
}

extension AonwEngineSessionClientProtocol on AonwEngineSession {
  Future<AonwClientResponse> send(AonwClientRequest request) async =>
      AonwClientResponse.parse(await requestJson(request.toJson()));
}
