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

abstract class GameReplayFrame implements _i1.SerializableModel {
  GameReplayFrame._({
    required this.matchId,
    required this.playerId,
    required this.frameJson,
  });

  factory GameReplayFrame({
    required String matchId,
    required String playerId,
    required String frameJson,
  }) = _GameReplayFrameImpl;

  factory GameReplayFrame.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameReplayFrame(
      matchId: jsonSerialization['matchId'] as String,
      playerId: jsonSerialization['playerId'] as String,
      frameJson: jsonSerialization['frameJson'] as String,
    );
  }

  String matchId;

  String playerId;

  String frameJson;

  /// Returns a shallow copy of this [GameReplayFrame]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameReplayFrame copyWith({
    String? matchId,
    String? playerId,
    String? frameJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameReplayFrame',
      'matchId': matchId,
      'playerId': playerId,
      'frameJson': frameJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameReplayFrameImpl extends GameReplayFrame {
  _GameReplayFrameImpl({
    required String matchId,
    required String playerId,
    required String frameJson,
  }) : super._(
         matchId: matchId,
         playerId: playerId,
         frameJson: frameJson,
       );

  /// Returns a shallow copy of this [GameReplayFrame]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameReplayFrame copyWith({
    String? matchId,
    String? playerId,
    String? frameJson,
  }) {
    return GameReplayFrame(
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      frameJson: frameJson ?? this.frameJson,
    );
  }
}
