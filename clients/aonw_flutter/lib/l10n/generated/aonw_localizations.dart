import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'aonw_localizations_en.dart';
import 'aonw_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AonwLocalizations
/// returned by `AonwLocalizations.of(context)`.
///
/// Applications need to include `AonwLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/aonw_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AonwLocalizations.localizationsDelegates,
///   supportedLocales: AonwLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AonwLocalizations.supportedLocales
/// property.
abstract class AonwLocalizations {
  AonwLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AonwLocalizations of(BuildContext context) {
    return Localizations.of<AonwLocalizations>(context, AonwLocalizations)!;
  }

  static const LocalizationsDelegate<AonwLocalizations> delegate =
      _AonwLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Age of New Worlds'**
  String get appTitle;

  /// No description provided for @mainMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenuTitle;

  /// No description provided for @mainMenuWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Age of New Worlds. Build cities, lead commanders, discover new lands, and write the history of your civilization.'**
  String get mainMenuWelcome;

  /// No description provided for @mainMenuSynopsisTitle.
  ///
  /// In en, this message translates to:
  /// **'Build · Research · Command'**
  String get mainMenuSynopsisTitle;

  /// No description provided for @mainMenuWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get mainMenuWhatsNew;

  /// No description provided for @singlePlayer.
  ///
  /// In en, this message translates to:
  /// **'Single player'**
  String get singlePlayer;

  /// No description provided for @singlePlayerSublabel.
  ///
  /// In en, this message translates to:
  /// **'Play against the computer'**
  String get singlePlayerSublabel;

  /// No description provided for @multiplayerSublabel.
  ///
  /// In en, this message translates to:
  /// **'Play online'**
  String get multiplayerSublabel;

  /// No description provided for @hotseat.
  ///
  /// In en, this message translates to:
  /// **'Hotseat'**
  String get hotseat;

  /// No description provided for @hotseatSublabel.
  ///
  /// In en, this message translates to:
  /// **'Players sharing one device'**
  String get hotseatSublabel;

  /// No description provided for @hotseatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Hotseat setup is not available yet.'**
  String get hotseatUnavailable;

  /// No description provided for @hotseatHandoffTitle.
  ///
  /// In en, this message translates to:
  /// **'Pass the device'**
  String get hotseatHandoffTitle;

  /// No description provided for @hotseatHandoffBody.
  ///
  /// In en, this message translates to:
  /// **'Give the device to {name}. Their map remains hidden until they confirm.'**
  String hotseatHandoffBody(String name);

  /// No description provided for @hotseatContinueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as {name}'**
  String hotseatContinueAs(String name);

  /// No description provided for @hotseatHandoffSwitching.
  ///
  /// In en, this message translates to:
  /// **'Preparing the next player'**
  String get hotseatHandoffSwitching;

  /// No description provided for @hotseatHandoffFailure.
  ///
  /// In en, this message translates to:
  /// **'The next local player could not be opened safely.'**
  String get hotseatHandoffFailure;

  /// No description provided for @loadGame.
  ///
  /// In en, this message translates to:
  /// **'Load game'**
  String get loadGame;

  /// No description provided for @loadGameSublabel.
  ///
  /// In en, this message translates to:
  /// **'Saved games and replays'**
  String get loadGameSublabel;

  /// No description provided for @exitGame.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitGame;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get instructions;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsTitle;

  /// No description provided for @creditsCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by {name}'**
  String creditsCreatedBy(String name);

  /// No description provided for @devlogLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Development journal: ernest.dev'**
  String get devlogLinkLabel;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Share ideas, report problems and follow development with the Age of New Worlds community.'**
  String get feedbackDescription;

  /// No description provided for @openFeedback.
  ///
  /// In en, this message translates to:
  /// **'Open r/aonw'**
  String get openFeedback;

  /// No description provided for @externalLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'External links are unavailable on this platform.'**
  String get externalLinkUnavailable;

  /// No description provided for @serverUpdateSoon.
  ///
  /// In en, this message translates to:
  /// **'A newer version is ready and will appear on this platform soon. Check your store or launcher again shortly.'**
  String get serverUpdateSoon;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @resumingGame.
  ///
  /// In en, this message translates to:
  /// **'Resuming game'**
  String get resumingGame;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// No description provided for @multiplayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get multiplayerTitle;

  /// No description provided for @multiplayerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer is unavailable in this build.'**
  String get multiplayerUnavailable;

  /// No description provided for @loadingMultiplayer.
  ///
  /// In en, this message translates to:
  /// **'Connecting to multiplayer'**
  String get loadingMultiplayer;

  /// No description provided for @multiplayerAuthenticationTitle.
  ///
  /// In en, this message translates to:
  /// **'AoNW account'**
  String get multiplayerAuthenticationTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters.'**
  String get invalidPassword;

  /// No description provided for @invalidDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name.'**
  String get invalidDisplayName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get createNewAccount;

  /// No description provided for @useExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'Use an existing account'**
  String get useExistingAccount;

  /// No description provided for @multiplayerLobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Match lobby'**
  String get multiplayerLobbyTitle;

  /// No description provided for @signedInAccount.
  ///
  /// In en, this message translates to:
  /// **'Account: {userId}'**
  String signedInAccount(String userId);

  /// No description provided for @multiplayerSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create online game'**
  String get multiplayerSetupTitle;

  /// No description provided for @multiplayerSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose your civilization and map before opening the authoritative waiting room.'**
  String get multiplayerSetupIntro;

  /// No description provided for @multiplayerTurnModeDescription.
  ///
  /// In en, this message translates to:
  /// **'All players act during one shared turn. The engine resolves it after every required submission or the authoritative timeout.'**
  String get multiplayerTurnModeDescription;

  /// No description provided for @continueToLobby.
  ///
  /// In en, this message translates to:
  /// **'Continue to lobby'**
  String get continueToLobby;

  /// No description provided for @createMultiplayerMatch.
  ///
  /// In en, this message translates to:
  /// **'Create match'**
  String get createMultiplayerMatch;

  /// No description provided for @joinMultiplayerMatch.
  ///
  /// In en, this message translates to:
  /// **'Join match'**
  String get joinMultiplayerMatch;

  /// No description provided for @matchIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Match ID'**
  String get matchIdLabel;

  /// No description provided for @playerSeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Player seat'**
  String get playerSeatLabel;

  /// No description provided for @playerSeatOne.
  ///
  /// In en, this message translates to:
  /// **'Player one'**
  String get playerSeatOne;

  /// No description provided for @playerSeatTwo.
  ///
  /// In en, this message translates to:
  /// **'Player two'**
  String get playerSeatTwo;

  /// No description provided for @playerSeatNumber.
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String playerSeatNumber(int number);

  /// No description provided for @refreshMatches.
  ///
  /// In en, this message translates to:
  /// **'Refresh matches'**
  String get refreshMatches;

  /// No description provided for @yourMatches.
  ///
  /// In en, this message translates to:
  /// **'Your matches'**
  String get yourMatches;

  /// No description provided for @noMultiplayerMatches.
  ///
  /// In en, this message translates to:
  /// **'No joined matches yet.'**
  String get noMultiplayerMatches;

  /// No description provided for @matchRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision {revision} · event offset {eventOffset}'**
  String matchRevision(int revision, int eventOffset);

  /// No description provided for @multiplayerMatchPhase.
  ///
  /// In en, this message translates to:
  /// **'Status: {phase, select, lobby{waiting room} running{in progress} finished{finished} abandoned{abandoned} other{unknown}}'**
  String multiplayerMatchPhase(String phase);

  /// No description provided for @multiplayerWaitingRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Match waiting room'**
  String get multiplayerWaitingRoomTitle;

  /// No description provided for @multiplayerReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get multiplayerReady;

  /// No description provided for @multiplayerNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get multiplayerNotReady;

  /// No description provided for @multiplayerSeatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open player seat'**
  String get multiplayerSeatOpen;

  /// No description provided for @multiplayerHumanSeat.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get multiplayerHumanSeat;

  /// No description provided for @multiplayerAiSeat.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get multiplayerAiSeat;

  /// No description provided for @multiplayerHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get multiplayerHost;

  /// No description provided for @multiplayerCurrentPlayer.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get multiplayerCurrentPlayer;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get markReady;

  /// No description provided for @markNotReady.
  ///
  /// In en, this message translates to:
  /// **'Withdraw readiness'**
  String get markNotReady;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Every human seat must be claimed and ready before the match starts.'**
  String get waitingForPlayers;

  /// No description provided for @refreshMatch.
  ///
  /// In en, this message translates to:
  /// **'Refresh match'**
  String get refreshMatch;

  /// No description provided for @leaveMultiplayerMatch.
  ///
  /// In en, this message translates to:
  /// **'Leave match'**
  String get leaveMultiplayerMatch;

  /// No description provided for @multiplayerResignTitle.
  ///
  /// In en, this message translates to:
  /// **'Resign from this match?'**
  String get multiplayerResignTitle;

  /// No description provided for @multiplayerResignBody.
  ///
  /// In en, this message translates to:
  /// **'Your participation will end immediately and this action cannot be undone.'**
  String get multiplayerResignBody;

  /// No description provided for @multiplayerResignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get multiplayerResignConfirm;

  /// No description provided for @multiplayerMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Online match'**
  String get multiplayerMatchTitle;

  /// No description provided for @multiplayerParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get multiplayerParticipants;

  /// No description provided for @multiplayerRemoveParticipant.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get multiplayerRemoveParticipant;

  /// No description provided for @multiplayerRemoveParticipantTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove participant?'**
  String get multiplayerRemoveParticipantTitle;

  /// No description provided for @multiplayerRemoveParticipantBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this match? They will no longer be able to reconnect.'**
  String multiplayerRemoveParticipantBody(String name);

  /// No description provided for @cancelDialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelDialog;

  /// No description provided for @matchIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Match: {matchId}'**
  String matchIdentifier(String matchId);

  /// No description provided for @playerIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Player: {playerId}'**
  String playerIdentifier(String playerId);

  /// No description provided for @multiplayerTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn}'**
  String multiplayerTurn(int turn);

  /// No description provided for @multiplayerSubmissionProgress.
  ///
  /// In en, this message translates to:
  /// **'Submitted {submitted} of {required}'**
  String multiplayerSubmissionProgress(int submitted, int required);

  /// No description provided for @visibleUnits.
  ///
  /// In en, this message translates to:
  /// **'Visible units: {count}'**
  String visibleUnits(int count);

  /// No description provided for @networkPhase.
  ///
  /// In en, this message translates to:
  /// **'Connection: {phase, select, connecting{connecting} ready{online} reconnecting{reconnecting} resyncing{synchronizing} failed{offline} closed{closed} other{unavailable}}'**
  String networkPhase(String phase);

  /// No description provided for @submitTurn.
  ///
  /// In en, this message translates to:
  /// **'Submit turn'**
  String get submitTurn;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @backToLobby.
  ///
  /// In en, this message translates to:
  /// **'Back to lobby'**
  String get backToLobby;

  /// No description provided for @multiplayerFailure.
  ///
  /// In en, this message translates to:
  /// **'{code, select, client_update_required{Update the client before connecting.} authentication_required{Sign in again to continue.} invalid_authentication_response{The authentication response was invalid.} authentication_identity_changed{The account identity changed during refresh.} connection_interrupted{The connection was interrupted. Reconnect to synchronize the match.} invalid_server_response{The server response failed validation.} invalid_command_sequence{The command sequence was not contiguous.} invalid_resync_sequence{The synchronized state moved backwards.} invalid_match_lifecycle{The match lifecycle response was inconsistent.} match_not_found{The match was not found.} match_not_started{The match has not been started by its host.} match_already_started{The match has already started.} host_required{Only the host can perform this action.} lobby_not_ready{Every human player must join and be ready.} participant_not_claimable{Computer-controlled seats cannot be claimed.} participant_not_active{That participant is no longer active.} invalid_kick_target{The host cannot remove itself.} player_seat_taken{That player seat is already occupied.} other{The multiplayer request could not be completed.}}'**
  String multiplayerFailure(String code);

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get helpTitle;

  /// No description provided for @helpIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Build a civilization turn by turn. The engine resolves every rule; this guide explains the decisions available in the client.'**
  String get helpIntroduction;

  /// No description provided for @helpObjectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Pursue the objective'**
  String get helpObjectiveTitle;

  /// No description provided for @helpObjectiveBody.
  ///
  /// In en, this message translates to:
  /// **'Expand, develop cities and complete the scenario objectives before your opponent. Open Strategic objectives on the map to review the authored goals.'**
  String get helpObjectiveBody;

  /// No description provided for @helpMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore and command'**
  String get helpMapTitle;

  /// No description provided for @helpMapBody.
  ///
  /// In en, this message translates to:
  /// **'Select a visible hex to inspect it. Select your unit, choose a highlighted destination and confirm the route. Keyboard, gamepad and touch controls use the same commands.'**
  String get helpMapBody;

  /// No description provided for @helpDevelopmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Develop your civilization'**
  String get helpDevelopmentTitle;

  /// No description provided for @helpDevelopmentBody.
  ///
  /// In en, this message translates to:
  /// **'Use city, research, production, worker, logistics, artifact and diplomacy panels when their actions become available.'**
  String get helpDevelopmentBody;

  /// No description provided for @helpTurnTitle.
  ///
  /// In en, this message translates to:
  /// **'End the turn deliberately'**
  String get helpTurnTitle;

  /// No description provided for @helpTurnBody.
  ///
  /// In en, this message translates to:
  /// **'Finish your actions, then end the turn. The computer completes its authoritative turn before control returns to you.'**
  String get helpTurnBody;

  /// No description provided for @helpSaveReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Save and review'**
  String get helpSaveReplayTitle;

  /// No description provided for @helpSaveReplayBody.
  ///
  /// In en, this message translates to:
  /// **'Save from the map. Continue opens the latest valid save, and Replay reviews the authoritative command history without changing the game.'**
  String get helpSaveReplayBody;

  /// No description provided for @startOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Start guided introduction'**
  String get startOnboarding;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Guided introduction'**
  String get onboardingTitle;

  /// No description provided for @onboardingProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {count}'**
  String onboardingProgress(int step, int count);

  /// No description provided for @onboardingExploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Read the map'**
  String get onboardingExploreTitle;

  /// No description provided for @onboardingExploreBody.
  ///
  /// In en, this message translates to:
  /// **'The map shows only information visible to your player. Select hexes to inspect terrain, cities and units, then pan or zoom to plan your next action.'**
  String get onboardingExploreBody;

  /// No description provided for @onboardingCommandTitle.
  ///
  /// In en, this message translates to:
  /// **'Give precise commands'**
  String get onboardingCommandTitle;

  /// No description provided for @onboardingCommandBody.
  ///
  /// In en, this message translates to:
  /// **'Available destinations and actions come from the game engine. Choose one, review the preview and confirm; rejected or stale commands never change the match.'**
  String get onboardingCommandBody;

  /// No description provided for @onboardingDevelopTitle.
  ///
  /// In en, this message translates to:
  /// **'Build a long-term advantage'**
  String get onboardingDevelopTitle;

  /// No description provided for @onboardingDevelopBody.
  ///
  /// In en, this message translates to:
  /// **'Cities, production, research, workers, logistics, artifacts and diplomacy shape your strategy. Their panels expose only actions currently allowed by the engine.'**
  String get onboardingDevelopBody;

  /// No description provided for @onboardingContinueTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue with confidence'**
  String get onboardingContinueTitle;

  /// No description provided for @onboardingContinueBody.
  ///
  /// In en, this message translates to:
  /// **'Save the authoritative match before leaving. Continue validates it in a fresh engine session, while Replay provides a read-only review of the same history.'**
  String get onboardingContinueBody;

  /// No description provided for @previousOnboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousOnboardingStep;

  /// No description provided for @nextOnboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextOnboardingStep;

  /// No description provided for @skipOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipOnboarding;

  /// No description provided for @finishOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Create a game'**
  String get finishOnboarding;

  /// No description provided for @newGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Create local game'**
  String get newGameTitle;

  /// No description provided for @singlePlayerSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Play with the computer'**
  String get singlePlayerSetupTitle;

  /// No description provided for @singlePlayerSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose your civilization and configure an authoritative local match.'**
  String get singlePlayerSetupIntro;

  /// No description provided for @hotseatSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Play in hotseat mode'**
  String get hotseatSetupTitle;

  /// No description provided for @hotseatSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Share one device. Every human view stays hidden until the next player confirms the handoff.'**
  String get hotseatSetupIntro;

  /// No description provided for @chooseCivilizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose civilization'**
  String get chooseCivilizationTitle;

  /// No description provided for @gameSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Game setup'**
  String get gameSetupTitle;

  /// No description provided for @turnModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn mode'**
  String get turnModeTitle;

  /// No description provided for @turnModeName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, sequential{Traditional} simultaneous{Simultaneous} other{Unknown}}'**
  String turnModeName(String value);

  /// No description provided for @turnModeSequentialDescription.
  ///
  /// In en, this message translates to:
  /// **'Civilizations complete and resolve their turns one after another.'**
  String get turnModeSequentialDescription;

  /// No description provided for @turnModeSimultaneousDescription.
  ///
  /// In en, this message translates to:
  /// **'You and the computer act within one shared turn before the engine resolves its common phases.'**
  String get turnModeSimultaneousDescription;

  /// No description provided for @opponentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Opponents'**
  String get opponentsTitle;

  /// No description provided for @opponentControlLabel.
  ///
  /// In en, this message translates to:
  /// **'Opponent control'**
  String get opponentControlLabel;

  /// No description provided for @opponentNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Opponent {number}'**
  String opponentNumberLabel(int number);

  /// No description provided for @humanOpponent.
  ///
  /// In en, this message translates to:
  /// **'Human player'**
  String get humanOpponent;

  /// No description provided for @aiOpponent.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get aiOpponent;

  /// No description provided for @mapSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapSetupTitle;

  /// No description provided for @mapSetupBody.
  ///
  /// In en, this message translates to:
  /// **'A compact authored 7 × 7 map for a focused two-civilization match.'**
  String get mapSetupBody;

  /// No description provided for @mapSetupDetails.
  ///
  /// In en, this message translates to:
  /// **'{mapName} · {columns} × {rows} · {players} civilizations'**
  String mapSetupDetails(String mapName, int columns, int rows, int players);

  /// No description provided for @victoryPathsTitle.
  ///
  /// In en, this message translates to:
  /// **'Victory paths'**
  String get victoryPathsTitle;

  /// No description provided for @victoryPathsBody.
  ///
  /// In en, this message translates to:
  /// **'Conquest, domination, culture and score are resolved by the game engine.'**
  String get victoryPathsBody;

  /// No description provided for @settlementToEmpireTitle.
  ///
  /// In en, this message translates to:
  /// **'From settlement to empire'**
  String get settlementToEmpireTitle;

  /// No description provided for @settlementToEmpireBody.
  ///
  /// In en, this message translates to:
  /// **'Explore, found cities, research, produce armies and build lasting advantages.'**
  String get settlementToEmpireBody;

  /// No description provided for @continueToSummary.
  ///
  /// In en, this message translates to:
  /// **'Continue to summary'**
  String get continueToSummary;

  /// No description provided for @gameSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Expedition ready'**
  String get gameSummaryTitle;

  /// No description provided for @gameSummaryIntro.
  ///
  /// In en, this message translates to:
  /// **'Review every local participant before creating the match.'**
  String get gameSummaryIntro;

  /// No description provided for @summaryModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get summaryModeLabel;

  /// No description provided for @summaryTurnModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Turns'**
  String get summaryTurnModeLabel;

  /// No description provided for @summaryCivilizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Your civilization'**
  String get summaryCivilizationLabel;

  /// No description provided for @summaryOpponentLabel.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get summaryOpponentLabel;

  /// No description provided for @summaryMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get summaryMapLabel;

  /// No description provided for @summaryFogLabel.
  ///
  /// In en, this message translates to:
  /// **'Fog of war'**
  String get summaryFogLabel;

  /// No description provided for @summaryAiLabel.
  ///
  /// In en, this message translates to:
  /// **'Computer profile'**
  String get summaryAiLabel;

  /// No description provided for @changeSetup.
  ///
  /// In en, this message translates to:
  /// **'Change setup'**
  String get changeSetup;

  /// No description provided for @localModeName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, singlePlayer{Single player} hotseat{Hotseat} other{Local game}}'**
  String localModeName(String value);

  /// No description provided for @participantControlName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, human{Human} ai{Computer} other{Unknown}}'**
  String participantControlName(String value);

  /// No description provided for @fogSettingName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, enabled{Enabled} disabled{Disabled} other{Unknown}}'**
  String fogSettingName(String value);

  /// No description provided for @defaultSecondPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get defaultSecondPlayerName;

  /// No description provided for @defaultNumberedPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String defaultNumberedPlayerName(int number);

  /// No description provided for @defaultNumberedAiName.
  ///
  /// In en, this message translates to:
  /// **'Computer {number}'**
  String defaultNumberedAiName(int number);

  /// No description provided for @scenarioLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get scenarioLabel;

  /// No description provided for @localScenarioName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, starterDuel{Starter} dravonia{Dravonia} myranth{Myranth} terenos{Terenos} verdantia{Verdantia} other{Local map}}'**
  String localScenarioName(String value);

  /// No description provided for @humanCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Your country'**
  String get humanCountryLabel;

  /// No description provided for @aiCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'AI country'**
  String get aiCountryLabel;

  /// No description provided for @aiDifficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'AI difficulty'**
  String get aiDifficultyLabel;

  /// No description provided for @aiPersonaLabel.
  ///
  /// In en, this message translates to:
  /// **'AI personality'**
  String get aiPersonaLabel;

  /// No description provided for @fogOfWarLabel.
  ///
  /// In en, this message translates to:
  /// **'Fog of war'**
  String get fogOfWarLabel;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get startGame;

  /// No description provided for @startingGame.
  ///
  /// In en, this message translates to:
  /// **'Starting game'**
  String get startingGame;

  /// No description provided for @localGameStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The local game could not be started.'**
  String get localGameStartFailed;

  /// No description provided for @saveGame.
  ///
  /// In en, this message translates to:
  /// **'Save game'**
  String get saveGame;

  /// No description provided for @savingGame.
  ///
  /// In en, this message translates to:
  /// **'Saving game'**
  String get savingGame;

  /// No description provided for @gameSaved.
  ///
  /// In en, this message translates to:
  /// **'Game saved'**
  String get gameSaved;

  /// No description provided for @saveFailure.
  ///
  /// In en, this message translates to:
  /// **'{value, select, unavailable{Saving is unavailable for this session.} exportFailed{The game could not be exported.} writeFailed{The save file could not be stored.} other{The game could not be saved.}}'**
  String saveFailure(String value);

  /// No description provided for @resumeFailure.
  ///
  /// In en, this message translates to:
  /// **'{value, select, unavailable{Saved games are unavailable on this platform.} missing{No saved game was found.} unreadable{The saved game could not be read.} incompatible{The saved game is invalid or incompatible with the current game.} other{The saved game could not be resumed.}}'**
  String resumeFailure(String value);

  /// No description provided for @loadGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Load game'**
  String get loadGameTitle;

  /// No description provided for @loadGameEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved games were found.'**
  String get loadGameEmpty;

  /// No description provided for @loadGameSingleLabel.
  ///
  /// In en, this message translates to:
  /// **'Single player · {scenario}'**
  String loadGameSingleLabel(String scenario);

  /// No description provided for @importSave.
  ///
  /// In en, this message translates to:
  /// **'Import save'**
  String get importSave;

  /// No description provided for @exportSave.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportSave;

  /// No description provided for @saveTransferUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Save import and export are unavailable on this platform.'**
  String get saveTransferUnavailable;

  /// No description provided for @saveImportCompleted.
  ///
  /// In en, this message translates to:
  /// **'Imported {map} as a separate saved game.'**
  String saveImportCompleted(String map);

  /// No description provided for @saveExportCompleted.
  ///
  /// In en, this message translates to:
  /// **'Exported {map}.'**
  String saveExportCompleted(String map);

  /// No description provided for @saveTransferFailure.
  ///
  /// In en, this message translates to:
  /// **'{value, select, unavailable{Save transfer is unavailable on this platform.} unreadable{The selected save file could not be read.} tooLarge{The selected save file exceeds the 16 MiB limit.} incompatible{The selected save is invalid or does not match an installed map, ruleset, or engine version.} missing{The selected saved game no longer exists.} writeFailed{The imported save could not be stored.} exportFailed{The save file could not be exported.} other{The save transfer could not be completed.}}'**
  String saveTransferFailure(String value);

  /// No description provided for @replayTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replayTitle;

  /// No description provided for @loadingReplay.
  ///
  /// In en, this message translates to:
  /// **'Loading replay'**
  String get loadingReplay;

  /// No description provided for @replayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Replay playback is unavailable.'**
  String get replayUnavailable;

  /// No description provided for @replayFailure.
  ///
  /// In en, this message translates to:
  /// **'{value, select, unavailable{Replay playback is unavailable on this platform.} missing{No replay was found. Save a local game first.} unreadable{The replay file could not be read.} incompatible{The replay is invalid or incompatible with the current game.} seekFailed{The requested replay frame could not be loaded.} other{The replay could not be opened.}}'**
  String replayFailure(String value);

  /// No description provided for @replayMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Replay map'**
  String get replayMapLabel;

  /// No description provided for @replayControls.
  ///
  /// In en, this message translates to:
  /// **'Replay controls'**
  String get replayControls;

  /// No description provided for @playReplay.
  ///
  /// In en, this message translates to:
  /// **'Play replay'**
  String get playReplay;

  /// No description provided for @pauseReplay.
  ///
  /// In en, this message translates to:
  /// **'Pause replay'**
  String get pauseReplay;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to main menu'**
  String get backToMenu;

  /// No description provided for @replayProgress.
  ///
  /// In en, this message translates to:
  /// **'{position} of {entryCount}'**
  String replayProgress(int position, int entryCount);

  /// No description provided for @replaySpeed.
  ///
  /// In en, this message translates to:
  /// **'{value}× speed'**
  String replaySpeed(String value);

  /// No description provided for @aiTurnRunning.
  ///
  /// In en, this message translates to:
  /// **'The computer is taking its turn.'**
  String get aiTurnRunning;

  /// No description provided for @aiTurnFailure.
  ///
  /// In en, this message translates to:
  /// **'{value, select, requestFailed{The computer turn could not be completed.} responseIncompatible{The computer turn response is incompatible with this client.} incomplete{The computer did not complete its turn within the safe command budget.} other{The computer turn could not be completed.}}'**
  String aiTurnFailure(String value);

  /// No description provided for @defaultPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get defaultPlayerName;

  /// No description provided for @defaultAiName.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get defaultAiName;

  /// No description provided for @countryName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, poland{Poland} ukraine{Ukraine} germany{Germany} france{France} unitedKingdom{United Kingdom} italy{Italy} spain{Spain} netherlands{Netherlands} sweden{Sweden} russia{Russia} unitedStates{United States} canada{Canada} china{China} korea{Korea} japan{Japan} portugal{Portugal} india{India} brazil{Brazil} indonesia{Indonesia} mexico{Mexico} turkey{Turkey} saudiArabia{Saudi Arabia} egypt{Egypt} greece{Greece} other{Unknown country}}'**
  String countryName(String value);

  /// No description provided for @aiDifficultyName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, easy{Easy} normal{Normal} hard{Hard} veryHard{Very hard} other{Unknown difficulty}}'**
  String aiDifficultyName(String value);

  /// No description provided for @aiPersonaName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, balanced{Balanced} aggressive{Aggressive} expansive{Expansive} economic{Economic} scientific{Scientific} other{Unknown personality}}'**
  String aiPersonaName(String value);

  /// No description provided for @unknownRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown route'**
  String get unknownRouteLabel;

  /// No description provided for @pageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Page unavailable'**
  String get pageUnavailable;

  /// No description provided for @unknownRouteMessage.
  ///
  /// In en, this message translates to:
  /// **'Unknown route: {location}'**
  String unknownRouteMessage(String location);

  /// No description provided for @missingRouteLocation.
  ///
  /// In en, this message translates to:
  /// **'(missing)'**
  String get missingRouteLocation;

  /// No description provided for @mapSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Map {mapId}, {cols} by {rows} hexes'**
  String mapSemanticsLabel(String mapId, int cols, int rows);

  /// No description provided for @mapInputHint.
  ///
  /// In en, this message translates to:
  /// **'Use the arrow keys or D-pad to move the map cursor and Enter or A to select.'**
  String get mapInputHint;

  /// No description provided for @noHexSelected.
  ///
  /// In en, this message translates to:
  /// **'No hex selected'**
  String get noHexSelected;

  /// No description provided for @selectedHex.
  ///
  /// In en, this message translates to:
  /// **'Selected hex {col}, {row}'**
  String selectedHex(int col, int row);

  /// No description provided for @mapViewModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change map view mode'**
  String get mapViewModeTooltip;

  /// No description provided for @mapViewGraphicUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Graphic view is unavailable for this map.'**
  String get mapViewGraphicUnavailable;

  /// No description provided for @mapViewModeGraphic.
  ///
  /// In en, this message translates to:
  /// **'Graphic'**
  String get mapViewModeGraphic;

  /// No description provided for @mapViewModeTiles.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get mapViewModeTiles;

  /// No description provided for @hexLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex {col}, {row}'**
  String hexLabel(int col, int row);

  /// No description provided for @selectionTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get selectionTerrain;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit {unitId}'**
  String unitLabel(String unitId);

  /// No description provided for @routeSummary.
  ///
  /// In en, this message translates to:
  /// **'Route: {totalCost} movement units · {remaining} remaining'**
  String routeSummary(int totalCost, int remaining);

  /// No description provided for @confirmMove.
  ///
  /// In en, this message translates to:
  /// **'Confirm move'**
  String get confirmMove;

  /// No description provided for @moveTurnCost.
  ///
  /// In en, this message translates to:
  /// **'{turns, plural, one{1 turn} other{{turns} turns}}'**
  String moveTurnCost(int turns);

  /// No description provided for @confirmMoveWithCost.
  ///
  /// In en, this message translates to:
  /// **'Confirm · {turnCost}'**
  String confirmMoveWithCost(String turnCost);

  /// No description provided for @chooseHighlightedDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose a highlighted destination.'**
  String get chooseHighlightedDestination;

  /// No description provided for @movingUnit.
  ///
  /// In en, this message translates to:
  /// **'Moving unit'**
  String get movingUnit;

  /// No description provided for @unitActionLabel.
  ///
  /// In en, this message translates to:
  /// **'{label, select, title{Unit actions} fortify{Fortify} skip{Skip} cancel{Cancel action} executing{Executing unit action} logisticsTitle{Logistics} logisticsLoading{Loading logistics options} logisticsEmpty{No logistics actions are currently available.} autoExplore{Auto explore} merchantRoute{Assign trade route} merchantTravel{Move to city} detachTroop{Detach troop} other{Unit action}}'**
  String unitActionLabel(String label);

  /// No description provided for @unitActionFailure.
  ///
  /// In en, this message translates to:
  /// **'{failure, select, requestFailed{The unit action request could not be completed.} responseIncompatible{The unit action response is incompatible with this client.} sessionUnavailable{The local game session is unavailable.} stale{The game state changed. Review the unit and try again.} matchFinished{The match has already finished.} unitUnavailable{That unit is no longer available to command.} unitBusy{That unit is busy and cannot perform this action now.} internal{The unit action could not be applied. Try again.} logisticsRequestFailed{The logistics request could not be completed.} logisticsResponseIncompatible{The logistics response is incompatible with this client.} logisticsOptionUnavailable{That logistics option is no longer available.} combatFailureRequestFailed{The combat request could not be completed.} combatFailureResponseIncompatible{The combat response is incompatible with this client.} combatFailureSessionUnavailable{The local game session is unavailable.} combatFailureTargetUnavailable{No attack preview is available for that target.} combatFailureStaleRevision{The game state changed. Review it and try again.} combatFailureMatchFinished{The match has already finished.} combatFailureAttackerNotFound{The attacking unit is no longer available.} combatFailureAttackerNotControlled{The attacking unit is not controlled by this player.} combatFailureAttackerUnavailable{The attacking unit is unavailable.} combatFailureAttackerExhausted{The attacking unit is exhausted.} combatFailureAttackerOutOfBounds{The attacking unit is outside the map.} combatFailureAttackerCannotAttack{That unit cannot attack.} combatFailureAttackTargetNotVisible{The target is not visible.} combatFailureAttackTargetOutOfBounds{The target is outside the map.} combatFailureAttackTargetNotFound{No target is present there.} combatFailureAttackTargetNotEnemy{That target is not an enemy.} combatFailureAttackTargetProtectedByTreaty{A treaty protects that target.} combatFailureAttackTargetOutOfRange{The target is out of range.} combatFailureAttackCityHasNoHealth{That city cannot be attacked.} other{The unit action could not be completed.}}'**
  String unitActionFailure(String failure);

  /// No description provided for @turnSummary.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, label{TURN {turn}} progress{Ready: {submitted} of {required}} other{TURN {turn}}}'**
  String turnSummary(String kind, int turn, int submitted, int required);

  /// No description provided for @turnText.
  ///
  /// In en, this message translates to:
  /// **'{value, select, statusActive{Your turn} statusFinished{Turn finished} statusSubmitted{Turn submitted} statusWaiting{Waiting} statusPendingAction{Action required} actionEnd{End turn} actionEnding{Ending turn} outcomeConquest{Conquest victory} outcomeDomination{Domination victory} outcomeCultural{Cultural victory} outcomeScore{Score victory} outcomeResignation{Match ended by resignation} outcomeDraw{Draw} outcomeOngoing{Match in progress} activityTitle{Activity} activityArtifact{Artifact activity} activityCity{City activity} activityResearch{Research progress} activityObjective{Strategic objective update} activityOutcome{Match outcome updated} activityCombat{Combat activity} activityDiplomacy{Diplomatic activity} activityUnit{Unit activity} activityTurn{Turn updated} activityWorker{Worker job completed} combatTitle{Combat} combatLoading{Loading combat preview} combatTarget{Target} combatDistance{Distance} combatOutgoing{Outgoing damage} combatRetaliation{Retaliation damage} combatNone{None} combatCapture{Capture city} combatDestroy{Destroy city} combatConfirm{Confirm attack} combatExecuting{Resolving combat} combatResolved{Combat resolved} combatAttackerHp{Attacker health} combatDefenderHp{Defender health} combatEventUnitAttacked{Unit attacked} combatEventCityAttacked{City attacked} combatEventCombatResolved{Combat resolved} combatEventUnitGainedExperience{Unit gained experience} combatEventUnitKilled{Unit defeated} combatEventUnitRetreated{Unit retreated} combatEventCityCaptured{City captured} combatEventCityDestroyed{City destroyed} combatEventDiplomaticScoreChanged{Diplomatic relation changed} other{Game activity}}'**
  String turnText(String value);

  /// No description provided for @turnFailure.
  ///
  /// In en, this message translates to:
  /// **'{failure, select, requestFailed{The turn request could not be completed.} responseIncompatible{The turn response is incompatible with this client.} sessionUnavailable{The local game session is unavailable.} stale_revision{The game state changed. Review it and try again.} match_finished{The match has already finished.} turn_player_not_controlled{This player cannot end the current turn.} turn_player_not_active{This player is not active.} turn_scope_invalid{The current turn scope is invalid.} turn_processor_unsupported{A required turn processor is unavailable.} turn_number_overflow{The next turn cannot be represented.} state_revision_overflow{The game revision cannot be advanced.} other{The turn could not be completed.}}'**
  String turnFailure(String failure);

  /// No description provided for @loadingMap.
  ///
  /// In en, this message translates to:
  /// **'Loading map'**
  String get loadingMap;

  /// No description provided for @mapLoadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Map loading failed'**
  String get mapLoadingFailed;

  /// No description provided for @mapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map unavailable'**
  String get mapUnavailable;

  /// No description provided for @mapAdapterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The native game adapter is unavailable on this platform.'**
  String get mapAdapterUnavailable;

  /// No description provided for @mapClientIncompatible.
  ///
  /// In en, this message translates to:
  /// **'The native game adapter is incompatible with this client.'**
  String get mapClientIncompatible;

  /// No description provided for @mapLoadSuperseded.
  ///
  /// In en, this message translates to:
  /// **'A newer map request replaced this one.'**
  String get mapLoadSuperseded;

  /// No description provided for @mapLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'The map could not be loaded.'**
  String get mapLoadFailure;

  /// No description provided for @movementRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'The movement request could not be completed.'**
  String get movementRequestFailed;

  /// No description provided for @movementResponseIncompatible.
  ///
  /// In en, this message translates to:
  /// **'The movement response is incompatible with this client.'**
  String get movementResponseIncompatible;

  /// No description provided for @movementSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The local game session is unavailable.'**
  String get movementSessionUnavailable;

  /// No description provided for @moveRejectedStale.
  ///
  /// In en, this message translates to:
  /// **'The game state changed. Review the latest position and try again.'**
  String get moveRejectedStale;

  /// No description provided for @moveRejectedUnitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That unit is no longer available to move.'**
  String get moveRejectedUnitUnavailable;

  /// No description provided for @moveRejectedUnitBusy.
  ///
  /// In en, this message translates to:
  /// **'That unit is busy and cannot move now.'**
  String get moveRejectedUnitBusy;

  /// No description provided for @moveRejectedTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That destination is not available.'**
  String get moveRejectedTargetUnavailable;

  /// No description provided for @moveRejectedMovementInsufficient.
  ///
  /// In en, this message translates to:
  /// **'The unit does not have enough movement remaining.'**
  String get moveRejectedMovementInsufficient;

  /// No description provided for @moveRejectedPathUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No valid route to that destination is available.'**
  String get moveRejectedPathUnavailable;

  /// No description provided for @moveRejectedInternal.
  ///
  /// In en, this message translates to:
  /// **'The move could not be applied. Try again.'**
  String get moveRejectedInternal;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @audioSettings.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioSettings;

  /// No description provided for @masterVolume.
  ///
  /// In en, this message translates to:
  /// **'Master volume'**
  String get masterVolume;

  /// No description provided for @cameraSettings.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraSettings;

  /// No description provided for @cameraSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Zoom sensitivity'**
  String get cameraSensitivity;

  /// No description provided for @smoothCameraMovement.
  ///
  /// In en, this message translates to:
  /// **'Smooth camera movement'**
  String get smoothCameraMovement;

  /// No description provided for @mapSettings.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapSettings;

  /// No description provided for @mapGrid.
  ///
  /// In en, this message translates to:
  /// **'Hex borders'**
  String get mapGrid;

  /// No description provided for @mapGridDescription.
  ///
  /// In en, this message translates to:
  /// **'Show black borders around map hexes.'**
  String get mapGridDescription;

  /// No description provided for @mapResourceIcons.
  ///
  /// In en, this message translates to:
  /// **'Resource icons'**
  String get mapResourceIcons;

  /// No description provided for @mapResourceIconsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show resources available on map hexes.'**
  String get mapResourceIconsDescription;

  /// No description provided for @mapTerrainIcons.
  ///
  /// In en, this message translates to:
  /// **'Terrain icons'**
  String get mapTerrainIcons;

  /// No description provided for @mapTerrainIconsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the terrain tags assigned to each hex.'**
  String get mapTerrainIconsDescription;

  /// No description provided for @mapHeightBadges.
  ///
  /// In en, this message translates to:
  /// **'Height labels'**
  String get mapHeightBadges;

  /// No description provided for @mapHeightBadgesDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the authored height of raised hexes.'**
  String get mapHeightBadgesDescription;

  /// No description provided for @mapElevationWalls.
  ///
  /// In en, this message translates to:
  /// **'Elevation walls'**
  String get mapElevationWalls;

  /// No description provided for @mapElevationWallsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show neighbor-aware depth on raised hexes.'**
  String get mapElevationWallsDescription;

  /// No description provided for @accessibilitySettings.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilitySettings;

  /// No description provided for @reducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reducedMotion;

  /// No description provided for @reducedMotionDescription.
  ///
  /// In en, this message translates to:
  /// **'Avoid nonessential animations and transitions.'**
  String get reducedMotionDescription;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @highContrastDescription.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast in the application interface.'**
  String get highContrastDescription;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get resetSettings;

  /// No description provided for @objectivesTitle.
  ///
  /// In en, this message translates to:
  /// **'Strategic objectives'**
  String get objectivesTitle;

  /// No description provided for @openObjectives.
  ///
  /// In en, this message translates to:
  /// **'Open objectives'**
  String get openObjectives;

  /// No description provided for @closeObjectives.
  ///
  /// In en, this message translates to:
  /// **'Close objectives'**
  String get closeObjectives;

  /// No description provided for @objectivesEmpty.
  ///
  /// In en, this message translates to:
  /// **'This map has no objectives.'**
  String get objectivesEmpty;

  /// No description provided for @objectivesAuthoredRules.
  ///
  /// In en, this message translates to:
  /// **'Authored map requirements. Current progress remains in the engine.'**
  String get objectivesAuthoredRules;

  /// No description provided for @objectiveType.
  ///
  /// In en, this message translates to:
  /// **'{type, select, ruins{Ruins} strategicPass{Strategic pass} holySite{Holy site} legendaryResource{Legendary resource} other{Strategic objective}}'**
  String objectiveType(String type);

  /// No description provided for @objectiveDetails.
  ///
  /// In en, this message translates to:
  /// **'Hex {col}, {row}\nRequired hold turns: {holdTurns} · Victory points: {victoryPoints} · Gold per turn: {goldPerTurn}'**
  String objectiveDetails(
    int col,
    int row,
    int holdTurns,
    int victoryPoints,
    int goldPerTurn,
  );

  /// No description provided for @matchFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Match finished'**
  String get matchFinishedTitle;

  /// No description provided for @outcomeWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner: {playerId}'**
  String outcomeWinner(String playerId);

  /// No description provided for @outcomeNoWinner.
  ///
  /// In en, this message translates to:
  /// **'No winner'**
  String get outcomeNoWinner;

  /// No description provided for @outcomeFinalScore.
  ///
  /// In en, this message translates to:
  /// **'Final score'**
  String get outcomeFinalScore;

  /// No description provided for @outcomeScoreLine.
  ///
  /// In en, this message translates to:
  /// **'{playerId}: {score}'**
  String outcomeScoreLine(String playerId, int score);

  /// No description provided for @cityText.
  ///
  /// In en, this message translates to:
  /// **'{key, select, title{City} foundingTitle{Found a city} loading{Loading city details} owner{Owner} health{Health} population{Population} territory{Territory} foundingSelection{Initial territory} foundingConfirm{Confirm city founding} foundingCancel{Cancel founding} executing{Applying city action} cityYield{Yield} food{Food} production{Production} gold{Gold} defense{Defense} workedHexes{Worked hexes} workedHexSelect{Manage worked hexes} workedHexHint{Select a highlighted controlled hex on the map.} expansion{Preferred expansion} expansionSelect{Choose expansion} expansionHint{Select a highlighted expansion hex on the map.} managementCancel{Finish map selection} foundingOpen{Plan a city} other{City}}'**
  String cityText(String key);

  /// No description provided for @cityFailure.
  ///
  /// In en, this message translates to:
  /// **'{code, select, requestFailed{The city request could not be completed.} responseIncompatible{The city response is incompatible with this client.} sessionUnavailable{The local game session is unavailable.} staleRevision{The game state changed. Review the city and try again.} matchFinished{The match has already finished.} cityFounderNotFound{The founding unit is no longer available.} cityFounderNotControlled{The founding unit is not controlled by this player.} cityFounderBusy{The founding unit is busy.} cityFounderInvalid{That unit cannot found a city.} cityFounderNoSettlers{The founding unit has no settlers.} citySiteInvalid{A city cannot be founded at that site.} cityCenterOccupied{The city center is occupied.} cityCenterClaimed{The city center is already claimed.} cityCenterTooClose{The city center is too close to another city.} cityControlledHexesInvalid{The selected initial territory is invalid.} cityNotFound{That city is no longer available.} cityNotControlled{That city is not controlled by this player.} workedHexUnavailable{That worked hex is unavailable.} workedHexLimitReached{The city has reached its worked-hex limit.} cityExpansionHexUnavailable{That expansion hex is unavailable.} stateRevisionOverflow{The game state cannot advance further.} other{The city request could not be completed.}}'**
  String cityFailure(String code);

  /// No description provided for @workerText.
  ///
  /// In en, this message translates to:
  /// **'{key, select, title{Worker} loading{Loading worker options} empty{No worker action is currently available.} executing{Applying worker action} buildCharges{Build charges} progress{Progress} assigned{Assigned hex} selectImprovement{Select} confirmImprovement{Confirm improvement} cancelJob{Cancel construction} assign{Assign to hex} cancelAssignment{Cancel assignment} buildRoad{Build road} automate{Automate} automationEvidence{Planner evidence} other{Worker}}'**
  String workerText(String key);

  /// No description provided for @workerFailure.
  ///
  /// In en, this message translates to:
  /// **'{code, select, requestFailed{The worker request could not be completed.} responseIncompatible{The worker response is incompatible with this client.} sessionUnavailable{The local game session is unavailable.} staleRevision{The game state changed. Review the worker and try again.} matchFinished{The match has already finished.} workerNotFound{The worker is no longer available.} workerNotControlled{The worker is not controlled by this player.} workerUnavailable{The worker is unavailable.} workerNoMovementPoints{The worker has no movement points.} workerQueuedPathActive{The worker has an active movement order.} workerImprovementNotSelected{Select an improvement first.} workerActionNotControlled{The pending worker action is not controlled.} workerImprovementUnavailable{That improvement is unavailable.} workerJobNotActive{The worker has no active construction.} workerAssignmentUnavailable{The worker cannot be assigned here.} workerAssignmentNotActive{The worker has no active assignment.} workerRoadUnavailable{Road construction is unavailable here.} roadConstructionExistingRoad{A road already exists here.} roadConstructionCity{A road cannot be built on a city center.} roadConstructionEnemyTerritory{A road cannot be built in enemy territory.} roadConstructionImpassableTerrain{A road cannot be built on this terrain.} workerAutomationNotActive{Worker automation is not active.} workerAutomationNoTarget{Worker automation found no target.} stateRevisionOverflow{The game state cannot advance further.} other{The worker request could not be completed.}}'**
  String workerFailure(String code);

  /// No description provided for @productionText.
  ///
  /// In en, this message translates to:
  /// **'{key, select, title{Production and resources} loading{Loading production options} executing{Updating city production} current{Current production} invested{Invested} overflow{Overflow} resources{Strategic resources} buildings{Buildings} units{Units} projects{Projects} wonders{Wonders} specializations{Specializations} rush{Rush production} cost{cost} requires{requires} empty{No option is currently available.} other{Production}}'**
  String productionText(String key);

  /// No description provided for @productionFailure.
  ///
  /// In en, this message translates to:
  /// **'{code, select, requestFailed{The production request could not be completed.} responseIncompatible{The production response is incompatible.} sessionUnavailable{The local game session is unavailable.} staleRevision{The city changed. Review production and try again.} matchFinished{The match has already finished.} cityNotFound{The city is no longer available.} cityNotControlled{The city is not controlled by this player.} buildingNotAvailable{This building is unavailable.} unitProductionInvalidResourceOption{That resource option is invalid.} unitProductionNotAvailable{This unit is unavailable.} unitProductionRequiresResource{Select a resource option.} unitProductionMissingStrategicResource{Required resources are missing.} unitProductionRequiresCoast{This unit requires a coastal city.} unitSupplyLimitReached{The unit supply limit is reached.} wonderNotAvailable{This wonder is unavailable.} citySpecializationLocked{This specialization is locked.} citySpecializationUnchanged{This specialization is already active.} citySpecializationMissingBuilding{A required building is missing.} productionQueueEmpty{The production queue is empty.} projectCannotBeRushed{A continuous project cannot be rushed.} rushProductionUnavailable{Rush production is unavailable.} stateRevisionOverflow{The game state cannot advance further.} other{The production request could not be completed.}}'**
  String productionFailure(String code);

  /// No description provided for @artifactText.
  ///
  /// In en, this message translates to:
  /// **'{key, select, title{World artifacts} executing{Applying artifact action} startExcavation{Start excavation} storeInCity{Store in city} trade{Trade artifact} targetPlayer{Target player} offeredGold{Offered gold} onMap{On map at} carried{Carried by} stored{Stored in} excavation{Excavation at} turnsRemaining{turns remaining} other{Artifact}}'**
  String artifactText(String key);

  /// No description provided for @artifactName.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, ancientImperialCrown{Ancient Imperial Crown} astronomersTablets{Astronomer’s Tablets} prophetMask{Prophet’s Mask} heroSword{Hero’s Sword} merchantsSeal{Merchant’s Seal} firstPeoplesChronicle{First People’s Chronicle} templeReliquary{Temple Reliquary} queensMirror{Queen’s Mirror} other{World artifact}}'**
  String artifactName(String kind);

  /// No description provided for @artifactOnMap.
  ///
  /// In en, this message translates to:
  /// **'On map at {col}, {row}'**
  String artifactOnMap(int col, int row);

  /// No description provided for @artifactCarriedBy.
  ///
  /// In en, this message translates to:
  /// **'Carried by {unitName}'**
  String artifactCarriedBy(String unitName);

  /// No description provided for @artifactStoredIn.
  ///
  /// In en, this message translates to:
  /// **'Stored in {cityName}'**
  String artifactStoredIn(String cityName);

  /// No description provided for @artifactExcavationAt.
  ///
  /// In en, this message translates to:
  /// **'Excavation at {col}, {row} · {remainingTurns} turns remaining'**
  String artifactExcavationAt(int col, int row, int remainingTurns);

  /// No description provided for @artifactFailure.
  ///
  /// In en, this message translates to:
  /// **'{code, select, requestFailed{The artifact request could not be completed.} responseIncompatible{The artifact response is incompatible.} sessionUnavailable{The local game session is unavailable.} staleRevision{The game state changed. Review the artifact and try again.} matchFinished{The match has already finished.} unitNotFound{The unit is no longer available.} unitNotControlled{The unit is not controlled by this player.} unitUnavailable{The unit is unavailable.} unitAlreadyCarryingArtifact{The unit already carries an artifact.} artifactNotFound{The artifact is no longer available.} unitNotCarryingArtifact{The unit is not carrying an artifact.} cityNotFound{The city is no longer available.} cityNotControlled{The city is not controlled by this player.} unitNotInCity{The unit is not in that city.} cityArtifactSlotFull{The city artifact slot is full.} artifactTradeActorUnavailable{This player cannot trade artifacts.} artifactTradeTargetInvalid{The target player is invalid.} artifactTradeGoldInvalid{The gold offer is invalid.} artifactTradeBlockedByWar{Artifact trade is blocked by war.} artifactTradeGoldUnavailable{The offered gold is unavailable.} offeredArtifactUnavailable{The offered artifact is unavailable.} targetArtifactSlotUnavailable{The target has no artifact slot.} stateRevisionOverflow{The game state cannot advance further.} other{The artifact request could not be completed.}}'**
  String artifactFailure(String code);

  /// No description provided for @researchText.
  ///
  /// In en, this message translates to:
  /// **'{key, select, title{Research} open{Open research} close{Close research} loading{Loading research options} retry{Retry} selecting{Selecting technology} selectionRequired{Select a technology to continue} sciencePerTurn{Science per turn} overflow{Stored science} active{Active technology} none{None} cost{Cost} progress{Progress} boost{Boost discount} prerequisites{Prerequisites} blockedBy{Blocked by} unlocks{Unlocks} choose{Select} other{Research}}'**
  String researchText(String key);

  /// No description provided for @researchAvailability.
  ///
  /// In en, this message translates to:
  /// **'{value, select, unlocked{Researched} active{Active} available{Available} lockedByPrerequisites{Prerequisites required} lockedByTechnology{Blocked by technology} other{Unavailable}}'**
  String researchAvailability(String value);

  /// No description provided for @researchUnlock.
  ///
  /// In en, this message translates to:
  /// **'{kind}: {target}'**
  String researchUnlock(String kind, String target);

  /// No description provided for @researchFailure.
  ///
  /// In en, this message translates to:
  /// **'{code, select, requestFailed{The research request could not be completed.} responseIncompatible{The research response is incompatible.} sessionUnavailable{The local game session is unavailable.} staleRevision{Research changed. Review the options and try again.} technologyPlayerNotControlled{This player cannot select research.} technologyNotAvailable{This technology is not available.} stateRevisionOverflow{The game state cannot advance further.} other{The research request could not be completed.}}'**
  String researchFailure(String code);

  /// No description provided for @diplomacyText.
  ///
  /// In en, this message translates to:
  /// **'{key, select, title{Diplomacy} open{Open diplomacy} close{Close diplomacy} noContacts{No contacts} compose{New action} target{Counterpart} action{Action} send{Send} invalid{Review the form terms.} pending{Sending diplomacy action} relations{Relations} proposals{Proposals} messages{Private messages} agreements{Resource agreements} accept{Accept} reject{Reject} amount{Amount} goldPerTurn{Gold per turn} duration{Turns} resource{Resource} offered{Offered resource} requested{Requested resource} topic{Topic} other{Diplomacy}}'**
  String diplomacyText(String key);

  /// No description provided for @diplomacyFailure.
  ///
  /// In en, this message translates to:
  /// **'{code, select, requestFailed{The diplomacy request could not be completed.} responseIncompatible{The diplomacy response is incompatible.} sessionUnavailable{The local game session is unavailable.} staleRevision{Diplomacy changed. Review the current state and try again.} matchFinished{The match has already finished.} diplomacyPlayerNotControlled{This player cannot issue diplomacy actions.} diplomacyTargetNotDiscovered{This counterpart is not available.} diplomacyProposalNotAllowed{This proposal is not allowed.} diplomacyDuplicateProposal{This proposal already exists.} diplomacyProposalNotFound{This proposal no longer exists.} diplomacyProposalPaymentUnavailable{The proposal payment is unavailable.} diplomacyMessageCooldown{A similar message was sent too recently.} diplomacyDuplicateMessage{This message already exists.} diplomacyMessageNotFound{This message no longer exists.} diplomacyMessageUnavailable{This message cannot be used now.} diplomacyTruceActive{A truce is active.} diplomacyWarAlreadyActive{War is already active.} diplomacyInvalidGoldAmount{The gold amount is invalid.} diplomacyGoldGiftBlockedByRelation{This relation blocks gold gifts.} diplomacyGoldUnavailable{The required gold is unavailable.} diplomacyGoldGiftUnavailable{This gold gift is unavailable.} invalidResourceTradeTarget{The resource trade target is invalid.} invalidResourceTradeResource{The selected resource is invalid.} invalidResourceTradeTerms{The resource trade terms are invalid.} resourceTradeBlockedByWar{War blocks this resource trade.} resourceTradeGoldUnavailable{Trade gold is unavailable.} resourceTradeAlreadyActive{This resource trade is already active.} invalidResourceTradeAgreementId{The agreement identity is invalid.} resourceTradeAgreementIdConflict{The agreement identity conflicts.} resourceTradeExportUnavailable{The resource export is unavailable.} resourceTradeOfferUnavailable{The offered resource is unavailable.} resourceTradeRequestUnavailable{The requested resource is unavailable.} stateRevisionOverflow{The game state cannot advance further.} other{The diplomacy request could not be completed.}}'**
  String diplomacyFailure(String code);

  /// No description provided for @presentationName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, farm{Farm} riverFarm{River farm} mine{Mine} lumberMill{Lumber mill} pasture{Pasture} camp{Camp} quarry{Quarry} fishingBoats{Fishing boats} orchard{Orchard} plantation{Plantation} vineyard{Vineyard} tradingPost{Trading post} prospectorCamp{Prospector camp} horseRanch{Horse ranch} pearlDivers{Pearl divers} coalShaft{Coal shaft} oilWell{Oil well} bauxiteMine{Bauxite mine} uraniumMine{Uranium mine} wheat{Wheat} fish{Fish} deer{Deer} sheep{Sheep} rice{Rice} cow{Cow} apple{Apple} banana{Banana} citrus{Citrus} gold{Gold} silver{Silver} gems{Gems} silk{Silk} spices{Spices} cotton{Cotton} grapes{Grapes} ivory{Ivory} pearls{Pearls} coffee{Coffee} cocoa{Cocoa} tobacco{Tobacco} sugar{Sugar} iron{Iron} coal{Coal} oil{Oil} aluminium{Aluminium} uranium{Uranium} horses{Horses} marble{Marble} commander{Commander} warrior{Warrior} archer{Archer} settler{Settler} worker{Worker} merchant{Merchant} scout{Scout} spearman{Spearman} cavalry{Cavalry} catapult{Catapult} heavyInfantry{Heavy infantry} fieldCannon{Field cannon} rifleman{Rifleman} tank{Tank} scoutShip{Scout ship} warship{Warship} reconPlane{Recon plane} building{Building} improvement{Improvement} resourceVisibility{Resource visibility} unit{Unit} wonder{Wonder} friendly{Friendly} neutral{Neutral} hostile{Hostile} truce{Truce} war{War} warning{Warning} complaint{Complaint} request{Request} praise{Praise} threat{Threat} cooperation{Cooperation} troopsNearCities{Troops near cities} citiesTooClose{Cities too close} blockedRoutes{Blocked routes} withdrawScouts{Withdraw scouts} avoidEscalation{Avoid escalation} commonEnemy{Common enemy} expansionProvocation{Expansion provocation} peacefulPraise{Peaceful praise} conciliatory{Conciliatory} evasive{Evasive} aggressive{Aggressive} declareWar{Declare war} goldGift{Gold gift} friendshipProposal{Friendship proposal} truceProposal{Truce proposal} message{Message} resourceTrade{Resource trade} resourceExchange{Resource exchange} granary{Granary} workshop{Workshop} industry{Industry} other{{value}}}'**
  String presentationName(String value);

  /// No description provided for @technologyName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, agriculture{Agriculture} woodworking{Woodworking} mining{Mining} animalHusbandry{Animal husbandry} hunting{Hunting} fishing{Fishing} craftsmanship{Craftsmanship} trade{Trade} storage{Storage} waterEngineering{Water engineering} stoneworking{Stoneworking} militaryOrganization{Military organization} advancedTrade{Advanced trade} construction{Construction} navigation{Navigation} irrigation{Irrigation} banking{Banking} engineering{Engineering} metallurgy{Metallurgy} horsebackRiding{Horseback riding} ironWorking{Iron working} coalMining{Coal mining} machinery{Machinery} administration{Administration} logistics{Logistics} shipbuilding{Shipbuilding} tactics{Tactics} economy{Economy} urbanization{Urbanization} fortifications{Fortifications} strategy{Strategy} specialization{Specialization} writing{Writing} mathematics{Mathematics} medicine{Medicine} civilService{Civil service} siegecraft{Siegecraft} cartography{Cartography} guilds{Guilds} law{Law} education{Education} urbanPlanning{Urban planning} navalDoctrine{Naval doctrine} steel{Steel} bureaucracy{Bureaucracy} nationalism{Nationalism} scientificMethod{Scientific method} steamPower{Steam power} electricity{Electricity} combustion{Combustion} flight{Flight} massProduction{Mass production} radio{Radio} nuclearPhysics{Nuclear physics} other{{value}}}'**
  String technologyName(String value);

  /// No description provided for @cityContentName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, growth{Growth} industry{Industry} commerce{Commerce} science{Science} military{Military} wealth{Wealth} research{Research} granary{Granary} waterMill{Water mill} workshop{Workshop} storehouse{Storehouse} housing{Housing} merchantHall{Merchant hall} stonemason{Stonemason} barracks{Barracks} marketplace{Marketplace} port{Port} aqueduct{Aqueduct} forge{Forge} stable{Stable} bank{Bank} buildersGuild{Builders’ guild} factory{Factory} lighthouse{Lighthouse} trainingGrounds{Training grounds} townHall{Town hall} monument{Monument} archive{Archive} academy{Academy} university{University} observatory{Observatory} laboratory{Laboratory} reactor{Reactor} courthouse{Courthouse} court{Court} governorsOffice{Governor’s office} surveyorsOffice{Surveyors’ office} planningOffice{Planning office} apothecary{Apothecary} publicBaths{Public baths} hospital{Hospital} ministries{Ministries} walls{Walls} armory{Armory} siegeWorkshop{Siege workshop} citadel{Citadel} warCollege{War college} conscriptionOffice{Conscription office} borderFort{Border fort} airfield{Airfield} artisansGuild{Artisans’ guild} masterWorkshop{Master workshop} steelworks{Steelworks} railDepot{Rail depot} powerPlant{Power plant} assemblyPlant{Assembly plant} refinery{Refinery} mapRoom{Map room} shipyard{Shipyard} dryDock{Dry dock} navalAcademy{Naval academy} harborCustoms{Harbor customs} museum{Museum} parliament{Parliament} broadcastTower{Broadcast tower} worldFairGrounds{World fair grounds} greatLibrary{Great Library} hangingGardens{Hanging Gardens} greatWall{Great Wall} petra{Petra} centralBank{Central Bank} imperialUniversity{Imperial University} grandCathedral{Grand Cathedral} motherFactory{Mother Factory} nationalObservatory{National Observatory} svalbardSeedVault{Svalbard Seed Vault} grandExposition{Grand Exposition} other{Unknown city content}}'**
  String cityContentName(String value);

  /// No description provided for @diplomaticProposalName.
  ///
  /// In en, this message translates to:
  /// **'{value, select, friendship{Friendship} truce{Truce} other{Unknown proposal}}'**
  String diplomaticProposalName(String value);

  /// No description provided for @mapFeedbackText.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, roadCompleted{+Road} unitKilled{KO} unitRetreated{Retreat} artifactExcavationStarted{Excavate} artifactCarried{Artifact carried} artifactStored{Artifact stored} other{}}'**
  String mapFeedbackText(String kind);

  /// No description provided for @mapYieldShort.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, food{FOOD} production{PROD} gold{GOLD} defense{DEF} other{}}'**
  String mapYieldShort(String kind);
}

class _AonwLocalizationsDelegate
    extends LocalizationsDelegate<AonwLocalizations> {
  const _AonwLocalizationsDelegate();

  @override
  Future<AonwLocalizations> load(Locale locale) {
    return SynchronousFuture<AonwLocalizations>(
      lookupAonwLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AonwLocalizationsDelegate old) => false;
}

AonwLocalizations lookupAonwLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AonwLocalizationsEn();
    case 'pl':
      return AonwLocalizationsPl();
  }

  throw FlutterError(
    'AonwLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
