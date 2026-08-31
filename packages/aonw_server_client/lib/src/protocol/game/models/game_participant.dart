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
import '../../game/models/game_match.dart' as _i2;
import 'package:aonw_server_client/src/protocol/protocol.dart' as _i3;

abstract class GameParticipant implements _i1.SerializableModel {
  GameParticipant._({
    this.id,
    required this.matchId,
    this.match,
    required this.userIdentifier,
    required this.playerId,
    required this.joinedAt,
  });

  factory GameParticipant({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String userIdentifier,
    required String playerId,
    required DateTime joinedAt,
  }) = _GameParticipantImpl;

  factory GameParticipant.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameParticipant(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      userIdentifier: jsonSerialization['userIdentifier'] as String,
      playerId: jsonSerialization['playerId'] as String,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int matchId;

  _i2.GameMatch? match;

  String userIdentifier;

  String playerId;

  DateTime joinedAt;

  /// Returns a shallow copy of this [GameParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameParticipant copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? userIdentifier,
    String? playerId,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameParticipant',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'userIdentifier': userIdentifier,
      'playerId': playerId,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameParticipantImpl extends GameParticipant {
  _GameParticipantImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String userIdentifier,
    required String playerId,
    required DateTime joinedAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         userIdentifier: userIdentifier,
         playerId: playerId,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [GameParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameParticipant copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? userIdentifier,
    String? playerId,
    DateTime? joinedAt,
  }) {
    return GameParticipant(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      userIdentifier: userIdentifier ?? this.userIdentifier,
      playerId: playerId ?? this.playerId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
