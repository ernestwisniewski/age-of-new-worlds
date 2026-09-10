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
import '../../game/models/game_match_view.dart' as _i2;
import 'package:aonw_server/src/generated/protocol.dart' as _i3;

abstract class GameMatchHistoryEntry
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GameMatchHistoryEntry._({
    required this.match,
    required this.playerId,
    required this.turn,
    this.endedAt,
    this.outcomeCondition,
    this.winnerPlayerId,
    this.resignedAt,
    this.kickedAt,
  });

  factory GameMatchHistoryEntry({
    required _i2.GameMatchView match,
    required String playerId,
    required int turn,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    DateTime? resignedAt,
    DateTime? kickedAt,
  }) = _GameMatchHistoryEntryImpl;

  factory GameMatchHistoryEntry.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameMatchHistoryEntry(
      match: _i3.Protocol().deserialize<_i2.GameMatchView>(
        jsonSerialization['match'],
      ),
      playerId: jsonSerialization['playerId'] as String,
      turn: jsonSerialization['turn'] as int,
      endedAt: jsonSerialization['endedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endedAt']),
      outcomeCondition: jsonSerialization['outcomeCondition'] as String?,
      winnerPlayerId: jsonSerialization['winnerPlayerId'] as String?,
      resignedAt: jsonSerialization['resignedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resignedAt']),
      kickedAt: jsonSerialization['kickedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['kickedAt']),
    );
  }

  _i2.GameMatchView match;

  String playerId;

  int turn;

  DateTime? endedAt;

  String? outcomeCondition;

  String? winnerPlayerId;

  DateTime? resignedAt;

  DateTime? kickedAt;

  /// Returns a shallow copy of this [GameMatchHistoryEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameMatchHistoryEntry copyWith({
    _i2.GameMatchView? match,
    String? playerId,
    int? turn,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    DateTime? resignedAt,
    DateTime? kickedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameMatchHistoryEntry',
      'match': match.toJson(),
      'playerId': playerId,
      'turn': turn,
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      if (outcomeCondition != null) 'outcomeCondition': outcomeCondition,
      if (winnerPlayerId != null) 'winnerPlayerId': winnerPlayerId,
      if (resignedAt != null) 'resignedAt': resignedAt?.toJson(),
      if (kickedAt != null) 'kickedAt': kickedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameMatchHistoryEntry',
      'match': match.toJsonForProtocol(),
      'playerId': playerId,
      'turn': turn,
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      if (outcomeCondition != null) 'outcomeCondition': outcomeCondition,
      if (winnerPlayerId != null) 'winnerPlayerId': winnerPlayerId,
      if (resignedAt != null) 'resignedAt': resignedAt?.toJson(),
      if (kickedAt != null) 'kickedAt': kickedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameMatchHistoryEntryImpl extends GameMatchHistoryEntry {
  _GameMatchHistoryEntryImpl({
    required _i2.GameMatchView match,
    required String playerId,
    required int turn,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    DateTime? resignedAt,
    DateTime? kickedAt,
  }) : super._(
         match: match,
         playerId: playerId,
         turn: turn,
         endedAt: endedAt,
         outcomeCondition: outcomeCondition,
         winnerPlayerId: winnerPlayerId,
         resignedAt: resignedAt,
         kickedAt: kickedAt,
       );

  /// Returns a shallow copy of this [GameMatchHistoryEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameMatchHistoryEntry copyWith({
    _i2.GameMatchView? match,
    String? playerId,
    int? turn,
    Object? endedAt = _Undefined,
    Object? outcomeCondition = _Undefined,
    Object? winnerPlayerId = _Undefined,
    Object? resignedAt = _Undefined,
    Object? kickedAt = _Undefined,
  }) {
    return GameMatchHistoryEntry(
      match: match ?? this.match.copyWith(),
      playerId: playerId ?? this.playerId,
      turn: turn ?? this.turn,
      endedAt: endedAt is DateTime? ? endedAt : this.endedAt,
      outcomeCondition: outcomeCondition is String?
          ? outcomeCondition
          : this.outcomeCondition,
      winnerPlayerId: winnerPlayerId is String?
          ? winnerPlayerId
          : this.winnerPlayerId,
      resignedAt: resignedAt is DateTime? ? resignedAt : this.resignedAt,
      kickedAt: kickedAt is DateTime? ? kickedAt : this.kickedAt,
    );
  }
}
