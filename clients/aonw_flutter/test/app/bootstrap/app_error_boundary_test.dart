import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/app/bootstrap/app_error_boundary.dart';
import 'package:aonw_flutter/app/telemetry/client_telemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies framework and asynchronous process errors', () {
    final dispatcher = PlatformDispatcher.instance;
    final originalFlutterHandler = FlutterError.onError;
    final originalPlatformHandler = dispatcher.onError;
    void previousFlutterHandler(FlutterErrorDetails _) {}
    bool previousPlatformHandler(Object _, StackTrace _) => false;
    FlutterError.onError = previousFlutterHandler;
    dispatcher.onError = previousPlatformHandler;

    final diagnostics = _RecordingAppErrorReporter();
    final telemetry = _RecordingClientTelemetry();
    final boundary = AppErrorBoundary.install(
      reporter: AppErrorTelemetryReporter(
        telemetry: telemetry,
        diagnostics: diagnostics,
      ),
      dispatcher: dispatcher,
    );
    addTearDown(() {
      boundary.dispose();
      FlutterError.onError = originalFlutterHandler;
      dispatcher.onError = originalPlatformHandler;
    });

    final frameworkError = StateError('framework');
    final frameworkStack = StackTrace.current;
    FlutterError.onError!(
      FlutterErrorDetails(exception: frameworkError, stack: frameworkStack),
    );

    final asynchronousError = StateError('asynchronous');
    final asynchronousStack = StackTrace.current;
    final handled = dispatcher.onError!(asynchronousError, asynchronousStack);

    expect(handled, isTrue);
    expect(diagnostics.reports, hasLength(2));
    expect(diagnostics.reports[0].kind, AppErrorKind.framework);
    expect(diagnostics.reports[0].kind.code, 'flutter_framework_error');
    expect(diagnostics.reports[0].error, same(frameworkError));
    expect(diagnostics.reports[0].stackTrace, same(frameworkStack));
    expect(diagnostics.reports[1].kind, AppErrorKind.asynchronous);
    expect(diagnostics.reports[1].kind.code, 'unhandled_async_error');
    expect(diagnostics.reports[1].error, same(asynchronousError));
    expect(diagnostics.reports[1].stackTrace, same(asynchronousStack));
    expect(telemetry.events, [
      ClientTelemetryEvent.frameworkError,
      ClientTelemetryEvent.asynchronousError,
    ]);

    boundary.dispose();
    expect(FlutterError.onError, same(previousFlutterHandler));
    expect(dispatcher.onError, same(previousPlatformHandler));
  });

  test('stores a bounded crash record without the raw error message', () async {
    final directory = await Directory.systemTemp.createTemp(
      'aonw-crash-reporter-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final reporter = LocalAppErrorReporter(
      directory: () async => directory,
      clock: () => DateTime.utc(2026, 8, 30, 2, 3, 4),
    );

    reporter.report(
      AppErrorReport(
        kind: AppErrorKind.asynchronous,
        error: StateError('secret-token-value'),
        stackTrace: StackTrace.fromString('frame-one\nframe-two'),
      ),
    );
    await reporter.flush();

    final document = await File(
      '${directory.path}/${LocalAppErrorReporter.fileName}',
    ).readAsString();
    final record = jsonDecode(document.trim()) as Map<String, Object?>;
    expect(record['timestamp'], '2026-08-30T02:03:04.000Z');
    expect(record['kind'], 'unhandled_async_error');
    expect(record['errorType'], 'StateError');
    expect(record['stackTrace'], contains('frame-one'));
    expect(document, isNot(contains('secret-token-value')));
  });
}

final class _RecordingAppErrorReporter implements AppErrorReporter {
  final reports = <AppErrorReport>[];

  @override
  void report(AppErrorReport report) => reports.add(report);
}

final class _RecordingClientTelemetry implements ClientTelemetry {
  final events = <ClientTelemetryEvent>[];

  @override
  void record(ClientTelemetryEvent event) => events.add(event);
}
