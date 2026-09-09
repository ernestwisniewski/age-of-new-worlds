part of 'atomic_local_save_store.dart';

extension _AtomicLocalAutosave on AtomicLocalSaveStore {
  Future<LocalSaveSlotView> _writeAutomatic(
    LocalGameScenarioView scenario,
    bool privateHandoff,
    MatchTurnModeView turnMode,
    String document,
  ) => AtomicLocalSaveStore._translate(() async {
    final slot = LocalSaveSlotView(
      id: _automaticId(scenario, privateHandoff, turnMode),
      scenario: scenario,
      savedAt: _clock().toUtc(),
      automatic: true,
    );
    return write(slot, document);
  });
}

String _automaticId(
  LocalGameScenarioView scenario,
  bool privateHandoff,
  MatchTurnModeView turnMode,
) =>
    'auto-${scenario.name}-${privateHandoff ? 'hotseat' : 'single'}-${turnMode.name}';

LocalSaveSlotView? _automaticSlot(String name) {
  final parts = name.split('-');
  if (parts.length != 4 || parts[0] != 'auto') return null;
  final scenario = LocalGameScenarioView.values
      .where((value) => value.name == parts[1])
      .firstOrNull;
  if (scenario == null ||
      !['single', 'hotseat'].contains(parts[2]) ||
      !MatchTurnModeView.values.any((value) => value.name == parts[3])) {
    return null;
  }
  return LocalSaveSlotView(
    id: name,
    scenario: scenario,
    automatic: true,
    savedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}
