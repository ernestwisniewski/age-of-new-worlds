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
import 'auth/models/account_auth_exception.dart' as _i2;
import 'auth/models/external_auth_poll_result.dart' as _i3;
import 'auth/models/external_auth_start.dart' as _i4;
import 'auth/models/steam_auth_poll_result.dart' as _i5;
import 'auth/models/steam_auth_start.dart' as _i6;
import 'game/models/game_command_ledger.dart' as _i7;
import 'game/models/game_command_outcome.dart' as _i8;
import 'game/models/game_create_match_request.dart' as _i9;
import 'game/models/game_event.dart' as _i10;
import 'game/models/game_exception.dart' as _i11;
import 'game/models/game_join_match_request.dart' as _i12;
import 'game/models/game_match.dart' as _i13;
import 'game/models/game_match_view.dart' as _i14;
import 'game/models/game_participant.dart' as _i15;
import 'game/models/game_player_command_request.dart' as _i16;
import 'game/models/game_recipient_snapshot.dart' as _i17;
import 'game/models/game_resync.dart' as _i18;
import 'game/models/game_submit_turn_request.dart' as _i19;
import 'package:aonw_server_client/src/protocol/game/models/game_match_view.dart'
    as _i20;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i21;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i22;
export 'auth/models/account_auth_exception.dart';
export 'auth/models/external_auth_poll_result.dart';
export 'auth/models/external_auth_start.dart';
export 'auth/models/steam_auth_poll_result.dart';
export 'auth/models/steam_auth_start.dart';
export 'game/models/game_command_ledger.dart';
export 'game/models/game_command_outcome.dart';
export 'game/models/game_create_match_request.dart';
export 'game/models/game_event.dart';
export 'game/models/game_exception.dart';
export 'game/models/game_join_match_request.dart';
export 'game/models/game_match.dart';
export 'game/models/game_match_view.dart';
export 'game/models/game_participant.dart';
export 'game/models/game_player_command_request.dart';
export 'game/models/game_recipient_snapshot.dart';
export 'game/models/game_resync.dart';
export 'game/models/game_submit_turn_request.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.AccountAuthException) {
      return _i2.AccountAuthException.fromJson(data) as T;
    }
    if (t == _i3.ExternalAuthPollResult) {
      return _i3.ExternalAuthPollResult.fromJson(data) as T;
    }
    if (t == _i4.ExternalAuthStart) {
      return _i4.ExternalAuthStart.fromJson(data) as T;
    }
    if (t == _i5.SteamAuthPollResult) {
      return _i5.SteamAuthPollResult.fromJson(data) as T;
    }
    if (t == _i6.SteamAuthStart) {
      return _i6.SteamAuthStart.fromJson(data) as T;
    }
    if (t == _i7.GameCommandLedger) {
      return _i7.GameCommandLedger.fromJson(data) as T;
    }
    if (t == _i8.GameCommandOutcome) {
      return _i8.GameCommandOutcome.fromJson(data) as T;
    }
    if (t == _i9.GameCreateMatchRequest) {
      return _i9.GameCreateMatchRequest.fromJson(data) as T;
    }
    if (t == _i10.GameEvent) {
      return _i10.GameEvent.fromJson(data) as T;
    }
    if (t == _i11.GameException) {
      return _i11.GameException.fromJson(data) as T;
    }
    if (t == _i12.GameJoinMatchRequest) {
      return _i12.GameJoinMatchRequest.fromJson(data) as T;
    }
    if (t == _i13.GameMatch) {
      return _i13.GameMatch.fromJson(data) as T;
    }
    if (t == _i14.GameMatchView) {
      return _i14.GameMatchView.fromJson(data) as T;
    }
    if (t == _i15.GameParticipant) {
      return _i15.GameParticipant.fromJson(data) as T;
    }
    if (t == _i16.GamePlayerCommandRequest) {
      return _i16.GamePlayerCommandRequest.fromJson(data) as T;
    }
    if (t == _i17.GameRecipientSnapshot) {
      return _i17.GameRecipientSnapshot.fromJson(data) as T;
    }
    if (t == _i18.GameResync) {
      return _i18.GameResync.fromJson(data) as T;
    }
    if (t == _i19.GameSubmitTurnRequest) {
      return _i19.GameSubmitTurnRequest.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AccountAuthException?>()) {
      return (data != null ? _i2.AccountAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i3.ExternalAuthPollResult?>()) {
      return (data != null ? _i3.ExternalAuthPollResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.ExternalAuthStart?>()) {
      return (data != null ? _i4.ExternalAuthStart.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.SteamAuthPollResult?>()) {
      return (data != null ? _i5.SteamAuthPollResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.SteamAuthStart?>()) {
      return (data != null ? _i6.SteamAuthStart.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.GameCommandLedger?>()) {
      return (data != null ? _i7.GameCommandLedger.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.GameCommandOutcome?>()) {
      return (data != null ? _i8.GameCommandOutcome.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.GameCreateMatchRequest?>()) {
      return (data != null ? _i9.GameCreateMatchRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.GameEvent?>()) {
      return (data != null ? _i10.GameEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.GameException?>()) {
      return (data != null ? _i11.GameException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.GameJoinMatchRequest?>()) {
      return (data != null ? _i12.GameJoinMatchRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.GameMatch?>()) {
      return (data != null ? _i13.GameMatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.GameMatchView?>()) {
      return (data != null ? _i14.GameMatchView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.GameParticipant?>()) {
      return (data != null ? _i15.GameParticipant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.GamePlayerCommandRequest?>()) {
      return (data != null
              ? _i16.GamePlayerCommandRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i17.GameRecipientSnapshot?>()) {
      return (data != null ? _i17.GameRecipientSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.GameResync?>()) {
      return (data != null ? _i18.GameResync.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.GameSubmitTurnRequest?>()) {
      return (data != null ? _i19.GameSubmitTurnRequest.fromJson(data) : null)
          as T;
    }
    if (t == List<_i20.GameMatchView>) {
      return (data as List)
              .map((e) => deserialize<_i20.GameMatchView>(e))
              .toList()
          as T;
    }
    try {
      return _i21.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i22.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AccountAuthException => 'AccountAuthException',
      _i3.ExternalAuthPollResult => 'ExternalAuthPollResult',
      _i4.ExternalAuthStart => 'ExternalAuthStart',
      _i5.SteamAuthPollResult => 'SteamAuthPollResult',
      _i6.SteamAuthStart => 'SteamAuthStart',
      _i7.GameCommandLedger => 'GameCommandLedger',
      _i8.GameCommandOutcome => 'GameCommandOutcome',
      _i9.GameCreateMatchRequest => 'GameCreateMatchRequest',
      _i10.GameEvent => 'GameEvent',
      _i11.GameException => 'GameException',
      _i12.GameJoinMatchRequest => 'GameJoinMatchRequest',
      _i13.GameMatch => 'GameMatch',
      _i14.GameMatchView => 'GameMatchView',
      _i15.GameParticipant => 'GameParticipant',
      _i16.GamePlayerCommandRequest => 'GamePlayerCommandRequest',
      _i17.GameRecipientSnapshot => 'GameRecipientSnapshot',
      _i18.GameResync => 'GameResync',
      _i19.GameSubmitTurnRequest => 'GameSubmitTurnRequest',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('aonw.', '');
    }

    switch (data) {
      case _i2.AccountAuthException():
        return 'AccountAuthException';
      case _i3.ExternalAuthPollResult():
        return 'ExternalAuthPollResult';
      case _i4.ExternalAuthStart():
        return 'ExternalAuthStart';
      case _i5.SteamAuthPollResult():
        return 'SteamAuthPollResult';
      case _i6.SteamAuthStart():
        return 'SteamAuthStart';
      case _i7.GameCommandLedger():
        return 'GameCommandLedger';
      case _i8.GameCommandOutcome():
        return 'GameCommandOutcome';
      case _i9.GameCreateMatchRequest():
        return 'GameCreateMatchRequest';
      case _i10.GameEvent():
        return 'GameEvent';
      case _i11.GameException():
        return 'GameException';
      case _i12.GameJoinMatchRequest():
        return 'GameJoinMatchRequest';
      case _i13.GameMatch():
        return 'GameMatch';
      case _i14.GameMatchView():
        return 'GameMatchView';
      case _i15.GameParticipant():
        return 'GameParticipant';
      case _i16.GamePlayerCommandRequest():
        return 'GamePlayerCommandRequest';
      case _i17.GameRecipientSnapshot():
        return 'GameRecipientSnapshot';
      case _i18.GameResync():
        return 'GameResync';
      case _i19.GameSubmitTurnRequest():
        return 'GameSubmitTurnRequest';
    }
    className = _i21.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i22.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AccountAuthException') {
      return deserialize<_i2.AccountAuthException>(data['data']);
    }
    if (dataClassName == 'ExternalAuthPollResult') {
      return deserialize<_i3.ExternalAuthPollResult>(data['data']);
    }
    if (dataClassName == 'ExternalAuthStart') {
      return deserialize<_i4.ExternalAuthStart>(data['data']);
    }
    if (dataClassName == 'SteamAuthPollResult') {
      return deserialize<_i5.SteamAuthPollResult>(data['data']);
    }
    if (dataClassName == 'SteamAuthStart') {
      return deserialize<_i6.SteamAuthStart>(data['data']);
    }
    if (dataClassName == 'GameCommandLedger') {
      return deserialize<_i7.GameCommandLedger>(data['data']);
    }
    if (dataClassName == 'GameCommandOutcome') {
      return deserialize<_i8.GameCommandOutcome>(data['data']);
    }
    if (dataClassName == 'GameCreateMatchRequest') {
      return deserialize<_i9.GameCreateMatchRequest>(data['data']);
    }
    if (dataClassName == 'GameEvent') {
      return deserialize<_i10.GameEvent>(data['data']);
    }
    if (dataClassName == 'GameException') {
      return deserialize<_i11.GameException>(data['data']);
    }
    if (dataClassName == 'GameJoinMatchRequest') {
      return deserialize<_i12.GameJoinMatchRequest>(data['data']);
    }
    if (dataClassName == 'GameMatch') {
      return deserialize<_i13.GameMatch>(data['data']);
    }
    if (dataClassName == 'GameMatchView') {
      return deserialize<_i14.GameMatchView>(data['data']);
    }
    if (dataClassName == 'GameParticipant') {
      return deserialize<_i15.GameParticipant>(data['data']);
    }
    if (dataClassName == 'GamePlayerCommandRequest') {
      return deserialize<_i16.GamePlayerCommandRequest>(data['data']);
    }
    if (dataClassName == 'GameRecipientSnapshot') {
      return deserialize<_i17.GameRecipientSnapshot>(data['data']);
    }
    if (dataClassName == 'GameResync') {
      return deserialize<_i18.GameResync>(data['data']);
    }
    if (dataClassName == 'GameSubmitTurnRequest') {
      return deserialize<_i19.GameSubmitTurnRequest>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i21.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i22.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i21.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i22.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
