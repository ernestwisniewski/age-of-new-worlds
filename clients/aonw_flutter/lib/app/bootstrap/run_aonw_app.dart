import 'package:flutter/widgets.dart';

import '../composition/app_composition.dart';
import '../telemetry/client_telemetry.dart';
import 'app_error_boundary.dart';

void runAonwApp({
  AppErrorReporter? errorReporter,
  ClientTelemetry telemetry = const DebugClientTelemetry(),
}) {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorBoundary.install(
    reporter: AppErrorTelemetryReporter(
      telemetry: telemetry,
      diagnostics: errorReporter ?? LocalAppErrorReporter.production(),
    ),
  );
  runApp(AppComposition.production(telemetry: telemetry).root);
}
