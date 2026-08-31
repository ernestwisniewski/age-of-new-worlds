/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod/serverpod.dart' as _i1;

abstract class GameCreateMatchRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GameCreateMatchRequest._({
    required this.mapId,
    required this.mapDocument,
    required this.scenarioDocument,
    required this.rulesetId,
    required this.matchIdentityJson,
    required this.fogEnabled,
    required this.creatorPlayerId,
  });

  factory GameCreateMatchRequest({
    required String mapId,
    required String mapDocument,
    required String scenarioDocument,
    required String rulesetId,
    required String matchIdentityJson,
    required bool fogEnabled,
    required String creatorPlayerId,
  }) = _GameCreateMatchRequestImpl;

  factory GameCreateMatchRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameCreateMatchRequest(
      mapId: jsonSerialization['mapId'] as String,
      mapDocument: jsonSerialization['mapDocument'] as String,
      scenarioDocument: jsonSerialization['scenarioDocument'] as String,
      rulesetId: jsonSerialization['rulesetId'] as String,
      matchIdentityJson: jsonSerialization['matchIdentityJson'] as String,
      fogEnabled: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['fogEnabled'],
      ),
      creatorPlayerId: jsonSerialization['creatorPlayerId'] as String,
    );
  }

  String mapId;

  String mapDocument;

  String scenarioDocument;

  String rulesetId;

  String matchIdentityJson;

  bool fogEnabled;

  String creatorPlayerId;

  /// Returns a shallow copy of this [GameCreateMatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameCreateMatchRequest copyWith({
    String? mapId,
    String? mapDocument,
    String? scenarioDocument,
    String? rulesetId,
    String? matchIdentityJson,
    bool? fogEnabled,
    String? creatorPlayerId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameCreateMatchRequest',
      'mapId': mapId,
      'mapDocument': mapDocument,
      'scenarioDocument': scenarioDocument,
      'rulesetId': rulesetId,
      'matchIdentityJson': matchIdentityJson,
      'fogEnabled': fogEnabled,
      'creatorPlayerId': creatorPlayerId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameCreateMatchRequest',
      'mapId': mapId,
      'mapDocument': mapDocument,
      'scenarioDocument': scenarioDocument,
      'rulesetId': rulesetId,
      'matchIdentityJson': matchIdentityJson,
      'fogEnabled': fogEnabled,
      'creatorPlayerId': creatorPlayerId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameCreateMatchRequestImpl extends GameCreateMatchRequest {
  _GameCreateMatchRequestImpl({
    required String mapId,
    required String mapDocument,
    required String scenarioDocument,
    required String rulesetId,
    required String matchIdentityJson,
    required bool fogEnabled,
    required String creatorPlayerId,
  }) : super._(
         mapId: mapId,
         mapDocument: mapDocument,
         scenarioDocument: scenarioDocument,
         rulesetId: rulesetId,
         matchIdentityJson: matchIdentityJson,
         fogEnabled: fogEnabled,
         creatorPlayerId: creatorPlayerId,
       );

  /// Returns a shallow copy of this [GameCreateMatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameCreateMatchRequest copyWith({
    String? mapId,
    String? mapDocument,
    String? scenarioDocument,
    String? rulesetId,
    String? matchIdentityJson,
    bool? fogEnabled,
    String? creatorPlayerId,
  }) {
    return GameCreateMatchRequest(
      mapId: mapId ?? this.mapId,
      mapDocument: mapDocument ?? this.mapDocument,
      scenarioDocument: scenarioDocument ?? this.scenarioDocument,
      rulesetId: rulesetId ?? this.rulesetId,
      matchIdentityJson: matchIdentityJson ?? this.matchIdentityJson,
      fogEnabled: fogEnabled ?? this.fogEnabled,
      creatorPlayerId: creatorPlayerId ?? this.creatorPlayerId,
    );
  }
}
