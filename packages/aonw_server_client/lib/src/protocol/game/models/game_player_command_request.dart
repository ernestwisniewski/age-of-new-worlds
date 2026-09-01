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

abstract class GamePlayerCommandRequest implements _i1.SerializableModel {
  GamePlayerCommandRequest._({
    required this.matchId,
    required this.clientCommandId,
    required this.commandJson,
  });

  factory GamePlayerCommandRequest({
    required String matchId,
    required String clientCommandId,
    required String commandJson,
  }) = _GamePlayerCommandRequestImpl;

  factory GamePlayerCommandRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GamePlayerCommandRequest(
      matchId: jsonSerialization['matchId'] as String,
      clientCommandId: jsonSerialization['clientCommandId'] as String,
      commandJson: jsonSerialization['commandJson'] as String,
    );
  }

  String matchId;

  String clientCommandId;

  String commandJson;

  /// Returns a shallow copy of this [GamePlayerCommandRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GamePlayerCommandRequest copyWith({
    String? matchId,
    String? clientCommandId,
    String? commandJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GamePlayerCommandRequest',
      'matchId': matchId,
      'clientCommandId': clientCommandId,
      'commandJson': commandJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GamePlayerCommandRequestImpl extends GamePlayerCommandRequest {
  _GamePlayerCommandRequestImpl({
    required String matchId,
    required String clientCommandId,
    required String commandJson,
  }) : super._(
         matchId: matchId,
         clientCommandId: clientCommandId,
         commandJson: commandJson,
       );

  /// Returns a shallow copy of this [GamePlayerCommandRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GamePlayerCommandRequest copyWith({
    String? matchId,
    String? clientCommandId,
    String? commandJson,
  }) {
    return GamePlayerCommandRequest(
      matchId: matchId ?? this.matchId,
      clientCommandId: clientCommandId ?? this.clientCommandId,
      commandJson: commandJson ?? this.commandJson,
    );
  }
}
