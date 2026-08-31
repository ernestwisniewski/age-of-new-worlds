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
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i2;
import 'package:aonw_server/src/generated/protocol.dart' as _i3;

abstract class SteamAuthPollResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SteamAuthPollResult._({
    required this.status,
    this.auth,
    this.error,
  });

  factory SteamAuthPollResult({
    required String status,
    _i2.AuthSuccess? auth,
    String? error,
  }) = _SteamAuthPollResultImpl;

  factory SteamAuthPollResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return SteamAuthPollResult(
      status: jsonSerialization['status'] as String,
      auth: jsonSerialization['auth'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AuthSuccess>(
              jsonSerialization['auth'],
            ),
      error: jsonSerialization['error'] as String?,
    );
  }

  String status;

  _i2.AuthSuccess? auth;

  String? error;

  /// Returns a shallow copy of this [SteamAuthPollResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SteamAuthPollResult copyWith({
    String? status,
    _i2.AuthSuccess? auth,
    String? error,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SteamAuthPollResult',
      'status': status,
      if (auth != null) 'auth': auth?.toJson(),
      if (error != null) 'error': error,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SteamAuthPollResult',
      'status': status,
      if (auth != null) 'auth': auth?.toJsonForProtocol(),
      if (error != null) 'error': error,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SteamAuthPollResultImpl extends SteamAuthPollResult {
  _SteamAuthPollResultImpl({
    required String status,
    _i2.AuthSuccess? auth,
    String? error,
  }) : super._(
         status: status,
         auth: auth,
         error: error,
       );

  /// Returns a shallow copy of this [SteamAuthPollResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SteamAuthPollResult copyWith({
    String? status,
    Object? auth = _Undefined,
    Object? error = _Undefined,
  }) {
    return SteamAuthPollResult(
      status: status ?? this.status,
      auth: auth is _i2.AuthSuccess? ? auth : this.auth?.copyWith(),
      error: error is String? ? error : this.error,
    );
  }
}
