// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AonwLocalizationsEn extends AonwLocalizations {
  AonwLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String get mainMenuTitle => 'Main menu';

  @override
  String get mainMenuWelcome =>
      'Welcome to the Age of New Worlds. Build cities, lead commanders, discover new lands, and write the history of your civilization.';

  @override
  String get mainMenuSynopsisTitle => 'Build · Research · Command';

  @override
  String get mainMenuWhatsNew => 'What\'s new';

  @override
  String get singlePlayer => 'Single player';

  @override
  String get singlePlayerSublabel => 'Play against the computer';

  @override
  String get multiplayerSublabel => 'Play online';

  @override
  String get hotseat => 'Hotseat';

  @override
  String get hotseatSublabel => 'Players sharing one device';

  @override
  String get hotseatUnavailable => 'Hotseat setup is not available yet.';

  @override
  String get hotseatHandoffTitle => 'Pass the device';

  @override
  String hotseatHandoffBody(String name) {
    return 'Give the device to $name. Their map remains hidden until they confirm.';
  }

  @override
  String hotseatContinueAs(String name) {
    return 'Continue as $name';
  }

  @override
  String get hotseatHandoffSwitching => 'Preparing the next player';

  @override
  String get hotseatHandoffFailure =>
      'The next local player could not be opened safely.';

  @override
  String get loadGame => 'Load game';

  @override
  String get loadGameSublabel => 'Saved games and replays';

  @override
  String get exitGame => 'Exit';

  @override
  String get instructions => 'Manual';

  @override
  String get creditsTitle => 'Credits';

  @override
  String creditsCreatedBy(String name) {
    return 'Created by $name';
  }

  @override
  String get devlogLinkLabel => 'Development journal: ernest.dev';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackDescription =>
      'Share ideas, report problems and follow development with the Age of New Worlds community.';

  @override
  String get openFeedback => 'Open r/aonw';

  @override
  String get externalLinkUnavailable =>
      'External links are unavailable on this platform.';

  @override
  String get serverUpdateSoon =>
      'A newer version is ready and will appear on this platform soon. Check your store or launcher again shortly.';

  @override
  String get continueGame => 'Continue';

  @override
  String get resumingGame => 'Resuming game';

  @override
  String get newGame => 'New game';

  @override
  String get multiplayerTitle => 'Multiplayer';

  @override
  String get multiplayerUnavailable =>
      'Multiplayer is unavailable in this build.';

  @override
  String get loadingMultiplayer => 'Connecting to multiplayer';

  @override
  String get multiplayerAuthenticationTitle => 'AoNW account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get invalidPassword => 'Use at least 12 characters.';

  @override
  String get invalidDisplayName => 'Enter a display name.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get createAccount => 'Create account';

  @override
  String get createNewAccount => 'Create a new account';

  @override
  String get useExistingAccount => 'Use an existing account';

  @override
  String get multiplayerLobbyTitle => 'Match lobby';

  @override
  String signedInAccount(String userId) {
    return 'Account: $userId';
  }

  @override
  String get multiplayerSetupTitle => 'Create online game';

  @override
  String get multiplayerSetupIntro =>
      'Choose your civilization and map before opening the authoritative waiting room.';

  @override
  String get multiplayerTurnModeDescription =>
      'All players act during one shared turn. The engine resolves it after every required submission or the authoritative timeout.';

  @override
  String get continueToLobby => 'Continue to lobby';

  @override
  String get createMultiplayerMatch => 'Create match';

  @override
  String get joinMultiplayerMatch => 'Join match';

  @override
  String get matchIdLabel => 'Match ID';

  @override
  String get playerSeatLabel => 'Player seat';

  @override
  String get playerSeatOne => 'Player one';

  @override
  String get playerSeatTwo => 'Player two';

  @override
  String playerSeatNumber(int number) {
    return 'Player $number';
  }

  @override
  String get refreshMatches => 'Refresh matches';

  @override
  String get yourMatches => 'Your matches';

  @override
  String get noMultiplayerMatches => 'No joined matches yet.';

  @override
  String matchRevision(int revision, int eventOffset) {
    return 'Revision $revision · event offset $eventOffset';
  }

  @override
  String multiplayerMatchPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'lobby': 'waiting room',
      'running': 'in progress',
      'finished': 'finished',
      'abandoned': 'abandoned',
      'other': 'unknown',
    });
    return 'Status: $_temp0';
  }

  @override
  String get multiplayerWaitingRoomTitle => 'Match waiting room';

  @override
  String get multiplayerReady => 'Ready';

  @override
  String get multiplayerNotReady => 'Not ready';

  @override
  String get multiplayerSeatOpen => 'Open player seat';

  @override
  String get multiplayerHumanSeat => 'Human';

  @override
  String get multiplayerAiSeat => 'Computer';

  @override
  String get multiplayerHost => 'Host';

  @override
  String get multiplayerCurrentPlayer => 'You';

  @override
  String get markReady => 'Mark ready';

  @override
  String get markNotReady => 'Withdraw readiness';

  @override
  String get waitingForPlayers =>
      'Every human seat must be claimed and ready before the match starts.';

  @override
  String get refreshMatch => 'Refresh match';

  @override
  String get leaveMultiplayerMatch => 'Leave match';

  @override
  String get multiplayerResignTitle => 'Resign from this match?';

  @override
  String get multiplayerResignBody =>
      'Your participation will end immediately and this action cannot be undone.';

  @override
  String get multiplayerResignConfirm => 'Resign';

  @override
  String get multiplayerMatchTitle => 'Online match';

  @override
  String get multiplayerParticipants => 'Participants';

  @override
  String get multiplayerRemoveParticipant => 'Remove';

  @override
  String get multiplayerRemoveParticipantTitle => 'Remove participant?';

  @override
  String multiplayerRemoveParticipantBody(String name) {
    return 'Remove $name from this match? They will no longer be able to reconnect.';
  }

  @override
  String get cancelDialog => 'Cancel';

  @override
  String matchIdentifier(String matchId) {
    return 'Match: $matchId';
  }

  @override
  String playerIdentifier(String playerId) {
    return 'Player: $playerId';
  }

  @override
  String multiplayerTurn(int turn) {
    return 'Turn $turn';
  }

  @override
  String multiplayerSubmissionProgress(int submitted, int required) {
    return 'Submitted $submitted of $required';
  }

  @override
  String visibleUnits(int count) {
    return 'Visible units: $count';
  }

  @override
  String networkPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'connecting': 'connecting',
      'ready': 'online',
      'reconnecting': 'reconnecting',
      'resyncing': 'synchronizing',
      'failed': 'offline',
      'closed': 'closed',
      'other': 'unavailable',
    });
    return 'Connection: $_temp0';
  }

  @override
  String get submitTurn => 'Submit turn';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get backToLobby => 'Back to lobby';

  @override
  String multiplayerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'client_update_required': 'Update the client before connecting.',
      'authentication_required': 'Sign in again to continue.',
      'invalid_authentication_response':
          'The authentication response was invalid.',
      'authentication_identity_changed':
          'The account identity changed during refresh.',
      'connection_interrupted':
          'The connection was interrupted. Reconnect to synchronize the match.',
      'invalid_server_response': 'The server response failed validation.',
      'invalid_command_sequence': 'The command sequence was not contiguous.',
      'invalid_resync_sequence': 'The synchronized state moved backwards.',
      'invalid_match_lifecycle':
          'The match lifecycle response was inconsistent.',
      'match_not_found': 'The match was not found.',
      'match_not_started': 'The match has not been started by its host.',
      'match_already_started': 'The match has already started.',
      'host_required': 'Only the host can perform this action.',
      'lobby_not_ready': 'Every human player must join and be ready.',
      'participant_not_claimable':
          'Computer-controlled seats cannot be claimed.',
      'participant_not_active': 'That participant is no longer active.',
      'invalid_kick_target': 'The host cannot remove itself.',
      'player_seat_taken': 'That player seat is already occupied.',
      'other': 'The multiplayer request could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String get helpTitle => 'How to play';

  @override
  String get helpIntroduction =>
      'Build a civilization turn by turn. The engine resolves every rule; this guide explains the decisions available in the client.';

  @override
  String get helpObjectiveTitle => 'Pursue the objective';

  @override
  String get helpObjectiveBody =>
      'Expand, develop cities and complete the scenario objectives before your opponent. Open Strategic objectives on the map to review the authored goals.';

  @override
  String get helpMapTitle => 'Explore and command';

  @override
  String get helpMapBody =>
      'Select a visible hex to inspect it. Select your unit, choose a highlighted destination and confirm the route. Keyboard, gamepad and touch controls use the same commands.';

  @override
  String get helpDevelopmentTitle => 'Develop your civilization';

  @override
  String get helpDevelopmentBody =>
      'Use city, research, production, worker, logistics, artifact and diplomacy panels when their actions become available.';

  @override
  String get helpTurnTitle => 'End the turn deliberately';

  @override
  String get helpTurnBody =>
      'Finish your actions, then end the turn. The computer completes its authoritative turn before control returns to you.';

  @override
  String get helpSaveReplayTitle => 'Save and review';

  @override
  String get helpSaveReplayBody =>
      'Save from the map. Continue opens the latest valid save, and Replay reviews the authoritative command history without changing the game.';

  @override
  String get startOnboarding => 'Start guided introduction';

  @override
  String get onboardingTitle => 'Guided introduction';

  @override
  String onboardingProgress(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get onboardingExploreTitle => 'Read the map';

  @override
  String get onboardingExploreBody =>
      'The map shows only information visible to your player. Select hexes to inspect terrain, cities and units, then pan or zoom to plan your next action.';

  @override
  String get onboardingCommandTitle => 'Give precise commands';

  @override
  String get onboardingCommandBody =>
      'Available destinations and actions come from the game engine. Choose one, review the preview and confirm; rejected or stale commands never change the match.';

  @override
  String get onboardingDevelopTitle => 'Build a long-term advantage';

  @override
  String get onboardingDevelopBody =>
      'Cities, production, research, workers, logistics, artifacts and diplomacy shape your strategy. Their panels expose only actions currently allowed by the engine.';

  @override
  String get onboardingContinueTitle => 'Continue with confidence';

  @override
  String get onboardingContinueBody =>
      'Save the authoritative match before leaving. Continue validates it in a fresh engine session, while Replay provides a read-only review of the same history.';

  @override
  String get previousOnboardingStep => 'Previous';

  @override
  String get nextOnboardingStep => 'Next';

  @override
  String get skipOnboarding => 'Skip';

  @override
  String get finishOnboarding => 'Create a game';

  @override
  String get newGameTitle => 'Create local game';

  @override
  String get singlePlayerSetupTitle => 'Play with the computer';

  @override
  String get singlePlayerSetupIntro =>
      'Choose your civilization and configure an authoritative local match.';

  @override
  String get hotseatSetupTitle => 'Play in hotseat mode';

  @override
  String get hotseatSetupIntro =>
      'Share one device. Every human view stays hidden until the next player confirms the handoff.';

  @override
  String get chooseCivilizationTitle => 'Choose civilization';

  @override
  String get gameSetupTitle => 'Game setup';

  @override
  String get turnModeTitle => 'Turn mode';

  @override
  String turnModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'sequential': 'Traditional',
      'simultaneous': 'Simultaneous',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get turnModeSequentialDescription =>
      'Civilizations complete and resolve their turns one after another.';

  @override
  String get turnModeSimultaneousDescription =>
      'You and the computer act within one shared turn before the engine resolves its common phases.';

  @override
  String get opponentsTitle => 'Opponents';

  @override
  String get opponentControlLabel => 'Opponent control';

  @override
  String opponentNumberLabel(int number) {
    return 'Opponent $number';
  }

  @override
  String get humanOpponent => 'Human player';

  @override
  String get aiOpponent => 'Computer';

  @override
  String get mapSetupTitle => 'Map';

  @override
  String get mapSetupBody =>
      'A compact authored 7 × 7 map for a focused two-civilization match.';

  @override
  String mapSetupDetails(String mapName, int columns, int rows, int players) {
    return '$mapName · $columns × $rows · $players civilizations';
  }

  @override
  String get victoryPathsTitle => 'Victory paths';

  @override
  String get victoryPathsBody =>
      'Conquest, domination, culture and score are resolved by the game engine.';

  @override
  String get settlementToEmpireTitle => 'From settlement to empire';

  @override
  String get settlementToEmpireBody =>
      'Explore, found cities, research, produce armies and build lasting advantages.';

  @override
  String get continueToSummary => 'Continue to summary';

  @override
  String get gameSummaryTitle => 'Expedition ready';

  @override
  String get gameSummaryIntro =>
      'Review every local participant before creating the match.';

  @override
  String get summaryModeLabel => 'Mode';

  @override
  String get summaryTurnModeLabel => 'Turns';

  @override
  String get summaryCivilizationLabel => 'Your civilization';

  @override
  String get summaryOpponentLabel => 'Opponent';

  @override
  String get summaryMapLabel => 'Map';

  @override
  String get summaryFogLabel => 'Fog of war';

  @override
  String get summaryAiLabel => 'Computer profile';

  @override
  String get changeSetup => 'Change setup';

  @override
  String localModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'singlePlayer': 'Single player',
      'hotseat': 'Hotseat',
      'other': 'Local game',
    });
    return '$_temp0';
  }

  @override
  String participantControlName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'human': 'Human',
      'ai': 'Computer',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String fogSettingName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get defaultSecondPlayerName => 'Player 2';

  @override
  String defaultNumberedPlayerName(int number) {
    return 'Player $number';
  }

  @override
  String defaultNumberedAiName(int number) {
    return 'Computer $number';
  }

  @override
  String get scenarioLabel => 'Map';

  @override
  String localScenarioName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'starterDuel': 'Starter',
      'dravonia': 'Dravonia',
      'myranth': 'Myranth',
      'terenos': 'Terenos',
      'verdantia': 'Verdantia',
      'other': 'Local map',
    });
    return '$_temp0';
  }

  @override
  String get humanCountryLabel => 'Your country';

  @override
  String get aiCountryLabel => 'AI country';

  @override
  String get aiDifficultyLabel => 'AI difficulty';

  @override
  String get aiPersonaLabel => 'AI personality';

  @override
  String get fogOfWarLabel => 'Fog of war';

  @override
  String get startGame => 'Start game';

  @override
  String get startingGame => 'Starting game';

  @override
  String get localGameStartFailed => 'The local game could not be started.';

  @override
  String get saveGame => 'Save game';

  @override
  String get savingGame => 'Saving game';

  @override
  String get gameSaved => 'Game saved';

  @override
  String saveFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Saving is unavailable for this session.',
      'exportFailed': 'The game could not be exported.',
      'writeFailed': 'The save file could not be stored.',
      'other': 'The game could not be saved.',
    });
    return '$_temp0';
  }

  @override
  String resumeFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Saved games are unavailable on this platform.',
      'missing': 'No saved game was found.',
      'unreadable': 'The saved game could not be read.',
      'incompatible':
          'The saved game is invalid or incompatible with the current game.',
      'other': 'The saved game could not be resumed.',
    });
    return '$_temp0';
  }

  @override
  String get loadGameTitle => 'Load game';

  @override
  String get loadGameEmpty => 'No saved games were found.';

  @override
  String loadGameSingleLabel(String scenario) {
    return 'Single player · $scenario';
  }

  @override
  String get importSave => 'Import save';

  @override
  String get exportSave => 'Export';

  @override
  String get saveTransferUnavailable =>
      'Save import and export are unavailable on this platform.';

  @override
  String saveImportCompleted(String map) {
    return 'Imported $map as a separate saved game.';
  }

  @override
  String saveExportCompleted(String map) {
    return 'Exported $map.';
  }

  @override
  String saveTransferFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Save transfer is unavailable on this platform.',
      'unreadable': 'The selected save file could not be read.',
      'tooLarge': 'The selected save file exceeds the 16 MiB limit.',
      'incompatible':
          'The selected save is invalid or does not match an installed map, ruleset, or engine version.',
      'missing': 'The selected saved game no longer exists.',
      'writeFailed': 'The imported save could not be stored.',
      'exportFailed': 'The save file could not be exported.',
      'other': 'The save transfer could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String get replayTitle => 'Replay';

  @override
  String get loadingReplay => 'Loading replay';

  @override
  String get replayUnavailable => 'Replay playback is unavailable.';

  @override
  String replayFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Replay playback is unavailable on this platform.',
      'missing': 'No replay was found. Save a local game first.',
      'unreadable': 'The replay file could not be read.',
      'incompatible':
          'The replay is invalid or incompatible with the current game.',
      'seekFailed': 'The requested replay frame could not be loaded.',
      'other': 'The replay could not be opened.',
    });
    return '$_temp0';
  }

  @override
  String get replayMapLabel => 'Replay map';

  @override
  String get replayControls => 'Replay controls';

  @override
  String get playReplay => 'Play replay';

  @override
  String get pauseReplay => 'Pause replay';

  @override
  String get backToMenu => 'Back to main menu';

  @override
  String replayProgress(int position, int entryCount) {
    return '$position of $entryCount';
  }

  @override
  String replaySpeed(String value) {
    return '$value× speed';
  }

  @override
  String get aiTurnRunning => 'The computer is taking its turn.';

  @override
  String aiTurnFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'requestFailed': 'The computer turn could not be completed.',
      'responseIncompatible':
          'The computer turn response is incompatible with this client.',
      'incomplete':
          'The computer did not complete its turn within the safe command budget.',
      'other': 'The computer turn could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String get defaultPlayerName => 'Player';

  @override
  String get defaultAiName => 'Computer';

  @override
  String countryName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'poland': 'Poland',
      'ukraine': 'Ukraine',
      'germany': 'Germany',
      'france': 'France',
      'unitedKingdom': 'United Kingdom',
      'italy': 'Italy',
      'spain': 'Spain',
      'netherlands': 'Netherlands',
      'sweden': 'Sweden',
      'russia': 'Russia',
      'unitedStates': 'United States',
      'canada': 'Canada',
      'china': 'China',
      'korea': 'Korea',
      'japan': 'Japan',
      'portugal': 'Portugal',
      'india': 'India',
      'brazil': 'Brazil',
      'indonesia': 'Indonesia',
      'mexico': 'Mexico',
      'turkey': 'Turkey',
      'saudiArabia': 'Saudi Arabia',
      'egypt': 'Egypt',
      'greece': 'Greece',
      'other': 'Unknown country',
    });
    return '$_temp0';
  }

  @override
  String aiDifficultyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'easy': 'Easy',
      'normal': 'Normal',
      'hard': 'Hard',
      'veryHard': 'Very hard',
      'other': 'Unknown difficulty',
    });
    return '$_temp0';
  }

  @override
  String aiPersonaName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'balanced': 'Balanced',
      'aggressive': 'Aggressive',
      'expansive': 'Expansive',
      'economic': 'Economic',
      'scientific': 'Scientific',
      'other': 'Unknown personality',
    });
    return '$_temp0';
  }

  @override
  String get unknownRouteLabel => 'Unknown route';

  @override
  String get pageUnavailable => 'Page unavailable';

  @override
  String unknownRouteMessage(String location) {
    return 'Unknown route: $location';
  }

  @override
  String get missingRouteLocation => '(missing)';

  @override
  String mapSemanticsLabel(String mapId, int cols, int rows) {
    return 'Map $mapId, $cols by $rows hexes';
  }

  @override
  String get mapInputHint =>
      'Use the arrow keys or D-pad to move the map cursor and Enter or A to select.';

  @override
  String get noHexSelected => 'No hex selected';

  @override
  String selectedHex(int col, int row) {
    return 'Selected hex $col, $row';
  }

  @override
  String get mapViewModeTooltip => 'Change map view mode';

  @override
  String get mapViewGraphicUnavailable =>
      'Graphic view is unavailable for this map.';

  @override
  String get mapViewModeGraphic => 'Graphic';

  @override
  String get mapViewModeTiles => 'Tiles';

  @override
  String hexLabel(int col, int row) {
    return 'Hex $col, $row';
  }

  @override
  String get selectionTerrain => 'Terrain';

  @override
  String unitLabel(String unitId) {
    return 'Unit $unitId';
  }

  @override
  String routeSummary(int totalCost, int remaining) {
    return 'Route: $totalCost movement units · $remaining remaining';
  }

  @override
  String get confirmMove => 'Confirm move';

  @override
  String moveTurnCost(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns turns',
      one: '1 turn',
    );
    return '$_temp0';
  }

  @override
  String confirmMoveWithCost(String turnCost) {
    return 'Confirm · $turnCost';
  }

  @override
  String get chooseHighlightedDestination =>
      'Choose a highlighted destination.';

  @override
  String get movingUnit => 'Moving unit';

  @override
  String unitActionLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'title': 'Unit actions',
      'fortify': 'Fortify',
      'skip': 'Skip',
      'cancel': 'Cancel action',
      'executing': 'Executing unit action',
      'logisticsTitle': 'Logistics',
      'logisticsLoading': 'Loading logistics options',
      'logisticsEmpty': 'No logistics actions are currently available.',
      'autoExplore': 'Auto explore',
      'merchantRoute': 'Assign trade route',
      'merchantTravel': 'Move to city',
      'detachTroop': 'Detach troop',
      'other': 'Unit action',
    });
    return '$_temp0';
  }

  @override
  String unitActionFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'The unit action request could not be completed.',
      'responseIncompatible':
          'The unit action response is incompatible with this client.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'stale': 'The game state changed. Review the unit and try again.',
      'matchFinished': 'The match has already finished.',
      'unitUnavailable': 'That unit is no longer available to command.',
      'unitBusy': 'That unit is busy and cannot perform this action now.',
      'internal': 'The unit action could not be applied. Try again.',
      'logisticsRequestFailed': 'The logistics request could not be completed.',
      'logisticsResponseIncompatible':
          'The logistics response is incompatible with this client.',
      'logisticsOptionUnavailable':
          'That logistics option is no longer available.',
      'combatFailureRequestFailed':
          'The combat request could not be completed.',
      'combatFailureResponseIncompatible':
          'The combat response is incompatible with this client.',
      'combatFailureSessionUnavailable':
          'The local game session is unavailable.',
      'combatFailureTargetUnavailable':
          'No attack preview is available for that target.',
      'combatFailureStaleRevision':
          'The game state changed. Review it and try again.',
      'combatFailureMatchFinished': 'The match has already finished.',
      'combatFailureAttackerNotFound':
          'The attacking unit is no longer available.',
      'combatFailureAttackerNotControlled':
          'The attacking unit is not controlled by this player.',
      'combatFailureAttackerUnavailable': 'The attacking unit is unavailable.',
      'combatFailureAttackerExhausted': 'The attacking unit is exhausted.',
      'combatFailureAttackerOutOfBounds':
          'The attacking unit is outside the map.',
      'combatFailureAttackerCannotAttack': 'That unit cannot attack.',
      'combatFailureAttackTargetNotVisible': 'The target is not visible.',
      'combatFailureAttackTargetOutOfBounds': 'The target is outside the map.',
      'combatFailureAttackTargetNotFound': 'No target is present there.',
      'combatFailureAttackTargetNotEnemy': 'That target is not an enemy.',
      'combatFailureAttackTargetProtectedByTreaty':
          'A treaty protects that target.',
      'combatFailureAttackTargetOutOfRange': 'The target is out of range.',
      'combatFailureAttackCityHasNoHealth': 'That city cannot be attacked.',
      'other': 'The unit action could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String turnSummary(String kind, int turn, int submitted, int required) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'label': 'TURN $turn',
      'progress': 'Ready: $submitted of $required',
      'other': 'TURN $turn',
    });
    return '$_temp0';
  }

  @override
  String turnText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'statusActive': 'Your turn',
      'statusFinished': 'Turn finished',
      'statusSubmitted': 'Turn submitted',
      'statusWaiting': 'Waiting',
      'statusPendingAction': 'Action required',
      'actionEnd': 'End turn',
      'actionEnding': 'Ending turn',
      'outcomeConquest': 'Conquest victory',
      'outcomeDomination': 'Domination victory',
      'outcomeCultural': 'Cultural victory',
      'outcomeScore': 'Score victory',
      'outcomeResignation': 'Match ended by resignation',
      'outcomeDraw': 'Draw',
      'outcomeOngoing': 'Match in progress',
      'activityTitle': 'Activity',
      'activityArtifact': 'Artifact activity',
      'activityCity': 'City activity',
      'activityResearch': 'Research progress',
      'activityObjective': 'Strategic objective update',
      'activityOutcome': 'Match outcome updated',
      'activityCombat': 'Combat activity',
      'activityDiplomacy': 'Diplomatic activity',
      'activityUnit': 'Unit activity',
      'activityTurn': 'Turn updated',
      'activityWorker': 'Worker job completed',
      'combatTitle': 'Combat',
      'combatLoading': 'Loading combat preview',
      'combatTarget': 'Target',
      'combatDistance': 'Distance',
      'combatOutgoing': 'Outgoing damage',
      'combatRetaliation': 'Retaliation damage',
      'combatNone': 'None',
      'combatCapture': 'Capture city',
      'combatDestroy': 'Destroy city',
      'combatConfirm': 'Confirm attack',
      'combatExecuting': 'Resolving combat',
      'combatResolved': 'Combat resolved',
      'combatAttackerHp': 'Attacker health',
      'combatDefenderHp': 'Defender health',
      'combatEventUnitAttacked': 'Unit attacked',
      'combatEventCityAttacked': 'City attacked',
      'combatEventCombatResolved': 'Combat resolved',
      'combatEventUnitGainedExperience': 'Unit gained experience',
      'combatEventUnitKilled': 'Unit defeated',
      'combatEventUnitRetreated': 'Unit retreated',
      'combatEventCityCaptured': 'City captured',
      'combatEventCityDestroyed': 'City destroyed',
      'combatEventDiplomaticScoreChanged': 'Diplomatic relation changed',
      'other': 'Game activity',
    });
    return '$_temp0';
  }

  @override
  String turnFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'The turn request could not be completed.',
      'responseIncompatible':
          'The turn response is incompatible with this client.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'stale_revision': 'The game state changed. Review it and try again.',
      'match_finished': 'The match has already finished.',
      'turn_player_not_controlled': 'This player cannot end the current turn.',
      'turn_player_not_active': 'This player is not active.',
      'turn_scope_invalid': 'The current turn scope is invalid.',
      'turn_processor_unsupported': 'A required turn processor is unavailable.',
      'turn_number_overflow': 'The next turn cannot be represented.',
      'state_revision_overflow': 'The game revision cannot be advanced.',
      'other': 'The turn could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String get loadingMap => 'Loading map';

  @override
  String get mapLoadingFailed => 'Map loading failed';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get mapAdapterUnavailable =>
      'The native game adapter is unavailable on this platform.';

  @override
  String get mapClientIncompatible =>
      'The native game adapter is incompatible with this client.';

  @override
  String get mapLoadSuperseded => 'A newer map request replaced this one.';

  @override
  String get mapLoadFailure => 'The map could not be loaded.';

  @override
  String get movementRequestFailed =>
      'The movement request could not be completed.';

  @override
  String get movementResponseIncompatible =>
      'The movement response is incompatible with this client.';

  @override
  String get movementSessionUnavailable =>
      'The local game session is unavailable.';

  @override
  String get moveRejectedStale =>
      'The game state changed. Review the latest position and try again.';

  @override
  String get moveRejectedUnitUnavailable =>
      'That unit is no longer available to move.';

  @override
  String get moveRejectedUnitBusy => 'That unit is busy and cannot move now.';

  @override
  String get moveRejectedTargetUnavailable =>
      'That destination is not available.';

  @override
  String get moveRejectedMovementInsufficient =>
      'The unit does not have enough movement remaining.';

  @override
  String get moveRejectedPathUnavailable =>
      'No valid route to that destination is available.';

  @override
  String get moveRejectedInternal =>
      'The move could not be applied. Try again.';

  @override
  String get retry => 'Retry';

  @override
  String get openSettings => 'Open settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get audioSettings => 'Audio';

  @override
  String get masterVolume => 'Master volume';

  @override
  String get cameraSettings => 'Camera';

  @override
  String get cameraSensitivity => 'Zoom sensitivity';

  @override
  String get animationSettings => 'Animations';

  @override
  String get showUnitMovementAnimations => 'Show unit movement animations';

  @override
  String get showCombatAnimations => 'Show combat animations';

  @override
  String get cinematicCamera => 'Cinematic camera';

  @override
  String get smoothCameraMovement => 'Smooth camera movement';

  @override
  String get mapSettings => 'Map';

  @override
  String get mapGrid => 'Hex borders';

  @override
  String get mapGridDescription => 'Show black borders around map hexes.';

  @override
  String get mapResourceIcons => 'Resource icons';

  @override
  String get mapResourceIconsDescription =>
      'Show resources available on map hexes.';

  @override
  String get mapTerrainIcons => 'Terrain icons';

  @override
  String get mapTerrainIconsDescription =>
      'Show the terrain tags assigned to each hex.';

  @override
  String get mapHeightBadges => 'Height labels';

  @override
  String get mapHeightBadgesDescription =>
      'Show the authored height of raised hexes.';

  @override
  String get mapElevationWalls => 'Elevation walls';

  @override
  String get mapElevationWallsDescription =>
      'Show neighbor-aware depth on raised hexes.';

  @override
  String get accessibilitySettings => 'Accessibility';

  @override
  String get reducedMotion => 'Reduce motion';

  @override
  String get reducedMotionDescription =>
      'Avoid nonessential animations and transitions.';

  @override
  String get highContrast => 'High contrast';

  @override
  String get highContrastDescription =>
      'Increase contrast in the application interface.';

  @override
  String get resetSettings => 'Restore defaults';

  @override
  String get objectivesTitle => 'Strategic objectives';

  @override
  String get openObjectives => 'Open objectives';

  @override
  String get closeObjectives => 'Close objectives';

  @override
  String get objectivesEmpty => 'This map has no objectives.';

  @override
  String get objectivesAuthoredRules =>
      'Authored map requirements. Current progress remains in the engine.';

  @override
  String objectiveType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'ruins': 'Ruins',
      'strategicPass': 'Strategic pass',
      'holySite': 'Holy site',
      'legendaryResource': 'Legendary resource',
      'other': 'Strategic objective',
    });
    return '$_temp0';
  }

  @override
  String objectiveDetails(
    int col,
    int row,
    int holdTurns,
    int victoryPoints,
    int goldPerTurn,
  ) {
    return 'Hex $col, $row\nRequired hold turns: $holdTurns · Victory points: $victoryPoints · Gold per turn: $goldPerTurn';
  }

  @override
  String get matchFinishedTitle => 'Match finished';

  @override
  String outcomeWinner(String playerId) {
    return 'Winner: $playerId';
  }

  @override
  String get outcomeNoWinner => 'No winner';

  @override
  String get outcomeFinalScore => 'Final score';

  @override
  String outcomeScoreLine(String playerId, int score) {
    return '$playerId: $score';
  }

  @override
  String cityText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'City',
      'foundingTitle': 'Found a city',
      'loading': 'Loading city details',
      'owner': 'Owner',
      'health': 'Health',
      'population': 'Population',
      'territory': 'Territory',
      'foundingSelection': 'Initial territory',
      'foundingConfirm': 'Confirm city founding',
      'foundingCancel': 'Cancel founding',
      'executing': 'Applying city action',
      'cityYield': 'Yield',
      'food': 'Food',
      'production': 'Production',
      'gold': 'Gold',
      'defense': 'Defense',
      'workedHexes': 'Worked hexes',
      'workedHexSelect': 'Manage worked hexes',
      'workedHexHint': 'Select a highlighted controlled hex on the map.',
      'expansion': 'Preferred expansion',
      'expansionSelect': 'Choose expansion',
      'expansionHint': 'Select a highlighted expansion hex on the map.',
      'managementCancel': 'Finish map selection',
      'foundingOpen': 'Plan a city',
      'other': 'City',
    });
    return '$_temp0';
  }

  @override
  String cityFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'The city request could not be completed.',
      'responseIncompatible':
          'The city response is incompatible with this client.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'staleRevision': 'The game state changed. Review the city and try again.',
      'matchFinished': 'The match has already finished.',
      'cityFounderNotFound': 'The founding unit is no longer available.',
      'cityFounderNotControlled':
          'The founding unit is not controlled by this player.',
      'cityFounderBusy': 'The founding unit is busy.',
      'cityFounderInvalid': 'That unit cannot found a city.',
      'cityFounderNoSettlers': 'The founding unit has no settlers.',
      'citySiteInvalid': 'A city cannot be founded at that site.',
      'cityCenterOccupied': 'The city center is occupied.',
      'cityCenterClaimed': 'The city center is already claimed.',
      'cityCenterTooClose': 'The city center is too close to another city.',
      'cityControlledHexesInvalid':
          'The selected initial territory is invalid.',
      'cityNotFound': 'That city is no longer available.',
      'cityNotControlled': 'That city is not controlled by this player.',
      'workedHexUnavailable': 'That worked hex is unavailable.',
      'workedHexLimitReached': 'The city has reached its worked-hex limit.',
      'cityExpansionHexUnavailable': 'That expansion hex is unavailable.',
      'stateRevisionOverflow': 'The game state cannot advance further.',
      'other': 'The city request could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String workerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Worker',
      'loading': 'Loading worker options',
      'empty': 'No worker action is currently available.',
      'executing': 'Applying worker action',
      'buildCharges': 'Build charges',
      'progress': 'Progress',
      'assigned': 'Assigned hex',
      'selectImprovement': 'Select',
      'confirmImprovement': 'Confirm improvement',
      'cancelJob': 'Cancel construction',
      'assign': 'Assign to hex',
      'cancelAssignment': 'Cancel assignment',
      'buildRoad': 'Build road',
      'automate': 'Automate',
      'automationEvidence': 'Planner evidence',
      'other': 'Worker',
    });
    return '$_temp0';
  }

  @override
  String workerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'The worker request could not be completed.',
      'responseIncompatible':
          'The worker response is incompatible with this client.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'staleRevision':
          'The game state changed. Review the worker and try again.',
      'matchFinished': 'The match has already finished.',
      'workerNotFound': 'The worker is no longer available.',
      'workerNotControlled': 'The worker is not controlled by this player.',
      'workerUnavailable': 'The worker is unavailable.',
      'workerNoMovementPoints': 'The worker has no movement points.',
      'workerQueuedPathActive': 'The worker has an active movement order.',
      'workerImprovementNotSelected': 'Select an improvement first.',
      'workerActionNotControlled':
          'The pending worker action is not controlled.',
      'workerImprovementUnavailable': 'That improvement is unavailable.',
      'workerJobNotActive': 'The worker has no active construction.',
      'workerAssignmentUnavailable': 'The worker cannot be assigned here.',
      'workerAssignmentNotActive': 'The worker has no active assignment.',
      'workerRoadUnavailable': 'Road construction is unavailable here.',
      'roadConstructionExistingRoad': 'A road already exists here.',
      'roadConstructionCity': 'A road cannot be built on a city center.',
      'roadConstructionEnemyTerritory':
          'A road cannot be built in enemy territory.',
      'roadConstructionImpassableTerrain':
          'A road cannot be built on this terrain.',
      'workerAutomationNotActive': 'Worker automation is not active.',
      'workerAutomationNoTarget': 'Worker automation found no target.',
      'stateRevisionOverflow': 'The game state cannot advance further.',
      'other': 'The worker request could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String productionText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Production and resources',
      'loading': 'Loading production options',
      'executing': 'Updating city production',
      'current': 'Current production',
      'invested': 'Invested',
      'overflow': 'Overflow',
      'resources': 'Strategic resources',
      'buildings': 'Buildings',
      'units': 'Units',
      'projects': 'Projects',
      'wonders': 'Wonders',
      'specializations': 'Specializations',
      'rush': 'Rush production',
      'cost': 'cost',
      'requires': 'requires',
      'empty': 'No option is currently available.',
      'other': 'Production',
    });
    return '$_temp0';
  }

  @override
  String productionFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'The production request could not be completed.',
      'responseIncompatible': 'The production response is incompatible.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'staleRevision': 'The city changed. Review production and try again.',
      'matchFinished': 'The match has already finished.',
      'cityNotFound': 'The city is no longer available.',
      'cityNotControlled': 'The city is not controlled by this player.',
      'buildingNotAvailable': 'This building is unavailable.',
      'unitProductionInvalidResourceOption': 'That resource option is invalid.',
      'unitProductionNotAvailable': 'This unit is unavailable.',
      'unitProductionRequiresResource': 'Select a resource option.',
      'unitProductionMissingStrategicResource':
          'Required resources are missing.',
      'unitProductionRequiresCoast': 'This unit requires a coastal city.',
      'unitSupplyLimitReached': 'The unit supply limit is reached.',
      'wonderNotAvailable': 'This wonder is unavailable.',
      'citySpecializationLocked': 'This specialization is locked.',
      'citySpecializationUnchanged': 'This specialization is already active.',
      'citySpecializationMissingBuilding': 'A required building is missing.',
      'productionQueueEmpty': 'The production queue is empty.',
      'projectCannotBeRushed': 'A continuous project cannot be rushed.',
      'rushProductionUnavailable': 'Rush production is unavailable.',
      'stateRevisionOverflow': 'The game state cannot advance further.',
      'other': 'The production request could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String artifactText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'World artifacts',
      'executing': 'Applying artifact action',
      'startExcavation': 'Start excavation',
      'storeInCity': 'Store in city',
      'trade': 'Trade artifact',
      'targetPlayer': 'Target player',
      'offeredGold': 'Offered gold',
      'onMap': 'On map at',
      'carried': 'Carried by',
      'stored': 'Stored in',
      'excavation': 'Excavation at',
      'turnsRemaining': 'turns remaining',
      'other': 'Artifact',
    });
    return '$_temp0';
  }

  @override
  String artifactName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ancientImperialCrown': 'Ancient Imperial Crown',
      'astronomersTablets': 'Astronomer’s Tablets',
      'prophetMask': 'Prophet’s Mask',
      'heroSword': 'Hero’s Sword',
      'merchantsSeal': 'Merchant’s Seal',
      'firstPeoplesChronicle': 'First People’s Chronicle',
      'templeReliquary': 'Temple Reliquary',
      'queensMirror': 'Queen’s Mirror',
      'other': 'World artifact',
    });
    return '$_temp0';
  }

  @override
  String artifactOnMap(int col, int row) {
    return 'On map at $col, $row';
  }

  @override
  String artifactCarriedBy(String unitName) {
    return 'Carried by $unitName';
  }

  @override
  String artifactStoredIn(String cityName) {
    return 'Stored in $cityName';
  }

  @override
  String artifactExcavationAt(int col, int row, int remainingTurns) {
    return 'Excavation at $col, $row · $remainingTurns turns remaining';
  }

  @override
  String artifactFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'The artifact request could not be completed.',
      'responseIncompatible': 'The artifact response is incompatible.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'staleRevision':
          'The game state changed. Review the artifact and try again.',
      'matchFinished': 'The match has already finished.',
      'unitNotFound': 'The unit is no longer available.',
      'unitNotControlled': 'The unit is not controlled by this player.',
      'unitUnavailable': 'The unit is unavailable.',
      'unitAlreadyCarryingArtifact': 'The unit already carries an artifact.',
      'artifactNotFound': 'The artifact is no longer available.',
      'unitNotCarryingArtifact': 'The unit is not carrying an artifact.',
      'cityNotFound': 'The city is no longer available.',
      'cityNotControlled': 'The city is not controlled by this player.',
      'unitNotInCity': 'The unit is not in that city.',
      'cityArtifactSlotFull': 'The city artifact slot is full.',
      'artifactTradeActorUnavailable': 'This player cannot trade artifacts.',
      'artifactTradeTargetInvalid': 'The target player is invalid.',
      'artifactTradeGoldInvalid': 'The gold offer is invalid.',
      'artifactTradeBlockedByWar': 'Artifact trade is blocked by war.',
      'artifactTradeGoldUnavailable': 'The offered gold is unavailable.',
      'offeredArtifactUnavailable': 'The offered artifact is unavailable.',
      'targetArtifactSlotUnavailable': 'The target has no artifact slot.',
      'stateRevisionOverflow': 'The game state cannot advance further.',
      'other': 'The artifact request could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String researchText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Research',
      'open': 'Open research',
      'close': 'Close research',
      'loading': 'Loading research options',
      'retry': 'Retry',
      'selecting': 'Selecting technology',
      'selectionRequired': 'Select a technology to continue',
      'sciencePerTurn': 'Science per turn',
      'overflow': 'Stored science',
      'active': 'Active technology',
      'none': 'None',
      'cost': 'Cost',
      'progress': 'Progress',
      'boost': 'Boost discount',
      'prerequisites': 'Prerequisites',
      'blockedBy': 'Blocked by',
      'unlocks': 'Unlocks',
      'choose': 'Select',
      'other': 'Research',
    });
    return '$_temp0';
  }

  @override
  String researchAvailability(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unlocked': 'Researched',
      'active': 'Active',
      'available': 'Available',
      'lockedByPrerequisites': 'Prerequisites required',
      'lockedByTechnology': 'Blocked by technology',
      'other': 'Unavailable',
    });
    return '$_temp0';
  }

  @override
  String researchUnlock(String kind, String target) {
    return '$kind: $target';
  }

  @override
  String researchFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'The research request could not be completed.',
      'responseIncompatible': 'The research response is incompatible.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'staleRevision': 'Research changed. Review the options and try again.',
      'technologyPlayerNotControlled': 'This player cannot select research.',
      'technologyNotAvailable': 'This technology is not available.',
      'stateRevisionOverflow': 'The game state cannot advance further.',
      'other': 'The research request could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String diplomacyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Diplomacy',
      'open': 'Open diplomacy',
      'close': 'Close diplomacy',
      'noContacts': 'No contacts',
      'compose': 'New action',
      'target': 'Counterpart',
      'action': 'Action',
      'send': 'Send',
      'invalid': 'Review the form terms.',
      'pending': 'Sending diplomacy action',
      'relations': 'Relations',
      'proposals': 'Proposals',
      'messages': 'Private messages',
      'agreements': 'Resource agreements',
      'accept': 'Accept',
      'reject': 'Reject',
      'amount': 'Amount',
      'goldPerTurn': 'Gold per turn',
      'duration': 'Turns',
      'resource': 'Resource',
      'offered': 'Offered resource',
      'requested': 'Requested resource',
      'topic': 'Topic',
      'other': 'Diplomacy',
    });
    return '$_temp0';
  }

  @override
  String diplomacyFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'The diplomacy request could not be completed.',
      'responseIncompatible': 'The diplomacy response is incompatible.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'staleRevision':
          'Diplomacy changed. Review the current state and try again.',
      'matchFinished': 'The match has already finished.',
      'diplomacyPlayerNotControlled':
          'This player cannot issue diplomacy actions.',
      'diplomacyTargetNotDiscovered': 'This counterpart is not available.',
      'diplomacyProposalNotAllowed': 'This proposal is not allowed.',
      'diplomacyDuplicateProposal': 'This proposal already exists.',
      'diplomacyProposalNotFound': 'This proposal no longer exists.',
      'diplomacyProposalPaymentUnavailable':
          'The proposal payment is unavailable.',
      'diplomacyMessageCooldown': 'A similar message was sent too recently.',
      'diplomacyDuplicateMessage': 'This message already exists.',
      'diplomacyMessageNotFound': 'This message no longer exists.',
      'diplomacyMessageUnavailable': 'This message cannot be used now.',
      'diplomacyTruceActive': 'A truce is active.',
      'diplomacyWarAlreadyActive': 'War is already active.',
      'diplomacyInvalidGoldAmount': 'The gold amount is invalid.',
      'diplomacyGoldGiftBlockedByRelation': 'This relation blocks gold gifts.',
      'diplomacyGoldUnavailable': 'The required gold is unavailable.',
      'diplomacyGoldGiftUnavailable': 'This gold gift is unavailable.',
      'invalidResourceTradeTarget': 'The resource trade target is invalid.',
      'invalidResourceTradeResource': 'The selected resource is invalid.',
      'invalidResourceTradeTerms': 'The resource trade terms are invalid.',
      'resourceTradeBlockedByWar': 'War blocks this resource trade.',
      'resourceTradeGoldUnavailable': 'Trade gold is unavailable.',
      'resourceTradeAlreadyActive': 'This resource trade is already active.',
      'invalidResourceTradeAgreementId': 'The agreement identity is invalid.',
      'resourceTradeAgreementIdConflict': 'The agreement identity conflicts.',
      'resourceTradeExportUnavailable': 'The resource export is unavailable.',
      'resourceTradeOfferUnavailable': 'The offered resource is unavailable.',
      'resourceTradeRequestUnavailable':
          'The requested resource is unavailable.',
      'stateRevisionOverflow': 'The game state cannot advance further.',
      'other': 'The diplomacy request could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String presentationName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'farm': 'Farm',
      'riverFarm': 'River farm',
      'mine': 'Mine',
      'lumberMill': 'Lumber mill',
      'pasture': 'Pasture',
      'camp': 'Camp',
      'quarry': 'Quarry',
      'fishingBoats': 'Fishing boats',
      'orchard': 'Orchard',
      'plantation': 'Plantation',
      'vineyard': 'Vineyard',
      'tradingPost': 'Trading post',
      'prospectorCamp': 'Prospector camp',
      'horseRanch': 'Horse ranch',
      'pearlDivers': 'Pearl divers',
      'coalShaft': 'Coal shaft',
      'oilWell': 'Oil well',
      'bauxiteMine': 'Bauxite mine',
      'uraniumMine': 'Uranium mine',
      'wheat': 'Wheat',
      'fish': 'Fish',
      'deer': 'Deer',
      'sheep': 'Sheep',
      'rice': 'Rice',
      'cow': 'Cow',
      'apple': 'Apple',
      'banana': 'Banana',
      'citrus': 'Citrus',
      'gold': 'Gold',
      'silver': 'Silver',
      'gems': 'Gems',
      'silk': 'Silk',
      'spices': 'Spices',
      'cotton': 'Cotton',
      'grapes': 'Grapes',
      'ivory': 'Ivory',
      'pearls': 'Pearls',
      'coffee': 'Coffee',
      'cocoa': 'Cocoa',
      'tobacco': 'Tobacco',
      'sugar': 'Sugar',
      'iron': 'Iron',
      'coal': 'Coal',
      'oil': 'Oil',
      'aluminium': 'Aluminium',
      'uranium': 'Uranium',
      'horses': 'Horses',
      'marble': 'Marble',
      'commander': 'Commander',
      'warrior': 'Warrior',
      'archer': 'Archer',
      'settler': 'Settler',
      'worker': 'Worker',
      'merchant': 'Merchant',
      'scout': 'Scout',
      'spearman': 'Spearman',
      'cavalry': 'Cavalry',
      'catapult': 'Catapult',
      'heavyInfantry': 'Heavy infantry',
      'fieldCannon': 'Field cannon',
      'rifleman': 'Rifleman',
      'tank': 'Tank',
      'scoutShip': 'Scout ship',
      'warship': 'Warship',
      'reconPlane': 'Recon plane',
      'building': 'Building',
      'improvement': 'Improvement',
      'resourceVisibility': 'Resource visibility',
      'unit': 'Unit',
      'wonder': 'Wonder',
      'friendly': 'Friendly',
      'neutral': 'Neutral',
      'hostile': 'Hostile',
      'truce': 'Truce',
      'war': 'War',
      'warning': 'Warning',
      'complaint': 'Complaint',
      'request': 'Request',
      'praise': 'Praise',
      'threat': 'Threat',
      'cooperation': 'Cooperation',
      'troopsNearCities': 'Troops near cities',
      'citiesTooClose': 'Cities too close',
      'blockedRoutes': 'Blocked routes',
      'withdrawScouts': 'Withdraw scouts',
      'avoidEscalation': 'Avoid escalation',
      'commonEnemy': 'Common enemy',
      'expansionProvocation': 'Expansion provocation',
      'peacefulPraise': 'Peaceful praise',
      'conciliatory': 'Conciliatory',
      'evasive': 'Evasive',
      'aggressive': 'Aggressive',
      'declareWar': 'Declare war',
      'goldGift': 'Gold gift',
      'friendshipProposal': 'Friendship proposal',
      'truceProposal': 'Truce proposal',
      'message': 'Message',
      'resourceTrade': 'Resource trade',
      'resourceExchange': 'Resource exchange',
      'granary': 'Granary',
      'workshop': 'Workshop',
      'industry': 'Industry',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String technologyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'agriculture': 'Agriculture',
      'woodworking': 'Woodworking',
      'mining': 'Mining',
      'animalHusbandry': 'Animal husbandry',
      'hunting': 'Hunting',
      'fishing': 'Fishing',
      'craftsmanship': 'Craftsmanship',
      'trade': 'Trade',
      'storage': 'Storage',
      'waterEngineering': 'Water engineering',
      'stoneworking': 'Stoneworking',
      'militaryOrganization': 'Military organization',
      'advancedTrade': 'Advanced trade',
      'construction': 'Construction',
      'navigation': 'Navigation',
      'irrigation': 'Irrigation',
      'banking': 'Banking',
      'engineering': 'Engineering',
      'metallurgy': 'Metallurgy',
      'horsebackRiding': 'Horseback riding',
      'ironWorking': 'Iron working',
      'coalMining': 'Coal mining',
      'machinery': 'Machinery',
      'administration': 'Administration',
      'logistics': 'Logistics',
      'shipbuilding': 'Shipbuilding',
      'tactics': 'Tactics',
      'economy': 'Economy',
      'urbanization': 'Urbanization',
      'fortifications': 'Fortifications',
      'strategy': 'Strategy',
      'specialization': 'Specialization',
      'writing': 'Writing',
      'mathematics': 'Mathematics',
      'medicine': 'Medicine',
      'civilService': 'Civil service',
      'siegecraft': 'Siegecraft',
      'cartography': 'Cartography',
      'guilds': 'Guilds',
      'law': 'Law',
      'education': 'Education',
      'urbanPlanning': 'Urban planning',
      'navalDoctrine': 'Naval doctrine',
      'steel': 'Steel',
      'bureaucracy': 'Bureaucracy',
      'nationalism': 'Nationalism',
      'scientificMethod': 'Scientific method',
      'steamPower': 'Steam power',
      'electricity': 'Electricity',
      'combustion': 'Combustion',
      'flight': 'Flight',
      'massProduction': 'Mass production',
      'radio': 'Radio',
      'nuclearPhysics': 'Nuclear physics',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String cityContentName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'growth': 'Growth',
      'industry': 'Industry',
      'commerce': 'Commerce',
      'science': 'Science',
      'military': 'Military',
      'wealth': 'Wealth',
      'research': 'Research',
      'granary': 'Granary',
      'waterMill': 'Water mill',
      'workshop': 'Workshop',
      'storehouse': 'Storehouse',
      'housing': 'Housing',
      'merchantHall': 'Merchant hall',
      'stonemason': 'Stonemason',
      'barracks': 'Barracks',
      'marketplace': 'Marketplace',
      'port': 'Port',
      'aqueduct': 'Aqueduct',
      'forge': 'Forge',
      'stable': 'Stable',
      'bank': 'Bank',
      'buildersGuild': 'Builders’ guild',
      'factory': 'Factory',
      'lighthouse': 'Lighthouse',
      'trainingGrounds': 'Training grounds',
      'townHall': 'Town hall',
      'monument': 'Monument',
      'archive': 'Archive',
      'academy': 'Academy',
      'university': 'University',
      'observatory': 'Observatory',
      'laboratory': 'Laboratory',
      'reactor': 'Reactor',
      'courthouse': 'Courthouse',
      'court': 'Court',
      'governorsOffice': 'Governor’s office',
      'surveyorsOffice': 'Surveyors’ office',
      'planningOffice': 'Planning office',
      'apothecary': 'Apothecary',
      'publicBaths': 'Public baths',
      'hospital': 'Hospital',
      'ministries': 'Ministries',
      'walls': 'Walls',
      'armory': 'Armory',
      'siegeWorkshop': 'Siege workshop',
      'citadel': 'Citadel',
      'warCollege': 'War college',
      'conscriptionOffice': 'Conscription office',
      'borderFort': 'Border fort',
      'airfield': 'Airfield',
      'artisansGuild': 'Artisans’ guild',
      'masterWorkshop': 'Master workshop',
      'steelworks': 'Steelworks',
      'railDepot': 'Rail depot',
      'powerPlant': 'Power plant',
      'assemblyPlant': 'Assembly plant',
      'refinery': 'Refinery',
      'mapRoom': 'Map room',
      'shipyard': 'Shipyard',
      'dryDock': 'Dry dock',
      'navalAcademy': 'Naval academy',
      'harborCustoms': 'Harbor customs',
      'museum': 'Museum',
      'parliament': 'Parliament',
      'broadcastTower': 'Broadcast tower',
      'worldFairGrounds': 'World fair grounds',
      'greatLibrary': 'Great Library',
      'hangingGardens': 'Hanging Gardens',
      'greatWall': 'Great Wall',
      'petra': 'Petra',
      'centralBank': 'Central Bank',
      'imperialUniversity': 'Imperial University',
      'grandCathedral': 'Grand Cathedral',
      'motherFactory': 'Mother Factory',
      'nationalObservatory': 'National Observatory',
      'svalbardSeedVault': 'Svalbard Seed Vault',
      'grandExposition': 'Grand Exposition',
      'other': 'Unknown city content',
    });
    return '$_temp0';
  }

  @override
  String diplomaticProposalName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'friendship': 'Friendship',
      'truce': 'Truce',
      'other': 'Unknown proposal',
    });
    return '$_temp0';
  }

  @override
  String mapFeedbackText(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'roadCompleted': '+Road',
      'unitKilled': 'KO',
      'unitRetreated': 'Retreat',
      'artifactExcavationStarted': 'Excavate',
      'artifactCarried': 'Artifact carried',
      'artifactStored': 'Artifact stored',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String mapYieldShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'food': 'FOOD',
      'production': 'PROD',
      'gold': 'GOLD',
      'defense': 'DEF',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get focusOwnUnitMovement => 'Focus camera on my unit movement';

  @override
  String get followOwnUnitMovement => 'Track my unit movement with camera';

  @override
  String get focusForeignUnitMovement => 'Focus camera on enemy unit movement';

  @override
  String get followForeignUnitMovement =>
      'Track enemy unit movement with camera';
}
