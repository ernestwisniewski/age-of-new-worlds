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

abstract class GamePlayerQueryOutcome
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GamePlayerQueryOutcome._({
    required this.matchId,
    required this.outcomeJson,
  });

  factory GamePlayerQueryOutcome({
    required String matchId,
    required String outcomeJson,
  }) = _GamePlayerQueryOutcomeImpl;

  factory GamePlayerQueryOutcome.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GamePlayerQueryOutcome(
      matchId: jsonSerialization['matchId'] as String,
      outcomeJson: jsonSerialization['outcomeJson'] as String,
    );
  }

  String matchId;

  String outcomeJson;

  /// Returns a shallow copy of this [GamePlayerQueryOutcome]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GamePlayerQueryOutcome copyWith({
    String? matchId,
    String? outcomeJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GamePlayerQueryOutcome',
      'matchId': matchId,
      'outcomeJson': outcomeJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GamePlayerQueryOutcome',
      'matchId': matchId,
      'outcomeJson': outcomeJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GamePlayerQueryOutcomeImpl extends GamePlayerQueryOutcome {
  _GamePlayerQueryOutcomeImpl({
    required String matchId,
    required String outcomeJson,
  }) : super._(
         matchId: matchId,
         outcomeJson: outcomeJson,
       );

  /// Returns a shallow copy of this [GamePlayerQueryOutcome]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GamePlayerQueryOutcome copyWith({
    String? matchId,
    String? outcomeJson,
  }) {
    return GamePlayerQueryOutcome(
      matchId: matchId ?? this.matchId,
      outcomeJson: outcomeJson ?? this.outcomeJson,
    );
  }
}
