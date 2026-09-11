// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AonwLocalizationsDe extends AonwLocalizations {
  AonwLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get moveTargeting => 'Bewegen';

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String get mainMenuTitle => 'Hauptmenü';

  @override
  String get mainMenuWelcome =>
      'Willkommen in Age of New Worlds. Gründe Städte, führe Kommandanten, entdecke neue Länder und schreibe die Geschichte deiner Zivilisation.';

  @override
  String get mainMenuSynopsisTitle => 'Bauen · Forschen · Befehlen';

  @override
  String get mainMenuWhatsNew => 'Neuigkeiten';

  @override
  String get singlePlayer => 'Einzelspieler';

  @override
  String get singlePlayerSublabel => 'Gegen den Computer spielen';

  @override
  String get multiplayerSublabel => 'Online spielen';

  @override
  String get hotseat => 'Hotseat';

  @override
  String get hotseatSublabel => 'Mehrere Spieler an einem Gerät';

  @override
  String get hotseatUnavailable =>
      'Die Hotseat-Einrichtung ist noch nicht verfügbar.';

  @override
  String get hotseatHandoffTitle => 'Gib das Gerät weiter';

  @override
  String hotseatHandoffBody(String name) {
    return 'Gib das Gerät an $name. Die Karte bleibt bis zur Bestätigung verborgen.';
  }

  @override
  String hotseatContinueAs(String name) {
    return 'Als $name fortfahren';
  }

  @override
  String get hotseatHandoffSwitching => 'Der nächste Spieler wird vorbereitet';

  @override
  String get hotseatHandoffFailure =>
      'Die Sitzung des nächsten lokalen Spielers konnte nicht sicher geöffnet werden.';

  @override
  String get loadGame => 'Spiel laden';

  @override
  String get loadGameSublabel => 'Spielstände und Wiederholungen';

  @override
  String get exitGame => 'Beenden';

  @override
  String get instructions => 'Handbuch';

  @override
  String get creditsTitle => 'Mitwirkende';

  @override
  String creditsCreatedBy(String name) {
    return 'Erstellt von $name';
  }

  @override
  String get devlogLinkLabel => 'Entwicklungstagebuch: ernest.dev';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackDescription =>
      'Teile Ideen, melde Probleme und verfolge die Entwicklung mit der Community von Age of New Worlds.';

  @override
  String get openFeedback => 'r/aonw öffnen';

  @override
  String get externalLinkUnavailable =>
      'Externe Links sind auf dieser Plattform nicht verfügbar.';

  @override
  String get serverUpdateSoon =>
      'Eine neue Version ist fertig und wird bald auf dieser Plattform verfügbar sein. Sieh in Kürze erneut im Store oder Launcher nach.';

  @override
  String get continueGame => 'Fortsetzen';

  @override
  String get resumingGame => 'Spiel wird fortgesetzt';

  @override
  String get newGame => 'Neues Spiel';

  @override
  String get multiplayerTitle => 'Mehrspieler';

  @override
  String get multiplayerUnavailable =>
      'Mehrspieler ist in dieser Version nicht verfügbar.';

  @override
  String get loadingMultiplayer =>
      'Verbindung zum Mehrspielermodus wird hergestellt';

  @override
  String get multiplayerAuthenticationTitle => 'AoNW-Konto';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get displayNameLabel => 'Anzeigename';

  @override
  String get invalidEmail => 'Gib eine gültige E-Mail-Adresse ein.';

  @override
  String get invalidPassword => 'Verwende mindestens 12 Zeichen.';

  @override
  String get invalidDisplayName => 'Gib einen Anzeigenamen ein.';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get createNewAccount => 'Neues Konto erstellen';

  @override
  String get useExistingAccount => 'Vorhandenes Konto verwenden';

  @override
  String get multiplayerLobbyTitle => 'Spiellobby';

  @override
  String signedInAccount(String userId) {
    return 'Konto: $userId';
  }

  @override
  String get multiplayerSetupTitle => 'Online-Spiel erstellen';

  @override
  String get multiplayerSetupIntro =>
      'Wähle deine Zivilisation und Karte, bevor du den vom Server verwalteten Warteraum öffnest.';

  @override
  String get multiplayerTurnModeDescription =>
      'Alle Spieler handeln in einer gemeinsamen Runde. Die Spielengine wertet sie nach allen erforderlichen Bestätigungen oder nach Ablauf der serverseitigen Frist aus.';

  @override
  String get continueToLobby => 'Weiter zur Lobby';

  @override
  String get createMultiplayerMatch => 'Partie erstellen';

  @override
  String get joinMultiplayerMatch => 'Partie beitreten';

  @override
  String get matchIdLabel => 'Partie-ID';

  @override
  String get playerSeatLabel => 'Spielerplatz';

  @override
  String get playerSeatOne => 'Spieler eins';

  @override
  String get playerSeatTwo => 'Spieler zwei';

  @override
  String playerSeatNumber(int number) {
    return 'Spieler $number';
  }

  @override
  String get refreshMatches => 'Partien aktualisieren';

  @override
  String get yourMatches => 'Deine Partien';

  @override
  String get noMultiplayerMatches => 'Du bist noch keiner Partie beigetreten.';

  @override
  String matchRevision(int revision, int eventOffset) {
    return 'Revision $revision · Ereignisposition $eventOffset';
  }

  @override
  String multiplayerMatchPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'lobby': 'Warteraum',
      'running': 'läuft',
      'finished': 'beendet',
      'abandoned': 'abgebrochen',
      'other': 'unbekannt',
    });
    return 'Status: $_temp0';
  }

  @override
  String get multiplayerWaitingRoomTitle => 'Warteraum der Partie';

  @override
  String get multiplayerReady => 'Bereit';

  @override
  String get multiplayerNotReady => 'Nicht bereit';

  @override
  String get multiplayerSeatOpen => 'Freier Spielerplatz';

  @override
  String get multiplayerHumanSeat => 'Mensch';

  @override
  String get multiplayerAiSeat => 'Computer';

  @override
  String get multiplayerHost => 'Gastgeber';

  @override
  String get multiplayerCurrentPlayer => 'Du';

  @override
  String get markReady => 'Bereitschaft bestätigen';

  @override
  String get markNotReady => 'Bereitschaft zurücknehmen';

  @override
  String get waitingForPlayers =>
      'Alle menschlichen Spielerplätze müssen belegt und bereit sein, bevor die Partie beginnt.';

  @override
  String get refreshMatch => 'Partie aktualisieren';

  @override
  String get leaveMultiplayerMatch => 'Partie verlassen';

  @override
  String get multiplayerResignTitle => 'Diese Partie aufgeben?';

  @override
  String get multiplayerResignBody =>
      'Deine Teilnahme endet sofort. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get multiplayerResignConfirm => 'Aufgeben';

  @override
  String get multiplayerMatchTitle => 'Online-Partie';

  @override
  String get multiplayerParticipants => 'Teilnehmer';

  @override
  String get multiplayerRemoveParticipant => 'Entfernen';

  @override
  String get multiplayerRemoveParticipantTitle => 'Teilnehmer entfernen?';

  @override
  String multiplayerRemoveParticipantBody(String name) {
    return '$name aus dieser Partie entfernen? Eine erneute Verbindung ist danach nicht mehr möglich.';
  }

  @override
  String get cancelDialog => 'Abbrechen';

  @override
  String matchIdentifier(String matchId) {
    return 'Partie: $matchId';
  }

  @override
  String playerIdentifier(String playerId) {
    return 'Spieler: $playerId';
  }

  @override
  String multiplayerTurn(int turn) {
    return 'Runde $turn';
  }

  @override
  String multiplayerSubmissionProgress(int submitted, int required) {
    return 'Bestätigt: $submitted von $required';
  }

  @override
  String visibleUnits(int count) {
    return 'Sichtbare Einheiten: $count';
  }

  @override
  String networkPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'connecting': 'wird hergestellt',
      'ready': 'online',
      'reconnecting': 'wird wiederhergestellt',
      'resyncing': 'wird synchronisiert',
      'failed': 'offline',
      'closed': 'geschlossen',
      'other': 'nicht verfügbar',
    });
    return 'Verbindung: $_temp0';
  }

  @override
  String get submitTurn => 'Runde bestätigen';

  @override
  String get reconnect => 'Erneut verbinden';

  @override
  String get backToLobby => 'Zurück zur Lobby';

  @override
  String multiplayerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'client_update_required':
          'Aktualisiere den Client, bevor du eine Verbindung herstellst.',
      'authentication_required': 'Melde dich erneut an, um fortzufahren.',
      'invalid_authentication_response': 'Die Anmeldeantwort war ungültig.',
      'authentication_identity_changed':
          'Die Kontoidentität hat sich während der Aktualisierung geändert.',
      'connection_interrupted':
          'Die Verbindung wurde unterbrochen. Verbinde dich erneut, um die Partie zu synchronisieren.',
      'invalid_server_response':
          'Die Serverantwort hat die Prüfung nicht bestanden.',
      'invalid_command_sequence': 'Die Befehlsfolge war nicht lückenlos.',
      'invalid_resync_sequence':
          'Der synchronisierte Zustand ist auf einen älteren Stand zurückgefallen.',
      'invalid_match_lifecycle':
          'Die Antwort zum Verlauf der Partie war widersprüchlich.',
      'match_not_found': 'Die Partie wurde nicht gefunden.',
      'match_not_started': 'Der Gastgeber hat die Partie noch nicht gestartet.',
      'match_already_started': 'Die Partie hat bereits begonnen.',
      'host_required': 'Nur der Gastgeber kann diese Aktion ausführen.',
      'lobby_not_ready':
          'Alle menschlichen Spieler müssen beitreten und bereit sein.',
      'participant_not_claimable':
          'Computergesteuerte Plätze können nicht übernommen werden.',
      'participant_not_active': 'Dieser Teilnehmer ist nicht mehr aktiv.',
      'invalid_kick_target': 'Der Gastgeber kann sich nicht selbst entfernen.',
      'player_seat_taken': 'Dieser Spielerplatz ist bereits belegt.',
      'other': 'Die Mehrspieler-Anfrage konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String get helpTitle => 'Spielanleitung';

  @override
  String get helpIntroduction =>
      'Baue Runde für Runde eine Zivilisation auf. Die Spielengine setzt alle Regeln um; diese Anleitung erklärt die Entscheidungen, die dir im Client zur Verfügung stehen.';

  @override
  String get helpObjectiveTitle => 'Verfolge dein Ziel';

  @override
  String get helpObjectiveBody =>
      'Erweitere dein Reich, entwickle Städte und erfülle die Szenarioziele vor deinem Gegner. Öffne die strategischen Ziele auf der Karte, um die festgelegten Aufgaben anzusehen.';

  @override
  String get helpMapTitle => 'Erkunde und befehlige';

  @override
  String get helpMapBody =>
      'Wähle ein sichtbares Hexfeld, um es zu untersuchen. Wähle deine Einheit, ein hervorgehobenes Ziel und bestätige die Route. Tastatur, Gamepad und Touchsteuerung verwenden dieselben Befehle.';

  @override
  String get helpDevelopmentTitle => 'Entwickle deine Zivilisation';

  @override
  String get helpDevelopmentBody =>
      'Nutze die Bereiche für Städte, Forschung, Produktion, Arbeiter, Logistik, Artefakte und Diplomatie, sobald ihre Aktionen verfügbar werden.';

  @override
  String get helpTurnTitle => 'Beende die Runde bewusst';

  @override
  String get helpTurnBody =>
      'Schließe deine Aktionen ab und beende dann die Runde. Der Computer führt seine von der Spielengine geprüfte Runde aus, bevor du wieder an der Reihe bist.';

  @override
  String get helpSaveReplayTitle => 'Speichern und nachverfolgen';

  @override
  String get helpSaveReplayBody =>
      'Speichere auf der Karte. Fortsetzen öffnet den letzten gültigen Spielstand. Eine Wiederholung zeigt den Verlauf der bestätigten Befehle, ohne das Spiel zu verändern.';

  @override
  String get startOnboarding => 'Geführte Einführung starten';

  @override
  String get onboardingTitle => 'Geführte Einführung';

  @override
  String onboardingProgress(int step, int count) {
    return 'Schritt $step von $count';
  }

  @override
  String get onboardingExploreTitle => 'Lies die Karte';

  @override
  String get onboardingExploreBody =>
      'Die Karte zeigt nur Informationen, die dein Spieler sehen darf. Wähle Hexfelder, um Gelände, Städte und Einheiten zu untersuchen. Verschiebe oder zoome anschließend die Ansicht, um deine nächste Aktion zu planen.';

  @override
  String get onboardingCommandTitle => 'Gib genaue Befehle';

  @override
  String get onboardingCommandBody =>
      'Die Spielengine liefert die verfügbaren Ziele und Aktionen. Wähle eine Möglichkeit, prüfe die Vorschau und bestätige sie. Abgelehnte oder veraltete Befehle verändern die Partie niemals.';

  @override
  String get onboardingDevelopTitle => 'Baue einen langfristigen Vorteil auf';

  @override
  String get onboardingDevelopBody =>
      'Städte, Produktion, Forschung, Arbeiter, Logistik, Artefakte und Diplomatie prägen deine Strategie. Ihre Bereiche zeigen nur Aktionen, die die Spielengine derzeit erlaubt.';

  @override
  String get onboardingContinueTitle => 'Setze dein Spiel sicher fort';

  @override
  String get onboardingContinueBody =>
      'Speichere den bestätigten Spielstand, bevor du das Spiel verlässt. Fortsetzen prüft ihn in einer neuen Sitzung der Spielengine. Eine Wiederholung zeigt denselben Verlauf, ohne ihn zu verändern.';

  @override
  String get previousOnboardingStep => 'Zurück';

  @override
  String get nextOnboardingStep => 'Weiter';

  @override
  String get skipOnboarding => 'Überspringen';

  @override
  String get finishOnboarding => 'Spiel erstellen';

  @override
  String get newGameTitle => 'Lokales Spiel erstellen';

  @override
  String get singlePlayerSetupTitle => 'Gegen den Computer spielen';

  @override
  String get singlePlayerSetupIntro =>
      'Wähle deine Zivilisation und richte eine von der Spielengine verwaltete lokale Partie ein.';

  @override
  String get hotseatSetupTitle => 'Im Hotseat-Modus spielen';

  @override
  String get hotseatSetupIntro =>
      'Teilt euch ein Gerät. Die Ansicht jedes menschlichen Spielers bleibt verborgen, bis der nächste Spieler die Übergabe bestätigt.';

  @override
  String get chooseCivilizationTitle => 'Zivilisation wählen';

  @override
  String get gameSetupTitle => 'Spieleinstellungen';

  @override
  String get turnModeTitle => 'Rundenmodus';

  @override
  String turnModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'sequential': 'Traditionell',
      'simultaneous': 'Gleichzeitig',
      'other': 'Unbekannt',
    });
    return '$_temp0';
  }

  @override
  String get turnModeSequentialDescription =>
      'Die Zivilisationen führen ihre Runden nacheinander aus und werten sie aus.';

  @override
  String get turnModeSimultaneousDescription =>
      'Du und der Computer handeln in einer gemeinsamen Runde, bevor die Spielengine deren gemeinsame Phasen auswertet.';

  @override
  String get opponentsTitle => 'Gegner';

  @override
  String get opponentControlLabel => 'Gegnersteuerung';

  @override
  String opponentNumberLabel(int number) {
    return 'Gegner $number';
  }

  @override
  String get humanOpponent => 'Menschlicher Spieler';

  @override
  String get aiOpponent => 'Computer';

  @override
  String get mapSetupTitle => 'Karte';

  @override
  String get mapSetupBody =>
      'Eine kompakte, gestaltete Karte mit 7 × 7 Feldern für eine Partie mit zwei Zivilisationen.';

  @override
  String mapSetupDetails(String mapName, int columns, int rows, int players) {
    return '$mapName · $columns × $rows · $players Zivilisationen';
  }

  @override
  String get victoryPathsTitle => 'Wege zum Sieg';

  @override
  String get victoryPathsBody =>
      'Eroberung, Vorherrschaft, Kultur und Punkte werden von der Spielengine ausgewertet.';

  @override
  String get settlementToEmpireTitle => 'Von der Siedlung zum Reich';

  @override
  String get settlementToEmpireBody =>
      'Erkunde, gründe Städte, forsche, stelle Armeen auf und verschaffe dir dauerhafte Vorteile.';

  @override
  String get continueToSummary => 'Weiter zur Übersicht';

  @override
  String get gameSummaryTitle => 'Die Expedition ist bereit';

  @override
  String get gameSummaryIntro =>
      'Prüfe alle lokalen Teilnehmer, bevor du die Partie erstellst.';

  @override
  String get summaryModeLabel => 'Modus';

  @override
  String get summaryTurnModeLabel => 'Runden';

  @override
  String get summaryCivilizationLabel => 'Deine Zivilisation';

  @override
  String get summaryOpponentLabel => 'Gegner';

  @override
  String get summaryMapLabel => 'Karte';

  @override
  String get summaryFogLabel => 'Nebel des Krieges';

  @override
  String get summaryAiLabel => 'Computerprofil';

  @override
  String get changeSetup => 'Einstellungen ändern';

  @override
  String localModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'singlePlayer': 'Einzelspieler',
      'hotseat': 'Hotseat',
      'other': 'Lokales Spiel',
    });
    return '$_temp0';
  }

  @override
  String participantControlName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'human': 'Mensch',
      'ai': 'Computer',
      'other': 'Unbekannt',
    });
    return '$_temp0';
  }

  @override
  String fogSettingName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'enabled': 'Aktiviert',
      'disabled': 'Deaktiviert',
      'other': 'Unbekannt',
    });
    return '$_temp0';
  }

  @override
  String get defaultSecondPlayerName => 'Spieler 2';

  @override
  String defaultNumberedPlayerName(int number) {
    return 'Spieler $number';
  }

  @override
  String defaultNumberedAiName(int number) {
    return 'Computer $number';
  }

  @override
  String get scenarioLabel => 'Karte';

  @override
  String localScenarioName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'starterDuel': 'Einstieg',
      'dravonia': 'Dravonia',
      'myranth': 'Myranth',
      'terenos': 'Terenos',
      'verdantia': 'Verdantia',
      'other': 'Lokale Karte',
    });
    return '$_temp0';
  }

  @override
  String get humanCountryLabel => 'Dein Land';

  @override
  String get aiCountryLabel => 'Land der KI';

  @override
  String get aiDifficultyLabel => 'KI-Schwierigkeit';

  @override
  String get aiPersonaLabel => 'KI-Persönlichkeit';

  @override
  String get fogOfWarLabel => 'Nebel des Krieges';

  @override
  String get startGame => 'Spiel starten';

  @override
  String get startingGame => 'Spiel wird gestartet';

  @override
  String get localGameStartFailed =>
      'Das lokale Spiel konnte nicht gestartet werden.';

  @override
  String get saveGame => 'Spiel speichern';

  @override
  String get savingGame => 'Spiel wird gespeichert';

  @override
  String get gameSaved => 'Spiel gespeichert';

  @override
  String saveFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Speichern ist für diese Sitzung nicht verfügbar.',
      'exportFailed': 'Das Spiel konnte nicht exportiert werden.',
      'writeFailed': 'Die Spielstandsdatei konnte nicht gespeichert werden.',
      'other': 'Das Spiel konnte nicht gespeichert werden.',
    });
    return '$_temp0';
  }

  @override
  String resumeFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Spielstände sind auf dieser Plattform nicht verfügbar.',
      'missing': 'Es wurde kein Spielstand gefunden.',
      'unreadable': 'Der Spielstand konnte nicht gelesen werden.',
      'incompatible':
          'Der Spielstand ist ungültig oder mit dem aktuellen Spiel nicht kompatibel.',
      'other': 'Der Spielstand konnte nicht fortgesetzt werden.',
    });
    return '$_temp0';
  }

  @override
  String get loadGameTitle => 'Spiel laden';

  @override
  String get loadGameEmpty => 'Es wurden keine Spielstände gefunden.';

  @override
  String loadGameSingleLabel(String scenario) {
    return 'Einzelspieler · $scenario';
  }

  @override
  String get importSave => 'Spielstand importieren';

  @override
  String get exportSave => 'Exportieren';

  @override
  String get saveTransferUnavailable =>
      'Der Import und Export von Spielständen ist auf dieser Plattform nicht verfügbar.';

  @override
  String saveImportCompleted(String map) {
    return '$map wurde als separater Spielstand importiert.';
  }

  @override
  String saveExportCompleted(String map) {
    return '$map wurde exportiert.';
  }

  @override
  String saveTransferFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'Die Übertragung von Spielständen ist auf dieser Plattform nicht verfügbar.',
      'unreadable':
          'Die gewählte Spielstandsdatei konnte nicht gelesen werden.',
      'tooLarge':
          'Die gewählte Spielstandsdatei überschreitet die Grenze von 16 MiB.',
      'incompatible':
          'Der gewählte Spielstand ist ungültig oder passt nicht zu einer installierten Karte, einem Regelwerk oder der Version der Spielengine.',
      'missing': 'Der gewählte Spielstand existiert nicht mehr.',
      'writeFailed':
          'Der importierte Spielstand konnte nicht gespeichert werden.',
      'exportFailed': 'Die Spielstandsdatei konnte nicht exportiert werden.',
      'other':
          'Die Übertragung des Spielstands konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String get replayTitle => 'Wiederholung';

  @override
  String get loadingReplay => 'Wiederholung wird geladen';

  @override
  String get replayUnavailable =>
      'Die Wiedergabe von Wiederholungen ist nicht verfügbar.';

  @override
  String replayFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'Die Wiedergabe von Wiederholungen ist auf dieser Plattform nicht verfügbar.',
      'missing':
          'Es wurde keine Wiederholung gefunden. Speichere zuerst ein lokales Spiel.',
      'unreadable': 'Die Wiederholungsdatei konnte nicht gelesen werden.',
      'incompatible':
          'Die Wiederholung ist ungültig oder mit dem aktuellen Spiel nicht kompatibel.',
      'seekFailed':
          'Der gewünschte Schritt der Wiederholung konnte nicht geladen werden.',
      'other': 'Die Wiederholung konnte nicht geöffnet werden.',
    });
    return '$_temp0';
  }

  @override
  String get replayMapLabel => 'Karte der Wiederholung';

  @override
  String get replayControls => 'Wiedergabesteuerung';

  @override
  String get playReplay => 'Wiederholung abspielen';

  @override
  String get pauseReplay => 'Wiederholung pausieren';

  @override
  String get backToMenu => 'Zurück zum Hauptmenü';

  @override
  String replayProgress(int position, int entryCount) {
    return '$position von $entryCount';
  }

  @override
  String replaySpeed(String value) {
    return 'Geschwindigkeit $value×';
  }

  @override
  String get aiTurnRunning => 'Der Computer ist am Zug.';

  @override
  String aiTurnFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'requestFailed':
          'Die Runde des Computers konnte nicht abgeschlossen werden.',
      'responseIncompatible':
          'Die Antwort auf die Computerrunde ist mit diesem Client nicht kompatibel.',
      'incomplete':
          'Der Computer hat seine Runde nicht innerhalb der sicheren Befehlsgrenze abgeschlossen.',
      'other': 'Die Runde des Computers konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String get defaultPlayerName => 'Spieler';

  @override
  String get defaultAiName => 'Computer';

  @override
  String countryName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'poland': 'Polen',
      'ukraine': 'Ukraine',
      'germany': 'Deutschland',
      'france': 'Frankreich',
      'unitedKingdom': 'Vereinigtes Königreich',
      'italy': 'Italien',
      'spain': 'Spanien',
      'netherlands': 'Niederlande',
      'sweden': 'Schweden',
      'russia': 'Russland',
      'unitedStates': 'Vereinigte Staaten',
      'canada': 'Kanada',
      'china': 'China',
      'korea': 'Korea',
      'japan': 'Japan',
      'portugal': 'Portugal',
      'india': 'Indien',
      'brazil': 'Brasilien',
      'indonesia': 'Indonesien',
      'mexico': 'Mexiko',
      'turkey': 'Türkei',
      'saudiArabia': 'Saudi-Arabien',
      'egypt': 'Ägypten',
      'greece': 'Griechenland',
      'other': 'Unbekanntes Land',
    });
    return '$_temp0';
  }

  @override
  String aiDifficultyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'easy': 'Leicht',
      'normal': 'Normal',
      'hard': 'Schwer',
      'veryHard': 'Sehr schwer',
      'other': 'Unbekannte Schwierigkeit',
    });
    return '$_temp0';
  }

  @override
  String aiPersonaName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'balanced': 'Ausgewogen',
      'aggressive': 'Aggressiv',
      'expansive': 'Expansiv',
      'economic': 'Wirtschaftlich',
      'scientific': 'Wissenschaftlich',
      'other': 'Unbekannte Persönlichkeit',
    });
    return '$_temp0';
  }

  @override
  String get unknownRouteLabel => 'Unbekannte Seite';

  @override
  String get pageUnavailable => 'Seite nicht verfügbar';

  @override
  String unknownRouteMessage(String location) {
    return 'Unbekannte Seite: $location';
  }

  @override
  String get missingRouteLocation => '(fehlt)';

  @override
  String mapSemanticsLabel(String mapId, int cols, int rows) {
    return 'Karte $mapId, $cols mal $rows Hexfelder';
  }

  @override
  String get mapInputHint =>
      'Verschiebe die Kamera mit WASD oder den Pfeiltasten. Wähle mit Eingabe aus, aktiviere mit M den Bewegungsmodus, untersuche mit I und wechsle mit R die Kartenansicht. Mit den eckigen Klammern wechselst du zwischen offenen Aktionen. Die Leertaste öffnet die nächste Aktion oder beendet die Runde. Mit Tab wechselst du zwischen Bedienelementen.';

  @override
  String get noHexSelected => 'Kein Hexfeld ausgewählt';

  @override
  String selectedHex(int col, int row) {
    return 'Ausgewähltes Hexfeld $col, $row';
  }

  @override
  String get mapViewModeTooltip => 'Kartenansicht wechseln';

  @override
  String get mapViewGraphicUnavailable =>
      'Die grafische Ansicht ist für diese Karte nicht verfügbar.';

  @override
  String get mapViewModeGraphic => 'Grafisch';

  @override
  String get mapViewModeTiles => 'Kacheln';

  @override
  String hexLabel(int col, int row) {
    return 'Hexfeld $col, $row';
  }

  @override
  String get selectionTerrain => 'Gelände';

  @override
  String unitLabel(String unitId) {
    return 'Einheit $unitId';
  }

  @override
  String routeSummary(int totalCost, int remaining) {
    return 'Route: $totalCost Bewegungspunkte · $remaining verbleibend';
  }

  @override
  String get confirmMove => 'Bewegung bestätigen';

  @override
  String moveTurnCost(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns Runden',
      one: '1 Runde',
    );
    return '$_temp0';
  }

  @override
  String confirmMoveWithCost(String turnCost) {
    return 'Bestätigen · $turnCost';
  }

  @override
  String get chooseHighlightedDestination => 'Wähle ein hervorgehobenes Ziel.';

  @override
  String get movingUnit => 'Einheit wird bewegt';

  @override
  String unitActionLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'title': 'Einheitenaktionen',
      'fortify': 'Befestigen',
      'skip': 'Aussetzen',
      'cancel': 'Aktion abbrechen',
      'executing': 'Einheitenaktion wird ausgeführt',
      'logisticsTitle': 'Logistik',
      'logisticsLoading': 'Logistikoptionen werden geladen',
      'logisticsEmpty': 'Derzeit sind keine Logistikaktionen verfügbar.',
      'autoExplore': 'Automatisch erkunden',
      'merchantRoute': 'Handelsroute zuweisen',
      'merchantTravel': 'Zur Stadt bewegen',
      'detachTroop': 'Trupp abtrennen',
      'other': 'Einheitenaktion',
    });
    return '$_temp0';
  }

  @override
  String unitActionFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed':
          'Die Anfrage für die Einheitenaktion konnte nicht abgeschlossen werden.',
      'responseIncompatible':
          'Die Antwort auf die Einheitenaktion ist mit diesem Client nicht kompatibel.',
      'sessionUnavailable': 'Die lokale Spielsitzung ist nicht verfügbar.',
      'stale':
          'Der Spielzustand hat sich geändert. Prüfe die Einheit und versuche es erneut.',
      'matchFinished': 'Die Partie ist bereits beendet.',
      'unitUnavailable': 'Diese Einheit kann keine Befehle mehr empfangen.',
      'unitBusy':
          'Diese Einheit ist beschäftigt und kann die Aktion gerade nicht ausführen.',
      'internal':
          'Die Einheitenaktion konnte nicht angewendet werden. Versuche es erneut.',
      'logisticsRequestFailed':
          'Die Logistikanfrage konnte nicht abgeschlossen werden.',
      'logisticsResponseIncompatible':
          'Die Logistikantwort ist mit diesem Client nicht kompatibel.',
      'logisticsOptionUnavailable':
          'Diese Logistikoption ist nicht mehr verfügbar.',
      'combatFailureRequestFailed':
          'Die Kampfanfrage konnte nicht abgeschlossen werden.',
      'combatFailureResponseIncompatible':
          'Die Kampfantwort ist mit diesem Client nicht kompatibel.',
      'combatFailureSessionUnavailable':
          'Die lokale Spielsitzung ist nicht verfügbar.',
      'combatFailureTargetUnavailable':
          'Für dieses Ziel ist keine Angriffsvorschau verfügbar.',
      'combatFailureStaleRevision':
          'Der Spielzustand hat sich geändert. Prüfe ihn und versuche es erneut.',
      'combatFailureMatchFinished': 'Die Partie ist bereits beendet.',
      'combatFailureAttackerNotFound':
          'Die angreifende Einheit ist nicht mehr verfügbar.',
      'combatFailureAttackerNotControlled':
          'Dieser Spieler kontrolliert die angreifende Einheit nicht.',
      'combatFailureAttackerUnavailable':
          'Die angreifende Einheit ist nicht verfügbar.',
      'combatFailureAttackerExhausted':
          'Die angreifende Einheit ist erschöpft.',
      'combatFailureAttackerOutOfBounds':
          'Die angreifende Einheit befindet sich außerhalb der Karte.',
      'combatFailureAttackerCannotAttack':
          'Diese Einheit kann nicht angreifen.',
      'combatFailureAttackTargetNotVisible': 'Das Ziel ist nicht sichtbar.',
      'combatFailureAttackTargetOutOfBounds':
          'Das Ziel befindet sich außerhalb der Karte.',
      'combatFailureAttackTargetNotFound': 'Dort befindet sich kein Ziel.',
      'combatFailureAttackTargetNotEnemy': 'Dieses Ziel ist kein Feind.',
      'combatFailureAttackTargetProtectedByTreaty':
          'Ein Vertrag schützt dieses Ziel.',
      'combatFailureAttackTargetOutOfRange': 'Das Ziel ist außer Reichweite.',
      'combatFailureAttackCityHasNoHealth':
          'Diese Stadt kann nicht angegriffen werden.',
      'other': 'Die Einheitenaktion konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String turnSummary(String kind, int turn, int submitted, int required) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'label': 'RUNDE $turn',
      'progress': 'Bereit: $submitted von $required',
      'other': 'RUNDE $turn',
    });
    return '$_temp0';
  }

  @override
  String turnText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'statusActive': 'Du bist am Zug',
      'statusFinished': 'Runde beendet',
      'statusSubmitted': 'Runde bestätigt',
      'statusWaiting': 'Warten',
      'statusPendingAction': 'Aktion erforderlich',
      'actionEnd': 'Runde beenden',
      'actionSubmit': 'Zug bestätigen',
      'actionSubmitting': 'Zug wird bestätigt',
      'actionEnding': 'Runde wird beendet',
      'outcomeConquest': 'Eroberungssieg',
      'outcomeDomination': 'Vorherrschaftssieg',
      'outcomeCultural': 'Kultursieg',
      'outcomeScore': 'Punktesieg',
      'outcomeResignation': 'Partie durch Aufgabe beendet',
      'outcomeDraw': 'Unentschieden',
      'outcomeOngoing': 'Partie läuft',
      'activityTitle': 'Aktivität',
      'activityArtifact': 'Artefaktaktivität',
      'activityCity': 'Stadtaktivität',
      'activityResearch': 'Forschungsfortschritt',
      'activityObjective': 'Strategisches Ziel aktualisiert',
      'activityOutcome': 'Spielergebnis aktualisiert',
      'activityCombat': 'Kampfaktivität',
      'activityDiplomacy': 'Diplomatische Aktivität',
      'activityUnit': 'Einheitenaktivität',
      'activityTurn': 'Runde aktualisiert',
      'activityWorker': 'Arbeiterauftrag abgeschlossen',
      'combatTitle': 'Kampf',
      'combatLoading': 'Kampfvorschau wird geladen',
      'combatTarget': 'Ziel',
      'combatDistance': 'Entfernung',
      'combatOutgoing': 'Verursachter Schaden',
      'combatRetaliation': 'Vergeltungsschaden',
      'combatNone': 'Keine',
      'combatCapture': 'Stadt einnehmen',
      'combatDestroy': 'Stadt zerstören',
      'combatConfirm': 'Angriff bestätigen',
      'combatExecuting': 'Kampf wird ausgewertet',
      'combatResolved': 'Kampf ausgewertet',
      'combatAttackerHp': 'Gesundheit des Angreifers',
      'combatDefenderHp': 'Gesundheit des Verteidigers',
      'combatEventUnitAttacked': 'Einheit angegriffen',
      'combatEventCityAttacked': 'Stadt angegriffen',
      'combatEventCombatResolved': 'Kampf ausgewertet',
      'combatEventUnitGainedExperience': 'Einheit hat Erfahrung gesammelt',
      'combatEventUnitKilled': 'Einheit besiegt',
      'combatEventUnitRetreated': 'Einheit zurückgezogen',
      'combatEventCityCaptured': 'Stadt eingenommen',
      'combatEventCityDestroyed': 'Stadt zerstört',
      'combatEventDiplomaticScoreChanged': 'Diplomatische Beziehung geändert',
      'other': 'Spielaktivität',
    });
    return '$_temp0';
  }

  @override
  String turnFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'Die Rundenanfrage konnte nicht abgeschlossen werden.',
      'responseIncompatible':
          'Die Rundenantwort ist mit diesem Client nicht kompatibel.',
      'sessionUnavailable': 'Die lokale Spielsitzung ist nicht verfügbar.',
      'stale_revision':
          'Der Spielzustand hat sich geändert. Prüfe ihn und versuche es erneut.',
      'match_finished': 'Die Partie ist bereits beendet.',
      'turn_player_not_controlled':
          'Dieser Spieler kann die aktuelle Runde nicht beenden.',
      'turn_player_not_active': 'Dieser Spieler ist nicht aktiv.',
      'turn_scope_invalid':
          'Der Geltungsbereich der aktuellen Runde ist ungültig.',
      'turn_processor_unsupported':
          'Ein erforderlicher Rundenschritt ist nicht verfügbar.',
      'turn_number_overflow':
          'Die nächste Rundennummer überschreitet die zulässige Grenze.',
      'state_revision_overflow':
          'Die Spielrevision kann nicht weiter erhöht werden.',
      'other': 'Die Runde konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String get loadingMap => 'Karte wird geladen';

  @override
  String get mapLoadingFailed => 'Laden der Karte fehlgeschlagen';

  @override
  String get mapUnavailable => 'Karte nicht verfügbar';

  @override
  String get mapAdapterUnavailable =>
      'Der native Spieladapter ist auf dieser Plattform nicht verfügbar.';

  @override
  String get mapClientIncompatible =>
      'Der native Spieladapter ist mit diesem Client nicht kompatibel.';

  @override
  String get mapLoadSuperseded =>
      'Eine neuere Kartenanfrage hat diese ersetzt.';

  @override
  String get mapLoadFailure => 'Die Karte konnte nicht geladen werden.';

  @override
  String get movementRequestFailed =>
      'Die Bewegungsanfrage konnte nicht abgeschlossen werden.';

  @override
  String get movementResponseIncompatible =>
      'Die Bewegungsantwort ist mit diesem Client nicht kompatibel.';

  @override
  String get movementSessionUnavailable =>
      'Die lokale Spielsitzung ist nicht verfügbar.';

  @override
  String get moveRejectedStale =>
      'Der Spielzustand hat sich geändert. Prüfe die aktuelle Position und versuche es erneut.';

  @override
  String get moveRejectedUnitUnavailable =>
      'Diese Einheit steht nicht mehr für eine Bewegung zur Verfügung.';

  @override
  String get moveRejectedUnitBusy =>
      'Diese Einheit ist beschäftigt und kann sich gerade nicht bewegen.';

  @override
  String get moveRejectedTargetUnavailable =>
      'Dieses Ziel ist nicht verfügbar.';

  @override
  String get moveRejectedMovementInsufficient =>
      'Die Einheit hat nicht genügend Bewegungspunkte übrig.';

  @override
  String get moveRejectedPathUnavailable =>
      'Es gibt keine gültige Route zu diesem Ziel.';

  @override
  String get moveRejectedInternal =>
      'Die Bewegung konnte nicht angewendet werden. Versuche es erneut.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get audioSettings => 'Audio';

  @override
  String get cameraSettings => 'Kamera';

  @override
  String get cameraSensitivity => 'Zoomempfindlichkeit';

  @override
  String get animationSettings => 'Animationen';

  @override
  String get showUnitMovementAnimations =>
      'Bewegungsanimationen der Einheiten anzeigen';

  @override
  String get showUnitIdleAnimations => 'Ruheanimationen der Einheiten anzeigen';

  @override
  String get showRouteAnimations => 'Animationen geplanter Routen anzeigen';

  @override
  String get showCombatAnimations => 'Kampfanimationen anzeigen';

  @override
  String get cinematicCamera => 'Filmische Kamera';

  @override
  String get smoothCameraMovement => 'Weiche Kamerabewegung';

  @override
  String get mapSettings => 'Karte';

  @override
  String get mapGrid => 'Hexfeldränder';

  @override
  String get mapGridDescription =>
      'Schwarze Ränder um die Hexfelder der Karte anzeigen.';

  @override
  String get mapResourceIcons => 'Ressourcensymbole';

  @override
  String get mapResourceIconsDescription =>
      'Auf Hexfeldern verfügbare Ressourcen anzeigen.';

  @override
  String get mapTerrainIcons => 'Geländesymbole';

  @override
  String get mapTerrainIconsDescription =>
      'Die Geländemerkmale jedes Hexfelds anzeigen.';

  @override
  String get mapHeightBadges => 'Höhenangaben';

  @override
  String get mapHeightBadgesDescription =>
      'Die festgelegte Höhe erhöhter Hexfelder anzeigen.';

  @override
  String get mapElevationWalls => 'Höhenwände';

  @override
  String get mapElevationWallsDescription =>
      'Die Tiefe erhöhter Hexfelder unter Berücksichtigung ihrer Nachbarn anzeigen.';

  @override
  String get accessibilitySettings => 'Barrierefreiheit';

  @override
  String get reducedMotion => 'Bewegungen reduzieren';

  @override
  String get reducedMotionDescription =>
      'Unwesentliche Animationen und Übergänge vermeiden.';

  @override
  String get highContrast => 'Hoher Kontrast';

  @override
  String get highContrastDescription =>
      'Den Kontrast der Benutzeroberfläche erhöhen.';

  @override
  String get resetSettings => 'Standardwerte wiederherstellen';

  @override
  String get objectivesTitle => 'Strategische Ziele';

  @override
  String get openObjectives => 'Ziele öffnen';

  @override
  String get closeObjectives => 'Ziele schließen';

  @override
  String get objectivesEmpty => 'Diese Karte hat keine Ziele.';

  @override
  String get objectivesAuthoredRules =>
      'Festgelegte Kartenanforderungen. Der aktuelle Fortschritt wird von der Spielengine verwaltet.';

  @override
  String objectiveType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'ruins': 'Ruinen',
      'strategicPass': 'Strategischer Pass',
      'holySite': 'Heilige Stätte',
      'legendaryResource': 'Legendäre Ressource',
      'other': 'Strategisches Ziel',
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
    return 'Hexfeld $col, $row\nErforderliche Halterunden: $holdTurns · Siegpunkte: $victoryPoints · Gold pro Runde: $goldPerTurn';
  }

  @override
  String get matchFinishedTitle => 'Partie beendet';

  @override
  String outcomeWinner(String playerId) {
    return 'Sieger: $playerId';
  }

  @override
  String get outcomeNoWinner => 'Kein Sieger';

  @override
  String get outcomeFinalScore => 'Endstand';

  @override
  String outcomeScoreLine(String playerId, int score) {
    return '$playerId: $score';
  }

  @override
  String cityText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Stadt',
      'foundingTitle': 'Stadt gründen',
      'loading': 'Stadtdetails werden geladen',
      'owner': 'Besitzer',
      'health': 'Gesundheit',
      'population': 'Bevölkerung',
      'territory': 'Gebiet',
      'foundingSelection': 'Anfangsgebiet',
      'foundingConfirm': 'Stadtgründung bestätigen',
      'foundingCancel': 'Gründung abbrechen',
      'executing': 'Stadtaktion wird angewendet',
      'cityYield': 'Ertrag',
      'food': 'Nahrung',
      'production': 'Produktion',
      'gold': 'Gold',
      'defense': 'Verteidigung',
      'workedHexes': 'Bewirtschaftete Hexfelder',
      'workedHexSelect': 'Bewirtschaftete Hexfelder verwalten',
      'workedHexHint':
          'Wähle ein hervorgehobenes, kontrolliertes Hexfeld auf der Karte.',
      'expansion': 'Bevorzugte Erweiterung',
      'expansionSelect': 'Erweiterung wählen',
      'expansionHint':
          'Wähle ein hervorgehobenes Erweiterungsfeld auf der Karte.',
      'managementCancel': 'Kartenauswahl beenden',
      'foundingOpen': 'Stadt planen',
      'other': 'Stadt',
    });
    return '$_temp0';
  }

  @override
  String cityFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Die Stadtanfrage konnte nicht abgeschlossen werden.',
      'responseIncompatible':
          'Die Stadtantwort ist mit diesem Client nicht kompatibel.',
      'sessionUnavailable': 'Die lokale Spielsitzung ist nicht verfügbar.',
      'staleRevision':
          'Der Spielzustand hat sich geändert. Prüfe die Stadt und versuche es erneut.',
      'matchFinished': 'Die Partie ist bereits beendet.',
      'cityFounderNotFound': 'Die Gründungseinheit ist nicht mehr verfügbar.',
      'cityFounderNotControlled':
          'Dieser Spieler kontrolliert die Gründungseinheit nicht.',
      'cityFounderBusy': 'Die Gründungseinheit ist beschäftigt.',
      'cityFounderInvalid': 'Diese Einheit kann keine Stadt gründen.',
      'cityFounderNoSettlers': 'Die Gründungseinheit hat keine Siedler.',
      'citySiteInvalid':
          'An diesem Standort kann keine Stadt gegründet werden.',
      'cityCenterOccupied': 'Das Stadtzentrum ist besetzt.',
      'cityCenterClaimed': 'Das Stadtzentrum ist bereits beansprucht.',
      'cityCenterTooClose':
          'Das Stadtzentrum liegt zu nahe an einer anderen Stadt.',
      'cityControlledHexesInvalid':
          'Das ausgewählte Anfangsgebiet ist ungültig.',
      'cityNotFound': 'Diese Stadt ist nicht mehr verfügbar.',
      'cityNotControlled': 'Dieser Spieler kontrolliert diese Stadt nicht.',
      'workedHexUnavailable':
          'Dieses bewirtschaftete Hexfeld ist nicht verfügbar.',
      'workedHexLimitReached':
          'Die Stadt hat ihre Grenze für bewirtschaftete Hexfelder erreicht.',
      'cityExpansionHexUnavailable':
          'Dieses Erweiterungsfeld ist nicht verfügbar.',
      'stateRevisionOverflow':
          'Der Spielzustand kann nicht weiter fortgeschrieben werden.',
      'other': 'Die Stadtanfrage konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String workerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Arbeiter',
      'loading': 'Arbeiteroptionen werden geladen',
      'empty': 'Derzeit ist keine Arbeiteraktion verfügbar.',
      'executing': 'Arbeiteraktion wird angewendet',
      'buildCharges': 'Bauaktionen',
      'progress': 'Fortschritt',
      'assigned': 'Zugewiesenes Hexfeld',
      'openActions': 'Hexfeld verbessern',
      'closeActions': 'Auswahl abbrechen',
      'selectImprovement': 'Auswählen',
      'confirmImprovement': 'Verbesserung bestätigen',
      'cancelJob': 'Bau abbrechen',
      'assign': 'Hexfeld zuweisen',
      'cancelAssignment': 'Zuweisung aufheben',
      'buildRoad': 'Straße bauen',
      'automate': 'Automatisieren',
      'automationEvidence': 'Planungsgrundlagen',
      'other': 'Arbeiter',
    });
    return '$_temp0';
  }

  @override
  String workerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Die Arbeiteranfrage konnte nicht abgeschlossen werden.',
      'responseIncompatible':
          'Die Arbeiterantwort ist mit diesem Client nicht kompatibel.',
      'sessionUnavailable': 'Die lokale Spielsitzung ist nicht verfügbar.',
      'staleRevision':
          'Der Spielzustand hat sich geändert. Prüfe den Arbeiter und versuche es erneut.',
      'matchFinished': 'Die Partie ist bereits beendet.',
      'workerNotFound': 'Der Arbeiter ist nicht mehr verfügbar.',
      'workerNotControlled': 'Dieser Spieler kontrolliert den Arbeiter nicht.',
      'workerUnavailable': 'Der Arbeiter ist nicht verfügbar.',
      'workerNoMovementPoints': 'Der Arbeiter hat keine Bewegungspunkte.',
      'workerQueuedPathActive':
          'Der Arbeiter hat einen aktiven Bewegungsbefehl.',
      'workerImprovementNotSelected': 'Wähle zuerst eine Verbesserung.',
      'workerActionNotControlled':
          'Die ausstehende Arbeiteraktion wird nicht von diesem Spieler kontrolliert.',
      'workerImprovementUnavailable': 'Diese Verbesserung ist nicht verfügbar.',
      'workerJobNotActive': 'Der Arbeiter hat keinen laufenden Bauauftrag.',
      'workerAssignmentUnavailable':
          'Der Arbeiter kann hier nicht zugewiesen werden.',
      'workerAssignmentNotActive': 'Der Arbeiter hat keine aktive Zuweisung.',
      'workerRoadUnavailable': 'Hier kann keine Straße gebaut werden.',
      'roadConstructionExistingRoad': 'Hier existiert bereits eine Straße.',
      'roadConstructionCity':
          'Auf einem Stadtzentrum kann keine Straße gebaut werden.',
      'roadConstructionEnemyTerritory':
          'In feindlichem Gebiet kann keine Straße gebaut werden.',
      'roadConstructionImpassableTerrain':
          'Auf diesem Gelände kann keine Straße gebaut werden.',
      'workerAutomationNotActive':
          'Die Arbeiterautomatisierung ist nicht aktiv.',
      'workerAutomationNoTarget':
          'Die Arbeiterautomatisierung hat kein Ziel gefunden.',
      'stateRevisionOverflow':
          'Der Spielzustand kann nicht weiter fortgeschrieben werden.',
      'other': 'Die Arbeiteranfrage konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String productionText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Produktion und Ressourcen',
      'loading': 'Produktionsoptionen werden geladen',
      'executing': 'Stadtproduktion wird aktualisiert',
      'current': 'Aktuelle Produktion',
      'invested': 'Investiert',
      'overflow': 'Überschuss',
      'resources': 'Strategische Ressourcen',
      'buildings': 'Gebäude',
      'units': 'Einheiten',
      'projects': 'Projekte',
      'wonders': 'Wunder',
      'specializations': 'Spezialisierungen',
      'rush': 'Produktion beschleunigen',
      'cost': 'Kosten',
      'requires': 'benötigt',
      'empty': 'Derzeit ist keine Option verfügbar.',
      'other': 'Produktion',
    });
    return '$_temp0';
  }

  @override
  String productionFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed':
          'Die Produktionsanfrage konnte nicht abgeschlossen werden.',
      'responseIncompatible': 'Die Produktionsantwort ist nicht kompatibel.',
      'sessionUnavailable': 'Die lokale Spielsitzung ist nicht verfügbar.',
      'staleRevision':
          'Die Stadt hat sich geändert. Prüfe die Produktion und versuche es erneut.',
      'matchFinished': 'Die Partie ist bereits beendet.',
      'cityNotFound': 'Die Stadt ist nicht mehr verfügbar.',
      'cityNotControlled': 'Dieser Spieler kontrolliert die Stadt nicht.',
      'buildingNotAvailable': 'Dieses Gebäude ist nicht verfügbar.',
      'unitProductionInvalidResourceOption':
          'Diese Ressourcenoption ist ungültig.',
      'unitProductionNotAvailable': 'Diese Einheit ist nicht verfügbar.',
      'unitProductionRequiresResource': 'Wähle eine Ressourcenoption.',
      'unitProductionMissingStrategicResource':
          'Erforderliche Ressourcen fehlen.',
      'unitProductionRequiresCoast': 'Diese Einheit benötigt eine Küstenstadt.',
      'unitSupplyLimitReached':
          'Die Versorgungsgrenze für Einheiten ist erreicht.',
      'wonderNotAvailable': 'Dieses Wunder ist nicht verfügbar.',
      'citySpecializationLocked': 'Diese Spezialisierung ist gesperrt.',
      'citySpecializationUnchanged': 'Diese Spezialisierung ist bereits aktiv.',
      'citySpecializationMissingBuilding': 'Ein erforderliches Gebäude fehlt.',
      'productionQueueEmpty': 'Die Produktionswarteschlange ist leer.',
      'projectCannotBeRushed':
          'Ein fortlaufendes Projekt kann nicht beschleunigt werden.',
      'rushProductionUnavailable':
          'Die Produktionsbeschleunigung ist nicht verfügbar.',
      'stateRevisionOverflow':
          'Der Spielzustand kann nicht weiter fortgeschrieben werden.',
      'other': 'Die Produktionsanfrage konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String artifactText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Weltartefakte',
      'executing': 'Artefaktaktion wird angewendet',
      'startExcavation': 'Ausgrabung starten',
      'storeInCity': 'In Stadt lagern',
      'trade': 'Artefakt handeln',
      'targetPlayer': 'Zielspieler',
      'offeredGold': 'Angebotenes Gold',
      'onMap': 'Auf der Karte bei',
      'carried': 'Getragen von',
      'stored': 'Gelagert in',
      'excavation': 'Ausgrabung bei',
      'turnsRemaining': 'Runden verbleibend',
      'other': 'Artefakt',
    });
    return '$_temp0';
  }

  @override
  String artifactName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ancientImperialCrown': 'Antike Kaiserkrone',
      'astronomersTablets': 'Tafeln des Astronomen',
      'prophetMask': 'Maske des Propheten',
      'heroSword': 'Schwert des Helden',
      'merchantsSeal': 'Siegel des Händlers',
      'firstPeoplesChronicle': 'Chronik der ersten Völker',
      'templeReliquary': 'Tempelreliquiar',
      'queensMirror': 'Spiegel der Königin',
      'other': 'Weltartefakt',
    });
    return '$_temp0';
  }

  @override
  String artifactOnMap(int col, int row) {
    return 'Auf der Karte bei $col, $row';
  }

  @override
  String artifactCarriedBy(String unitName) {
    return 'Getragen von $unitName';
  }

  @override
  String artifactStoredIn(String cityName) {
    return 'Gelagert in $cityName';
  }

  @override
  String artifactExcavationAt(int col, int row, int remainingTurns) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingTurns,
      locale: localeName,
      other: '$remainingTurns Runden verbleibend',
      one: '1 Runde verbleibend',
    );
    return 'Ausgrabung bei $col, $row · $_temp0';
  }

  @override
  String artifactFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Die Artefaktanfrage konnte nicht abgeschlossen werden.',
      'responseIncompatible': 'Die Artefaktantwort ist nicht kompatibel.',
      'sessionUnavailable': 'Die lokale Spielsitzung ist nicht verfügbar.',
      'staleRevision':
          'Der Spielzustand hat sich geändert. Prüfe das Artefakt und versuche es erneut.',
      'matchFinished': 'Die Partie ist bereits beendet.',
      'unitNotFound': 'Die Einheit ist nicht mehr verfügbar.',
      'unitNotControlled': 'Dieser Spieler kontrolliert die Einheit nicht.',
      'unitUnavailable': 'Die Einheit ist nicht verfügbar.',
      'unitAlreadyCarryingArtifact': 'Die Einheit trägt bereits ein Artefakt.',
      'artifactNotFound': 'Das Artefakt ist nicht mehr verfügbar.',
      'unitNotCarryingArtifact': 'Die Einheit trägt kein Artefakt.',
      'cityNotFound': 'Die Stadt ist nicht mehr verfügbar.',
      'cityNotControlled': 'Dieser Spieler kontrolliert die Stadt nicht.',
      'unitNotInCity': 'Die Einheit befindet sich nicht in dieser Stadt.',
      'cityArtifactSlotFull': 'Der Artefaktplatz der Stadt ist belegt.',
      'artifactTradeActorUnavailable':
          'Dieser Spieler kann keine Artefakte handeln.',
      'artifactTradeTargetInvalid': 'Der Zielspieler ist ungültig.',
      'artifactTradeGoldInvalid': 'Das Goldangebot ist ungültig.',
      'artifactTradeBlockedByWar': 'Krieg verhindert den Artefakthandel.',
      'artifactTradeGoldUnavailable':
          'Das angebotene Gold ist nicht verfügbar.',
      'offeredArtifactUnavailable':
          'Das angebotene Artefakt ist nicht verfügbar.',
      'targetArtifactSlotUnavailable':
          'Der Empfänger hat keinen freien Artefaktplatz.',
      'stateRevisionOverflow':
          'Der Spielzustand kann nicht weiter fortgeschrieben werden.',
      'other': 'Die Artefaktanfrage konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String researchText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'recommendations': 'Empfehlungen',
      'title': 'Forschung',
      'open': 'Forschung öffnen',
      'close': 'Forschung schließen',
      'loading': 'Forschungsoptionen werden geladen',
      'retry': 'Erneut versuchen',
      'selecting': 'Technologie wird ausgewählt',
      'selectionRequired': 'Wähle eine Technologie, um fortzufahren',
      'sciencePerTurn': 'Wissenschaft pro Runde',
      'overflow': 'Gespeicherte Wissenschaft',
      'active': 'Aktive Technologie',
      'none': 'Keine',
      'cost': 'Kosten',
      'progress': 'Fortschritt',
      'boost': 'Kostenreduktion durch Förderung',
      'prerequisites': 'Voraussetzungen',
      'blockedBy': 'Gesperrt durch',
      'unlocks': 'Schaltet frei',
      'choose': 'Auswählen',
      'tree': 'Technologiebaum',
      'catalog': 'Forschungskatalog',
      'backToTree': 'Zurück zum Baum',
      'treeUnavailable': 'Das Abhängigkeitsdiagramm ist nicht verfügbar.',
      'other': 'Forschung',
    });
    return '$_temp0';
  }

  @override
  String researchAvailability(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unlocked': 'Erforscht',
      'active': 'Aktiv',
      'available': 'Verfügbar',
      'lockedByPrerequisites': 'Voraussetzungen erforderlich',
      'lockedByTechnology': 'Durch Technologie gesperrt',
      'other': 'Nicht verfügbar',
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
      'requestFailed':
          'Die Forschungsanfrage konnte nicht abgeschlossen werden.',
      'responseIncompatible': 'Die Forschungsantwort ist nicht kompatibel.',
      'sessionUnavailable': 'Die lokale Spielsitzung ist nicht verfügbar.',
      'staleRevision':
          'Die Forschung hat sich geändert. Prüfe die Optionen und versuche es erneut.',
      'technologyPlayerNotControlled':
          'Dieser Spieler kann keine Forschung auswählen.',
      'technologyNotAvailable': 'Diese Technologie ist nicht verfügbar.',
      'stateRevisionOverflow':
          'Der Spielzustand kann nicht weiter fortgeschrieben werden.',
      'other': 'Die Forschungsanfrage konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String diplomacyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Diplomatie',
      'open': 'Diplomatie öffnen',
      'close': 'Diplomatie schließen',
      'noContacts': 'Keine Kontakte',
      'compose': 'Neue Aktion',
      'target': 'Gegenüber',
      'action': 'Aktion',
      'send': 'Senden',
      'invalid': 'Prüfe die Bedingungen im Formular.',
      'pending': 'Diplomatische Aktion wird gesendet',
      'relations': 'Beziehungen',
      'proposals': 'Vorschläge',
      'messages': 'Private Nachrichten',
      'agreements': 'Ressourcenabkommen',
      'accept': 'Annehmen',
      'reject': 'Ablehnen',
      'amount': 'Menge',
      'goldPerTurn': 'Gold pro Runde',
      'duration': 'Runden',
      'resource': 'Ressource',
      'offered': 'Angebotene Ressource',
      'requested': 'Gewünschte Ressource',
      'topic': 'Thema',
      'other': 'Diplomatie',
    });
    return '$_temp0';
  }

  @override
  String diplomacyFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed':
          'Die Diplomatieanfrage konnte nicht abgeschlossen werden.',
      'responseIncompatible': 'Die Diplomatieantwort ist nicht kompatibel.',
      'sessionUnavailable': 'Die lokale Spielsitzung ist nicht verfügbar.',
      'staleRevision':
          'Die diplomatische Lage hat sich geändert. Prüfe den aktuellen Stand und versuche es erneut.',
      'matchFinished': 'Die Partie ist bereits beendet.',
      'diplomacyPlayerNotControlled':
          'Dieser Spieler kann keine diplomatischen Aktionen ausführen.',
      'diplomacyTargetNotDiscovered': 'Dieses Gegenüber ist nicht verfügbar.',
      'diplomacyProposalNotAllowed': 'Dieser Vorschlag ist nicht erlaubt.',
      'diplomacyDuplicateProposal': 'Dieser Vorschlag existiert bereits.',
      'diplomacyProposalNotFound': 'Dieser Vorschlag existiert nicht mehr.',
      'diplomacyProposalPaymentUnavailable':
          'Die Zahlung für den Vorschlag ist nicht verfügbar.',
      'diplomacyMessageCooldown':
          'Eine ähnliche Nachricht wurde erst vor Kurzem gesendet.',
      'diplomacyDuplicateMessage': 'Diese Nachricht existiert bereits.',
      'diplomacyMessageNotFound': 'Diese Nachricht existiert nicht mehr.',
      'diplomacyMessageUnavailable':
          'Diese Nachricht kann derzeit nicht verwendet werden.',
      'diplomacyTruceActive': 'Ein Waffenstillstand ist aktiv.',
      'diplomacyWarAlreadyActive': 'Es herrscht bereits Krieg.',
      'diplomacyInvalidGoldAmount': 'Die Goldmenge ist ungültig.',
      'diplomacyGoldGiftBlockedByRelation':
          'Diese Beziehung verhindert Goldgeschenke.',
      'diplomacyGoldUnavailable': 'Das benötigte Gold ist nicht verfügbar.',
      'diplomacyGoldGiftUnavailable':
          'Dieses Goldgeschenk ist nicht verfügbar.',
      'invalidResourceTradeTarget':
          'Der Handelspartner für den Ressourcenhandel ist ungültig.',
      'invalidResourceTradeResource': 'Die gewählte Ressource ist ungültig.',
      'invalidResourceTradeTerms':
          'Die Bedingungen des Ressourcenhandels sind ungültig.',
      'resourceTradeBlockedByWar': 'Krieg verhindert diesen Ressourcenhandel.',
      'resourceTradeGoldUnavailable':
          'Das Gold für den Handel ist nicht verfügbar.',
      'resourceTradeAlreadyActive':
          'Dieser Ressourcenhandel ist bereits aktiv.',
      'invalidResourceTradeAgreementId':
          'Die Kennung des Abkommens ist ungültig.',
      'resourceTradeAgreementIdConflict':
          'Die Kennung des Abkommens steht im Konflikt.',
      'resourceTradeExportUnavailable':
          'Der Ressourcenexport ist nicht verfügbar.',
      'resourceTradeOfferUnavailable':
          'Die angebotene Ressource ist nicht verfügbar.',
      'resourceTradeRequestUnavailable':
          'Die gewünschte Ressource ist nicht verfügbar.',
      'stateRevisionOverflow':
          'Der Spielzustand kann nicht weiter fortgeschrieben werden.',
      'other': 'Die Diplomatieanfrage konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String presentationName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'farm': 'Bauernhof',
      'riverFarm': 'Flussbauernhof',
      'mine': 'Mine',
      'lumberMill': 'Sägewerk',
      'pasture': 'Weide',
      'camp': 'Lager',
      'quarry': 'Steinbruch',
      'fishingBoats': 'Fischerboote',
      'orchard': 'Obstgarten',
      'plantation': 'Plantage',
      'vineyard': 'Weinberg',
      'tradingPost': 'Handelsposten',
      'prospectorCamp': 'Prospektorenlager',
      'horseRanch': 'Pferdezucht',
      'pearlDivers': 'Perlentaucher',
      'coalShaft': 'Kohleschacht',
      'oilWell': 'Ölquelle',
      'bauxiteMine': 'Bauxitmine',
      'uraniumMine': 'Uranmine',
      'wheat': 'Weizen',
      'fish': 'Fisch',
      'deer': 'Hirsch',
      'sheep': 'Schaf',
      'rice': 'Reis',
      'cow': 'Kuh',
      'apple': 'Apfel',
      'banana': 'Banane',
      'citrus': 'Zitrusfrüchte',
      'gold': 'Gold',
      'silver': 'Silber',
      'gems': 'Edelsteine',
      'silk': 'Seide',
      'spices': 'Gewürze',
      'cotton': 'Baumwolle',
      'grapes': 'Trauben',
      'ivory': 'Elfenbein',
      'pearls': 'Perlen',
      'coffee': 'Kaffee',
      'cocoa': 'Kakao',
      'tobacco': 'Tabak',
      'sugar': 'Zucker',
      'iron': 'Eisen',
      'coal': 'Kohle',
      'oil': 'Öl',
      'aluminium': 'Aluminium',
      'uranium': 'Uran',
      'horses': 'Pferde',
      'marble': 'Marmor',
      'commander': 'Kommandant',
      'warrior': 'Krieger',
      'archer': 'Bogenschütze',
      'settler': 'Siedler',
      'worker': 'Arbeiter',
      'merchant': 'Händler',
      'scout': 'Späher',
      'spearman': 'Speerträger',
      'cavalry': 'Kavallerie',
      'catapult': 'Katapult',
      'heavyInfantry': 'Schwere Infanterie',
      'fieldCannon': 'Feldkanone',
      'rifleman': 'Schütze',
      'tank': 'Panzer',
      'scoutShip': 'Erkundungsschiff',
      'warship': 'Kriegsschiff',
      'reconPlane': 'Aufklärungsflugzeug',
      'building': 'Gebäude',
      'improvement': 'Verbesserung',
      'resourceVisibility': 'Ressourcensichtbarkeit',
      'unit': 'Einheit',
      'wonder': 'Wunder',
      'friendly': 'Freundlich',
      'neutral': 'Neutral',
      'hostile': 'Feindselig',
      'truce': 'Waffenstillstand',
      'war': 'Krieg',
      'warning': 'Warnung',
      'complaint': 'Beschwerde',
      'request': 'Bitte',
      'praise': 'Lob',
      'threat': 'Drohung',
      'cooperation': 'Zusammenarbeit',
      'troopsNearCities': 'Truppen nahe Städten',
      'citiesTooClose': 'Städte zu nahe',
      'blockedRoutes': 'Blockierte Routen',
      'withdrawScouts': 'Späher zurückziehen',
      'avoidEscalation': 'Eskalation vermeiden',
      'commonEnemy': 'Gemeinsamer Feind',
      'expansionProvocation': 'Provokation durch Expansion',
      'peacefulPraise': 'Lob für friedliches Verhalten',
      'conciliatory': 'Versöhnlich',
      'evasive': 'Ausweichend',
      'aggressive': 'Aggressiv',
      'declareWar': 'Krieg erklären',
      'goldGift': 'Goldgeschenk',
      'friendshipProposal': 'Freundschaftsvorschlag',
      'truceProposal': 'Waffenstillstandsvorschlag',
      'message': 'Nachricht',
      'resourceTrade': 'Ressourcenhandel',
      'resourceExchange': 'Ressourcentausch',
      'granary': 'Kornspeicher',
      'workshop': 'Werkstatt',
      'industry': 'Industrie',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String technologyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'agriculture': 'Landwirtschaft',
      'woodworking': 'Holzverarbeitung',
      'mining': 'Bergbau',
      'animalHusbandry': 'Viehzucht',
      'hunting': 'Jagd',
      'fishing': 'Fischerei',
      'craftsmanship': 'Handwerk',
      'trade': 'Handel',
      'storage': 'Lagerhaltung',
      'waterEngineering': 'Wasserbau',
      'stoneworking': 'Steinbearbeitung',
      'militaryOrganization': 'Militärorganisation',
      'advancedTrade': 'Fortgeschrittener Handel',
      'construction': 'Bauwesen',
      'navigation': 'Navigation',
      'irrigation': 'Bewässerung',
      'banking': 'Bankwesen',
      'engineering': 'Ingenieurwesen',
      'metallurgy': 'Metallurgie',
      'horsebackRiding': 'Reitkunst',
      'ironWorking': 'Eisenverarbeitung',
      'coalMining': 'Kohlebergbau',
      'machinery': 'Maschinenbau',
      'administration': 'Verwaltung',
      'logistics': 'Logistik',
      'shipbuilding': 'Schiffbau',
      'tactics': 'Taktik',
      'economy': 'Wirtschaft',
      'urbanization': 'Urbanisierung',
      'fortifications': 'Befestigungen',
      'strategy': 'Strategie',
      'specialization': 'Spezialisierung',
      'writing': 'Schrift',
      'mathematics': 'Mathematik',
      'medicine': 'Medizin',
      'civilService': 'Öffentlicher Dienst',
      'siegecraft': 'Belagerungstechnik',
      'cartography': 'Kartografie',
      'guilds': 'Zünfte',
      'law': 'Recht',
      'education': 'Bildung',
      'urbanPlanning': 'Stadtplanung',
      'navalDoctrine': 'Marinedoktrin',
      'steel': 'Stahl',
      'bureaucracy': 'Bürokratie',
      'nationalism': 'Nationalismus',
      'scientificMethod': 'Wissenschaftliche Methode',
      'steamPower': 'Dampfkraft',
      'electricity': 'Elektrizität',
      'combustion': 'Verbrennung',
      'flight': 'Luftfahrt',
      'massProduction': 'Massenproduktion',
      'radio': 'Funk',
      'nuclearPhysics': 'Kernphysik',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String cityContentName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'growth': 'Wachstum',
      'industry': 'Industrie',
      'commerce': 'Handel',
      'science': 'Wissenschaft',
      'military': 'Militär',
      'wealth': 'Wohlstand',
      'research': 'Forschung',
      'granary': 'Kornspeicher',
      'waterMill': 'Wassermühle',
      'workshop': 'Werkstatt',
      'storehouse': 'Lagerhaus',
      'housing': 'Wohnhäuser',
      'merchantHall': 'Handelshalle',
      'stonemason': 'Steinmetz',
      'barracks': 'Kaserne',
      'marketplace': 'Marktplatz',
      'port': 'Hafen',
      'aqueduct': 'Aquädukt',
      'forge': 'Schmiede',
      'stable': 'Stall',
      'bank': 'Bank',
      'buildersGuild': 'Bauzunft',
      'factory': 'Fabrik',
      'lighthouse': 'Leuchtturm',
      'trainingGrounds': 'Übungsplatz',
      'townHall': 'Rathaus',
      'monument': 'Monument',
      'archive': 'Archiv',
      'academy': 'Akademie',
      'university': 'Universität',
      'observatory': 'Observatorium',
      'laboratory': 'Labor',
      'reactor': 'Reaktor',
      'courthouse': 'Gerichtsgebäude',
      'court': 'Hof',
      'governorsOffice': 'Statthalteramt',
      'surveyorsOffice': 'Vermessungsamt',
      'planningOffice': 'Planungsamt',
      'apothecary': 'Apotheke',
      'publicBaths': 'Öffentliche Bäder',
      'hospital': 'Krankenhaus',
      'ministries': 'Ministerien',
      'walls': 'Stadtmauern',
      'armory': 'Waffenkammer',
      'siegeWorkshop': 'Belagerungswerkstatt',
      'citadel': 'Zitadelle',
      'warCollege': 'Kriegsakademie',
      'conscriptionOffice': 'Wehramt',
      'borderFort': 'Grenzfort',
      'airfield': 'Flugplatz',
      'artisansGuild': 'Handwerkszunft',
      'masterWorkshop': 'Meisterwerkstatt',
      'steelworks': 'Stahlwerk',
      'railDepot': 'Bahndepot',
      'powerPlant': 'Kraftwerk',
      'assemblyPlant': 'Montagewerk',
      'refinery': 'Raffinerie',
      'mapRoom': 'Kartensaal',
      'shipyard': 'Werft',
      'dryDock': 'Trockendock',
      'navalAcademy': 'Marineakademie',
      'harborCustoms': 'Hafenzollamt',
      'museum': 'Museum',
      'parliament': 'Parlament',
      'broadcastTower': 'Sendeturm',
      'worldFairGrounds': 'Weltausstellungsgelände',
      'greatLibrary': 'Große Bibliothek',
      'hangingGardens': 'Hängende Gärten',
      'greatWall': 'Große Mauer',
      'petra': 'Petra',
      'centralBank': 'Zentralbank',
      'imperialUniversity': 'Kaiserliche Universität',
      'grandCathedral': 'Große Kathedrale',
      'motherFactory': 'Stammfabrik',
      'nationalObservatory': 'Nationales Observatorium',
      'svalbardSeedVault': 'Saatguttresor auf Spitzbergen',
      'grandExposition': 'Große Ausstellung',
      'other': 'Unbekannter Stadtinhalt',
    });
    return '$_temp0';
  }

  @override
  String diplomaticProposalName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'friendship': 'Freundschaft',
      'truce': 'Waffenstillstand',
      'other': 'Unbekannter Vorschlag',
    });
    return '$_temp0';
  }

  @override
  String mapFeedbackText(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'roadCompleted': '+Straße',
      'unitKilled': 'KO',
      'unitRetreated': 'Rückzug',
      'artifactExcavationStarted': 'Ausgrabung',
      'artifactCarried': 'Artefakt aufgenommen',
      'artifactStored': 'Artefakt eingelagert',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String mapYieldShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'food': 'NAHR',
      'production': 'PROD',
      'gold': 'GOLD',
      'defense': 'VERT',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get focusOwnUnitMovement =>
      'Kamera auf Bewegungen meiner Einheiten richten';

  @override
  String get followOwnUnitMovement =>
      'Bewegungen meiner Einheiten mit der Kamera verfolgen';

  @override
  String get focusForeignUnitMovement =>
      'Kamera auf Bewegungen feindlicher Einheiten richten';

  @override
  String get followForeignUnitMovement =>
      'Bewegungen feindlicher Einheiten mit der Kamera verfolgen';

  @override
  String get gameSoundsLabel => 'Spielgeräusche';

  @override
  String get soundVolumeLabel => 'Geräuschlautstärke';

  @override
  String get gameMusicLabel => 'Spielmusik';

  @override
  String get musicVolumeLabel => 'Musiklautstärke';

  @override
  String get natureSoundsLabel => 'Naturgeräusche';

  @override
  String get natureVolumeLabel => 'Lautstärke der Naturgeräusche';

  @override
  String hexInspectionKind(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite': 'Idealer Stadtstandort',
      'goodCitySite': 'Guter Stadtstandort',
      'fertileField': 'Fruchtbares Feld',
      'fertilePlains': 'Fruchtbare Ebenen',
      'richPlain': 'Ertragreiche Ebene',
      'strategicBorderland': 'Strategisches Grenzland',
      'strategicField': 'Strategisches Feld',
      'defensivePosition': 'Verteidigungsstellung',
      'fertileForest': 'Fruchtbarer Wald',
      'forestBackline': 'Bewaldetes Hinterland',
      'forestForge': 'Industriewald',
      'wildLand': 'Wildnis',
      'richWilds': 'Ertragreiche Wildnis',
      'exoticBackline': 'Exotisches Hinterland',
      'difficultStrategicTerrain': 'Schwieriges strategisches Gelände',
      'highGround': 'Anhöhe',
      'riverHills': 'Flusshügel',
      'industrialStronghold': 'Industriestützpunkt',
      'richHills': 'Ertragreiche Hügel',
      'barrenLand': 'Ödland',
      'oasis': 'Oase',
      'tradeOasis': 'Handelsoase',
      'desertDeposits': 'Wüstenvorkommen',
      'harshLand': 'Raues Land',
      'coldPastures': 'Kalte Weiden',
      'resourceOutpost': 'Ressourcenaußenposten',
      'hostileLand': 'Unwirtliches Land',
      'arcticDeposits': 'Arktische Vorkommen',
      'coast': 'Küste',
      'fishingCoast': 'Fischreiche Küste',
      'richCoast': 'Ertragreiche Küste',
      'riverPort': 'Flusshafen',
      'regionalPortHeart': 'Regionales Hafenzentrum',
      'openSea': 'Offenes Meer',
      'naturalBarrier': 'Natürliche Barriere',
      'promisingLand': 'Vielversprechendes Land',
      'weakLand': 'Ertragsarmes Land',
      'ordinaryLand': 'Gewöhnliches Land',
      'mapTile': 'Kartenfeld',
      'other': 'Kartenfeld',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionDescription(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite':
          'Ein wertvoller Siedlungsstandort, der Nahrung, Wachstum und Expansionspotenzial vereint.',
      'goodCitySite':
          'Solides Gelände für ein Stadtzentrum mit genügend Grundwert für frühes Wachstum.',
      'fertileField':
          'Flussversorgtes Grasland, das Nahrung, Bevölkerungswachstum und Arbeiterverbesserungen begünstigt.',
      'fertilePlains':
          'Offene Ebenen an einem Fluss, geeignet für ein Gleichgewicht aus Nahrung und Produktion.',
      'richPlain':
          'Ein wertvolles offenes Feld mit Luxusressourcen oder Handelswert, das sich innerhalb der Grenzen lohnt.',
      'strategicBorderland':
          'Gutes Land mit strategischem Wert, das du vor deinen Rivalen beanspruchen solltest.',
      'strategicField':
          'Ein Ebenenfeld mit strategischen Ressourcen oder Einfluss auf die Grenzlage.',
      'defensivePosition':
          'Gelände, das die Verteidigung stärkt und hilft, benachbarte Zugänge zu halten.',
      'fertileForest':
          'Ein Wald an einem Fluss, der Wachstumspotenzial mit natürlicher Deckung verbindet.',
      'forestBackline':
          'Ein sichereres Waldfeld, das Wachstum oder jagdbezogene Verbesserungen unterstützen kann.',
      'forestForge':
          'Ein Wald mit industriellen Ressourcen, der nach der Verbesserung gute Produktion verspricht.',
      'wildLand':
          'Dichtes, schwieriges Gelände, das nur mit einem klaren Arbeiter- oder Expansionsplan sinnvoll ist.',
      'richWilds':
          'Wildes Gelände mit genügend Fruchtbarkeit oder Ressourcen für eine überlegte Erschließung.',
      'exoticBackline':
          'Ein Dschungel- oder Feuchtgebietsfeld mit Luxusressourcen für spätere Expansion und Handel.',
      'difficultStrategicTerrain':
          'Schwieriges Gelände mit strategischen Ressourcen, später mächtig, anfangs umständlich.',
      'highGround':
          'Hügel, die Verteidigung und Kartenkontrolle stärker begünstigen als schnelles Wachstum.',
      'riverHills':
          'Hügel neben einem Fluss, die Verteidigung mit besserem wirtschaftlichem Potenzial verbinden.',
      'industrialStronghold':
          'Hügel mit industriellen Ressourcen, ein starkes Produktionsziel für eine Stadt.',
      'richHills':
          'Hügel mit wertvollen Ressourcen, geeignet für eine auf Gold oder Produktion ausgerichtete Expansion.',
      'barrenLand':
          'Trockenes Land mit geringem unmittelbarem Nutzen, sofern spätere Technologien oder Grenzen den Plan nicht ändern.',
      'oasis':
          'Wüste mit Flusszugang, der schwaches Land zu einem nutzbaren Wachstumsfeld macht.',
      'tradeOasis':
          'Ein Handelsstandort in der Wüste, der mit der richtigen Verbesserung wertvoll werden kann.',
      'desertDeposits':
          'Schlechter Siedlungsboden mit einem strategischen Vorkommen, das in späteren Epochen wichtiger wird.',
      'harshLand':
          'Kaltes oder raues Land mit begrenzter früher Wirtschaft und langsamer Entwicklung.',
      'coldPastures':
          'Kaltes Gelände mit genügend Weidewert, um eine Grenzstadt zu unterstützen.',
      'resourceOutpost':
          'Entlegenes kaltes Land, das sich vor allem wegen seiner geschützten Ressource lohnt.',
      'hostileLand':
          'Unwirtlicher Boden mit geringem Siedlungswert und wenigen unmittelbaren Erträgen.',
      'arcticDeposits':
          'Schneebedecktes Ressourcenland, das schwer nutzbar ist, aber strategisch wichtig werden kann.',
      'coast':
          'Küstenland, das Zugang zur See und vielseitiges Stadtwachstum ermöglicht.',
      'fishingCoast':
          'Eine nahrungsreiche Küste, ein guter Grund, am Wasser zu wirtschaften oder zu siedeln.',
      'richCoast':
          'Luxusressourcen oder Handelswert an der Küste, die sich innerhalb der Stadtgrenzen lohnen.',
      'riverPort':
          'Eine Flussmündung mit Handels- und Bewegungsvorteilen für eine Küstenstadt.',
      'regionalPortHeart':
          'Ein starkes Küstenzentrum, in dem Fluss- und Ressourcenwert zusammenkommen.',
      'openSea':
          'Wasser, das für Schiffe und Erkundung nützlich ist, aber nicht für Landsiedlungen.',
      'naturalBarrier':
          'Unpassierbares Gelände, das Bewegung und Verteidigung statt Wirtschaft prägt.',
      'promisingLand':
          'Ein allgemein nützliches Feld, das eine Untersuchung vor dem Weiterziehen verdient.',
      'weakLand':
          'Ertragsarmes Gelände, das frühe Arbeiterzeit selten rechtfertigt.',
      'ordinaryLand':
          'Ein gewöhnliches Feld ohne besondere Stärke, das nützlich ist, wenn es zum Stadtplan passt.',
      'mapTile':
          'Ein einfaches Kartenfeld, zu dem nicht genügend Informationen für eine klare Einschätzung vorliegen.',
      'other':
          'Ein einfaches Kartenfeld, zu dem nicht genügend Informationen für eine klare Einschätzung vorliegen.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendation(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity': 'Guter Entwicklungsstandort',
      'defendHere': 'Gute Verteidigungsstellung',
      'exploitEconomy': 'Erschließung lohnt sich',
      'avoid': 'Ohne Plan meiden',
      'neutral': 'Vor der Bewegung untersuchen',
      'other': 'Vor der Bewegung untersuchen',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendationDetail(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity':
          'Wenn die Grenzen frei sind, erwäge hier eine Stadt zu gründen oder einen Siedler hierher zu schicken.',
      'defendHere':
          'Nutze die Stellung für Einheiten, zum Grenzschutz oder zur Deckung benachbarter Städte.',
      'exploitEconomy':
          'Nimm das Feld in deine Grenzen auf und weise einen Arbeiter zu, sobald die Stadt davon profitieren kann.',
      'avoid':
          'Meide es anfangs, sofern nicht eine Ressource, Route oder militärische Notwendigkeit seinen Wert verändert.',
      'neutral':
          'Erkunde benachbarte Felder und vergleiche Ressourcen, bevor du einen Arbeiter oder Siedler einsetzt.',
      'other':
          'Erkunde benachbarte Felder und vergleiche Ressourcen, bevor du einen Arbeiter oder Siedler einsetzt.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Hexfeld untersuchen',
      'close': 'Untersuchung schließen',
      'loading': 'Hexfeld wird untersucht…',
      'requestFailed':
          'Das Hexfeld konnte nicht untersucht werden. Versuche es erneut.',
      'responseIncompatible':
          'Die Antwort auf die Hexfelduntersuchung ist nicht kompatibel.',
      'sessionUnavailable': 'Die Spielsitzung ist nicht verfügbar.',
      'description': 'Beschreibung',
      'terrain': 'Gelände',
      'resources': 'Ressourcen',
      'none': 'Keine',
      'height': 'Höhe',
      'improvements': 'Mögliche Verbesserungen',
      'noImprovements': 'Keine passenden Verbesserungen.',
      'fromStart': 'Von Anfang an verfügbar',
      'unlocked': 'Technologie freigeschaltet',
      'locked': 'Technologie erforderlich',
      'riverBonus': 'Flussbonus',
      'defenseBonus': 'Verteidigungsgelände',
      'outsideCity': 'Außerhalb kontrollierter Stadtgrenzen',
      'cityCenter': 'Stadtzentrum',
      'alreadyImproved': 'Dieses Hexfeld ist bereits verbessert',
      'objective': 'Kartenziel',
      'other': 'Hexfeld untersuchen',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionCity(String city) {
    return 'Wird von $city bewirtschaftet';
  }

  @override
  String hexInspectionBuildTurns(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns Runden',
      one: '1 Runde',
    );
    return 'Bauzeit: $_temp0';
  }

  @override
  String hexInspectionTerrain(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'ocean': 'Ozean',
      'coast': 'Küste',
      'lake': 'See',
      'plains': 'Ebene',
      'grassland': 'Grasland',
      'desert': 'Wüste',
      'tundra': 'Tundra',
      'snow': 'Schnee',
      'mountain': 'Gebirge',
      'hills': 'Hügel',
      'wetlands': 'Feuchtgebiet',
      'jungle': 'Dschungel',
      'forest': 'Wald',
      'river': 'Fluss',
      'other': 'Ebene',
    });
    return '$_temp0';
  }

  @override
  String get gamepadSettings => 'Gamepad';

  @override
  String get gamepadEnabled => 'Gamepad-Eingabe';

  @override
  String get gamepadDeadzone => 'Gamepad-Totzone';

  @override
  String get gamepadCameraSensitivity => 'Kameraempfindlichkeit des Gamepads';

  @override
  String get gamepadInvertCameraY => 'Y-Achse der Gamepad-Kamera umkehren';

  @override
  String get gamepadButtonBindings => 'Tastenbelegung';

  @override
  String get gamepadAxisBindings => 'Achsenbelegung';

  @override
  String get gamepadResetBindings => 'Belegung zurücksetzen';

  @override
  String get gamepadUnassigned => 'Nicht belegt';

  @override
  String gamepadAssignedTo(String action) {
    return 'Belegt mit: $action';
  }

  @override
  String get gamepadActionConfirm => 'Bestätigen';

  @override
  String get gamepadActionCancel => 'Abbrechen';

  @override
  String get gamepadActionMoveMode => 'Bewegungsmodus';

  @override
  String get gamepadActionInspect => 'Hexfeld untersuchen';

  @override
  String get gamepadActionHudPrevious => 'Vorheriger Oberflächenbereich';

  @override
  String get gamepadActionHudNext => 'Nächster Oberflächenbereich';

  @override
  String get gamepadActionPrevious => 'Vorherige offene Aktion';

  @override
  String get gamepadActionNext => 'Nächste offene Aktion';

  @override
  String get gamepadActionPrimary => 'Hauptaktion';

  @override
  String get gamepadActionUp => 'Steuerkreuz oben';

  @override
  String get gamepadActionDown => 'Steuerkreuz unten';

  @override
  String get gamepadActionLeft => 'Steuerkreuz links';

  @override
  String get gamepadActionRight => 'Steuerkreuz rechts';

  @override
  String get gamepadActionZoomIn => 'Vergrößern';

  @override
  String get gamepadActionZoomOut => 'Verkleinern';

  @override
  String get gamepadActionCursorX => 'Cursor X';

  @override
  String get gamepadActionCursorY => 'Cursor Y';

  @override
  String get gamepadActionCameraX => 'Kamera X';

  @override
  String get gamepadActionCameraY => 'Kamera Y';

  @override
  String get gamepadControlHome => 'Home';

  @override
  String get gamepadControlTouchpad => 'Touchpad';

  @override
  String get gamepadControlLeftStickX => 'Linker Stick X';

  @override
  String get gamepadControlLeftStickY => 'Linker Stick Y';

  @override
  String get gamepadControlRightStickX => 'Rechter Stick X';

  @override
  String get gamepadControlRightStickY => 'Rechter Stick Y';

  @override
  String get gamepadControlLeftTrigger => 'Linker Trigger (LT)';

  @override
  String get gamepadControlRightTrigger => 'Rechter Trigger (RT)';

  @override
  String get keyboardSettings => 'Tastatur';

  @override
  String get keyboardScope =>
      'Kartenkürzel funktionieren, wenn die Karte den Tastaturfokus hat. Klicke auf die Karte, um ihr den Fokus zurückzugeben.';

  @override
  String get keyboardPanKeys => 'W / A / S / D oder Pfeiltasten';

  @override
  String get keyboardPan => 'Kamera verschieben';

  @override
  String get keyboardSelect =>
      'Hexfeld unter dem Mauszeiger oder die aktuelle Auswahl auswählen';

  @override
  String get keyboardMove =>
      'Zielauswahl für die Bewegung der ausgewählten Einheit umschalten';

  @override
  String get keyboardInspect =>
      'Hexfeld unter dem Mauszeiger, ausgewähltes Hexfeld oder die Mitte der Ansicht untersuchen';

  @override
  String get keyboardMapMode =>
      'Zwischen grafischer Ansicht und Kachelansicht wechseln';

  @override
  String get keyboardPending => 'Vorherige / nächste offene Rundenaktion';

  @override
  String get keyboardSpace => 'Leertaste';

  @override
  String get keyboardPrimary =>
      'Zur nächsten offenen Aktion wechseln; die Runde beenden, wenn keine mehr offen ist';

  @override
  String get keyboardCancel =>
      'Aktiven Bereich schließen oder die aktuelle Interaktion abbrechen';

  @override
  String get keyboardFocus => 'Nächstes / vorheriges Bedienelement fokussieren';

  @override
  String get textSize => 'Textgröße';

  @override
  String get textSizeDescription =>
      'Wird zusätzlich zur Textgröße des Systems angewendet.';

  @override
  String get textScaleStandard => 'Standard (100%)';

  @override
  String get textScaleLarge => 'Groß (115%)';

  @override
  String get textScaleExtraLarge => 'Sehr groß (130%)';

  @override
  String get languageSettings => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get windowSettingsTitle => 'Fenster';

  @override
  String get windowModeFullscreen => 'Vollbild';

  @override
  String get windowModeWindowed => 'Im Fenster';

  @override
  String get windowSettingsBusy => 'Fenstermodus wird geändert…';

  @override
  String windowSettingsFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'load':
          'Die Fenstereinstellungen konnten nicht geladen werden. Der Standardmodus wurde angefordert.',
      'apply':
          'Der Fenstermodus konnte nicht geändert werden. Wähle erneut einen Modus.',
      'save':
          'Die Fenstereinstellung konnte nicht gespeichert werden. Wähle erneut einen Modus.',
      'restore':
          'Der vorherige Fenstermodus konnte nicht wiederhergestellt werden. Wähle erneut einen Modus.',
      'other': 'Der Fenstervorgang konnte nicht abgeschlossen werden.',
    });
    return '$_temp0';
  }

  @override
  String get automationSettings => 'Automatisierung';

  @override
  String get advanceActions => 'Zur nächsten Aktion wechseln';

  @override
  String get advanceActionsDescription =>
      'Nach einer Aktion die nächste Einheit, Stadt oder Forschung auswählen, die deine Aufmerksamkeit benötigt.';

  @override
  String get automaticEndTurn => 'Züge automatisch beenden';

  @override
  String get automaticEndTurnDescription =>
      'Deinen Zug beenden, wenn keine Aktionen mehr ausstehen. Manuelle Entscheidungen und geöffnete Fenster pausieren die Automatisierung.';

  @override
  String get performanceSettings => 'Leistung';

  @override
  String get showFps => 'FPS anzeigen';

  @override
  String get showFpsDescription => 'Die Bildrate in der gesamten App anzeigen.';

  @override
  String get showMapZoom => 'Kartenzoom anzeigen';

  @override
  String get showMapZoomDescription =>
      'Den aktuellen Zoom bei geöffneter Karte anzeigen.';

  @override
  String get aiSettings => 'KI';

  @override
  String get aiBatterySaver => 'KI-Akkusparmodus';

  @override
  String get aiBatterySaverDescription =>
      'Reduziert die taktische Suche während lokaler KI-Züge.';

  @override
  String get mapAppearanceSettings => 'Kartendarstellung';

  @override
  String get mapMarkingsSettings => 'Kartenmarkierungen';

  @override
  String get preferredMapViewMode => 'Standard-Kartenansicht';

  @override
  String get preferredMapViewModeDescription =>
      'Wird beim Öffnen eines Spiels oder einer Wiederholung verwendet.';

  @override
  String get mapCitySites => 'Stadtstandorte';

  @override
  String get mapCitySitesDescription =>
      'Mögliche Stadtstandorte auf erkundetem Gelände anzeigen.';

  @override
  String get mapCityGrowth => 'Stadtwachstum';

  @override
  String get mapCityGrowthDescription =>
      'Erkundete Felder außerhalb bekannter Stadtgebiete anzeigen.';

  @override
  String resourceText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'gold': 'Gold',
      'science': 'Wissenschaft',
      'stability': 'Stabilität',
      'resources': 'Ressourcen',
      'victory': 'Sieg',
      'turn': 'Runde',
      'close': 'Details schließen',
      'treasury': 'Staatskasse',
      'income': 'Einkommen',
      'cityIncome': 'Stadteinkommen',
      'projectIncome': 'Projekteinkommen',
      'upkeep': 'Einheitenunterhalt',
      'netPerTurn': 'Pro Runde',
      'freeUnits': 'Kostenlose Einheiten',
      'paidUnits': 'Unterhaltspflichtige Einheiten',
      'nextWorker': 'Unterhalt des nächsten Arbeiters',
      'activeResearch': 'Aktive Forschung',
      'overflow': 'Gespeicherte Wissenschaft',
      'sources': 'Quellen',
      'baseOrder': 'Grundordnung',
      'buildings': 'Gebäude',
      'luxuries': 'Luxusgüter',
      'technologies': 'Technologien',
      'artifacts': 'Artefakte',
      'wonders': 'Wunder',
      'cities': 'Städte',
      'population': 'Bevölkerung',
      'cohesion': 'Zusammenhalt',
      'conqueredCities': 'Eroberte Städte',
      'warWeariness': 'Kriegsmüdigkeit',
      'hegemony': 'Hegemoniesteuer',
      'relativeStanding': 'Relative Stellung',
      'totalSources': 'Quellen gesamt',
      'totalCosts': 'Kosten gesamt',
      'stockpile': 'Vorrat',
      'output': 'Ertrag pro Runde',
      'empty': 'Keine Quellen',
      'score': 'Punktzahl',
      'conquest': 'Eroberung',
      'domination': 'Vorherrschaft',
      'culture': 'Kultur',
      'holdTurns': 'Gehaltene Runden',
      'remainingTurns': 'Verbleibende Runden',
      'turnLimit': 'Rundenlimit',
      'submitted': 'Bestätigt',
      'required': 'Erforderliche Bestätigungen',
      'content': 'Zufrieden',
      'stable': 'Stabil',
      'strained': 'Angespannt',
      'unrest': 'Unruhen',
      'other': 'Ressourcen',
    });
    return '$_temp0';
  }

  @override
  String get automaticSave => 'Automatischer Spielstand';

  @override
  String playerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Spieler',
      'active': 'Aktiv',
      'finished': 'Zug beendet',
      'submitted': 'Bestätigt',
      'waiting': 'Warten',
      'ended': 'Partie beendet',
      'privateStatus': 'Zugstatus ist privat',
      'noContact': 'Kein diplomatischer Kontakt',
      'other': 'Spieler',
    });
    return '$_temp0';
  }

  @override
  String historyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Abgeschlossene Online-Partien',
      'loading': 'Spielverlauf wird geladen',
      'empty': 'Noch keine abgeschlossenen Partien.',
      'failed':
          'Der Spielverlauf konnte nicht geladen werden. Bitte aktualisieren.',
      'refresh': 'Aktualisieren',
      'previous': 'Vorherige Seite',
      'next': 'Nächste Seite',
      'turn': 'Letzte Runde',
      'won': 'Du hast gewonnen',
      'lost': 'Du hast verloren',
      'resigned': 'Du hast aufgegeben',
      'removed': 'Du wurdest aus der Partie entfernt',
      'other': 'Abgeschlossene Online-Partien',
    });
    return '$_temp0';
  }

  @override
  String profileText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Dein Profil',
      'description':
          'Beim Ändern des Anzeigenamens bleiben dein Konto und deine Mehrspielerpartien erhalten.',
      'save': 'Namen speichern',
      'saved': 'Anzeigename gespeichert.',
      'taken': 'Dieser Anzeigename ist bereits vergeben.',
      'changed': 'Das Konto hat sich geändert. Lade das Profil erneut.',
      'other': 'Dein Profil',
    });
    return '$_temp0';
  }

  @override
  String get researchDiscoveryTitle => 'Forschung abgeschlossen';

  @override
  String get showResearchDiscoveries => 'Technologische Entdeckungen anzeigen';

  @override
  String get researchDiscoverySuppress => 'Nicht mehr anzeigen';

  @override
  String get researchDiscoveryMinimize => 'Minimieren';

  @override
  String get researchDiscoveryRestore => 'Entdeckung wieder anzeigen';

  @override
  String get researchDiscoveryContinue => 'Weiter';

  @override
  String researchRecommendationRank(int rank) {
    return 'Empfehlung $rank';
  }

  @override
  String researchRecommendationTurns(int turns) {
    return 'Geschätzte Runden: $turns';
  }

  @override
  String researchRecommendationReason(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'boost': 'Forschungsbonus',
      'workerYields': 'Arbeitererträge',
      'unlocks': 'Neue Freischaltungen',
      'effects': 'Technologieeffekte',
      'nearCompletion': 'Bald abgeschlossen',
      'other': 'Empfehlungen',
    });
    return '$_temp0';
  }

  @override
  String technologyDescription(String technology) {
    String _temp0 = intl.Intl.selectLogic(technology, {
      'agriculture':
          'Öffnet den grundlegenden Wachstumspfad. Bauernhöfe und Flussbauernhöfe lassen die Bevölkerung schneller wachsen und stabilisieren die erste Stadt.',
      'woodworking':
          'Entwickelt die Produktionsseite des Bergbaus. Sägewerke verwandeln Wälder in Produktion, ohne tief in die Metallurgie einzusteigen.',
      'mining':
          'Öffnet den Pfad von Industrie und Infrastruktur. Minen sind der erste große Sprung in der Stadtproduktion.',
      'animalHusbandry':
          'Stärkt Wachstum durch Tierressourcen. Weiden bauen eine Nahrungswirtschaft auf und bereiten den Weg zur Reitkunst.',
      'hunting':
          'Öffnet den Militär- und Erkundungszweig. Bietet Lager und die erste Fernkampfeinheit für Stadtproduktion.',
      'fishing':
          'Entwickelt Städte am Wasser. Fischerboote helfen Küstenstädten, schneller zu wachsen, und bereiten den Weg zum Hafen.',
      'craftsmanship':
          'Die erste Aufwertung der Stadtproduktion. Die Werkstatt verhindert, dass spätere Gebäude und Einheiten die Warteschlange zu lange blockieren.',
      'trade':
          'Der erste Schritt in der Goldwirtschaft. Die Kaufmannshalle gibt einer Stadt nach der Wahl eines Wachstumspfads einen einfachen finanziellen Nutzen.',
      'storage':
          'Stabilisiert Stadtwachstum. Lagerung hilft, das Nahrungstempo zu halten und das Risiko von Entwicklungsstillständen zu senken.',
      'waterEngineering':
          'Erweitert den wasserbasierten Wachstumspfad. Die Wassermühle belohnt Städte, die Flüsse kontrollieren.',
      'stoneworking':
          'Verbindet Produktion und Verteidigung. Steinbrüche und der Steinmetz stärken Städte im Infrastrukturzweig.',
      'militaryOrganization':
          'Baut den ersten militärischen Kern einer Stadt auf. Kasernen stärken Produktion und Verteidigung, bevor spätere Armeeboni erscheinen.',
      'advancedTrade':
          'Entwickelt die Wirtschaft nach dem Handel. Der Marktplatz ist ein stärkeres Goldgebäude und bereitet den Weg zum Bankwesen.',
      'construction':
          'Erweitert Gebiet und Stadtreife. Wohnraum erhöht die Feldkontrolle und führt zu Verwaltung und Ingenieurwesen.',
      'navigation':
          'Öffnet einen Stadtnutzen für die Küste. Der Hafen erfordert Küsten-/Ozeanzugang und belohnt Uferstädte mit Nahrung und Gold.',
      'irrigation':
          'Spezialisiert wasserbasiertes Wachstum. Das Aquädukt gewährt einen starken Nahrungsbonus und zusätzliche territoriale Kontrolle.',
      'banking':
          'Spezialisiert den Handelszweig. Die Bank macht frühere Märkte zu starkem Stadteinkommen und schaltet die breitere Wirtschaft frei.',
      'engineering':
          'Spezialisierung im Bauwesen. Die Baumeistergilde beschleunigt Produktion und erhöht das Limit kontrollierter Felder.',
      'metallurgy':
          'Ein starker industrieller Ertrag nach Steinbearbeitung. Die Schmiede erhöht Produktion und bereitet den Weg zu Eisen und Kohle.',
      'horsebackRiding':
          'Eine Technologie, die Wachstum und Krieg verbindet. Der Stall unterstützt Städte, die zuvor in Tiere und Jagd investiert haben.',
      'ironWorking':
          'Ein Effekt industrieller Ressourcen. Jede kontrollierte Eisenressource erhöht die Stadtproduktion.',
      'coalMining':
          'Ein späterer Effekt industrieller Ressourcen. Kontrollierte Kohle erhöht die Stadtproduktion und unterstützt den Fabrikpfad.',
      'machinery':
          'Ein später Infrastrukturertrag. Die Fabrik gibt Städten, die Ingenieurwesen erreicht haben, einen großen Produktionszuwachs.',
      'administration':
          'Verbindet Infrastruktur mit Wirtschaft. Rathäuser und Monumente stärken reife Städte und führen zur Urbanisierung.',
      'logistics':
          'Beschleunigt Einheitsproduktion. Dies ist die Haupttechnologie für Spieler, die häufiger Armeen aus Städten aufstellen wollen.',
      'shipbuilding':
          'Entwickelt den Küsten-/Erkundungsunterzweig. Der Leuchtturm benötigt Küstenzugang und stärkt Uferstädte.',
      'tactics':
          'Militärische Stadtspezialisierung. Übungsplätze fügen Verteidigung und Produktion für Militärzentren hinzu.',
      'economy':
          'Ein systemischer Ertrag für Bankwesen. Erhöht das von Stadtwirtschaften erzeugte Gold.',
      'urbanization':
          'Die finale Richtung für Großstadtwachstum. Erhöht das Bevölkerungslimit, sobald das Bevölkerungssystem harte Grenzen nutzt.',
      'fortifications':
          'Stärkt die Stadtverteidigung. Gewährt der Stadtwirtschaft einen Verteidigungsbonus, dessen volle Bedeutung mit Kampf- und Belagerungserweiterung wächst.',
      'strategy':
          'Die finale militärische Richtung. Stärkt die Armeewirksamkeit als später Ertrag nach Logistik.',
      'specialization':
          'Der finale zivile/wirtschaftliche Ertrag. Schaltet Stadtspezialisierungen frei, fügt Stadtwissenschaft hinzu und hilft, späte Technologien in längeren Partien abzuschließen.',
      'writing':
          'Der erste Schritt zu Wissenschaft, Recht und Verwaltung. Das Archiv gibt einer Stadt eine dauerhafte Forschungsbasis.',
      'mathematics':
          'Verbindet Wissenschaft mit Gebietsplanung. Das Vermessungsbüro hilft Städten, Grenzen wirksamer zu kontrollieren.',
      'medicine':
          'Entwickelt Gesundheit und langfristiges Wachstum in großen Städten durch Apotheken, Bäder und Krankenhäuser.',
      'civilService':
          'Verbessert die Verwaltung eines großen Imperiums und schaltet Gerichte frei, die Städte stabilisieren.',
      'siegecraft':
          'Öffnet die Belagerungskriegsführung. Katapulte und Belagerungswerkstätten brechen Festungsstädte.',
      'cartography':
          'Entwickelt Erkundung, Karten und die Küste. Gewährt den Kartenraum und die ersten Spähschiffe.',
      'guilds':
          'Gibt Produktionsstädten eine Stufe zwischen Werkstatt und Industrie.',
      'law': 'Führt Ordnung, Politik und zivile Verwaltung durch Gerichte ein.',
      'education':
          'Baut den vollständigen Wissenschaftspfad für Städte über Akademien und Universitäten auf.',
      'urbanPlanning':
          'Entwickelt große Städte und territoriale Kontrolle durch räumliche Planung.',
      'navalDoctrine':
          'Macht Häfen zu Zentren für Flotten, Werften und Machtprojektion auf See.',
      'steel':
          'Führt Schwerindustrie und schwere Infanterie für die spätere Front ein.',
      'bureaucracy':
          'Bietet nach Verwaltung ein großes ziviles Ziel: Büros, Ministerien, Museen und Parlament.',
      'nationalism':
          'Kombiniert Grenzverteidigung, Mobilisierung und Imperiumsidentität.',
      'scientificMethod':
          'Bereitet späte Wissenschaft, Labore, Observatorien und Technologieprojekte vor.',
      'steamPower': 'Öffnet Bahn, schwerere Logistik und Dampfindustrie.',
      'electricity':
          'Führt Strom, Infrastruktur und Informationsreichweite ein.',
      'combustion':
          'Gibt Öl Bedeutung und schaltet moderne Fronteinheiten frei.',
      'flight':
          'Führt Luftfahrt, Aufklärung und Machtprojektion über die Front ein.',
      'massProduction':
          'Entwickelt finale Industrieproduktion, Panzer und Montagewerke.',
      'radio':
          'Stärkt Imperiumskommunikation, Sicht und Einfluss durch Sendetürme.',
      'nuclearPhysics': 'Öffnet Reaktor, Uran und späte Endspielprojekte.',
      'other': '',
    });
    return '$_temp0';
  }
}
