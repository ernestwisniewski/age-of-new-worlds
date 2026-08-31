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

abstract class SteamAuthStart implements _i1.SerializableModel {
  SteamAuthStart._({
    required this.requestId,
    required this.authUrl,
    required this.expiresAt,
  });

  factory SteamAuthStart({
    required String requestId,
    required String authUrl,
    required DateTime expiresAt,
  }) = _SteamAuthStartImpl;

  factory SteamAuthStart.fromJson(Map<String, dynamic> jsonSerialization) {
    return SteamAuthStart(
      requestId: jsonSerialization['requestId'] as String,
      authUrl: jsonSerialization['authUrl'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  String requestId;

  String authUrl;

  DateTime expiresAt;

  /// Returns a shallow copy of this [SteamAuthStart]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SteamAuthStart copyWith({
    String? requestId,
    String? authUrl,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SteamAuthStart',
      'requestId': requestId,
      'authUrl': authUrl,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SteamAuthStartImpl extends SteamAuthStart {
  _SteamAuthStartImpl({
    required String requestId,
    required String authUrl,
    required DateTime expiresAt,
  }) : super._(
         requestId: requestId,
         authUrl: authUrl,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [SteamAuthStart]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SteamAuthStart copyWith({
    String? requestId,
    String? authUrl,
    DateTime? expiresAt,
  }) {
    return SteamAuthStart(
      requestId: requestId ?? this.requestId,
      authUrl: authUrl ?? this.authUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
