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
            city: CityState(cityId: cityId, inspection: inspection),
          ),
        ),
      );
    } on CitySessionException catch (error, stackTrace) {
      _loadFailure(
        error,
        stackTrace,
        subjectId: cityId,
        founding: false,
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
    if (current == null) return;
    final revision = current.recipient.stamp.revision;
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
      );
      if (ready == null) return;
      publish(
        ready.withInteraction(
          ready.interaction.copyWith(
            city: CityState(
              founderUnitId: founderUnitId,
              foundingOptions: options,
              foundingSelection: options.selectedControlledHexes,
            ),
          ),
        ),
      );
    } on CitySessionException catch (error, stackTrace) {
      _loadFailure(
        error,
        stackTrace,
        subjectId: founderUnitId,
        founding: true,
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
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _report(error, stackTrace);
    final ready = founding
        ? _selectedUnit(readState(), subjectId)
        : _selectedCity(readState(), subjectId);
    if (ready == null) return;
    publish(
      ready.withInteraction(
        ready.interaction.copyWith(
          city: CityState(
            cityId: founding ? null : subjectId,
            founderUnitId: founding ? subjectId : null,
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
    required CityStateReader readState,
    required CityStatePublisher publish,
    required CityDisposed isDisposed,
  }) {
    if (isDisposed()) return;
    _diagnosticReporter('unexpected_city_failure', error, stackTrace);
    final ready = founding
        ? _selectedUnit(readState(), subjectId)
        : _selectedCity(readState(), subjectId);
    if (ready == null) return;
    publish(
      ready.withInteraction(
        ready.interaction.copyWith(
          city: CityState(
            cityId: founding ? null : subjectId,
            founderUnitId: founding ? subjectId : null,
            failure: const CityFailureView(CityFailureCode.requestFailed),
          ),
        ),
      ),
    );
  }
}
