import 'dart:async';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as auth;

import '../application/multiplayer_session_port.dart';
import '../read_model/multiplayer_view.dart';
import 'auth_token_store.dart';
import 'server_connection_config.dart';
import 'server_projection_decoder.dart';
import 'serverpod_game_transport.dart';

final class ServerpodMultiplayerSession implements MultiplayerSessionPort {
  ServerpodMultiplayerSession({
    required ServerConnectionConfig config,
    required AuthTokenStore tokenStore,
    ServerProjectionDecoder decoder = const ServerProjectionDecoder(),
  }) : _config = config,
       _tokenStore = tokenStore,
       _decoder = decoder,
       _client = server.Client(
         config.host,
         connectionTimeout: config.requestTimeout,
       ) {
    _client.authKeyProvider = _authProvider;
  }

  final ServerConnectionConfig _config;
  final AuthTokenStore _tokenStore;
  final ServerProjectionDecoder _decoder;
  final server.Client _client;
  final _MutableAuthProvider _authProvider = _MutableAuthProvider();
  String? _refreshToken;
  String? _userId;
  var _serverVerified = false;
  var _closed = false;

  @override
  Future<MultiplayerAccountView?> restoreAccount() async {
    _ensureOpen();
    await _verifyServer();
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      return _accountView(await _rotate(refreshToken));
    } on server.ServerpodClientUnauthorized {
      await _clearCredentials();
      return null;
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  @override
  Future<MultiplayerAccountView> signIn({
    required String email,
    required String password,
  }) async {
    _ensureOpen();
    await _verifyServer();
    try {
      return _installAuthentication(
        await _client.emailIdp.login(email: email, password: password),
      );
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  @override
  Future<MultiplayerAccountView> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _ensureOpen();
    await _verifyServer();
    try {
      await _client.emailIdp.createAccount(
        email: email,
        password: password,
        displayName: displayName,
      );
      return _installAuthentication(
        await _client.emailIdp.login(email: email, password: password),
      );
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    _ensureOpen();
    final refreshToken = _refreshToken;
    try {
      if (refreshToken != null) {
        await _client.authStatus.signOutRefreshToken(
          refreshToken: refreshToken,
        );
      }
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    } finally {
      await _clearCredentials();
    }
  }

  @override
  Future<void> reconnect() async {
    _ensureOpen();
    final refreshToken = _refreshToken ?? await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const MultiplayerSessionException(
        code: 'authentication_required',
        message: 'The authenticated session is unavailable.',
      );
    }
    try {
      await _rotate(refreshToken);
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  @override
  Future<List<MultiplayerMatchView>> listMatches() async {
    _ensureAuthenticated();
    try {
      final matches = await _client.game.listMatches();
      return [for (final match in matches) _match(match)];
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  @override
  Future<MultiplayerProjectionView> createMatch(
    MultiplayerMatchDocuments documents,
  ) async {
    _ensureAuthenticated();
    try {
      final created = await _client.game.createMatch(
        server.GameCreateMatchRequest(
          mapId: documents.mapId,
          mapDocument: documents.mapDocument,
          scenarioDocument: documents.scenarioDocument,
          rulesetId: documents.rulesetId,
          matchIdentityJson: documents.matchIdentityDocument,
          fogEnabled: documents.fogEnabled,
          creatorPlayerId: documents.creatorPlayerId,
        ),
      );
      final projection = _decoder.resync(
        await _client.game.resync(created.matchId),
      );
      if (projection.revision != created.revision ||
          projection.eventOffset != created.eventOffset ||
          projection.playerId != documents.creatorPlayerId) {
        throw const FormatException(
          'Created match and initial projection do not agree.',
        );
      }
      return projection;
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  @override
  Future<MultiplayerProjectionView> joinMatch({
    required String matchId,
    required String playerId,
  }) async {
    _ensureAuthenticated();
    try {
      return _decoder.resync(
        await _client.game.joinMatch(
          server.GameJoinMatchRequest(matchId: matchId, playerId: playerId),
        ),
      );
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  @override
  Future<MultiplayerProjectionView> resync(String matchId) async {
    _ensureAuthenticated();
    try {
      return _decoder.resync(await _client.game.resync(matchId));
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  @override
  Future<MultiplayerCommandView> submitTurn({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  }) async {
    _ensureAuthenticated();
    try {
      return _decoder.command(
        await _client.game.applyCommand(
          server.GamePlayerCommandRequest(
            matchId: matchId,
            clientCommandId: clientCommandId,
            commandJson: AonwClientRequest.endTurn(
              expectedRevision: expectedRevision,
            ).toPlayerCommandJson(),
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  ServerpodGameTransport openGameTransport(
    String matchId, {
    void Function()? onReconnecting,
    void Function()? onRecovered,
    ServerpodGameRecoveryFailure? onRecoveryFailed,
  }) {
    _ensureAuthenticated();
    return ServerpodGameTransport(
      matchId: matchId,
      resync: (value) => _gameRequest(() => _client.game.resync(value)),
      query: (value) => _gameRequest(() => _client.game.query(value)),
      command: (value) => _gameRequest(() => _client.game.applyCommand(value)),
      reconnect: reconnect,
      onReconnecting: onReconnecting,
      onRecovered: onRecovered,
      onRecoveryFailed: onRecoveryFailed,
      decoder: _decoder,
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _authProvider.token = null;
    _client.close();
  }

  Future<void> _verifyServer() async {
    if (_serverVerified) return;
    try {
      final status = await _client.appStatus.versionStatus(
        platform: _config.platform,
        buildNumber: _config.buildNumber,
      );
      if (status != 'current') {
        throw const MultiplayerSessionException(
          code: 'client_update_required',
          message: 'This client build is not accepted by the server.',
        );
      }
      _serverVerified = true;
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  Future<MultiplayerAccountView> _installAuthentication(
    auth.AuthSuccess value,
  ) async {
    final refreshToken = value.refreshToken;
    if (value.token.isEmpty || refreshToken == null || refreshToken.isEmpty) {
      throw const MultiplayerSessionException(
        code: 'invalid_authentication_response',
        message: 'The server returned incomplete authentication credentials.',
      );
    }
    final userId = value.authUserId.toString();
    if (userId.isEmpty) {
      throw const MultiplayerSessionException(
        code: 'invalid_authentication_response',
        message: 'The server returned an empty account identifier.',
      );
    }
    await _tokenStore.writeRefreshToken(refreshToken);
    _authProvider.token = value.token;
    _refreshToken = refreshToken;
    _userId = userId;
    return MultiplayerAccountView(userId: userId);
  }

  Future<auth.AuthSuccess> _rotate(String refreshToken) async {
    final previousUserId = _userId;
    final next = await _client.jwtRefresh.refreshAccessToken(
      refreshToken: refreshToken,
    );
    final account = await _installAuthentication(next);
    if (previousUserId != null && previousUserId != account.userId) {
      await _clearCredentials();
      throw const MultiplayerSessionException(
        code: 'authentication_identity_changed',
        message: 'The refreshed session changed account identity.',
      );
    }
    return next;
  }

  Future<T> _gameRequest<T>(Future<T> Function() operation) async {
    _ensureAuthenticated();
    try {
      return await operation();
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }

  MultiplayerAccountView _accountView(auth.AuthSuccess value) {
    final userId = value.authUserId.toString();
    if (userId.isEmpty || userId != _userId) {
      throw const MultiplayerSessionException(
        code: 'invalid_authentication_response',
        message: 'The restored account identity is invalid.',
      );
    }
    return MultiplayerAccountView(userId: userId);
  }

  Future<void> _clearCredentials() async {
    _authProvider.token = null;
    _refreshToken = null;
    _userId = null;
    await _tokenStore.clear();
  }

  void _ensureOpen() {
    if (_closed) {
      throw const MultiplayerSessionException(
        code: 'session_closed',
        message: 'The multiplayer session is closed.',
      );
    }
  }

  void _ensureAuthenticated() {
    _ensureOpen();
    if (_authProvider.token == null || _refreshToken == null) {
      throw const MultiplayerSessionException(
        code: 'authentication_required',
        message: 'Authentication is required.',
      );
    }
  }
}

final class _MutableAuthProvider implements server.ClientAuthKeyProvider {
  String? token;

  @override
  Future<String?> get authHeaderValue async {
    final value = token;
    return value == null ? null : server.wrapAsBearerAuthHeaderValue(value);
  }
}

MultiplayerMatchView _match(server.GameMatchView value) {
  if (value.matchId.isEmpty ||
      value.mapId.isEmpty ||
      value.mapHash.isEmpty ||
      value.rulesetId.isEmpty ||
      value.rulesetHash.isEmpty ||
      value.revision < 0 ||
      value.eventOffset < 0) {
    throw const FormatException('The server returned an invalid match.');
  }
  return MultiplayerMatchView(
    matchId: value.matchId,
    mapId: value.mapId,
    mapHash: value.mapHash,
    rulesetId: value.rulesetId,
    rulesetHash: value.rulesetHash,
    revision: value.revision,
    eventOffset: value.eventOffset,
  );
}

MultiplayerSessionException _translate(Object error, StackTrace stackTrace) {
  if (error is MultiplayerSessionException) return error;
  if (error is server.GameException) {
    return MultiplayerSessionException(
      code: error.code,
      message: error.message ?? 'The game request was rejected.',
      diagnosticCause: error,
      diagnosticStackTrace: stackTrace,
    );
  }
  if (error is FormatException) {
    return MultiplayerSessionException(
      code: 'invalid_server_response',
      message: 'The server response failed strict validation.',
      diagnosticCause: error,
      diagnosticStackTrace: stackTrace,
    );
  }
  if (error is server.ServerpodClientUnauthorized ||
      error is TimeoutException ||
      error is server.ServerpodClientInternalServerError) {
    return MultiplayerSessionException(
      code: 'connection_interrupted',
      message: 'The server connection was interrupted.',
      retryable: true,
      diagnosticCause: error,
      diagnosticStackTrace: stackTrace,
    );
  }
  if (error is server.ServerpodClientException) {
    return MultiplayerSessionException(
      code: 'server_request_failed',
      message: 'The server request failed.',
      retryable: error.statusCode >= 500,
      diagnosticCause: error,
      diagnosticStackTrace: stackTrace,
    );
  }
  return MultiplayerSessionException(
    code: 'connection_interrupted',
    message: 'The server connection was interrupted.',
    retryable: true,
    diagnosticCause: error,
    diagnosticStackTrace: stackTrace,
  );
}
