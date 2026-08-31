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

abstract class GameMatchView
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GameMatchView._({
    required this.matchId,
    required this.mapId,
    required this.mapHash,
    required this.rulesetId,
    required this.rulesetHash,
    required this.revision,
    required this.eventOffset,
  });

  factory GameMatchView({
    required String matchId,
    required String mapId,
    required String mapHash,
    required String rulesetId,
    required String rulesetHash,
    required int revision,
    required int eventOffset,
  }) = _GameMatchViewImpl;

  factory GameMatchView.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameMatchView(
      matchId: jsonSerialization['matchId'] as String,
      mapId: jsonSerialization['mapId'] as String,
      mapHash: jsonSerialization['mapHash'] as String,
      rulesetId: jsonSerialization['rulesetId'] as String,
      rulesetHash: jsonSerialization['rulesetHash'] as String,
      revision: jsonSerialization['revision'] as int,
      eventOffset: jsonSerialization['eventOffset'] as int,
    );
  }

  String matchId;

  String mapId;

  String mapHash;

  String rulesetId;

  String rulesetHash;

  int revision;

  int eventOffset;

  /// Returns a shallow copy of this [GameMatchView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameMatchView copyWith({
    String? matchId,
    String? mapId,
    String? mapHash,
    String? rulesetId,
    String? rulesetHash,
    int? revision,
    int? eventOffset,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameMatchView',
      'matchId': matchId,
      'mapId': mapId,
      'mapHash': mapHash,
      'rulesetId': rulesetId,
      'rulesetHash': rulesetHash,
      'revision': revision,
      'eventOffset': eventOffset,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameMatchView',
      'matchId': matchId,
      'mapId': mapId,
      'mapHash': mapHash,
      'rulesetId': rulesetId,
      'rulesetHash': rulesetHash,
      'revision': revision,
      'eventOffset': eventOffset,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameMatchViewImpl extends GameMatchView {
  _GameMatchViewImpl({
    required String matchId,
    required String mapId,
    required String mapHash,
    required String rulesetId,
    required String rulesetHash,
    required int revision,
    required int eventOffset,
  }) : super._(
         matchId: matchId,
         mapId: mapId,
         mapHash: mapHash,
         rulesetId: rulesetId,
         rulesetHash: rulesetHash,
         revision: revision,
         eventOffset: eventOffset,
       );

  /// Returns a shallow copy of this [GameMatchView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameMatchView copyWith({
    String? matchId,
    String? mapId,
    String? mapHash,
    String? rulesetId,
    String? rulesetHash,
    int? revision,
    int? eventOffset,
  }) {
    return GameMatchView(
      matchId: matchId ?? this.matchId,
      mapId: mapId ?? this.mapId,
      mapHash: mapHash ?? this.mapHash,
      rulesetId: rulesetId ?? this.rulesetId,
      rulesetHash: rulesetHash ?? this.rulesetHash,
      revision: revision ?? this.revision,
      eventOffset: eventOffset ?? this.eventOffset,
    );
  }
}
