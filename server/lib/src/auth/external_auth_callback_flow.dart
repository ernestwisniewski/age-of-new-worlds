part of 'external_auth_service.dart';

extension _ExternalAuthCallbackFlow on ExternalAuthService {
  Future<ExternalAuthCallbackResult> _handleAppleCallback(
    Session session,
    Map<String, String> parameters,
  ) async {
    final state = parameters['state'];
    if (!ExternalAuthService.isDesktopState(state)) {
      return _failure('Apple sign-in failed', 'Invalid authentication state.');
    }
    final appleError = parameters['error'];
    if (appleError != null) {
      await _failByState(session, state!, _safeProviderError(appleError));
      return _failure(
        'Apple sign-in cancelled',
        'Please return to Age of New Worlds and try again.',
      );
    }

    final identityToken = parameters['id_token'];
    final authorizationCode = parameters['code'];
    if (identityToken == null || authorizationCode == null) {
      await _failByState(session, state!, 'invalid_response');
      return _failure(
        'Apple sign-in failed',
        'Apple returned an incomplete response.',
      );
    }

    final name = _parseAppleName(parameters['user']);
    return _completeCallback(
      session,
      state: state!,
      provider: ExternalAuthService.appleProvider,
      credentials: {
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        if (name.firstName != null) 'firstName': name.firstName!,
        if (name.lastName != null) 'lastName': name.lastName!,
      },
    );
  }

  Future<ExternalAuthCallbackResult> _handleGoogleCallback(
    Session session,
    Map<String, String> parameters,
  ) async {
    final state = parameters['state'];
    if (!ExternalAuthService.isDesktopState(state)) {
      return _failure('Google sign-in failed', 'Invalid authentication state.');
    }
    final googleError = parameters['error'];
    if (googleError != null) {
      await _failByState(session, state!, _safeProviderError(googleError));
      return _failure(
        'Google sign-in cancelled',
        'Please return to Age of New Worlds and try again.',
      );
    }

    final code = parameters['code'];
    if (code == null) {
      await _failByState(session, state!, 'invalid_response');
      return _failure(
        'Google sign-in failed',
        'Google returned an incomplete response.',
      );
    }

    final request = await _requestForState(session, state!);
    if (request == null ||
        request.provider != ExternalAuthService.googleProvider) {
      return _failure(
        'Google sign-in failed',
        'The authentication request was not found.',
      );
    }
    final codeVerifier = request.codeVerifier;
    if (codeVerifier == null) {
      await _failByState(session, state, 'invalid_request');
      return _failure(
        'Google sign-in failed',
        'The authentication request is invalid.',
      );
    }

    return _exchangeGoogleCode(
      session,
      state: state,
      code: code,
      codeVerifier: codeVerifier,
    );
  }

  Future<ExternalAuthCallbackResult> _exchangeGoogleCode(
    Session session, {
    required String state,
    required String code,
    required String codeVerifier,
  }) async {
    final preparation = await _prepareCallback(
      session,
      state: state,
      provider: ExternalAuthService.googleProvider,
    );
    if (!preparation.claimed) return preparation.result!;

    try {
      final configuration = _configurationResolver(
        ExternalAuthService.googleProvider,
      );
      final tokenResponse =
          await _tokenExchange(Uri.https('oauth2.googleapis.com', '/token'), {
            'client_id': configuration.clientId,
            'client_secret': configuration.clientSecret!,
            'code': code,
            'code_verifier': codeVerifier,
            'grant_type': 'authorization_code',
            'redirect_uri': configuration.redirectUri,
          });
      final idToken = tokenResponse['id_token'] as String?;
      final accessToken = tokenResponse['access_token'] as String?;
      if (idToken == null) throw const FormatException('Missing id_token');
      return _authenticateClaimedCallback(
        session,
        state: state,
        provider: ExternalAuthService.googleProvider,
        credentials: {'idToken': idToken, 'accessToken': ?accessToken},
      );
    } catch (error, stackTrace) {
      session.log(
        'Google desktop token exchange failed.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
      await _failByState(session, state, 'token_exchange_failed');
      return _failure(
        'Google sign-in failed',
        'Google could not validate this sign-in response.',
      );
    }
  }

  Future<ExternalAuthCallbackResult> _completeCallback(
    Session session, {
    required String state,
    required String provider,
    required Map<String, String> credentials,
  }) async {
    final preparation = await _prepareCallback(
      session,
      state: state,
      provider: provider,
    );
    if (!preparation.claimed) return preparation.result!;

    return _authenticateClaimedCallback(
      session,
      state: state,
      provider: provider,
      credentials: credentials,
    );
  }

  Future<ExternalAuthCallbackResult> _authenticateClaimedCallback(
    Session session, {
    required String state,
    required String provider,
    required Map<String, String> credentials,
  }) async {
    try {
      final auth = await _authenticator(session, provider, credentials);
      final committed = await _commitAuth(session, state, auth);
      if (!committed) {
        return _failure(
          '${_providerLabel(provider)} sign-in failed',
          'The authentication request could not be completed.',
        );
      }
      return _success(provider);
    } catch (error, stackTrace) {
      session.log(
        '${_providerLabel(provider)} desktop authentication failed.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
      await _failByState(session, state, 'authentication_failed');
      return _failure(
        '${_providerLabel(provider)} sign-in failed',
        '${_providerLabel(provider)} could not validate this sign-in response.',
      );
    }
  }
}
