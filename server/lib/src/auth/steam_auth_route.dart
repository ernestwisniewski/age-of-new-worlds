import 'dart:async';
import 'dart:convert';

import 'package:aonw_server/src/auth/steam_auth_service.dart';
import 'package:serverpod/serverpod.dart';

class SteamAuthCallbackRoute extends Route {
  SteamAuthCallbackRoute() : super(methods: {Method.get});

  final _service = SteamAuthService();

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final result = await _service.handleCallback(session, request.url);
    return Response.ok(
      body: Body.fromString(
        _html(result.title, result.message, success: result.success),
        mimeType: MimeType.html,
      ),
    );
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
}
