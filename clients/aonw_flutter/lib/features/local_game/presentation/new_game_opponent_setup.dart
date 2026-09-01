import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/local_game_session_port.dart';
import 'local_game_launch_mode.dart';

final class NewGameOpponentView {
  const NewGameOpponentView({
    required this.country,
    required this.control,
    required this.difficulty,
    required this.persona,
  });

  final LocalPlayerCountryView country;
  final LocalPlayerControlView control;
  final LocalAiDifficultyView difficulty;
  final LocalAiPersonaView persona;

  NewGameOpponentView copyWith({
    LocalPlayerCountryView? country,
    LocalPlayerControlView? control,
    LocalAiDifficultyView? difficulty,
    LocalAiPersonaView? persona,
  }) => NewGameOpponentView(
    country: country ?? this.country,
    control: control ?? this.control,
    difficulty: difficulty ?? this.difficulty,
    persona: persona ?? this.persona,
  );
}

final class NewGameOpponentSetup extends StatelessWidget {
  const NewGameOpponentSetup({
    required this.launchMode,
    required this.opponents,
    required this.onCountryChanged,
    required this.onControlChanged,
    required this.onDifficultyChanged,
    required this.onPersonaChanged,
    super.key,
  });

  final LocalGameLaunchModeView launchMode;
  final List<NewGameOpponentView> opponents;
  final void Function(int index, LocalPlayerCountryView value) onCountryChanged;
  final void Function(int index, LocalPlayerControlView value) onControlChanged;
  final void Function(int index, LocalAiDifficultyView value)
  onDifficultyChanged;
  final void Function(int index, LocalAiPersonaView value) onPersonaChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < opponents.length; index++) ...[
        _OpponentCard(
          index: index,
          launchMode: launchMode,
          opponent: opponents[index],
          onCountryChanged: (value) => onCountryChanged(index, value),
          onControlChanged: (value) => onControlChanged(index, value),
          onDifficultyChanged: (value) => onDifficultyChanged(index, value),
          onPersonaChanged: (value) => onPersonaChanged(index, value),
        ),
        if (index + 1 < opponents.length)
          const SizedBox(height: AonwSpacing.md),
      ],
    ],
  );
}

final class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.index,
    required this.launchMode,
    required this.opponent,
    required this.onCountryChanged,
    required this.onControlChanged,
    required this.onDifficultyChanged,
    required this.onPersonaChanged,
  });

  final int index;
  final LocalGameLaunchModeView launchMode;
  final NewGameOpponentView opponent;
  final ValueChanged<LocalPlayerCountryView> onCountryChanged;
  final ValueChanged<LocalPlayerControlView> onControlChanged;
  final ValueChanged<LocalAiDifficultyView> onDifficultyChanged;
  final ValueChanged<LocalAiPersonaView> onPersonaChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AonwRadii.panel),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.md),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.opponentNumberLabel(index + 1),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (launchMode == LocalGameLaunchModeView.hotseat) ...[
          const SizedBox(height: AonwSpacing.sm),
          _controlField(l10n),
        ],
        const SizedBox(height: AonwSpacing.md),
        _countryField(l10n),
        if (opponent.control == LocalPlayerControlView.ai) ...[
          const SizedBox(height: AonwSpacing.md),
          _difficultyField(l10n),
          const SizedBox(height: AonwSpacing.md),
          _personaField(l10n),
        ],
      ],
    );
  }

  Widget _controlField(AonwLocalizations l10n) =>
      SegmentedButton<LocalPlayerControlView>(
        key: index == 0
            ? const ValueKey('opponent-control')
            : ValueKey(('opponent-control', index)),
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
        selected: {opponent.control},
        onSelectionChanged: (values) => onControlChanged(values.single),
      );

  Widget _countryField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalPlayerCountryView>(
        key: ValueKey(('opponent-country', index, opponent.country)),
        initialValue: opponent.country,
        decoration: InputDecoration(
          labelText: opponent.control == LocalPlayerControlView.ai
              ? l10n.aiCountryLabel
              : l10n.humanCountryLabel,
        ),
        items: [
          for (final country in LocalPlayerCountryView.values)
            DropdownMenuItem(
              value: country,
              child: Text(l10n.countryName(country.name)),
            ),
        ],
        onChanged: (value) => onCountryChanged(value!),
      );

  Widget _difficultyField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalAiDifficultyView>(
        key: ValueKey(('difficulty', index, opponent.difficulty)),
        initialValue: opponent.difficulty,
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
        key: ValueKey(('persona', index, opponent.persona)),
        initialValue: opponent.persona,
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
}
