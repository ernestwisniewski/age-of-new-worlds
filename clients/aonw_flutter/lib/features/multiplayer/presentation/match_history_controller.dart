import 'package:flutter/foundation.dart';

import '../application/match_history_port.dart';
import '../application/multiplayer_session_port.dart';

final class MatchHistoryController extends ChangeNotifier {
  MatchHistoryController(this._port, {required this.userId});

  final MatchHistoryPort _port;
  final String userId;
  MatchHistoryPageView? page;
  String? failureCode;
  bool busy = false;
  final _previous = <int?>[];
  int? _cursor;
  var _generation = 0;
  var _disposed = false;

  bool get hasPrevious => _previous.isNotEmpty;
  bool get hasNext => page?.nextBeforeParticipantId != null;

  Future<void> refresh() => _load(null, 0);

  Future<void> next() =>
      hasNext ? _load(page!.nextBeforeParticipantId, 1) : Future.value();

  Future<void> previous() =>
      hasPrevious ? _load(_previous.last, -1) : Future.value();

  Future<void> _load(int? cursor, int direction) async {
    if (_disposed || busy) return;
    final generation = ++_generation;
    busy = true;
    failureCode = null;
    notifyListeners();
    try {
      final result = await _port.readMatchHistory(beforeParticipantId: cursor);
      if (!_current(generation)) return;
      _validatePage(result, userId, cursor);
      _accept(result, cursor, direction);
    } on Object catch (error) {
      if (!_current(generation)) return;
      failureCode = error is MultiplayerSessionException
          ? error.code
          : 'history_unavailable';
    } finally {
      if (_current(generation)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void _accept(MatchHistoryPageView result, int? cursor, int direction) {
    if (direction > 0) {
      _previous.add(_cursor);
    } else if (direction < 0) {
      _previous.removeLast();
    } else {
      _previous.clear();
    }
    _cursor = cursor;
    page = result;
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

void _validatePage(MatchHistoryPageView page, String userId, int? cursor) {
  final next = page.nextBeforeParticipantId;
  if (page.userId != userId) {
    throw const MultiplayerSessionException(
      code: 'history_session_changed',
      message: 'The history belongs to another account.',
    );
  }
  if (page.entries.length > 50 ||
      page.entries.map((entry) => entry.match.matchId).toSet().length !=
          page.entries.length ||
      next != null &&
          (page.entries.isEmpty ||
              next < 1 ||
              cursor != null && next >= cursor)) {
    throw const MultiplayerSessionException(
      code: 'history_unavailable',
      message: 'The history page cannot be continued safely.',
    );
  }
}
