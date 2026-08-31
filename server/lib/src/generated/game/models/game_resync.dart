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

abstract class GameResync
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GameResync._({
    required this.matchId,
    required this.playerId,
    required this.eventOffset,
    required this.snapshotJson,
  });

  factory GameResync({
    required String matchId,
    required String playerId,
    required int eventOffset,
    required String snapshotJson,
  }) = _GameResyncImpl;

  factory GameResync.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameResync(
      matchId: jsonSerialization['matchId'] as String,
      playerId: jsonSerialization['playerId'] as String,
      eventOffset: jsonSerialization['eventOffset'] as int,
      snapshotJson: jsonSerialization['snapshotJson'] as String,
    );
  }

  String matchId;

  String playerId;

  int eventOffset;

  String snapshotJson;

  /// Returns a shallow copy of this [GameResync]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameResync copyWith({
    String? matchId,
    String? playerId,
    int? eventOffset,
    String? snapshotJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameResync',
      'matchId': matchId,
      'playerId': playerId,
      'eventOffset': eventOffset,
      'snapshotJson': snapshotJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameResync',
      'matchId': matchId,
      'playerId': playerId,
      'eventOffset': eventOffset,
      'snapshotJson': snapshotJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameResyncImpl extends GameResync {
  _GameResyncImpl({
    required String matchId,
    required String playerId,
    required int eventOffset,
    required String snapshotJson,
  }) : super._(
         matchId: matchId,
         playerId: playerId,
         eventOffset: eventOffset,
         snapshotJson: snapshotJson,
       );

  /// Returns a shallow copy of this [GameResync]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameResync copyWith({
    String? matchId,
    String? playerId,
    int? eventOffset,
    String? snapshotJson,
  }) {
    return GameResync(
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      eventOffset: eventOffset ?? this.eventOffset,
      snapshotJson: snapshotJson ?? this.snapshotJson,
    );
  }
}
