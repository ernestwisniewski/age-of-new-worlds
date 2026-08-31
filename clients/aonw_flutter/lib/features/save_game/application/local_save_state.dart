enum LocalSavePhase { idle, saving, saved, failed }

enum LocalSaveFailureViewCode { unavailable, exportFailed, writeFailed }

final class LocalSaveState {
  const LocalSaveState._({required this.phase, this.failure});

  const LocalSaveState.idle() : this._(phase: LocalSavePhase.idle);

  const LocalSaveState.saving() : this._(phase: LocalSavePhase.saving);

  const LocalSaveState.saved() : this._(phase: LocalSavePhase.saved);

  const LocalSaveState.failed(LocalSaveFailureViewCode failure)
    : this._(phase: LocalSavePhase.failed, failure: failure);

  final LocalSavePhase phase;
  final LocalSaveFailureViewCode? failure;

  bool get inFlight => phase == LocalSavePhase.saving;
}

enum LocalResumeFailureViewCode {
  unavailable,
  missing,
  unreadable,
  incompatible,
}

final class LocalResumeResultView {
  const LocalResumeResultView.started() : started = true, failure = null;

  const LocalResumeResultView.failed(this.failure) : started = false;

  final bool started;
  final LocalResumeFailureViewCode? failure;
}
