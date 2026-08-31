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

abstract class GameJoinMatchRequest implements _i1.SerializableModel {
  GameJoinMatchRequest._({
    required this.matchId,
    required this.playerId,
  });

  factory GameJoinMatchRequest({
    required String matchId,
    required String playerId,
  }) = _GameJoinMatchRequestImpl;

  factory GameJoinMatchRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameJoinMatchRequest(
      matchId: jsonSerialization['matchId'] as String,
      playerId: jsonSerialization['playerId'] as String,
    );
  }

  String matchId;

  String playerId;

  /// Returns a shallow copy of this [GameJoinMatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameJoinMatchRequest copyWith({
    String? matchId,
    String? playerId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameJoinMatchRequest',
      'matchId': matchId,
      'playerId': playerId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameJoinMatchRequestImpl extends GameJoinMatchRequest {
  _GameJoinMatchRequestImpl({
    required String matchId,
    required String playerId,
  }) : super._(
         matchId: matchId,
         playerId: playerId,
       );

  /// Returns a shallow copy of this [GameJoinMatchRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameJoinMatchRequest copyWith({
    String? matchId,
    String? playerId,
  }) {
    return GameJoinMatchRequest(
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
    );
  }
}
