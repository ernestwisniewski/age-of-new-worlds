import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_menu_backdrop.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/map_presentation_controller.dart';
import '../application/local_game_catalog.dart';
import '../application/local_game_session_port.dart';
import 'local_game_launch_mode.dart';
import 'new_game_opponent_setup.dart';
import 'new_game_review_step.dart';
import 'new_game_setup_step.dart';

const _participantColors = [0xff3d5a80, 0xffee6c4d, 0xff4f772d, 0xfff4d35e];

const _defaultOpponentCountries = [
  LocalPlayerCountryView.japan,
  LocalPlayerCountryView.germany,
  LocalPlayerCountryView.france,
];

final class NewGameScreen extends StatefulWidget {
  const NewGameScreen({
    required this.mapController,
    required this.onStarted,
    this.initialMode = LocalGameLaunchModeView.singlePlayer,
    super.key,
  });

  final MapPresentationController mapController;
  final VoidCallback onStarted;
  final LocalGameLaunchModeView initialMode;

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

final class _NewGameScreenState extends State<NewGameScreen> {
  late LocalGameCatalogEntryView _scenario;
  var _humanCountry = LocalPlayerCountryView.poland;
  var _opponents = <NewGameOpponentView>[];
  var _fogEnabled = true;
  var _turnMode = LocalTurnModeView.sequential;
  var _reviewing = false;
  var _starting = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _scenario = widget.initialMode == LocalGameLaunchModeView.hotseat
        ? LocalGameCatalog.hotseatEntries.first
        : LocalGameCatalog.entries.first;
    _opponents = _initialOpponents(_scenario.opponentCount);
  }

  LocalGameLaunchModeView get _actualMode =>
      _opponents.any(
        (opponent) => opponent.control == LocalPlayerControlView.human,
      )
      ? LocalGameLaunchModeView.hotseat
      : LocalGameLaunchModeView.singlePlayer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final title = _reviewing
        ? l10n.gameSummaryTitle
        : widget.initialMode == LocalGameLaunchModeView.hotseat
        ? l10n.hotseatSetupTitle
        : l10n.singlePlayerSetupTitle;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: AonwMenuBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AonwSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _reviewing ? _reviewStep() : _setupStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setupStep() => NewGameSetupStep(
    launchMode: widget.initialMode,
    scenario: _scenario,
    humanCountry: _humanCountry,
    opponents: _opponents,
    fogEnabled: _fogEnabled,
    turnMode: _turnMode,
    onScenarioChanged: _changeScenario,
    onHumanCountryChanged: _changeHumanCountry,
    onOpponentCountryChanged: _changeOpponentCountry,
    onOpponentControlChanged: (index, value) =>
        _updateOpponent(index, (opponent) => opponent.copyWith(control: value)),
    onOpponentDifficultyChanged: (index, value) => _updateOpponent(
      index,
      (opponent) => opponent.copyWith(difficulty: value),
    ),
    onOpponentPersonaChanged: (index, value) =>
        _updateOpponent(index, (opponent) => opponent.copyWith(persona: value)),
    onFogChanged: (value) => setState(() => _fogEnabled = value),
    onTurnModeChanged: (value) => setState(() => _turnMode = value),
    onContinue: () => setState(() {
      _reviewing = true;
      _failed = false;
    }),
  );

  Widget _reviewStep() => NewGameReviewStep(
    actualMode: _actualMode,
    scenario: _scenario,
    humanCountry: _humanCountry,
    opponents: _opponents,
    fogEnabled: _fogEnabled,
    turnMode: widget.initialMode == LocalGameLaunchModeView.hotseat
        ? LocalTurnModeView.sequential
        : _turnMode,
    starting: _starting,
    failed: _failed,
    onBack: () => setState(() {
      _reviewing = false;
      _failed = false;
    }),
    onStart: _start,
  );

  void _changeHumanCountry(LocalPlayerCountryView value) {
    setState(() {
      final previous = _humanCountry;
      final conflict = _opponents.indexWhere(
        (opponent) => opponent.country == value,
      );
      if (conflict >= 0) {
        _opponents[conflict] = _opponents[conflict].copyWith(country: previous);
      }
      _humanCountry = value;
    });
  }

  void _changeOpponentCountry(int index, LocalPlayerCountryView value) {
    setState(() {
      if (value == _humanCountry) {
        _humanCountry = _opponents[index].country;
      } else {
        final conflict = _opponents.indexWhere(
          (opponent) => opponent.country == value,
        );
        if (conflict >= 0 && conflict != index) {
          _opponents[conflict] = _opponents[conflict].copyWith(
            country: _opponents[index].country,
          );
        }
      }
      _opponents[index] = _opponents[index].copyWith(country: value);
    });
  }

  void _changeScenario(LocalGameCatalogEntryView value) {
    setState(() {
      _scenario = value;
      _opponents = _resizedOpponents(value.opponentCount);
      _failed = false;
    });
  }

  void _updateOpponent(
    int index,
    NewGameOpponentView Function(NewGameOpponentView opponent) update,
  ) {
    setState(() {
      _opponents[index] = update(_opponents[index]);
      _failed = false;
    });
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _failed = false;
    });
    final l10n = context.aonwL10n;
    final seed = DateTime.now().microsecondsSinceEpoch;
    final started = await widget.mapController.startLocalMatch(
      _scenario,
      LocalMatchSetupView(
        assets: _scenario.assets,
        participants: [
          LocalParticipantSetupView(
            id: 'player-1',
            name: l10n.defaultPlayerName,
            colorValue: _participantColors.first,
            country: _humanCountry,
            control: LocalPlayerControlView.human,
          ),
          for (var index = 0; index < _opponents.length; index++)
            _participant(l10n, index, _opponents[index], seed),
        ],
        fogEnabled: _fogEnabled,
        turnMode: widget.initialMode == LocalGameLaunchModeView.hotseat
            ? LocalTurnModeView.sequential
            : _turnMode,
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

  LocalParticipantSetupView _participant(
    AonwLocalizations l10n,
    int opponentIndex,
    NewGameOpponentView opponent,
    int seed,
  ) {
    final participantIndex = opponentIndex + 1;
    final playerNumber = participantIndex + 1;
    final isAi = opponent.control == LocalPlayerControlView.ai;
    return LocalParticipantSetupView(
      id: _scenario.participantIds[participantIndex],
      name: isAi
          ? l10n.defaultNumberedAiName(playerNumber)
          : l10n.defaultNumberedPlayerName(playerNumber),
      colorValue: _participantColors[participantIndex],
      country: opponent.country,
      control: opponent.control,
      ai: isAi
          ? LocalAiProfileView(
              difficulty: opponent.difficulty,
              persona: opponent.persona,
              seed: seed + participantIndex,
            )
          : null,
    );
  }

  List<NewGameOpponentView> _initialOpponents(int count) => [
    for (var index = 0; index < count; index++)
      NewGameOpponentView(
        country: _defaultOpponentCountries[index],
        control:
            widget.initialMode == LocalGameLaunchModeView.hotseat && index == 0
            ? LocalPlayerControlView.human
            : LocalPlayerControlView.ai,
        difficulty: LocalAiDifficultyView.normal,
        persona: LocalAiPersonaView.balanced,
      ),
  ];

  List<NewGameOpponentView> _resizedOpponents(int count) {
    final resized = _opponents.take(count).toList();
    while (resized.length < count) {
      final used = {_humanCountry, ...resized.map((item) => item.country)};
      final country = LocalPlayerCountryView.values.firstWhere(
        (candidate) => !used.contains(candidate),
      );
      final index = resized.length;
      resized.add(
        NewGameOpponentView(
          country: country,
          control:
              widget.initialMode == LocalGameLaunchModeView.hotseat &&
                  index == 0
              ? LocalPlayerControlView.human
              : LocalPlayerControlView.ai,
          difficulty: LocalAiDifficultyView.normal,
          persona: LocalAiPersonaView.balanced,
        ),
      );
    }
    return resized;
  }
}
