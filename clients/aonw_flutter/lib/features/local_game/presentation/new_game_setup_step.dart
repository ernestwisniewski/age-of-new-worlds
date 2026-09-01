import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/local_game_catalog.dart';
import '../application/local_game_session_port.dart';
import 'local_game_launch_mode.dart';
import 'new_game_opponent_setup.dart';
import 'new_game_widgets.dart';

final class NewGameSetupStep extends StatelessWidget {
  const NewGameSetupStep({
    required this.launchMode,
    required this.scenario,
    required this.humanCountry,
    required this.opponents,
    required this.fogEnabled,
    required this.turnMode,
    required this.onScenarioChanged,
    required this.onHumanCountryChanged,
    required this.onOpponentCountryChanged,
    required this.onOpponentControlChanged,
    required this.onOpponentDifficultyChanged,
    required this.onOpponentPersonaChanged,
    required this.onFogChanged,
    required this.onTurnModeChanged,
    required this.onContinue,
    super.key,
  });

  final LocalGameLaunchModeView launchMode;
  final LocalGameCatalogEntryView scenario;
  final LocalPlayerCountryView humanCountry;
  final List<NewGameOpponentView> opponents;
  final bool fogEnabled;
  final LocalTurnModeView turnMode;
  final ValueChanged<LocalGameCatalogEntryView> onScenarioChanged;
  final ValueChanged<LocalPlayerCountryView> onHumanCountryChanged;
  final void Function(int index, LocalPlayerCountryView value)
  onOpponentCountryChanged;
  final void Function(int index, LocalPlayerControlView value)
  onOpponentControlChanged;
  final void Function(int index, LocalAiDifficultyView value)
  onOpponentDifficultyChanged;
  final void Function(int index, LocalAiPersonaView value)
  onOpponentPersonaChanged;
  final ValueChanged<bool> onFogChanged;
  final ValueChanged<LocalTurnModeView> onTurnModeChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      key: const ValueKey('new-game-setup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          launchMode == LocalGameLaunchModeView.hotseat
              ? l10n.hotseatSetupIntro
              : l10n.singlePlayerSetupIntro,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AonwSpacing.lg),
        _civilizationSection(context, l10n),
        const SizedBox(height: AonwSpacing.md),
        _gameSetupSection(context, l10n),
        const SizedBox(height: AonwSpacing.md),
        _opponentsSection(l10n),
        const SizedBox(height: AonwSpacing.md),
        _facts(l10n),
        const SizedBox(height: AonwSpacing.lg),
        FilledButton.icon(
          key: const ValueKey('continue-to-summary'),
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward),
          label: Text(l10n.continueToSummary),
        ),
      ],
    );
  }

  Widget _civilizationSection(BuildContext context, AonwLocalizations l10n) =>
      NewGameSection(
        keyName: 'civilization-section',
        title: l10n.chooseCivilizationTitle,
        icon: Icons.flag_outlined,
        child: _countryField(
          context,
          keyName: 'human-country',
          label: l10n.humanCountryLabel,
          value: humanCountry,
          onChanged: onHumanCountryChanged,
        ),
      );

  Widget _gameSetupSection(BuildContext context, AonwLocalizations l10n) =>
      NewGameSection(
        keyName: 'game-setup-section',
        title: l10n.gameSetupTitle,
        icon: Icons.tune,
        child: Column(
          children: [
            _scenarioField(l10n),
            const SizedBox(height: AonwSpacing.md),
            _turnModeField(context, l10n),
            SwitchListTile.adaptive(
              key: const ValueKey('fog-of-war'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fogOfWarLabel),
              value: fogEnabled,
              onChanged: onFogChanged,
            ),
          ],
        ),
      );

  Widget _opponentsSection(AonwLocalizations l10n) => NewGameSection(
    keyName: 'opponents-section',
    title: l10n.opponentsTitle,
    icon: Icons.groups_outlined,
    child: NewGameOpponentSetup(
      launchMode: launchMode,
      opponents: opponents,
      onCountryChanged: onOpponentCountryChanged,
      onControlChanged: onOpponentControlChanged,
      onDifficultyChanged: onOpponentDifficultyChanged,
      onPersonaChanged: onOpponentPersonaChanged,
    ),
  );

  Widget _turnModeField(BuildContext context, AonwLocalizations l10n) => Column(
    key: const ValueKey('turn-mode'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(l10n.turnModeTitle, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: AonwSpacing.sm),
      if (launchMode == LocalGameLaunchModeView.singlePlayer)
        SegmentedButton<LocalTurnModeView>(
          key: const ValueKey('turn-mode-selector'),
          segments: [
            for (final value in LocalTurnModeView.values)
              ButtonSegment(
                value: value,
                icon: Icon(
                  value == LocalTurnModeView.sequential
                      ? Icons.redo
                      : Icons.sync_alt,
                ),
                label: Text(l10n.turnModeName(value.name)),
              ),
          ],
          selected: {turnMode},
          onSelectionChanged: (values) => onTurnModeChanged(values.single),
        )
      else
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.redo),
          title: Text(l10n.turnModeName(LocalTurnModeView.sequential.name)),
        ),
      const SizedBox(height: AonwSpacing.sm),
      Text(
        turnMode == LocalTurnModeView.simultaneous &&
                launchMode == LocalGameLaunchModeView.singlePlayer
            ? l10n.turnModeSimultaneousDescription
            : l10n.turnModeSequentialDescription,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _scenarioField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalGameCatalogEntryView>(
        key: ValueKey(('scenario', scenario.id)),
        initialValue: scenario,
        decoration: InputDecoration(labelText: l10n.scenarioLabel),
        items: [
          for (final entry
              in launchMode == LocalGameLaunchModeView.hotseat
                  ? LocalGameCatalog.hotseatEntries
                  : LocalGameCatalog.entries)
            DropdownMenuItem(
              value: entry,
              child: Text(l10n.localScenarioName(entry.id.name)),
            ),
        ],
        onChanged: (value) => onScenarioChanged(value!),
      );

  Widget _countryField(
    BuildContext context, {
    required String keyName,
    required String label,
    required LocalPlayerCountryView value,
    required ValueChanged<LocalPlayerCountryView> onChanged,
  }) => DropdownButtonFormField<LocalPlayerCountryView>(
    key: ValueKey((keyName, value)),
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final country in LocalPlayerCountryView.values)
        DropdownMenuItem(
          value: country,
          child: Text(context.aonwL10n.countryName(country.name)),
        ),
    ],
    onChanged: (value) => onChanged(value!),
  );

  Widget _facts(AonwLocalizations l10n) => Column(
    children: [
      NewGameFact(
        title: l10n.mapSetupTitle,
        body: l10n.mapSetupDetails(
          l10n.localScenarioName(scenario.id.name),
          scenario.columns,
          scenario.rows,
          scenario.maximumPlayers,
        ),
        icon: Icons.map_outlined,
      ),
      const SizedBox(height: AonwSpacing.md),
      NewGameFact(
        title: l10n.victoryPathsTitle,
        body: l10n.victoryPathsBody,
        icon: Icons.emoji_events_outlined,
      ),
      const SizedBox(height: AonwSpacing.md),
      NewGameFact(
        title: l10n.settlementToEmpireTitle,
        body: l10n.settlementToEmpireBody,
        icon: Icons.account_balance_outlined,
      ),
    ],
  );
}
