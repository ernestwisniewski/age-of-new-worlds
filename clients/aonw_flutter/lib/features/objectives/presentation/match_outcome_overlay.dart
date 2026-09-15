import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../audio/presentation/game_audio_actions.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../../map/read_model/player_victory_view.dart';
import '../../turns/read_model/recipient_turn_view.dart';

part 'match_outcome_metrics.dart';

final class MatchOutcomeOverlay extends StatelessWidget {
  const MatchOutcomeOverlay({
    required this.outcome,
    required this.playerNames,
    this.actorPlayerId,
    this.progress,
    this.onReturnToMenu,
    super.key,
  });

  final GameOutcomeView outcome;
  final Map<String, String> playerNames;
  final String? actorPlayerId;
  final PlayerVictoryView? progress;
  final VoidCallback? onReturnToMenu;

  @override
  Widget build(BuildContext context) {
    if (!outcome.isTerminal) return const SizedBox.shrink();
    final tone = _outcomeTone(outcome.winnerPlayerId, actorPlayerId);
    final returnToMenu = context.withGameSound(
      onReturnToMenu,
      cue: GameSoundCue.menuBack,
    );
    return BlockSemantics(
      child: Stack(
        key: const ValueKey('terminal-outcome'),
        children: [
          const ModalBarrier(dismissible: false, color: Color(0xB3000000)),
          MapGamepadRegion(
            section: MapHudSection.globalActions,
            priority: MapGamepadPriority.modal,
            scrollBeforeFocus: true,
            onCancel: returnToMenu,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AonwSpacing.lg),
                  child: _OutcomeSurface(
                    outcome: outcome,
                    playerNames: playerNames,
                    actorPlayerId: actorPlayerId,
                    progress: progress,
                    tone: tone,
                    onReturnToMenu: returnToMenu,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _OutcomeTone = ({String key, Color color, IconData icon});

_OutcomeTone _outcomeTone(String? winner, String? actor) {
  if (winner == null) {
    return (key: 'draw', color: AonwColorTokens.warning, icon: Icons.balance);
  }
  if (actor == null) {
    return (key: 'complete', color: AonwColorTokens.brand, icon: Icons.flag);
  }
  return winner == actor
      ? (
          key: 'victory',
          color: AonwColorTokens.success,
          icon: Icons.emoji_events,
        )
      : (
          key: 'defeat',
          color: AonwColorTokens.danger,
          icon: Icons.flag_outlined,
        );
}

final class _OutcomeSurface extends StatelessWidget {
  const _OutcomeSurface({
    required this.outcome,
    required this.playerNames,
    required this.actorPlayerId,
    required this.progress,
    required this.tone,
    required this.onReturnToMenu,
  });

  final GameOutcomeView outcome;
  final Map<String, String> playerNames;
  final String? actorPlayerId;
  final PlayerVictoryView? progress;
  final _OutcomeTone tone;
  final VoidCallback? onReturnToMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final winner = outcome.winnerPlayerId;
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.matchFinishedTitle,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AonwColorTokens.surface.withAlpha(246),
          border: Border.all(color: tone.color.withAlpha(190)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 28)],
        ),
        child: Semantics(
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OutcomeHeader(outcome: outcome, tone: tone),
              const SizedBox(height: AonwSpacing.lg),
              Text(
                winner == null
                    ? l10n.outcomeNoWinner
                    : l10n.outcomeWinner(playerNames[winner] ?? winner),
                key: const ValueKey('outcome-winner'),
              ),
              ..._outcomeMetrics(context, this),
              const SizedBox(height: AonwSpacing.lg),
              _action(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context) => FilledButton.icon(
    key: const ValueKey('outcome-return-menu'),
    autofocus: true,
    onPressed: onReturnToMenu,
    style: FilledButton.styleFrom(
      backgroundColor: tone.color,
      foregroundColor:
          ThemeData.estimateBrightnessForColor(tone.color) == Brightness.dark
          ? Colors.white
          : Colors.black,
    ),
    icon: const Icon(Icons.arrow_back, size: 18),
    label: Text(context.aonwL10n.backToMenu, textAlign: TextAlign.center),
  );
}

final class _OutcomeHeader extends StatelessWidget {
  const _OutcomeHeader({required this.outcome, required this.tone});

  final GameOutcomeView outcome;
  final _OutcomeTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final condition = outcome.condition.name;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tone.color.withAlpha(34),
            border: Border.all(color: tone.color.withAlpha(160)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(tone.icon, color: tone.color, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.outcomePresentationText(tone.key),
                key: const ValueKey('outcome-title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AonwSpacing.xs),
              Text(
                l10n.turnText(
                  'outcome${condition[0].toUpperCase()}${condition.substring(1)}',
                ),
                key: const ValueKey('outcome-condition'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
