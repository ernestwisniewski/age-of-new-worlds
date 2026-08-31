import 'package:flutter/foundation.dart';

enum ClientTelemetryEvent {
  appStarted('app_started'),
  appSuspended('app_suspended'),
  appResumed('app_resumed'),
  frameworkError('framework_error'),
  asynchronousError('asynchronous_error');

  const ClientTelemetryEvent(this.code);

  final String code;
}

abstract interface class ClientTelemetry {
  void record(ClientTelemetryEvent event);
}

final class NoOpClientTelemetry implements ClientTelemetry {
  const NoOpClientTelemetry();

  @override
  void record(ClientTelemetryEvent event) {}
}

final class DebugClientTelemetry implements ClientTelemetry {
  const DebugClientTelemetry();

  @override
  void record(ClientTelemetryEvent event) {
    debugPrint('AoNW client event: ${event.code}');
  }
}
