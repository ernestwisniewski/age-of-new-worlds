part of 'external_auth_service.dart';

ExternalAuthProviderConfiguration _defaultConfiguration(String provider) {
  if (provider == ExternalAuthService.appleProvider) {
    final config = auth_core.AuthServices.instance.appleIdp.config;
    return (
      clientId: config.serviceIdentifier,
      clientSecret: null,
      redirectUri: config.redirectUri,
    );
  }
  if (provider == ExternalAuthService.googleProvider) {
    final config = auth_core.AuthServices.instance.googleIdp.config;
    final configuredRedirect = Serverpod.instance.getPassword(
      'googleDesktopRedirectUri',
    );
    final redirectUri = configuredRedirect?.trim().isNotEmpty == true
        ? configuredRedirect!.trim()
        : _publicWebUri(ExternalAuthService.googleCallbackPath).toString();
    if (!config.clientSecret.redirectUris.contains(redirectUri)) {
      throw StateError(
        'Google desktop redirect URI is not present in googleClientSecret: '
        '$redirectUri',
      );
    }
    return (
      clientId: config.clientSecret.clientId,
      clientSecret: config.clientSecret.clientSecret,
      redirectUri: redirectUri,
    );
  }
  throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
}

Future<auth_core.AuthSuccess> _defaultAuthenticator(
  Session session,
  String provider,
  Map<String, String> credentials,
) {
  if (provider == ExternalAuthService.appleProvider) {
    return auth_core.AuthServices.instance.appleIdp.login(
      session,
      identityToken: credentials['identityToken']!,
      authorizationCode: credentials['authorizationCode']!,
      isNativeApplePlatformSignIn: false,
      firstName: credentials['firstName'],
      lastName: credentials['lastName'],
    );
  }
  if (provider == ExternalAuthService.googleProvider) {
    return auth_core.AuthServices.instance.googleIdp.login(
      session,
      idToken: credentials['idToken']!,
      accessToken: credentials['accessToken'],
    );
  }
  throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
}

Future<Map<String, dynamic>> _defaultTokenExchange(
  Uri uri,
  Map<String, String> body,
) async {
  final response = await http.post(uri, body: body);
  if (response.statusCode != 200) {
    throw StateError('OAuth token exchange failed (${response.statusCode}).');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid OAuth token response.');
  }
  return decoded;
}

Uri _appleAuthorizationUri(
  ExternalAuthProviderConfiguration configuration,
  String state,
) {
  return Uri.https('appleid.apple.com', '/auth/authorize', {
    'client_id': configuration.clientId,
    'redirect_uri': configuration.redirectUri,
    'response_type': 'code id_token',
    'response_mode': 'form_post',
    'scope': 'name email',
    'state': state,
  });
}

Uri _googleAuthorizationUri(
  ExternalAuthProviderConfiguration configuration,
  String state,
  String codeVerifier,
) {
  final challenge = base64UrlEncode(
    sha256.convert(ascii.encode(codeVerifier)).bytes,
  ).replaceAll('=', '');
  return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
    'client_id': configuration.clientId,
    'redirect_uri': configuration.redirectUri,
    'response_type': 'code',
    'scope': 'openid email profile',
    'state': state,
    'code_challenge': challenge,
    'code_challenge_method': 'S256',
    'prompt': 'select_account',
  });
}

({String? firstName, String? lastName}) _parseAppleName(
  String? serializedUser,
) {
  if (serializedUser == null || serializedUser.isEmpty) {
    return (firstName: null, lastName: null);
  }
  try {
    final user = jsonDecode(serializedUser);
    if (user is! Map<String, dynamic>) {
      return (firstName: null, lastName: null);
    }
    final name = user['name'];
    if (name is! Map<String, dynamic>) {
      return (firstName: null, lastName: null);
    }
    return (
      firstName: name['firstName'] as String?,
      lastName: name['lastName'] as String?,
    );
  } catch (_) {
    return (firstName: null, lastName: null);
  }
}

ExternalAuthCallbackResult _success(String provider) => (
  success: true,
  title: '${_providerLabel(provider)} sign-in complete',
  message: 'You can return to Age of New Worlds.',
);

ExternalAuthCallbackResult _failure(String title, String message) =>
    (success: false, title: title, message: message);

String _providerLabel(String provider) => switch (provider) {
  ExternalAuthService.appleProvider => 'Apple',
  ExternalAuthService.googleProvider => 'Google',
  _ => 'External',
};

String _safeProviderError(String value) {
  return RegExp(r'^[a-zA-Z0-9_.-]{1,64}$').hasMatch(value)
      ? value
      : 'provider_error';
}

bool _isValidToken(String value) =>
    RegExp(r'^[A-Za-z0-9_-]{40,128}$').hasMatch(value);

String _secureToken(int byteCount) {
  final random = Random.secure();
  final bytes = List<int>.generate(byteCount, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

Uri _publicWebUri(String path) {
  final config =
      Serverpod.instance.config.webServer ??
      Serverpod.instance.config.apiServer;
  return Uri(
    scheme: config.publicScheme,
    host: config.publicHost,
    port: _defaultPort(config.publicScheme) == config.publicPort
        ? null
        : config.publicPort,
    path: path,
  );
}

int _defaultPort(String scheme) => scheme == 'https' ? 443 : 80;
