// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AonwLocalizationsPl extends AonwLocalizations {
  AonwLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get moveTargeting => 'Ruch';

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String get mainMenuTitle => 'Menu główne';

  @override
  String get mainMenuWelcome =>
      'Witaj w Erze Nowych Światów. Buduj miasta, prowadź dowódców, odkrywaj nowe krainy i zapisuj historię swojej cywilizacji.';

  @override
  String get mainMenuSynopsisTitle => 'Buduj · Badaj · Dowódź';

  @override
  String get mainMenuWhatsNew => 'Co nowego';

  @override
  String get singlePlayer => 'Gra jednoosobowa';

  @override
  String get singlePlayerSublabel => 'Rozgrywka przeciw komputerowi';

  @override
  String get multiplayerSublabel => 'Rozgrywka online';

  @override
  String get hotseat => 'Hotseat';

  @override
  String get hotseatSublabel => 'Gracze przy jednym urządzeniu';

  @override
  String get hotseatUnavailable =>
      'Konfiguracja hotseat nie jest jeszcze dostępna.';

  @override
  String get hotseatHandoffTitle => 'Przekaż urządzenie';

  @override
  String hotseatHandoffBody(String name) {
    return 'Przekaż urządzenie graczowi $name. Jego mapa pozostanie ukryta do potwierdzenia.';
  }

  @override
  String hotseatContinueAs(String name) {
    return 'Kontynuuj jako $name';
  }

  @override
  String get hotseatHandoffSwitching => 'Przygotowywanie następnego gracza';

  @override
  String get hotseatHandoffFailure =>
      'Nie udało się bezpiecznie otworzyć widoku następnego gracza.';

  @override
  String get loadGame => 'Wczytaj grę';

  @override
  String get loadGameSublabel => 'Zapisy i powtórki';

  @override
  String get exitGame => 'Wyjdź';

  @override
  String get instructions => 'Instrukcja';

  @override
  String get creditsTitle => 'Autorzy';

  @override
  String creditsCreatedBy(String name) {
    return 'Autor: $name';
  }

  @override
  String get devlogLinkLabel => 'Dziennik twórcy: ernest.dev';

  @override
  String get feedbackTitle => 'Opinie';

  @override
  String get feedbackDescription =>
      'Podziel się pomysłami, zgłoś problem i obserwuj rozwój Age of New Worlds razem ze społecznością.';

  @override
  String get openFeedback => 'Otwórz r/aonw';

  @override
  String get externalLinkUnavailable =>
      'Odnośniki zewnętrzne są niedostępne na tej platformie.';

  @override
  String get serverUpdateSoon =>
      'Nowsza wersja gry jest już gotowa i pojawi się na tej platformie wkrótce. Sprawdź sklep albo launcher za chwilę.';

  @override
  String get continueGame => 'Kontynuuj';

  @override
  String get resumingGame => 'Wznawianie gry';

  @override
  String get newGame => 'Nowa gra';

  @override
  String get multiplayerTitle => 'Gra wieloosobowa';

  @override
  String get multiplayerUnavailable =>
      'Gra wieloosobowa jest niedostępna w tej wersji.';

  @override
  String get loadingMultiplayer => 'Łączenie z grą wieloosobową';

  @override
  String get multiplayerAuthenticationTitle => 'Konto AoNW';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Hasło';

  @override
  String get displayNameLabel => 'Nazwa gracza';

  @override
  String get invalidEmail => 'Podaj prawidłowy adres e-mail.';

  @override
  String get invalidPassword => 'Użyj co najmniej 12 znaków.';

  @override
  String get invalidDisplayName => 'Podaj nazwę gracza.';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get createNewAccount => 'Utwórz nowe konto';

  @override
  String get useExistingAccount => 'Użyj istniejącego konta';

  @override
  String get multiplayerLobbyTitle => 'Poczekalnia';

  @override
  String signedInAccount(String userId) {
    return 'Konto: $userId';
  }

  @override
  String get multiplayerSetupTitle => 'Utwórz grę online';

  @override
  String get multiplayerSetupIntro =>
      'Wybierz cywilizację i mapę przed otwarciem autorytatywnej poczekalni.';

  @override
  String get multiplayerTurnModeDescription =>
      'Wszyscy gracze działają w ramach jednej wspólnej tury. Silnik rozlicza ją po zatwierdzeniu przez wymaganych graczy albo po autorytatywnym limicie czasu.';

  @override
  String get continueToLobby => 'Przejdź do poczekalni';

  @override
  String get createMultiplayerMatch => 'Utwórz rozgrywkę';

  @override
  String get joinMultiplayerMatch => 'Dołącz do rozgrywki';

  @override
  String get matchIdLabel => 'Identyfikator rozgrywki';

  @override
  String get playerSeatLabel => 'Miejsce gracza';

  @override
  String get playerSeatOne => 'Gracz pierwszy';

  @override
  String get playerSeatTwo => 'Gracz drugi';

  @override
  String playerSeatNumber(int number) {
    return 'Gracz $number';
  }

  @override
  String get refreshMatches => 'Odśwież rozgrywki';

  @override
  String get yourMatches => 'Twoje rozgrywki';

  @override
  String get noMultiplayerMatches =>
      'Nie dołączono jeszcze do żadnej rozgrywki.';

  @override
  String matchRevision(int revision, int eventOffset) {
    return 'Rewizja $revision · pozycja zdarzeń $eventOffset';
  }

  @override
  String multiplayerMatchPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'lobby': 'poczekalnia',
      'running': 'w toku',
      'finished': 'zakończona',
      'abandoned': 'porzucona',
      'other': 'nieznany',
    });
    return 'Status: $_temp0';
  }

  @override
  String get multiplayerWaitingRoomTitle => 'Poczekalnia rozgrywki';

  @override
  String get multiplayerReady => 'Gotowy';

  @override
  String get multiplayerNotReady => 'Niegotowy';

  @override
  String get multiplayerSeatOpen => 'Wolne miejsce gracza';

  @override
  String get multiplayerHumanSeat => 'Człowiek';

  @override
  String get multiplayerAiSeat => 'Komputer';

  @override
  String get multiplayerHost => 'Host';

  @override
  String get multiplayerCurrentPlayer => 'Ty';

  @override
  String get markReady => 'Zgłoś gotowość';

  @override
  String get markNotReady => 'Wycofaj gotowość';

  @override
  String get waitingForPlayers =>
      'Każde miejsce człowieka musi być zajęte, a wszyscy gracze gotowi przed startem.';

  @override
  String get refreshMatch => 'Odśwież rozgrywkę';

  @override
  String get leaveMultiplayerMatch => 'Opuść rozgrywkę';

  @override
  String get multiplayerResignTitle => 'Poddać tę rozgrywkę?';

  @override
  String get multiplayerResignBody =>
      'Twój udział zakończy się natychmiast i tej operacji nie można cofnąć.';

  @override
  String get multiplayerResignConfirm => 'Poddaj rozgrywkę';

  @override
  String get multiplayerMatchTitle => 'Rozgrywka online';

  @override
  String get multiplayerParticipants => 'Uczestnicy';

  @override
  String get multiplayerRemoveParticipant => 'Usuń';

  @override
  String get multiplayerRemoveParticipantTitle => 'Usunąć uczestnika?';

  @override
  String multiplayerRemoveParticipantBody(String name) {
    return 'Usunąć gracza $name z tej rozgrywki? Nie będzie mógł ponownie się połączyć.';
  }

  @override
  String get cancelDialog => 'Anuluj';

  @override
  String matchIdentifier(String matchId) {
    return 'Rozgrywka: $matchId';
  }

  @override
  String playerIdentifier(String playerId) {
    return 'Gracz: $playerId';
  }

  @override
  String multiplayerTurn(int turn) {
    return 'Tura $turn';
  }

  @override
  String multiplayerSubmissionProgress(int submitted, int required) {
    return 'Zatwierdzono $submitted z $required';
  }

  @override
  String visibleUnits(int count) {
    return 'Widoczne jednostki: $count';
  }

  @override
  String networkPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'connecting': 'łączenie',
      'ready': 'online',
      'reconnecting': 'ponowne łączenie',
      'resyncing': 'synchronizacja',
      'failed': 'offline',
      'closed': 'zamknięte',
      'other': 'niedostępne',
    });
    return 'Połączenie: $_temp0';
  }

  @override
  String get submitTurn => 'Zatwierdź turę';

  @override
  String get reconnect => 'Połącz ponownie';

  @override
  String get backToLobby => 'Wróć do poczekalni';

  @override
  String multiplayerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'client_update_required': 'Zaktualizuj klienta przed połączeniem.',
      'authentication_required': 'Zaloguj się ponownie.',
      'invalid_authentication_response':
          'Odpowiedź uwierzytelniania była nieprawidłowa.',
      'authentication_identity_changed':
          'Podczas odświeżania zmieniła się tożsamość konta.',
      'connection_interrupted':
          'Połączenie zostało przerwane. Połącz się ponownie, aby zsynchronizować rozgrywkę.',
      'invalid_server_response': 'Odpowiedź serwera nie przeszła walidacji.',
      'invalid_command_sequence': 'Sekwencja polecenia nie była ciągła.',
      'invalid_resync_sequence': 'Zsynchronizowany stan cofnął rozgrywkę.',
      'invalid_match_lifecycle':
          'Odpowiedź cyklu życia rozgrywki była niespójna.',
      'match_not_found': 'Nie znaleziono rozgrywki.',
      'match_not_started': 'Host nie rozpoczął jeszcze rozgrywki.',
      'match_already_started': 'Rozgrywka została już rozpoczęta.',
      'host_required': 'Tylko host może wykonać tę akcję.',
      'lobby_not_ready':
          'Każdy gracz-człowiek musi dołączyć i zgłosić gotowość.',
      'participant_not_claimable':
          'Nie można zająć miejsca sterowanego przez komputer.',
      'participant_not_active': 'Ten uczestnik nie jest już aktywny.',
      'invalid_kick_target': 'Host nie może usunąć samego siebie.',
      'player_seat_taken': 'To miejsce gracza jest już zajęte.',
      'other': 'Nie udało się wykonać żądania gry wieloosobowej.',
    });
    return '$_temp0';
  }

  @override
  String get helpTitle => 'Jak grać';

  @override
  String get helpIntroduction =>
      'Rozwijaj cywilizację tura po turze. Silnik rozstrzyga wszystkie zasady, a ten przewodnik wyjaśnia decyzje dostępne w kliencie.';

  @override
  String get helpObjectiveTitle => 'Realizuj cel';

  @override
  String get helpObjectiveBody =>
      'Rozwijaj terytorium i miasta oraz ukończ cele scenariusza przed przeciwnikiem. Na mapie otwórz Cele strategiczne, aby sprawdzić zaprojektowane zadania.';

  @override
  String get helpMapTitle => 'Odkrywaj i dowódź';

  @override
  String get helpMapBody =>
      'Wybierz widoczny heks, aby go sprawdzić. Wybierz swoją jednostkę, wskaż podświetlony cel i potwierdź trasę. Klawiatura, gamepad i dotyk korzystają z tych samych poleceń.';

  @override
  String get helpDevelopmentTitle => 'Rozwijaj cywilizację';

  @override
  String get helpDevelopmentBody =>
      'Korzystaj z paneli miasta, badań, produkcji, robotników, logistyki, artefaktów i dyplomacji, gdy ich akcje staną się dostępne.';

  @override
  String get helpTurnTitle => 'Kończ turę świadomie';

  @override
  String get helpTurnBody =>
      'Zakończ swoje działania, a następnie turę. Komputer wykonuje swoją autorytatywną turę, zanim sterowanie wróci do ciebie.';

  @override
  String get helpSaveReplayTitle => 'Zapisuj i analizuj';

  @override
  String get helpSaveReplayBody =>
      'Zapisuj grę z mapy. Kontynuuj otwiera ostatni poprawny zapis, a Powtórka pokazuje autorytatywną historię poleceń bez zmieniania gry.';

  @override
  String get startOnboarding => 'Rozpocznij przewodnik';

  @override
  String get onboardingTitle => 'Przewodnik po grze';

  @override
  String onboardingProgress(int step, int count) {
    return 'Krok $step z $count';
  }

  @override
  String get onboardingExploreTitle => 'Czytaj mapę';

  @override
  String get onboardingExploreBody =>
      'Mapa pokazuje tylko informacje widoczne dla twojego gracza. Wybieraj heksy, aby sprawdzać teren, miasta i jednostki, a potem przesuwaj lub przybliżaj widok, planując kolejną akcję.';

  @override
  String get onboardingCommandTitle => 'Wydawaj precyzyjne polecenia';

  @override
  String get onboardingCommandBody =>
      'Dostępne cele i akcje pochodzą z silnika gry. Wybierz akcję, sprawdź podgląd i ją potwierdź; odrzucone lub nieaktualne polecenia nigdy nie zmieniają rozgrywki.';

  @override
  String get onboardingDevelopTitle => 'Buduj długoterminową przewagę';

  @override
  String get onboardingDevelopBody =>
      'Miasta, produkcja, badania, robotnicy, logistyka, artefakty i dyplomacja kształtują strategię. Ich panele pokazują wyłącznie akcje aktualnie dozwolone przez silnik.';

  @override
  String get onboardingContinueTitle => 'Wracaj do gry bez obaw';

  @override
  String get onboardingContinueBody =>
      'Przed wyjściem zapisz autorytatywny stan gry. Kontynuuj waliduje go w nowej sesji silnika, a Powtórka pozwala tylko odczytywać tę samą historię.';

  @override
  String get previousOnboardingStep => 'Wstecz';

  @override
  String get nextOnboardingStep => 'Dalej';

  @override
  String get skipOnboarding => 'Pomiń';

  @override
  String get finishOnboarding => 'Utwórz grę';

  @override
  String get newGameTitle => 'Utwórz grę lokalną';

  @override
  String get singlePlayerSetupTitle => 'Graj z komputerem';

  @override
  String get singlePlayerSetupIntro => 'Wybierz cywilizację i ustaw rozgrywkę.';

  @override
  String get hotseatSetupTitle => 'Graj w trybie hotseat';

  @override
  String get hotseatSetupIntro =>
      'Korzystajcie z jednego urządzenia. Widok każdego człowieka pozostaje ukryty do potwierdzenia przekazania tury.';

  @override
  String get chooseCivilizationTitle => 'Wybierz cywilizację';

  @override
  String get gameSetupTitle => 'Ustawienie rozgrywki';

  @override
  String get turnModeTitle => 'Tryb tur';

  @override
  String turnModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'sequential': 'Tradycyjne',
      'simultaneous': 'Symultaniczne',
      'other': 'Nieznane',
    });
    return '$_temp0';
  }

  @override
  String get turnModeSequentialDescription =>
      'Cywilizacje wykonują i rozliczają swoje tury kolejno.';

  @override
  String get turnModeSimultaneousDescription =>
      'Gracz i komputer działają w ramach tej samej tury, zanim silnik rozliczy jej wspólne fazy.';

  @override
  String get opponentsTitle => 'Przeciwnicy';

  @override
  String get opponentControlLabel => 'Sterowanie przeciwnikiem';

  @override
  String opponentNumberLabel(int number) {
    return 'Przeciwnik $number';
  }

  @override
  String get humanOpponent => 'Żywy gracz';

  @override
  String get aiOpponent => 'Komputer';

  @override
  String get mapSetupTitle => 'Mapa';

  @override
  String get mapSetupBody =>
      'Kompaktowa, ręcznie przygotowana mapa 7 × 7 do skupionego pojedynku dwóch cywilizacji.';

  @override
  String mapSetupDetails(String mapName, int columns, int rows, int players) {
    return '$mapName · $columns × $rows · $players cywilizacje';
  }

  @override
  String get victoryPathsTitle => 'Drogi do zwycięstwa';

  @override
  String get victoryPathsBody =>
      'Podbój, dominacja, kultura i punkty są rozstrzygane przez silnik gry.';

  @override
  String get settlementToEmpireTitle => 'Od osady do imperium';

  @override
  String get settlementToEmpireBody =>
      'Eksploruj, zakładaj miasta, prowadź badania, twórz armie i buduj trwałą przewagę.';

  @override
  String get continueToSummary => 'Przejdź do podsumowania';

  @override
  String get gameSummaryTitle => 'Wyprawa gotowa';

  @override
  String get gameSummaryIntro =>
      'Sprawdź wszystkich lokalnych uczestników przed utworzeniem rozgrywki.';

  @override
  String get summaryModeLabel => 'Tryb';

  @override
  String get summaryTurnModeLabel => 'Tury';

  @override
  String get summaryCivilizationLabel => 'Twoja cywilizacja';

  @override
  String get summaryOpponentLabel => 'Przeciwnik';

  @override
  String get summaryMapLabel => 'Mapa';

  @override
  String get summaryFogLabel => 'Mgła wojny';

  @override
  String get summaryAiLabel => 'Profil komputera';

  @override
  String get changeSetup => 'Zmień ustawienia';

  @override
  String localModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'singlePlayer': 'Gra jednoosobowa',
      'hotseat': 'Hotseat',
      'other': 'Gra lokalna',
    });
    return '$_temp0';
  }

  @override
  String participantControlName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'human': 'Człowiek',
      'ai': 'Komputer',
      'other': 'Nieznane',
    });
    return '$_temp0';
  }

  @override
  String fogSettingName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'enabled': 'Włączona',
      'disabled': 'Wyłączona',
      'other': 'Nieznane',
    });
    return '$_temp0';
  }

  @override
  String get defaultSecondPlayerName => 'Gracz 2';

  @override
  String defaultNumberedPlayerName(int number) {
    return 'Gracz $number';
  }

  @override
  String defaultNumberedAiName(int number) {
    return 'Komputer $number';
  }

  @override
  String get scenarioLabel => 'Mapa';

  @override
  String localScenarioName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'starterDuel': 'Startowa',
      'dravonia': 'Dravonia',
      'myranth': 'Myranth',
      'terenos': 'Terenos',
      'verdantia': 'Verdantia',
      'other': 'Mapa lokalna',
    });
    return '$_temp0';
  }

  @override
  String get humanCountryLabel => 'Twój kraj';

  @override
  String get aiCountryLabel => 'Kraj AI';

  @override
  String get aiDifficultyLabel => 'Poziom trudności AI';

  @override
  String get aiPersonaLabel => 'Osobowość AI';

  @override
  String get fogOfWarLabel => 'Mgła wojny';

  @override
  String get startGame => 'Rozpocznij grę';

  @override
  String get startingGame => 'Uruchamianie gry';

  @override
  String get localGameStartFailed => 'Nie udało się uruchomić gry lokalnej.';

  @override
  String get saveGame => 'Zapisz grę';

  @override
  String get savingGame => 'Zapisywanie gry';

  @override
  String get gameSaved => 'Gra została zapisana';

  @override
  String saveFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Zapisywanie jest niedostępne dla tej sesji.',
      'exportFailed': 'Nie udało się wyeksportować stanu gry.',
      'writeFailed': 'Nie udało się zapisać pliku gry.',
      'other': 'Nie udało się zapisać gry.',
    });
    return '$_temp0';
  }

  @override
  String resumeFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Zapisane gry są niedostępne na tej platformie.',
      'missing': 'Nie znaleziono zapisanej gry.',
      'unreadable': 'Nie udało się odczytać zapisanej gry.',
      'incompatible':
          'Zapisana gra jest nieprawidłowa lub niezgodna z bieżącą grą.',
      'other': 'Nie udało się wznowić gry.',
    });
    return '$_temp0';
  }

  @override
  String get loadGameTitle => 'Wczytaj grę';

  @override
  String get loadGameEmpty => 'Nie znaleziono zapisanych gier.';

  @override
  String loadGameSingleLabel(String scenario) {
    return 'Gra jednoosobowa · $scenario';
  }

  @override
  String get importSave => 'Importuj zapis';

  @override
  String get exportSave => 'Eksportuj';

  @override
  String get saveTransferUnavailable =>
      'Import i eksport zapisów są niedostępne na tej platformie.';

  @override
  String saveImportCompleted(String map) {
    return 'Zaimportowano mapę $map jako osobny zapis gry.';
  }

  @override
  String saveExportCompleted(String map) {
    return 'Wyeksportowano mapę $map.';
  }

  @override
  String saveTransferFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Transfer zapisów jest niedostępny na tej platformie.',
      'unreadable': 'Nie udało się odczytać wybranego pliku zapisu.',
      'tooLarge': 'Wybrany plik zapisu przekracza limit 16 MiB.',
      'incompatible':
          'Wybrany zapis jest nieprawidłowy albo nie pasuje do zainstalowanej mapy, rulesetu lub wersji silnika.',
      'missing': 'Wybrany zapis gry już nie istnieje.',
      'writeFailed': 'Nie udało się zachować zaimportowanego zapisu.',
      'exportFailed': 'Nie udało się wyeksportować pliku zapisu.',
      'other': 'Nie udało się ukończyć transferu zapisu.',
    });
    return '$_temp0';
  }

  @override
  String get replayTitle => 'Powtórka';

  @override
  String get loadingReplay => 'Wczytywanie powtórki';

  @override
  String get replayUnavailable => 'Odtwarzanie powtórki jest niedostępne.';

  @override
  String replayFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'Odtwarzanie powtórek jest niedostępne na tej platformie.',
      'missing': 'Nie znaleziono powtórki. Najpierw zapisz grę lokalną.',
      'unreadable': 'Nie udało się odczytać pliku powtórki.',
      'incompatible':
          'Powtórka jest nieprawidłowa lub niezgodna z bieżącą grą.',
      'seekFailed': 'Nie udało się wczytać wybranej klatki powtórki.',
      'other': 'Nie udało się otworzyć powtórki.',
    });
    return '$_temp0';
  }

  @override
  String get replayMapLabel => 'Mapa powtórki';

  @override
  String get replayControls => 'Sterowanie powtórką';

  @override
  String get playReplay => 'Odtwórz powtórkę';

  @override
  String get pauseReplay => 'Wstrzymaj powtórkę';

  @override
  String get backToMenu => 'Wróć do menu głównego';

  @override
  String replayProgress(int position, int entryCount) {
    return '$position z $entryCount';
  }

  @override
  String replaySpeed(String value) {
    return 'Szybkość $value×';
  }

  @override
  String get aiTurnRunning => 'Komputer wykonuje swoją turę.';

  @override
  String aiTurnFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'requestFailed': 'Nie udało się ukończyć tury komputera.',
      'responseIncompatible':
          'Odpowiedź tury komputera jest niezgodna z tym klientem.',
      'incomplete': 'Komputer nie ukończył tury w bezpiecznym limicie komend.',
      'other': 'Nie udało się ukończyć tury komputera.',
    });
    return '$_temp0';
  }

  @override
  String get defaultPlayerName => 'Gracz';

  @override
  String get defaultAiName => 'Komputer';

  @override
  String countryName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'poland': 'Polska',
      'ukraine': 'Ukraina',
      'germany': 'Niemcy',
      'france': 'Francja',
      'unitedKingdom': 'Wielka Brytania',
      'italy': 'Włochy',
      'spain': 'Hiszpania',
      'netherlands': 'Holandia',
      'sweden': 'Szwecja',
      'russia': 'Rosja',
      'unitedStates': 'Stany Zjednoczone',
      'canada': 'Kanada',
      'china': 'Chiny',
      'korea': 'Korea',
      'japan': 'Japonia',
      'portugal': 'Portugalia',
      'india': 'Indie',
      'brazil': 'Brazylia',
      'indonesia': 'Indonezja',
      'mexico': 'Meksyk',
      'turkey': 'Turcja',
      'saudiArabia': 'Arabia Saudyjska',
      'egypt': 'Egipt',
      'greece': 'Grecja',
      'other': 'Nieznany kraj',
    });
    return '$_temp0';
  }

  @override
  String aiDifficultyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'easy': 'Łatwy',
      'normal': 'Normalny',
      'hard': 'Trudny',
      'veryHard': 'Bardzo trudny',
      'other': 'Nieznany poziom',
    });
    return '$_temp0';
  }

  @override
  String aiPersonaName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'balanced': 'Zrównoważona',
      'aggressive': 'Agresywna',
      'expansive': 'Ekspansywna',
      'economic': 'Gospodarcza',
      'scientific': 'Naukowa',
      'other': 'Nieznana osobowość',
    });
    return '$_temp0';
  }

  @override
  String get unknownRouteLabel => 'Nieznana trasa';

  @override
  String get pageUnavailable => 'Strona niedostępna';

  @override
  String unknownRouteMessage(String location) {
    return 'Nieznana trasa: $location';
  }

  @override
  String get missingRouteLocation => '(brak)';

  @override
  String mapSemanticsLabel(String mapId, int cols, int rows) {
    return 'Mapa $mapId, $cols na $rows heksów';
  }

  @override
  String get mapInputHint =>
      'WASD lub strzałki przesuwają kamerę, Enter wybiera, M włącza ruch, I pokazuje inspekcję, R zmienia widok mapy, nawiasy kwadratowe przechodzą między czynnościami, a spacja wybiera następną czynność lub kończy turę. Tab przenosi fokus między kontrolkami.';

  @override
  String get noHexSelected => 'Nie wybrano heksa';

  @override
  String selectedHex(int col, int row) {
    return 'Wybrany heks $col, $row';
  }

  @override
  String get mapViewModeTooltip => 'Zmień tryb widoku mapy';

  @override
  String get mapViewGraphicUnavailable =>
      'Widok graficzny jest niedostępny dla tej mapy.';

  @override
  String get mapViewModeGraphic => 'Graficzna';

  @override
  String get mapViewModeTiles => 'Kafelki';

  @override
  String hexLabel(int col, int row) {
    return 'Heks $col, $row';
  }

  @override
  String get selectionTerrain => 'Teren';

  @override
  String unitLabel(String unitId) {
    return 'Jednostka $unitId';
  }

  @override
  String routeSummary(int totalCost, int remaining) {
    return 'Trasa: $totalCost punktów ruchu · pozostało $remaining';
  }

  @override
  String get confirmMove => 'Potwierdź ruch';

  @override
  String moveTurnCost(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns tury',
      many: '$turns tur',
      few: '$turns tury',
      one: '1 tura',
    );
    return '$_temp0';
  }

  @override
  String confirmMoveWithCost(String turnCost) {
    return 'Potwierdź · $turnCost';
  }

  @override
  String get chooseHighlightedDestination =>
      'Wybierz podświetlone pole docelowe.';

  @override
  String get movingUnit => 'Przemieszczanie jednostki';

  @override
  String unitActionLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'title': 'Akcje jednostki',
      'fortify': 'Ufortyfikuj',
      'skip': 'Pomiń',
      'cancel': 'Anuluj akcję',
      'executing': 'Wykonywanie akcji jednostki',
      'logisticsTitle': 'Logistyka',
      'logisticsLoading': 'Ładowanie opcji logistycznych',
      'logisticsEmpty': 'Brak dostępnych działań logistycznych.',
      'autoExplore': 'Automatyczna eksploracja',
      'merchantRoute': 'Przypisz szlak handlowy',
      'merchantTravel': 'Przenieś do miasta',
      'detachTroop': 'Odłącz oddział',
      'other': 'Akcja jednostki',
    });
    return '$_temp0';
  }

  @override
  String unitActionFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'Nie udało się wykonać żądania akcji jednostki.',
      'responseIncompatible':
          'Odpowiedź akcji jednostki jest niezgodna z tym klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'stale': 'Stan gry uległ zmianie. Sprawdź jednostkę i spróbuj ponownie.',
      'matchFinished': 'Rozgrywka już się zakończyła.',
      'unitUnavailable':
          'Ta jednostka nie jest już dostępna do wydawania rozkazów.',
      'unitBusy':
          'Ta jednostka jest zajęta i nie może teraz wykonać tej akcji.',
      'internal': 'Nie udało się zastosować akcji jednostki. Spróbuj ponownie.',
      'logisticsRequestFailed': 'Nie udało się wykonać żądania logistycznego.',
      'logisticsResponseIncompatible':
          'Odpowiedź logistyczna jest niezgodna z tym klientem.',
      'logisticsOptionUnavailable':
          'Ta opcja logistyczna nie jest już dostępna.',
      'combatFailureRequestFailed': 'Nie udało się wykonać żądania walki.',
      'combatFailureResponseIncompatible':
          'Odpowiedź walki jest niezgodna z tym klientem.',
      'combatFailureSessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'combatFailureTargetUnavailable':
          'Dla tego celu nie ma dostępnego podglądu ataku.',
      'combatFailureStaleRevision':
          'Stan gry uległ zmianie. Sprawdź go i spróbuj ponownie.',
      'combatFailureMatchFinished': 'Mecz już się zakończył.',
      'combatFailureAttackerNotFound':
          'Atakująca jednostka nie jest już dostępna.',
      'combatFailureAttackerNotControlled':
          'Atakująca jednostka nie należy do tego gracza.',
      'combatFailureAttackerUnavailable':
          'Atakująca jednostka jest niedostępna.',
      'combatFailureAttackerExhausted': 'Atakująca jednostka jest wyczerpana.',
      'combatFailureAttackerOutOfBounds':
          'Atakująca jednostka znajduje się poza mapą.',
      'combatFailureAttackerCannotAttack': 'Ta jednostka nie może atakować.',
      'combatFailureAttackTargetNotVisible': 'Cel nie jest widoczny.',
      'combatFailureAttackTargetOutOfBounds': 'Cel znajduje się poza mapą.',
      'combatFailureAttackTargetNotFound': 'W tym miejscu nie ma celu.',
      'combatFailureAttackTargetNotEnemy': 'Ten cel nie jest wrogiem.',
      'combatFailureAttackTargetProtectedByTreaty': 'Traktat chroni ten cel.',
      'combatFailureAttackTargetOutOfRange': 'Cel jest poza zasięgiem.',
      'combatFailureAttackCityHasNoHealth': 'Tego miasta nie można zaatakować.',
      'other': 'Nie udało się wykonać akcji jednostki.',
    });
    return '$_temp0';
  }

  @override
  String turnSummary(String kind, int turn, int submitted, int required) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'label': 'TURA $turn',
      'progress': 'Gotowi: $submitted z $required',
      'other': 'TURA $turn',
    });
    return '$_temp0';
  }

  @override
  String turnText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'statusActive': 'Twoja tura',
      'statusFinished': 'Tura zakończona',
      'statusSubmitted': 'Tura zgłoszona',
      'statusWaiting': 'Oczekiwanie',
      'statusPendingAction': 'Wymagana akcja',
      'actionEnd': 'Zakończ turę',
      'actionSubmit': 'Zatwierdź turę',
      'actionSubmitting': 'Zatwierdzanie tury',
      'actionEnding': 'Kończenie tury',
      'outcomeConquest': 'Zwycięstwo przez podbój',
      'outcomeDomination': 'Zwycięstwo przez dominację',
      'outcomeCultural': 'Zwycięstwo kulturowe',
      'outcomeScore': 'Zwycięstwo punktowe',
      'outcomeResignation': 'Rozgrywka zakończona rezygnacją',
      'outcomeDraw': 'Remis',
      'outcomeOngoing': 'Rozgrywka trwa',
      'activityTitle': 'Aktywność',
      'activityArtifact': 'Aktywność artefaktu',
      'activityCity': 'Aktywność miasta',
      'activityResearch': 'Postęp badań',
      'activityObjective': 'Aktualizacja celu strategicznego',
      'activityOutcome': 'Zaktualizowano wynik rozgrywki',
      'activityCombat': 'Aktywność bojowa',
      'activityDiplomacy': 'Aktywność dyplomatyczna',
      'activityUnit': 'Aktywność jednostki',
      'activityTurn': 'Zaktualizowano turę',
      'activityWorker': 'Robotnik ukończył zadanie',
      'combatTitle': 'Walka',
      'combatLoading': 'Ładowanie podglądu walki',
      'combatTarget': 'Cel',
      'combatDistance': 'Dystans',
      'combatOutgoing': 'Zadawane obrażenia',
      'combatRetaliation': 'Obrażenia odwetowe',
      'combatNone': 'Brak',
      'combatCapture': 'Przejmij miasto',
      'combatDestroy': 'Zniszcz miasto',
      'combatConfirm': 'Potwierdź atak',
      'combatExecuting': 'Rozstrzyganie walki',
      'combatResolved': 'Walka rozstrzygnięta',
      'combatAttackerHp': 'Zdrowie atakującego',
      'combatDefenderHp': 'Zdrowie obrońcy',
      'combatEventUnitAttacked': 'Jednostka zaatakowana',
      'combatEventCityAttacked': 'Miasto zaatakowane',
      'combatEventCombatResolved': 'Walka rozstrzygnięta',
      'combatEventUnitGainedExperience': 'Jednostka zdobyła doświadczenie',
      'combatEventUnitKilled': 'Jednostka pokonana',
      'combatEventUnitRetreated': 'Jednostka wycofała się',
      'combatEventCityCaptured': 'Miasto przejęte',
      'combatEventCityDestroyed': 'Miasto zniszczone',
      'combatEventDiplomaticScoreChanged': 'Relacja dyplomatyczna zmieniona',
      'other': 'Aktywność w grze',
    });
    return '$_temp0';
  }

  @override
  String turnFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'Nie udało się wykonać żądania zakończenia tury.',
      'responseIncompatible': 'Odpowiedź tury jest niezgodna z tym klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'stale_revision':
          'Stan gry uległ zmianie. Sprawdź go i spróbuj ponownie.',
      'match_finished': 'Rozgrywka już się zakończyła.',
      'turn_player_not_controlled':
          'Ten gracz nie może zakończyć bieżącej tury.',
      'turn_player_not_active': 'Ten gracz nie jest aktywny.',
      'turn_scope_invalid': 'Zakres bieżącej tury jest nieprawidłowy.',
      'turn_processor_unsupported': 'Wymagany procesor tury jest niedostępny.',
      'turn_number_overflow': 'Nie można zapisać numeru następnej tury.',
      'state_revision_overflow': 'Nie można zwiększyć rewizji gry.',
      'other': 'Nie udało się zakończyć tury.',
    });
    return '$_temp0';
  }

  @override
  String get loadingMap => 'Wczytywanie mapy';

  @override
  String get mapLoadingFailed => 'Nie udało się wczytać mapy';

  @override
  String get mapUnavailable => 'Mapa jest niedostępna';

  @override
  String get mapAdapterUnavailable =>
      'Natywny adapter gry jest niedostępny na tej platformie.';

  @override
  String get mapClientIncompatible =>
      'Natywny adapter gry jest niezgodny z tym klientem.';

  @override
  String get mapLoadSuperseded => 'Nowsze żądanie mapy zastąpiło to żądanie.';

  @override
  String get mapLoadFailure => 'Nie udało się wczytać mapy.';

  @override
  String get movementRequestFailed => 'Nie udało się wykonać żądania ruchu.';

  @override
  String get movementResponseIncompatible =>
      'Odpowiedź ruchu jest niezgodna z tym klientem.';

  @override
  String get movementSessionUnavailable =>
      'Lokalna sesja gry jest niedostępna.';

  @override
  String get moveRejectedStale =>
      'Stan gry uległ zmianie. Sprawdź aktualną pozycję i spróbuj ponownie.';

  @override
  String get moveRejectedUnitUnavailable =>
      'Ta jednostka nie jest już dostępna do ruchu.';

  @override
  String get moveRejectedUnitBusy =>
      'Ta jednostka jest zajęta i nie może się teraz ruszyć.';

  @override
  String get moveRejectedTargetUnavailable =>
      'To pole docelowe jest niedostępne.';

  @override
  String get moveRejectedMovementInsufficient =>
      'Jednostka nie ma wystarczającej liczby punktów ruchu.';

  @override
  String get moveRejectedPathUnavailable =>
      'Brak dostępnej prawidłowej trasy do tego celu.';

  @override
  String get moveRejectedInternal =>
      'Nie udało się zastosować ruchu. Spróbuj ponownie.';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get audioSettings => 'Dźwięk';

  @override
  String get cameraSettings => 'Kamera';

  @override
  String get cameraSensitivity => 'Czułość przybliżenia';

  @override
  String get animationSettings => 'Animacje';

  @override
  String get showUnitMovementAnimations => 'Pokazuj animacje ruchu jednostki';

  @override
  String get showUnitIdleAnimations => 'Pokazuj animacje bezczynności';

  @override
  String get showRouteAnimations => 'Pokazuj animacje wyznaczonej trasy';

  @override
  String get showCombatAnimations => 'Pokazuj animacje walki';

  @override
  String get cinematicCamera => 'Filmowa kamera';

  @override
  String get smoothCameraMovement => 'Płynny ruch kamery';

  @override
  String get mapSettings => 'Mapa';

  @override
  String get mapGrid => 'Obramowanie heksów';

  @override
  String get mapGridDescription => 'Pokazuj czarne obramowanie heksów mapy.';

  @override
  String get mapResourceIcons => 'Ikony zasobów';

  @override
  String get mapResourceIconsDescription =>
      'Pokazuj zasoby dostępne na heksach mapy.';

  @override
  String get mapTerrainIcons => 'Ikony terenu';

  @override
  String get mapTerrainIconsDescription =>
      'Pokazuj typy terenu przypisane do każdego heksu.';

  @override
  String get mapHeightBadges => 'Etykiety wysokości';

  @override
  String get mapHeightBadgesDescription =>
      'Pokazuj zapisaną wysokość wyniesionych heksów.';

  @override
  String get mapElevationWalls => 'Ściany wysokości';

  @override
  String get mapElevationWallsDescription =>
      'Pokazuj głębokość wyniesionych heksów zależną od sąsiadów.';

  @override
  String get accessibilitySettings => 'Dostępność';

  @override
  String get reducedMotion => 'Ogranicz ruch';

  @override
  String get reducedMotionDescription => 'Wyłącz zbędne animacje i przejścia.';

  @override
  String get highContrast => 'Wysoki kontrast';

  @override
  String get highContrastDescription =>
      'Zwiększ kontrast interfejsu aplikacji.';

  @override
  String get resetSettings => 'Przywróć domyślne';

  @override
  String get objectivesTitle => 'Cele strategiczne';

  @override
  String get openObjectives => 'Otwórz cele strategiczne';

  @override
  String get closeObjectives => 'Zamknij cele strategiczne';

  @override
  String get objectivesEmpty => 'Ta mapa nie ma celów.';

  @override
  String objectiveControlProgress(String player, int turns, int required) {
    return 'Kontroluje: $player\nPostęp utrzymania: $turns / $required';
  }

  @override
  String get objectiveControlUnknown => 'Brak znanego kontrolującego';

  @override
  String get objectivesAuthoredRules =>
      'Zajmuj te miejsca i utrzymuj kontrolę przez wymaganą liczbę tur.';

  @override
  String objectiveType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'ruins': 'Ruiny',
      'strategicPass': 'Przełęcz strategiczna',
      'holySite': 'Święte miejsce',
      'legendaryResource': 'Legendarny zasób',
      'other': 'Cel strategiczny',
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
    return 'Heks $col, $row\nWymagane tury utrzymania: $holdTurns · Punkty zwycięstwa: $victoryPoints · Złoto na turę: $goldPerTurn';
  }

  @override
  String get matchFinishedTitle => 'Rozgrywka zakończona';

  @override
  String outcomeWinner(String playerId) {
    return 'Zwycięzca: $playerId';
  }

  @override
  String get outcomeNoWinner => 'Brak zwycięzcy';

  @override
  String get outcomeFinalScore => 'Wynik końcowy';

  @override
  String outcomeScoreLine(String playerId, int score) {
    return '$playerId: $score';
  }

  @override
  String cityText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Miasto',
      'foundingTitle': 'Załóż miasto',
      'loading': 'Ładowanie danych miasta',
      'owner': 'Właściciel',
      'health': 'Zdrowie',
      'population': 'Populacja',
      'territory': 'Terytorium',
      'foundingSelection': 'Terytorium początkowe',
      'foundingConfirm': 'Potwierdź założenie miasta',
      'foundingCancel': 'Anuluj zakładanie',
      'executing': 'Wykonywanie akcji miasta',
      'cityYield': 'Dochód',
      'food': 'Żywność',
      'production': 'Produkcja',
      'gold': 'Złoto',
      'defense': 'Obrona',
      'workedHexes': 'Pola robocze',
      'workedHexSelect': 'Zarządzaj polami roboczymi',
      'workedHexHint': 'Wybierz podświetlone kontrolowane pole na mapie.',
      'expansion': 'Preferowana ekspansja',
      'expansionSelect': 'Wybierz ekspansję',
      'expansionHint': 'Wybierz podświetlone pole ekspansji na mapie.',
      'managementCancel': 'Zakończ wybór na mapie',
      'foundingOpen': 'Zaplanuj miasto',
      'other': 'Miasto',
    });
    return '$_temp0';
  }

  @override
  String cityFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Nie udało się wykonać żądania miasta.',
      'responseIncompatible': 'Odpowiedź miasta jest niezgodna z tym klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'staleRevision':
          'Stan gry uległ zmianie. Sprawdź miasto i spróbuj ponownie.',
      'matchFinished': 'Rozgrywka już się zakończyła.',
      'cityFounderNotFound':
          'Jednostka zakładająca miasto nie jest już dostępna.',
      'cityFounderNotControlled':
          'Jednostka zakładająca miasto nie należy do tego gracza.',
      'cityFounderBusy': 'Jednostka zakładająca miasto jest zajęta.',
      'cityFounderInvalid': 'Ta jednostka nie może założyć miasta.',
      'cityFounderNoSettlers': 'Jednostka nie ma osadników.',
      'citySiteInvalid': 'W tym miejscu nie można założyć miasta.',
      'cityCenterOccupied': 'Centrum miasta jest zajęte.',
      'cityCenterClaimed': 'Centrum miasta jest już zajęte terytorialnie.',
      'cityCenterTooClose': 'Centrum miasta jest zbyt blisko innego miasta.',
      'cityControlledHexesInvalid':
          'Wybrane terytorium początkowe jest nieprawidłowe.',
      'cityNotFound': 'To miasto nie jest już dostępne.',
      'cityNotControlled': 'To miasto nie należy do tego gracza.',
      'workedHexUnavailable': 'To pole robocze jest niedostępne.',
      'workedHexLimitReached': 'Miasto osiągnęło limit pól roboczych.',
      'cityExpansionHexUnavailable': 'To pole ekspansji jest niedostępne.',
      'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
      'other': 'Nie udało się wykonać żądania miasta.',
    });
    return '$_temp0';
  }

  @override
  String workerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Robotnik',
      'loading': 'Ładowanie opcji robotnika',
      'empty': 'Brak dostępnych akcji robotnika.',
      'executing': 'Wykonywanie akcji robotnika',
      'buildCharges': 'Ładunki budowy',
      'progress': 'Postęp',
      'assigned': 'Przypisane pole',
      'openActions': 'Ulepsz pole',
      'closeActions': 'Anuluj wybór',
      'selectImprovement': 'Wybierz',
      'confirmImprovement': 'Potwierdź ulepszenie',
      'cancelJob': 'Anuluj budowę',
      'assign': 'Przypisz do pola',
      'cancelAssignment': 'Anuluj przypisanie',
      'buildRoad': 'Zbuduj drogę',
      'automate': 'Automatyzuj',
      'automationEvidence': 'Dane planera',
      'other': 'Robotnik',
    });
    return '$_temp0';
  }

  @override
  String workerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Nie udało się wykonać żądania robotnika.',
      'responseIncompatible': 'Odpowiedź robotnika jest niezgodna z klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'staleRevision': 'Stan gry uległ zmianie. Sprawdź robotnika ponownie.',
      'matchFinished': 'Rozgrywka już się zakończyła.',
      'workerNotFound': 'Robotnik nie jest już dostępny.',
      'workerNotControlled': 'Robotnik nie należy do tego gracza.',
      'workerUnavailable': 'Robotnik jest niedostępny.',
      'workerNoMovementPoints': 'Robotnik nie ma punktów ruchu.',
      'workerQueuedPathActive': 'Robotnik ma aktywny rozkaz ruchu.',
      'workerImprovementNotSelected': 'Najpierw wybierz ulepszenie.',
      'workerActionNotControlled':
          'Oczekująca akcja robotnika nie jest kontrolowana.',
      'workerImprovementUnavailable': 'To ulepszenie jest niedostępne.',
      'workerJobNotActive': 'Robotnik nie prowadzi budowy.',
      'workerAssignmentUnavailable':
          'Nie można przypisać robotnika do tego pola.',
      'workerAssignmentNotActive': 'Robotnik nie ma aktywnego przypisania.',
      'workerRoadUnavailable': 'Nie można tutaj zbudować drogi.',
      'roadConstructionExistingRoad': 'Na tym polu jest już droga.',
      'roadConstructionCity': 'Nie można budować drogi w centrum miasta.',
      'roadConstructionEnemyTerritory':
          'Nie można budować drogi na terenie wroga.',
      'roadConstructionImpassableTerrain':
          'Na tym terenie nie można zbudować drogi.',
      'workerAutomationNotActive': 'Automatyzacja robotnika nie jest aktywna.',
      'workerAutomationNoTarget': 'Automatyzacja nie znalazła celu.',
      'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
      'other': 'Nie udało się wykonać żądania robotnika.',
    });
    return '$_temp0';
  }

  @override
  String productionText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Produkcja i zasoby',
      'loading': 'Ładowanie opcji produkcji',
      'executing': 'Aktualizacja produkcji miasta',
      'current': 'Bieżąca produkcja',
      'invested': 'Zainwestowano',
      'overflow': 'Nadwyżka',
      'resources': 'Zasoby strategiczne',
      'buildings': 'Budynki',
      'units': 'Jednostki',
      'projects': 'Projekty',
      'wonders': 'Cuda',
      'specializations': 'Specjalizacje',
      'rush': 'Przyspiesz produkcję',
      'cost': 'koszt',
      'requires': 'wymaga',
      'empty': 'Brak dostępnych opcji.',
      'other': 'Produkcja',
    });
    return '$_temp0';
  }

  @override
  String productionFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Nie udało się wykonać żądania produkcji.',
      'responseIncompatible': 'Odpowiedź produkcji jest niezgodna z klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'staleRevision': 'Miasto uległo zmianie. Sprawdź produkcję ponownie.',
      'matchFinished': 'Rozgrywka już się zakończyła.',
      'cityNotFound': 'Miasto nie jest już dostępne.',
      'cityNotControlled': 'Miasto nie należy do tego gracza.',
      'buildingNotAvailable': 'Ten budynek jest niedostępny.',
      'unitProductionInvalidResourceOption':
          'Ta opcja zasobów jest nieprawidłowa.',
      'unitProductionNotAvailable': 'Ta jednostka jest niedostępna.',
      'unitProductionRequiresResource': 'Wybierz opcję zasobów.',
      'unitProductionMissingStrategicResource': 'Brakuje wymaganych zasobów.',
      'unitProductionRequiresCoast': 'Ta jednostka wymaga miasta nadbrzeżnego.',
      'unitSupplyLimitReached': 'Osiągnięto limit jednostek.',
      'wonderNotAvailable': 'Ten cud jest niedostępny.',
      'citySpecializationLocked': 'Ta specjalizacja jest zablokowana.',
      'citySpecializationUnchanged': 'Ta specjalizacja jest już aktywna.',
      'citySpecializationMissingBuilding': 'Brakuje wymaganego budynku.',
      'productionQueueEmpty': 'Kolejka produkcji jest pusta.',
      'projectCannotBeRushed': 'Nie można przyspieszyć projektu ciągłego.',
      'rushProductionUnavailable': 'Przyspieszenie produkcji jest niedostępne.',
      'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
      'other': 'Nie udało się wykonać żądania produkcji.',
    });
    return '$_temp0';
  }

  @override
  String artifactText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Artefakty świata',
      'executing': 'Wykonywanie akcji artefaktu',
      'startExcavation': 'Rozpocznij wykopaliska',
      'storeInCity': 'Umieść w mieście',
      'trade': 'Wymień artefakt',
      'targetPlayer': 'Gracz docelowy',
      'offeredGold': 'Oferowane złoto',
      'onMap': 'Na mapie',
      'carried': 'Niesiony przez',
      'stored': 'Przechowywany w',
      'excavation': 'Wykopaliska',
      'turnsRemaining': 'pozostało tur',
      'other': 'Artefakt',
    });
    return '$_temp0';
  }

  @override
  String artifactName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ancientImperialCrown': 'Starożytna korona cesarska',
      'astronomersTablets': 'Tablice astronoma',
      'prophetMask': 'Maska proroka',
      'heroSword': 'Miecz bohatera',
      'merchantsSeal': 'Pieczęć kupca',
      'firstPeoplesChronicle': 'Kronika pierwszych ludów',
      'templeReliquary': 'Relikwiarz świątynny',
      'queensMirror': 'Lustro królowej',
      'other': 'Artefakt świata',
    });
    return '$_temp0';
  }

  @override
  String artifactOnMap(int col, int row) {
    return 'Na mapie: $col, $row';
  }

  @override
  String artifactCarriedBy(String unitName) {
    return 'Niesiony przez: $unitName';
  }

  @override
  String artifactStoredIn(String cityName) {
    return 'Przechowywany w: $cityName';
  }

  @override
  String artifactExcavationAt(int col, int row, int remainingTurns) {
    return 'Wykopaliska: $col, $row · pozostało tur: $remainingTurns';
  }

  @override
  String artifactFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Nie udało się wykonać żądania artefaktu.',
      'responseIncompatible': 'Odpowiedź artefaktu jest niezgodna z klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'staleRevision': 'Stan gry uległ zmianie. Sprawdź artefakt ponownie.',
      'matchFinished': 'Rozgrywka już się zakończyła.',
      'unitNotFound': 'Jednostka nie jest już dostępna.',
      'unitNotControlled': 'Jednostka nie należy do tego gracza.',
      'unitUnavailable': 'Jednostka jest niedostępna.',
      'unitAlreadyCarryingArtifact': 'Jednostka już niesie artefakt.',
      'artifactNotFound': 'Artefakt nie jest już dostępny.',
      'unitNotCarryingArtifact': 'Jednostka nie niesie artefaktu.',
      'cityNotFound': 'Miasto nie jest już dostępne.',
      'cityNotControlled': 'Miasto nie należy do tego gracza.',
      'unitNotInCity': 'Jednostka nie znajduje się w tym mieście.',
      'cityArtifactSlotFull': 'Miejsce na artefakt w mieście jest zajęte.',
      'artifactTradeActorUnavailable':
          'Ten gracz nie może wymieniać artefaktów.',
      'artifactTradeTargetInvalid': 'Gracz docelowy jest nieprawidłowy.',
      'artifactTradeGoldInvalid': 'Oferta złota jest nieprawidłowa.',
      'artifactTradeBlockedByWar':
          'Wymiana artefaktów jest zablokowana przez wojnę.',
      'artifactTradeGoldUnavailable': 'Oferowane złoto jest niedostępne.',
      'offeredArtifactUnavailable': 'Oferowany artefakt jest niedostępny.',
      'targetArtifactSlotUnavailable':
          'Gracz docelowy nie ma miejsca na artefakt.',
      'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
      'other': 'Nie udało się wykonać żądania artefaktu.',
    });
    return '$_temp0';
  }

  @override
  String researchText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'recommendations': 'Rekomendacje',
      'title': 'Badania',
      'open': 'Otwórz badania',
      'close': 'Zamknij badania',
      'loading': 'Ładowanie opcji badań',
      'retry': 'Ponów',
      'selecting': 'Wybieranie technologii',
      'selectionRequired': 'Wybierz technologię, aby kontynuować',
      'sciencePerTurn': 'Nauka na turę',
      'overflow': 'Zachowana nauka',
      'active': 'Aktywna technologia',
      'none': 'Brak',
      'cost': 'Koszt',
      'progress': 'Postęp',
      'boost': 'Rabat za premię',
      'prerequisites': 'Wymagania',
      'blockedBy': 'Blokowane przez',
      'unlocks': 'Odblokowuje',
      'choose': 'Wybierz',
      'tree': 'Drzewo technologii',
      'catalog': 'Katalog badań',
      'backToTree': 'Powrót do drzewa',
      'treeUnavailable': 'Diagram zależności jest niedostępny.',
      'other': 'Badania',
    });
    return '$_temp0';
  }

  @override
  String researchAvailability(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unlocked': 'Zbadana',
      'active': 'Aktywna',
      'available': 'Dostępna',
      'lockedByPrerequisites': 'Wymaga wcześniejszych technologii',
      'lockedByTechnology': 'Zablokowana przez technologię',
      'other': 'Niedostępna',
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
      'requestFailed': 'Nie udało się wykonać żądania badań.',
      'responseIncompatible': 'Odpowiedź badań jest niezgodna z klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'staleRevision': 'Stan badań uległ zmianie. Sprawdź opcje ponownie.',
      'technologyPlayerNotControlled': 'Ten gracz nie może wybrać badań.',
      'technologyNotAvailable': 'Ta technologia jest niedostępna.',
      'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
      'other': 'Nie udało się wykonać żądania badań.',
    });
    return '$_temp0';
  }

  @override
  String diplomacyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Dyplomacja',
      'open': 'Otwórz dyplomację',
      'close': 'Zamknij dyplomację',
      'noContacts': 'Brak kontaktów',
      'compose': 'Nowa akcja',
      'target': 'Kontrahent',
      'action': 'Akcja',
      'send': 'Wyślij',
      'invalid': 'Sprawdź warunki formularza.',
      'pending': 'Wysyłanie akcji dyplomatycznej',
      'relations': 'Relacje',
      'proposals': 'Propozycje',
      'messages': 'Wiadomości prywatne',
      'agreements': 'Umowy zasobowe',
      'accept': 'Akceptuj',
      'reject': 'Odrzuć',
      'amount': 'Kwota',
      'goldPerTurn': 'Złoto na turę',
      'duration': 'Liczba tur',
      'resource': 'Zasób',
      'offered': 'Oferowany zasób',
      'requested': 'Żądany zasób',
      'topic': 'Temat',
      'other': 'Dyplomacja',
    });
    return '$_temp0';
  }

  @override
  String diplomacyFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'Nie udało się wykonać akcji dyplomatycznej.',
      'responseIncompatible': 'Odpowiedź dyplomacji jest niezgodna z klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'staleRevision': 'Stan dyplomacji się zmienił. Sprawdź go ponownie.',
      'matchFinished': 'Rozgrywka już się zakończyła.',
      'diplomacyPlayerNotControlled':
          'Ten gracz nie może prowadzić dyplomacji.',
      'diplomacyTargetNotDiscovered': 'Ten kontrahent jest niedostępny.',
      'diplomacyProposalNotAllowed': 'Ta propozycja jest niedozwolona.',
      'diplomacyDuplicateProposal': 'Taka propozycja już istnieje.',
      'diplomacyProposalNotFound': 'Ta propozycja już nie istnieje.',
      'diplomacyProposalPaymentUnavailable':
          'Płatność propozycji jest niedostępna.',
      'diplomacyMessageCooldown': 'Podobną wiadomość wysłano zbyt niedawno.',
      'diplomacyDuplicateMessage': 'Taka wiadomość już istnieje.',
      'diplomacyMessageNotFound': 'Ta wiadomość już nie istnieje.',
      'diplomacyMessageUnavailable': 'Tej wiadomości nie można teraz użyć.',
      'diplomacyTruceActive': 'Obowiązuje rozejm.',
      'diplomacyWarAlreadyActive': 'Wojna już trwa.',
      'diplomacyInvalidGoldAmount': 'Kwota złota jest nieprawidłowa.',
      'diplomacyGoldGiftBlockedByRelation': 'Ta relacja blokuje dar złota.',
      'diplomacyGoldUnavailable': 'Wymagane złoto jest niedostępne.',
      'diplomacyGoldGiftUnavailable': 'Ten dar złota jest niedostępny.',
      'invalidResourceTradeTarget': 'Cel handlu zasobami jest nieprawidłowy.',
      'invalidResourceTradeResource': 'Wybrany zasób jest nieprawidłowy.',
      'invalidResourceTradeTerms': 'Warunki handlu zasobami są nieprawidłowe.',
      'resourceTradeBlockedByWar': 'Wojna blokuje ten handel zasobami.',
      'resourceTradeGoldUnavailable': 'Złoto dla handlu jest niedostępne.',
      'resourceTradeAlreadyActive': 'Taki handel zasobami już trwa.',
      'invalidResourceTradeAgreementId':
          'Identyfikator umowy jest nieprawidłowy.',
      'resourceTradeAgreementIdConflict': 'Identyfikator umowy jest zajęty.',
      'resourceTradeExportUnavailable': 'Eksport zasobu jest niedostępny.',
      'resourceTradeOfferUnavailable': 'Oferowany zasób jest niedostępny.',
      'resourceTradeRequestUnavailable': 'Żądany zasób jest niedostępny.',
      'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
      'other': 'Nie udało się wykonać akcji dyplomatycznej.',
    });
    return '$_temp0';
  }

  @override
  String presentationName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'farm': 'Gospodarstwo',
      'riverFarm': 'Gospodarstwo rzeczne',
      'mine': 'Kopalnia',
      'lumberMill': 'Tartak',
      'pasture': 'Pastwisko',
      'camp': 'Obóz',
      'quarry': 'Kamieniołom',
      'fishingBoats': 'Łodzie rybackie',
      'orchard': 'Sad',
      'plantation': 'Plantacja',
      'vineyard': 'Winnica',
      'tradingPost': 'Faktoria handlowa',
      'prospectorCamp': 'Obóz poszukiwaczy',
      'horseRanch': 'Stadnina',
      'pearlDivers': 'Poławiacze pereł',
      'coalShaft': 'Szyb węglowy',
      'oilWell': 'Szyb naftowy',
      'bauxiteMine': 'Kopalnia boksytu',
      'uraniumMine': 'Kopalnia uranu',
      'wheat': 'Pszenica',
      'fish': 'Ryby',
      'deer': 'Jelenie',
      'sheep': 'Owce',
      'rice': 'Ryż',
      'cow': 'Krowy',
      'apple': 'Jabłka',
      'banana': 'Banany',
      'citrus': 'Cytrusy',
      'gold': 'Złoto',
      'silver': 'Srebro',
      'gems': 'Klejnoty',
      'silk': 'Jedwab',
      'spices': 'Przyprawy',
      'cotton': 'Bawełna',
      'grapes': 'Winogrona',
      'ivory': 'Kość słoniowa',
      'pearls': 'Perły',
      'coffee': 'Kawa',
      'cocoa': 'Kakao',
      'tobacco': 'Tytoń',
      'sugar': 'Cukier',
      'iron': 'Żelazo',
      'coal': 'Węgiel',
      'oil': 'Ropa',
      'aluminium': 'Aluminium',
      'uranium': 'Uran',
      'horses': 'Konie',
      'marble': 'Marmur',
      'commander': 'Dowódca',
      'warrior': 'Wojownik',
      'archer': 'Łucznik',
      'settler': 'Osadnik',
      'worker': 'Robotnik',
      'merchant': 'Kupiec',
      'scout': 'Zwiadowca',
      'spearman': 'Włócznik',
      'cavalry': 'Kawaleria',
      'catapult': 'Katapulta',
      'heavyInfantry': 'Ciężka piechota',
      'fieldCannon': 'Działo polowe',
      'rifleman': 'Strzelec',
      'tank': 'Czołg',
      'scoutShip': 'Okręt zwiadowczy',
      'warship': 'Okręt wojenny',
      'reconPlane': 'Samolot rozpoznawczy',
      'building': 'Budynek',
      'improvement': 'Ulepszenie',
      'resourceVisibility': 'Widoczność zasobu',
      'unit': 'Jednostka',
      'wonder': 'Cud',
      'friendly': 'Przyjazne',
      'neutral': 'Neutralne',
      'hostile': 'Wrogie',
      'truce': 'Rozejm',
      'war': 'Wojna',
      'warning': 'Ostrzeżenie',
      'complaint': 'Skarga',
      'request': 'Prośba',
      'praise': 'Pochwała',
      'threat': 'Groźba',
      'cooperation': 'Współpraca',
      'troopsNearCities': 'Wojska w pobliżu miast',
      'citiesTooClose': 'Miasta zbyt blisko',
      'blockedRoutes': 'Zablokowane szlaki',
      'withdrawScouts': 'Wycofaj zwiadowców',
      'avoidEscalation': 'Unikaj eskalacji',
      'commonEnemy': 'Wspólny wróg',
      'expansionProvocation': 'Prowokacja ekspansją',
      'peacefulPraise': 'Pochwała pokoju',
      'conciliatory': 'Pojednawcza',
      'evasive': 'Wymijająca',
      'aggressive': 'Agresywna',
      'declareWar': 'Wypowiedz wojnę',
      'goldGift': 'Dar złota',
      'friendshipProposal': 'Propozycja przyjaźni',
      'truceProposal': 'Propozycja rozejmu',
      'message': 'Wiadomość',
      'resourceTrade': 'Handel zasobami',
      'resourceExchange': 'Wymiana zasobów',
      'granary': 'Spichlerz',
      'workshop': 'Warsztat',
      'industry': 'Przemysł',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String technologyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'agriculture': 'Rolnictwo',
      'woodworking': 'Obróbka drewna',
      'mining': 'Górnictwo',
      'animalHusbandry': 'Hodowla zwierząt',
      'hunting': 'Łowiectwo',
      'fishing': 'Rybołówstwo',
      'craftsmanship': 'Rzemiosło',
      'trade': 'Handel',
      'storage': 'Magazynowanie',
      'waterEngineering': 'Inżynieria wodna',
      'stoneworking': 'Kamieniarstwo',
      'militaryOrganization': 'Organizacja wojskowa',
      'advancedTrade': 'Zaawansowany handel',
      'construction': 'Budownictwo',
      'navigation': 'Nawigacja',
      'irrigation': 'Irygacja',
      'banking': 'Bankowość',
      'engineering': 'Inżynieria',
      'metallurgy': 'Metalurgia',
      'horsebackRiding': 'Jeździectwo',
      'ironWorking': 'Obróbka żelaza',
      'coalMining': 'Górnictwo węgla',
      'machinery': 'Maszyny',
      'administration': 'Administracja',
      'logistics': 'Logistyka',
      'shipbuilding': 'Okrętownictwo',
      'tactics': 'Taktyka',
      'economy': 'Gospodarka',
      'urbanization': 'Urbanizacja',
      'fortifications': 'Fortyfikacje',
      'strategy': 'Strategia',
      'specialization': 'Specjalizacja',
      'writing': 'Pismo',
      'mathematics': 'Matematyka',
      'medicine': 'Medycyna',
      'civilService': 'Służba cywilna',
      'siegecraft': 'Sztuka oblężnicza',
      'cartography': 'Kartografia',
      'guilds': 'Cechy',
      'law': 'Prawo',
      'education': 'Edukacja',
      'urbanPlanning': 'Planowanie miejskie',
      'navalDoctrine': 'Doktryna morska',
      'steel': 'Stal',
      'bureaucracy': 'Biurokracja',
      'nationalism': 'Nacjonalizm',
      'scientificMethod': 'Metoda naukowa',
      'steamPower': 'Energia parowa',
      'electricity': 'Elektryczność',
      'combustion': 'Silnik spalinowy',
      'flight': 'Lotnictwo',
      'massProduction': 'Produkcja masowa',
      'radio': 'Radio',
      'nuclearPhysics': 'Fizyka jądrowa',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String cityContentName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'growth': 'Wzrost',
      'industry': 'Przemysł',
      'commerce': 'Handel',
      'science': 'Nauka',
      'military': 'Wojsko',
      'wealth': 'Bogactwo',
      'research': 'Badania',
      'granary': 'Spichlerz',
      'waterMill': 'Młyn wodny',
      'workshop': 'Warsztat',
      'storehouse': 'Magazyn',
      'housing': 'Zabudowa mieszkaniowa',
      'merchantHall': 'Hala kupiecka',
      'stonemason': 'Zakład kamieniarski',
      'barracks': 'Koszary',
      'marketplace': 'Targowisko',
      'port': 'Port',
      'aqueduct': 'Akwedukt',
      'forge': 'Kuźnia',
      'stable': 'Stajnia',
      'bank': 'Bank',
      'buildersGuild': 'Cech budowniczych',
      'factory': 'Fabryka',
      'lighthouse': 'Latarnia morska',
      'trainingGrounds': 'Plac ćwiczeń',
      'townHall': 'Ratusz',
      'monument': 'Pomnik',
      'archive': 'Archiwum',
      'academy': 'Akademia',
      'university': 'Uniwersytet',
      'observatory': 'Obserwatorium',
      'laboratory': 'Laboratorium',
      'reactor': 'Reaktor',
      'courthouse': 'Sąd',
      'court': 'Dwór',
      'governorsOffice': 'Urząd gubernatora',
      'surveyorsOffice': 'Urząd geodetów',
      'planningOffice': 'Biuro planowania',
      'apothecary': 'Apteka',
      'publicBaths': 'Łaźnie publiczne',
      'hospital': 'Szpital',
      'ministries': 'Ministerstwa',
      'walls': 'Mury',
      'armory': 'Zbrojownia',
      'siegeWorkshop': 'Warsztat oblężniczy',
      'citadel': 'Cytadela',
      'warCollege': 'Akademia wojenna',
      'conscriptionOffice': 'Biuro poboru',
      'borderFort': 'Fort graniczny',
      'airfield': 'Lotnisko',
      'artisansGuild': 'Cech rzemieślników',
      'masterWorkshop': 'Warsztat mistrzowski',
      'steelworks': 'Huta stali',
      'railDepot': 'Zajezdnia kolejowa',
      'powerPlant': 'Elektrownia',
      'assemblyPlant': 'Montownia',
      'refinery': 'Rafineria',
      'mapRoom': 'Sala map',
      'shipyard': 'Stocznia',
      'dryDock': 'Suchy dok',
      'navalAcademy': 'Akademia morska',
      'harborCustoms': 'Urząd celny portu',
      'museum': 'Muzeum',
      'parliament': 'Parlament',
      'broadcastTower': 'Wieża nadawcza',
      'worldFairGrounds': 'Tereny wystawy światowej',
      'greatLibrary': 'Wielka Biblioteka',
      'hangingGardens': 'Wiszące Ogrody',
      'greatWall': 'Wielki Mur',
      'petra': 'Petra',
      'centralBank': 'Bank Centralny',
      'imperialUniversity': 'Uniwersytet Cesarski',
      'grandCathedral': 'Wielka Katedra',
      'motherFactory': 'Fabryka Matka',
      'nationalObservatory': 'Obserwatorium Narodowe',
      'svalbardSeedVault': 'Globalny Bank Nasion na Svalbardzie',
      'grandExposition': 'Wielka Wystawa',
      'other': 'Nieznana zawartość miasta',
    });
    return '$_temp0';
  }

  @override
  String diplomaticProposalName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'friendship': 'Przyjaźń',
      'truce': 'Rozejm',
      'other': 'Nieznana propozycja',
    });
    return '$_temp0';
  }

  @override
  String mapFeedbackText(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'roadCompleted': '+Droga',
      'unitKilled': 'KO',
      'unitRetreated': 'Odwrót',
      'artifactExcavationStarted': 'Wykop',
      'artifactCarried': 'Artefakt przenoszony',
      'artifactStored': 'Artefakt w mieście',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String mapYieldShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'food': 'ŻYW',
      'production': 'PROD',
      'gold': 'ZŁ',
      'defense': 'DEF',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get focusOwnUnitMovement => 'Kieruj kamerę na ruch mojej jednostki';

  @override
  String get followOwnUnitMovement => 'Śledź ruch mojej jednostki kamerą';

  @override
  String get focusForeignUnitMovement =>
      'Kieruj kamerę na ruch jednostki wroga';

  @override
  String get followForeignUnitMovement => 'Śledź ruch jednostki wroga kamerą';

  @override
  String get gameSoundsLabel => 'Dźwięki gry';

  @override
  String get soundVolumeLabel => 'Głośność dźwięków';

  @override
  String get gameMusicLabel => 'Muzyka w grze';

  @override
  String get musicVolumeLabel => 'Głośność muzyki';

  @override
  String get natureSoundsLabel => 'Odgłosy natury';

  @override
  String get natureVolumeLabel => 'Głośność natury';

  @override
  String hexInspectionKind(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite': 'Idealne pod miasto',
      'goodCitySite': 'Dobre pod miasto',
      'fertileField': 'Żyzne pole',
      'fertilePlains': 'Żyzna równina',
      'richPlain': 'Bogata równina',
      'strategicBorderland': 'Strategiczne pogranicze',
      'strategicField': 'Pole strategiczne',
      'defensivePosition': 'Pozycja obronna',
      'fertileForest': 'Żyzny las',
      'forestBackline': 'Leśne zaplecze',
      'forestForge': 'Leśna kuźnia',
      'wildLand': 'Dziki teren',
      'richWilds': 'Bogata dzicz',
      'exoticBackline': 'Egzotyczne zaplecze',
      'difficultStrategicTerrain': 'Trudny teren strategiczny',
      'highGround': 'Wysoka pozycja',
      'riverHills': 'Wzgórza nad rzeką',
      'industrialStronghold': 'Twierdza przemysłowa',
      'richHills': 'Bogate wzgórza',
      'barrenLand': 'Jałowy teren',
      'oasis': 'Oaza',
      'tradeOasis': 'Oaza handlowa',
      'desertDeposits': 'Pustynne złoża',
      'harshLand': 'Surowy teren',
      'coldPastures': 'Zimne pastwiska',
      'resourceOutpost': 'Surowcowa placówka',
      'hostileLand': 'Nieprzyjazny teren',
      'arcticDeposits': 'Arktyczne złoża',
      'coast': 'Wybrzeże',
      'fishingCoast': 'Rybackie wybrzeże',
      'richCoast': 'Bogate wybrzeże',
      'riverPort': 'Portowe ujście',
      'regionalPortHeart': 'Portowe serce regionu',
      'openSea': 'Otwarte morze',
      'naturalBarrier': 'Naturalna bariera',
      'promisingLand': 'Obiecujący teren',
      'weakLand': 'Słaby teren',
      'ordinaryLand': 'Zwykły teren',
      'mapTile': 'Pole mapy',
      'other': 'Pole mapy',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionDescription(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite':
          'Bardzo mocne miejsce pod osadę: żywność, wzrost i przestrzeń rozwoju są już w jednym pakiecie.',
      'goodCitySite':
          'Solidny teren pod centrum miasta, z dość dobrą bazą pod wczesny rozwój.',
      'fertileField':
          'Trawiaste pole nad rzeką, dobre pod żywność, populację i pracę robotnika.',
      'fertilePlains':
          'Otwarte równiny z rzeką, przydatne do zbalansowania żywności i produkcji.',
      'richPlain':
          'Wartościowe otwarte pole z luksusem albo handlem, warte objęcia granicami.',
      'strategicBorderland':
          'Dobry teren o znaczeniu strategicznym, przydatny zanim zajmie go rywal.',
      'strategicField':
          'Równinne pole powiązane z zasobem strategicznym lub presją na granicy.',
      'defensivePosition':
          'Teren wzmacniający kontrolę obronną i utrzymanie pobliskich podejść.',
      'fertileForest':
          'Las z dostępem do rzeki, łączący potencjał wzrostu z naturalną osłoną.',
      'forestBackline':
          'Bezpieczniejszy leśny heks, dobry pod zaplecze lub ulepszenia łowieckie.',
      'forestForge':
          'Las z zasobem przemysłowym, obiecujący pod produkcję po ulepszeniu.',
      'wildLand':
          'Gęsty i trudniejszy teren; opłaca się dopiero z jasnym planem robotnika lub ekspansji.',
      'richWilds':
          'Dziki teren z dość dobrą żyznością albo zasobami, wart ostrożnego rozwoju.',
      'exoticBackline':
          'Dżungla lub mokradła z wartością luksusową dla późniejszych granic i handlu.',
      'difficultStrategicTerrain':
          'Trudny teren z zasobem strategicznym; mocny później, niewygodny na starcie.',
      'highGround':
          'Wzgórza lepsze do obrony i kontroli mapy niż do szybkiego wzrostu.',
      'riverHills':
          'Wzgórza nad rzeką, łączące obronę z lepszym potencjałem ekonomicznym.',
      'industrialStronghold':
          'Wzgórza z zasobami przemysłowymi, mocny cel produkcyjny dla miasta.',
      'richHills':
          'Bogate wzgórza przydatne pod złoto albo ekspansję nastawioną na produkcję.',
      'barrenLand':
          'Suchy teren o małej wartości natychmiastowej, chyba że plan zmienią technologie lub granice.',
      'oasis':
          'Pustynia złagodzona rzeką, zmieniająca słabe pole w użyteczny heks wzrostu.',
      'tradeOasis':
          'Pustynna kieszeń handlowa, która może zyskać wartość po właściwym ulepszeniu.',
      'desertDeposits':
          'Słaby teren osadniczy ze złożem strategicznym ważniejszym w późniejszych erach.',
      'harshLand':
          'Zimny albo surowy teren z ograniczoną ekonomią i wolnym rozwojem na starcie.',
      'coldPastures':
          'Zimny teren z pastwiskową wartością wystarczającą dla miasta granicznego.',
      'resourceOutpost':
          'Odległy zimny teren wart zajęcia głównie przez chroniony zasób.',
      'hostileLand':
          'Nieprzyjazny teren o słabej wartości osadniczej i małym zwrocie na starcie.',
      'arcticDeposits':
          'Śnieżne złoża trudne w użyciu, ale ważne strategicznie.',
      'coast': 'Wybrzeże otwierające dostęp morski i elastyczny rozwój miasta.',
      'fishingCoast':
          'Wybrzeże z żywnością, dobry powód do pracy pola albo osady przy wodzie.',
      'richCoast':
          'Wybrzeże z luksusem lub handlem, warte włączenia do granic miasta.',
      'riverPort':
          'Ujście rzeki z wartością handlową i ruchową dla miasta nad wodą.',
      'regionalPortHeart':
          'Mocne centrum portowe, gdzie rzeka i zasoby nakładają się na siebie.',
      'openSea':
          'Woda przydatna dla statków i zwiadu, ale nie dla osadnictwa lądowego.',
      'naturalBarrier':
          'Blokujący teren, który kształtuje ruch i obronę bardziej niż ekonomię.',
      'promisingLand':
          'Ogólnie użyteczne pole z wartością, którą warto sprawdzić przed ruchem dalej.',
      'weakLand':
          'Nisko opłacalny teren, który rzadko zasługuje na wczesny czas robotnika.',
      'ordinaryLand':
          'Zwykłe pole bez wyraźnej przewagi, użyteczne gdy pasuje do planu miasta.',
      'mapTile':
          'Zwykłe pole mapy bez dość mocnych danych do jednoznacznej oceny.',
      'other':
          'Zwykłe pole mapy bez dość mocnych danych do jednoznacznej oceny.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendation(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity': 'Dobra lokacja pod rozwój',
      'defendHere': 'Dobra pozycja obronna',
      'exploitEconomy': 'Warto eksploatować',
      'avoid': 'Lepiej ominąć bez planu',
      'neutral': 'Sprawdź przed ruchem',
      'other': 'Sprawdź przed ruchem',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendationDetail(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity':
          'Jeśli granice są wolne, rozważ założenie miasta albo skierowanie tu osadnika.',
      'defendHere':
          'Użyj jako punktu oparcia dla jednostek, granic lub obrony pobliskiego miasta.',
      'exploitEconomy':
          'Warto objąć granicami i wysłać robotnika, gdy miasto może skorzystać z yieldu.',
      'avoid':
          'Na początku pomiń, chyba że zasób, trasa albo potrzeba militarna zmienia ocenę.',
      'neutral':
          'Odkryj sąsiednie pola i porównaj zasoby, zanim poświęcisz ruch lub robotnika.',
      'other':
          'Odkryj sąsiednie pola i porównaj zasoby, zanim poświęcisz ruch lub robotnika.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Inspekcja heksu',
      'close': 'Zamknij inspekcję',
      'loading': 'Odczytywanie heksu…',
      'requestFailed': 'Nie udało się odczytać heksu. Spróbuj ponownie.',
      'responseIncompatible': 'Odpowiedź inspekcji heksu jest niezgodna.',
      'sessionUnavailable': 'Sesja gry jest niedostępna.',
      'description': 'Opis',
      'terrain': 'Teren',
      'resources': 'Zasoby',
      'none': 'Brak',
      'height': 'Wysokość',
      'improvements': 'Możliwe ulepszenia',
      'noImprovements': 'Brak pasujących ulepszeń.',
      'fromStart': 'Dostępne od początku',
      'unlocked': 'Technologia odkryta',
      'locked': 'Wymagana technologia',
      'riverBonus': 'Premia rzeki',
      'defenseBonus': 'Teren obronny',
      'outsideCity': 'Poza granicami kontrolowanego miasta',
      'cityCenter': 'Centrum miasta',
      'alreadyImproved': 'Ten heks jest już ulepszony',
      'objective': 'Cel mapy',
      'other': 'Inspekcja heksu',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionCity(String city) {
    return 'Pracuje dla miasta $city';
  }

  @override
  String hexInspectionBuildTurns(int turns) {
    return 'Czas budowy: $turns tur';
  }

  @override
  String hexInspectionTerrain(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'ocean': 'Ocean',
      'coast': 'Wybrzeże',
      'lake': 'Jezioro',
      'plains': 'Równiny',
      'grassland': 'Łąki',
      'desert': 'Pustynia',
      'tundra': 'Tundra',
      'snow': 'Śnieg',
      'mountain': 'Góra',
      'hills': 'Wzgórza',
      'wetlands': 'Mokradła',
      'jungle': 'Dżungla',
      'forest': 'Las',
      'river': 'Rzeka',
      'other': 'Równiny',
    });
    return '$_temp0';
  }

  @override
  String get gamepadSettings => 'Gamepad';

  @override
  String get gamepadEnabled => 'Wejście gamepada';

  @override
  String get gamepadDeadzone => 'Martwa strefa gamepada';

  @override
  String get gamepadCameraSensitivity => 'Czułość kamery gamepada';

  @override
  String get gamepadInvertCameraY => 'Odwróć oś Y kamery gamepada';

  @override
  String get gamepadButtonBindings => 'Przypisania przycisków';

  @override
  String get gamepadAxisBindings => 'Przypisania osi';

  @override
  String get gamepadResetBindings => 'Przywróć przypisania';

  @override
  String get gamepadUnassigned => 'Bez przypisania';

  @override
  String gamepadAssignedTo(String action) {
    return 'Przypisano do: $action';
  }

  @override
  String get gamepadActionConfirm => 'Potwierdź';

  @override
  String get gamepadActionCancel => 'Anuluj';

  @override
  String get gamepadActionMoveMode => 'Tryb ruchu';

  @override
  String get gamepadActionInspect => 'Inspekcja pola';

  @override
  String get gamepadActionHudPrevious => 'Poprzednia sekcja HUD';

  @override
  String get gamepadActionHudNext => 'Następna sekcja HUD';

  @override
  String get gamepadActionPrevious => 'Poprzednie oczekujące działanie';

  @override
  String get gamepadActionNext => 'Następne oczekujące działanie';

  @override
  String get gamepadActionPrimary => 'Główna akcja';

  @override
  String get gamepadActionUp => 'D-pad w górę';

  @override
  String get gamepadActionDown => 'D-pad w dół';

  @override
  String get gamepadActionLeft => 'D-pad w lewo';

  @override
  String get gamepadActionRight => 'D-pad w prawo';

  @override
  String get gamepadActionZoomIn => 'Przybliż';

  @override
  String get gamepadActionZoomOut => 'Oddal';

  @override
  String get gamepadActionCursorX => 'Kursor X';

  @override
  String get gamepadActionCursorY => 'Kursor Y';

  @override
  String get gamepadActionCameraX => 'Kamera X';

  @override
  String get gamepadActionCameraY => 'Kamera Y';

  @override
  String get gamepadControlHome => 'Home';

  @override
  String get gamepadControlTouchpad => 'Panel dotykowy';

  @override
  String get gamepadControlLeftStickX => 'Lewy drążek X';

  @override
  String get gamepadControlLeftStickY => 'Lewy drążek Y';

  @override
  String get gamepadControlRightStickX => 'Prawy drążek X';

  @override
  String get gamepadControlRightStickY => 'Prawy drążek Y';

  @override
  String get gamepadControlLeftTrigger => 'Lewy trigger (LT)';

  @override
  String get gamepadControlRightTrigger => 'Prawy trigger (RT)';

  @override
  String get keyboardSettings => 'Klawiatura';

  @override
  String get keyboardScope =>
      'Skróty mapy działają, gdy mapa ma fokus klawiatury. Kliknij mapę, aby przywrócić jej fokus.';

  @override
  String get keyboardPanKeys => 'W / A / S / D lub strzałki';

  @override
  String get keyboardPan => 'Przesuń kamerę';

  @override
  String get keyboardSelect =>
      'Wybierz heks pod kursorem lub bieżące zaznaczenie';

  @override
  String get keyboardMove =>
      'Włącz lub wyłącz wskazywanie celu ruchu zaznaczonej jednostki';

  @override
  String get keyboardInspect =>
      'Sprawdź heks pod kursorem, zaznaczony heks lub środek widoku';

  @override
  String get keyboardMapMode =>
      'Przełącz widok mapy między graficznym a kafelkowym';

  @override
  String get keyboardPending => 'Poprzednia / następna czynność w turze';

  @override
  String get keyboardSpace => 'Spacja';

  @override
  String get keyboardPrimary =>
      'Przejdź do następnej czynności; zakończ turę, gdy nie ma już żadnej';

  @override
  String get keyboardCancel =>
      'Zamknij aktywny panel lub anuluj bieżącą interakcję';

  @override
  String get keyboardFocus => 'Przejdź do następnej / poprzedniej kontrolki';

  @override
  String get textSize => 'Wielkość tekstu';

  @override
  String get textSizeDescription =>
      'Powiększenie stosowane dodatkowo do wielkości tekstu ustawionej w systemie.';

  @override
  String get textScaleStandard => 'Standardowy (100%)';

  @override
  String get textScaleLarge => 'Duży (115%)';

  @override
  String get textScaleExtraLarge => 'Bardzo duży (130%)';

  @override
  String get languageSettings => 'Język';

  @override
  String get languageSystem => 'Język systemowy';

  @override
  String get windowSettingsTitle => 'Okno';

  @override
  String get windowModeFullscreen => 'Pełny ekran';

  @override
  String get windowModeWindowed => 'W oknie';

  @override
  String get windowSettingsBusy => 'Zmienianie trybu okna…';

  @override
  String windowSettingsFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'load': 'Nie udało się wczytać ustawień okna. Wybrano tryb domyślny.',
      'apply': 'Nie udało się zmienić trybu okna. Spróbuj wybrać go ponownie.',
      'save':
          'Nie udało się zapisać ustawienia okna. Spróbuj wybrać tryb ponownie.',
      'restore':
          'Nie udało się przywrócić poprzedniego trybu okna. Wybierz tryb ponownie.',
      'other': 'Nie udało się zakończyć operacji okna.',
    });
    return '$_temp0';
  }

  @override
  String get automationSettings => 'Automatyzacja';

  @override
  String get advanceActions => 'Przechodź do następnej czynności';

  @override
  String get advanceActionsDescription =>
      'Po wykonaniu czynności wybierz następną jednostkę, miasto lub badanie wymagające uwagi.';

  @override
  String get automaticEndTurn => 'Kończ tury automatycznie';

  @override
  String get automaticEndTurnDescription =>
      'Zakończ turę, gdy nie ma już czynności do wykonania. Ręczny wybór i otwarte panele wstrzymują automatyzację.';

  @override
  String get performanceSettings => 'Wydajność';

  @override
  String get showFps => 'Pokaż FPS';

  @override
  String get showFpsDescription =>
      'Pokazuj liczbę klatek na sekundę w całej aplikacji.';

  @override
  String get showMapZoom => 'Pokaż zbliżenie mapy';

  @override
  String get showMapZoomDescription =>
      'Pokazuj bieżące powiększenie podczas wyświetlania mapy.';

  @override
  String get aiSettings => 'AI';

  @override
  String get aiBatterySaver => 'Oszczędzanie baterii AI';

  @override
  String get aiBatterySaverDescription =>
      'Ogranicza wyszukiwanie taktyczne podczas lokalnych tur AI.';

  @override
  String get mapAppearanceSettings => 'Wygląd mapy';

  @override
  String get mapMarkingsSettings => 'Oznaczenia mapy';

  @override
  String get preferredMapViewMode => 'Domyślny widok mapy';

  @override
  String get preferredMapViewModeDescription =>
      'Używany przy otwieraniu gry lub powtórki.';

  @override
  String get mapCitySites => 'Miejsca pod miasta';

  @override
  String get mapCitySitesDescription =>
      'Pokazuj potencjalne miejsca pod miasta na odkrytym terenie.';

  @override
  String get mapCityGrowth => 'Rozwój miast';

  @override
  String get mapCityGrowthDescription =>
      'Pokazuj odkryte pola poza terytorium znanych miast.';

  @override
  String resourceTurnsCompact(int turns) {
    return '${turns}T';
  }

  @override
  String resourceText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'gold': 'Złoto',
      'science': 'Nauka',
      'stability': 'Stabilność',
      'resources': 'Zasoby',
      'victory': 'Zwycięstwo',
      'turn': 'Tura',
      'close': 'Zamknij szczegóły',
      'treasury': 'Skarbiec',
      'income': 'Przychód',
      'cityIncome': 'Przychód miast',
      'projectIncome': 'Przychód projektów',
      'upkeep': 'Utrzymanie jednostek',
      'netPerTurn': 'Na turę',
      'freeUnits': 'Darmowe jednostki',
      'paidUnits': 'Płatne jednostki',
      'nextWorker': 'Utrzymanie następnego robotnika',
      'activeResearch': 'Aktywne badanie',
      'overflow': 'Zgromadzona nauka',
      'sources': 'Źródła',
      'baseOrder': 'Porządek bazowy',
      'buildings': 'Budynki',
      'luxuries': 'Dobra luksusowe',
      'technologies': 'Technologie',
      'artifacts': 'Artefakty',
      'wonders': 'Cuda',
      'cities': 'Miasta',
      'population': 'Populacja',
      'cohesion': 'Spójność',
      'conqueredCities': 'Podbite miasta',
      'warWeariness': 'Zmęczenie wojną',
      'hegemony': 'Podatek hegemonii',
      'relativeStanding': 'Pozycja względna',
      'totalSources': 'Suma źródeł',
      'totalCosts': 'Suma kosztów',
      'stockpile': 'Zapasy',
      'output': 'Produkcja na turę',
      'empty': 'Brak źródeł',
      'score': 'Wynik',
      'conquest': 'Podbój',
      'domination': 'Dominacja',
      'culture': 'Kultura',
      'holdTurns': 'Tury utrzymania',
      'remainingTurns': 'Pozostałe tury',
      'turnLimit': 'Limit tur',
      'submitted': 'Zatwierdzono',
      'required': 'Wymagane zatwierdzenia',
      'content': 'Zadowolenie',
      'stable': 'Stabilność',
      'strained': 'Napięcie',
      'unrest': 'Niepokoje',
      'warning': 'Ostrzeżenie',
      'negativeBalance': 'Skarbiec ma ujemne saldo.',
      'deficitWithinThreeTurns':
          'Przy obecnym dochodzie skarbiec będzie miał ujemne saldo w ciągu trzech tur.',
      'shortage': 'Brakuje zasobów dla odblokowanych jednostek',
      'victoryCritical': 'Zbliża się rozstrzygnięcie warunku zwycięstwa.',
      'leader': 'Lider',
      'noVictory': 'Brak warunku zwycięstwa',
      'goalCompact': 'Cel',
      'scoreCapCompact': 'LIMIT',
      'other': 'Zasoby',
    });
    return '$_temp0';
  }

  @override
  String get automaticSave => 'Zapis automatyczny';

  @override
  String playerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Gracze',
      'active': 'Aktywny',
      'finished': 'Tura zakończona',
      'submitted': 'Zatwierdzono',
      'waiting': 'Oczekiwanie',
      'ended': 'Mecz zakończony',
      'privateStatus': 'Status tury jest prywatny',
      'noContact': 'Brak kontaktu dyplomatycznego',
      'other': 'Gracze',
    });
    return '$_temp0';
  }

  @override
  String historyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Zakończone mecze Online',
      'loading': 'Ładowanie historii meczów',
      'empty': 'Nie ma jeszcze zakończonych meczów.',
      'failed': 'Nie udało się wczytać historii. Spróbuj odświeżyć.',
      'refresh': 'Odśwież',
      'previous': 'Poprzednia strona',
      'next': 'Następna strona',
      'turn': 'Ostatnia tura',
      'won': 'Wygrana',
      'lost': 'Przegrana',
      'resigned': 'Zrezygnowano z meczu',
      'removed': 'Usunięto Cię z meczu',
      'other': 'Zakończone mecze Online',
    });
    return '$_temp0';
  }

  @override
  String profileText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Twój profil',
      'description': 'Zmiana nazwy zachowuje konto i mecze multiplayer.',
      'save': 'Zapisz nazwę',
      'saved': 'Nazwa została zapisana.',
      'taken': 'Ta nazwa jest już zajęta.',
      'changed': 'Konto uległo zmianie. Wczytaj profil ponownie.',
      'other': 'Twój profil',
    });
    return '$_temp0';
  }

  @override
  String get researchDiscoveryTitle => 'Badanie ukończone';

  @override
  String get showResearchDiscoveries => 'Pokazuj odkrycia technologii';

  @override
  String get researchDiscoverySuppress => 'Nie pokazuj ponownie';

  @override
  String get researchDiscoveryMinimize => 'Minimalizuj';

  @override
  String get researchDiscoveryRestore => 'Przywróć odkrycie';

  @override
  String get researchDiscoveryContinue => 'Kontynuuj';

  @override
  String researchRecommendationRank(int rank) {
    return 'Rekomendacja $rank';
  }

  @override
  String researchRecommendationTurns(int turns) {
    return 'Przewidywana liczba tur: $turns';
  }

  @override
  String researchRecommendationReason(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'boost': 'Premia do badań',
      'workerYields': 'Przychody z ulepszeń robotników',
      'unlocks': 'Nowe odblokowania',
      'effects': 'Efekty technologii',
      'nearCompletion': 'Blisko ukończenia',
      'other': 'Rekomendacje',
    });
    return '$_temp0';
  }

  @override
  String technologyDescription(String technology) {
    String _temp0 = intl.Intl.selectLogic(technology, {
      'agriculture':
          'Otwiera podstawową ścieżkę wzrostu. Farmy i farmy rzeczne pozwalają szybciej zwiększać populację oraz stabilizują pierwsze miasto.',
      'woodworking':
          'Rozwija produkcyjną stronę górnictwa. Tartaki zmieniają lasy w źródło produkcji bez wchodzenia głęboko w metalurgię.',
      'mining':
          'Otwiera ścieżkę przemysłu i infrastruktury. Kopalnie są pierwszym dużym skokiem produkcji miasta.',
      'animalHusbandry':
          'Wzmacnia rozwój przez zasoby zwierzęce. Pastwiska budują gospodarkę żywnościową i przygotowują drogę do jazdy konnej.',
      'hunting':
          'Otwiera militarną i eksploracyjną gałąź. Daje obozy oraz pierwszą jednostkę dystansową do produkcji w mieście.',
      'fishing':
          'Rozwija miasta przy wodzie. Łodzie rybackie pomagają coastal city szybciej rosnąć i przygotowują drogę do portu.',
      'craftsmanship':
          'Pierwszy miejski upgrade produkcji. Warsztat sprawia, że kolejne budynki i jednostki nie blokują kolejki na zbyt długo.',
      'trade':
          'Pierwszy krok w ekonomii złota. Hala kupiecka daje miastu prosty payoff finansowy po wyborze gałęzi wzrostu.',
      'storage':
          'Stabilizuje wzrost miasta. Magazynowanie pomaga utrzymać tempo żywności i zmniejsza ryzyko przestojów rozwoju.',
      'waterEngineering':
          'Rozbudowuje wodną ścieżkę wzrostu. Młyn wodny nagradza miasta kontrolujące rzeki.',
      'stoneworking':
          'Łączy produkcję i obronę. Kamieniołomy oraz kamieniarz wzmacniają miasta w gałęzi infrastruktury.',
      'militaryOrganization':
          'Buduje pierwszy militarny rdzeń miasta. Koszary wzmacniają produkcję i obronę, zanim pojawią się późniejsze premie armii.',
      'advancedTrade':
          'Rozwija ekonomię po handlu. Targowisko jest mocniejszym budynkiem złota i przygotowuje ścieżkę do bankowości.',
      'construction':
          'Poszerza terytorium i dojrzewanie miasta. Mieszkania zwiększają kontrolę pól i prowadzą do administracji oraz inżynierii.',
      'navigation':
          'Otwiera miejski payoff dla wybrzeża. Port wymaga dostępu do coast/ocean i nagradza miasta nad wodą żywnością oraz złotem.',
      'irrigation':
          'Specjalizacja wodnego wzrostu. Akwedukt daje mocny food bonus i dodatkową kontrolę terytorium.',
      'banking':
          'Specjalizacja gałęzi handlu. Bank zamienia wcześniejsze targi w silny przychód miasta i odblokowuje dalszą gospodarkę.',
      'engineering':
          'Specjalizacja budowlana. Gildia budowniczych przyspiesza produkcję i zwiększa limit kontrolowanych pól.',
      'metallurgy':
          'Mocny payoff przemysłowy po kamieniarstwie. Kuźnia podnosi produkcję i przygotowuje ścieżkę do żelaza oraz węgla.',
      'horsebackRiding':
          'Technologia łącząca wzrost i wojsko. Stajnia wspiera miasta, które wcześniej inwestowały w zwierzęta i łowiectwo.',
      'ironWorking':
          'Przemysłowy efekt zasobów. Każde kontrolowane żelazo zwiększa produkcję miasta.',
      'coalMining':
          'Późniejszy efekt zasobów przemysłowych. Kontrolowany węgiel zwiększa produkcję miasta i wspiera ścieżkę fabryki.',
      'machinery':
          'Późny payoff infrastruktury. Fabryka daje duży wzrost produkcji dla miast, które weszły w inżynierię.',
      'administration':
          'Łączy infrastrukturę z ekonomią. Ratusz i pomnik wzmacniają dojrzałe miasta oraz prowadzą do urbanizacji.',
      'logistics':
          'Przyspiesza produkcję jednostek. To główna technologia dla gracza, który chce częściej wystawiać armię z miast.',
      'shipbuilding':
          'Rozwija coastal/exploration subbranch. Latarnia morska wymaga dostępu do wybrzeża i wzmacnia miasta nad wodą.',
      'tactics':
          'Militarna specjalizacja miasta. Plac ćwiczeń dodaje obronę i produkcję dla ośrodków wojskowych.',
      'economy':
          'Systemowy payoff za bankowość. Zwiększa złoto generowane przez ekonomię miast.',
      'urbanization':
          'Końcowy kierunek rozwoju dużych miast. Zwiększa limit populacji, gdy system populacji zacznie używać twardych limitów.',
      'fortifications':
          'Wzmacnia obronę miast. Daje defensywny bonus gospodarce miasta, a pełne znaczenie wzrośnie po rozbudowie walki i oblężeń.',
      'strategy':
          'Końcowy kierunek wojskowy. Wzmacnia skuteczność armii jako late-game payoff po logistyce.',
      'specialization':
          'Końcowy payoff civic/economy. Odblokowuje specjalizacje miast, dodaje naukę miastom i pomaga domykać późne technologie w dłuższej partii.',
      'writing':
          'Pierwszy krok do nauki, prawa i administracji. Archiwum daje miastu trwałą podstawę badań.',
      'mathematics':
          'Łączy naukę z planowaniem terytorium. Urząd mierniczy pomaga miastom lepiej kontrolować granice.',
      'medicine':
          'Rozwija zdrowie i długoterminowy wzrost dużych miast przez apteki, łaźnie i szpitale.',
      'civilService':
          'Usprawnia zarządzanie dużym imperium i odblokowuje sądy stabilizujące miasta.',
      'siegecraft':
          'Otwiera oblężenia. Katapulty i warsztaty oblężnicze przełamują miasta-fortece.',
      'cartography':
          'Rozwija eksplorację, mapy i wybrzeże. Daje salę map oraz pierwsze okręty zwiadowcze.',
      'guilds':
          'Daje miastom produkcyjnym etap między warsztatem a przemysłem.',
      'law':
          'Wprowadza porządek, polityki i cywilne zarządzanie przez trybunały.',
      'education':
          'Buduje pełną ścieżkę naukową dla miast przez akademie i uniwersytety.',
      'urbanPlanning':
          'Rozwija wielkie miasta i kontrolę terytorium przez planowanie przestrzenne.',
      'navalDoctrine':
          'Zamienia porty w centra floty, stoczni i projekcji siły na morzu.',
      'steel':
          'Wprowadza ciężki przemysł oraz ciężką piechotę dla późniejszego frontu.',
      'bureaucracy':
          'Daje duży cywilny cel po administracji: urzędy, ministerstwa, muzea i parlament.',
      'nationalism': 'Łączy obronę granic, mobilizację i tożsamość imperium.',
      'scientificMethod':
          'Przygotowuje późną naukę, laboratoria, obserwatoria i projekty technologiczne.',
      'steamPower': 'Otwiera kolej, cięższą logistykę i przemysł parowy.',
      'electricity': 'Wprowadza energię, infrastrukturę i zasięg informacyjny.',
      'combustion':
          'Nadaje ropie znaczenie i odblokowuje nowoczesne jednostki frontowe.',
      'flight': 'Wprowadza lotnictwo, zwiad i projekcję siły ponad frontem.',
      'massProduction':
          'Rozwija końcową produkcję przemysłową, czołgi i zakłady montażowe.',
      'radio':
          'Wzmacnia komunikację, widoczność i wpływ imperium przez wieże nadawcze.',
      'nuclearPhysics': 'Otwiera reaktor, uran i późne projekty końcowe.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String outcomePresentationText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'victory': 'Zwycięstwo',
      'defeat': 'Porażka',
      'draw': 'Remis',
      'complete': 'Rozgrywka zakończona',
      'control': 'Kontrola mapy',
      'threshold': 'Wymagana kontrola',
      'other': 'Rozgrywka zakończona',
    });
    return '$_temp0';
  }
}
