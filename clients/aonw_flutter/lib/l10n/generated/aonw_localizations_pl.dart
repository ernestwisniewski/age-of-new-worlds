// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AonwLocalizationsPl extends AonwLocalizations {
  AonwLocalizationsPl([String locale = 'pl']) : super(locale);

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
  String get multiplayerMatchTitle => 'Rozgrywka online';

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
      'match_not_found': 'Nie znaleziono rozgrywki.',
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
  String get singlePlayerSetupIntro =>
      'Wybierz cywilizację i skonfiguruj autorytatywny pojedynek lokalny.';

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
  String get opponentsTitle => 'Przeciwnicy';

  @override
  String get opponentControlLabel => 'Sterowanie przeciwnikiem';

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
  String get scenarioLabel => 'Scenariusz';

  @override
  String localScenarioName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'starterDuel': 'Pojedynek startowy',
      'other': 'Scenariusz lokalny',
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
      'Użyj strzałek lub krzyżaka, aby przesunąć kursor mapy, oraz Enter lub A, aby wybrać.';

  @override
  String get noHexSelected => 'Nie wybrano heksa';

  @override
  String selectedHex(int col, int row) {
    return 'Wybrany heks $col, $row';
  }

  @override
  String get hideReferenceLayer => 'Ukryj warstwę referencyjną';

  @override
  String get showReferenceLayer => 'Pokaż warstwę referencyjną';

  @override
  String hexLabel(int col, int row) {
    return 'Heks $col, $row';
  }

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
  String get masterVolume => 'Głośność główna';

  @override
  String get cameraSettings => 'Kamera';

  @override
  String get cameraSensitivity => 'Czułość przybliżenia';

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
  String get objectivesAuthoredRules =>
      'Wymagania mapy. Bieżący postęp pozostaje w silniku.';

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
      'executing': 'Wykonywanie akcji miasta',
      'cityYield': 'Dochód',
      'food': 'Żywność',
      'production': 'Produkcja',
      'gold': 'Złoto',
      'defense': 'Obrona',
      'workedHexes': 'Pola robocze',
      'expansion': 'Preferowana ekspansja',
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
}
