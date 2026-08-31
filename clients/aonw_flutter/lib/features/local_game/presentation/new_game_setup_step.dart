import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/local_game_catalog.dart';
import '../application/local_game_session_port.dart';
import 'local_game_launch_mode.dart';
import 'new_game_widgets.dart';

final class NewGameSetupStep extends StatelessWidget {
  const NewGameSetupStep({
    required this.launchMode,
    required this.scenario,
    required this.humanCountry,
    required this.opponentCountry,
    required this.opponentControl,
    required this.difficulty,
    required this.persona,
    required this.fogEnabled,
    required this.onScenarioChanged,
    required this.onHumanCountryChanged,
    required this.onOpponentCountryChanged,
    required this.onOpponentControlChanged,
    required this.onDifficultyChanged,
    required this.onPersonaChanged,
    required this.onFogChanged,
    required this.onContinue,
    super.key,
  });

  final LocalGameLaunchModeView launchMode;
  final LocalGameCatalogEntryView scenario;
  final LocalPlayerCountryView humanCountry;
  final LocalPlayerCountryView opponentCountry;
  final LocalPlayerControlView opponentControl;
  final LocalAiDifficultyView difficulty;
  final LocalAiPersonaView persona;
  final bool fogEnabled;
  final ValueChanged<LocalGameCatalogEntryView> onScenarioChanged;
  final ValueChanged<LocalPlayerCountryView> onHumanCountryChanged;
  final ValueChanged<LocalPlayerCountryView> onOpponentCountryChanged;
  final ValueChanged<LocalPlayerControlView> onOpponentControlChanged;
  final ValueChanged<LocalAiDifficultyView> onDifficultyChanged;
  final ValueChanged<LocalAiPersonaView> onPersonaChanged;
  final ValueChanged<bool> onFogChanged;
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
        NewGameSection(
          keyName: 'game-setup-section',
          title: l10n.gameSetupTitle,
          icon: Icons.tune,
          child: Column(
            children: [
              _scenarioField(l10n),
              SwitchListTile.adaptive(
                key: const ValueKey('fog-of-war'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.fogOfWarLabel),
                value: fogEnabled,
                onChanged: onFogChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: AonwSpacing.md),
        NewGameSection(
          keyName: 'opponents-section',
          title: l10n.opponentsTitle,
          icon: Icons.groups_outlined,
          child: _opponentFields(context, l10n),
        ),
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

  Widget _scenarioField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalGameCatalogEntryView>(
        key: ValueKey(('scenario', scenario.id)),
        initialValue: scenario,
        decoration: InputDecoration(labelText: l10n.scenarioLabel),
        items: [
          for (final entry in LocalGameCatalog.entries)
            DropdownMenuItem(
              value: entry,
              child: Text(l10n.localScenarioName(entry.id.name)),
            ),
        ],
        onChanged: (value) => onScenarioChanged(value!),
      );

  Widget _opponentFields(BuildContext context, AonwLocalizations l10n) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (launchMode == LocalGameLaunchModeView.hotseat) ...[
            Text(l10n.opponentControlLabel),
            const SizedBox(height: AonwSpacing.sm),
            SegmentedButton<LocalPlayerControlView>(
              key: const ValueKey('opponent-control'),
              segments: [
                ButtonSegment(
                  value: LocalPlayerControlView.human,
                  icon: const Icon(Icons.person_outline),
                  label: Text(l10n.humanOpponent),
                ),
                ButtonSegment(
                  value: LocalPlayerControlView.ai,
                  icon: const Icon(Icons.memory),
                  label: Text(l10n.aiOpponent),
                ),
              ],
              selected: {opponentControl},
              onSelectionChanged: (values) =>
                  onOpponentControlChanged(values.single),
            ),
            const SizedBox(height: AonwSpacing.md),
          ],
          _countryField(
            context,
            keyName: 'opponent-country',
            label: opponentControl == LocalPlayerControlView.ai
                ? l10n.aiCountryLabel
                : l10n.humanCountryLabel,
            value: opponentCountry,
            onChanged: onOpponentCountryChanged,
          ),
          if (opponentControl == LocalPlayerControlView.ai) ...[
            const SizedBox(height: AonwSpacing.md),
            _difficultyField(l10n),
            const SizedBox(height: AonwSpacing.md),
            _personaField(l10n),
          ],
        ],
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

  Widget _difficultyField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalAiDifficultyView>(
        key: ValueKey(('difficulty', difficulty)),
        initialValue: difficulty,
        decoration: InputDecoration(labelText: l10n.aiDifficultyLabel),
        items: [
          for (final value in LocalAiDifficultyView.values)
            DropdownMenuItem(
              value: value,
              child: Text(l10n.aiDifficultyName(value.name)),
            ),
        ],
        onChanged: (value) => onDifficultyChanged(value!),
      );

  Widget _personaField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalAiPersonaView>(
        key: ValueKey(('persona', persona)),
        initialValue: persona,
        decoration: InputDecoration(labelText: l10n.aiPersonaLabel),
        items: [
          for (final value in LocalAiPersonaView.values)
            DropdownMenuItem(
              value: value,
              child: Text(l10n.aiPersonaName(value.name)),
            ),
        ],
        onChanged: (value) => onPersonaChanged(value!),
      );

  Widget _facts(AonwLocalizations l10n) => Column(
    children: [
      NewGameFact(
        title: l10n.mapSetupTitle,
        body: l10n.mapSetupBody,
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
