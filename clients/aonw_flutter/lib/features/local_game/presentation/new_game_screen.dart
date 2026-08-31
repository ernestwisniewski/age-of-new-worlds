import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_menu_backdrop.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/map_presentation_controller.dart';
import '../application/local_game_catalog.dart';
import '../application/local_game_session_port.dart';
import 'local_game_launch_mode.dart';
import 'new_game_review_step.dart';
import 'new_game_setup_step.dart';

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
  var _scenario = LocalGameCatalog.entries.first;
  var _humanCountry = LocalPlayerCountryView.poland;
  var _opponentCountry = LocalPlayerCountryView.japan;
  var _difficulty = LocalAiDifficultyView.normal;
  var _persona = LocalAiPersonaView.balanced;
  var _fogEnabled = true;
  var _opponentControl = LocalPlayerControlView.ai;
  var _reviewing = false;
  var _starting = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMode == LocalGameLaunchModeView.hotseat) {
      _opponentControl = LocalPlayerControlView.human;
    }
  }

  LocalGameLaunchModeView get _actualMode =>
      _opponentControl == LocalPlayerControlView.human
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
    opponentCountry: _opponentCountry,
    opponentControl: _opponentControl,
    difficulty: _difficulty,
    persona: _persona,
    fogEnabled: _fogEnabled,
    onScenarioChanged: (value) => setState(() => _scenario = value),
    onHumanCountryChanged: _changeHumanCountry,
    onOpponentCountryChanged: _changeOpponentCountry,
    onOpponentControlChanged: (value) => setState(() {
      _opponentControl = value;
      _failed = false;
    }),
    onDifficultyChanged: (value) => setState(() => _difficulty = value),
    onPersonaChanged: (value) => setState(() => _persona = value),
    onFogChanged: (value) => setState(() => _fogEnabled = value),
    onContinue: () => setState(() {
      _reviewing = true;
      _failed = false;
    }),
  );

  Widget _reviewStep() => NewGameReviewStep(
    actualMode: _actualMode,
    scenario: _scenario,
    humanCountry: _humanCountry,
    opponentCountry: _opponentCountry,
    opponentControl: _opponentControl,
    difficulty: _difficulty,
    persona: _persona,
    fogEnabled: _fogEnabled,
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
      if (value == _opponentCountry) {
        _opponentCountry = _humanCountry;
      }
      _humanCountry = value;
    });
  }

  void _changeOpponentCountry(LocalPlayerCountryView value) {
    setState(() {
      if (value == _humanCountry) {
        _humanCountry = _opponentCountry;
      }
      _opponentCountry = value;
    });
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _failed = false;
    });
    final l10n = context.aonwL10n;
    final opponentIsAi = _opponentControl == LocalPlayerControlView.ai;
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
            name: opponentIsAi
                ? l10n.defaultAiName
                : l10n.defaultSecondPlayerName,
            colorValue: 0xffee6c4d,
            country: _opponentCountry,
            control: _opponentControl,
            ai: opponentIsAi
                ? LocalAiProfileView(
                    difficulty: _difficulty,
                    persona: _persona,
                    seed: DateTime.now().microsecondsSinceEpoch,
                  )
                : null,
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
