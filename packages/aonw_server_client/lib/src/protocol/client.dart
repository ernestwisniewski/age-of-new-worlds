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
import 'dart:async' as _i2;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:aonw_server_client/src/protocol/auth/models/external_auth_start.dart'
    as _i5;
import 'package:aonw_server_client/src/protocol/auth/models/external_auth_poll_result.dart'
    as _i6;
import 'package:aonw_server_client/src/protocol/auth/models/steam_auth_start.dart'
    as _i7;
import 'package:aonw_server_client/src/protocol/auth/models/steam_auth_poll_result.dart'
    as _i8;
import 'package:aonw_server_client/src/protocol/game/models/game_match_view.dart'
    as _i9;
import 'package:aonw_server_client/src/protocol/game/models/game_create_match_request.dart'
    as _i10;
import 'package:aonw_server_client/src/protocol/game/models/game_resync.dart'
    as _i11;
import 'package:aonw_server_client/src/protocol/game/models/game_join_match_request.dart'
    as _i12;
import 'package:aonw_server_client/src/protocol/game/models/game_command_outcome.dart'
    as _i13;
import 'package:aonw_server_client/src/protocol/game/models/game_submit_turn_request.dart'
    as _i14;
import 'protocol.dart' as _i15;

/// {@category Endpoint}
class EndpointAppStatus extends _i1.EndpointRef {
  EndpointAppStatus(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'appStatus';

  _i2.Future<String> versionStatus({
    required String platform,
    required int buildNumber,
  }) => caller.callServerEndpoint<String>(
    'appStatus',
    'versionStatus',
    {
      'platform': platform,
      'buildNumber': buildNumber,
    },
    authenticated: false,
  );
}

/// Keeps the game account table in sync with Serverpod Auth users.
/// {@category Endpoint}
class EndpointAccountProfile extends _i1.EndpointRef {
  EndpointAccountProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'accountProfile';

  _i2.Future<String> ensureAccount() => caller.callServerEndpoint<String>(
    'accountProfile',
    'ensureAccount',
    {},
  );
}

/// Apple account endpoint backed by Serverpod Auth IDP.
/// {@category Endpoint}
class EndpointAppleIdp extends _i3.EndpointAppleIdpBase {
  EndpointAppleIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'appleIdp';

  /// Signs in a user with their Apple account.
  ///
  /// If no user exists yet linked to the Apple-provided identifier, a new one
  /// will be created (without any `Scope`s). Further their provided name and
  /// email (if any) will be used for the `UserProfile` which will be linked to
  /// their `AuthUser`.
  ///
  /// Returns a session for the user upon successful login.
  @override
  _i2.Future<_i4.AuthSuccess> login({
    required String identityToken,
    required String authorizationCode,
    required bool isNativeApplePlatformSignIn,
    String? firstName,
    String? lastName,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'appleIdp',
    'login',
    {
      'identityToken': identityToken,
      'authorizationCode': authorizationCode,
      'isNativeApplePlatformSignIn': isNativeApplePlatformSignIn,
      'firstName': firstName,
      'lastName': lastName,
    },
  );

  @override
  _i2.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'appleIdp',
    'hasAccount',
    {},
  );
}

/// Manages the lifecycle of authenticated sessions.
///
/// Serverpod Auth already exposes access-token based sign-out through its
/// status endpoint. This endpoint covers clients that only have a persisted
/// refresh token, or whose short-lived access token expired.
/// {@category Endpoint}
class EndpointAuthStatus extends _i1.EndpointRef {
  EndpointAuthStatus(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'authStatus';

  /// Revokes the session represented by [refreshToken].
  ///
  /// Rotating the token first proves possession of its complete secret. Merely
  /// decoding its public id and deleting that row would allow anyone holding an
  /// old access token to sign another device out.
  _i2.Future<void> signOutRefreshToken({required String refreshToken}) =>
      caller.callServerEndpoint<void>(
        'authStatus',
        'signOutRefreshToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// Email/password account endpoint backed by Serverpod Auth Core.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointRef {
  EndpointEmailIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  _i2.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
    authenticated: false,
  );

  _i2.Future<_i4.AuthSuccess> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'createAccount',
    {
      'email': email,
      'password': password,
      'displayName': displayName,
    },
    authenticated: false,
  );

  _i2.Future<String> displayName() => caller.callServerEndpoint<String>(
    'emailIdp',
    'displayName',
    {},
  );

  _i2.Future<String> updateDisplayName({required String displayName}) =>
      caller.callServerEndpoint<String>(
        'emailIdp',
        'updateDisplayName',
        {'displayName': displayName},
      );

  _i2.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// {@category Endpoint}
class EndpointExternalAuth extends _i1.EndpointRef {
  EndpointExternalAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'externalAuth';

  _i2.Future<_i5.ExternalAuthStart> start({required String provider}) =>
      caller.callServerEndpoint<_i5.ExternalAuthStart>(
        'externalAuth',
        'start',
        {'provider': provider},
        authenticated: false,
      );

  _i2.Future<_i6.ExternalAuthPollResult> poll({required String requestId}) =>
      caller.callServerEndpoint<_i6.ExternalAuthPollResult>(
        'externalAuth',
        'poll',
        {'requestId': requestId},
        authenticated: false,
      );
}

/// Google account endpoint backed by Serverpod Auth IDP.
/// {@category Endpoint}
class EndpointGoogleIdp extends _i3.EndpointGoogleIdpBase {
  EndpointGoogleIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'googleIdp';

  /// Validates a Google ID token and either logs in the associated user or
  /// creates a new user account if the Google account ID is not yet known.
  ///
  /// If a new user is created an associated [UserProfile] is also created.
  @override
  _i2.Future<_i4.AuthSuccess> login({
    required String idToken,
    required String? accessToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'googleIdp',
    'login',
    {
      'idToken': idToken,
      'accessToken': accessToken,
    },
  );

  @override
  _i2.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'googleIdp',
    'hasAccount',
    {},
  );
}

/// JWT refresh endpoint used by Serverpod auth clients.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  @override
  _i2.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// {@category Endpoint}
class EndpointSteamAuth extends _i1.EndpointRef {
  EndpointSteamAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'steamAuth';

  _i2.Future<_i7.SteamAuthStart> start() =>
      caller.callServerEndpoint<_i7.SteamAuthStart>(
        'steamAuth',
        'start',
        {},
        authenticated: false,
      );

  _i2.Future<_i8.SteamAuthPollResult> poll({required String requestId}) =>
      caller.callServerEndpoint<_i8.SteamAuthPollResult>(
        'steamAuth',
        'poll',
        {'requestId': requestId},
        authenticated: false,
      );
}

/// Authenticated endpoint for Rust-authoritative multiplayer.
/// {@category Endpoint}
class EndpointGame extends _i1.EndpointRef {
  EndpointGame(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'game';

  _i2.Future<_i9.GameMatchView> createMatch(
    _i10.GameCreateMatchRequest request,
  ) => caller.callServerEndpoint<_i9.GameMatchView>(
    'game',
    'createMatch',
    {'request': request},
  );

  _i2.Future<_i11.GameResync> joinMatch(_i12.GameJoinMatchRequest request) =>
      caller.callServerEndpoint<_i11.GameResync>(
        'game',
        'joinMatch',
        {'request': request},
      );

  _i2.Future<List<_i9.GameMatchView>> listMatches() =>
      caller.callServerEndpoint<List<_i9.GameMatchView>>(
        'game',
        'listMatches',
        {},
      );

  _i2.Future<_i13.GameCommandOutcome> submitTurn(
    _i14.GameSubmitTurnRequest request,
  ) => caller.callServerEndpoint<_i13.GameCommandOutcome>(
    'game',
    'submitTurn',
    {'request': request},
  );

  _i2.Future<_i11.GameResync> resync(String matchId) =>
      caller.callServerEndpoint<_i11.GameResync>(
        'game',
        'resync',
        {'matchId': matchId},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_core = _i4.Caller(client);
    serverpod_auth_idp = _i3.Caller(client);
  }

  late final _i4.Caller serverpod_auth_core;

  late final _i3.Caller serverpod_auth_idp;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i15.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    appStatus = EndpointAppStatus(this);
    accountProfile = EndpointAccountProfile(this);
    appleIdp = EndpointAppleIdp(this);
    authStatus = EndpointAuthStatus(this);
    emailIdp = EndpointEmailIdp(this);
    externalAuth = EndpointExternalAuth(this);
    googleIdp = EndpointGoogleIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    steamAuth = EndpointSteamAuth(this);
    game = EndpointGame(this);
    modules = Modules(this);
  }

  late final EndpointAppStatus appStatus;

  late final EndpointAccountProfile accountProfile;

  late final EndpointAppleIdp appleIdp;

  late final EndpointAuthStatus authStatus;

  late final EndpointEmailIdp emailIdp;

  late final EndpointExternalAuth externalAuth;

  late final EndpointGoogleIdp googleIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointSteamAuth steamAuth;

  late final EndpointGame game;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'appStatus': appStatus,
    'accountProfile': accountProfile,
    'appleIdp': appleIdp,
    'authStatus': authStatus,
    'emailIdp': emailIdp,
    'externalAuth': externalAuth,
    'googleIdp': googleIdp,
    'jwtRefresh': jwtRefresh,
    'steamAuth': steamAuth,
    'game': game,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_core': modules.serverpod_auth_core,
    'serverpod_auth_idp': modules.serverpod_auth_idp,
  };
}
