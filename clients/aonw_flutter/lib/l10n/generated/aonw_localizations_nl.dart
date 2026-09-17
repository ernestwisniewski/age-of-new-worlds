// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AonwLocalizationsNl extends AonwLocalizations {
  AonwLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get moveTargeting => 'Verplaatsen';

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String get mainMenuTitle => 'Hoofdmenu';

  @override
  String get mainMenuWelcome =>
      'Welkom bij Age of New Worlds. Bouw steden, leid commandanten, ontdek nieuwe landen en schrijf de geschiedenis van je beschaving.';

  @override
  String get mainMenuSynopsisTitle => 'Bouw · Onderzoek · Voer het bevel';

  @override
  String get mainMenuWhatsNew => 'Wat is er nieuw';

  @override
  String get singlePlayer => 'Eén speler';

  @override
  String get singlePlayerSublabel => 'Speel tegen de computer';

  @override
  String get multiplayerSublabel => 'Speel online';

  @override
  String get hotseat => 'Hotseat';

  @override
  String get hotseatSublabel => 'Spelers delen één apparaat';

  @override
  String get hotseatUnavailable => 'Hotseat instellen is nog niet beschikbaar.';

  @override
  String get hotseatHandoffTitle => 'Geef het apparaat door';

  @override
  String hotseatHandoffBody(String name) {
    return 'Geef het apparaat aan $name. De kaart blijft verborgen totdat deze speler bevestigt.';
  }

  @override
  String hotseatContinueAs(String name) {
    return 'Doorgaan als $name';
  }

  @override
  String get hotseatHandoffSwitching => 'De volgende speler wordt voorbereid';

  @override
  String get hotseatHandoffFailure =>
      'De sessie van de volgende lokale speler kon niet veilig worden geopend.';

  @override
  String get loadGame => 'Spel laden';

  @override
  String get loadGameSublabel => 'Opgeslagen spellen en herhalingen';

  @override
  String get exitGame => 'Afsluiten';

  @override
  String get instructions => 'Handleiding';

  @override
  String get creditsTitle => 'Credits';

  @override
  String creditsCreatedBy(String name) {
    return 'Gemaakt door $name';
  }

  @override
  String get devlogLinkLabel => 'Ontwikkeldagboek: ernest.dev';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackDescription =>
      'Deel ideeën, meld problemen en volg de ontwikkeling met de community van Age of New Worlds.';

  @override
  String get openFeedback => 'r/aonw openen';

  @override
  String get externalLinkUnavailable =>
      'Externe links zijn niet beschikbaar op dit platform.';

  @override
  String get serverUpdateSoon =>
      'Er staat een nieuwe versie klaar die binnenkort op dit platform verschijnt. Kijk over enige tijd opnieuw in je winkel of launcher.';

  @override
  String get continueGame => 'Doorgaan';

  @override
  String get resumingGame => 'Spel wordt hervat';

  @override
  String get newGame => 'Nieuw spel';

  @override
  String get multiplayerTitle => 'Multiplayer';

  @override
  String get multiplayerUnavailable =>
      'Multiplayer is niet beschikbaar in deze versie.';

  @override
  String get loadingMultiplayer => 'Verbinding maken met multiplayer';

  @override
  String get multiplayerAuthenticationTitle => 'AoNW-account';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Wachtwoord';

  @override
  String get displayNameLabel => 'Weergavenaam';

  @override
  String get invalidEmail => 'Voer een geldig e-mailadres in.';

  @override
  String get invalidPassword => 'Gebruik minstens 12 tekens.';

  @override
  String get invalidDisplayName => 'Voer een weergavenaam in.';

  @override
  String get signIn => 'Inloggen';

  @override
  String get signOut => 'Uitloggen';

  @override
  String get createAccount => 'Account aanmaken';

  @override
  String get createNewAccount => 'Een nieuw account aanmaken';

  @override
  String get useExistingAccount => 'Een bestaand account gebruiken';

  @override
  String get multiplayerLobbyTitle => 'Partijlobby';

  @override
  String signedInAccount(String userId) {
    return 'Account: $userId';
  }

  @override
  String get multiplayerSetupTitle => 'Online spel aanmaken';

  @override
  String get multiplayerSetupIntro =>
      'Kies je beschaving en kaart voordat je de door de server beheerde wachtkamer opent.';

  @override
  String get multiplayerTurnModeDescription =>
      'Alle spelers handelen tijdens één gedeelde beurt. De spelengine verwerkt die nadat alle vereiste bevestigingen binnen zijn of de termijn van de server is verstreken.';

  @override
  String get continueToLobby => 'Doorgaan naar de lobby';

  @override
  String get createMultiplayerMatch => 'Partij aanmaken';

  @override
  String get joinMultiplayerMatch => 'Deelnemen aan partij';

  @override
  String get matchIdLabel => 'Partij-ID';

  @override
  String get playerSeatLabel => 'Spelersplaats';

  @override
  String get playerSeatOne => 'Speler één';

  @override
  String get playerSeatTwo => 'Speler twee';

  @override
  String playerSeatNumber(int number) {
    return 'Speler $number';
  }

  @override
  String get refreshMatches => 'Partijen vernieuwen';

  @override
  String get yourMatches => 'Jouw partijen';

  @override
  String get noMultiplayerMatches => 'Je neemt nog niet deel aan een partij.';

  @override
  String matchRevision(int revision, int eventOffset) {
    return 'Revisie $revision · gebeurtenispositie $eventOffset';
  }

  @override
  String multiplayerMatchPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'lobby': 'wachtkamer',
      'running': 'bezig',
      'finished': 'afgelopen',
      'abandoned': 'verlaten',
      'other': 'onbekend',
    });
    return 'Status: $_temp0';
  }

  @override
  String get multiplayerWaitingRoomTitle => 'Wachtkamer van de partij';

  @override
  String multiplayerPresence(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'ready': 'Gereed',
      'connected': 'Verbonden',
      'connecting': 'Verbinden',
      'reconnecting': 'Opnieuw verbinden',
      'offline': 'Offline',
      'open': 'Vrije plek',
      'other': 'Offline',
    });
    return '$_temp0';
  }

  @override
  String get multiplayerReady => 'Klaar';

  @override
  String get multiplayerNotReady => 'Niet klaar';

  @override
  String get multiplayerSeatOpen => 'Vrije spelersplaats';

  @override
  String get multiplayerHumanSeat => 'Mens';

  @override
  String get multiplayerAiSeat => 'Computer';

  @override
  String get multiplayerHost => 'Host';

  @override
  String get multiplayerCurrentPlayer => 'Jij';

  @override
  String get markReady => 'Gereedheid bevestigen';

  @override
  String get markNotReady => 'Gereedheid intrekken';

  @override
  String get waitingForPlayers =>
      'Elke menselijke speler moet verbonden en gereed zijn voordat de wedstrijd begint.';

  @override
  String get refreshMatch => 'Partij vernieuwen';

  @override
  String get leaveMultiplayerMatch => 'Partij verlaten';

  @override
  String get multiplayerResignTitle => 'Deze partij opgeven?';

  @override
  String get multiplayerResignBody =>
      'Je deelname eindigt onmiddellijk. Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get multiplayerResignConfirm => 'Opgeven';

  @override
  String get multiplayerMatchTitle => 'Online partij';

  @override
  String get multiplayerParticipants => 'Deelnemers';

  @override
  String get multiplayerRemoveParticipant => 'Verwijderen';

  @override
  String get multiplayerRemoveParticipantTitle => 'Deelnemer verwijderen?';

  @override
  String multiplayerRemoveParticipantBody(String name) {
    return '$name uit deze partij verwijderen? Deze speler kan daarna niet opnieuw verbinden.';
  }

  @override
  String get cancelDialog => 'Annuleren';

  @override
  String matchIdentifier(String matchId) {
    return 'Partij: $matchId';
  }

  @override
  String playerIdentifier(String playerId) {
    return 'Speler: $playerId';
  }

  @override
  String multiplayerTurn(int turn) {
    return 'Beurt $turn';
  }

  @override
  String multiplayerSubmissionProgress(int submitted, int required) {
    return 'Bevestigd: $submitted van $required';
  }

  @override
  String visibleUnits(int count) {
    return 'Zichtbare eenheden: $count';
  }

  @override
  String networkPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'connecting': 'verbinden',
      'ready': 'online',
      'reconnecting': 'opnieuw verbinden',
      'resyncing': 'synchroniseren',
      'failed': 'offline',
      'closed': 'gesloten',
      'other': 'niet beschikbaar',
    });
    return 'Verbinding: $_temp0';
  }

  @override
  String get submitTurn => 'Beurt bevestigen';

  @override
  String get reconnect => 'Opnieuw verbinden';

  @override
  String get backToLobby => 'Terug naar de lobby';

  @override
  String multiplayerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'client_update_required':
          'Werk de client bij voordat je verbinding maakt.',
      'authentication_required': 'Log opnieuw in om door te gaan.',
      'invalid_authentication_response':
          'Het authenticatieantwoord was ongeldig.',
      'authentication_identity_changed':
          'De accountidentiteit is tijdens het vernieuwen veranderd.',
      'connection_interrupted':
          'De verbinding is onderbroken. Verbind opnieuw om de partij te synchroniseren.',
      'invalid_server_response':
          'Het serverantwoord heeft de validatie niet doorstaan.',
      'invalid_command_sequence': 'De opdrachtenreeks was niet aaneengesloten.',
      'invalid_resync_sequence':
          'De gesynchroniseerde toestand is teruggegaan.',
      'invalid_match_lifecycle':
          'Het antwoord over het partijverloop was tegenstrijdig.',
      'match_not_found': 'De partij is niet gevonden.',
      'match_not_started': 'De host heeft de partij nog niet gestart.',
      'match_already_started': 'De partij is al begonnen.',
      'host_required': 'Alleen de host kan deze actie uitvoeren.',
      'lobby_not_ready':
          'Elke menselijke speler moet verbonden en gereed zijn voordat de wedstrijd begint.',
      'participant_not_claimable':
          'Computerbestuurde plaatsen kunnen niet worden overgenomen.',
      'participant_not_active': 'Die deelnemer is niet meer actief.',
      'invalid_kick_target': 'De host kan zichzelf niet verwijderen.',
      'player_seat_taken': 'Die spelersplaats is al bezet.',
      'other': 'Het multiplayerverzoek kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String get helpTitle => 'Hoe speel je';

  @override
  String get helpIntroduction =>
      'Bouw beurt voor beurt een beschaving op. De spelengine past alle regels toe; deze gids legt de beschikbare beslissingen in de client uit.';

  @override
  String get helpObjectiveTitle => 'Streef je doel na';

  @override
  String get helpObjectiveBody =>
      'Breid uit, ontwikkel steden en voltooi de scenariodoelen vóór je tegenstander. Open de strategische doelen op de kaart om de vastgelegde doelen te bekijken.';

  @override
  String get helpMapTitle => 'Verken en voer het bevel';

  @override
  String get helpMapBody =>
      'Selecteer een zichtbare hex om die te inspecteren. Selecteer je eenheid, kies een gemarkeerde bestemming en bevestig de route. Toetsenbord, gamepad en aanraakbediening gebruiken dezelfde opdrachten.';

  @override
  String get helpDevelopmentTitle => 'Ontwikkel je beschaving';

  @override
  String get helpDevelopmentBody =>
      'Gebruik de panelen voor steden, onderzoek, productie, werkers, logistiek, artefacten en diplomatie zodra hun acties beschikbaar zijn.';

  @override
  String get helpTurnTitle => 'Beëindig de beurt bewust';

  @override
  String get helpTurnBody =>
      'Rond je acties af en beëindig dan de beurt. De computer voltooit zijn door de spelengine gecontroleerde beurt voordat jij weer de controle krijgt.';

  @override
  String get helpSaveReplayTitle => 'Opslaan en terugkijken';

  @override
  String get helpSaveReplayBody =>
      'Sla op vanuit de kaart. Doorgaan opent het laatste geldige opgeslagen spel. Een herhaling toont de geschiedenis van bevestigde opdrachten zonder het spel te veranderen.';

  @override
  String get startOnboarding => 'Begeleide introductie starten';

  @override
  String get onboardingTitle => 'Begeleide introductie';

  @override
  String onboardingProgress(int step, int count) {
    return 'Stap $step van $count';
  }

  @override
  String get onboardingExploreTitle => 'Lees de kaart';

  @override
  String get onboardingExploreBody =>
      'De kaart toont alleen informatie die jouw speler kan zien. Selecteer hexen om terrein, steden en eenheden te inspecteren. Verschuif de kaart of zoom in om je volgende actie te plannen.';

  @override
  String get onboardingCommandTitle => 'Geef nauwkeurige opdrachten';

  @override
  String get onboardingCommandBody =>
      'Beschikbare bestemmingen en acties komen van de spelengine. Kies een optie, bekijk het voorbeeld en bevestig. Afgewezen of verouderde opdrachten veranderen de partij nooit.';

  @override
  String get onboardingDevelopTitle => 'Bouw een blijvend voordeel op';

  @override
  String get onboardingDevelopBody =>
      'Steden, productie, onderzoek, werkers, logistiek, artefacten en diplomatie bepalen je strategie. Hun panelen tonen alleen acties die de spelengine op dat moment toestaat.';

  @override
  String get onboardingContinueTitle => 'Ga met vertrouwen verder';

  @override
  String get onboardingContinueBody =>
      'Sla de bevestigde partijtoestand op voordat je vertrekt. Doorgaan valideert die in een nieuwe sessie van de spelengine. Een herhaling laat je dezelfde geschiedenis bekijken zonder die te veranderen.';

  @override
  String get previousOnboardingStep => 'Vorige';

  @override
  String get nextOnboardingStep => 'Volgende';

  @override
  String get skipOnboarding => 'Overslaan';

  @override
  String get finishOnboarding => 'Een spel aanmaken';

  @override
  String get newGameTitle => 'Lokaal spel aanmaken';

  @override
  String get singlePlayerSetupTitle => 'Tegen de computer spelen';

  @override
  String get singlePlayerSetupIntro => 'Kies je beschaving en stel je spel in.';

  @override
  String get hotseatSetupTitle => 'In Hotseat-modus spelen';

  @override
  String get hotseatSetupIntro =>
      'Deel één apparaat. De weergave van elke menselijke speler blijft verborgen totdat de volgende speler de overdracht bevestigt.';

  @override
  String get chooseCivilizationTitle => 'Beschaving kiezen';

  @override
  String get gameSetupTitle => 'Spelinstellingen';

  @override
  String get turnModeTitle => 'Beurtmodus';

  @override
  String turnModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'sequential': 'Traditioneel',
      'simultaneous': 'Gelijktijdig',
      'other': 'Onbekend',
    });
    return '$_temp0';
  }

  @override
  String get turnModeSequentialDescription =>
      'Beschavingen voltooien en verwerken hun beurten na elkaar.';

  @override
  String get turnModeSimultaneousDescription =>
      'Jij en de computer handelen tijdens één gedeelde beurt voordat de spelengine de gemeenschappelijke fasen verwerkt.';

  @override
  String get opponentsTitle => 'Tegenstanders';

  @override
  String get opponentControlLabel => 'Besturing tegenstander';

  @override
  String opponentNumberLabel(int number) {
    return 'Tegenstander $number';
  }

  @override
  String get humanOpponent => 'Menselijke speler';

  @override
  String get aiOpponent => 'Computer';

  @override
  String get mapSetupTitle => 'Kaart';

  @override
  String get mapSetupBody =>
      'Een compacte, ontworpen kaart van 7 × 7 vakken voor een gerichte partij tussen twee beschavingen.';

  @override
  String mapSetupDetails(String mapName, int columns, int rows, int players) {
    return '$mapName · $columns × $rows · $players beschavingen';
  }

  @override
  String get victoryPathsTitle => 'Wegen naar de overwinning';

  @override
  String get victoryPathsBody =>
      'De spelengine bepaalt overwinningen door verovering, dominantie, cultuur en punten.';

  @override
  String get settlementToEmpireTitle => 'Van nederzetting tot rijk';

  @override
  String get settlementToEmpireBody =>
      'Verken, sticht steden, doe onderzoek, vorm legers en bouw blijvende voordelen op.';

  @override
  String get continueToSummary => 'Doorgaan naar overzicht';

  @override
  String get gameSummaryTitle => 'Expeditie gereed';

  @override
  String get gameSummaryIntro =>
      'Controleer alle lokale deelnemers voordat je de partij aanmaakt.';

  @override
  String get summaryModeLabel => 'Modus';

  @override
  String get summaryTurnModeLabel => 'Beurten';

  @override
  String get summaryCivilizationLabel => 'Jouw beschaving';

  @override
  String get summaryOpponentLabel => 'Tegenstander';

  @override
  String get summaryMapLabel => 'Kaart';

  @override
  String get summaryFogLabel => 'Oorlogsmist';

  @override
  String get summaryAiLabel => 'Computerprofiel';

  @override
  String get changeSetup => 'Instellingen wijzigen';

  @override
  String localModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'singlePlayer': 'Eén speler',
      'hotseat': 'Hotseat',
      'other': 'Lokaal spel',
    });
    return '$_temp0';
  }

  @override
  String participantControlName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'human': 'Mens',
      'ai': 'Computer',
      'other': 'Onbekend',
    });
    return '$_temp0';
  }

  @override
  String fogSettingName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'enabled': 'Ingeschakeld',
      'disabled': 'Uitgeschakeld',
      'other': 'Onbekend',
    });
    return '$_temp0';
  }

  @override
  String get defaultSecondPlayerName => 'Speler 2';

  @override
  String defaultNumberedPlayerName(int number) {
    return 'Speler $number';
  }

  @override
  String defaultNumberedAiName(int number) {
    return 'Computer $number';
  }

  @override
  String get scenarioLabel => 'Kaart';

  @override
  String localScenarioName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'starterDuel': 'Startkaart',
      'dravonia': 'Dravonia',
      'myranth': 'Myranth',
      'terenos': 'Terenos',
      'verdantia': 'Verdantia',
      'other': 'Lokale kaart',
    });
    return '$_temp0';
  }

  @override
  String get humanCountryLabel => 'Jouw land';

  @override
  String get aiCountryLabel => 'AI-land';

  @override
  String get aiDifficultyLabel => 'AI-moeilijkheid';

  @override
  String get aiPersonaLabel => 'AI-persoonlijkheid';

  @override
  String get fogOfWarLabel => 'Oorlogsmist';

  @override
  String get startGame => 'Spel starten';

  @override
  String get startingGame => 'Spel wordt gestart';

  @override
  String get localGameStartFailed => 'Het lokale spel kon niet worden gestart.';

  @override
  String get saveGame => 'Spel opslaan';

  @override
  String get savingGame => 'Spel wordt opgeslagen';

  @override
  String get gameSaved => 'Spel opgeslagen';

  @override
  String saveFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Opslaan is niet beschikbaar voor deze sessie.',
      'exportFailed': 'Het spel kon niet worden geëxporteerd.',
      'writeFailed': 'Het opslagbestand kon niet worden bewaard.',
      'other': 'Het spel kon niet worden opgeslagen.',
    });
    return '$_temp0';
  }

  @override
  String resumeFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'Opgeslagen spellen zijn niet beschikbaar op dit platform.',
      'missing': 'Er is geen opgeslagen spel gevonden.',
      'unreadable': 'Het opgeslagen spel kon niet worden gelezen.',
      'incompatible':
          'Het opgeslagen spel is ongeldig of niet compatibel met het huidige spel.',
      'other': 'Het opgeslagen spel kon niet worden hervat.',
    });
    return '$_temp0';
  }

  @override
  String get loadGameTitle => 'Spel laden';

  @override
  String get loadGameEmpty => 'Er zijn geen opgeslagen spellen gevonden.';

  @override
  String loadGameSingleLabel(String scenario) {
    return 'Eén speler · $scenario';
  }

  @override
  String get importSave => 'Opgeslagen spel importeren';

  @override
  String get exportSave => 'Exporteren';

  @override
  String get saveTransferUnavailable =>
      'Het importeren en exporteren van opgeslagen spellen is niet beschikbaar op dit platform.';

  @override
  String saveImportCompleted(String map) {
    return '$map is als afzonderlijk opgeslagen spel geïmporteerd.';
  }

  @override
  String saveExportCompleted(String map) {
    return '$map is geëxporteerd.';
  }

  @override
  String saveTransferFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'Het overzetten van opgeslagen spellen is niet beschikbaar op dit platform.',
      'unreadable': 'Het geselecteerde opslagbestand kon niet worden gelezen.',
      'tooLarge':
          'Het geselecteerde opslagbestand overschrijdt de limiet van 16 MiB.',
      'incompatible':
          'Het geselecteerde opgeslagen spel is ongeldig of komt niet overeen met een geïnstalleerde kaart, regelset of versie van de spelengine.',
      'missing': 'Het geselecteerde opgeslagen spel bestaat niet meer.',
      'writeFailed': 'Het geïmporteerde spel kon niet worden opgeslagen.',
      'exportFailed': 'Het opslagbestand kon niet worden geëxporteerd.',
      'other': 'Het opgeslagen spel kon niet worden overgezet.',
    });
    return '$_temp0';
  }

  @override
  String get replayTitle => 'Herhaling';

  @override
  String get loadingReplay => 'Herhaling wordt geladen';

  @override
  String get replayUnavailable => 'Herhalingen afspelen is niet beschikbaar.';

  @override
  String replayFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'Herhalingen afspelen is niet beschikbaar op dit platform.',
      'missing': 'Er is geen herhaling gevonden. Sla eerst een lokaal spel op.',
      'unreadable': 'Het herhalingsbestand kon niet worden gelezen.',
      'incompatible':
          'De herhaling is ongeldig of niet compatibel met het huidige spel.',
      'seekFailed':
          'De gevraagde stap van de herhaling kon niet worden geladen.',
      'other': 'De herhaling kon niet worden geopend.',
    });
    return '$_temp0';
  }

  @override
  String get replayMapLabel => 'Herhalingskaart';

  @override
  String get replayControls => 'Herhalingsbediening';

  @override
  String get playReplay => 'Herhaling afspelen';

  @override
  String get pauseReplay => 'Herhaling pauzeren';

  @override
  String get backToMenu => 'Terug naar het hoofdmenu';

  @override
  String replayProgress(int position, int entryCount) {
    return '$position van $entryCount';
  }

  @override
  String replaySpeed(String value) {
    return 'Snelheid $value×';
  }

  @override
  String get aiTurnRunning => 'De computer is aan de beurt.';

  @override
  String aiTurnFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'requestFailed': 'De computerbeurt kon niet worden voltooid.',
      'responseIncompatible':
          'Het antwoord op de computerbeurt is niet compatibel met deze client.',
      'incomplete':
          'De computer heeft zijn beurt niet binnen de veilige opdrachtenlimiet voltooid.',
      'other': 'De computerbeurt kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String get defaultPlayerName => 'Speler';

  @override
  String get defaultAiName => 'Computer';

  @override
  String countryName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'poland': 'Polen',
      'ukraine': 'Oekraïne',
      'germany': 'Duitsland',
      'france': 'Frankrijk',
      'unitedKingdom': 'Verenigd Koninkrijk',
      'italy': 'Italië',
      'spain': 'Spanje',
      'netherlands': 'Nederland',
      'sweden': 'Zweden',
      'russia': 'Rusland',
      'unitedStates': 'Verenigde Staten',
      'canada': 'Canada',
      'china': 'China',
      'korea': 'Korea',
      'japan': 'Japan',
      'portugal': 'Portugal',
      'india': 'India',
      'brazil': 'Brazilië',
      'indonesia': 'Indonesië',
      'mexico': 'Mexico',
      'turkey': 'Turkije',
      'saudiArabia': 'Saoedi-Arabië',
      'egypt': 'Egypte',
      'greece': 'Griekenland',
      'other': 'Onbekend land',
    });
    return '$_temp0';
  }

  @override
  String aiDifficultyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'easy': 'Makkelijk',
      'normal': 'Normaal',
      'hard': 'Moeilijk',
      'veryHard': 'Zeer moeilijk',
      'other': 'Onbekende moeilijkheid',
    });
    return '$_temp0';
  }

  @override
  String aiPersonaName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'balanced': 'Evenwichtig',
      'aggressive': 'Agressief',
      'expansive': 'Expansionistisch',
      'economic': 'Economisch',
      'scientific': 'Wetenschappelijk',
      'other': 'Onbekende persoonlijkheid',
    });
    return '$_temp0';
  }

  @override
  String get unknownRouteLabel => 'Onbekende pagina';

  @override
  String get pageUnavailable => 'Pagina niet beschikbaar';

  @override
  String unknownRouteMessage(String location) {
    return 'Onbekende pagina: $location';
  }

  @override
  String get missingRouteLocation => '(ontbreekt)';

  @override
  String mapSemanticsLabel(String mapId, int cols, int rows) {
    return 'Kaart $mapId, $cols bij $rows hexen';
  }

  @override
  String get mapInputHint =>
      'Gebruik WASD of de pijltjestoetsen om de camera te verschuiven, Enter om te selecteren, M voor verplaatsen, I om te inspecteren, R om de kaartweergave te wisselen, vierkante haakjes voor openstaande acties en Spatie voor de volgende actie of om de beurt te beëindigen. Gebruik Tab om bedieningselementen te focussen.';

  @override
  String get noHexSelected => 'Geen hex geselecteerd';

  @override
  String selectedHex(int col, int row) {
    return 'Geselecteerde hex $col, $row';
  }

  @override
  String get mapViewModeTooltip => 'Kaartweergave wijzigen';

  @override
  String get mapViewGraphicUnavailable =>
      'Grafische weergave is niet beschikbaar voor deze kaart.';

  @override
  String get mapViewModeGraphic => 'Grafisch';

  @override
  String get mapViewModeTiles => 'Tegels';

  @override
  String hexLabel(int col, int row) {
    return 'Hex $col, $row';
  }

  @override
  String get selectionTerrain => 'Terrein';

  @override
  String unitLabel(String unitId) {
    return 'Eenheid $unitId';
  }

  @override
  String routeSummary(int totalCost, int remaining) {
    return 'Route: $totalCost bewegingspunten · $remaining resterend';
  }

  @override
  String get confirmMove => 'Verplaatsing bevestigen';

  @override
  String moveTurnCost(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns beurten',
      one: '1 beurt',
    );
    return '$_temp0';
  }

  @override
  String confirmMoveWithCost(String turnCost) {
    return 'Bevestigen · $turnCost';
  }

  @override
  String get chooseHighlightedDestination => 'Kies een gemarkeerde bestemming.';

  @override
  String get movingUnit => 'Eenheid wordt verplaatst';

  @override
  String unitActionLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'title': 'Eenheidsacties',
      'fortify': 'Verschansen',
      'skip': 'Overslaan',
      'cancel': 'Actie annuleren',
      'executing': 'Eenheidsactie wordt uitgevoerd',
      'logisticsTitle': 'Logistiek',
      'logisticsLoading': 'Logistieke opties worden geladen',
      'logisticsEmpty': 'Er zijn momenteel geen logistieke acties beschikbaar.',
      'autoExplore': 'Automatisch verkennen',
      'merchantRoute': 'Handelsroute toewijzen',
      'merchantTravel': 'Naar stad verplaatsen',
      'detachTroop': 'Troep afsplitsen',
      'other': 'Eenheidsactie',
    });
    return '$_temp0';
  }

  @override
  String unitActionFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed':
          'Het verzoek voor de eenheidsactie kon niet worden voltooid.',
      'responseIncompatible':
          'Het antwoord op de eenheidsactie is niet compatibel met deze client.',
      'sessionUnavailable': 'De lokale spelsessie is niet beschikbaar.',
      'stale':
          'De speltoestand is veranderd. Controleer de eenheid en probeer het opnieuw.',
      'matchFinished': 'De partij is al afgelopen.',
      'unitUnavailable': 'Die eenheid kan geen opdrachten meer ontvangen.',
      'unitBusy': 'Die eenheid is bezig en kan deze actie nu niet uitvoeren.',
      'internal':
          'De eenheidsactie kon niet worden toegepast. Probeer het opnieuw.',
      'logisticsRequestFailed':
          'Het logistieke verzoek kon niet worden voltooid.',
      'logisticsResponseIncompatible':
          'Het logistieke antwoord is niet compatibel met deze client.',
      'logisticsOptionUnavailable':
          'Die logistieke optie is niet meer beschikbaar.',
      'combatFailureRequestFailed':
          'Het gevechtsverzoek kon niet worden voltooid.',
      'combatFailureResponseIncompatible':
          'Het gevechtsantwoord is niet compatibel met deze client.',
      'combatFailureSessionUnavailable':
          'De lokale spelsessie is niet beschikbaar.',
      'combatFailureTargetUnavailable':
          'Er is geen aanvalsvoorbeeld beschikbaar voor dat doel.',
      'combatFailureStaleRevision':
          'De speltoestand is veranderd. Controleer die en probeer het opnieuw.',
      'combatFailureMatchFinished': 'De partij is al afgelopen.',
      'combatFailureAttackerNotFound':
          'De aanvallende eenheid is niet meer beschikbaar.',
      'combatFailureAttackerNotControlled':
          'Deze speler bestuurt de aanvallende eenheid niet.',
      'combatFailureAttackerUnavailable':
          'De aanvallende eenheid is niet beschikbaar.',
      'combatFailureAttackerExhausted': 'De aanvallende eenheid is uitgeput.',
      'combatFailureAttackerOutOfBounds':
          'De aanvallende eenheid bevindt zich buiten de kaart.',
      'combatFailureAttackerCannotAttack': 'Die eenheid kan niet aanvallen.',
      'combatFailureAttackTargetNotVisible': 'Het doel is niet zichtbaar.',
      'combatFailureAttackTargetOutOfBounds':
          'Het doel bevindt zich buiten de kaart.',
      'combatFailureAttackTargetNotFound': 'Daar is geen doel aanwezig.',
      'combatFailureAttackTargetNotEnemy': 'Dat doel is geen vijand.',
      'combatFailureAttackTargetProtectedByTreaty':
          'Een verdrag beschermt dat doel.',
      'combatFailureAttackTargetOutOfRange': 'Het doel is buiten bereik.',
      'combatFailureAttackCityHasNoHealth':
          'Die stad kan niet worden aangevallen.',
      'other': 'De eenheidsactie kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String turnSummary(String kind, int turn, int submitted, int required) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'label': 'BEURT $turn',
      'progress': 'Klaar: $submitted van $required',
      'other': 'BEURT $turn',
    });
    return '$_temp0';
  }

  @override
  String turnText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'statusActive': 'Jouw beurt',
      'statusFinished': 'Beurt voltooid',
      'statusSubmitted': 'Beurt bevestigd',
      'statusWaiting': 'Wachten',
      'statusPendingAction': 'Actie vereist',
      'actionEnd': 'Beurt beëindigen',
      'actionSubmit': 'Beurt bevestigen',
      'actionSubmitting': 'Beurt bevestigen…',
      'actionEnding': 'Beurt wordt beëindigd',
      'outcomeConquest': 'Veroveringsoverwinning',
      'outcomeDomination': 'Dominantieoverwinning',
      'outcomeCultural': 'Culturele overwinning',
      'outcomeScore': 'Puntenoverwinning',
      'outcomeResignation': 'Partij geëindigd door opgave',
      'outcomeDraw': 'Gelijkspel',
      'outcomeOngoing': 'Partij bezig',
      'activityTitle': 'Activiteit',
      'activityArtifact': 'Artefactactiviteit',
      'activityCity': 'Stadsactiviteit',
      'activityResearch': 'Onderzoeksvoortgang',
      'activityObjective': 'Strategisch doel bijgewerkt',
      'activityOutcome': 'Partijresultaat bijgewerkt',
      'activityCombat': 'Gevechtsactiviteit',
      'activityDiplomacy': 'Diplomatieke activiteit',
      'activityUnit': 'Eenheidsactiviteit',
      'activityTurn': 'Beurt bijgewerkt',
      'activityWorker': 'Werkerstaak voltooid',
      'combatTitle': 'Gevecht',
      'combatLoading': 'Gevechtsvoorbeeld wordt geladen',
      'combatTarget': 'Doel',
      'combatDistance': 'Afstand',
      'combatOutgoing': 'Toegebrachte schade',
      'combatRetaliation': 'Schade door tegenaanval',
      'combatNone': 'Geen',
      'combatCapture': 'Stad innemen',
      'combatDestroy': 'Stad vernietigen',
      'combatConfirm': 'Aanval bevestigen',
      'combatExecuting': 'Gevecht wordt verwerkt',
      'combatResolved': 'Gevecht verwerkt',
      'combatAttackerHp': 'Gezondheid aanvaller',
      'combatDefenderHp': 'Gezondheid verdediger',
      'combatEventUnitAttacked': 'Eenheid aangevallen',
      'combatEventCityAttacked': 'Stad aangevallen',
      'combatEventCombatResolved': 'Gevecht verwerkt',
      'combatEventUnitGainedExperience': 'Eenheid heeft ervaring opgedaan',
      'combatEventUnitKilled': 'Eenheid verslagen',
      'combatEventUnitRetreated': 'Eenheid teruggetrokken',
      'combatEventCityCaptured': 'Stad ingenomen',
      'combatEventCityDestroyed': 'Stad vernietigd',
      'combatEventDiplomaticScoreChanged': 'Diplomatieke relatie gewijzigd',
      'other': 'Spelactiviteit',
    });
    return '$_temp0';
  }

  @override
  String turnFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'Het beurtverzoek kon niet worden voltooid.',
      'responseIncompatible':
          'Het beurtantwoord is niet compatibel met deze client.',
      'sessionUnavailable': 'De lokale spelsessie is niet beschikbaar.',
      'stale_revision':
          'De speltoestand is veranderd. Controleer die en probeer het opnieuw.',
      'match_finished': 'De partij is al afgelopen.',
      'turn_player_not_controlled':
          'Deze speler kan de huidige beurt niet beëindigen.',
      'turn_player_not_active': 'Deze speler is niet actief.',
      'turn_scope_invalid': 'Het bereik van de huidige beurt is ongeldig.',
      'turn_processor_unsupported':
          'Een vereiste beurtverwerking is niet beschikbaar.',
      'turn_number_overflow':
          'Het volgende beurtnummer overschrijdt de toegestane limiet.',
      'state_revision_overflow':
          'De spelrevisie kan niet verder worden verhoogd.',
      'other': 'De beurt kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String get loadingMap => 'Kaart wordt geladen';

  @override
  String get mapLoadingFailed => 'Kaart laden mislukt';

  @override
  String get mapUnavailable => 'Kaart niet beschikbaar';

  @override
  String get mapAdapterUnavailable =>
      'De native speladapter is niet beschikbaar op dit platform.';

  @override
  String get mapClientIncompatible =>
      'De native speladapter is niet compatibel met deze client.';

  @override
  String get mapLoadSuperseded =>
      'Een nieuwer kaartverzoek heeft dit verzoek vervangen.';

  @override
  String get mapLoadFailure => 'De kaart kon niet worden geladen.';

  @override
  String get movementRequestFailed =>
      'Het verplaatsingsverzoek kon niet worden voltooid.';

  @override
  String get movementResponseIncompatible =>
      'Het verplaatsingsantwoord is niet compatibel met deze client.';

  @override
  String get movementSessionUnavailable =>
      'De lokale spelsessie is niet beschikbaar.';

  @override
  String get moveRejectedStale =>
      'De speltoestand is veranderd. Controleer de nieuwste positie en probeer het opnieuw.';

  @override
  String get moveRejectedUnitUnavailable =>
      'Die eenheid is niet meer beschikbaar om te verplaatsen.';

  @override
  String get moveRejectedUnitBusy =>
      'Die eenheid is bezig en kan nu niet verplaatsen.';

  @override
  String get moveRejectedTargetUnavailable =>
      'Die bestemming is niet beschikbaar.';

  @override
  String get moveRejectedMovementInsufficient =>
      'De eenheid heeft niet genoeg bewegingspunten over.';

  @override
  String get moveRejectedPathUnavailable =>
      'Er is geen geldige route naar die bestemming beschikbaar.';

  @override
  String get moveRejectedInternal =>
      'De verplaatsing kon niet worden toegepast. Probeer het opnieuw.';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get openSettings => 'Instellingen openen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get audioSettings => 'Audio';

  @override
  String get cameraSettings => 'Camera';

  @override
  String get cameraSensitivity => 'Zoomgevoeligheid';

  @override
  String get animationSettings => 'Animaties';

  @override
  String get showUnitMovementAnimations =>
      'Bewegingsanimaties van eenheden tonen';

  @override
  String get showUnitIdleAnimations => 'Rustanimaties van eenheden tonen';

  @override
  String get showRouteAnimations => 'Animaties van geplande routes tonen';

  @override
  String get showCombatAnimations => 'Gevechtsanimaties tonen';

  @override
  String get cinematicCamera => 'Filmische camera';

  @override
  String get smoothCameraMovement => 'Soepele camerabeweging';

  @override
  String get mapSettings => 'Kaart';

  @override
  String get mapGrid => 'Hexranden';

  @override
  String get mapGridDescription =>
      'Zwarte randen rond hexen op de kaart tonen.';

  @override
  String get mapResourceIcons => 'Grondstofpictogrammen';

  @override
  String get mapResourceIconsDescription =>
      'Beschikbare grondstoffen op hexen tonen.';

  @override
  String get mapTerrainIcons => 'Terreinpictogrammen';

  @override
  String get mapTerrainIconsDescription =>
      'De terreinkenmerken van elke hex tonen.';

  @override
  String get mapHeightBadges => 'Hoogtelabels';

  @override
  String get mapHeightBadgesDescription =>
      'De vastgelegde hoogte van verhoogde hexen tonen.';

  @override
  String get mapElevationWalls => 'Hoogtewanden';

  @override
  String get mapElevationWallsDescription =>
      'Diepte bij verhoogde hexen tonen, rekening houdend met hun buren.';

  @override
  String get accessibilitySettings => 'Toegankelijkheid';

  @override
  String get reducedMotion => 'Beweging verminderen';

  @override
  String get reducedMotionDescription =>
      'Niet-essentiële animaties en overgangen vermijden.';

  @override
  String get highContrast => 'Hoog contrast';

  @override
  String get highContrastDescription =>
      'Het contrast van de gebruikersinterface verhogen.';

  @override
  String get resetSettings => 'Standaardwaarden herstellen';

  @override
  String get objectivesTitle => 'Strategische doelen';

  @override
  String get openObjectives => 'Doelen openen';

  @override
  String get closeObjectives => 'Doelen sluiten';

  @override
  String get objectivesEmpty => 'Deze kaart heeft geen doelen.';

  @override
  String objectiveControlProgress(String player, int turns, int required) {
    return 'Beheerst door $player\nVoortgang: $turns / $required';
  }

  @override
  String get objectiveControlUnknown => 'Geen bekende eigenaar';

  @override
  String get objectivesAuthoredRules =>
      'Beheers deze locaties gedurende het vereiste aantal beurten.';

  @override
  String objectiveType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'ruins': 'Ruïnes',
      'strategicPass': 'Strategische pas',
      'holySite': 'Heilige plaats',
      'legendaryResource': 'Legendarische grondstof',
      'other': 'Strategisch doel',
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
    return 'Hex $col, $row\nVereiste bezettingsbeurten: $holdTurns · Overwinningspunten: $victoryPoints · Goud per beurt: $goldPerTurn';
  }

  @override
  String get matchFinishedTitle => 'Partij afgelopen';

  @override
  String outcomeWinner(String playerId) {
    return 'Winnaar: $playerId';
  }

  @override
  String get outcomeNoWinner => 'Geen winnaar';

  @override
  String get outcomeFinalScore => 'Eindscore';

  @override
  String outcomeScoreLine(String playerId, int score) {
    return '$playerId: $score';
  }

  @override
  String cityText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Stad',
      'foundingTitle': 'Een stad stichten',
      'loading': 'Stadsgegevens worden geladen',
      'owner': 'Eigenaar',
      'health': 'Gezondheid',
      'population': 'Bevolking',
      'territory': 'Gebied',
      'foundingSelection': 'Begingebied',
      'foundingConfirm': 'Stadsstichting bevestigen',
      'foundingCancel': 'Stichting annuleren',
      'executing': 'Stadsactie wordt toegepast',
      'cityYield': 'Opbrengst',
      'food': 'Voedsel',
      'production': 'Productie',
      'gold': 'Goud',
      'defense': 'Verdediging',
      'workedHexes': 'Bewerkte hexen',
      'workedHexSelect': 'Bewerkte hexen beheren',
      'workedHexHint':
          'Selecteer een gemarkeerde hex onder jouw controle op de kaart.',
      'expansion': 'Gewenste uitbreiding',
      'expansionSelect': 'Uitbreiding kiezen',
      'expansionHint': 'Selecteer een gemarkeerde uitbreidingshex op de kaart.',
      'managementCancel': 'Kaartselectie afronden',
      'foundingOpen': 'Een stad plannen',
      'other': 'Stad',
    });
    return '$_temp0';
  }

  @override
  String cityFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Het stadsverzoek kon niet worden voltooid.',
      'responseIncompatible':
          'Het stadsantwoord is niet compatibel met deze client.',
      'sessionUnavailable': 'De lokale spelsessie is niet beschikbaar.',
      'staleRevision':
          'De speltoestand is veranderd. Controleer de stad en probeer het opnieuw.',
      'matchFinished': 'De partij is al afgelopen.',
      'cityFounderNotFound': 'De stichtende eenheid is niet meer beschikbaar.',
      'cityFounderNotControlled':
          'Deze speler bestuurt de stichtende eenheid niet.',
      'cityFounderBusy': 'De stichtende eenheid is bezig.',
      'cityFounderInvalid': 'Die eenheid kan geen stad stichten.',
      'cityFounderNoSettlers': 'De stichtende eenheid heeft geen kolonisten.',
      'citySiteInvalid': 'Op die plaats kan geen stad worden gesticht.',
      'cityCenterOccupied': 'Het stadscentrum is bezet.',
      'cityCenterClaimed': 'Het stadscentrum is al opgeëist.',
      'cityCenterTooClose':
          'Het stadscentrum ligt te dicht bij een andere stad.',
      'cityControlledHexesInvalid':
          'Het geselecteerde begingebied is ongeldig.',
      'cityNotFound': 'Die stad is niet meer beschikbaar.',
      'cityNotControlled': 'Deze speler bestuurt die stad niet.',
      'workedHexUnavailable': 'Die bewerkte hex is niet beschikbaar.',
      'workedHexLimitReached':
          'De stad heeft haar limiet voor bewerkte hexen bereikt.',
      'cityExpansionHexUnavailable': 'Die uitbreidingshex is niet beschikbaar.',
      'stateRevisionOverflow':
          'De speltoestand kan niet verder worden bijgewerkt.',
      'other': 'Het stadsverzoek kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String workerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Werker',
      'loading': 'Werkeropties worden geladen',
      'empty': 'Er is momenteel geen werkeractie beschikbaar.',
      'executing': 'Werkeractie wordt toegepast',
      'buildCharges': 'Bouwacties',
      'progress': 'Voortgang',
      'assigned': 'Toegewezen hex',
      'openActions': 'Hex verbeteren',
      'closeActions': 'Selectie annuleren',
      'selectImprovement': 'Selecteren',
      'confirmImprovement': 'Verbetering bevestigen',
      'cancelJob': 'Bouw annuleren',
      'assign': 'Aan hex toewijzen',
      'cancelAssignment': 'Toewijzing annuleren',
      'buildRoad': 'Weg aanleggen',
      'automate': 'Automatiseren',
      'plannedWork': 'Gepland werk',
      'other': 'Werker',
    });
    return '$_temp0';
  }

  @override
  String workerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Het werkerverzoek kon niet worden voltooid.',
      'responseIncompatible':
          'Het werkerantwoord is niet compatibel met deze client.',
      'sessionUnavailable': 'De lokale spelsessie is niet beschikbaar.',
      'staleRevision':
          'De speltoestand is veranderd. Controleer de werker en probeer het opnieuw.',
      'matchFinished': 'De partij is al afgelopen.',
      'workerNotFound': 'De werker is niet meer beschikbaar.',
      'workerNotControlled': 'Deze speler bestuurt de werker niet.',
      'workerUnavailable': 'De werker is niet beschikbaar.',
      'workerNoMovementPoints': 'De werker heeft geen bewegingspunten.',
      'workerQueuedPathActive':
          'De werker heeft een actieve verplaatsingsopdracht.',
      'workerImprovementNotSelected': 'Selecteer eerst een verbetering.',
      'workerActionNotControlled':
          'Deze speler beheert de openstaande werkeractie niet.',
      'workerImprovementUnavailable': 'Die verbetering is niet beschikbaar.',
      'workerJobNotActive': 'De werker heeft geen actieve bouwopdracht.',
      'workerAssignmentUnavailable':
          'De werker kan hier niet worden toegewezen.',
      'workerAssignmentNotActive': 'De werker heeft geen actieve toewijzing.',
      'workerRoadUnavailable': 'Hier kan geen weg worden aangelegd.',
      'roadConstructionExistingRoad': 'Hier ligt al een weg.',
      'roadConstructionCity':
          'Op een stadscentrum kan geen weg worden aangelegd.',
      'roadConstructionEnemyTerritory':
          'In vijandelijk gebied kan geen weg worden aangelegd.',
      'roadConstructionImpassableTerrain':
          'Op dit terrein kan geen weg worden aangelegd.',
      'workerAutomationNotActive': 'Werkerautomatisering is niet actief.',
      'workerAutomationNoTarget':
          'Werkerautomatisering heeft geen doel gevonden.',
      'stateRevisionOverflow':
          'De speltoestand kan niet verder worden bijgewerkt.',
      'other': 'Het werkerverzoek kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String productionText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Productie en grondstoffen',
      'loading': 'Productieopties worden geladen',
      'executing': 'Stadsproductie wordt bijgewerkt',
      'current': 'Huidige productie',
      'invested': 'Geïnvesteerd',
      'overflow': 'Overschot',
      'resources': 'Strategische grondstoffen',
      'buildings': 'Gebouwen',
      'units': 'Eenheden',
      'projects': 'Projecten',
      'wonders': 'Wereldwonderen',
      'specializations': 'Specialisaties',
      'rush': 'Productie versnellen',
      'cost': 'kosten',
      'requires': 'vereist',
      'empty': 'Er is momenteel geen optie beschikbaar.',
      'choose': 'Kies een productiedoel voor deze stad.',
      'ready': 'Klaar voor voltooiing',
      'spawnBlocked': 'Wachten op een vrij veld',
      'noEstimate': 'Geen tijdschatting',
      'continuous': 'Doorlopend project',
      'futureBuildings': 'Toekomstige gebouwen',
      'futureBuildingsHint': 'Ontgrendel deze gebouwen door onderzoek.',
      'completedBuildings': 'Voltooide gebouwen',
      'produce': 'Produceren',
      'inProgress': 'Bezig',
      'other': 'Productie',
    });
    return '$_temp0';
  }

  @override
  String productionFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Het productieverzoek kon niet worden voltooid.',
      'responseIncompatible': 'Het productieantwoord is niet compatibel.',
      'sessionUnavailable': 'De lokale spelsessie is niet beschikbaar.',
      'staleRevision':
          'De stad is veranderd. Controleer de productie en probeer het opnieuw.',
      'matchFinished': 'De partij is al afgelopen.',
      'cityNotFound': 'De stad is niet meer beschikbaar.',
      'cityNotControlled': 'Deze speler bestuurt de stad niet.',
      'buildingNotAvailable': 'Dit gebouw is niet beschikbaar.',
      'unitProductionInvalidResourceOption': 'Die grondstofoptie is ongeldig.',
      'unitProductionNotAvailable': 'Deze eenheid is niet beschikbaar.',
      'unitProductionRequiresResource': 'Selecteer een grondstofoptie.',
      'unitProductionMissingStrategicResource':
          'Vereiste grondstoffen ontbreken.',
      'unitProductionRequiresCoast': 'Deze eenheid vereist een kuststad.',
      'unitSupplyLimitReached':
          'De bevoorradingslimiet voor eenheden is bereikt.',
      'wonderNotAvailable': 'Dit wereldwonder is niet beschikbaar.',
      'citySpecializationLocked': 'Deze specialisatie is vergrendeld.',
      'citySpecializationUnchanged': 'Deze specialisatie is al actief.',
      'citySpecializationMissingBuilding': 'Een vereist gebouw ontbreekt.',
      'productionQueueEmpty': 'De productiewachtrij is leeg.',
      'projectCannotBeRushed':
          'Een doorlopend project kan niet worden versneld.',
      'rushProductionUnavailable': 'Productie versnellen is niet beschikbaar.',
      'stateRevisionOverflow':
          'De speltoestand kan niet verder worden bijgewerkt.',
      'other': 'Het productieverzoek kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String artifactText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Wereldartefacten',
      'executing': 'Artefactactie wordt toegepast',
      'startExcavation': 'Opgraving starten',
      'storeInCity': 'In stad opslaan',
      'trade': 'Artefact verhandelen',
      'targetPlayer': 'Ontvangende speler',
      'offeredGold': 'Aangeboden goud',
      'onMap': 'Op de kaart bij',
      'carried': 'Gedragen door',
      'stored': 'Opgeslagen in',
      'excavation': 'Opgraving bij',
      'turnsRemaining': 'beurten resterend',
      'other': 'Artefact',
    });
    return '$_temp0';
  }

  @override
  String artifactName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ancientImperialCrown': 'Oude keizerskroon',
      'astronomersTablets': 'Tabletten van de astronoom',
      'prophetMask': 'Masker van de profeet',
      'heroSword': 'Zwaard van de held',
      'merchantsSeal': 'Zegel van de koopman',
      'firstPeoplesChronicle': 'Kroniek van het eerste volk',
      'templeReliquary': 'Tempelreliekschrijn',
      'queensMirror': 'Spiegel van de koningin',
      'other': 'Wereldartefact',
    });
    return '$_temp0';
  }

  @override
  String artifactOnMap(int col, int row) {
    return 'Op de kaart bij $col, $row';
  }

  @override
  String artifactCarriedBy(String unitName) {
    return 'Gedragen door $unitName';
  }

  @override
  String artifactStoredIn(String cityName) {
    return 'Opgeslagen in $cityName';
  }

  @override
  String artifactExcavationAt(int col, int row, int remainingTurns) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingTurns,
      locale: localeName,
      other: '$remainingTurns beurten resterend',
      one: '1 beurt resterend',
    );
    return 'Opgraving bij $col, $row · $_temp0';
  }

  @override
  String artifactFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Het artefactverzoek kon niet worden voltooid.',
      'responseIncompatible': 'Het artefactantwoord is niet compatibel.',
      'sessionUnavailable': 'De lokale spelsessie is niet beschikbaar.',
      'staleRevision':
          'De speltoestand is veranderd. Controleer het artefact en probeer het opnieuw.',
      'matchFinished': 'De partij is al afgelopen.',
      'unitNotFound': 'De eenheid is niet meer beschikbaar.',
      'unitNotControlled': 'Deze speler bestuurt de eenheid niet.',
      'unitUnavailable': 'De eenheid is niet beschikbaar.',
      'unitAlreadyCarryingArtifact': 'De eenheid draagt al een artefact.',
      'artifactNotFound': 'Het artefact is niet meer beschikbaar.',
      'unitNotCarryingArtifact': 'De eenheid draagt geen artefact.',
      'cityNotFound': 'De stad is niet meer beschikbaar.',
      'cityNotControlled': 'Deze speler bestuurt de stad niet.',
      'unitNotInCity': 'De eenheid bevindt zich niet in die stad.',
      'cityArtifactSlotFull': 'De artefactplaats van de stad is vol.',
      'artifactTradeActorUnavailable':
          'Deze speler kan geen artefacten verhandelen.',
      'artifactTradeTargetInvalid': 'De ontvangende speler is ongeldig.',
      'artifactTradeGoldInvalid': 'Het goudaanbod is ongeldig.',
      'artifactTradeBlockedByWar': 'Oorlog blokkeert de artefacthandel.',
      'artifactTradeGoldUnavailable':
          'Het aangeboden goud is niet beschikbaar.',
      'offeredArtifactUnavailable':
          'Het aangeboden artefact is niet beschikbaar.',
      'targetArtifactSlotUnavailable':
          'De ontvanger heeft geen artefactplaats.',
      'stateRevisionOverflow':
          'De speltoestand kan niet verder worden bijgewerkt.',
      'other': 'Het artefactverzoek kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String researchText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'recommendations': 'Aanbevelingen',
      'title': 'Onderzoek',
      'open': 'Onderzoek openen',
      'close': 'Onderzoek sluiten',
      'loading': 'Onderzoeksopties worden geladen',
      'retry': 'Opnieuw proberen',
      'selecting': 'Technologie wordt geselecteerd',
      'selectionRequired': 'Selecteer een technologie om door te gaan',
      'sciencePerTurn': 'Wetenschap per beurt',
      'overflow': 'Opgeslagen wetenschap',
      'active': 'Actieve technologie',
      'none': 'Geen',
      'cost': 'Kosten',
      'progress': 'Voortgang',
      'boost': 'Kostenkorting door impuls',
      'prerequisites': 'Vereisten',
      'blockedBy': 'Geblokkeerd door',
      'unlocks': 'Ontgrendelt',
      'choose': 'Selecteren',
      'tree': 'Technologieboom',
      'catalog': 'Onderzoekscatalogus',
      'backToTree': 'Terug naar de boom',
      'treeUnavailable': 'Het afhankelijkheidsdiagram is niet beschikbaar.',
      'other': 'Onderzoek',
    });
    return '$_temp0';
  }

  @override
  String researchAvailability(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unlocked': 'Onderzocht',
      'active': 'Actief',
      'available': 'Beschikbaar',
      'lockedByPrerequisites': 'Vereisten nodig',
      'lockedByTechnology': 'Geblokkeerd door technologie',
      'other': 'Niet beschikbaar',
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
      'requestFailed': 'Het onderzoeksverzoek kon niet worden voltooid.',
      'responseIncompatible': 'Het onderzoeksantwoord is niet compatibel.',
      'sessionUnavailable': 'De lokale spelsessie is niet beschikbaar.',
      'staleRevision':
          'Het onderzoek is veranderd. Controleer de opties en probeer het opnieuw.',
      'technologyPlayerNotControlled':
          'Deze speler kan geen onderzoek selecteren.',
      'technologyNotAvailable': 'Deze technologie is niet beschikbaar.',
      'stateRevisionOverflow':
          'De speltoestand kan niet verder worden bijgewerkt.',
      'other': 'Het onderzoeksverzoek kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String diplomacyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Diplomatie',
      'open': 'Diplomatie openen',
      'close': 'Diplomatie sluiten',
      'noContacts': 'Geen contacten',
      'compose': 'Nieuwe actie',
      'target': 'Gesprekspartner',
      'action': 'Actie',
      'send': 'Verzenden',
      'invalid': 'Controleer de voorwaarden in het formulier.',
      'pending': 'Diplomatieke actie wordt verzonden',
      'relations': 'Relaties',
      'proposals': 'Voorstellen',
      'messages': 'Privéberichten',
      'agreements': 'Grondstoffenovereenkomsten',
      'accept': 'Accepteren',
      'reject': 'Afwijzen',
      'amount': 'Hoeveelheid',
      'goldPerTurn': 'Goud per beurt',
      'duration': 'Beurten',
      'resource': 'Grondstof',
      'offered': 'Aangeboden grondstof',
      'requested': 'Gevraagde grondstof',
      'topic': 'Onderwerp',
      'other': 'Diplomatie',
    });
    return '$_temp0';
  }

  @override
  String diplomacyFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Het diplomatieverzoek kon niet worden voltooid.',
      'responseIncompatible': 'Het diplomatieantwoord is niet compatibel.',
      'sessionUnavailable': 'De lokale spelsessie is niet beschikbaar.',
      'staleRevision':
          'De diplomatieke situatie is veranderd. Controleer de huidige toestand en probeer het opnieuw.',
      'matchFinished': 'De partij is al afgelopen.',
      'diplomacyPlayerNotControlled':
          'Deze speler kan geen diplomatieke acties uitvoeren.',
      'diplomacyTargetNotDiscovered':
          'Deze gesprekspartner is niet beschikbaar.',
      'diplomacyProposalNotAllowed': 'Dit voorstel is niet toegestaan.',
      'diplomacyDuplicateProposal': 'Dit voorstel bestaat al.',
      'diplomacyProposalNotFound': 'Dit voorstel bestaat niet meer.',
      'diplomacyProposalPaymentUnavailable':
          'De betaling voor het voorstel is niet beschikbaar.',
      'diplomacyMessageCooldown':
          'Er is te kort geleden een vergelijkbaar bericht verzonden.',
      'diplomacyDuplicateMessage': 'Dit bericht bestaat al.',
      'diplomacyMessageNotFound': 'Dit bericht bestaat niet meer.',
      'diplomacyMessageUnavailable': 'Dit bericht kan nu niet worden gebruikt.',
      'diplomacyTruceActive': 'Er is een wapenstilstand actief.',
      'diplomacyWarAlreadyActive': 'Er is al oorlog.',
      'diplomacyInvalidGoldAmount': 'De hoeveelheid goud is ongeldig.',
      'diplomacyGoldGiftBlockedByRelation':
          'Deze relatie blokkeert goudgiften.',
      'diplomacyGoldUnavailable': 'Het vereiste goud is niet beschikbaar.',
      'diplomacyGoldGiftUnavailable': 'Deze goudgift is niet beschikbaar.',
      'invalidResourceTradeTarget':
          'De ontvanger van de grondstoffenhandel is ongeldig.',
      'invalidResourceTradeResource': 'De geselecteerde grondstof is ongeldig.',
      'invalidResourceTradeTerms':
          'De voorwaarden van de grondstoffenhandel zijn ongeldig.',
      'resourceTradeBlockedByWar': 'Oorlog blokkeert deze grondstoffenhandel.',
      'resourceTradeGoldUnavailable':
          'Het goud voor de handel is niet beschikbaar.',
      'resourceTradeAlreadyActive': 'Deze grondstoffenhandel is al actief.',
      'invalidResourceTradeAgreementId':
          'De identificatie van de overeenkomst is ongeldig.',
      'resourceTradeAgreementIdConflict':
          'De identificatie van de overeenkomst veroorzaakt een conflict.',
      'resourceTradeExportUnavailable':
          'De grondstofexport is niet beschikbaar.',
      'resourceTradeOfferUnavailable':
          'De aangeboden grondstof is niet beschikbaar.',
      'resourceTradeRequestUnavailable':
          'De gevraagde grondstof is niet beschikbaar.',
      'stateRevisionOverflow':
          'De speltoestand kan niet verder worden bijgewerkt.',
      'other': 'Het diplomatieverzoek kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String presentationName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'farm': 'Boerderij',
      'riverFarm': 'Rivierboerderij',
      'mine': 'Mijn',
      'lumberMill': 'Zagerij',
      'pasture': 'Weide',
      'camp': 'Kamp',
      'quarry': 'Steengroeve',
      'fishingBoats': 'Vissersboten',
      'orchard': 'Boomgaard',
      'plantation': 'Plantage',
      'vineyard': 'Wijngaard',
      'tradingPost': 'Handelspost',
      'prospectorCamp': 'Prospectiekamp',
      'horseRanch': 'Paardenfokkerij',
      'pearlDivers': 'Parelduikers',
      'coalShaft': 'Kolenschacht',
      'oilWell': 'Oliebron',
      'bauxiteMine': 'Bauxietmijn',
      'uraniumMine': 'Uraniummijn',
      'wheat': 'Tarwe',
      'fish': 'Vis',
      'deer': 'Hert',
      'sheep': 'Schaap',
      'rice': 'Rijst',
      'cow': 'Koe',
      'apple': 'Appel',
      'banana': 'Banaan',
      'citrus': 'Citrusvruchten',
      'gold': 'Goud',
      'silver': 'Zilver',
      'gems': 'Edelstenen',
      'silk': 'Zijde',
      'spices': 'Specerijen',
      'cotton': 'Katoen',
      'grapes': 'Druiven',
      'ivory': 'Ivoor',
      'pearls': 'Parels',
      'coffee': 'Koffie',
      'cocoa': 'Cacao',
      'tobacco': 'Tabak',
      'sugar': 'Suiker',
      'iron': 'IJzer',
      'coal': 'Steenkool',
      'oil': 'Olie',
      'aluminium': 'Aluminium',
      'uranium': 'Uranium',
      'horses': 'Paarden',
      'marble': 'Marmer',
      'commander': 'Commandant',
      'warrior': 'Krijger',
      'archer': 'Boogschutter',
      'settler': 'Kolonist',
      'worker': 'Werker',
      'merchant': 'Koopman',
      'scout': 'Verkenner',
      'spearman': 'Speerdrager',
      'cavalry': 'Cavalerie',
      'catapult': 'Katapult',
      'heavyInfantry': 'Zware infanterie',
      'fieldCannon': 'Veldkanon',
      'rifleman': 'Geweerschutter',
      'tank': 'Tank',
      'scoutShip': 'Verkenningsschip',
      'warship': 'Oorlogsschip',
      'reconPlane': 'Verkenningsvliegtuig',
      'building': 'Gebouw',
      'improvement': 'Verbetering',
      'resourceVisibility': 'Grondstofzichtbaarheid',
      'unit': 'Eenheid',
      'wonder': 'Wereldwonder',
      'friendly': 'Vriendelijk',
      'neutral': 'Neutraal',
      'hostile': 'Vijandig',
      'truce': 'Wapenstilstand',
      'war': 'Oorlog',
      'warning': 'Waarschuwing',
      'complaint': 'Klacht',
      'request': 'Verzoek',
      'praise': 'Lof',
      'threat': 'Dreiging',
      'cooperation': 'Samenwerking',
      'troopsNearCities': 'Troepen bij steden',
      'citiesTooClose': 'Steden te dichtbij',
      'blockedRoutes': 'Geblokkeerde routes',
      'withdrawScouts': 'Verkenners terugtrekken',
      'avoidEscalation': 'Escalatie vermijden',
      'commonEnemy': 'Gemeenschappelijke vijand',
      'expansionProvocation': 'Provocatie door uitbreiding',
      'peacefulPraise': 'Lof voor vreedzaam gedrag',
      'conciliatory': 'Verzoenend',
      'evasive': 'Ontwijkend',
      'aggressive': 'Agressief',
      'declareWar': 'Oorlog verklaren',
      'goldGift': 'Goudgift',
      'friendshipProposal': 'Vriendschapsvoorstel',
      'truceProposal': 'Wapenstilstandsvoorstel',
      'message': 'Bericht',
      'resourceTrade': 'Grondstoffenhandel',
      'resourceExchange': 'Grondstoffenruil',
      'granary': 'Graanschuur',
      'workshop': 'Werkplaats',
      'industry': 'Industrie',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String technologyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'agriculture': 'Landbouw',
      'woodworking': 'Houtbewerking',
      'mining': 'Mijnbouw',
      'animalHusbandry': 'Veeteelt',
      'hunting': 'Jacht',
      'fishing': 'Visserij',
      'craftsmanship': 'Ambacht',
      'trade': 'Handel',
      'storage': 'Opslag',
      'waterEngineering': 'Waterbouw',
      'stoneworking': 'Steenbewerking',
      'militaryOrganization': 'Militaire organisatie',
      'advancedTrade': 'Geavanceerde handel',
      'construction': 'Bouwkunde',
      'navigation': 'Navigatie',
      'irrigation': 'Irrigatie',
      'banking': 'Bankwezen',
      'engineering': 'Techniek',
      'metallurgy': 'Metallurgie',
      'horsebackRiding': 'Paardrijden',
      'ironWorking': 'IJzerbewerking',
      'coalMining': 'Steenkoolwinning',
      'machinery': 'Machines',
      'administration': 'Bestuur',
      'logistics': 'Logistiek',
      'shipbuilding': 'Scheepsbouw',
      'tactics': 'Tactiek',
      'economy': 'Economie',
      'urbanization': 'Verstedelijking',
      'fortifications': 'Vestingwerken',
      'strategy': 'Strategie',
      'specialization': 'Specialisatie',
      'writing': 'Schrift',
      'mathematics': 'Wiskunde',
      'medicine': 'Geneeskunde',
      'civilService': 'Ambtenarenapparaat',
      'siegecraft': 'Belegeringstechniek',
      'cartography': 'Cartografie',
      'guilds': 'Gilden',
      'law': 'Recht',
      'education': 'Onderwijs',
      'urbanPlanning': 'Stedenbouw',
      'navalDoctrine': 'Marinedoctrine',
      'steel': 'Staal',
      'bureaucracy': 'Bureaucratie',
      'nationalism': 'Nationalisme',
      'scientificMethod': 'Wetenschappelijke methode',
      'steamPower': 'Stoomkracht',
      'electricity': 'Elektriciteit',
      'combustion': 'Verbranding',
      'flight': 'Luchtvaart',
      'massProduction': 'Massaproductie',
      'radio': 'Radio',
      'nuclearPhysics': 'Kernfysica',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String cityContentName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'growth': 'Groei',
      'industry': 'Industrie',
      'commerce': 'Handel',
      'science': 'Wetenschap',
      'military': 'Militair',
      'wealth': 'Rijkdom',
      'research': 'Onderzoek',
      'granary': 'Graanschuur',
      'waterMill': 'Watermolen',
      'workshop': 'Werkplaats',
      'storehouse': 'Pakhuis',
      'housing': 'Woningen',
      'merchantHall': 'Koopmanshal',
      'stonemason': 'Steenhouwer',
      'barracks': 'Kazerne',
      'marketplace': 'Marktplaats',
      'port': 'Haven',
      'aqueduct': 'Aquaduct',
      'forge': 'Smidse',
      'stable': 'Stal',
      'bank': 'Bank',
      'buildersGuild': 'Bouwgilde',
      'factory': 'Fabriek',
      'lighthouse': 'Vuurtoren',
      'trainingGrounds': 'Oefenterrein',
      'townHall': 'Stadhuis',
      'monument': 'Monument',
      'archive': 'Archief',
      'academy': 'Academie',
      'university': 'Universiteit',
      'observatory': 'Observatorium',
      'laboratory': 'Laboratorium',
      'reactor': 'Reactor',
      'courthouse': 'Gerechtsgebouw',
      'court': 'Hof',
      'governorsOffice': 'Gouverneurskantoor',
      'surveyorsOffice': 'Landmeterskantoor',
      'planningOffice': 'Planningskantoor',
      'apothecary': 'Apotheek',
      'publicBaths': 'Openbare baden',
      'hospital': 'Ziekenhuis',
      'ministries': 'Ministeries',
      'walls': 'Stadsmuren',
      'armory': 'Wapenkamer',
      'siegeWorkshop': 'Belegeringswerkplaats',
      'citadel': 'Citadel',
      'warCollege': 'Krijgsacademie',
      'conscriptionOffice': 'Dienstplichtkantoor',
      'borderFort': 'Grensfort',
      'airfield': 'Vliegveld',
      'artisansGuild': 'Ambachtsgilde',
      'masterWorkshop': 'Meesterwerkplaats',
      'steelworks': 'Staalfabriek',
      'railDepot': 'Spoorwegdepot',
      'powerPlant': 'Elektriciteitscentrale',
      'assemblyPlant': 'Assemblagefabriek',
      'refinery': 'Raffinaderij',
      'mapRoom': 'Kaartenkamer',
      'shipyard': 'Scheepswerf',
      'dryDock': 'Droogdok',
      'navalAcademy': 'Marineacademie',
      'harborCustoms': 'Havendouane',
      'museum': 'Museum',
      'parliament': 'Parlement',
      'broadcastTower': 'Zendmast',
      'worldFairGrounds': 'Wereldtentoonstellingsterrein',
      'greatLibrary': 'Grote Bibliotheek',
      'hangingGardens': 'Hangende Tuinen',
      'greatWall': 'Grote Muur',
      'petra': 'Petra',
      'centralBank': 'Centrale Bank',
      'imperialUniversity': 'Keizerlijke Universiteit',
      'grandCathedral': 'Grote Kathedraal',
      'motherFactory': 'Moederfabriek',
      'nationalObservatory': 'Nationaal Observatorium',
      'svalbardSeedVault': 'Wereldzadenbank op Spitsbergen',
      'grandExposition': 'Grote Tentoonstelling',
      'other': 'Onbekende stadsinhoud',
    });
    return '$_temp0';
  }

  @override
  String diplomaticProposalName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'friendship': 'Vriendschap',
      'truce': 'Wapenstilstand',
      'other': 'Onbekend voorstel',
    });
    return '$_temp0';
  }

  @override
  String mapFeedbackText(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'roadCompleted': '+Weg',
      'unitKilled': 'KO',
      'unitRetreated': 'Terugtocht',
      'artifactExcavationStarted': 'Opgraving',
      'artifactCarried': 'Artefact opgepakt',
      'artifactStored': 'Artefact opgeslagen',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String mapYieldShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'food': 'VOED',
      'production': 'PROD',
      'gold': 'GOUD',
      'defense': 'VERD',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get focusOwnUnitMovement =>
      'Camera richten op bewegingen van mijn eenheden';

  @override
  String get followOwnUnitMovement =>
      'Bewegingen van mijn eenheden volgen met de camera';

  @override
  String get focusForeignUnitMovement =>
      'Camera richten op bewegingen van vijandelijke eenheden';

  @override
  String get followForeignUnitMovement =>
      'Bewegingen van vijandelijke eenheden volgen met de camera';

  @override
  String get gameSoundsLabel => 'Spelgeluiden';

  @override
  String get soundVolumeLabel => 'Geluidsvolume';

  @override
  String get gameMusicLabel => 'Spelmuziek';

  @override
  String get musicVolumeLabel => 'Muziekvolume';

  @override
  String get natureSoundsLabel => 'Natuurgeluiden';

  @override
  String get natureVolumeLabel => 'Volume van natuurgeluiden';

  @override
  String hexInspectionKind(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite': 'Ideale stadsplaats',
      'goodCitySite': 'Goede stadsplaats',
      'fertileField': 'Vruchtbaar veld',
      'fertilePlains': 'Vruchtbare vlakten',
      'richPlain': 'Rijke vlakte',
      'strategicBorderland': 'Strategisch grensland',
      'strategicField': 'Strategisch veld',
      'defensivePosition': 'Verdedigingspositie',
      'fertileForest': 'Vruchtbaar bos',
      'forestBackline': 'Bebost achterland',
      'forestForge': 'Industrieel bos',
      'wildLand': 'Wildernis',
      'richWilds': 'Rijke wildernis',
      'exoticBackline': 'Exotisch achterland',
      'difficultStrategicTerrain': 'Moeilijk strategisch terrein',
      'highGround': 'Hooggelegen terrein',
      'riverHills': 'Rivierheuvels',
      'industrialStronghold': 'Industrieel bolwerk',
      'richHills': 'Rijke heuvels',
      'barrenLand': 'Onvruchtbaar land',
      'oasis': 'Oase',
      'tradeOasis': 'Handelsoase',
      'desertDeposits': 'Woestijnafzettingen',
      'harshLand': 'Guur land',
      'coldPastures': 'Koude weiden',
      'resourceOutpost': 'Grondstoffenvoorpost',
      'hostileLand': 'Onherbergzaam land',
      'arcticDeposits': 'Arctische afzettingen',
      'coast': 'Kust',
      'fishingCoast': 'Visrijke kust',
      'richCoast': 'Rijke kust',
      'riverPort': 'Rivierhaven',
      'regionalPortHeart': 'Regionaal havenknooppunt',
      'openSea': 'Open zee',
      'naturalBarrier': 'Natuurlijke barrière',
      'promisingLand': 'Veelbelovend land',
      'weakLand': 'Weinig productief land',
      'ordinaryLand': 'Gewoon land',
      'mapTile': 'Kaarttegel',
      'other': 'Kaarttegel',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionDescription(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite':
          'Een waardevolle vestigingsplek waar voedsel, groei en uitbreidingspotentieel samenkomen.',
      'goodCitySite':
          'Degelijk terrein voor een stadscentrum met genoeg basiswaarde om vroege groei te ondersteunen.',
      'fertileField':
          'Grasland langs een rivier dat voedsel, bevolkingsgroei en verbeteringen door werkers bevordert.',
      'fertilePlains':
          'Open vlakten langs een rivier, nuttig voor een balans tussen voedsel en productie.',
      'richPlain':
          'Een waardevolle open tegel met luxegrondstoffen of handelswaarde die de moeite waard is om binnen de grenzen te brengen.',
      'strategicBorderland':
          'Goed land met strategische waarde, nuttig voor uitbreiding voordat rivalen het opeisen.',
      'strategicField':
          'Een vlaktetegel met strategische grondstoffen of invloed op de grenssituatie.',
      'defensivePosition':
          'Terrein dat de verdediging versterkt en helpt nabijgelegen toegangen te bewaken.',
      'fertileForest':
          'Een bos langs een rivier dat groeipotentieel met natuurlijke dekking combineert.',
      'forestBackline':
          'Een veiligere bostegel die groei of op jacht gerichte verbeteringen kan ondersteunen.',
      'forestForge':
          'Bos met industriële grondstoffen, veelbelovend voor productie zodra het is verbeterd.',
      'wildLand':
          'Dicht en lastig terrein, alleen nuttig met een duidelijk plan voor werkers of uitbreiding.',
      'richWilds':
          'Wild terrein met genoeg vruchtbaarheid of grondstoffen om zorgvuldige ontwikkeling te rechtvaardigen.',
      'exoticBackline':
          'Een jungle- of moerastegel met luxegrondstoffen voor latere uitbreiding en handel.',
      'difficultStrategicTerrain':
          'Lastig terrein met strategische grondstoffen: later krachtig, vroeg onhandig.',
      'highGround':
          'Heuvels die verdediging en kaartcontrole meer bevorderen dan snelle groei.',
      'riverHills':
          'Heuvels langs een rivier die verdediging met beter economisch potentieel combineren.',
      'industrialStronghold':
          'Heuvels met industriële grondstoffen, een sterk productiedoel voor een stad.',
      'richHills':
          'Heuvels met waardevolle grondstoffen, nuttig voor uitbreiding gericht op goud of productie.',
      'barrenLand':
          'Droog land met weinig directe waarde, tenzij latere technologie of grenzen het plan veranderen.',
      'oasis':
          'Woestijn met toegang tot een rivier, waardoor zwak land bruikbaar wordt voor groei.',
      'tradeOasis':
          'Een handelsplek in de woestijn die met de juiste verbetering waardevol kan worden.',
      'desertDeposits':
          'Slechte vestigingsgrond met een strategische afzetting die in latere tijdperken belangrijker wordt.',
      'harshLand':
          'Koud of ruig land met een beperkte vroege economie en trage ontwikkeling.',
      'coldPastures':
          'Koud terrein met genoeg weidewaarde om een grensstad te ondersteunen.',
      'resourceOutpost':
          'Afgelegen koud land dat vooral de moeite waard is vanwege de grondstof die het herbergt.',
      'hostileLand':
          'Onherbergzaam terrein met weinig vestigingswaarde en lage directe opbrengsten.',
      'arcticDeposits':
          'Besneeuwd grondstofgebied dat moeilijk bruikbaar is, maar strategisch belangrijk kan worden.',
      'coast':
          'Kustland dat toegang tot de zee en flexibele stadsgroei mogelijk maakt.',
      'fishingCoast':
          'Kust met voedselwaarde, een goede reden om dicht bij het water te werken of te vestigen.',
      'richCoast':
          'Luxegrondstoffen of handelswaarde aan de kust die de moeite waard zijn om binnen stadsgrenzen te brengen.',
      'riverPort':
          'Een riviermonding met handels- en verplaatsingswaarde voor een kuststad.',
      'regionalPortHeart':
          'Een sterk kustcentrum waar de waarde van rivier en grondstoffen samenkomt.',
      'openSea':
          'Water dat nuttig is voor schepen en verkenning, maar niet voor vestiging op land.',
      'naturalBarrier':
          'Onbegaanbaar terrein dat vooral beweging en verdediging beïnvloedt, in plaats van de economie.',
      'promisingLand':
          'Een doorgaans nuttige tegel met genoeg waarde om te inspecteren voordat je verdergaat.',
      'weakLand':
          'Terrein met lage opbrengsten dat vroeg in het spel zelden werkertijd verdient.',
      'ordinaryLand':
          'Een gewone tegel zonder uitgesproken sterke kant, nuttig als die in het stadsplan past.',
      'mapTile':
          'Een eenvoudige kaarttegel met te weinig informatie voor een duidelijk oordeel.',
      'other':
          'Een eenvoudige kaarttegel met te weinig informatie voor een duidelijk oordeel.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendation(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity': 'Goede ontwikkelingsplek',
      'defendHere': 'Goede verdedigingspositie',
      'exploitEconomy': 'De moeite waard om te benutten',
      'avoid': 'Zonder plan vermijden',
      'neutral': 'Inspecteren vóór verplaatsing',
      'other': 'Inspecteren vóór verplaatsing',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendationDetail(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity':
          'Als het gebied vrij is van grenzen, overweeg dan hier een stad te stichten of een kolonist heen te sturen.',
      'defendHere':
          'Gebruik de positie om eenheden op te stellen, grenzen te beschermen of nabijgelegen steden te dekken.',
      'exploitEconomy':
          'Breng de tegel binnen je grenzen en wijs een werker toe zodra de stad ervan kan profiteren.',
      'avoid':
          'Sla de tegel vroeg over, tenzij een grondstof, route of militaire noodzaak de waarde verandert.',
      'neutral':
          'Verken naburige tegels en vergelijk grondstoffen voordat je een werker of kolonist inzet.',
      'other':
          'Verken naburige tegels en vergelijk grondstoffen voordat je een werker of kolonist inzet.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Hexinspectie',
      'close': 'Inspectie sluiten',
      'loading': 'Hex wordt geïnspecteerd…',
      'requestFailed':
          'De hex kon niet worden geïnspecteerd. Probeer het opnieuw.',
      'responseIncompatible':
          'Het antwoord op de hexinspectie is niet compatibel.',
      'sessionUnavailable': 'De spelsessie is niet beschikbaar.',
      'description': 'Beschrijving',
      'terrain': 'Terrein',
      'resources': 'Grondstoffen',
      'none': 'Geen',
      'height': 'Hoogte',
      'improvements': 'Mogelijke verbeteringen',
      'noImprovements': 'Geen passende verbeteringen.',
      'fromStart': 'Vanaf het begin beschikbaar',
      'unlocked': 'Technologie ontgrendeld',
      'locked': 'Technologie vereist',
      'riverBonus': 'Rivierbonus',
      'defenseBonus': 'Verdedigingsterrein',
      'outsideCity': 'Buiten de beheerde stadsgrenzen',
      'cityCenter': 'Stadscentrum',
      'alreadyImproved': 'Deze hex is al verbeterd',
      'objective': 'Kaartdoel',
      'other': 'Hexinspectie',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionCity(String city) {
    return 'Bewerkt door $city';
  }

  @override
  String hexInspectionBuildTurns(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns beurten',
      one: '1 beurt',
    );
    return 'Bouwtijd: $_temp0';
  }

  @override
  String hexInspectionTerrain(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'ocean': 'Oceaan',
      'coast': 'Kust',
      'lake': 'Meer',
      'plains': 'Vlakten',
      'grassland': 'Grasland',
      'desert': 'Woestijn',
      'tundra': 'Toendra',
      'snow': 'Sneeuw',
      'mountain': 'Berg',
      'hills': 'Heuvels',
      'wetlands': 'Moerasland',
      'jungle': 'Jungle',
      'forest': 'Bos',
      'river': 'Rivier',
      'other': 'Vlakten',
    });
    return '$_temp0';
  }

  @override
  String get gamepadSettings => 'Gamepad';

  @override
  String get gamepadEnabled => 'Gamepadinvoer';

  @override
  String get gamepadDeadzone => 'Dode zone van gamepad';

  @override
  String get gamepadCameraSensitivity => 'Cameragevoeligheid van gamepad';

  @override
  String get gamepadInvertCameraY => 'Y-as van gamepadcamera omkeren';

  @override
  String get gamepadButtonBindings => 'Knoptoewijzingen';

  @override
  String get gamepadAxisBindings => 'Astoewijzingen';

  @override
  String get gamepadResetBindings => 'Toewijzingen herstellen';

  @override
  String get gamepadUnassigned => 'Niet toegewezen';

  @override
  String gamepadAssignedTo(String action) {
    return 'Toegewezen aan: $action';
  }

  @override
  String get gamepadActionConfirm => 'Bevestigen';

  @override
  String get gamepadActionCancel => 'Annuleren';

  @override
  String get gamepadActionMoveMode => 'Verplaatsingsmodus';

  @override
  String get gamepadActionInspect => 'Hex inspecteren';

  @override
  String get gamepadActionHudPrevious => 'Vorige interfacesectie';

  @override
  String get gamepadActionHudNext => 'Volgende interfacesectie';

  @override
  String get gamepadActionPrevious => 'Vorige openstaande actie';

  @override
  String get gamepadActionNext => 'Volgende openstaande actie';

  @override
  String get gamepadActionPrimary => 'Hoofdactie';

  @override
  String get gamepadActionUp => 'Richtingsknop omhoog';

  @override
  String get gamepadActionDown => 'Richtingsknop omlaag';

  @override
  String get gamepadActionLeft => 'Richtingsknop links';

  @override
  String get gamepadActionRight => 'Richtingsknop rechts';

  @override
  String get gamepadActionZoomIn => 'Inzoomen';

  @override
  String get gamepadActionZoomOut => 'Uitzoomen';

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
  String get gamepadControlLeftStickX => 'Linkerstick X';

  @override
  String get gamepadControlLeftStickY => 'Linkerstick Y';

  @override
  String get gamepadControlRightStickX => 'Rechterstick X';

  @override
  String get gamepadControlRightStickY => 'Rechterstick Y';

  @override
  String get gamepadControlLeftTrigger => 'Linkertrigger (LT)';

  @override
  String get gamepadControlRightTrigger => 'Rechtertrigger (RT)';

  @override
  String get keyboardSettings => 'Toetsenbord';

  @override
  String get keyboardScope =>
      'Kaartsneltoetsen werken wanneer de kaart toetsenbordfocus heeft. Klik op de kaart om de focus terug te geven.';

  @override
  String get keyboardPanKeys => 'W / A / S / D of pijltjestoetsen';

  @override
  String get keyboardPan => 'Camera verschuiven';

  @override
  String get keyboardSelect =>
      'De hex onder de aanwijzer of de huidige selectie selecteren';

  @override
  String get keyboardMove =>
      'Doelselectie voor verplaatsing van de geselecteerde eenheid omschakelen';

  @override
  String get keyboardInspect =>
      'De hex onder de aanwijzer, de geselecteerde hex of het midden van de weergave inspecteren';

  @override
  String get keyboardMapMode =>
      'Wisselen tussen grafische kaartweergave en tegelweergave';

  @override
  String get keyboardPending => 'Vorige / volgende openstaande beurtactie';

  @override
  String get keyboardSpace => 'Spatie';

  @override
  String get keyboardPrimary =>
      'Naar de volgende openstaande actie gaan; de beurt beëindigen als er geen acties meer zijn';

  @override
  String get keyboardCancel =>
      'Het actieve paneel sluiten of de huidige interactie annuleren';

  @override
  String get keyboardFocus =>
      'Het volgende / vorige bedieningselement focussen';

  @override
  String get textSize => 'Tekstgrootte';

  @override
  String get textSizeDescription =>
      'Wordt toegepast boven op de tekstgrootte van het systeem.';

  @override
  String get textScaleStandard => 'Standaard (100%)';

  @override
  String get textScaleLarge => 'Groot (115%)';

  @override
  String get textScaleExtraLarge => 'Extra groot (130%)';

  @override
  String get languageSettings => 'Taal';

  @override
  String get languageSystem => 'Systeemtaal';

  @override
  String get windowSettingsTitle => 'Venster';

  @override
  String get windowModeFullscreen => 'Volledig scherm';

  @override
  String get windowModeWindowed => 'In venster';

  @override
  String get windowSettingsBusy => 'Venstermodus wordt gewijzigd…';

  @override
  String windowSettingsFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'load':
          'De venstervoorkeuren konden niet worden geladen. De standaardmodus is aangevraagd.',
      'apply':
          'De venstermodus kon niet worden gewijzigd. Kies opnieuw een modus.',
      'save':
          'De venstervoorkeur kon niet worden opgeslagen. Kies opnieuw een modus.',
      'restore':
          'De vorige venstermodus kon niet worden hersteld. Kies opnieuw een modus.',
      'other': 'De vensterbewerking kon niet worden voltooid.',
    });
    return '$_temp0';
  }

  @override
  String get automationSettings => 'Automatisering';

  @override
  String get advanceActions => 'Naar de volgende actie gaan';

  @override
  String get advanceActionsDescription =>
      'Na een actie de volgende eenheid, stad of onderzoek selecteren die je aandacht nodig heeft.';

  @override
  String get automaticEndTurn => 'Beurten automatisch beëindigen';

  @override
  String get automaticEndTurnDescription =>
      'Je beurt beëindigen wanneer er geen acties meer over zijn. Handmatige keuzes en geopende panelen pauzeren de automatisering.';

  @override
  String get performanceSettings => 'Prestatie';

  @override
  String get showFps => 'FPS tonen';

  @override
  String get showFpsDescription => 'Toon de beeldsnelheid in de hele app.';

  @override
  String get showMapZoom => 'Toon kaartzoom';

  @override
  String get showMapZoomDescription =>
      'Toon de huidige zoom wanneer de kaart geopend is.';

  @override
  String get aiSettings => 'AI';

  @override
  String get aiBatterySaver => 'AI-batterijbesparing';

  @override
  String get aiBatterySaverDescription =>
      'Vermindert tactisch zoekwerk tijdens lokale AI-beurten.';

  @override
  String get mapAppearanceSettings => 'Kaartweergave';

  @override
  String get mapMarkingsSettings => 'Kaartmarkeringen';

  @override
  String get preferredMapViewMode => 'Standaardkaartweergave';

  @override
  String get preferredMapViewModeDescription =>
      'Wordt gebruikt bij het openen van een spel of herhaling.';

  @override
  String get mapCitySites => 'Stadslocaties';

  @override
  String get mapCitySitesDescription =>
      'Toon mogelijke stadslocaties op verkend terrein.';

  @override
  String get mapCityGrowth => 'Stadsuitbreiding';

  @override
  String get mapCityGrowthDescription =>
      'Toon verkende velden buiten het grondgebied van bekende steden.';

  @override
  String resourceTurnsCompact(int turns) {
    return '${turns}T';
  }

  @override
  String resourceText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'gold': 'Goud',
      'science': 'Wetenschap',
      'stability': 'Stabiliteit',
      'resources': 'Grondstoffen',
      'victory': 'Overwinning',
      'turn': 'Beurt',
      'close': 'Details sluiten',
      'treasury': 'Schatkist',
      'income': 'Inkomsten',
      'cityIncome': 'Stadsinkomsten',
      'projectIncome': 'Projectinkomsten',
      'upkeep': 'Eenheidsonderhoud',
      'netPerTurn': 'Per beurt',
      'freeUnits': 'Gratis eenheden',
      'paidUnits': 'Betaalde eenheden',
      'nextWorker': 'Onderhoud volgende werker',
      'activeResearch': 'Actief onderzoek',
      'overflow': 'Opgeslagen wetenschap',
      'sources': 'Bronnen',
      'baseOrder': 'Basisorde',
      'buildings': 'Gebouwen',
      'luxuries': 'Luxegoederen',
      'technologies': 'Technologieën',
      'artifacts': 'Artefacten',
      'wonders': 'Wereldwonderen',
      'cities': 'Steden',
      'population': 'Bevolking',
      'cohesion': 'Samenhang',
      'conqueredCities': 'Veroverde steden',
      'warWeariness': 'Oorlogsmoeheid',
      'hegemony': 'Hegemoniebelasting',
      'relativeStanding': 'Relatieve positie',
      'totalSources': 'Totaal bronnen',
      'totalCosts': 'Totale kosten',
      'stockpile': 'Voorraad',
      'output': 'Opbrengst per beurt',
      'empty': 'Geen bronnen',
      'score': 'Score',
      'conquest': 'Verovering',
      'domination': 'Dominantie',
      'culture': 'Cultuur',
      'holdTurns': 'Beurten behouden',
      'remainingTurns': 'Resterende beurten',
      'turnLimit': 'Beurtlimiet',
      'submitted': 'Bevestigd',
      'required': 'Vereiste bevestigingen',
      'content': 'Tevreden',
      'stable': 'Stabiel',
      'strained': 'Gespannen',
      'unrest': 'Onrust',
      'warning': 'Waarschuwing',
      'negativeBalance': 'De schatkist is negatief.',
      'deficitWithinThreeTurns':
          'Met het huidige inkomen wordt de schatkist binnen drie beurten negatief.',
      'shortage': 'Onvoldoende grondstoffen voor vrijgespeelde eenheden',
      'victoryCritical': 'Een overwinningsvoorwaarde nadert.',
      'leader': 'Leider',
      'noVictory': 'Geen overwinningsvoorwaarde',
      'goalCompact': 'Doel',
      'scoreCapCompact': 'LIMIET',
      'other': 'Grondstoffen',
    });
    return '$_temp0';
  }

  @override
  String get automaticSave => 'Automatisch opgeslagen spel';

  @override
  String playerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Spelers',
      'active': 'Actief',
      'finished': 'Beurt beëindigd',
      'submitted': 'Bevestigd',
      'waiting': 'Wachten',
      'ended': 'Wedstrijd beëindigd',
      'privateStatus': 'Beurtstatus is privé',
      'noContact': 'Geen diplomatiek contact',
      'other': 'Spelers',
    });
    return '$_temp0';
  }

  @override
  String historyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Voltooide onlinewedstrijden',
      'loading': 'Wedstrijdgeschiedenis laden',
      'empty': 'Nog geen voltooide wedstrijden.',
      'failed':
          'De geschiedenis kon niet worden geladen. Probeer te vernieuwen.',
      'refresh': 'Vernieuwen',
      'previous': 'Vorige pagina',
      'next': 'Volgende pagina',
      'turn': 'Laatste beurt',
      'won': 'Je hebt gewonnen',
      'lost': 'Je hebt verloren',
      'resigned': 'Je hebt opgegeven',
      'removed': 'Je bent uit de wedstrijd verwijderd',
      'other': 'Voltooide onlinewedstrijden',
    });
    return '$_temp0';
  }

  @override
  String profileText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Je profiel',
      'description':
          'Bij het wijzigen van je weergavenaam blijven je account en multiplayerwedstrijden behouden.',
      'save': 'Naam opslaan',
      'saved': 'Weergavenaam opgeslagen.',
      'taken': 'Deze weergavenaam is al in gebruik.',
      'changed': 'Het account is gewijzigd. Laad het profiel opnieuw.',
      'other': 'Je profiel',
    });
    return '$_temp0';
  }

  @override
  String get researchDiscoveryTitle => 'Onderzoek voltooid';

  @override
  String get showResearchDiscoveries => 'Technologische ontdekkingen tonen';

  @override
  String get researchDiscoverySuppress => 'Niet opnieuw tonen';

  @override
  String get researchDiscoveryMinimize => 'Minimaliseren';

  @override
  String get researchDiscoveryRestore => 'Ontdekking herstellen';

  @override
  String get researchDiscoveryContinue => 'Doorgaan';

  @override
  String researchRecommendationRank(int rank) {
    return 'Aanbeveling $rank';
  }

  @override
  String researchRecommendationTurns(int turns) {
    return 'Geschatte beurten: $turns';
  }

  @override
  String researchRecommendationReason(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'boost': 'Onderzoeksbonus',
      'workerYields': 'Opbrengsten van arbeiders',
      'unlocks': 'Nieuwe vrijgaven',
      'effects': 'Technologie-effecten',
      'nearCompletion': 'Bijna voltooid',
      'other': 'Aanbevelingen',
    });
    return '$_temp0';
  }

  @override
  String technologyDescription(String technology) {
    String _temp0 = intl.Intl.selectLogic(technology, {
      'agriculture':
          'Opent het basisgroeipad. Boerderijen en rivierboerderijen laten de bevolking sneller groeien en stabiliseren de eerste stad.',
      'woodworking':
          'Ontwikkelt de productiekant van de mijnbouw. Houtzagerijen zetten bossen om in productie zonder diep in de metallurgie te duiken.',
      'mining':
          'Opent het pad van industrie en infrastructuur. Mijnen zijn de eerste grote sprong voorwaarts in de stadsproductie.',
      'animalHusbandry':
          'Versterkt de groei via dierlijke hulpbronnen. Weilanden bouwen een voedseleconomie op en bereiden de weg voor paardrijden voor.',
      'hunting':
          'Opent de militaire en verkenningsafdeling. Biedt kampen en de eerste afstandseenheid voor stadsproductie.',
      'fishing':
          'Ontwikkelt steden aan het water. Vissersboten helpen kuststeden sneller te groeien en de weg naar de haven voor te bereiden.',
      'craftsmanship':
          'De eerste upgrade van de stadsproductie. De werkplaats zorgt ervoor dat latere gebouwen en eenheden de wachtrij niet te lang blokkeren.',
      'trade':
          'De eerste stap in de goudeconomie. De koopmanszaal geeft een stad een eenvoudige financiële beloning na het kiezen van een groeitak.',
      'storage':
          'Stabiliseert de groei van de stad. Opslag helpt het voedseltempo op peil te houden en vermindert het risico dat de ontwikkeling stagneert.',
      'waterEngineering':
          'Vergroot het watergroeipad. De watermolen beloont steden die rivieren beheersen.',
      'stoneworking':
          'Combineert productie en verdediging. Steengroeven en steenhouwers versterken steden in de infrastructuursector.',
      'militaryOrganization':
          'Bouwt de eerste militaire kern van een stad. Kazernes versterken de productie en verdediging voordat latere legerbonussen verschijnen.',
      'advancedTrade':
          'Ontwikkelt de economie na de handel. De markt is een sterker goudgebouw en bereidt de weg naar het bankwezen voor.',
      'construction':
          'Vergroot de volwassenheid van het territorium en de stad. Huisvesting vergroot de tegelcontrole en leidt tot administratie en engineering.',
      'navigation':
          'Opent een stadsuitbetaling voor de kust. De haven heeft toegang tot de kust/oceaan nodig en beloont steden aan het water met voedsel en goud.',
      'irrigation':
          'Gespecialiseerd in kweken op waterbasis. Het aquaduct biedt een sterke voedselbonus en extra territoriale controle.',
      'banking':
          'Gespecialiseerd in de handelsbranche. De bank verandert eerdere markten in sterke stadsinkomsten en ontsluit de bredere economie.',
      'engineering':
          'Specialisatie bouw. Het bouwersgilde versnelt de productie en verhoogt de gecontroleerde tegellimiet.',
      'metallurgy':
          'Een sterke industriële uitbetaling na steenbewerking. De smederij verhoogt de productie en bereidt de weg voor naar ijzer en steenkool.',
      'horsebackRiding':
          'Een technologie die groei en oorlog met elkaar verbindt. De stal ondersteunt steden die eerder investeerden in dieren en jacht.',
      'ironWorking':
          'Een industrieel hulpbronneneffect. Elke gecontroleerde ijzerbron verhoogt de stadsproductie.',
      'coalMining':
          'Een later industrieel hulpbronneneffect. Gecontroleerde steenkool verhoogt de stadsproductie en ondersteunt het fabriekspad.',
      'machinery':
          'Een late uitbetaling van de infrastructuur. De fabriek geeft een grote productieverhoging aan steden die de techniek zijn ingegaan.',
      'administration':
          'Verbindt infrastructuur met economie. Stadhuizen en monumenten versterken volwassen steden en leiden tot verstedelijking.',
      'logistics':
          'Versnelt de productie van eenheden. Dit is de belangrijkste technologie voor spelers die vaker legers uit steden willen inzetten.',
      'shipbuilding':
          'Ontwikkelt de deeltak kust/exploratie. De vuurtoren vereist toegang tot de kust en versterkt steden aan het water.',
      'tactics':
          'Specialisatie militaire stad. Oefenterreinen voegen defensie en productie voor militaire centra toe.',
      'economy':
          'Een systemische uitbetaling voor het bankwezen. Verhoogt het goud gegenereerd door stadseconomieën.',
      'urbanization':
          'De definitieve richting voor de groei van grote steden. Verhoogt de bevolkingslimiet zodra het bevolkingssysteem harde limieten gaat gebruiken.',
      'fortifications':
          'Versterkt de stadsverdediging. Geeft een defensieve bonus aan de stadseconomie, waarvan de volle betekenis toeneemt na uitbreiding van gevechten en belegeringen.',
      'strategy':
          'De laatste militaire richting. Versterkt de effectiviteit van het leger als uitbetaling in de late game na logistiek.',
      'specialization':
          'De uiteindelijke maatschappelijke/economische uitbetaling. Ontgrendelt stadsspecialisaties, voegt stadswetenschap toe en helpt bij het voltooien van late technologieën in langere wedstrijden.',
      'writing':
          'De eerste stap richting wetenschap, recht en bestuur. Het archief geeft een stad een permanente onderzoeksbasis.',
      'mathematics':
          'Verbindt wetenschap met territoriale planning. Het landmeterkantoor helpt steden hun grenzen effectiever te controleren.',
      'medicine':
          'Ontwikkelt de gezondheidszorg en groei op lange termijn in grote steden via apotheken, baden en ziekenhuizen.',
      'civilService':
          'Verbetert het beheer van een groot imperium en ontgrendelt rechtbanken die steden stabiliseren.',
      'siegecraft':
          'Opent een belegeringsoorlog. Katapulten en belegeringswerkplaatsen breken vestingsteden.',
      'cartography':
          'Ontwikkelt verkenning, kaarten en de kust. Geeft de kaartenkamer en de eerste verkenningsschepen.',
      'guilds':
          'Geeft productiesteden een podium tussen werkplaats en industrie.',
      'law': 'Introduceert orde, beleid en civiel bestuur via rechtbanken.',
      'education':
          'Bouwt het volledige wetenschapspad voor steden via academies en universiteiten.',
      'urbanPlanning':
          'Ontwikkelt grote steden en territoriale controle door middel van ruimtelijke planning.',
      'navalDoctrine':
          'Verandert havens in centra van vloten, scheepswerven en krachtprojectie op zee.',
      'steel':
          'Introduceert zware industrie en zware infanterie voor het latere front.',
      'bureaucracy':
          'Biedt na de regering een belangrijk maatschappelijk doel: kantoren, ministeries, musea en parlement.',
      'nationalism':
          'Combineert grensverdediging, mobilisatie en imperiumidentiteit.',
      'scientificMethod':
          'Bereidt late wetenschappelijke, laboratoria, observatoria en technologieprojecten voor.',
      'steamPower': 'Opent spoor-, zwaardere logistiek- en stoomindustrie.',
      'electricity': 'Introduceert stroom, infrastructuur en informatiebereik.',
      'combustion':
          'Geeft olie belang en ontgrendelt moderne frontlinie-eenheden.',
      'flight':
          'Introduceert luchtvaart, verkenning en krachtprojectie over het front.',
      'massProduction':
          'Ontwikkelt de uiteindelijke industriële productie, tanks en assemblagefabrieken.',
      'radio':
          'Versterkt de communicatie, zichtbaarheid en invloed van het imperium via zendmasten.',
      'nuclearPhysics':
          'Opent de reactor-, uranium- en late eindspelprojecten.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String outcomePresentationText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'victory': 'Overwinning',
      'defeat': 'Nederlaag',
      'draw': 'Gelijkspel',
      'complete': 'Partij afgelopen',
      'control': 'Kaartcontrole',
      'threshold': 'Vereiste controle',
      'other': 'Partij afgelopen',
    });
    return '$_temp0';
  }

  @override
  String resourceInventoryText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'barter': 'ruil',
      'importDirection': 'Importeert',
      'exportDirection': 'Exporteert',
      'title': 'Strategische economie',
      'healthy': 'De strategische aanvoer is stabiel.',
      'resources': 'Strategische grondstoffen',
      'alerts': 'Economische waarschuwingen',
      'allocations': 'Productietoewijzingen',
      'noAllocations': 'Er zijn geen strategische grondstoffen toegewezen.',
      'sources': 'Bronnen',
      'noSources': 'Geen actieve bronnen van strategische grondstoffen.',
      'agreements': 'Actieve overeenkomsten',
      'noAgreements': 'Geen actieve grondstoffenakkoorden.',
      'partners': 'Handelspartners',
      'noPartners':
          'Er is geen bekende beschaving beschikbaar voor grondstoffenhandel.',
      'openTrade': 'Handel openen',
      'goToCity': 'Naar stad',
      'stored': 'Voorraad',
      'allocated': 'Toegewezen',
      'controlled': 'Gecontroleerde stortingen',
      'available': 'Beschikbaar',
      'production': 'Binnenlandse productie',
      'imports': 'Invoer',
      'exports': 'Uitvoer',
      'net': 'Netto / beurt',
      'stockWarningDetail':
          'Nieuwe productie die deze grondstof vereist, is geblokkeerd.',
      'tradeWarningDetail':
          'Controleer de overeenkomst voordat de strategische stroom verandert.',
      'other': 'Strategische economie',
    });
    return '$_temp0';
  }

  @override
  String resourceInventoryAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problemen vereisen aandacht.',
      one: '1 probleem vereist aandacht.',
    );
    return '$_temp0';
  }

  @override
  String resourceInventoryNoFreeStock(String resourceName) {
    return 'Geen vrije $resourceName';
  }

  @override
  String resourceInventoryInsufficientStock(String resourceName) {
    return 'Niet genoeg vrije $resourceName';
  }

  @override
  String resourceInventoryTradeExpiring(String resourceName, int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns beurten',
      one: '1 beurt',
    );
    return 'De overeenkomst voor $resourceName loopt af over $_temp0';
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
      other: '$remainingTurns beurten resterend',
      one: '1 beurt resterend',
    );
    return '$direction: $amount $resourceName/beurt · $price · $_temp0';
  }

  @override
  String resourceInventoryTradeGold(int goldPerTurn) {
    return '$goldPerTurn goud/beurt';
  }

  @override
  String productionProgress(int invested, int cost) {
    return '$invested / $cost productie';
  }

  @override
  String productionRate(int amount) {
    return '$amount productie / beurt';
  }

  @override
  String productionRushPrice(int production, int gold) {
    return 'Versnel met $production · $gold goud';
  }

  @override
  String productionTreasury(int gold) {
    return 'Beschikbaar goud: $gold';
  }

  @override
  String productionTurns(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: 'Ongeveer $turns beurten',
      one: 'Ongeveer 1 beurt',
    );
    return '$_temp0';
  }

  @override
  String productionGoldOutput(int amount) {
    return '$amount goud / beurt';
  }

  @override
  String productionScienceOutput(int amount) {
    return '$amount wetenschap / beurt';
  }
}
