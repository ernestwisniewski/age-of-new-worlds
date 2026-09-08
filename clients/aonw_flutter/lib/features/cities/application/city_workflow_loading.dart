part of 'city_workflow.dart';

extension CityWorkflowLoading on CityWorkflow {
  Future<void> _inspect({
    required String cityId,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) async {
    final current = _selectedCity(readState(), cityId);
    if (current == null) return;
    final revision = current.recipient.stamp.revision;
    try {
      final inspection = await _session.inspectCity(
        expectedRevision: revision,
        cityId: cityId,
      );
      if (isDisposed()) return;
      final ready = _selectedCityAtRevision(readState(), cityId, revision);
      if (ready == null) return;
      publish(
        ready.withInteraction(
          ready.interaction.copyWith(
            city: CityState(
              cityId: cityId,
              inspection: inspection,
              managementMode: ready.interaction.city?.managementMode,
            ),
          ),
        ),
      );
    } on CitySessionException catch (error, stackTrace) {
      _loadFailure(
        error,
        stackTrace,
        subjectId: cityId,
        founding: false,
        expectedRevision: revision,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on Object catch (error, stackTrace) {
      _unexpectedLoadFailure(
        error,
        stackTrace,
        subjectId: cityId,
        founding: false,
        expectedRevision: revision,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    }
  }

  Future<void> _founding({
    required String founderUnitId,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) async {
    final current = _selectedUnit(readState(), founderUnitId);
    if (current == null ||
        current.interaction.city?.founderUnitId != founderUnitId) {
      return;
    }
    final revision = current.recipient.stamp.revision;
    final correlationId = current.interaction.city!.correlationId;
    try {
      final options = await _session.cityFoundingOptions(
        expectedRevision: revision,
        founderUnitId: founderUnitId,
      );
      if (isDisposed()) return;
      final ready = _selectedUnitAtRevision(
        readState(),
        founderUnitId,
        revision,
        correlationId,
      );
      if (ready == null) return;
      publish(_loadedFounding(ready, options));
    } on CitySessionException catch (error, stackTrace) {
      _loadFailure(
        error,
        stackTrace,
        subjectId: founderUnitId,
        founding: true,
        expectedRevision: revision,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on Object catch (error, stackTrace) {
      _unexpectedLoadFailure(
        error,
        stackTrace,
        subjectId: founderUnitId,
        founding: true,
        expectedRevision: revision,
        correlationId: correlationId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    }
  }

  void _loadFailure(
    CitySessionException error,
    StackTrace stackTrace, {
    required String subjectId,
    required bool founding,
    required int expectedRevision,
    int? correlationId,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    final ready = _selectedLoadSubject(
      readState(),
      subjectId,
      expectedRevision,
      founding,
      correlationId,
    );
    if (ready == null) return;
    _report(error, stackTrace);
    publish(
      ready.withInteraction(
        ready.interaction.copyWith(
          city: CityState(
            cityId: founding ? null : subjectId,
            founderUnitId: founding ? subjectId : null,
            correlationId: correlationId ?? 0,
            managementMode: ready.interaction.city?.managementMode,
            failure: CityFailureView(_failureCode(error.code)),
          ),
        ),
      ),
    );
  }

  void _unexpectedLoadFailure(
    Object error,
    StackTrace stackTrace, {
    required String subjectId,
    required bool founding,
    required int expectedRevision,
    int? correlationId,
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    final ready = _selectedLoadSubject(
      readState(),
      subjectId,
      expectedRevision,
      founding,
      correlationId,
    );
    if (ready == null) return;
    _diagnosticReporter('unexpected_city_failure', error, stackTrace);
    publish(
      ready.withInteraction(
        ready.interaction.copyWith(
          city: CityState(
            cityId: founding ? null : subjectId,
            founderUnitId: founding ? subjectId : null,
            correlationId: correlationId ?? 0,
            managementMode: ready.interaction.city?.managementMode,
            failure: const CityFailureView(CityFailureCode.requestFailed),
          ),
        ),
      ),
    );
  }
}

GameSessionReady _loadedFounding(
  GameSessionReady current,
  CityFoundingOptionsView options,
) => current.withInteraction(
  current.interaction.copyWith(
    city: current.interaction.city!.copyWith(
      loading: false,
      foundingOptions: options,
      foundingSelection: options.selectedControlledHexes,
      clearFailure: true,
    ),
  ),
);
