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
import '../../game/models/game_match_history_entry.dart' as _i2;
import 'package:aonw_server/src/generated/protocol.dart' as _i3;

abstract class GameMatchHistoryPage
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GameMatchHistoryPage._({
    required this.entries,
    this.nextBeforeParticipantId,
  });

  factory GameMatchHistoryPage({
    required List<_i2.GameMatchHistoryEntry> entries,
    int? nextBeforeParticipantId,
  }) = _GameMatchHistoryPageImpl;

  factory GameMatchHistoryPage.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameMatchHistoryPage(
      entries: _i3.Protocol().deserialize<List<_i2.GameMatchHistoryEntry>>(
        jsonSerialization['entries'],
      ),
      nextBeforeParticipantId:
          jsonSerialization['nextBeforeParticipantId'] as int?,
    );
  }

  List<_i2.GameMatchHistoryEntry> entries;

  int? nextBeforeParticipantId;

  /// Returns a shallow copy of this [GameMatchHistoryPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameMatchHistoryPage copyWith({
    List<_i2.GameMatchHistoryEntry>? entries,
    int? nextBeforeParticipantId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameMatchHistoryPage',
      'entries': entries.toJson(valueToJson: (v) => v.toJson()),
      if (nextBeforeParticipantId != null)
        'nextBeforeParticipantId': nextBeforeParticipantId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameMatchHistoryPage',
      'entries': entries.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (nextBeforeParticipantId != null)
        'nextBeforeParticipantId': nextBeforeParticipantId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameMatchHistoryPageImpl extends GameMatchHistoryPage {
  _GameMatchHistoryPageImpl({
    required List<_i2.GameMatchHistoryEntry> entries,
    int? nextBeforeParticipantId,
  }) : super._(
         entries: entries,
         nextBeforeParticipantId: nextBeforeParticipantId,
       );

  /// Returns a shallow copy of this [GameMatchHistoryPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameMatchHistoryPage copyWith({
    List<_i2.GameMatchHistoryEntry>? entries,
    Object? nextBeforeParticipantId = _Undefined,
  }) {
    return GameMatchHistoryPage(
      entries: entries ?? this.entries.map((e0) => e0.copyWith()).toList(),
      nextBeforeParticipantId: nextBeforeParticipantId is int?
          ? nextBeforeParticipantId
          : this.nextBeforeParticipantId,
    );
  }
}
