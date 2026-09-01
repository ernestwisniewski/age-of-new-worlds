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

abstract class GamePlayerQueryRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GamePlayerQueryRequest._({
    required this.matchId,
    required this.queryJson,
  });

  factory GamePlayerQueryRequest({
    required String matchId,
    required String queryJson,
  }) = _GamePlayerQueryRequestImpl;

  factory GamePlayerQueryRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GamePlayerQueryRequest(
      matchId: jsonSerialization['matchId'] as String,
      queryJson: jsonSerialization['queryJson'] as String,
    );
  }

  String matchId;

  String queryJson;

  /// Returns a shallow copy of this [GamePlayerQueryRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GamePlayerQueryRequest copyWith({
    String? matchId,
    String? queryJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GamePlayerQueryRequest',
      'matchId': matchId,
      'queryJson': queryJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GamePlayerQueryRequest',
      'matchId': matchId,
      'queryJson': queryJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GamePlayerQueryRequestImpl extends GamePlayerQueryRequest {
  _GamePlayerQueryRequestImpl({
    required String matchId,
    required String queryJson,
  }) : super._(
         matchId: matchId,
         queryJson: queryJson,
       );

  /// Returns a shallow copy of this [GamePlayerQueryRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GamePlayerQueryRequest copyWith({
    String? matchId,
    String? queryJson,
  }) {
    return GamePlayerQueryRequest(
      matchId: matchId ?? this.matchId,
      queryJson: queryJson ?? this.queryJson,
    );
  }
}
