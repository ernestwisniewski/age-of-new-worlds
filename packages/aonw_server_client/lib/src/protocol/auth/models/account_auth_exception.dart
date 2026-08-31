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

abstract class AccountAuthException
    implements _i1.SerializableException, _i1.SerializableModel {
  AccountAuthException._({
    required this.code,
    this.message,
  });

  factory AccountAuthException({
    required String code,
    String? message,
  }) = _AccountAuthExceptionImpl;

  factory AccountAuthException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AccountAuthException(
      code: jsonSerialization['code'] as String,
      message: jsonSerialization['message'] as String?,
    );
  }

  String code;

  String? message;

  /// Returns a shallow copy of this [AccountAuthException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AccountAuthException copyWith({
    String? code,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountAuthException',
      'code': code,
      if (message != null) 'message': message,
    };
  }

  @override
  String toString() {
    return 'AccountAuthException(code: $code, message: $message)';
  }
}

class _Undefined {}

class _AccountAuthExceptionImpl extends AccountAuthException {
  _AccountAuthExceptionImpl({
    required String code,
    String? message,
  }) : super._(
         code: code,
         message: message,
       );

  /// Returns a shallow copy of this [AccountAuthException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AccountAuthException copyWith({
    String? code,
    Object? message = _Undefined,
  }) {
    return AccountAuthException(
      code: code ?? this.code,
      message: message is String? ? message : this.message,
    );
  }
}
