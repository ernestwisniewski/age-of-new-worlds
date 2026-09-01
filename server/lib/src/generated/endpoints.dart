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
import '../app_status/app_status_endpoint.dart' as _i2;
import '../auth/account_profile_endpoint.dart' as _i3;
import '../auth/apple_idp_endpoint.dart' as _i4;
import '../auth/auth_status_endpoint.dart' as _i5;
import '../auth/email_idp_endpoint.dart' as _i6;
import '../auth/external_auth_endpoint.dart' as _i7;
import '../auth/google_idp_endpoint.dart' as _i8;
import '../auth/jwt_refresh_endpoint.dart' as _i9;
import '../auth/steam_auth_endpoint.dart' as _i10;
import '../game/game_endpoint.dart' as _i11;
import 'package:aonw_server/src/generated/game/models/game_create_match_request.dart'
    as _i12;
import 'package:aonw_server/src/generated/game/models/game_join_match_request.dart'
    as _i13;
import 'package:aonw_server/src/generated/game/models/game_submit_turn_request.dart'
    as _i14;
import 'package:aonw_server/src/generated/game/models/game_player_command_request.dart'
    as _i15;
import 'package:aonw_server/src/generated/game/models/game_player_query_request.dart'
    as _i16;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i17;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i18;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'appStatus': _i2.AppStatusEndpoint()
        ..initialize(
          server,
          'appStatus',
          null,
        ),
      'accountProfile': _i3.AccountProfileEndpoint()
        ..initialize(
          server,
          'accountProfile',
          null,
        ),
      'appleIdp': _i4.AppleIdpEndpoint()
        ..initialize(
          server,
          'appleIdp',
          null,
        ),
      'authStatus': _i5.AuthStatusEndpoint()
        ..initialize(
          server,
          'authStatus',
          null,
        ),
      'emailIdp': _i6.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'externalAuth': _i7.ExternalAuthEndpoint()
        ..initialize(
          server,
          'externalAuth',
          null,
        ),
      'googleIdp': _i8.GoogleIdpEndpoint()
        ..initialize(
          server,
          'googleIdp',
          null,
        ),
      'jwtRefresh': _i9.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'steamAuth': _i10.SteamAuthEndpoint()
        ..initialize(
          server,
          'steamAuth',
          null,
        ),
      'game': _i11.GameEndpoint()
        ..initialize(
          server,
          'game',
          null,
        ),
    };
    connectors['appStatus'] = _i1.EndpointConnector(
      name: 'appStatus',
      endpoint: endpoints['appStatus']!,
      methodConnectors: {
        'versionStatus': _i1.MethodConnector(
          name: 'versionStatus',
          params: {
            'platform': _i1.ParameterDescription(
              name: 'platform',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'buildNumber': _i1.ParameterDescription(
              name: 'buildNumber',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['appStatus'] as _i2.AppStatusEndpoint)
                  .versionStatus(
                    session,
                    platform: params['platform'],
                    buildNumber: params['buildNumber'],
                  ),
        ),
      },
    );
    connectors['accountProfile'] = _i1.EndpointConnector(
      name: 'accountProfile',
      endpoint: endpoints['accountProfile']!,
      methodConnectors: {
        'ensureAccount': _i1.MethodConnector(
          name: 'ensureAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['accountProfile'] as _i3.AccountProfileEndpoint)
                      .ensureAccount(session),
        ),
      },
    );
    connectors['appleIdp'] = _i1.EndpointConnector(
      name: 'appleIdp',
      endpoint: endpoints['appleIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'identityToken': _i1.ParameterDescription(
              name: 'identityToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'authorizationCode': _i1.ParameterDescription(
              name: 'authorizationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'isNativeApplePlatformSignIn': _i1.ParameterDescription(
              name: 'isNativeApplePlatformSignIn',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'firstName': _i1.ParameterDescription(
              name: 'firstName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'lastName': _i1.ParameterDescription(
              name: 'lastName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['appleIdp'] as _i4.AppleIdpEndpoint).login(
                session,
                identityToken: params['identityToken'],
                authorizationCode: params['authorizationCode'],
                isNativeApplePlatformSignIn:
                    params['isNativeApplePlatformSignIn'],
                firstName: params['firstName'],
                lastName: params['lastName'],
              ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['appleIdp'] as _i4.AppleIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['authStatus'] = _i1.EndpointConnector(
      name: 'authStatus',
      endpoint: endpoints['authStatus']!,
      methodConnectors: {
        'signOutRefreshToken': _i1.MethodConnector(
          name: 'signOutRefreshToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['authStatus'] as _i5.AuthStatusEndpoint)
                  .signOutRefreshToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i6.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'createAccount': _i1.MethodConnector(
          name: 'createAccount',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _i6.EmailIdpEndpoint).createAccount(
                    session,
                    email: params['email'],
                    password: params['password'],
                    displayName: params['displayName'],
                  ),
        ),
        'displayName': _i1.MethodConnector(
          name: 'displayName',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i6.EmailIdpEndpoint)
                  .displayName(session),
        ),
        'updateDisplayName': _i1.MethodConnector(
          name: 'updateDisplayName',
          params: {
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i6.EmailIdpEndpoint)
                  .updateDisplayName(
                    session,
                    displayName: params['displayName'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i6.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['externalAuth'] = _i1.EndpointConnector(
      name: 'externalAuth',
      endpoint: endpoints['externalAuth']!,
      methodConnectors: {
        'start': _i1.MethodConnector(
          name: 'start',
          params: {
            'provider': _i1.ParameterDescription(
              name: 'provider',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['externalAuth'] as _i7.ExternalAuthEndpoint).start(
                    session,
                    provider: params['provider'],
                  ),
        ),
        'poll': _i1.MethodConnector(
          name: 'poll',
          params: {
            'requestId': _i1.ParameterDescription(
              name: 'requestId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['externalAuth'] as _i7.ExternalAuthEndpoint).poll(
                    session,
                    requestId: params['requestId'],
                  ),
        ),
      },
    );
    connectors['googleIdp'] = _i1.EndpointConnector(
      name: 'googleIdp',
      endpoint: endpoints['googleIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'idToken': _i1.ParameterDescription(
              name: 'idToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['googleIdp'] as _i8.GoogleIdpEndpoint).login(
                    session,
                    idToken: params['idToken'],
                    accessToken: params['accessToken'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['googleIdp'] as _i8.GoogleIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i9.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['steamAuth'] = _i1.EndpointConnector(
      name: 'steamAuth',
      endpoint: endpoints['steamAuth']!,
      methodConnectors: {
        'start': _i1.MethodConnector(
          name: 'start',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['steamAuth'] as _i10.SteamAuthEndpoint)
                  .start(session),
        ),
        'poll': _i1.MethodConnector(
          name: 'poll',
          params: {
            'requestId': _i1.ParameterDescription(
              name: 'requestId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['steamAuth'] as _i10.SteamAuthEndpoint).poll(
                    session,
                    requestId: params['requestId'],
                  ),
        ),
      },
    );
    connectors['game'] = _i1.EndpointConnector(
      name: 'game',
      endpoint: endpoints['game']!,
      methodConnectors: {
        'createMatch': _i1.MethodConnector(
          name: 'createMatch',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i12.GameCreateMatchRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).createMatch(
                session,
                params['request'],
              ),
        ),
        'joinMatch': _i1.MethodConnector(
          name: 'joinMatch',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i13.GameJoinMatchRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).joinMatch(
                session,
                params['request'],
              ),
        ),
        'listMatches': _i1.MethodConnector(
          name: 'listMatches',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['game'] as _i11.GameEndpoint).listMatches(session),
        ),
        'lobby': _i1.MethodConnector(
          name: 'lobby',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).lobby(
                session,
                params['matchId'],
              ),
        ),
        'setReady': _i1.MethodConnector(
          name: 'setReady',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'ready': _i1.ParameterDescription(
              name: 'ready',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).setReady(
                session,
                params['matchId'],
                params['ready'],
              ),
        ),
        'startMatch': _i1.MethodConnector(
          name: 'startMatch',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).startMatch(
                session,
                params['matchId'],
              ),
        ),
        'submitTurn': _i1.MethodConnector(
          name: 'submitTurn',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i14.GameSubmitTurnRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).submitTurn(
                session,
                params['request'],
              ),
        ),
        'applyCommand': _i1.MethodConnector(
          name: 'applyCommand',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i15.GamePlayerCommandRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).applyCommand(
                session,
                params['request'],
              ),
        ),
        'query': _i1.MethodConnector(
          name: 'query',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i16.GamePlayerQueryRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).query(
                session,
                params['request'],
              ),
        ),
        'resync': _i1.MethodConnector(
          name: 'resync',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _i11.GameEndpoint).resync(
                session,
                params['matchId'],
              ),
        ),
      },
    );
    modules['serverpod_auth_core'] = _i17.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_idp'] = _i18.Endpoints()
      ..initializeEndpoints(server);
  }
}
