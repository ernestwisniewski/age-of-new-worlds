import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/local_game_catalog.dart';
import '../application/local_game_session_port.dart';
import 'local_game_launch_mode.dart';
import 'new_game_widgets.dart';

final class NewGameReviewStep extends StatelessWidget {
  const NewGameReviewStep({
    required this.actualMode,
    required this.scenario,
    required this.humanCountry,
    required this.opponentCountry,
    required this.opponentControl,
    required this.difficulty,
    required this.persona,
    required this.fogEnabled,
    required this.turnMode,
    required this.starting,
    required this.failed,
    required this.onBack,
    required this.onStart,
    super.key,
  });

  final LocalGameLaunchModeView actualMode;
  final LocalGameCatalogEntryView scenario;
  final LocalPlayerCountryView humanCountry;
  final LocalPlayerCountryView opponentCountry;
  final LocalPlayerControlView opponentControl;
  final LocalAiDifficultyView difficulty;
  final LocalAiPersonaView persona;
  final bool fogEnabled;
  final LocalTurnModeView turnMode;
  final bool starting;
  final bool failed;
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      key: const ValueKey('new-game-review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.gameSummaryIntro,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AonwSpacing.lg),
        _summary(l10n),
        if (failed) ...[
          const SizedBox(height: AonwSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.localGameStartFailed,
              key: const ValueKey('new-game-failure'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: AonwSpacing.lg),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AonwSpacing.md,
          runSpacing: AonwSpacing.sm,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('back-to-setup'),
              onPressed: starting ? null : onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.changeSetup),
            ),
            FilledButton.icon(
              key: const ValueKey('start-game'),
              onPressed: starting ? null : onStart,
              icon: starting
                  ? const SizedBox.square(
                      dimension: AonwSizes.compactProgress,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(starting ? l10n.startingGame : l10n.startGame),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summary(AonwLocalizations l10n) {
    final country = l10n.countryName(humanCountry.name);
    final opponentCountryName = l10n.countryName(opponentCountry.name);
    final opponentName = opponentControl == LocalPlayerControlView.ai
        ? l10n.defaultAiName
        : l10n.defaultSecondPlayerName;
    return NewGameSection(
      keyName: 'game-summary',
      title: l10n.gameSummaryTitle,
      icon: Icons.fact_check_outlined,
      child: Column(
        children: [
          NewGameSummaryRow(
            label: l10n.summaryModeLabel,
            value: l10n.localModeName(actualMode.name),
          ),
          NewGameSummaryRow(
            label: l10n.summaryTurnModeLabel,
            value: l10n.turnModeName(turnMode.name),
          ),
          NewGameSummaryRow(
            label: l10n.summaryCivilizationLabel,
            value: '${l10n.defaultPlayerName} · $country',
          ),
          NewGameSummaryRow(
            label: l10n.summaryOpponentLabel,
            value:
                '$opponentName · $opponentCountryName · '
                '${l10n.participantControlName(opponentControl.name)}',
          ),
          NewGameSummaryRow(
            label: l10n.summaryMapLabel,
            value: l10n.localScenarioName(scenario.id.name),
          ),
          NewGameSummaryRow(
            label: l10n.summaryFogLabel,
            value: l10n.fogSettingName(fogEnabled ? 'enabled' : 'disabled'),
          ),
          if (opponentControl == LocalPlayerControlView.ai)
            NewGameSummaryRow(
              label: l10n.summaryAiLabel,
              value:
                  '${l10n.aiDifficultyName(difficulty.name)} · '
                  '${l10n.aiPersonaName(persona.name)}',
            ),
        ],
      ),
    );
  }
}
