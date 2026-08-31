part of 'city_workflow.dart';

extension CityWorkflowCommands on CityWorkflow {
  Future<void> _execute({
    required CityActionView action,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
    required void Function(String cityId)? onSelectionRetained,
  }) async {
    final current = _executable(readState(), action);
    if (current == null) return;
    final correlationId = ++_correlationId;
    publish(_pending(current, action, correlationId));
    try {
      final result = await _session.executeCityAction(
        expectedRevision: current.recipient.stamp.revision,
        action: action,
      );
      if (isDisposed()) return;
      final ready = _correlated(readState(), correlationId);
      if (ready == null) return;
      if (!result.accepted) {
        publish(_rejected(ready, result.rejectionCode!));
        return;
      }
      final accepted = _accepted(ready, result.player!, action);
      publish(accepted);
      if (action
          case ToggleWorkedHexActionView(:final cityId) ||
              SelectCityExpansionActionView(:final cityId)) {
        onSelectionRetained?.call(cityId);
        inspect(
          cityId: cityId,
          readState: readState,
          publish: publish,
          isDisposed: isDisposed,
        );
      }
    } on CitySessionException catch (error, stackTrace) {
      _commandFailure(
        error,
        stackTrace,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on Object catch (error, stackTrace) {
      _unexpectedCommandFailure(
        error,
        stackTrace,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    }
  }

  void _commandFailure(
    CitySessionException error,
    StackTrace stackTrace, {
    required int correlationId,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _report(error, stackTrace);
    final ready = _correlated(readState(), correlationId);
    if (ready == null) return;
    final synchronized = error.resyncedPlayer == null
        ? ready
        : ready.withRecipient(error.resyncedPlayer!);
    publish(
      synchronized.withInteraction(
        synchronized.interaction.copyWith(
          city: synchronized.interaction.city!.copyWith(
            clearInFlightAction: true,
            failure: CityFailureView(_failureCode(error.code)),
          ),
        ),
      ),
    );
  }

  void _unexpectedCommandFailure(
    Object error,
    StackTrace stackTrace, {
    required int correlationId,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _diagnosticReporter('unexpected_city_failure', error, stackTrace);
    final ready = _correlated(readState(), correlationId);
    if (ready == null) return;
    publish(
      ready.withInteraction(
        ready.interaction.copyWith(
          city: ready.interaction.city!.copyWith(
            clearInFlightAction: true,
            failure: const CityFailureView(CityFailureCode.requestFailed),
          ),
        ),
      ),
    );
  }
}
