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

abstract class GameRecipientSnapshot implements _i1.SerializableModel {
  GameRecipientSnapshot._({
    this.id,
    required this.matchId,
    this.match,
    required this.playerId,
    required this.eventOffset,
    required this.snapshotJson,
    required this.updatedAt,
  });

  factory GameRecipientSnapshot({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String playerId,
    required int eventOffset,
    required String snapshotJson,
    required DateTime updatedAt,
  }) = _GameRecipientSnapshotImpl;

  factory GameRecipientSnapshot.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameRecipientSnapshot(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      playerId: jsonSerialization['playerId'] as String,
      eventOffset: jsonSerialization['eventOffset'] as int,
      snapshotJson: jsonSerialization['snapshotJson'] as String,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int matchId;

  _i2.GameMatch? match;

  String playerId;

  int eventOffset;

  String snapshotJson;

  DateTime updatedAt;

  /// Returns a shallow copy of this [GameRecipientSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameRecipientSnapshot copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? playerId,
    int? eventOffset,
    String? snapshotJson,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameRecipientSnapshot',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'playerId': playerId,
      'eventOffset': eventOffset,
      'snapshotJson': snapshotJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameRecipientSnapshotImpl extends GameRecipientSnapshot {
  _GameRecipientSnapshotImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String playerId,
    required int eventOffset,
    required String snapshotJson,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         playerId: playerId,
         eventOffset: eventOffset,
         snapshotJson: snapshotJson,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [GameRecipientSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameRecipientSnapshot copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? playerId,
    int? eventOffset,
    String? snapshotJson,
    DateTime? updatedAt,
  }) {
    return GameRecipientSnapshot(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      playerId: playerId ?? this.playerId,
      eventOffset: eventOffset ?? this.eventOffset,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
