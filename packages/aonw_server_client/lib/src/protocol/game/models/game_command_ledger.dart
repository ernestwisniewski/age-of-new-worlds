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

abstract class GameCommandLedger implements _i1.SerializableModel {
  GameCommandLedger._({
    this.id,
    required this.matchId,
    this.match,
    required this.playerId,
    required this.clientCommandId,
    required this.expectedRevision,
    required this.initialEventOffset,
    required this.finalEventOffset,
    required this.recipientOutcomeJson,
    required this.createdAt,
  });

  factory GameCommandLedger({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String playerId,
    required String clientCommandId,
    required int expectedRevision,
    required int initialEventOffset,
    required int finalEventOffset,
    required String recipientOutcomeJson,
    required DateTime createdAt,
  }) = _GameCommandLedgerImpl;

  factory GameCommandLedger.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameCommandLedger(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      playerId: jsonSerialization['playerId'] as String,
      clientCommandId: jsonSerialization['clientCommandId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      initialEventOffset: jsonSerialization['initialEventOffset'] as int,
      finalEventOffset: jsonSerialization['finalEventOffset'] as int,
      recipientOutcomeJson: jsonSerialization['recipientOutcomeJson'] as String,
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

  String playerId;

  String clientCommandId;

  int expectedRevision;

  int initialEventOffset;

  int finalEventOffset;

  String recipientOutcomeJson;

  DateTime createdAt;

  /// Returns a shallow copy of this [GameCommandLedger]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameCommandLedger copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? playerId,
    String? clientCommandId,
    int? expectedRevision,
    int? initialEventOffset,
    int? finalEventOffset,
    String? recipientOutcomeJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameCommandLedger',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'playerId': playerId,
      'clientCommandId': clientCommandId,
      'expectedRevision': expectedRevision,
      'initialEventOffset': initialEventOffset,
      'finalEventOffset': finalEventOffset,
      'recipientOutcomeJson': recipientOutcomeJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameCommandLedgerImpl extends GameCommandLedger {
  _GameCommandLedgerImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String playerId,
    required String clientCommandId,
    required int expectedRevision,
    required int initialEventOffset,
    required int finalEventOffset,
    required String recipientOutcomeJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         playerId: playerId,
         clientCommandId: clientCommandId,
         expectedRevision: expectedRevision,
         initialEventOffset: initialEventOffset,
         finalEventOffset: finalEventOffset,
         recipientOutcomeJson: recipientOutcomeJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [GameCommandLedger]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameCommandLedger copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? playerId,
    String? clientCommandId,
    int? expectedRevision,
    int? initialEventOffset,
    int? finalEventOffset,
    String? recipientOutcomeJson,
    DateTime? createdAt,
  }) {
    return GameCommandLedger(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      playerId: playerId ?? this.playerId,
      clientCommandId: clientCommandId ?? this.clientCommandId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      initialEventOffset: initialEventOffset ?? this.initialEventOffset,
      finalEventOffset: finalEventOffset ?? this.finalEventOffset,
      recipientOutcomeJson: recipientOutcomeJson ?? this.recipientOutcomeJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
