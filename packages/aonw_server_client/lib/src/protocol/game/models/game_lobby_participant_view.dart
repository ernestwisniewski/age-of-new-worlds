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

abstract class GameLobbyParticipantView implements _i1.SerializableModel {
  GameLobbyParticipantView._({
    required this.playerId,
    required this.name,
    required this.kind,
    required this.isHost,
    required this.isClaimed,
    required this.isReady,
    required this.isCurrentUser,
  });

  factory GameLobbyParticipantView({
    required String playerId,
    required String name,
    required String kind,
    required bool isHost,
    required bool isClaimed,
    required bool isReady,
    required bool isCurrentUser,
  }) = _GameLobbyParticipantViewImpl;

  factory GameLobbyParticipantView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameLobbyParticipantView(
      playerId: jsonSerialization['playerId'] as String,
      name: jsonSerialization['name'] as String,
      kind: jsonSerialization['kind'] as String,
      isHost: _i1.BoolJsonExtension.fromJson(jsonSerialization['isHost']),
      isClaimed: _i1.BoolJsonExtension.fromJson(jsonSerialization['isClaimed']),
      isReady: _i1.BoolJsonExtension.fromJson(jsonSerialization['isReady']),
      isCurrentUser: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['isCurrentUser'],
      ),
    );
  }

  String playerId;

  String name;

  String kind;

  bool isHost;

  bool isClaimed;

  bool isReady;

  bool isCurrentUser;

  /// Returns a shallow copy of this [GameLobbyParticipantView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameLobbyParticipantView copyWith({
    String? playerId,
    String? name,
    String? kind,
    bool? isHost,
    bool? isClaimed,
    bool? isReady,
    bool? isCurrentUser,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameLobbyParticipantView',
      'playerId': playerId,
      'name': name,
      'kind': kind,
      'isHost': isHost,
      'isClaimed': isClaimed,
      'isReady': isReady,
      'isCurrentUser': isCurrentUser,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GameLobbyParticipantViewImpl extends GameLobbyParticipantView {
  _GameLobbyParticipantViewImpl({
    required String playerId,
    required String name,
    required String kind,
    required bool isHost,
    required bool isClaimed,
    required bool isReady,
    required bool isCurrentUser,
  }) : super._(
         playerId: playerId,
         name: name,
         kind: kind,
         isHost: isHost,
         isClaimed: isClaimed,
         isReady: isReady,
         isCurrentUser: isCurrentUser,
       );

  /// Returns a shallow copy of this [GameLobbyParticipantView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameLobbyParticipantView copyWith({
    String? playerId,
    String? name,
    String? kind,
    bool? isHost,
    bool? isClaimed,
    bool? isReady,
    bool? isCurrentUser,
  }) {
    return GameLobbyParticipantView(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isHost: isHost ?? this.isHost,
      isClaimed: isClaimed ?? this.isClaimed,
      isReady: isReady ?? this.isReady,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
