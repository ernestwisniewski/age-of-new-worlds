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

import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class GameMatch implements _i1.SerializableModel {
  GameMatch._({
    this.id,
    required this.publicId,
    required this.mapId,
    required this.mapHash,
    required this.rulesetId,
    required this.rulesetHash,
    required this.state,
    this.hostPlayerId,
    required this.turn,
    this.startedAt,
    this.endedAt,
    this.outcomeCondition,
    this.winnerPlayerId,
    required this.revision,
    required this.eventOffset,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GameMatch({
    int? id,
    required String publicId,
    required String mapId,
    required String mapHash,
    required String rulesetId,
    required String rulesetHash,
    required String state,
    String? hostPlayerId,
    required int turn,
    DateTime? startedAt,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    required int revision,
    required int eventOffset,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _GameMatchImpl;

  factory GameMatch.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameMatch(
      id: jsonSerialization['id'] as int?,
      publicId: jsonSerialization['publicId'] as String,
      mapId: jsonSerialization['mapId'] as String,
      mapHash: jsonSerialization['mapHash'] as String,
      rulesetId: jsonSerialization['rulesetId'] as String,
      rulesetHash: jsonSerialization['rulesetHash'] as String,
      state: jsonSerialization['state'] as String,
      hostPlayerId: jsonSerialization['hostPlayerId'] as String?,
      turn: jsonSerialization['turn'] as int,
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      endedAt: jsonSerialization['endedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endedAt']),
      outcomeCondition: jsonSerialization['outcomeCondition'] as String?,
      winnerPlayerId: jsonSerialization['winnerPlayerId'] as String?,
      revision: jsonSerialization['revision'] as int,
      eventOffset: jsonSerialization['eventOffset'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String publicId;

  String mapId;

  String mapHash;

  String rulesetId;

  String rulesetHash;

  String state;

  String? hostPlayerId;

  int turn;

  DateTime? startedAt;

  DateTime? endedAt;

  String? outcomeCondition;

  String? winnerPlayerId;

  int revision;

  int eventOffset;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [GameMatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameMatch copyWith({
    int? id,
    String? publicId,
    String? mapId,
    String? mapHash,
    String? rulesetId,
    String? rulesetHash,
    String? state,
    String? hostPlayerId,
    int? turn,
    DateTime? startedAt,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    int? revision,
    int? eventOffset,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameMatch',
      if (id != null) 'id': id,
      'publicId': publicId,
      'mapId': mapId,
      'mapHash': mapHash,
      'rulesetId': rulesetId,
      'rulesetHash': rulesetHash,
      'state': state,
      if (hostPlayerId != null) 'hostPlayerId': hostPlayerId,
      'turn': turn,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      if (outcomeCondition != null) 'outcomeCondition': outcomeCondition,
      if (winnerPlayerId != null) 'winnerPlayerId': winnerPlayerId,
      'revision': revision,
      'eventOffset': eventOffset,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameMatchImpl extends GameMatch {
  _GameMatchImpl({
    int? id,
    required String publicId,
    required String mapId,
    required String mapHash,
    required String rulesetId,
    required String rulesetHash,
    required String state,
    String? hostPlayerId,
    required int turn,
    DateTime? startedAt,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    required int revision,
    required int eventOffset,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         publicId: publicId,
         mapId: mapId,
         mapHash: mapHash,
         rulesetId: rulesetId,
         rulesetHash: rulesetHash,
         state: state,
         hostPlayerId: hostPlayerId,
         turn: turn,
         startedAt: startedAt,
         endedAt: endedAt,
         outcomeCondition: outcomeCondition,
         winnerPlayerId: winnerPlayerId,
         revision: revision,
         eventOffset: eventOffset,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [GameMatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameMatch copyWith({
    Object? id = _Undefined,
    String? publicId,
    String? mapId,
    String? mapHash,
    String? rulesetId,
    String? rulesetHash,
    String? state,
    Object? hostPlayerId = _Undefined,
    int? turn,
    Object? startedAt = _Undefined,
    Object? endedAt = _Undefined,
    Object? outcomeCondition = _Undefined,
    Object? winnerPlayerId = _Undefined,
    int? revision,
    int? eventOffset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameMatch(
      id: id is int? ? id : this.id,
      publicId: publicId ?? this.publicId,
      mapId: mapId ?? this.mapId,
      mapHash: mapHash ?? this.mapHash,
      rulesetId: rulesetId ?? this.rulesetId,
      rulesetHash: rulesetHash ?? this.rulesetHash,
      state: state ?? this.state,
      hostPlayerId: hostPlayerId is String? ? hostPlayerId : this.hostPlayerId,
      turn: turn ?? this.turn,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      endedAt: endedAt is DateTime? ? endedAt : this.endedAt,
      outcomeCondition: outcomeCondition is String?
          ? outcomeCondition
          : this.outcomeCondition,
      winnerPlayerId: winnerPlayerId is String?
          ? winnerPlayerId
          : this.winnerPlayerId,
      revision: revision ?? this.revision,
      eventOffset: eventOffset ?? this.eventOffset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
