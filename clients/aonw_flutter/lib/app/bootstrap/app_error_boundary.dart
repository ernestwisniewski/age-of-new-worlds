import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../telemetry/client_telemetry.dart';

enum AppErrorKind {
  framework('flutter_framework_error'),
  asynchronous('unhandled_async_error');

  const AppErrorKind(this.code);

  final String code;
}

final class AppErrorReport {
  const AppErrorReport({
    required this.kind,
    required this.error,
    required this.stackTrace,
  });

  final AppErrorKind kind;
  final Object error;
  final StackTrace stackTrace;
}

abstract interface class AppErrorReporter {
  void report(AppErrorReport report);
}

final class DebugAppErrorReporter implements AppErrorReporter {
  const DebugAppErrorReporter();

  @override
  void report(AppErrorReport report) {
    debugPrintStack(
      label: 'AoNW client error [${report.kind.code}]: ${report.error}',
      stackTrace: report.stackTrace,
    );
  }
}

typedef AppDiagnosticsDirectory = Future<Directory> Function();

final class LocalAppErrorReporter implements AppErrorReporter {
  LocalAppErrorReporter({
    required AppDiagnosticsDirectory directory,
    DateTime Function() clock = DateTime.now,
    int maximumBytes = 512 * 1024,
  }) : _directory = directory,
       _clock = clock,
       _maximumBytes = maximumBytes {
    if (maximumBytes <= 0) {
      throw ArgumentError.value(maximumBytes, 'maximumBytes');
    }
  }

  factory LocalAppErrorReporter.production() =>
      LocalAppErrorReporter(directory: getApplicationSupportDirectory);

  static const fileName = 'crashes.jsonl';
  static const previousFileName = 'crashes.previous.jsonl';
  static const _maximumStackTraceCharacters = 16 * 1024;

  final AppDiagnosticsDirectory _directory;
  final DateTime Function() _clock;
  final int _maximumBytes;
  Future<void> _tail = Future<void>.value();

  @override
  void report(AppErrorReport report) {
    _tail = _tail.then((_) => _write(report));
  }

  Future<void> flush() => _tail;

  Future<void> _write(AppErrorReport report) async {
    try {
      final directory = await _directory();
      await directory.create(recursive: true);
      final file = File('${directory.path}/$fileName');
      if (await file.exists() && await file.length() >= _maximumBytes) {
        final previous = File('${directory.path}/$previousFileName');
        if (await previous.exists()) await previous.delete();
        await file.rename(previous.path);
      }
      final stackTrace = report.stackTrace.toString();
      final boundedStackTrace =
          stackTrace.length <= _maximumStackTraceCharacters
          ? stackTrace
          : stackTrace.substring(0, _maximumStackTraceCharacters);
      await file.writeAsString(
        '${jsonEncode({'timestamp': _clock().toUtc().toIso8601String(), 'kind': report.kind.code, 'errorType': report.error.runtimeType.toString(), 'stackTrace': boundedStackTrace})}\n',
        mode: FileMode.append,
        flush: true,
      );
    } on Object catch (error) {
      debugPrint('AoNW local crash report write failed: ${error.runtimeType}');
    }
  }
}

final class AppErrorTelemetryReporter implements AppErrorReporter {
  const AppErrorTelemetryReporter({
    required ClientTelemetry telemetry,
    required AppErrorReporter diagnostics,
  }) : _telemetry = telemetry,
       _diagnostics = diagnostics;

  final ClientTelemetry _telemetry;
  final AppErrorReporter _diagnostics;

  @override
  void report(AppErrorReport report) {
    _telemetry.record(switch (report.kind) {
      AppErrorKind.framework => ClientTelemetryEvent.frameworkError,
      AppErrorKind.asynchronous => ClientTelemetryEvent.asynchronousError,
    });
    _diagnostics.report(report);
  }
}

/// Owns the two process-level Flutter error callbacks installed at bootstrap.
final class AppErrorBoundary {
  AppErrorBoundary._({
    required AppErrorReporter reporter,
    required PlatformDispatcher dispatcher,
  }) : _reporter = reporter,
       _dispatcher = dispatcher,
       _previousFlutterHandler = FlutterError.onError,
       _previousPlatformHandler = dispatcher.onError {
    _flutterHandler = _handleFlutterError;
    _platformHandler = _handlePlatformError;
    FlutterError.onError = _flutterHandler;
    _dispatcher.onError = _platformHandler;
  }

  factory AppErrorBoundary.install({
    required AppErrorReporter reporter,
    PlatformDispatcher? dispatcher,
  }) => AppErrorBoundary._(
    reporter: reporter,
    dispatcher: dispatcher ?? PlatformDispatcher.instance,
  );

  final AppErrorReporter _reporter;
  final PlatformDispatcher _dispatcher;
  final FlutterExceptionHandler? _previousFlutterHandler;
  final ErrorCallback? _previousPlatformHandler;
  late final FlutterExceptionHandler _flutterHandler;
  late final ErrorCallback _platformHandler;
  var _disposed = false;

  void _handleFlutterError(FlutterErrorDetails details) {
    _reporter.report(
      AppErrorReport(
        kind: AppErrorKind.framework,
        error: details.exception,
        stackTrace: details.stack ?? StackTrace.current,
      ),
    );
  }

  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    _reporter.report(
      AppErrorReport(
        kind: AppErrorKind.asynchronous,
        error: error,
        stackTrace: stackTrace,
      ),
    );
    return true;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (identical(FlutterError.onError, _flutterHandler)) {
      FlutterError.onError = _previousFlutterHandler;
    }
    if (identical(_dispatcher.onError, _platformHandler)) {
      _dispatcher.onError = _previousPlatformHandler;
    }
  }
}
