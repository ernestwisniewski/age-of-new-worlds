// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AonwLocalizationsFr extends AonwLocalizations {
  AonwLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get moveTargeting => 'Déplacer';

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String get mainMenuTitle => 'Menu principal';

  @override
  String get mainMenuWelcome =>
      'Bienvenue dans Age of New Worlds. Fondez des villes, dirigez vos commandants, découvrez de nouvelles terres et écrivez l’histoire de votre civilisation.';

  @override
  String get mainMenuSynopsisTitle => 'Bâtir · Rechercher · Commander';

  @override
  String get mainMenuWhatsNew => 'Nouveautés';

  @override
  String get singlePlayer => 'Solo';

  @override
  String get singlePlayerSublabel => 'Jouer contre l’ordinateur';

  @override
  String get multiplayerSublabel => 'Jouer en ligne';

  @override
  String get hotseat => 'Multijoueur local';

  @override
  String get hotseatSublabel => 'Plusieurs joueurs sur un même appareil';

  @override
  String get hotseatUnavailable =>
      'La configuration du multijoueur local n’est pas encore disponible.';

  @override
  String get hotseatHandoffTitle => 'Passez l’appareil';

  @override
  String hotseatHandoffBody(String name) {
    return 'Confiez l’appareil à $name. Sa carte reste masquée jusqu’à sa confirmation.';
  }

  @override
  String hotseatContinueAs(String name) {
    return 'Continuer avec $name';
  }

  @override
  String get hotseatHandoffSwitching => 'Préparation du joueur suivant';

  @override
  String get hotseatHandoffFailure =>
      'Impossible d’ouvrir la session du joueur local suivant en toute sécurité.';

  @override
  String get loadGame => 'Charger une partie';

  @override
  String get loadGameSublabel => 'Sauvegardes et rediffusions';

  @override
  String get exitGame => 'Quitter';

  @override
  String get instructions => 'Manuel';

  @override
  String get creditsTitle => 'Crédits';

  @override
  String creditsCreatedBy(String name) {
    return 'Créé par $name';
  }

  @override
  String get devlogLinkLabel => 'Journal de développement : ernest.dev';

  @override
  String get feedbackTitle => 'Commentaires';

  @override
  String get feedbackDescription =>
      'Partagez vos idées, signalez des problèmes et suivez le développement avec la communauté d’Age of New Worlds.';

  @override
  String get openFeedback => 'Ouvrir r/aonw';

  @override
  String get externalLinkUnavailable =>
      'Les liens externes ne sont pas disponibles sur cette plateforme.';

  @override
  String get serverUpdateSoon =>
      'Une nouvelle version est prête et sera bientôt disponible sur cette plateforme. Consultez à nouveau votre boutique ou votre lanceur dans quelques instants.';

  @override
  String get continueGame => 'Continuer';

  @override
  String get resumingGame => 'Reprise de la partie';

  @override
  String get newGame => 'Nouvelle partie';

  @override
  String get multiplayerTitle => 'Multijoueur';

  @override
  String get multiplayerUnavailable =>
      'Le multijoueur n’est pas disponible dans cette version.';

  @override
  String get loadingMultiplayer => 'Connexion au multijoueur';

  @override
  String get multiplayerAuthenticationTitle => 'Compte AoNW';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get displayNameLabel => 'Nom d’affichage';

  @override
  String get invalidEmail => 'Saisissez une adresse e-mail valide.';

  @override
  String get invalidPassword => 'Utilisez au moins 12 caractères.';

  @override
  String get invalidDisplayName => 'Saisissez un nom d’affichage.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get createNewAccount => 'Créer un nouveau compte';

  @override
  String get useExistingAccount => 'Utiliser un compte existant';

  @override
  String get multiplayerLobbyTitle => 'Salon de la partie';

  @override
  String signedInAccount(String userId) {
    return 'Compte : $userId';
  }

  @override
  String get multiplayerSetupTitle => 'Créer une partie en ligne';

  @override
  String get multiplayerSetupIntro =>
      'Choisissez votre civilisation et votre carte avant d’ouvrir la salle d’attente gérée par le serveur.';

  @override
  String get multiplayerTurnModeDescription =>
      'Tous les joueurs agissent au cours d’un même tour. Le moteur le résout une fois toutes les validations requises reçues ou le délai du serveur écoulé.';

  @override
  String get continueToLobby => 'Accéder au salon';

  @override
  String get createMultiplayerMatch => 'Créer une partie';

  @override
  String get joinMultiplayerMatch => 'Rejoindre une partie';

  @override
  String get matchIdLabel => 'Identifiant de la partie';

  @override
  String get playerSeatLabel => 'Place du joueur';

  @override
  String get playerSeatOne => 'Joueur un';

  @override
  String get playerSeatTwo => 'Joueur deux';

  @override
  String playerSeatNumber(int number) {
    return 'Joueur $number';
  }

  @override
  String get refreshMatches => 'Actualiser les parties';

  @override
  String get yourMatches => 'Vos parties';

  @override
  String get noMultiplayerMatches =>
      'Vous n’avez encore rejoint aucune partie.';

  @override
  String matchRevision(int revision, int eventOffset) {
    return 'Révision $revision · position d’événement $eventOffset';
  }

  @override
  String multiplayerMatchPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'lobby': 'salle d’attente',
      'running': 'en cours',
      'finished': 'terminée',
      'abandoned': 'abandonnée',
      'other': 'inconnu',
    });
    return 'Statut : $_temp0';
  }

  @override
  String get multiplayerWaitingRoomTitle => 'Salle d’attente de la partie';

  @override
  String get multiplayerReady => 'Prêt';

  @override
  String get multiplayerNotReady => 'Pas prêt';

  @override
  String get multiplayerSeatOpen => 'Place libre';

  @override
  String get multiplayerHumanSeat => 'Humain';

  @override
  String get multiplayerAiSeat => 'Ordinateur';

  @override
  String get multiplayerHost => 'Hôte';

  @override
  String get multiplayerCurrentPlayer => 'Vous';

  @override
  String get markReady => 'Se déclarer prêt';

  @override
  String get markNotReady => 'Annuler l’état prêt';

  @override
  String get waitingForPlayers =>
      'Chaque place humaine doit être occupée par un joueur prêt avant le début de la partie.';

  @override
  String get refreshMatch => 'Actualiser la partie';

  @override
  String get leaveMultiplayerMatch => 'Quitter la partie';

  @override
  String get multiplayerResignTitle => 'Abandonner cette partie ?';

  @override
  String get multiplayerResignBody =>
      'Votre participation prendra fin immédiatement. Cette action est irréversible.';

  @override
  String get multiplayerResignConfirm => 'Abandonner';

  @override
  String get multiplayerMatchTitle => 'Partie en ligne';

  @override
  String get multiplayerParticipants => 'Participants';

  @override
  String get multiplayerRemoveParticipant => 'Exclure';

  @override
  String get multiplayerRemoveParticipantTitle => 'Exclure ce participant ?';

  @override
  String multiplayerRemoveParticipantBody(String name) {
    return 'Exclure $name de cette partie ? Ce participant ne pourra plus s’y reconnecter.';
  }

  @override
  String get cancelDialog => 'Annuler';

  @override
  String matchIdentifier(String matchId) {
    return 'Partie : $matchId';
  }

  @override
  String playerIdentifier(String playerId) {
    return 'Joueur : $playerId';
  }

  @override
  String multiplayerTurn(int turn) {
    return 'Tour $turn';
  }

  @override
  String multiplayerSubmissionProgress(int submitted, int required) {
    return 'Validations : $submitted sur $required';
  }

  @override
  String visibleUnits(int count) {
    return 'Unités visibles : $count';
  }

  @override
  String networkPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'connecting': 'connexion en cours',
      'ready': 'en ligne',
      'reconnecting': 'reconnexion en cours',
      'resyncing': 'synchronisation en cours',
      'failed': 'hors ligne',
      'closed': 'fermée',
      'other': 'indisponible',
    });
    return 'Connexion : $_temp0';
  }

  @override
  String get submitTurn => 'Valider le tour';

  @override
  String get reconnect => 'Se reconnecter';

  @override
  String get backToLobby => 'Retour au salon';

  @override
  String multiplayerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'client_update_required':
          'Mettez le client à jour avant de vous connecter.',
      'authentication_required': 'Reconnectez-vous pour continuer.',
      'invalid_authentication_response':
          'La réponse d’authentification était invalide.',
      'authentication_identity_changed':
          'L’identité du compte a changé pendant l’actualisation.',
      'connection_interrupted':
          'La connexion a été interrompue. Reconnectez-vous pour synchroniser la partie.',
      'invalid_server_response':
          'La réponse du serveur a échoué à la validation.',
      'invalid_command_sequence':
          'La séquence de commandes n’était pas continue.',
      'invalid_resync_sequence': 'L’état synchronisé est revenu en arrière.',
      'invalid_match_lifecycle':
          'La réponse concernant le déroulement de la partie était incohérente.',
      'match_not_found': 'La partie est introuvable.',
      'match_not_started': 'L’hôte n’a pas encore lancé la partie.',
      'match_already_started': 'La partie a déjà commencé.',
      'host_required': 'Seul l’hôte peut effectuer cette action.',
      'lobby_not_ready':
          'Tous les joueurs humains doivent rejoindre la partie et être prêts.',
      'participant_not_claimable':
          'Les places contrôlées par l’ordinateur ne peuvent pas être occupées par un joueur.',
      'participant_not_active': 'Ce participant n’est plus actif.',
      'invalid_kick_target': 'L’hôte ne peut pas s’exclure lui-même.',
      'player_seat_taken': 'Cette place est déjà occupée.',
      'other': 'La requête multijoueur n’a pas pu aboutir.',
    });
    return '$_temp0';
  }

  @override
  String get helpTitle => 'Comment jouer';

  @override
  String get helpIntroduction =>
      'Bâtissez une civilisation tour après tour. Le moteur applique toutes les règles ; ce guide explique les décisions disponibles dans le client.';

  @override
  String get helpObjectiveTitle => 'Poursuivez votre objectif';

  @override
  String get helpObjectiveBody =>
      'Étendez votre territoire, développez vos villes et accomplissez les objectifs du scénario avant votre adversaire. Ouvrez les objectifs stratégiques sur la carte pour consulter les buts définis pour le scénario.';

  @override
  String get helpMapTitle => 'Explorez et commandez';

  @override
  String get helpMapBody =>
      'Sélectionnez un hexagone visible pour l’inspecter. Sélectionnez votre unité, choisissez une destination en surbrillance et confirmez l’itinéraire. Le clavier, la manette et les commandes tactiles utilisent les mêmes commandes.';

  @override
  String get helpDevelopmentTitle => 'Développez votre civilisation';

  @override
  String get helpDevelopmentBody =>
      'Utilisez les panneaux de ville, recherche, production, ouvriers, logistique, artefacts et diplomatie lorsque leurs actions deviennent disponibles.';

  @override
  String get helpTurnTitle => 'Terminez le tour au bon moment';

  @override
  String get helpTurnBody =>
      'Achevez vos actions, puis terminez le tour. L’ordinateur accomplit son tour selon les règles du moteur avant de vous rendre la main.';

  @override
  String get helpSaveReplayTitle => 'Sauvegardez et analysez';

  @override
  String get helpSaveReplayBody =>
      'Sauvegardez depuis la carte. Continuer ouvre la dernière sauvegarde valide ; la rediffusion permet de revoir l’historique des commandes validées sans modifier la partie.';

  @override
  String get startOnboarding => 'Lancer la visite guidée';

  @override
  String get onboardingTitle => 'Visite guidée';

  @override
  String onboardingProgress(int step, int count) {
    return 'Étape $step sur $count';
  }

  @override
  String get onboardingExploreTitle => 'Lisez la carte';

  @override
  String get onboardingExploreBody =>
      'La carte ne montre que les informations visibles par votre joueur. Sélectionnez des hexagones pour inspecter le terrain, les villes et les unités, puis déplacez ou zoomez la vue pour préparer votre prochaine action.';

  @override
  String get onboardingCommandTitle => 'Donnez des ordres précis';

  @override
  String get onboardingCommandBody =>
      'Les destinations et actions disponibles sont fournies par le moteur de jeu. Faites votre choix, examinez l’aperçu et confirmez ; les commandes refusées ou périmées ne modifient jamais la partie.';

  @override
  String get onboardingDevelopTitle => 'Prenez un avantage durable';

  @override
  String get onboardingDevelopBody =>
      'Villes, production, recherche, ouvriers, logistique, artefacts et diplomatie façonnent votre stratégie. Leurs panneaux proposent uniquement les actions actuellement autorisées par le moteur.';

  @override
  String get onboardingContinueTitle => 'Reprenez en toute confiance';

  @override
  String get onboardingContinueBody =>
      'Sauvegardez l’état validé de la partie avant de quitter. Continuer le vérifie dans une nouvelle session du moteur ; la rediffusion permet de consulter le même historique sans le modifier.';

  @override
  String get previousOnboardingStep => 'Précédent';

  @override
  String get nextOnboardingStep => 'Suivant';

  @override
  String get skipOnboarding => 'Passer';

  @override
  String get finishOnboarding => 'Créer une partie';

  @override
  String get newGameTitle => 'Créer une partie locale';

  @override
  String get singlePlayerSetupTitle => 'Jouer contre l’ordinateur';

  @override
  String get singlePlayerSetupIntro =>
      'Choisissez votre civilisation et configurez une partie locale gérée par le moteur.';

  @override
  String get hotseatSetupTitle => 'Jouer en multijoueur local';

  @override
  String get hotseatSetupIntro =>
      'Partagez un même appareil. La vue de chaque joueur humain reste masquée jusqu’à ce que le joueur suivant confirme qu’il a reçu l’appareil.';

  @override
  String get chooseCivilizationTitle => 'Choisir une civilisation';

  @override
  String get gameSetupTitle => 'Configuration de la partie';

  @override
  String get turnModeTitle => 'Mode de tours';

  @override
  String turnModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'sequential': 'Traditionnel',
      'simultaneous': 'Simultané',
      'other': 'Inconnu',
    });
    return '$_temp0';
  }

  @override
  String get turnModeSequentialDescription =>
      'Les civilisations jouent et résolvent leurs tours l’une après l’autre.';

  @override
  String get turnModeSimultaneousDescription =>
      'Vous et l’ordinateur agissez au cours d’un même tour, puis le moteur résout les phases communes.';

  @override
  String get opponentsTitle => 'Adversaires';

  @override
  String get opponentControlLabel => 'Contrôle de l’adversaire';

  @override
  String opponentNumberLabel(int number) {
    return 'Adversaire $number';
  }

  @override
  String get humanOpponent => 'Joueur humain';

  @override
  String get aiOpponent => 'Ordinateur';

  @override
  String get mapSetupTitle => 'Carte';

  @override
  String get mapSetupBody =>
      'Une carte compacte de 7 × 7 cases, conçue pour une partie à deux civilisations.';

  @override
  String mapSetupDetails(String mapName, int columns, int rows, int players) {
    return '$mapName · $columns × $rows · $players civilisations';
  }

  @override
  String get victoryPathsTitle => 'Voies vers la victoire';

  @override
  String get victoryPathsBody =>
      'La conquête, la domination, la culture et le score sont évalués par le moteur de jeu.';

  @override
  String get settlementToEmpireTitle => 'D’une colonie à un empire';

  @override
  String get settlementToEmpireBody =>
      'Explorez, fondez des villes, menez des recherches, formez des armées et bâtissez des avantages durables.';

  @override
  String get continueToSummary => 'Accéder au récapitulatif';

  @override
  String get gameSummaryTitle => 'L’expédition est prête';

  @override
  String get gameSummaryIntro =>
      'Vérifiez chaque participant local avant de créer la partie.';

  @override
  String get summaryModeLabel => 'Mode';

  @override
  String get summaryTurnModeLabel => 'Tours';

  @override
  String get summaryCivilizationLabel => 'Votre civilisation';

  @override
  String get summaryOpponentLabel => 'Adversaire';

  @override
  String get summaryMapLabel => 'Carte';

  @override
  String get summaryFogLabel => 'Brouillard de guerre';

  @override
  String get summaryAiLabel => 'Profil de l’ordinateur';

  @override
  String get changeSetup => 'Modifier la configuration';

  @override
  String localModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'singlePlayer': 'Solo',
      'hotseat': 'Multijoueur local',
      'other': 'Partie locale',
    });
    return '$_temp0';
  }

  @override
  String participantControlName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'human': 'Humain',
      'ai': 'Ordinateur',
      'other': 'Inconnu',
    });
    return '$_temp0';
  }

  @override
  String fogSettingName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'enabled': 'Activé',
      'disabled': 'Désactivé',
      'other': 'Inconnu',
    });
    return '$_temp0';
  }

  @override
  String get defaultSecondPlayerName => 'Joueur 2';

  @override
  String defaultNumberedPlayerName(int number) {
    return 'Joueur $number';
  }

  @override
  String defaultNumberedAiName(int number) {
    return 'Ordinateur $number';
  }

  @override
  String get scenarioLabel => 'Carte';

  @override
  String localScenarioName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'starterDuel': 'Initiation',
      'dravonia': 'Dravonia',
      'myranth': 'Myranth',
      'terenos': 'Terenos',
      'verdantia': 'Verdantia',
      'other': 'Carte locale',
    });
    return '$_temp0';
  }

  @override
  String get humanCountryLabel => 'Votre pays';

  @override
  String get aiCountryLabel => 'Pays de l’IA';

  @override
  String get aiDifficultyLabel => 'Difficulté de l’IA';

  @override
  String get aiPersonaLabel => 'Personnalité de l’IA';

  @override
  String get fogOfWarLabel => 'Brouillard de guerre';

  @override
  String get startGame => 'Lancer la partie';

  @override
  String get startingGame => 'Lancement de la partie';

  @override
  String get localGameStartFailed => 'Impossible de lancer la partie locale.';

  @override
  String get saveGame => 'Sauvegarder la partie';

  @override
  String get savingGame => 'Sauvegarde en cours';

  @override
  String get gameSaved => 'Partie sauvegardée';

  @override
  String saveFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'La sauvegarde n’est pas disponible pour cette session.',
      'exportFailed': 'Impossible d’exporter la partie.',
      'writeFailed': 'Impossible d’enregistrer le fichier de sauvegarde.',
      'other': 'Impossible de sauvegarder la partie.',
    });
    return '$_temp0';
  }

  @override
  String resumeFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'Les sauvegardes ne sont pas disponibles sur cette plateforme.',
      'missing': 'Aucune sauvegarde trouvée.',
      'unreadable': 'Impossible de lire la sauvegarde.',
      'incompatible':
          'La sauvegarde est invalide ou incompatible avec le jeu actuel.',
      'other': 'Impossible de reprendre la partie sauvegardée.',
    });
    return '$_temp0';
  }

  @override
  String get loadGameTitle => 'Charger une partie';

  @override
  String get loadGameEmpty => 'Aucune sauvegarde trouvée.';

  @override
  String loadGameSingleLabel(String scenario) {
    return 'Solo · $scenario';
  }

  @override
  String get importSave => 'Importer une sauvegarde';

  @override
  String get exportSave => 'Exporter';

  @override
  String get saveTransferUnavailable =>
      'L’importation et l’exportation de sauvegardes ne sont pas disponibles sur cette plateforme.';

  @override
  String saveImportCompleted(String map) {
    return '$map a été importée dans une sauvegarde distincte.';
  }

  @override
  String saveExportCompleted(String map) {
    return '$map a été exportée.';
  }

  @override
  String saveTransferFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'Le transfert de sauvegardes n’est pas disponible sur cette plateforme.',
      'unreadable': 'Impossible de lire le fichier de sauvegarde sélectionné.',
      'tooLarge':
          'Le fichier de sauvegarde sélectionné dépasse la limite de 16 Mio.',
      'incompatible':
          'La sauvegarde sélectionnée est invalide ou ne correspond à aucune carte, aucun ensemble de règles ou aucune version du moteur installés.',
      'missing': 'La sauvegarde sélectionnée n’existe plus.',
      'writeFailed': 'Impossible d’enregistrer la sauvegarde importée.',
      'exportFailed': 'Impossible d’exporter le fichier de sauvegarde.',
      'other': 'Impossible de terminer le transfert de sauvegarde.',
    });
    return '$_temp0';
  }

  @override
  String get replayTitle => 'Rediffusion';

  @override
  String get loadingReplay => 'Chargement de la rediffusion';

  @override
  String get replayUnavailable =>
      'La lecture des rediffusions n’est pas disponible.';

  @override
  String replayFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'La lecture des rediffusions n’est pas disponible sur cette plateforme.',
      'missing':
          'Aucune rediffusion trouvée. Sauvegardez d’abord une partie locale.',
      'unreadable': 'Impossible de lire le fichier de rediffusion.',
      'incompatible':
          'La rediffusion est invalide ou incompatible avec le jeu actuel.',
      'seekFailed': 'Impossible de charger l’étape demandée de la rediffusion.',
      'other': 'Impossible d’ouvrir la rediffusion.',
    });
    return '$_temp0';
  }

  @override
  String get replayMapLabel => 'Carte de la rediffusion';

  @override
  String get replayControls => 'Commandes de rediffusion';

  @override
  String get playReplay => 'Lire la rediffusion';

  @override
  String get pauseReplay => 'Mettre la rediffusion en pause';

  @override
  String get backToMenu => 'Retour au menu principal';

  @override
  String replayProgress(int position, int entryCount) {
    return '$position sur $entryCount';
  }

  @override
  String replaySpeed(String value) {
    return 'Vitesse $value×';
  }

  @override
  String get aiTurnRunning => 'L’ordinateur joue son tour.';

  @override
  String aiTurnFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'requestFailed': 'Impossible de terminer le tour de l’ordinateur.',
      'responseIncompatible':
          'La réponse du tour de l’ordinateur est incompatible avec ce client.',
      'incomplete':
          'L’ordinateur n’a pas terminé son tour dans la limite de commandes autorisée.',
      'other': 'Impossible de terminer le tour de l’ordinateur.',
    });
    return '$_temp0';
  }

  @override
  String get defaultPlayerName => 'Joueur';

  @override
  String get defaultAiName => 'Ordinateur';

  @override
  String countryName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'poland': 'Pologne',
      'ukraine': 'Ukraine',
      'germany': 'Allemagne',
      'france': 'France',
      'unitedKingdom': 'Royaume-Uni',
      'italy': 'Italie',
      'spain': 'Espagne',
      'netherlands': 'Pays-Bas',
      'sweden': 'Suède',
      'russia': 'Russie',
      'unitedStates': 'États-Unis',
      'canada': 'Canada',
      'china': 'Chine',
      'korea': 'Corée',
      'japan': 'Japon',
      'portugal': 'Portugal',
      'india': 'Inde',
      'brazil': 'Brésil',
      'indonesia': 'Indonésie',
      'mexico': 'Mexique',
      'turkey': 'Turquie',
      'saudiArabia': 'Arabie saoudite',
      'egypt': 'Égypte',
      'greece': 'Grèce',
      'other': 'Pays inconnu',
    });
    return '$_temp0';
  }

  @override
  String aiDifficultyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'easy': 'Facile',
      'normal': 'Normale',
      'hard': 'Difficile',
      'veryHard': 'Très difficile',
      'other': 'Difficulté inconnue',
    });
    return '$_temp0';
  }

  @override
  String aiPersonaName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'balanced': 'Équilibrée',
      'aggressive': 'Agressive',
      'expansive': 'Expansionniste',
      'economic': 'Économique',
      'scientific': 'Scientifique',
      'other': 'Personnalité inconnue',
    });
    return '$_temp0';
  }

  @override
  String get unknownRouteLabel => 'Page inconnue';

  @override
  String get pageUnavailable => 'Page indisponible';

  @override
  String unknownRouteMessage(String location) {
    return 'Page inconnue : $location';
  }

  @override
  String get missingRouteLocation => '(absente)';

  @override
  String mapSemanticsLabel(String mapId, int cols, int rows) {
    return 'Carte $mapId, $cols par $rows hexagones';
  }

  @override
  String get mapInputHint =>
      'Utilisez WASD ou les flèches pour déplacer la caméra, Entrée pour sélectionner, M pour déplacer une unité, I pour inspecter, R pour changer de vue, les crochets pour parcourir les actions en attente et Espace pour passer à l’action suivante ou terminer le tour. Tab permet de parcourir les commandes.';

  @override
  String get noHexSelected => 'Aucun hexagone sélectionné';

  @override
  String selectedHex(int col, int row) {
    return 'Hexagone sélectionné : $col, $row';
  }

  @override
  String get mapViewModeTooltip => 'Changer le mode d’affichage de la carte';

  @override
  String get mapViewGraphicUnavailable =>
      'La vue graphique n’est pas disponible pour cette carte.';

  @override
  String get mapViewModeGraphic => 'Graphique';

  @override
  String get mapViewModeTiles => 'Cases';

  @override
  String hexLabel(int col, int row) {
    return 'Hexagone $col, $row';
  }

  @override
  String get selectionTerrain => 'Terrain';

  @override
  String unitLabel(String unitId) {
    return 'Unité $unitId';
  }

  @override
  String routeSummary(int totalCost, int remaining) {
    return 'Itinéraire : $totalCost points de déplacement · $remaining restants';
  }

  @override
  String get confirmMove => 'Confirmer le déplacement';

  @override
  String moveTurnCost(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns tours',
      one: '$turns tour',
    );
    return '$_temp0';
  }

  @override
  String confirmMoveWithCost(String turnCost) {
    return 'Confirmer · $turnCost';
  }

  @override
  String get chooseHighlightedDestination =>
      'Choisissez une destination en surbrillance.';

  @override
  String get movingUnit => 'Déplacement de l’unité';

  @override
  String unitActionLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'title': 'Actions de l’unité',
      'fortify': 'Fortifier',
      'skip': 'Passer',
      'cancel': 'Annuler l’action',
      'executing': 'Exécution de l’action de l’unité',
      'logisticsTitle': 'Logistique',
      'logisticsLoading': 'Chargement des options logistiques',
      'logisticsEmpty':
          'Aucune action logistique n’est disponible actuellement.',
      'autoExplore': 'Exploration automatique',
      'merchantRoute': 'Affecter une route commerciale',
      'merchantTravel': 'Rejoindre une ville',
      'detachTroop': 'Détacher une troupe',
      'other': 'Action de l’unité',
    });
    return '$_temp0';
  }

  @override
  String unitActionFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'La demande d’action de l’unité n’a pas pu aboutir.',
      'responseIncompatible':
          'La réponse à l’action de l’unité est incompatible avec ce client.',
      'sessionUnavailable': 'La session de jeu locale n’est pas disponible.',
      'stale': 'L’état de la partie a changé. Vérifiez l’unité et réessayez.',
      'matchFinished': 'La partie est déjà terminée.',
      'unitUnavailable': 'Cette unité ne peut plus recevoir d’ordres.',
      'unitBusy':
          'Cette unité est occupée et ne peut pas effectuer cette action maintenant.',
      'internal': 'Impossible d’appliquer l’action de l’unité. Réessayez.',
      'logisticsRequestFailed': 'La demande logistique n’a pas pu aboutir.',
      'logisticsResponseIncompatible':
          'La réponse logistique est incompatible avec ce client.',
      'logisticsOptionUnavailable':
          'Cette option logistique n’est plus disponible.',
      'combatFailureRequestFailed': 'La demande de combat n’a pas pu aboutir.',
      'combatFailureResponseIncompatible':
          'La réponse de combat est incompatible avec ce client.',
      'combatFailureSessionUnavailable':
          'La session de jeu locale n’est pas disponible.',
      'combatFailureTargetUnavailable':
          'Aucun aperçu d’attaque n’est disponible pour cette cible.',
      'combatFailureStaleRevision':
          'L’état de la partie a changé. Vérifiez-le et réessayez.',
      'combatFailureMatchFinished': 'La partie est déjà terminée.',
      'combatFailureAttackerNotFound':
          'L’unité attaquante n’est plus disponible.',
      'combatFailureAttackerNotControlled':
          'Ce joueur ne contrôle pas l’unité attaquante.',
      'combatFailureAttackerUnavailable':
          'L’unité attaquante n’est pas disponible.',
      'combatFailureAttackerExhausted': 'L’unité attaquante est épuisée.',
      'combatFailureAttackerOutOfBounds':
          'L’unité attaquante se trouve hors de la carte.',
      'combatFailureAttackerCannotAttack': 'Cette unité ne peut pas attaquer.',
      'combatFailureAttackTargetNotVisible': 'La cible n’est pas visible.',
      'combatFailureAttackTargetOutOfBounds':
          'La cible se trouve hors de la carte.',
      'combatFailureAttackTargetNotFound':
          'Aucune cible ne se trouve à cet endroit.',
      'combatFailureAttackTargetNotEnemy': 'Cette cible n’est pas un ennemi.',
      'combatFailureAttackTargetProtectedByTreaty':
          'Un traité protège cette cible.',
      'combatFailureAttackTargetOutOfRange': 'La cible est hors de portée.',
      'combatFailureAttackCityHasNoHealth':
          'Cette ville ne peut pas être attaquée.',
      'other': 'Impossible d’effectuer l’action de l’unité.',
    });
    return '$_temp0';
  }

  @override
  String turnSummary(String kind, int turn, int submitted, int required) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'label': 'TOUR $turn',
      'progress': 'Prêts : $submitted sur $required',
      'other': 'TOUR $turn',
    });
    return '$_temp0';
  }

  @override
  String turnText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'statusActive': 'À vous de jouer',
      'statusFinished': 'Tour terminé',
      'statusSubmitted': 'Tour validé',
      'statusWaiting': 'En attente',
      'statusPendingAction': 'Action requise',
      'actionEnd': 'Terminer le tour',
      'actionEnding': 'Fin du tour en cours',
      'outcomeConquest': 'Victoire par conquête',
      'outcomeDomination': 'Victoire par domination',
      'outcomeCultural': 'Victoire culturelle',
      'outcomeScore': 'Victoire au score',
      'outcomeResignation': 'Partie terminée par abandon',
      'outcomeDraw': 'Match nul',
      'outcomeOngoing': 'Partie en cours',
      'activityTitle': 'Activité',
      'activityArtifact': 'Activité des artefacts',
      'activityCity': 'Activité des villes',
      'activityResearch': 'Avancée de la recherche',
      'activityObjective': 'Mise à jour d’un objectif stratégique',
      'activityOutcome': 'Résultat de la partie mis à jour',
      'activityCombat': 'Activité des combats',
      'activityDiplomacy': 'Activité diplomatique',
      'activityUnit': 'Activité des unités',
      'activityTurn': 'Tour mis à jour',
      'activityWorker': 'Travaux de l’ouvrier terminés',
      'combatTitle': 'Combat',
      'combatLoading': 'Chargement de l’aperçu du combat',
      'combatTarget': 'Cible',
      'combatDistance': 'Distance',
      'combatOutgoing': 'Dégâts infligés',
      'combatRetaliation': 'Dégâts de riposte',
      'combatNone': 'Aucun',
      'combatCapture': 'Capturer la ville',
      'combatDestroy': 'Détruire la ville',
      'combatConfirm': 'Confirmer l’attaque',
      'combatExecuting': 'Résolution du combat',
      'combatResolved': 'Combat résolu',
      'combatAttackerHp': 'Santé de l’attaquant',
      'combatDefenderHp': 'Santé du défenseur',
      'combatEventUnitAttacked': 'Unité attaquée',
      'combatEventCityAttacked': 'Ville attaquée',
      'combatEventCombatResolved': 'Combat résolu',
      'combatEventUnitGainedExperience': 'Unité ayant gagné de l’expérience',
      'combatEventUnitKilled': 'Unité vaincue',
      'combatEventUnitRetreated': 'Unité repliée',
      'combatEventCityCaptured': 'Ville capturée',
      'combatEventCityDestroyed': 'Ville détruite',
      'combatEventDiplomaticScoreChanged': 'Relation diplomatique modifiée',
      'other': 'Activité du jeu',
    });
    return '$_temp0';
  }

  @override
  String turnFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'La demande de tour n’a pas pu aboutir.',
      'responseIncompatible':
          'La réponse du tour est incompatible avec ce client.',
      'sessionUnavailable': 'La session de jeu locale n’est pas disponible.',
      'stale_revision':
          'L’état de la partie a changé. Vérifiez-le et réessayez.',
      'match_finished': 'La partie est déjà terminée.',
      'turn_player_not_controlled':
          'Ce joueur ne peut pas terminer le tour actuel.',
      'turn_player_not_active': 'Ce joueur n’est pas actif.',
      'turn_scope_invalid': 'Le périmètre du tour actuel est invalide.',
      'turn_processor_unsupported':
          'Un traitement nécessaire au tour n’est pas disponible.',
      'turn_number_overflow':
          'Le numéro du prochain tour dépasse la limite autorisée.',
      'state_revision_overflow':
          'La révision de la partie ne peut plus être augmentée.',
      'other': 'Impossible de terminer le tour.',
    });
    return '$_temp0';
  }

  @override
  String get loadingMap => 'Chargement de la carte';

  @override
  String get mapLoadingFailed => 'Échec du chargement de la carte';

  @override
  String get mapUnavailable => 'Carte indisponible';

  @override
  String get mapAdapterUnavailable =>
      'L’adaptateur natif du jeu n’est pas disponible sur cette plateforme.';

  @override
  String get mapClientIncompatible =>
      'L’adaptateur natif du jeu est incompatible avec ce client.';

  @override
  String get mapLoadSuperseded =>
      'Une demande de carte plus récente a remplacé celle-ci.';

  @override
  String get mapLoadFailure => 'Impossible de charger la carte.';

  @override
  String get movementRequestFailed =>
      'La demande de déplacement n’a pas pu aboutir.';

  @override
  String get movementResponseIncompatible =>
      'La réponse de déplacement est incompatible avec ce client.';

  @override
  String get movementSessionUnavailable =>
      'La session de jeu locale n’est pas disponible.';

  @override
  String get moveRejectedStale =>
      'L’état de la partie a changé. Vérifiez la dernière position et réessayez.';

  @override
  String get moveRejectedUnitUnavailable =>
      'Cette unité n’est plus disponible pour un déplacement.';

  @override
  String get moveRejectedUnitBusy =>
      'Cette unité est occupée et ne peut pas se déplacer maintenant.';

  @override
  String get moveRejectedTargetUnavailable =>
      'Cette destination n’est pas disponible.';

  @override
  String get moveRejectedMovementInsufficient =>
      'L’unité n’a pas assez de points de déplacement restants.';

  @override
  String get moveRejectedPathUnavailable =>
      'Aucun itinéraire valide ne mène à cette destination.';

  @override
  String get moveRejectedInternal =>
      'Impossible d’appliquer le déplacement. Réessayez.';

  @override
  String get retry => 'Réessayer';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get audioSettings => 'Audio';

  @override
  String get cameraSettings => 'Caméra';

  @override
  String get cameraSensitivity => 'Sensibilité du zoom';

  @override
  String get animationSettings => 'Animations';

  @override
  String get showUnitMovementAnimations =>
      'Afficher les animations de déplacement des unités';

  @override
  String get showUnitIdleAnimations =>
      'Afficher les animations des unités au repos';

  @override
  String get showRouteAnimations =>
      'Afficher les animations des itinéraires prévus';

  @override
  String get showCombatAnimations => 'Afficher les animations de combat';

  @override
  String get cinematicCamera => 'Caméra cinématique';

  @override
  String get smoothCameraMovement => 'Mouvement fluide de la caméra';

  @override
  String get mapSettings => 'Carte';

  @override
  String get mapGrid => 'Bordures des hexagones';

  @override
  String get mapGridDescription =>
      'Afficher des bordures noires autour des hexagones de la carte.';

  @override
  String get mapResourceIcons => 'Icônes des ressources';

  @override
  String get mapResourceIconsDescription =>
      'Afficher les ressources disponibles sur les hexagones de la carte.';

  @override
  String get mapTerrainIcons => 'Icônes du terrain';

  @override
  String get mapTerrainIconsDescription =>
      'Afficher les caractéristiques du terrain de chaque hexagone.';

  @override
  String get mapHeightBadges => 'Indicateurs de hauteur';

  @override
  String get mapHeightBadgesDescription =>
      'Afficher la hauteur définie pour les hexagones surélevés.';

  @override
  String get mapElevationWalls => 'Parois de relief';

  @override
  String get mapElevationWallsDescription =>
      'Afficher la profondeur des hexagones surélevés en fonction de leurs voisins.';

  @override
  String get accessibilitySettings => 'Accessibilité';

  @override
  String get reducedMotion => 'Réduire les animations';

  @override
  String get reducedMotionDescription =>
      'Éviter les animations et transitions non essentielles.';

  @override
  String get highContrast => 'Contraste élevé';

  @override
  String get highContrastDescription =>
      'Augmenter le contraste de l’interface de l’application.';

  @override
  String get resetSettings => 'Rétablir les valeurs par défaut';

  @override
  String get objectivesTitle => 'Objectifs stratégiques';

  @override
  String get openObjectives => 'Ouvrir les objectifs';

  @override
  String get closeObjectives => 'Fermer les objectifs';

  @override
  String get objectivesEmpty => 'Cette carte n’a aucun objectif.';

  @override
  String get objectivesAuthoredRules =>
      'Conditions définies pour la carte. Le moteur conserve la progression actuelle.';

  @override
  String objectiveType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'ruins': 'Ruines',
      'strategicPass': 'Passage stratégique',
      'holySite': 'Lieu saint',
      'legendaryResource': 'Ressource légendaire',
      'other': 'Objectif stratégique',
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
    return 'Hexagone $col, $row\nTours de contrôle requis : $holdTurns · Points de victoire : $victoryPoints · Or par tour : $goldPerTurn';
  }

  @override
  String get matchFinishedTitle => 'Partie terminée';

  @override
  String outcomeWinner(String playerId) {
    return 'Vainqueur : $playerId';
  }

  @override
  String get outcomeNoWinner => 'Aucun vainqueur';

  @override
  String get outcomeFinalScore => 'Score final';

  @override
  String outcomeScoreLine(String playerId, int score) {
    return '$playerId : $score';
  }

  @override
  String cityText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Ville',
      'foundingTitle': 'Fonder une ville',
      'loading': 'Chargement des détails de la ville',
      'owner': 'Propriétaire',
      'health': 'Santé',
      'population': 'Population',
      'territory': 'Territoire',
      'foundingSelection': 'Territoire initial',
      'foundingConfirm': 'Confirmer la fondation de la ville',
      'foundingCancel': 'Annuler la fondation',
      'executing': 'Application de l’action de la ville',
      'cityYield': 'Rendement',
      'food': 'Nourriture',
      'production': 'Production',
      'gold': 'Or',
      'defense': 'Défense',
      'workedHexes': 'Hexagones exploités',
      'workedHexSelect': 'Gérer les hexagones exploités',
      'workedHexHint':
          'Sélectionnez un hexagone contrôlé en surbrillance sur la carte.',
      'expansion': 'Expansion privilégiée',
      'expansionSelect': 'Choisir l’expansion',
      'expansionHint':
          'Sélectionnez un hexagone d’expansion en surbrillance sur la carte.',
      'managementCancel': 'Terminer la sélection sur la carte',
      'foundingOpen': 'Planifier une ville',
      'other': 'Ville',
    });
    return '$_temp0';
  }

  @override
  String cityFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'La demande concernant la ville n’a pas pu aboutir.',
      'responseIncompatible':
          'La réponse concernant la ville est incompatible avec ce client.',
      'sessionUnavailable': 'La session de jeu locale n’est pas disponible.',
      'staleRevision':
          'L’état de la partie a changé. Vérifiez la ville et réessayez.',
      'matchFinished': 'La partie est déjà terminée.',
      'cityFounderNotFound': 'L’unité fondatrice n’est plus disponible.',
      'cityFounderNotControlled':
          'Ce joueur ne contrôle pas l’unité fondatrice.',
      'cityFounderBusy': 'L’unité fondatrice est occupée.',
      'cityFounderInvalid': 'Cette unité ne peut pas fonder de ville.',
      'cityFounderNoSettlers': 'L’unité fondatrice ne dispose d’aucun colon.',
      'citySiteInvalid': 'Il est impossible de fonder une ville à cet endroit.',
      'cityCenterOccupied': 'Le centre de la ville est occupé.',
      'cityCenterClaimed': 'Le centre de la ville est déjà revendiqué.',
      'cityCenterTooClose':
          'Le centre de la ville est trop proche d’une autre ville.',
      'cityControlledHexesInvalid':
          'Le territoire initial sélectionné est invalide.',
      'cityNotFound': 'Cette ville n’est plus disponible.',
      'cityNotControlled': 'Ce joueur ne contrôle pas cette ville.',
      'workedHexUnavailable': 'Cet hexagone exploité n’est pas disponible.',
      'workedHexLimitReached':
          'La ville a atteint sa limite d’hexagones exploités.',
      'cityExpansionHexUnavailable':
          'Cet hexagone d’expansion n’est pas disponible.',
      'stateRevisionOverflow': 'L’état de la partie ne peut plus évoluer.',
      'other': 'La demande concernant la ville n’a pas pu aboutir.',
    });
    return '$_temp0';
  }

  @override
  String workerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Ouvrier',
      'loading': 'Chargement des options de l’ouvrier',
      'empty': 'Aucune action d’ouvrier n’est disponible actuellement.',
      'executing': 'Application de l’action de l’ouvrier',
      'buildCharges': 'Charges de construction',
      'progress': 'Progression',
      'assigned': 'Hexagone assigné',
      'openActions': 'Aménager l’hexagone',
      'closeActions': 'Annuler la sélection',
      'selectImprovement': 'Sélectionner',
      'confirmImprovement': 'Confirmer l’aménagement',
      'cancelJob': 'Annuler la construction',
      'assign': 'Assigner à l’hexagone',
      'cancelAssignment': 'Annuler l’affectation',
      'buildRoad': 'Construire une route',
      'automate': 'Automatiser',
      'automationEvidence': 'Détails du planificateur',
      'other': 'Ouvrier',
    });
    return '$_temp0';
  }

  @override
  String workerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'La demande concernant l’ouvrier n’a pas pu aboutir.',
      'responseIncompatible':
          'La réponse concernant l’ouvrier est incompatible avec ce client.',
      'sessionUnavailable': 'La session de jeu locale n’est pas disponible.',
      'staleRevision':
          'L’état de la partie a changé. Vérifiez l’ouvrier et réessayez.',
      'matchFinished': 'La partie est déjà terminée.',
      'workerNotFound': 'L’ouvrier n’est plus disponible.',
      'workerNotControlled': 'Ce joueur ne contrôle pas l’ouvrier.',
      'workerUnavailable': 'L’ouvrier n’est pas disponible.',
      'workerNoMovementPoints': 'L’ouvrier n’a plus de points de déplacement.',
      'workerQueuedPathActive': 'L’ouvrier a un ordre de déplacement actif.',
      'workerImprovementNotSelected': 'Sélectionnez d’abord un aménagement.',
      'workerActionNotControlled':
          'L’action d’ouvrier en attente n’est pas contrôlée par ce joueur.',
      'workerImprovementUnavailable': 'Cet aménagement n’est pas disponible.',
      'workerJobNotActive': 'L’ouvrier n’a aucune construction en cours.',
      'workerAssignmentUnavailable': 'L’ouvrier ne peut pas être assigné ici.',
      'workerAssignmentNotActive': 'L’ouvrier n’a aucune affectation active.',
      'workerRoadUnavailable':
          'La construction d’une route n’est pas possible ici.',
      'roadConstructionExistingRoad': 'Une route existe déjà ici.',
      'roadConstructionCity':
          'Une route ne peut pas être construite sur un centre-ville.',
      'roadConstructionEnemyTerritory':
          'Une route ne peut pas être construite en territoire ennemi.',
      'roadConstructionImpassableTerrain':
          'Une route ne peut pas être construite sur ce terrain.',
      'workerAutomationNotActive':
          'L’automatisation de l’ouvrier n’est pas active.',
      'workerAutomationNoTarget':
          'L’automatisation de l’ouvrier n’a trouvé aucune cible.',
      'stateRevisionOverflow': 'L’état de la partie ne peut plus évoluer.',
      'other': 'La demande concernant l’ouvrier n’a pas pu aboutir.',
    });
    return '$_temp0';
  }

  @override
  String productionText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Production et ressources',
      'loading': 'Chargement des options de production',
      'executing': 'Mise à jour de la production de la ville',
      'current': 'Production actuelle',
      'invested': 'Investissement',
      'overflow': 'Excédent',
      'resources': 'Ressources stratégiques',
      'buildings': 'Bâtiments',
      'units': 'Unités',
      'projects': 'Projets',
      'wonders': 'Merveilles',
      'specializations': 'Spécialisations',
      'rush': 'Accélérer la production',
      'cost': 'coût',
      'requires': 'nécessite',
      'empty': 'Aucune option n’est disponible actuellement.',
      'other': 'Production',
    });
    return '$_temp0';
  }

  @override
  String productionFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'La demande de production n’a pas pu aboutir.',
      'responseIncompatible': 'La réponse de production est incompatible.',
      'sessionUnavailable': 'La session de jeu locale n’est pas disponible.',
      'staleRevision':
          'La ville a changé. Vérifiez la production et réessayez.',
      'matchFinished': 'La partie est déjà terminée.',
      'cityNotFound': 'La ville n’est plus disponible.',
      'cityNotControlled': 'Ce joueur ne contrôle pas la ville.',
      'buildingNotAvailable': 'Ce bâtiment n’est pas disponible.',
      'unitProductionInvalidResourceOption':
          'Cette option de ressource est invalide.',
      'unitProductionNotAvailable': 'Cette unité n’est pas disponible.',
      'unitProductionRequiresResource': 'Sélectionnez une option de ressource.',
      'unitProductionMissingStrategicResource':
          'Les ressources requises sont manquantes.',
      'unitProductionRequiresCoast': 'Cette unité nécessite une ville côtière.',
      'unitSupplyLimitReached':
          'La limite d’entretien des unités est atteinte.',
      'wonderNotAvailable': 'Cette merveille n’est pas disponible.',
      'citySpecializationLocked': 'Cette spécialisation est verrouillée.',
      'citySpecializationUnchanged': 'Cette spécialisation est déjà active.',
      'citySpecializationMissingBuilding': 'Un bâtiment requis est manquant.',
      'productionQueueEmpty': 'La file de production est vide.',
      'projectCannotBeRushed': 'Un projet continu ne peut pas être accéléré.',
      'rushProductionUnavailable':
          'L’accélération de la production n’est pas disponible.',
      'stateRevisionOverflow': 'L’état de la partie ne peut plus évoluer.',
      'other': 'La demande de production n’a pas pu aboutir.',
    });
    return '$_temp0';
  }

  @override
  String artifactText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Artefacts du monde',
      'executing': 'Application de l’action d’artefact',
      'startExcavation': 'Commencer les fouilles',
      'storeInCity': 'Déposer dans une ville',
      'trade': 'Échanger l’artefact',
      'targetPlayer': 'Joueur destinataire',
      'offeredGold': 'Or proposé',
      'onMap': 'Sur la carte en',
      'carried': 'Transporté par',
      'stored': 'Déposé dans',
      'excavation': 'Fouilles en',
      'turnsRemaining': 'tours restants',
      'other': 'Artefact',
    });
    return '$_temp0';
  }

  @override
  String artifactName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ancientImperialCrown': 'Couronne impériale antique',
      'astronomersTablets': 'Tablettes de l’astronome',
      'prophetMask': 'Masque du prophète',
      'heroSword': 'Épée du héros',
      'merchantsSeal': 'Sceau du marchand',
      'firstPeoplesChronicle': 'Chronique des premiers peuples',
      'templeReliquary': 'Reliquaire du temple',
      'queensMirror': 'Miroir de la reine',
      'other': 'Artefact du monde',
    });
    return '$_temp0';
  }

  @override
  String artifactOnMap(int col, int row) {
    return 'Sur la carte en $col, $row';
  }

  @override
  String artifactCarriedBy(String unitName) {
    return 'Transporté par $unitName';
  }

  @override
  String artifactStoredIn(String cityName) {
    return 'Déposé dans $cityName';
  }

  @override
  String artifactExcavationAt(int col, int row, int remainingTurns) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingTurns,
      locale: localeName,
      other: '$remainingTurns tours restants',
      one: '$remainingTurns tour restant',
    );
    return 'Fouilles en $col, $row · $_temp0';
  }

  @override
  String artifactFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'La demande concernant l’artefact n’a pas pu aboutir.',
      'responseIncompatible':
          'La réponse concernant l’artefact est incompatible.',
      'sessionUnavailable': 'La session de jeu locale n’est pas disponible.',
      'staleRevision':
          'L’état de la partie a changé. Vérifiez l’artefact et réessayez.',
      'matchFinished': 'La partie est déjà terminée.',
      'unitNotFound': 'L’unité n’est plus disponible.',
      'unitNotControlled': 'Ce joueur ne contrôle pas l’unité.',
      'unitUnavailable': 'L’unité n’est pas disponible.',
      'unitAlreadyCarryingArtifact': 'L’unité transporte déjà un artefact.',
      'artifactNotFound': 'L’artefact n’est plus disponible.',
      'unitNotCarryingArtifact': 'L’unité ne transporte aucun artefact.',
      'cityNotFound': 'La ville n’est plus disponible.',
      'cityNotControlled': 'Ce joueur ne contrôle pas la ville.',
      'unitNotInCity': 'L’unité ne se trouve pas dans cette ville.',
      'cityArtifactSlotFull':
          'L’emplacement d’artefact de la ville est occupé.',
      'artifactTradeActorUnavailable':
          'Ce joueur ne peut pas échanger d’artefacts.',
      'artifactTradeTargetInvalid': 'Le joueur destinataire est invalide.',
      'artifactTradeGoldInvalid': 'L’offre d’or est invalide.',
      'artifactTradeBlockedByWar':
          'La guerre empêche les échanges d’artefacts.',
      'artifactTradeGoldUnavailable': 'L’or proposé n’est pas disponible.',
      'offeredArtifactUnavailable': 'L’artefact proposé n’est pas disponible.',
      'targetArtifactSlotUnavailable':
          'Le destinataire n’a aucun emplacement d’artefact disponible.',
      'stateRevisionOverflow': 'L’état de la partie ne peut plus évoluer.',
      'other': 'La demande concernant l’artefact n’a pas pu aboutir.',
    });
    return '$_temp0';
  }

  @override
  String researchText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Recherche',
      'open': 'Ouvrir la recherche',
      'close': 'Fermer la recherche',
      'loading': 'Chargement des options de recherche',
      'retry': 'Réessayer',
      'selecting': 'Sélection de la technologie',
      'selectionRequired': 'Sélectionnez une technologie pour continuer',
      'sciencePerTurn': 'Science par tour',
      'overflow': 'Science accumulée',
      'active': 'Technologie active',
      'none': 'Aucune',
      'cost': 'Coût',
      'progress': 'Progression',
      'boost': 'Réduction par accélération',
      'prerequisites': 'Prérequis',
      'blockedBy': 'Bloquée par',
      'unlocks': 'Débloque',
      'choose': 'Sélectionner',
      'other': 'Recherche',
    });
    return '$_temp0';
  }

  @override
  String researchAvailability(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unlocked': 'Recherchée',
      'active': 'Active',
      'available': 'Disponible',
      'lockedByPrerequisites': 'Prérequis nécessaires',
      'lockedByTechnology': 'Bloquée par une technologie',
      'other': 'Indisponible',
    });
    return '$_temp0';
  }

  @override
  String researchUnlock(String kind, String target) {
    return '$kind : $target';
  }

  @override
  String researchFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'La demande de recherche n’a pas pu aboutir.',
      'responseIncompatible': 'La réponse de recherche est incompatible.',
      'sessionUnavailable': 'La session de jeu locale n’est pas disponible.',
      'staleRevision':
          'La recherche a changé. Vérifiez les options et réessayez.',
      'technologyPlayerNotControlled':
          'Ce joueur ne peut pas choisir de recherche.',
      'technologyNotAvailable': 'Cette technologie n’est pas disponible.',
      'stateRevisionOverflow': 'L’état de la partie ne peut plus évoluer.',
      'other': 'La demande de recherche n’a pas pu aboutir.',
    });
    return '$_temp0';
  }

  @override
  String diplomacyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Diplomatie',
      'open': 'Ouvrir la diplomatie',
      'close': 'Fermer la diplomatie',
      'noContacts': 'Aucun contact',
      'compose': 'Nouvelle action',
      'target': 'Interlocuteur',
      'action': 'Action',
      'send': 'Envoyer',
      'invalid': 'Vérifiez les conditions du formulaire.',
      'pending': 'Envoi de l’action diplomatique',
      'relations': 'Relations',
      'proposals': 'Propositions',
      'messages': 'Messages privés',
      'agreements': 'Accords de ressources',
      'accept': 'Accepter',
      'reject': 'Refuser',
      'amount': 'Quantité',
      'goldPerTurn': 'Or par tour',
      'duration': 'Tours',
      'resource': 'Ressource',
      'offered': 'Ressource proposée',
      'requested': 'Ressource demandée',
      'topic': 'Sujet',
      'other': 'Diplomatie',
    });
    return '$_temp0';
  }

  @override
  String diplomacyFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'La demande diplomatique n’a pas pu aboutir.',
      'responseIncompatible': 'La réponse diplomatique est incompatible.',
      'sessionUnavailable': 'La session de jeu locale n’est pas disponible.',
      'staleRevision':
          'La situation diplomatique a changé. Vérifiez l’état actuel et réessayez.',
      'matchFinished': 'La partie est déjà terminée.',
      'diplomacyPlayerNotControlled':
          'Ce joueur ne peut pas effectuer d’actions diplomatiques.',
      'diplomacyTargetNotDiscovered': 'Cet interlocuteur n’est pas disponible.',
      'diplomacyProposalNotAllowed': 'Cette proposition n’est pas autorisée.',
      'diplomacyDuplicateProposal': 'Cette proposition existe déjà.',
      'diplomacyProposalNotFound': 'Cette proposition n’existe plus.',
      'diplomacyProposalPaymentUnavailable':
          'Le paiement de la proposition n’est pas disponible.',
      'diplomacyMessageCooldown':
          'Un message similaire a été envoyé trop récemment.',
      'diplomacyDuplicateMessage': 'Ce message existe déjà.',
      'diplomacyMessageNotFound': 'Ce message n’existe plus.',
      'diplomacyMessageUnavailable':
          'Ce message ne peut pas être utilisé maintenant.',
      'diplomacyTruceActive': 'Une trêve est en vigueur.',
      'diplomacyWarAlreadyActive': 'La guerre est déjà déclarée.',
      'diplomacyInvalidGoldAmount': 'La quantité d’or est invalide.',
      'diplomacyGoldGiftBlockedByRelation':
          'Cette relation empêche les dons d’or.',
      'diplomacyGoldUnavailable': 'L’or requis n’est pas disponible.',
      'diplomacyGoldGiftUnavailable': 'Ce don d’or n’est pas disponible.',
      'invalidResourceTradeTarget':
          'Le destinataire de l’échange de ressources est invalide.',
      'invalidResourceTradeResource': 'La ressource sélectionnée est invalide.',
      'invalidResourceTradeTerms':
          'Les conditions de l’échange de ressources sont invalides.',
      'resourceTradeBlockedByWar':
          'La guerre empêche cet échange de ressources.',
      'resourceTradeGoldUnavailable':
          'L’or nécessaire à l’échange n’est pas disponible.',
      'resourceTradeAlreadyActive': 'Cet échange de ressources est déjà actif.',
      'invalidResourceTradeAgreementId':
          'L’identifiant de l’accord est invalide.',
      'resourceTradeAgreementIdConflict':
          'L’identifiant de l’accord est en conflit.',
      'resourceTradeExportUnavailable':
          'L’exportation de ressources n’est pas disponible.',
      'resourceTradeOfferUnavailable':
          'La ressource proposée n’est pas disponible.',
      'resourceTradeRequestUnavailable':
          'La ressource demandée n’est pas disponible.',
      'stateRevisionOverflow': 'L’état de la partie ne peut plus évoluer.',
      'other': 'La demande diplomatique n’a pas pu aboutir.',
    });
    return '$_temp0';
  }

  @override
  String presentationName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'farm': 'Ferme',
      'riverFarm': 'Ferme riveraine',
      'mine': 'Mine',
      'lumberMill': 'Scierie',
      'pasture': 'Pâturage',
      'camp': 'Camp',
      'quarry': 'Carrière',
      'fishingBoats': 'Bateaux de pêche',
      'orchard': 'Verger',
      'plantation': 'Plantation',
      'vineyard': 'Vignoble',
      'tradingPost': 'Comptoir commercial',
      'prospectorCamp': 'Camp de prospecteurs',
      'horseRanch': 'Élevage de chevaux',
      'pearlDivers': 'Plongeurs de perles',
      'coalShaft': 'Puits de charbon',
      'oilWell': 'Puits de pétrole',
      'bauxiteMine': 'Mine de bauxite',
      'uraniumMine': 'Mine d’uranium',
      'wheat': 'Blé',
      'fish': 'Poisson',
      'deer': 'Cerf',
      'sheep': 'Mouton',
      'rice': 'Riz',
      'cow': 'Vache',
      'apple': 'Pomme',
      'banana': 'Banane',
      'citrus': 'Agrumes',
      'gold': 'Or',
      'silver': 'Argent',
      'gems': 'Pierres précieuses',
      'silk': 'Soie',
      'spices': 'Épices',
      'cotton': 'Coton',
      'grapes': 'Raisin',
      'ivory': 'Ivoire',
      'pearls': 'Perles',
      'coffee': 'Café',
      'cocoa': 'Cacao',
      'tobacco': 'Tabac',
      'sugar': 'Sucre',
      'iron': 'Fer',
      'coal': 'Charbon',
      'oil': 'Pétrole',
      'aluminium': 'Aluminium',
      'uranium': 'Uranium',
      'horses': 'Chevaux',
      'marble': 'Marbre',
      'commander': 'Commandant',
      'warrior': 'Guerrier',
      'archer': 'Archer',
      'settler': 'Colon',
      'worker': 'Ouvrier',
      'merchant': 'Marchand',
      'scout': 'Éclaireur',
      'spearman': 'Lancier',
      'cavalry': 'Cavalerie',
      'catapult': 'Catapulte',
      'heavyInfantry': 'Infanterie lourde',
      'fieldCannon': 'Canon de campagne',
      'rifleman': 'Fusilier',
      'tank': 'Char',
      'scoutShip': 'Navire d’exploration',
      'warship': 'Navire de guerre',
      'reconPlane': 'Avion de reconnaissance',
      'building': 'Bâtiment',
      'improvement': 'Aménagement',
      'resourceVisibility': 'Visibilité des ressources',
      'unit': 'Unité',
      'wonder': 'Merveille',
      'friendly': 'Amicale',
      'neutral': 'Neutre',
      'hostile': 'Hostile',
      'truce': 'Trêve',
      'war': 'Guerre',
      'warning': 'Avertissement',
      'complaint': 'Plainte',
      'request': 'Demande',
      'praise': 'Éloge',
      'threat': 'Menace',
      'cooperation': 'Coopération',
      'troopsNearCities': 'Troupes près des villes',
      'citiesTooClose': 'Villes trop proches',
      'blockedRoutes': 'Itinéraires bloqués',
      'withdrawScouts': 'Retirer les éclaireurs',
      'avoidEscalation': 'Éviter l’escalade',
      'commonEnemy': 'Ennemi commun',
      'expansionProvocation': 'Provocation par l’expansion',
      'peacefulPraise': 'Éloge pacifique',
      'conciliatory': 'Conciliante',
      'evasive': 'Évasive',
      'aggressive': 'Agressive',
      'declareWar': 'Déclarer la guerre',
      'goldGift': 'Don d’or',
      'friendshipProposal': 'Proposition d’amitié',
      'truceProposal': 'Proposition de trêve',
      'message': 'Message',
      'resourceTrade': 'Commerce de ressources',
      'resourceExchange': 'Échange de ressources',
      'granary': 'Grenier',
      'workshop': 'Atelier',
      'industry': 'Industrie',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String technologyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'agriculture': 'Agriculture',
      'woodworking': 'Travail du bois',
      'mining': 'Exploitation minière',
      'animalHusbandry': 'Élevage',
      'hunting': 'Chasse',
      'fishing': 'Pêche',
      'craftsmanship': 'Artisanat',
      'trade': 'Commerce',
      'storage': 'Stockage',
      'waterEngineering': 'Hydraulique',
      'stoneworking': 'Taille de la pierre',
      'militaryOrganization': 'Organisation militaire',
      'advancedTrade': 'Commerce avancé',
      'construction': 'Construction',
      'navigation': 'Navigation',
      'irrigation': 'Irrigation',
      'banking': 'Banque',
      'engineering': 'Ingénierie',
      'metallurgy': 'Métallurgie',
      'horsebackRiding': 'Équitation',
      'ironWorking': 'Travail du fer',
      'coalMining': 'Extraction du charbon',
      'machinery': 'Machines',
      'administration': 'Administration',
      'logistics': 'Logistique',
      'shipbuilding': 'Construction navale',
      'tactics': 'Tactique',
      'economy': 'Économie',
      'urbanization': 'Urbanisation',
      'fortifications': 'Fortifications',
      'strategy': 'Stratégie',
      'specialization': 'Spécialisation',
      'writing': 'Écriture',
      'mathematics': 'Mathématiques',
      'medicine': 'Médecine',
      'civilService': 'Fonction publique',
      'siegecraft': 'Techniques de siège',
      'cartography': 'Cartographie',
      'guilds': 'Guildes',
      'law': 'Droit',
      'education': 'Éducation',
      'urbanPlanning': 'Urbanisme',
      'navalDoctrine': 'Doctrine navale',
      'steel': 'Acier',
      'bureaucracy': 'Bureaucratie',
      'nationalism': 'Nationalisme',
      'scientificMethod': 'Méthode scientifique',
      'steamPower': 'Machine à vapeur',
      'electricity': 'Électricité',
      'combustion': 'Combustion',
      'flight': 'Aviation',
      'massProduction': 'Production de masse',
      'radio': 'Radio',
      'nuclearPhysics': 'Physique nucléaire',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String cityContentName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'growth': 'Croissance',
      'industry': 'Industrie',
      'commerce': 'Commerce',
      'science': 'Science',
      'military': 'Militaire',
      'wealth': 'Richesse',
      'research': 'Recherche',
      'granary': 'Grenier',
      'waterMill': 'Moulin à eau',
      'workshop': 'Atelier',
      'storehouse': 'Entrepôt',
      'housing': 'Logements',
      'merchantHall': 'Halle marchande',
      'stonemason': 'Tailleur de pierre',
      'barracks': 'Caserne',
      'marketplace': 'Marché',
      'port': 'Port',
      'aqueduct': 'Aqueduc',
      'forge': 'Forge',
      'stable': 'Écurie',
      'bank': 'Banque',
      'buildersGuild': 'Guilde des bâtisseurs',
      'factory': 'Usine',
      'lighthouse': 'Phare',
      'trainingGrounds': 'Terrain d’entraînement',
      'townHall': 'Hôtel de ville',
      'monument': 'Monument',
      'archive': 'Archives',
      'academy': 'Académie',
      'university': 'Université',
      'observatory': 'Observatoire',
      'laboratory': 'Laboratoire',
      'reactor': 'Réacteur',
      'courthouse': 'Palais de justice',
      'court': 'Cour',
      'governorsOffice': 'Bureau du gouverneur',
      'surveyorsOffice': 'Bureau des géomètres',
      'planningOffice': 'Bureau d’urbanisme',
      'apothecary': 'Apothicairerie',
      'publicBaths': 'Bains publics',
      'hospital': 'Hôpital',
      'ministries': 'Ministères',
      'walls': 'Remparts',
      'armory': 'Armurerie',
      'siegeWorkshop': 'Atelier de siège',
      'citadel': 'Citadelle',
      'warCollege': 'École de guerre',
      'conscriptionOffice': 'Bureau de conscription',
      'borderFort': 'Fort frontalier',
      'airfield': 'Aérodrome',
      'artisansGuild': 'Guilde des artisans',
      'masterWorkshop': 'Atelier de maître',
      'steelworks': 'Aciérie',
      'railDepot': 'Dépôt ferroviaire',
      'powerPlant': 'Centrale électrique',
      'assemblyPlant': 'Usine d’assemblage',
      'refinery': 'Raffinerie',
      'mapRoom': 'Salle des cartes',
      'shipyard': 'Chantier naval',
      'dryDock': 'Cale sèche',
      'navalAcademy': 'École navale',
      'harborCustoms': 'Douanes portuaires',
      'museum': 'Musée',
      'parliament': 'Parlement',
      'broadcastTower': 'Tour de radiodiffusion',
      'worldFairGrounds': 'Site d’exposition universelle',
      'greatLibrary': 'Grande Bibliothèque',
      'hangingGardens': 'Jardins suspendus',
      'greatWall': 'Grande Muraille',
      'petra': 'Pétra',
      'centralBank': 'Banque centrale',
      'imperialUniversity': 'Université impériale',
      'grandCathedral': 'Grande Cathédrale',
      'motherFactory': 'Usine mère',
      'nationalObservatory': 'Observatoire national',
      'svalbardSeedVault': 'Réserve de semences du Svalbard',
      'grandExposition': 'Grande Exposition',
      'other': 'Élément de ville inconnu',
    });
    return '$_temp0';
  }

  @override
  String diplomaticProposalName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'friendship': 'Amitié',
      'truce': 'Trêve',
      'other': 'Proposition inconnue',
    });
    return '$_temp0';
  }

  @override
  String mapFeedbackText(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'roadCompleted': '+Route',
      'unitKilled': 'KO',
      'unitRetreated': 'Repli',
      'artifactExcavationStarted': 'Fouilles',
      'artifactCarried': 'Artefact transporté',
      'artifactStored': 'Artefact déposé',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String mapYieldShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'food': 'NOURR',
      'production': 'PROD',
      'gold': 'OR',
      'defense': 'DÉF',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get focusOwnUnitMovement =>
      'Centrer la caméra sur les déplacements de mes unités';

  @override
  String get followOwnUnitMovement =>
      'Suivre les déplacements de mes unités avec la caméra';

  @override
  String get focusForeignUnitMovement =>
      'Centrer la caméra sur les déplacements des unités ennemies';

  @override
  String get followForeignUnitMovement =>
      'Suivre les déplacements des unités ennemies avec la caméra';

  @override
  String get gameSoundsLabel => 'Sons du jeu';

  @override
  String get soundVolumeLabel => 'Volume des sons';

  @override
  String get gameMusicLabel => 'Musique du jeu';

  @override
  String get musicVolumeLabel => 'Volume de la musique';

  @override
  String get natureSoundsLabel => 'Sons de la nature';

  @override
  String get natureVolumeLabel => 'Volume de la nature';

  @override
  String hexInspectionKind(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite': 'Site idéal pour une ville',
      'goodCitySite': 'Bon site pour une ville',
      'fertileField': 'Champ fertile',
      'fertilePlains': 'Plaines fertiles',
      'richPlain': 'Plaine riche',
      'strategicBorderland': 'Zone frontalière stratégique',
      'strategicField': 'Champ stratégique',
      'defensivePosition': 'Position défensive',
      'fertileForest': 'Forêt fertile',
      'forestBackline': 'Arrière-pays forestier',
      'forestForge': 'Forêt industrielle',
      'wildLand': 'Terre sauvage',
      'richWilds': 'Terres sauvages riches',
      'exoticBackline': 'Arrière-pays exotique',
      'difficultStrategicTerrain': 'Terrain stratégique difficile',
      'highGround': 'Hauteurs',
      'riverHills': 'Collines riveraines',
      'industrialStronghold': 'Bastion industriel',
      'richHills': 'Collines riches',
      'barrenLand': 'Terre aride',
      'oasis': 'Oasis',
      'tradeOasis': 'Oasis commerciale',
      'desertDeposits': 'Gisements désertiques',
      'harshLand': 'Terre inhospitalière',
      'coldPastures': 'Pâturages froids',
      'resourceOutpost': 'Avant-poste de ressources',
      'hostileLand': 'Terre hostile',
      'arcticDeposits': 'Gisements arctiques',
      'coast': 'Côte',
      'fishingCoast': 'Côte poissonneuse',
      'richCoast': 'Côte riche',
      'riverPort': 'Port fluvial',
      'regionalPortHeart': 'Pôle portuaire régional',
      'openSea': 'Haute mer',
      'naturalBarrier': 'Barrière naturelle',
      'promisingLand': 'Terre prometteuse',
      'weakLand': 'Terre peu productive',
      'ordinaryLand': 'Terre ordinaire',
      'mapTile': 'Case de la carte',
      'other': 'Case de la carte',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionDescription(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite':
          'Une case de grande valeur pour une colonie, réunissant nourriture, croissance et potentiel d’expansion.',
      'goodCitySite':
          'Un terrain solide pour un centre-ville, avec assez de valeur initiale pour soutenir les premiers développements.',
      'fertileField':
          'Une prairie irriguée par une rivière, favorable à la nourriture, à la croissance démographique et aux aménagements des ouvriers.',
      'fertilePlains':
          'Des plaines ouvertes près d’une rivière, utiles pour équilibrer nourriture et production.',
      'richPlain':
          'Une case ouverte de valeur, dotée de ressources de luxe ou d’un potentiel commercial, à intégrer dans vos frontières.',
      'strategicBorderland':
          'Une bonne terre à valeur stratégique, utile pour s’étendre avant que les rivaux ne la revendiquent.',
      'strategicField':
          'Une plaine liée à des ressources stratégiques ou à des tensions frontalières.',
      'defensivePosition':
          'Un terrain qui renforce le contrôle défensif et aide à tenir les accès voisins.',
      'fertileForest':
          'Une forêt proche d’une rivière, mêlant potentiel de croissance et couvert naturel.',
      'forestBackline':
          'Une case forestière plus sûre, pouvant soutenir la croissance ou des aménagements de chasse.',
      'forestForge':
          'Une forêt dotée de ressources industrielles, prometteuse pour la production après aménagement.',
      'wildLand':
          'Un terrain dense et contraignant, utile seulement avec un plan précis de travaux ou d’expansion.',
      'richWilds':
          'Un terrain sauvage assez fertile ou riche en ressources pour justifier un développement réfléchi.',
      'exoticBackline':
          'Une case de jungle ou de zone humide dotée de ressources de luxe, utile à une future expansion ou au commerce.',
      'difficultStrategicTerrain':
          'Un terrain difficile riche en ressources stratégiques, puissant à long terme mais peu commode au début.',
      'highGround':
          'Des collines favorisant davantage la défense et le contrôle de la carte qu’une croissance rapide.',
      'riverHills':
          'Des collines au bord d’une rivière, associant défense et meilleur potentiel économique.',
      'industrialStronghold':
          'Des collines dotées de ressources industrielles, une excellente cible pour la production d’une ville.',
      'richHills':
          'Des collines riches en ressources précieuses, utiles pour une expansion axée sur l’or ou la production.',
      'barrenLand':
          'Une terre sèche à faible valeur immédiate, sauf si de futures technologies ou frontières changent la donne.',
      'oasis':
          'Un désert adouci par l’accès à une rivière, transformant une terre peu productive en case propice à la croissance.',
      'tradeOasis':
          'Une poche commerciale désertique pouvant devenir précieuse avec le bon aménagement.',
      'desertDeposits':
          'Une terre peu adaptée aux colonies, mais dotée d’un gisement stratégique important aux époques ultérieures.',
      'harshLand':
          'Une terre froide ou accidentée, à l’économie initiale limitée et au développement lent.',
      'coldPastures':
          'Un terrain froid offrant assez de pâturages pour soutenir une ville frontalière.',
      'resourceOutpost':
          'Une terre froide et reculée à revendiquer surtout pour la ressource qu’elle protège.',
      'hostileLand':
          'Un terrain hostile, peu adapté aux colonies et offrant peu de rendements immédiats.',
      'arcticDeposits':
          'Une terre enneigée dotée de ressources, difficile à exploiter mais potentiellement stratégique.',
      'coast':
          'Un terrain côtier ouvrant un accès naval et des possibilités variées de croissance urbaine.',
      'fishingCoast':
          'Une côte nourricière, bonne raison d’exploiter les abords de l’eau ou de s’y installer.',
      'richCoast':
          'Des ressources de luxe ou un potentiel commercial côtier à intégrer aux frontières d’une ville.',
      'riverPort':
          'Une embouchure offrant des avantages commerciaux et de déplacement à une ville côtière.',
      'regionalPortHeart':
          'Un centre côtier puissant où se cumulent les atouts de la rivière et des ressources.',
      'openSea':
          'Une étendue d’eau utile aux navires et à l’exploration, mais pas à la fondation de villes terrestres.',
      'naturalBarrier':
          'Un terrain infranchissable qui façonne les déplacements et la défense plutôt que l’économie.',
      'promisingLand':
          'Une case généralement utile, offrant assez de valeur pour mériter une inspection.',
      'weakLand':
          'Un terrain à faible rendement qui mérite rarement le temps d’un ouvrier en début de partie.',
      'ordinaryLand':
          'Une case ordinaire sans atout majeur, utile lorsqu’elle s’intègre au projet d’une ville.',
      'mapTile':
          'Une simple case de la carte, sans assez d’informations pour porter un jugement précis.',
      'other':
          'Une simple case de la carte, sans assez d’informations pour porter un jugement précis.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendation(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity': 'Bon site de développement',
      'defendHere': 'Bonne position défensive',
      'exploitEconomy': 'À exploiter',
      'avoid': 'À éviter sans plan précis',
      'neutral': 'Inspecter avant de se déplacer',
      'other': 'Inspecter avant de se déplacer',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendationDetail(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity':
          'Si les frontières sont libres, envisagez d’y fonder une ville ou d’y diriger un colon.',
      'defendHere':
          'Utilisez cette position pour déployer des unités, protéger les frontières ou couvrir les villes voisines.',
      'exploitEconomy':
          'Intégrez cette case à vos frontières et assignez-y un ouvrier lorsque la ville peut en profiter.',
      'avoid':
          'Délaissez cette case au début, sauf si une ressource, un itinéraire ou un besoin militaire change sa valeur.',
      'neutral':
          'Explorez les cases voisines et comparez les ressources avant d’engager un ouvrier ou un colon.',
      'other':
          'Explorez les cases voisines et comparez les ressources avant d’engager un ouvrier ou un colon.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Inspection de l’hexagone',
      'close': 'Fermer l’inspection',
      'loading': 'Inspection de l’hexagone…',
      'requestFailed': 'Impossible d’inspecter l’hexagone. Réessayez.',
      'responseIncompatible':
          'La réponse d’inspection de l’hexagone est incompatible.',
      'sessionUnavailable': 'La session de jeu n’est pas disponible.',
      'description': 'Description',
      'terrain': 'Terrain',
      'resources': 'Ressources',
      'none': 'Aucune',
      'height': 'Hauteur',
      'improvements': 'Aménagements possibles',
      'noImprovements': 'Aucun aménagement correspondant.',
      'fromStart': 'Disponible dès le début',
      'unlocked': 'Technologie débloquée',
      'locked': 'Technologie requise',
      'riverBonus': 'Bonus de rivière',
      'defenseBonus': 'Terrain défensif',
      'outsideCity': 'Hors des frontières d’une ville contrôlée',
      'cityCenter': 'Centre-ville',
      'alreadyImproved': 'Cet hexagone est déjà aménagé',
      'objective': 'Objectif de la carte',
      'other': 'Inspection de l’hexagone',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionCity(String city) {
    return 'Exploité par $city';
  }

  @override
  String hexInspectionBuildTurns(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns tours',
      one: '$turns tour',
    );
    return 'Durée de construction : $_temp0';
  }

  @override
  String hexInspectionTerrain(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'ocean': 'Océan',
      'coast': 'Côte',
      'lake': 'Lac',
      'plains': 'Plaines',
      'grassland': 'Prairie',
      'desert': 'Désert',
      'tundra': 'Toundra',
      'snow': 'Neige',
      'mountain': 'Montagne',
      'hills': 'Collines',
      'wetlands': 'Zones humides',
      'jungle': 'Jungle',
      'forest': 'Forêt',
      'river': 'Rivière',
      'other': 'Plaines',
    });
    return '$_temp0';
  }

  @override
  String get gamepadSettings => 'Manette';

  @override
  String get gamepadEnabled => 'Commandes à la manette';

  @override
  String get gamepadDeadzone => 'Zone morte de la manette';

  @override
  String get gamepadCameraSensitivity =>
      'Sensibilité de la caméra à la manette';

  @override
  String get gamepadInvertCameraY =>
      'Inverser l’axe Y de la caméra à la manette';

  @override
  String get gamepadButtonBindings => 'Affectation des boutons';

  @override
  String get gamepadAxisBindings => 'Affectation des axes';

  @override
  String get gamepadResetBindings => 'Réinitialiser les affectations';

  @override
  String get gamepadUnassigned => 'Non affecté';

  @override
  String gamepadAssignedTo(String action) {
    return 'Affecté à : $action';
  }

  @override
  String get gamepadActionConfirm => 'Confirmer';

  @override
  String get gamepadActionCancel => 'Annuler';

  @override
  String get gamepadActionMoveMode => 'Mode de déplacement';

  @override
  String get gamepadActionInspect => 'Inspecter l’hexagone';

  @override
  String get gamepadActionHudPrevious => 'Section précédente de l’interface';

  @override
  String get gamepadActionHudNext => 'Section suivante de l’interface';

  @override
  String get gamepadActionPrevious => 'Action en attente précédente';

  @override
  String get gamepadActionNext => 'Action en attente suivante';

  @override
  String get gamepadActionPrimary => 'Action principale';

  @override
  String get gamepadActionUp => 'Croix directionnelle haut';

  @override
  String get gamepadActionDown => 'Croix directionnelle bas';

  @override
  String get gamepadActionLeft => 'Croix directionnelle gauche';

  @override
  String get gamepadActionRight => 'Croix directionnelle droite';

  @override
  String get gamepadActionZoomIn => 'Zoom avant';

  @override
  String get gamepadActionZoomOut => 'Zoom arrière';

  @override
  String get gamepadActionCursorX => 'Axe X du curseur';

  @override
  String get gamepadActionCursorY => 'Axe Y du curseur';

  @override
  String get gamepadActionCameraX => 'Axe X de la caméra';

  @override
  String get gamepadActionCameraY => 'Axe Y de la caméra';

  @override
  String get gamepadControlHome => 'Accueil';

  @override
  String get gamepadControlTouchpad => 'Pavé tactile';

  @override
  String get gamepadControlLeftStickX => 'Stick gauche, axe X';

  @override
  String get gamepadControlLeftStickY => 'Stick gauche, axe Y';

  @override
  String get gamepadControlRightStickX => 'Stick droit, axe X';

  @override
  String get gamepadControlRightStickY => 'Stick droit, axe Y';

  @override
  String get gamepadControlLeftTrigger => 'Gâchette gauche (LT)';

  @override
  String get gamepadControlRightTrigger => 'Gâchette droite (RT)';

  @override
  String get keyboardSettings => 'Clavier';

  @override
  String get keyboardScope =>
      'Les raccourcis de la carte fonctionnent lorsque celle-ci reçoit les commandes du clavier. Cliquez sur la carte pour lui redonner le focus.';

  @override
  String get keyboardPanKeys => 'W / A / S / D ou flèches';

  @override
  String get keyboardPan => 'Déplacer la caméra';

  @override
  String get keyboardSelect =>
      'Sélectionner l’hexagone sous le pointeur ou la sélection actuelle';

  @override
  String get keyboardMove =>
      'Activer ou désactiver le choix de destination de l’unité sélectionnée';

  @override
  String get keyboardInspect =>
      'Inspecter l’hexagone sous le pointeur, l’hexagone sélectionné ou le centre de la vue';

  @override
  String get keyboardMapMode =>
      'Basculer entre la vue graphique et la vue en cases';

  @override
  String get keyboardPending =>
      'Action de tour en attente précédente / suivante';

  @override
  String get keyboardSpace => 'Espace';

  @override
  String get keyboardPrimary =>
      'Passer à l’action en attente suivante ; terminer le tour s’il n’en reste aucune';

  @override
  String get keyboardCancel =>
      'Fermer le panneau actif ou annuler l’interaction actuelle';

  @override
  String get keyboardFocus => 'Passer à la commande suivante / précédente';

  @override
  String get textSize => 'Taille du texte';

  @override
  String get textSizeDescription =>
      'S’ajoute à la taille du texte définie dans le système.';

  @override
  String get textScaleStandard => 'Standard (100%)';

  @override
  String get textScaleLarge => 'Grand (115%)';

  @override
  String get textScaleExtraLarge => 'Très grand (130%)';

  @override
  String get languageSettings => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get windowSettingsTitle => 'Fenêtre';

  @override
  String get windowModeFullscreen => 'Plein écran';

  @override
  String get windowModeWindowed => 'En fenêtre';

  @override
  String get windowSettingsBusy => 'Changement du mode de fenêtre…';

  @override
  String windowSettingsFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'load':
          'Les préférences de fenêtre n’ont pas pu être chargées. Le mode par défaut a été demandé.',
      'apply':
          'Le mode de fenêtre n’a pas pu être modifié. Réessayez de choisir un mode.',
      'save':
          'La préférence de fenêtre n’a pas pu être enregistrée. Réessayez de choisir un mode.',
      'restore':
          'Le mode de fenêtre précédent n’a pas pu être rétabli. Choisissez à nouveau un mode.',
      'other': 'L’opération sur la fenêtre n’a pas pu être effectuée.',
    });
    return '$_temp0';
  }

  @override
  String get automationSettings => 'Automatisation';

  @override
  String get advanceActions => 'Passer à l’action suivante';

  @override
  String get advanceActionsDescription =>
      'Après une action, sélectionner la prochaine unité, ville ou recherche nécessitant votre attention.';

  @override
  String get automaticEndTurn => 'Terminer les tours automatiquement';

  @override
  String get automaticEndTurnDescription =>
      'Terminer votre tour lorsqu’il ne reste plus d’actions. Les choix manuels et les panneaux ouverts suspendent l’automatisation.';

  @override
  String get performanceSettings => 'Performances';

  @override
  String get showFps => 'Afficher les FPS';

  @override
  String get showFpsDescription =>
      'Afficher le nombre d’images par seconde dans toute l’application.';

  @override
  String get showMapZoom => 'Afficher le zoom de la carte';

  @override
  String get showMapZoomDescription =>
      'Afficher le zoom actuel lorsque la carte est ouverte.';

  @override
  String get aiSettings => 'IA';

  @override
  String get aiBatterySaver => 'Économie de batterie pour l’IA';

  @override
  String get aiBatterySaverDescription =>
      'Réduit le travail de recherche tactique pendant les tours locaux de l’IA.';

  @override
  String get mapAppearanceSettings => 'Apparence de la carte';

  @override
  String get mapMarkingsSettings => 'Repères de la carte';

  @override
  String get preferredMapViewMode => 'Vue de carte par défaut';

  @override
  String get preferredMapViewModeDescription =>
      'Utilisée à l’ouverture d’une partie ou d’un replay.';

  @override
  String get mapCitySites => 'Sites de villes';

  @override
  String get mapCitySitesDescription =>
      'Afficher les sites de villes potentiels sur le terrain exploré.';

  @override
  String get mapCityGrowth => 'Expansion des villes';

  @override
  String get mapCityGrowthDescription =>
      'Afficher les cases explorées en dehors du territoire des villes connues.';

  @override
  String resourceText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'gold': 'Or',
      'science': 'Science',
      'stability': 'Stabilité',
      'resources': 'Ressources',
      'victory': 'Victoire',
      'turn': 'Tour',
      'close': 'Fermer les détails',
      'treasury': 'Trésorerie',
      'income': 'Revenus',
      'cityIncome': 'Revenus des villes',
      'projectIncome': 'Revenus des projets',
      'upkeep': 'Entretien des unités',
      'netPerTurn': 'Par tour',
      'freeUnits': 'Unités gratuites',
      'paidUnits': 'Unités payantes',
      'nextWorker': 'Entretien du prochain ouvrier',
      'activeResearch': 'Recherche active',
      'overflow': 'Science stockée',
      'sources': 'Sources',
      'baseOrder': 'Ordre de base',
      'buildings': 'Bâtiments',
      'luxuries': 'Produits de luxe',
      'technologies': 'Technologies',
      'artifacts': 'Artefacts',
      'wonders': 'Merveilles',
      'cities': 'Villes',
      'population': 'Population',
      'cohesion': 'Cohésion',
      'conqueredCities': 'Villes conquises',
      'warWeariness': 'Lassitude de guerre',
      'hegemony': 'Taxe hégémonique',
      'relativeStanding': 'Position relative',
      'totalSources': 'Total des sources',
      'totalCosts': 'Total des coûts',
      'stockpile': 'Réserves',
      'output': 'Production par tour',
      'empty': 'Aucune source',
      'score': 'Score',
      'conquest': 'Conquête',
      'domination': 'Domination',
      'culture': 'Culture',
      'holdTurns': 'Tours de maintien',
      'remainingTurns': 'Tours restants',
      'turnLimit': 'Limite de tours',
      'submitted': 'Confirmé',
      'required': 'Confirmations requises',
      'content': 'Satisfait',
      'stable': 'Stable',
      'strained': 'Tendu',
      'unrest': 'Troubles',
      'other': 'Ressources',
    });
    return '$_temp0';
  }

  @override
  String get automaticSave => 'Sauvegarde automatique';
}
