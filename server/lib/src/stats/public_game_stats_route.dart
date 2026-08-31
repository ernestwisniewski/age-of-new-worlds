import 'dart:async';
import 'dart:convert';

import 'package:aonw_server/src/stats/public_game_stats_service.dart';
import 'package:aonw_server/src/stats/public_game_stats_store.dart';
import 'package:serverpod/serverpod.dart';

final class PublicGameStatsRoute extends Route {
  PublicGameStatsRoute({PublicGameStatsService? service})
    : _service = service ?? PublicGameStatsService(),
      super(methods: {Method.get});

  final PublicGameStatsService _service;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final stats = await _service.snapshot(
      ServerpodPublicGameStatsStore(session),
    );
    return Response.ok(
      headers: Headers.fromMap({
        'cache-control': [
          'public, max-age=30, s-maxage=60, stale-while-revalidate=300',
        ],
        'access-control-allow-origin': ['*'],
        'x-content-type-options': ['nosniff'],
      }),
      body: Body.fromString(
        jsonEncode(stats.toJson()),
        mimeType: MimeType.json,
      ),
    );
  }
}
