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
import '../../game/models/game_match_view.dart' as _i2;
import '../../game/models/game_lobby_participant_view.dart' as _i3;
import 'package:aonw_server/src/generated/protocol.dart' as _i4;

abstract class GameLobbyView
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GameLobbyView._({
    required this.match,
    required this.participants,
    required this.canStart,
  });

  factory GameLobbyView({
    required _i2.GameMatchView match,
    required List<_i3.GameLobbyParticipantView> participants,
    required bool canStart,
  }) = _GameLobbyViewImpl;

  factory GameLobbyView.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameLobbyView(
      match: _i4.Protocol().deserialize<_i2.GameMatchView>(
        jsonSerialization['match'],
      ),
      participants: _i4.Protocol()
          .deserialize<List<_i3.GameLobbyParticipantView>>(
            jsonSerialization['participants'],
          ),
      canStart: _i1.BoolJsonExtension.fromJson(jsonSerialization['canStart']),
    );
  }

  _i2.GameMatchView match;

  List<_i3.GameLobbyParticipantView> participants;

  bool canStart;

  /// Returns a shallow copy of this [GameLobbyView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameLobbyView copyWith({
    _i2.GameMatchView? match,
    List<_i3.GameLobbyParticipantView>? participants,
    bool? canStart,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameLobbyView',
      'match': match.toJson(),
      'participants': participants.toJson(valueToJson: (v) => v.toJson()),
      'canStart': canStart,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameLobbyView',
      'match': match.toJsonForProtocol(),
      'participants': participants.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'canStart': canStart,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameLobbyViewImpl extends GameLobbyView {
  _GameLobbyViewImpl({
    required _i2.GameMatchView match,
    required List<_i3.GameLobbyParticipantView> participants,
    required bool canStart,
  }) : super._(
         match: match,
         participants: participants,
         canStart: canStart,
       );

  /// Returns a shallow copy of this [GameLobbyView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameLobbyView copyWith({
    _i2.GameMatchView? match,
    List<_i3.GameLobbyParticipantView>? participants,
    bool? canStart,
  }) {
    return GameLobbyView(
      match: match ?? this.match.copyWith(),
      participants:
          participants ?? this.participants.map((e0) => e0.copyWith()).toList(),
      canStart: canStart ?? this.canStart,
    );
  }
}
