import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  test('emits auth rate-limit events with deliberate fields', () {
    final records = <_LogRecord>[];
    _recordingSink(records).authRateLimited(action: _AuthAction.emailLogin);

    expect(records.map((record) => record.message), [
      'event=auth_rate_limited action=emailLogin',
    ]);
    expect(records.single.level, LogLevel.warning);
  });

  test('logging failures never change request behavior', () {
    final sink = ServerpodOperationalEventSink.withWriter((
      _, {
      required level,
      stackTrace,
    }) {
      throw StateError('logger unavailable');
    });

    expect(
      () => sink.authRateLimited(action: _AuthAction.emailLogin),
      returnsNormally,
    );
  });
}

ServerpodOperationalEventSink _recordingSink(List<_LogRecord> records) {
  return ServerpodOperationalEventSink.withWriter((
    message, {
    required level,
    stackTrace,
  }) {
    records.add(
      _LogRecord(message: message, level: level, stackTrace: stackTrace),
    );
  });
}

enum _AuthAction { emailLogin }

final class _LogRecord {
  const _LogRecord({
    required this.message,
    required this.level,
    required this.stackTrace,
  });

  final String message;
  final LogLevel level;
  final StackTrace? stackTrace;
}
