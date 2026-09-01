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

abstract class GameKickParticipantRequest implements _i1.SerializableModel {
  GameKickParticipantRequest._({
    required this.matchId,
    required this.clientCommandId,
    required this.expectedRevision,
    required this.targetPlayerId,
  });

  factory GameKickParticipantRequest({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
    required String targetPlayerId,
  }) = _GameKickParticipantRequestImpl;

  factory GameKickParticipantRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameKickParticipantRequest(
      matchId: jsonSerialization['matchId'] as String,
      clientCommandId: jsonSerialization['clientCommandId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      targetPlayerId: jsonSerialization['targetPlayerId'] as String,
    );
  }

  String matchId;

  String clientCommandId;

  int expectedRevision;

  String targetPlayerId;

  /// Returns a shallow copy of this [GameKickParticipantRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameKickParticipantRequest copyWith({
    String? matchId,
    String? clientCommandId,
    int? expectedRevision,
    String? targetPlayerId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameKickParticipantRequest',
      'matchId': matchId,
      'clientCommandId': clientCommandId,
      'expectedRevision': expectedRevision,
      'targetPlayerId': targetPlayerId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameKickParticipantRequestImpl extends GameKickParticipantRequest {
  _GameKickParticipantRequestImpl({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
    required String targetPlayerId,
  }) : super._(
         matchId: matchId,
         clientCommandId: clientCommandId,
         expectedRevision: expectedRevision,
         targetPlayerId: targetPlayerId,
       );

  /// Returns a shallow copy of this [GameKickParticipantRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameKickParticipantRequest copyWith({
    String? matchId,
    String? clientCommandId,
    int? expectedRevision,
    String? targetPlayerId,
  }) {
    return GameKickParticipantRequest(
      matchId: matchId ?? this.matchId,
      clientCommandId: clientCommandId ?? this.clientCommandId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
    );
  }
}
