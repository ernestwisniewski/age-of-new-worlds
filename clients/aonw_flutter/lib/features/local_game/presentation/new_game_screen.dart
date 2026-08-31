import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/map_presentation_controller.dart';
import '../application/local_game_catalog.dart';
import '../application/local_game_session_port.dart';

final class NewGameScreen extends StatefulWidget {
  const NewGameScreen({
    required this.mapController,
    required this.onStarted,
    super.key,
  });

  final MapPresentationController mapController;
  final VoidCallback onStarted;

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

final class _NewGameScreenState extends State<NewGameScreen> {
  var _scenario = LocalGameCatalog.entries.first;
  var _humanCountry = LocalPlayerCountryView.poland;
  var _aiCountry = LocalPlayerCountryView.japan;
  var _difficulty = LocalAiDifficultyView.normal;
  var _persona = LocalAiPersonaView.balanced;
  var _fogEnabled = true;
  var _starting = false;
  var _failed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newGameTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AonwSpacing.md),
            child: AonwPanel(
              semanticLabel: l10n.newGameTitle,
              maxWidth: 560,
              padding: const EdgeInsets.all(AonwSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _scenarioField(l10n),
                  const SizedBox(height: AonwSpacing.md),
                  _countryField(
                    key: const ValueKey('human-country'),
                    label: l10n.humanCountryLabel,
                    value: _humanCountry,
                    onChanged: (value) => setState(() => _humanCountry = value),
                  ),
                  const SizedBox(height: AonwSpacing.md),
                  _countryField(
                    key: const ValueKey('ai-country'),
                    label: l10n.aiCountryLabel,
                    value: _aiCountry,
                    onChanged: (value) => setState(() => _aiCountry = value),
                  ),
                  const SizedBox(height: AonwSpacing.md),
                  _difficultyField(l10n),
                  const SizedBox(height: AonwSpacing.md),
                  _personaField(l10n),
                  const SizedBox(height: AonwSpacing.sm),
                  SwitchListTile.adaptive(
                    key: const ValueKey('fog-of-war'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.fogOfWarLabel),
                    value: _fogEnabled,
                    onChanged: _starting
                        ? null
                        : (value) => setState(() => _fogEnabled = value),
                  ),
                  if (_failed) ...[
                    const SizedBox(height: AonwSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.localGameStartFailed,
                        key: const ValueKey('new-game-failure'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AonwSpacing.lg),
                  FilledButton.icon(
                    key: const ValueKey('start-game'),
                    onPressed: _starting ? null : _start,
                    icon: _starting
                        ? const SizedBox.square(
                            dimension: AonwSizes.compactProgress,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_starting ? l10n.startingGame : l10n.startGame),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scenarioField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalGameCatalogEntryView>(
        key: ValueKey(('scenario', _scenario.id)),
        initialValue: _scenario,
        decoration: InputDecoration(labelText: l10n.scenarioLabel),
        items: [
          for (final entry in LocalGameCatalog.entries)
            DropdownMenuItem(
              value: entry,
              child: Text(l10n.localScenarioName(entry.id.name)),
            ),
        ],
        onChanged: _starting
            ? null
            : (value) => setState(() => _scenario = value!),
      );

  Widget _countryField({
    required Key key,
    required String label,
    required LocalPlayerCountryView value,
    required ValueChanged<LocalPlayerCountryView> onChanged,
  }) => DropdownButtonFormField<LocalPlayerCountryView>(
    key: ValueKey((key, value)),
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final country in LocalPlayerCountryView.values)
        DropdownMenuItem(
          value: country,
          child: Text(context.aonwL10n.countryName(country.name)),
        ),
    ],
    onChanged: _starting ? null : (value) => onChanged(value!),
  );

  Widget _difficultyField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalAiDifficultyView>(
        key: ValueKey(('difficulty', _difficulty)),
        initialValue: _difficulty,
        decoration: InputDecoration(labelText: l10n.aiDifficultyLabel),
        items: [
          for (final value in LocalAiDifficultyView.values)
            DropdownMenuItem(
              value: value,
              child: Text(l10n.aiDifficultyName(value.name)),
            ),
        ],
        onChanged: _starting
            ? null
            : (value) => setState(() => _difficulty = value!),
      );

  Widget _personaField(AonwLocalizations l10n) =>
      DropdownButtonFormField<LocalAiPersonaView>(
        key: ValueKey(('persona', _persona)),
        initialValue: _persona,
        decoration: InputDecoration(labelText: l10n.aiPersonaLabel),
        items: [
          for (final value in LocalAiPersonaView.values)
            DropdownMenuItem(
              value: value,
              child: Text(l10n.aiPersonaName(value.name)),
            ),
        ],
        onChanged: _starting
            ? null
            : (value) => setState(() => _persona = value!),
      );

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _failed = false;
    });
    final l10n = context.aonwL10n;
    final started = await widget.mapController.startLocalMatch(
      _scenario,
      LocalMatchSetupView(
        assets: _scenario.assets,
        participants: [
          LocalParticipantSetupView(
            id: 'player-1',
            name: l10n.defaultPlayerName,
            colorValue: 0xff3d5a80,
            country: _humanCountry,
            control: LocalPlayerControlView.human,
          ),
          LocalParticipantSetupView(
            id: 'player-2',
            name: l10n.defaultAiName,
            colorValue: 0xffee6c4d,
            country: _aiCountry,
            control: LocalPlayerControlView.ai,
            ai: LocalAiProfileView(
              difficulty: _difficulty,
              persona: _persona,
              seed: DateTime.now().microsecondsSinceEpoch,
            ),
          ),
        ],
        fogEnabled: _fogEnabled,
      ),
    );
    if (!mounted) return;
    if (started) {
      widget.onStarted();
      return;
    }
    setState(() {
      _starting = false;
      _failed = true;
    });
  }
}
