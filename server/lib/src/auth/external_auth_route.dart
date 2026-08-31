import 'dart:async';
import 'dart:convert';

import 'package:aonw_server/src/auth/external_auth_service.dart';
import 'package:serverpod/serverpod.dart';

class AppleExternalAuthCallbackRoute extends Route {
  AppleExternalAuthCallbackRoute({
    required this.androidPackageIdentifier,
    required this.webRedirectUri,
    ExternalAuthService? service,
  }) : _service = service ?? ExternalAuthService(),
       super(methods: {Method.post});

  final String? androidPackageIdentifier;
  final String? webRedirectUri;
  final ExternalAuthService _service;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final body = await request.readAsString();
    final parameters = body.isEmpty
        ? <String, String>{}
        : Uri.splitQueryString(body);
    if (ExternalAuthService.isDesktopState(parameters['state'])) {
      final result = await _service.handleAppleCallback(session, parameters);
      return _callbackPage(result);
    }

    final queryString = _queryString(parameters);
    if (_isAndroid(request.headers)) {
      final packageIdentifier = androidPackageIdentifier;
      if (packageIdentifier == null || packageIdentifier.isEmpty) {
        return Response.internalServerError(
          body: Body.fromString(
            'Apple Android package identifier is not configured.',
          ),
        );
      }
      final intentUri =
          'intent://callback$queryString#Intent;'
          'package=$packageIdentifier;scheme=signinwithapple;end';
      return _redirect(intentUri, statusCode: 307);
    }

    final redirectUri = webRedirectUri;
    if (redirectUri == null || redirectUri.isEmpty) {
      return Response.internalServerError(
        body: Body.fromString('Apple web redirect URI is not configured.'),
      );
    }
    return _redirect('$redirectUri$queryString', statusCode: 303);
  }

  bool _isAndroid(Headers headers) =>
      (headers.userAgent ?? '').toLowerCase().contains('android');
}

class GoogleExternalAuthCallbackRoute extends Route {
  GoogleExternalAuthCallbackRoute({ExternalAuthService? service})
    : _service = service ?? ExternalAuthService(),
      super(methods: {Method.get});

  final ExternalAuthService _service;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final result = await _service.handleGoogleCallback(
      session,
      request.url.queryParameters,
    );
    return _callbackPage(result);
  }
}

Result _callbackPage(ExternalAuthCallbackResult result) {
  return Response.ok(
    body: Body.fromString(
      _html(result.title, result.message, success: result.success),
      mimeType: MimeType.html,
    ),
  );
}

Result _redirect(String location, {required int statusCode}) {
  final headers = Headers.build((builder) {
    builder['Location'] = [location];
  });
  return Response(statusCode, headers: headers, body: Body.empty());
}

String _queryString(Map<String, String> parameters) {
  if (parameters.isEmpty) return '';
  return '?${parameters.entries.map((entry) {
    return '${Uri.encodeComponent(entry.key)}='
        '${Uri.encodeComponent(entry.value)}';
  }).join('&')}';
}

String _html(String title, String message, {required bool success}) {
  final escapedTitle = htmlEscape.convert(title);
  final escapedMessage = htmlEscape.convert(message);
  final color = success ? '#20a46b' : '#c2410c';
  return '''
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$escapedTitle</title>
    <style>
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        place-items: center;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background: #0f172a;
        color: #f8fafc;
      }
      main {
        width: min(90vw, 440px);
        padding: 32px;
        border: 1px solid rgba(248, 250, 252, 0.16);
        border-radius: 8px;
        background: rgba(15, 23, 42, 0.92);
        box-shadow: 0 22px 80px rgba(0, 0, 0, 0.35);
      }
      h1 {
        margin: 0 0 12px;
        color: $color;
        font-size: 28px;
        line-height: 1.15;
      }
      p {
        margin: 0;
        color: #cbd5e1;
        font-size: 16px;
        line-height: 1.5;
      }
    </style>
  </head>
  <body>
    <main>
      <h1>$escapedTitle</h1>
      <p>$escapedMessage</p>
    </main>
  </body>
</html>
''';
}
