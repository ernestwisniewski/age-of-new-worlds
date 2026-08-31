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

abstract class ExternalAuthStart
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ExternalAuthStart._({
    required this.requestId,
    required this.authUrl,
    required this.expiresAt,
  });

  factory ExternalAuthStart({
    required String requestId,
    required String authUrl,
    required DateTime expiresAt,
  }) = _ExternalAuthStartImpl;

  factory ExternalAuthStart.fromJson(Map<String, dynamic> jsonSerialization) {
    return ExternalAuthStart(
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

  /// Returns a shallow copy of this [ExternalAuthStart]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ExternalAuthStart copyWith({
    String? requestId,
    String? authUrl,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ExternalAuthStart',
      'requestId': requestId,
      'authUrl': authUrl,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ExternalAuthStart',
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

class _ExternalAuthStartImpl extends ExternalAuthStart {
  _ExternalAuthStartImpl({
    required String requestId,
    required String authUrl,
    required DateTime expiresAt,
  }) : super._(
         requestId: requestId,
         authUrl: authUrl,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [ExternalAuthStart]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ExternalAuthStart copyWith({
    String? requestId,
    String? authUrl,
    DateTime? expiresAt,
  }) {
    return ExternalAuthStart(
      requestId: requestId ?? this.requestId,
      authUrl: authUrl ?? this.authUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
