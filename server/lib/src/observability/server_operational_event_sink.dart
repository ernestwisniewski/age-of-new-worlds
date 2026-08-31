import 'package:serverpod/serverpod.dart';

typedef ServerOperationalLogWriter =
    void Function(
      String message, {
      required LogLevel level,
      StackTrace? stackTrace,
    });

/// Emits a deliberately small, non-sensitive set of operational events.
///
/// Callers provide only enums. Tokens, account identifiers, network addresses,
/// nonces, and payloads do not belong in this interface.
abstract interface class ServerOperationalEventSink {
  void authRateLimited({required Enum action});
}

final class ServerpodOperationalEventSink
    implements ServerOperationalEventSink {
  factory ServerpodOperationalEventSink(Session session) {
    return ServerpodOperationalEventSink.withWriter((
      message, {
      required level,
      stackTrace,
    }) {
      session.log(message, level: level, stackTrace: stackTrace);
    });
  }

  ServerpodOperationalEventSink.withWriter(this._write);

  final ServerOperationalLogWriter _write;

  @override
  void authRateLimited({required Enum action}) {
    _emit(
      'event=auth_rate_limited action=${action.name}',
      level: LogLevel.warning,
    );
  }

  void _emit(
    String message, {
    required LogLevel level,
    StackTrace? stackTrace,
  }) {
    try {
      _write(message, level: level, stackTrace: stackTrace);
    } catch (_) {
      // Observability is best-effort and must never change request behavior.
    }
  }
}

final class NoopServerOperationalEventSink
    implements ServerOperationalEventSink {
  const NoopServerOperationalEventSink();

  @override
  void authRateLimited({required Enum action}) {}
}
