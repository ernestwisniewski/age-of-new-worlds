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

abstract class GameSubmitTurnRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GameSubmitTurnRequest._({
    required this.matchId,
    required this.clientCommandId,
    required this.expectedRevision,
  });

  factory GameSubmitTurnRequest({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  }) = _GameSubmitTurnRequestImpl;

  factory GameSubmitTurnRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameSubmitTurnRequest(
      matchId: jsonSerialization['matchId'] as String,
      clientCommandId: jsonSerialization['clientCommandId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
    );
  }

  String matchId;

  String clientCommandId;

  int expectedRevision;

  /// Returns a shallow copy of this [GameSubmitTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameSubmitTurnRequest copyWith({
    String? matchId,
    String? clientCommandId,
    int? expectedRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameSubmitTurnRequest',
      'matchId': matchId,
      'clientCommandId': clientCommandId,
      'expectedRevision': expectedRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameSubmitTurnRequest',
      'matchId': matchId,
      'clientCommandId': clientCommandId,
      'expectedRevision': expectedRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameSubmitTurnRequestImpl extends GameSubmitTurnRequest {
  _GameSubmitTurnRequestImpl({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  }) : super._(
         matchId: matchId,
         clientCommandId: clientCommandId,
         expectedRevision: expectedRevision,
       );

  /// Returns a shallow copy of this [GameSubmitTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameSubmitTurnRequest copyWith({
    String? matchId,
    String? clientCommandId,
    int? expectedRevision,
  }) {
    return GameSubmitTurnRequest(
      matchId: matchId ?? this.matchId,
      clientCommandId: clientCommandId ?? this.clientCommandId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
    );
  }
}
