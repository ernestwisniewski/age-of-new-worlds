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

abstract class GameCommandOutcome implements _i1.SerializableModel {
  GameCommandOutcome._({
    required this.matchId,
    required this.clientCommandId,
    required this.initialEventOffset,
    required this.finalEventOffset,
    required this.duplicate,
    required this.outcomeJson,
  });

  factory GameCommandOutcome({
    required String matchId,
    required String clientCommandId,
    required int initialEventOffset,
    required int finalEventOffset,
    required bool duplicate,
    required String outcomeJson,
  }) = _GameCommandOutcomeImpl;

  factory GameCommandOutcome.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameCommandOutcome(
      matchId: jsonSerialization['matchId'] as String,
      clientCommandId: jsonSerialization['clientCommandId'] as String,
      initialEventOffset: jsonSerialization['initialEventOffset'] as int,
      finalEventOffset: jsonSerialization['finalEventOffset'] as int,
      duplicate: _i1.BoolJsonExtension.fromJson(jsonSerialization['duplicate']),
      outcomeJson: jsonSerialization['outcomeJson'] as String,
    );
  }

  String matchId;

  String clientCommandId;

  int initialEventOffset;

  int finalEventOffset;

  bool duplicate;

  String outcomeJson;

  /// Returns a shallow copy of this [GameCommandOutcome]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameCommandOutcome copyWith({
    String? matchId,
    String? clientCommandId,
    int? initialEventOffset,
    int? finalEventOffset,
    bool? duplicate,
    String? outcomeJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameCommandOutcome',
      'matchId': matchId,
      'clientCommandId': clientCommandId,
      'initialEventOffset': initialEventOffset,
      'finalEventOffset': finalEventOffset,
      'duplicate': duplicate,
      'outcomeJson': outcomeJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameCommandOutcomeImpl extends GameCommandOutcome {
  _GameCommandOutcomeImpl({
    required String matchId,
    required String clientCommandId,
    required int initialEventOffset,
    required int finalEventOffset,
    required bool duplicate,
    required String outcomeJson,
  }) : super._(
         matchId: matchId,
         clientCommandId: clientCommandId,
         initialEventOffset: initialEventOffset,
         finalEventOffset: finalEventOffset,
         duplicate: duplicate,
         outcomeJson: outcomeJson,
       );

  /// Returns a shallow copy of this [GameCommandOutcome]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameCommandOutcome copyWith({
    String? matchId,
    String? clientCommandId,
    int? initialEventOffset,
    int? finalEventOffset,
    bool? duplicate,
    String? outcomeJson,
  }) {
    return GameCommandOutcome(
      matchId: matchId ?? this.matchId,
      clientCommandId: clientCommandId ?? this.clientCommandId,
      initialEventOffset: initialEventOffset ?? this.initialEventOffset,
      finalEventOffset: finalEventOffset ?? this.finalEventOffset,
      duplicate: duplicate ?? this.duplicate,
      outcomeJson: outcomeJson ?? this.outcomeJson,
    );
  }
}
