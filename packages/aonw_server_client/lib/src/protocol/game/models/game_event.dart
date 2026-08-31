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

abstract class GameEvent implements _i1.SerializableModel {
  GameEvent._({
    this.id,
    required this.matchId,
    this.match,
    required this.offset,
    required this.createdAt,
  });

  factory GameEvent({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int offset,
    required DateTime createdAt,
  }) = _GameEventImpl;

  factory GameEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameEvent(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      offset: jsonSerialization['offset'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int matchId;

  _i2.GameMatch? match;

  int offset;

  DateTime createdAt;

  /// Returns a shallow copy of this [GameEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameEvent copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    int? offset,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameEvent',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'offset': offset,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameEventImpl extends GameEvent {
  _GameEventImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int offset,
    required DateTime createdAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         offset: offset,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [GameEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameEvent copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    int? offset,
    DateTime? createdAt,
  }) {
    return GameEvent(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      offset: offset ?? this.offset,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
