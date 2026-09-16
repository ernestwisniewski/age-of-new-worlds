// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AonwLocalizationsEn extends AonwLocalizations {
  AonwLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get moveTargeting => 'Move';

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
  String multiplayerPresence(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'ready': 'Ready',
      'connected': 'Connected',
      'connecting': 'Connecting',
      'reconnecting': 'Reconnecting',
      'offline': 'Offline',
      'open': 'Open seat',
      'other': 'Offline',
    });
    return '$_temp0';
  }

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
      'Every human player must be connected and ready before the match starts.';

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
      'lobby_not_ready':
          'Every human player must be connected and ready before the match starts.',
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
      'Choose your civilization and set up your game.';

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
      'Use WASD or arrow keys to pan the camera, Enter to select, M for movement, I to inspect, R to switch map views, brackets for pending actions, and Space for the next action or to end the turn. Use Tab to focus controls.';

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
      'actionSubmit': 'Submit turn',
      'actionSubmitting': 'Submitting turn',
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
  String get cameraSettings => 'Camera';

  @override
  String get cameraSensitivity => 'Zoom sensitivity';

  @override
  String get animationSettings => 'Animations';

  @override
  String get showUnitMovementAnimations => 'Show unit movement animations';

  @override
  String get showUnitIdleAnimations => 'Show unit idle animations';

  @override
  String get showRouteAnimations => 'Show planned route animations';

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
  String objectiveControlProgress(String player, int turns, int required) {
    return 'Controlled by $player\nHold progress: $turns / $required';
  }

  @override
  String get objectiveControlUnknown => 'No known controller';

  @override
  String get objectivesAuthoredRules =>
      'Control these locations and hold them for the required number of turns.';

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
      'openActions': 'Improve hex',
      'closeActions': 'Cancel selection',
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
      'recommendations': 'Recommendations',
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
      'tree': 'Technology tree',
      'catalog': 'Research catalog',
      'backToTree': 'Back to tree',
      'treeUnavailable': 'The dependency diagram is unavailable.',
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

  @override
  String get gameSoundsLabel => 'Game sounds';

  @override
  String get soundVolumeLabel => 'Sound volume';

  @override
  String get gameMusicLabel => 'Game music';

  @override
  String get musicVolumeLabel => 'Music volume';

  @override
  String get natureSoundsLabel => 'Nature sounds';

  @override
  String get natureVolumeLabel => 'Nature volume';

  @override
  String hexInspectionKind(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite': 'Ideal city site',
      'goodCitySite': 'Good city site',
      'fertileField': 'Fertile field',
      'fertilePlains': 'Fertile plains',
      'richPlain': 'Rich plain',
      'strategicBorderland': 'Strategic borderland',
      'strategicField': 'Strategic field',
      'defensivePosition': 'Defensive position',
      'fertileForest': 'Fertile forest',
      'forestBackline': 'Forest backline',
      'forestForge': 'Forest forge',
      'wildLand': 'Wild land',
      'richWilds': 'Rich wilds',
      'exoticBackline': 'Exotic backline',
      'difficultStrategicTerrain': 'Difficult strategic terrain',
      'highGround': 'High ground',
      'riverHills': 'River hills',
      'industrialStronghold': 'Industrial stronghold',
      'richHills': 'Rich hills',
      'barrenLand': 'Barren land',
      'oasis': 'Oasis',
      'tradeOasis': 'Trade oasis',
      'desertDeposits': 'Desert deposits',
      'harshLand': 'Harsh land',
      'coldPastures': 'Cold pastures',
      'resourceOutpost': 'Resource outpost',
      'hostileLand': 'Hostile land',
      'arcticDeposits': 'Arctic deposits',
      'coast': 'Coast',
      'fishingCoast': 'Fishing coast',
      'richCoast': 'Rich coast',
      'riverPort': 'River port',
      'regionalPortHeart': 'Regional port hub',
      'openSea': 'Open sea',
      'naturalBarrier': 'Natural barrier',
      'promisingLand': 'Promising land',
      'weakLand': 'Weak land',
      'ordinaryLand': 'Ordinary land',
      'mapTile': 'Map tile',
      'other': 'Map tile',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionDescription(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite':
          'A high-value settlement tile with food, growth, and expansion pressure already lined up.',
      'goodCitySite':
          'Solid terrain for a city center with enough baseline value to support early growth.',
      'fertileField':
          'River-fed grassland that favors food, population growth, and worker improvements.',
      'fertilePlains':
          'Open plains with river support, useful for balanced food and production.',
      'richPlain':
          'A valuable open tile with luxury or trade value worth bringing inside borders.',
      'strategicBorderland':
          'Good land with strategic value, useful for expansion before rivals claim it.',
      'strategicField':
          'A plains tile tied to strategic resources or pressure on the frontier.',
      'defensivePosition':
          'Terrain that improves defensive control and helps hold nearby approaches.',
      'fertileForest':
          'A forest with river support, mixing growth potential with natural cover.',
      'forestBackline':
          'A safer forest tile that can support growth or hunting-oriented improvements.',
      'forestForge':
          'Forest with industrial resource value, promising for production once improved.',
      'wildLand':
          'Dense terrain with friction; useful only when you have a clear worker or expansion plan.',
      'richWilds':
          'Wild terrain with enough fertility or resources to justify careful development.',
      'exoticBackline':
          'A jungle or wetland tile carrying luxury value for later borders and trade.',
      'difficultStrategicTerrain':
          'Hard terrain with strategic resource value; powerful later, awkward early.',
      'highGround':
          'Hills that favor defense and map control more than fast growth.',
      'riverHills':
          'Hills beside a river, combining defense with better economic potential.',
      'industrialStronghold':
          'Hills with industrial resources, a strong production target for a city.',
      'richHills':
          'Hills with wealth resources, useful for gold or production-focused expansion.',
      'barrenLand':
          'Dry land with little immediate value unless later tech or borders change the plan.',
      'oasis':
          'Desert softened by river access, turning weak land into a usable growth tile.',
      'tradeOasis':
          'A desert trade pocket that can become valuable with the right improvement.',
      'desertDeposits':
          'Poor settlement land with a strategic deposit that matters more in later eras.',
      'harshLand':
          'Cold or rough land with limited early economy and slow development.',
      'coldPastures':
          'Cold terrain with enough pasture value to support a border city.',
      'resourceOutpost':
          'Remote cold land worth claiming mainly for the resource it protects.',
      'hostileLand':
          'Unfriendly ground with weak settlement value and few immediate returns.',
      'arcticDeposits':
          'Snowy resource land that is hard to use but can matter strategically.',
      'coast': 'Coastal land that opens naval access and flexible city growth.',
      'fishingCoast':
          'Coast with food value, a strong reason to work or settle near the water.',
      'richCoast':
          'Coastal luxury or trade value worth folding into city borders.',
      'riverPort':
          'A river mouth with trade and movement value for a coastal city.',
      'regionalPortHeart':
          'A strong coastal center where river and resource value stack together.',
      'openSea':
          'Water that is useful for ships and scouting, but not for land settlement.',
      'naturalBarrier':
          'Blocked terrain that shapes movement and defense rather than economy.',
      'promisingLand':
          'A generally useful tile with enough value to inspect before moving on.',
      'weakLand': 'Low-return terrain that rarely deserves early worker time.',
      'ordinaryLand':
          'A normal tile with no standout strength, useful when it fits the city plan.',
      'mapTile':
          'A plain map tile without enough information to make a strong judgment.',
      'other':
          'A plain map tile without enough information to make a strong judgment.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendation(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity': 'Good development site',
      'defendHere': 'Good defensive position',
      'exploitEconomy': 'Worth exploiting',
      'avoid': 'Avoid without a plan',
      'neutral': 'Inspect before moving',
      'other': 'Inspect before moving',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendationDetail(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity':
          'If borders are free, consider founding or steering a settler here.',
      'defendHere':
          'Use it to anchor units, protect borders, or cover nearby cities.',
      'exploitEconomy':
          'Bring it inside borders and assign a worker when the city can benefit.',
      'avoid':
          'Skip it early unless a resource, route, or military need changes the value.',
      'neutral':
          'Scout neighboring tiles and compare resources before committing a worker or settler.',
      'other':
          'Scout neighboring tiles and compare resources before committing a worker or settler.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Hex inspection',
      'close': 'Close inspection',
      'loading': 'Inspecting hex…',
      'requestFailed': 'The hex could not be inspected. Try again.',
      'responseIncompatible': 'The hex inspection response is incompatible.',
      'sessionUnavailable': 'The game session is unavailable.',
      'description': 'Description',
      'terrain': 'Terrain',
      'resources': 'Resources',
      'none': 'None',
      'height': 'Height',
      'improvements': 'Possible improvements',
      'noImprovements': 'No matching improvements.',
      'fromStart': 'Available from the start',
      'unlocked': 'Technology unlocked',
      'locked': 'Technology required',
      'riverBonus': 'River bonus',
      'defenseBonus': 'Defensive terrain',
      'outsideCity': 'Outside controlled city borders',
      'cityCenter': 'City center',
      'alreadyImproved': 'This hex is already improved',
      'objective': 'Map objective',
      'other': 'Hex inspection',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionCity(String city) {
    return 'Works for $city';
  }

  @override
  String hexInspectionBuildTurns(int turns) {
    return 'Build time: $turns turns';
  }

  @override
  String hexInspectionTerrain(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'ocean': 'Ocean',
      'coast': 'Coast',
      'lake': 'Lake',
      'plains': 'Plains',
      'grassland': 'Grassland',
      'desert': 'Desert',
      'tundra': 'Tundra',
      'snow': 'Snow',
      'mountain': 'Mountain',
      'hills': 'Hills',
      'wetlands': 'Wetlands',
      'jungle': 'Jungle',
      'forest': 'Forest',
      'river': 'River',
      'other': 'Plains',
    });
    return '$_temp0';
  }

  @override
  String get gamepadSettings => 'Gamepad';

  @override
  String get gamepadEnabled => 'Gamepad input';

  @override
  String get gamepadDeadzone => 'Gamepad deadzone';

  @override
  String get gamepadCameraSensitivity => 'Gamepad camera sensitivity';

  @override
  String get gamepadInvertCameraY => 'Invert gamepad camera Y';

  @override
  String get gamepadButtonBindings => 'Button bindings';

  @override
  String get gamepadAxisBindings => 'Axis bindings';

  @override
  String get gamepadResetBindings => 'Reset bindings';

  @override
  String get gamepadUnassigned => 'Unassigned';

  @override
  String gamepadAssignedTo(String action) {
    return 'Assigned to: $action';
  }

  @override
  String get gamepadActionConfirm => 'Confirm';

  @override
  String get gamepadActionCancel => 'Cancel';

  @override
  String get gamepadActionMoveMode => 'Movement mode';

  @override
  String get gamepadActionInspect => 'Inspect hex';

  @override
  String get gamepadActionHudPrevious => 'Previous HUD section';

  @override
  String get gamepadActionHudNext => 'Next HUD section';

  @override
  String get gamepadActionPrevious => 'Previous pending action';

  @override
  String get gamepadActionNext => 'Next pending action';

  @override
  String get gamepadActionPrimary => 'Primary action';

  @override
  String get gamepadActionUp => 'D-pad up';

  @override
  String get gamepadActionDown => 'D-pad down';

  @override
  String get gamepadActionLeft => 'D-pad left';

  @override
  String get gamepadActionRight => 'D-pad right';

  @override
  String get gamepadActionZoomIn => 'Zoom in';

  @override
  String get gamepadActionZoomOut => 'Zoom out';

  @override
  String get gamepadActionCursorX => 'Cursor X';

  @override
  String get gamepadActionCursorY => 'Cursor Y';

  @override
  String get gamepadActionCameraX => 'Camera X';

  @override
  String get gamepadActionCameraY => 'Camera Y';

  @override
  String get gamepadControlHome => 'Home';

  @override
  String get gamepadControlTouchpad => 'Touchpad';

  @override
  String get gamepadControlLeftStickX => 'Left stick X';

  @override
  String get gamepadControlLeftStickY => 'Left stick Y';

  @override
  String get gamepadControlRightStickX => 'Right stick X';

  @override
  String get gamepadControlRightStickY => 'Right stick Y';

  @override
  String get gamepadControlLeftTrigger => 'Left trigger (LT)';

  @override
  String get gamepadControlRightTrigger => 'Right trigger (RT)';

  @override
  String get keyboardSettings => 'Keyboard';

  @override
  String get keyboardScope =>
      'Map shortcuts work while the map has keyboard focus. Click the map to return focus to it.';

  @override
  String get keyboardPanKeys => 'W / A / S / D or arrow keys';

  @override
  String get keyboardPan => 'Pan the camera';

  @override
  String get keyboardSelect =>
      'Select the hex under the pointer, or the current selection';

  @override
  String get keyboardMove => 'Toggle movement targeting for the selected unit';

  @override
  String get keyboardInspect =>
      'Inspect the hex under the pointer, the selected hex, or the center of the view';

  @override
  String get keyboardMapMode => 'Switch between graphic and tile map views';

  @override
  String get keyboardPending => 'Previous / next pending turn action';

  @override
  String get keyboardSpace => 'Space';

  @override
  String get keyboardPrimary =>
      'Go to the next pending action; end the turn when none remain';

  @override
  String get keyboardCancel =>
      'Close the active panel or cancel the current interaction';

  @override
  String get keyboardFocus => 'Focus the next / previous control';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeDescription =>
      'Applied in addition to your system text size.';

  @override
  String get textScaleStandard => 'Standard (100%)';

  @override
  String get textScaleLarge => 'Large (115%)';

  @override
  String get textScaleExtraLarge => 'Extra large (130%)';

  @override
  String get languageSettings => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get windowSettingsTitle => 'Window';

  @override
  String get windowModeFullscreen => 'Full screen';

  @override
  String get windowModeWindowed => 'Windowed';

  @override
  String get windowSettingsBusy => 'Changing window mode…';

  @override
  String windowSettingsFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'load':
          'Window preferences could not be loaded. The default mode was requested.',
      'apply':
          'The window mode could not be changed. Try choosing a mode again.',
      'save':
          'The window preference could not be saved. Try choosing a mode again.',
      'restore':
          'The previous window mode could not be restored. Choose a mode again.',
      'other': 'The window operation could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String get automationSettings => 'Automation';

  @override
  String get advanceActions => 'Advance to the next action';

  @override
  String get advanceActionsDescription =>
      'After completing an action, select the next unit, city or research that needs your attention.';

  @override
  String get automaticEndTurn => 'End turns automatically';

  @override
  String get automaticEndTurnDescription =>
      'End your turn when no actions remain. Manual choices and open panels pause automation.';

  @override
  String get performanceSettings => 'Performance';

  @override
  String get showFps => 'Show FPS';

  @override
  String get showFpsDescription => 'Show the frame rate throughout the app.';

  @override
  String get showMapZoom => 'Show map zoom';

  @override
  String get showMapZoomDescription =>
      'Show the current zoom while the map is open.';

  @override
  String get aiSettings => 'AI';

  @override
  String get aiBatterySaver => 'AI battery saver';

  @override
  String get aiBatterySaverDescription =>
      'Reduces tactical search work during local AI turns.';

  @override
  String get mapAppearanceSettings => 'Map appearance';

  @override
  String get mapMarkingsSettings => 'Map markings';

  @override
  String get preferredMapViewMode => 'Default map view';

  @override
  String get preferredMapViewModeDescription =>
      'Used when opening a game or replay.';

  @override
  String get mapCitySites => 'City sites';

  @override
  String get mapCitySitesDescription =>
      'Show potential city sites on discovered terrain.';

  @override
  String get mapCityGrowth => 'City growth';

  @override
  String get mapCityGrowthDescription =>
      'Show discovered tiles outside known city territory.';

  @override
  String resourceTurnsCompact(int turns) {
    return '${turns}T';
  }

  @override
  String resourceText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'gold': 'Gold',
      'science': 'Science',
      'stability': 'Stability',
      'resources': 'Resources',
      'victory': 'Victory',
      'turn': 'Turn',
      'close': 'Close details',
      'treasury': 'Treasury',
      'income': 'Income',
      'cityIncome': 'City income',
      'projectIncome': 'Project income',
      'upkeep': 'Unit upkeep',
      'netPerTurn': 'Per turn',
      'freeUnits': 'Free units',
      'paidUnits': 'Paid units',
      'nextWorker': 'Next worker upkeep',
      'activeResearch': 'Active research',
      'overflow': 'Stored science',
      'sources': 'Sources',
      'baseOrder': 'Base order',
      'buildings': 'Buildings',
      'luxuries': 'Luxuries',
      'technologies': 'Technologies',
      'artifacts': 'Artifacts',
      'wonders': 'Wonders',
      'cities': 'Cities',
      'population': 'Population',
      'cohesion': 'Cohesion',
      'conqueredCities': 'Conquered cities',
      'warWeariness': 'War weariness',
      'hegemony': 'Hegemony tax',
      'relativeStanding': 'Relative standing',
      'totalSources': 'Total sources',
      'totalCosts': 'Total costs',
      'stockpile': 'Stockpile',
      'output': 'Output per turn',
      'empty': 'No sources',
      'score': 'Score',
      'conquest': 'Conquest',
      'domination': 'Domination',
      'culture': 'Culture',
      'holdTurns': 'Hold turns',
      'remainingTurns': 'Remaining turns',
      'turnLimit': 'Turn limit',
      'submitted': 'Submitted',
      'required': 'Required submissions',
      'content': 'Content',
      'stable': 'Stable',
      'strained': 'Strained',
      'unrest': 'Unrest',
      'warning': 'Warning',
      'negativeBalance': 'The treasury is negative.',
      'deficitWithinThreeTurns':
          'At the current income, the treasury will be negative within three turns.',
      'shortage': 'Insufficient resources for unlocked units',
      'victoryCritical': 'A victory condition is approaching.',
      'leader': 'Leader',
      'noVictory': 'No victory condition',
      'goalCompact': 'Goal',
      'scoreCapCompact': 'CAP',
      'other': 'Resources',
    });
    return '$_temp0';
  }

  @override
  String get automaticSave => 'Autosave';

  @override
  String playerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Players',
      'active': 'Active',
      'finished': 'Turn finished',
      'submitted': 'Submitted',
      'waiting': 'Waiting',
      'ended': 'Match ended',
      'privateStatus': 'Turn status is private',
      'noContact': 'No diplomatic contact',
      'other': 'Players',
    });
    return '$_temp0';
  }

  @override
  String historyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Completed online matches',
      'loading': 'Loading match history',
      'empty': 'No completed matches yet.',
      'failed': 'Match history could not be loaded. Try refreshing.',
      'refresh': 'Refresh',
      'previous': 'Previous page',
      'next': 'Next page',
      'turn': 'Final turn',
      'won': 'You won',
      'lost': 'You lost',
      'resigned': 'You resigned',
      'removed': 'You were removed from the match',
      'other': 'Completed online matches',
    });
    return '$_temp0';
  }

  @override
  String profileText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Your profile',
      'description':
          'Changing your display name keeps your account and multiplayer matches.',
      'save': 'Save name',
      'saved': 'Display name saved.',
      'taken': 'This display name is already taken.',
      'changed': 'The account changed. Load the profile again.',
      'other': 'Your profile',
    });
    return '$_temp0';
  }

  @override
  String get researchDiscoveryTitle => 'Research completed';

  @override
  String get showResearchDiscoveries => 'Show research discoveries';

  @override
  String get researchDiscoverySuppress => 'Do not show again';

  @override
  String get researchDiscoveryMinimize => 'Minimize';

  @override
  String get researchDiscoveryRestore => 'Restore discovery';

  @override
  String get researchDiscoveryContinue => 'Continue';

  @override
  String researchRecommendationRank(int rank) {
    return 'Recommendation $rank';
  }

  @override
  String researchRecommendationTurns(int turns) {
    return 'Estimated turns: $turns';
  }

  @override
  String researchRecommendationReason(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'boost': 'Research boost',
      'workerYields': 'Worker yields',
      'unlocks': 'New unlocks',
      'effects': 'Technology effects',
      'nearCompletion': 'Near completion',
      'other': 'Recommendations',
    });
    return '$_temp0';
  }

  @override
  String technologyDescription(String technology) {
    String _temp0 = intl.Intl.selectLogic(technology, {
      'agriculture':
          'Opens the basic growth path. Farms and river farms let population grow faster and stabilize the first city.',
      'woodworking':
          'Develops the production side of mining. Lumber mills turn forests into production without going deep into metallurgy.',
      'mining':
          'Opens the path of industry and infrastructure. Mines are the first major jump in city production.',
      'animalHusbandry':
          'Strengthens growth through animal resources. Pastures build a food economy and prepare the way to horseback riding.',
      'hunting':
          'Opens the military and exploration branch. Provides camps and the first ranged unit for city production.',
      'fishing':
          'Develops cities near water. Fishing boats help coastal cities grow faster and prepare the way to the port.',
      'craftsmanship':
          'The first city production upgrade. The workshop keeps later buildings and units from blocking the queue too long.',
      'trade':
          'The first step in the gold economy. The merchant hall gives a city a simple financial payoff after choosing a growth branch.',
      'storage':
          'Stabilizes city growth. Storage helps maintain food pace and reduces the risk of development stalls.',
      'waterEngineering':
          'Expands the water growth path. The water mill rewards cities that control rivers.',
      'stoneworking':
          'Combines production and defense. Quarries and the stonemason strengthen cities in the infrastructure branch.',
      'militaryOrganization':
          'Builds the first military core of a city. Barracks strengthen production and defense before later army bonuses appear.',
      'advancedTrade':
          'Develops the economy after trade. The marketplace is a stronger gold building and prepares the path to banking.',
      'construction':
          'Expands territory and city maturity. Housing increases tile control and leads to administration and engineering.',
      'navigation':
          'Opens a city payoff for the coast. The port requires coast/ocean access and rewards waterfront cities with food and gold.',
      'irrigation':
          'Specializes water-based growth. The aqueduct grants a strong food bonus and additional territorial control.',
      'banking':
          'Specializes the trade branch. The bank turns earlier markets into strong city income and unlocks the wider economy.',
      'engineering':
          'Construction specialization. The builders guild speeds production and increases the controlled tile limit.',
      'metallurgy':
          'A strong industrial payoff after stoneworking. The forge raises production and prepares the path to iron and coal.',
      'horsebackRiding':
          'A technology linking growth and war. The stable supports cities that invested earlier in animals and hunting.',
      'ironWorking':
          'An industrial resource effect. Each controlled iron resource increases city production.',
      'coalMining':
          'A later industrial resource effect. Controlled coal increases city production and supports the factory path.',
      'machinery':
          'A late infrastructure payoff. The factory gives a large production increase to cities that entered engineering.',
      'administration':
          'Links infrastructure with economy. Town halls and monuments strengthen mature cities and lead to urbanization.',
      'logistics':
          'Speeds unit production. This is the main technology for players who want to field armies from cities more often.',
      'shipbuilding':
          'Develops the coastal/exploration subbranch. The lighthouse requires coast access and strengthens waterfront cities.',
      'tactics':
          'Military city specialization. Training grounds add defense and production for military centers.',
      'economy':
          'A systemic payoff for banking. Increases gold generated by city economies.',
      'urbanization':
          'The final direction for large-city growth. Increases the population limit once the population system starts using hard caps.',
      'fortifications':
          'Strengthens city defense. Grants a defensive bonus to the city economy, with its full meaning growing after combat and siege expansion.',
      'strategy':
          'The final military direction. Strengthens army effectiveness as a late-game payoff after logistics.',
      'specialization':
          'The final civic/economy payoff. Unlocks city specializations, adds city science, and helps finish late technologies in longer matches.',
      'writing':
          'The first step toward science, law, and administration. The archive gives a city a permanent research base.',
      'mathematics':
          'Connects science with territorial planning. The surveyor office helps cities control borders more effectively.',
      'medicine':
          'Develops health and long-term growth in large cities through apothecaries, baths, and hospitals.',
      'civilService':
          'Improves management of a large empire and unlocks courts that stabilize cities.',
      'siegecraft':
          'Opens siege warfare. Catapults and siege workshops break fortress cities.',
      'cartography':
          'Develops exploration, maps, and the coast. Grants the map room and the first scout ships.',
      'guilds':
          'Gives production cities a stage between the workshop and industry.',
      'law':
          'Introduces order, policies, and civilian governance through courts.',
      'education':
          'Builds the full science path for cities through academies and universities.',
      'urbanPlanning':
          'Develops great cities and territorial control through spatial planning.',
      'navalDoctrine':
          'Turns ports into centers of fleets, shipyards, and force projection at sea.',
      'steel':
          'Introduces heavy industry and heavy infantry for the later front.',
      'bureaucracy':
          'Provides a major civic goal after administration: offices, ministries, museums, and parliament.',
      'nationalism':
          'Combines border defense, mobilization, and empire identity.',
      'scientificMethod':
          'Prepares late science, laboratories, observatories, and technology projects.',
      'steamPower': 'Opens rail, heavier logistics, and steam industry.',
      'electricity': 'Introduces power, infrastructure, and information reach.',
      'combustion': 'Gives oil importance and unlocks modern frontline units.',
      'flight':
          'Introduces aviation, reconnaissance, and force projection over the front.',
      'massProduction':
          'Develops final industrial production, tanks, and assembly plants.',
      'radio':
          'Strengthens empire communication, visibility, and influence through broadcast towers.',
      'nuclearPhysics':
          'Opens the reactor, uranium, and late endgame projects.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String outcomePresentationText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'victory': 'Victory',
      'defeat': 'Defeat',
      'draw': 'Draw',
      'complete': 'Match finished',
      'control': 'Map control',
      'threshold': 'Required control',
      'other': 'Match finished',
    });
    return '$_temp0';
  }

  @override
  String resourceInventoryText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'barter': 'barter',
      'importDirection': 'Importing',
      'exportDirection': 'Exporting',
      'title': 'Strategic economy',
      'healthy': 'Strategic supply is stable.',
      'resources': 'Strategic resources',
      'alerts': 'Economic alerts',
      'allocations': 'Production allocations',
      'noAllocations': 'No strategic resources are allocated.',
      'sources': 'Sources',
      'noSources': 'No active strategic resource sources.',
      'agreements': 'Active agreements',
      'noAgreements': 'No active resource agreements.',
      'partners': 'Trade partners',
      'noPartners': 'No known civilization is available for resource trade.',
      'openTrade': 'Open trade',
      'goToCity': 'Go to city',
      'stored': 'Stored',
      'allocated': 'Allocated',
      'controlled': 'Controlled deposits',
      'available': 'Available',
      'production': 'Domestic production',
      'imports': 'Imports',
      'exports': 'Exports',
      'net': 'Net / turn',
      'stockWarningDetail':
          'New production that requires this resource is blocked.',
      'tradeWarningDetail':
          'Review the agreement before the strategic flow changes.',
      'other': 'Strategic economy',
    });
    return '$_temp0';
  }

  @override
  String resourceInventoryAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count issues require attention.',
      one: '1 issue requires attention.',
    );
    return '$_temp0';
  }

  @override
  String resourceInventoryNoFreeStock(String resourceName) {
    return 'No free $resourceName';
  }

  @override
  String resourceInventoryInsufficientStock(String resourceName) {
    return 'Not enough free $resourceName';
  }

  @override
  String resourceInventoryTradeExpiring(String resourceName, int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns turns',
      one: '1 turn',
    );
    return '$resourceName agreement expires in $_temp0';
  }

  @override
  String resourceInventoryTradeFlow(
    String direction,
    int amount,
    String resourceName,
    String price,
    int remainingTurns,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingTurns,
      locale: localeName,
      other: '$remainingTurns turns left',
      one: '1 turn left',
    );
    return '$direction: $amount $resourceName/turn · $price · $_temp0';
  }

  @override
  String resourceInventoryTradeGold(int goldPerTurn) {
    return '$goldPerTurn gold/turn';
  }
}
