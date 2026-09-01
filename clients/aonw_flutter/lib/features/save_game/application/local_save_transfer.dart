import '../../local_game/application/local_game_catalog.dart';

enum LocalSaveTransferFailureViewCode {
  unavailable,
  unreadable,
  tooLarge,
  incompatible,
  missing,
  writeFailed,
  exportFailed,
}

enum LocalSaveTransferStatusView { completed, cancelled, failed }

final class LocalSaveTransferResultView {
  const LocalSaveTransferResultView.completed({required this.scenario})
    : status = LocalSaveTransferStatusView.completed,
      failure = null;

  const LocalSaveTransferResultView.cancelled()
    : status = LocalSaveTransferStatusView.cancelled,
      scenario = null,
      failure = null;

  const LocalSaveTransferResultView.failed(this.failure)
    : status = LocalSaveTransferStatusView.failed,
      scenario = null;

  final LocalSaveTransferStatusView status;
  final LocalGameScenarioView? scenario;
  final LocalSaveTransferFailureViewCode? failure;

  bool get completed => status == LocalSaveTransferStatusView.completed;
}

enum LocalSaveExportDisposition { completed, cancelled }

final class LocalSavePickedDocumentView {
  const LocalSavePickedDocumentView({required this.document, this.name});

  final String document;
  final String? name;
}

abstract interface class LocalSaveTransferPort {
  Future<LocalSavePickedDocumentView?> pickSaveDocument();

  Future<LocalSaveExportDisposition> exportSaveDocument({
    required String suggestedName,
    required String document,
  });
}

final class LocalSaveTransferException implements Exception {
  const LocalSaveTransferException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;

  @override
  String toString() => 'LocalSaveTransferException($code): $message';
}
