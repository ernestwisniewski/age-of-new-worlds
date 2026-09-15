// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AonwLocalizationsEs extends AonwLocalizations {
  AonwLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get moveTargeting => 'Mover';

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String get mainMenuTitle => 'Menú principal';

  @override
  String get mainMenuWelcome =>
      'Te damos la bienvenida a Age of New Worlds. Construye ciudades, lidera comandantes, descubre nuevas tierras y escribe la historia de tu civilización.';

  @override
  String get mainMenuSynopsisTitle => 'Construye · Investiga · Dirige';

  @override
  String get mainMenuWhatsNew => 'Novedades';

  @override
  String get singlePlayer => 'Un jugador';

  @override
  String get singlePlayerSublabel => 'Juega contra el ordenador';

  @override
  String get multiplayerSublabel => 'Juega en línea';

  @override
  String get hotseat => 'Hotseat';

  @override
  String get hotseatSublabel => 'Varios jugadores en un dispositivo';

  @override
  String get hotseatUnavailable =>
      'La configuración de Hotseat aún no está disponible.';

  @override
  String get hotseatHandoffTitle => 'Pasa el dispositivo';

  @override
  String hotseatHandoffBody(String name) {
    return 'Entrega el dispositivo a $name. Su mapa permanecerá oculto hasta que confirme.';
  }

  @override
  String hotseatContinueAs(String name) {
    return 'Continuar como $name';
  }

  @override
  String get hotseatHandoffSwitching => 'Preparando al siguiente jugador';

  @override
  String get hotseatHandoffFailure =>
      'No se ha podido abrir de forma segura la sesión del siguiente jugador local.';

  @override
  String get loadGame => 'Cargar partida';

  @override
  String get loadGameSublabel => 'Partidas guardadas y repeticiones';

  @override
  String get exitGame => 'Salir';

  @override
  String get instructions => 'Manual';

  @override
  String get creditsTitle => 'Créditos';

  @override
  String creditsCreatedBy(String name) {
    return 'Creado por $name';
  }

  @override
  String get devlogLinkLabel => 'Diario de desarrollo: ernest.dev';

  @override
  String get feedbackTitle => 'Comentarios';

  @override
  String get feedbackDescription =>
      'Comparte ideas, informa de problemas y sigue el desarrollo con la comunidad de Age of New Worlds.';

  @override
  String get openFeedback => 'Abrir r/aonw';

  @override
  String get externalLinkUnavailable =>
      'Los enlaces externos no están disponibles en esta plataforma.';

  @override
  String get serverUpdateSoon =>
      'Hay una nueva versión lista que pronto estará disponible en esta plataforma. Vuelve a consultar tu tienda o lanzador en breve.';

  @override
  String get continueGame => 'Continuar';

  @override
  String get resumingGame => 'Reanudando la partida';

  @override
  String get newGame => 'Nueva partida';

  @override
  String get multiplayerTitle => 'Multijugador';

  @override
  String get multiplayerUnavailable =>
      'El modo multijugador no está disponible en esta versión.';

  @override
  String get loadingMultiplayer => 'Conectando al modo multijugador';

  @override
  String get multiplayerAuthenticationTitle => 'Cuenta de AoNW';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get displayNameLabel => 'Nombre visible';

  @override
  String get invalidEmail =>
      'Introduce una dirección de correo electrónico válida.';

  @override
  String get invalidPassword => 'Usa al menos 12 caracteres.';

  @override
  String get invalidDisplayName => 'Introduce un nombre visible.';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get createNewAccount => 'Crear una cuenta nueva';

  @override
  String get useExistingAccount => 'Usar una cuenta existente';

  @override
  String get multiplayerLobbyTitle => 'Sala de la partida';

  @override
  String signedInAccount(String userId) {
    return 'Cuenta: $userId';
  }

  @override
  String get multiplayerSetupTitle => 'Crear partida en línea';

  @override
  String get multiplayerSetupIntro =>
      'Elige tu civilización y el mapa antes de abrir la sala de espera gestionada por el servidor.';

  @override
  String get multiplayerTurnModeDescription =>
      'Todos los jugadores actúan durante un turno compartido. El motor lo resuelve tras recibir todas las confirmaciones necesarias o al vencer el plazo del servidor.';

  @override
  String get continueToLobby => 'Continuar a la sala';

  @override
  String get createMultiplayerMatch => 'Crear partida';

  @override
  String get joinMultiplayerMatch => 'Unirse a una partida';

  @override
  String get matchIdLabel => 'ID de la partida';

  @override
  String get playerSeatLabel => 'Plaza de jugador';

  @override
  String get playerSeatOne => 'Jugador uno';

  @override
  String get playerSeatTwo => 'Jugador dos';

  @override
  String playerSeatNumber(int number) {
    return 'Jugador $number';
  }

  @override
  String get refreshMatches => 'Actualizar partidas';

  @override
  String get yourMatches => 'Tus partidas';

  @override
  String get noMultiplayerMatches => 'Aún no te has unido a ninguna partida.';

  @override
  String matchRevision(int revision, int eventOffset) {
    return 'Revisión $revision · posición del evento $eventOffset';
  }

  @override
  String multiplayerMatchPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'lobby': 'sala de espera',
      'running': 'en curso',
      'finished': 'finalizada',
      'abandoned': 'abandonada',
      'other': 'desconocido',
    });
    return 'Estado: $_temp0';
  }

  @override
  String get multiplayerWaitingRoomTitle => 'Sala de espera de la partida';

  @override
  String get multiplayerReady => 'Listo';

  @override
  String get multiplayerNotReady => 'No está listo';

  @override
  String get multiplayerSeatOpen => 'Plaza de jugador libre';

  @override
  String get multiplayerHumanSeat => 'Humano';

  @override
  String get multiplayerAiSeat => 'Ordenador';

  @override
  String get multiplayerHost => 'Anfitrión';

  @override
  String get multiplayerCurrentPlayer => 'Tú';

  @override
  String get markReady => 'Marcar como listo';

  @override
  String get markNotReady => 'Retirar confirmación';

  @override
  String get waitingForPlayers =>
      'Todas las plazas humanas deben estar ocupadas y listas antes de iniciar la partida.';

  @override
  String get refreshMatch => 'Actualizar partida';

  @override
  String get leaveMultiplayerMatch => 'Abandonar partida';

  @override
  String get multiplayerResignTitle => '¿Rendirse en esta partida?';

  @override
  String get multiplayerResignBody =>
      'Tu participación terminará de inmediato y esta acción no se puede deshacer.';

  @override
  String get multiplayerResignConfirm => 'Rendirse';

  @override
  String get multiplayerMatchTitle => 'Partida en línea';

  @override
  String get multiplayerParticipants => 'Participantes';

  @override
  String get multiplayerRemoveParticipant => 'Expulsar';

  @override
  String get multiplayerRemoveParticipantTitle => '¿Expulsar al participante?';

  @override
  String multiplayerRemoveParticipantBody(String name) {
    return '¿Expulsar a $name de esta partida? Ya no podrá volver a conectarse.';
  }

  @override
  String get cancelDialog => 'Cancelar';

  @override
  String matchIdentifier(String matchId) {
    return 'Partida: $matchId';
  }

  @override
  String playerIdentifier(String playerId) {
    return 'Jugador: $playerId';
  }

  @override
  String multiplayerTurn(int turn) {
    return 'Turno $turn';
  }

  @override
  String multiplayerSubmissionProgress(int submitted, int required) {
    return 'Confirmados: $submitted de $required';
  }

  @override
  String visibleUnits(int count) {
    return 'Unidades visibles: $count';
  }

  @override
  String networkPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'connecting': 'conectando',
      'ready': 'en línea',
      'reconnecting': 'reconectando',
      'resyncing': 'sincronizando',
      'failed': 'sin conexión',
      'closed': 'cerrada',
      'other': 'no disponible',
    });
    return 'Conexión: $_temp0';
  }

  @override
  String get submitTurn => 'Confirmar turno';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get backToLobby => 'Volver a la sala';

  @override
  String multiplayerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'client_update_required': 'Actualiza el cliente antes de conectarte.',
      'authentication_required': 'Vuelve a iniciar sesión para continuar.',
      'invalid_authentication_response':
          'La respuesta de autenticación no es válida.',
      'authentication_identity_changed':
          'La identidad de la cuenta ha cambiado durante la actualización.',
      'connection_interrupted':
          'La conexión se ha interrumpido. Vuelve a conectarte para sincronizar la partida.',
      'invalid_server_response':
          'La respuesta del servidor no ha superado la validación.',
      'invalid_command_sequence': 'La secuencia de órdenes no era continua.',
      'invalid_resync_sequence': 'El estado sincronizado ha retrocedido.',
      'invalid_match_lifecycle':
          'La respuesta sobre el ciclo de la partida era incoherente.',
      'match_not_found': 'No se ha encontrado la partida.',
      'match_not_started': 'El anfitrión aún no ha iniciado la partida.',
      'match_already_started': 'La partida ya ha comenzado.',
      'host_required': 'Solo el anfitrión puede realizar esta acción.',
      'lobby_not_ready':
          'Todos los jugadores humanos deben unirse y estar listos.',
      'participant_not_claimable':
          'No se pueden ocupar plazas controladas por el ordenador.',
      'participant_not_active': 'Ese participante ya no está activo.',
      'invalid_kick_target': 'El anfitrión no puede expulsarse a sí mismo.',
      'player_seat_taken': 'Esa plaza de jugador ya está ocupada.',
      'other': 'No se ha podido completar la solicitud multijugador.',
    });
    return '$_temp0';
  }

  @override
  String get helpTitle => 'Cómo jugar';

  @override
  String get helpIntroduction =>
      'Construye una civilización turno a turno. El motor aplica todas las reglas; esta guía explica las decisiones disponibles en el cliente.';

  @override
  String get helpObjectiveTitle => 'Persigue el objetivo';

  @override
  String get helpObjectiveBody =>
      'Expándete, desarrolla ciudades y cumple los objetivos del escenario antes que tu rival. Abre los objetivos estratégicos del mapa para consultar las metas establecidas.';

  @override
  String get helpMapTitle => 'Explora y dirige';

  @override
  String get helpMapBody =>
      'Selecciona un hexágono visible para inspeccionarlo. Selecciona tu unidad, elige un destino resaltado y confirma la ruta. El teclado, el mando y los controles táctiles usan las mismas órdenes.';

  @override
  String get helpDevelopmentTitle => 'Desarrolla tu civilización';

  @override
  String get helpDevelopmentBody =>
      'Usa los paneles de ciudad, investigación, producción, trabajadores, logística, artefactos y diplomacia cuando sus acciones estén disponibles.';

  @override
  String get helpTurnTitle => 'Termina el turno con criterio';

  @override
  String get helpTurnBody =>
      'Completa tus acciones y termina el turno. El ordenador completa su turno validado por el motor antes de devolverte el control.';

  @override
  String get helpSaveReplayTitle => 'Guarda y revisa';

  @override
  String get helpSaveReplayBody =>
      'Guarda desde el mapa. Continuar abre la última partida guardada válida y Repetición muestra el historial de órdenes confirmadas sin modificar la partida.';

  @override
  String get startOnboarding => 'Iniciar introducción guiada';

  @override
  String get onboardingTitle => 'Introducción guiada';

  @override
  String onboardingProgress(int step, int count) {
    return 'Paso $step de $count';
  }

  @override
  String get onboardingExploreTitle => 'Lee el mapa';

  @override
  String get onboardingExploreBody =>
      'El mapa solo muestra información visible para tu jugador. Selecciona hexágonos para inspeccionar el terreno, las ciudades y las unidades; después desplaza o amplía la vista para planificar tu siguiente acción.';

  @override
  String get onboardingCommandTitle => 'Da órdenes precisas';

  @override
  String get onboardingCommandBody =>
      'Los destinos y las acciones disponibles proceden del motor del juego. Elige una opción, revisa la vista previa y confirma; las órdenes rechazadas u obsoletas nunca modifican la partida.';

  @override
  String get onboardingDevelopTitle => 'Consigue una ventaja duradera';

  @override
  String get onboardingDevelopBody =>
      'Las ciudades, la producción, la investigación, los trabajadores, la logística, los artefactos y la diplomacia definen tu estrategia. Sus paneles solo muestran las acciones que permite el motor en ese momento.';

  @override
  String get onboardingContinueTitle => 'Continúa con confianza';

  @override
  String get onboardingContinueBody =>
      'Guarda el estado confirmado de la partida antes de salir. Continuar lo valida en una nueva sesión del motor, mientras que Repetición permite revisar el mismo historial sin modificarlo.';

  @override
  String get previousOnboardingStep => 'Anterior';

  @override
  String get nextOnboardingStep => 'Siguiente';

  @override
  String get skipOnboarding => 'Omitir';

  @override
  String get finishOnboarding => 'Crear una partida';

  @override
  String get newGameTitle => 'Crear partida local';

  @override
  String get singlePlayerSetupTitle => 'Jugar contra el ordenador';

  @override
  String get singlePlayerSetupIntro =>
      'Elige tu civilización y configura tu partida.';

  @override
  String get hotseatSetupTitle => 'Jugar en modo Hotseat';

  @override
  String get hotseatSetupIntro =>
      'Comparte un dispositivo. La vista de cada jugador humano permanece oculta hasta que el siguiente jugador confirma el relevo.';

  @override
  String get chooseCivilizationTitle => 'Elegir civilización';

  @override
  String get gameSetupTitle => 'Configuración de la partida';

  @override
  String get turnModeTitle => 'Modo de turnos';

  @override
  String turnModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'sequential': 'Tradicional',
      'simultaneous': 'Simultáneo',
      'other': 'Desconocido',
    });
    return '$_temp0';
  }

  @override
  String get turnModeSequentialDescription =>
      'Las civilizaciones completan y resuelven sus turnos una tras otra.';

  @override
  String get turnModeSimultaneousDescription =>
      'Tú y el ordenador actuáis durante un turno compartido antes de que el motor resuelva sus fases comunes.';

  @override
  String get opponentsTitle => 'Rivales';

  @override
  String get opponentControlLabel => 'Control del rival';

  @override
  String opponentNumberLabel(int number) {
    return 'Rival $number';
  }

  @override
  String get humanOpponent => 'Jugador humano';

  @override
  String get aiOpponent => 'Ordenador';

  @override
  String get mapSetupTitle => 'Mapa';

  @override
  String get mapSetupBody =>
      'Un mapa diseñado de 7 × 7 casillas para una partida compacta entre dos civilizaciones.';

  @override
  String mapSetupDetails(String mapName, int columns, int rows, int players) {
    return '$mapName · $columns × $rows · $players civilizaciones';
  }

  @override
  String get victoryPathsTitle => 'Vías de victoria';

  @override
  String get victoryPathsBody =>
      'El motor del juego resuelve las victorias por conquista, dominación, cultura y puntuación.';

  @override
  String get settlementToEmpireTitle => 'Del asentamiento al imperio';

  @override
  String get settlementToEmpireBody =>
      'Explora, funda ciudades, investiga, crea ejércitos y consigue ventajas duraderas.';

  @override
  String get continueToSummary => 'Continuar al resumen';

  @override
  String get gameSummaryTitle => 'Expedición lista';

  @override
  String get gameSummaryIntro =>
      'Revisa todos los participantes locales antes de crear la partida.';

  @override
  String get summaryModeLabel => 'Modo';

  @override
  String get summaryTurnModeLabel => 'Turnos';

  @override
  String get summaryCivilizationLabel => 'Tu civilización';

  @override
  String get summaryOpponentLabel => 'Rival';

  @override
  String get summaryMapLabel => 'Mapa';

  @override
  String get summaryFogLabel => 'Niebla de guerra';

  @override
  String get summaryAiLabel => 'Perfil del ordenador';

  @override
  String get changeSetup => 'Cambiar configuración';

  @override
  String localModeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'singlePlayer': 'Un jugador',
      'hotseat': 'Hotseat',
      'other': 'Partida local',
    });
    return '$_temp0';
  }

  @override
  String participantControlName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'human': 'Humano',
      'ai': 'Ordenador',
      'other': 'Desconocido',
    });
    return '$_temp0';
  }

  @override
  String fogSettingName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'enabled': 'Activada',
      'disabled': 'Desactivada',
      'other': 'Desconocido',
    });
    return '$_temp0';
  }

  @override
  String get defaultSecondPlayerName => 'Jugador 2';

  @override
  String defaultNumberedPlayerName(int number) {
    return 'Jugador $number';
  }

  @override
  String defaultNumberedAiName(int number) {
    return 'Ordenador $number';
  }

  @override
  String get scenarioLabel => 'Mapa';

  @override
  String localScenarioName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'starterDuel': 'Inicial',
      'dravonia': 'Dravonia',
      'myranth': 'Myranth',
      'terenos': 'Terenos',
      'verdantia': 'Verdantia',
      'other': 'Mapa local',
    });
    return '$_temp0';
  }

  @override
  String get humanCountryLabel => 'Tu país';

  @override
  String get aiCountryLabel => 'País de la IA';

  @override
  String get aiDifficultyLabel => 'Dificultad de la IA';

  @override
  String get aiPersonaLabel => 'Personalidad de la IA';

  @override
  String get fogOfWarLabel => 'Niebla de guerra';

  @override
  String get startGame => 'Iniciar partida';

  @override
  String get startingGame => 'Iniciando la partida';

  @override
  String get localGameStartFailed =>
      'No se ha podido iniciar la partida local.';

  @override
  String get saveGame => 'Guardar partida';

  @override
  String get savingGame => 'Guardando la partida';

  @override
  String get gameSaved => 'Partida guardada';

  @override
  String saveFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable': 'No se puede guardar en esta sesión.',
      'exportFailed': 'No se ha podido exportar la partida.',
      'writeFailed': 'No se ha podido almacenar el archivo de la partida.',
      'other': 'No se ha podido guardar la partida.',
    });
    return '$_temp0';
  }

  @override
  String resumeFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'Las partidas guardadas no están disponibles en esta plataforma.',
      'missing': 'No se ha encontrado ninguna partida guardada.',
      'unreadable': 'No se ha podido leer la partida guardada.',
      'incompatible':
          'La partida guardada no es válida o no es compatible con el juego actual.',
      'other': 'No se ha podido reanudar la partida guardada.',
    });
    return '$_temp0';
  }

  @override
  String get loadGameTitle => 'Cargar partida';

  @override
  String get loadGameEmpty => 'No se han encontrado partidas guardadas.';

  @override
  String loadGameSingleLabel(String scenario) {
    return 'Un jugador · $scenario';
  }

  @override
  String get importSave => 'Importar partida';

  @override
  String get exportSave => 'Exportar';

  @override
  String get saveTransferUnavailable =>
      'La importación y exportación de partidas no están disponibles en esta plataforma.';

  @override
  String saveImportCompleted(String map) {
    return 'Se ha importado $map como una partida guardada independiente.';
  }

  @override
  String saveExportCompleted(String map) {
    return 'Se ha exportado $map.';
  }

  @override
  String saveTransferFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'La transferencia de partidas no está disponible en esta plataforma.',
      'unreadable': 'No se ha podido leer el archivo de partida seleccionado.',
      'tooLarge':
          'El archivo de partida seleccionado supera el límite de 16 MiB.',
      'incompatible':
          'La partida seleccionada no es válida o no coincide con un mapa, conjunto de reglas o versión del motor instalados.',
      'missing': 'La partida guardada seleccionada ya no existe.',
      'writeFailed': 'No se ha podido almacenar la partida importada.',
      'exportFailed': 'No se ha podido exportar el archivo de la partida.',
      'other': 'No se ha podido completar la transferencia de la partida.',
    });
    return '$_temp0';
  }

  @override
  String get replayTitle => 'Repetición';

  @override
  String get loadingReplay => 'Cargando la repetición';

  @override
  String get replayUnavailable =>
      'La reproducción de repeticiones no está disponible.';

  @override
  String replayFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unavailable':
          'La reproducción de repeticiones no está disponible en esta plataforma.',
      'missing':
          'No se ha encontrado ninguna repetición. Guarda primero una partida local.',
      'unreadable': 'No se ha podido leer el archivo de la repetición.',
      'incompatible':
          'La repetición no es válida o no es compatible con el juego actual.',
      'seekFailed':
          'No se ha podido cargar el paso solicitado de la repetición.',
      'other': 'No se ha podido abrir la repetición.',
    });
    return '$_temp0';
  }

  @override
  String get replayMapLabel => 'Mapa de la repetición';

  @override
  String get replayControls => 'Controles de repetición';

  @override
  String get playReplay => 'Reproducir repetición';

  @override
  String get pauseReplay => 'Pausar repetición';

  @override
  String get backToMenu => 'Volver al menú principal';

  @override
  String replayProgress(int position, int entryCount) {
    return '$position de $entryCount';
  }

  @override
  String replaySpeed(String value) {
    return 'Velocidad $value×';
  }

  @override
  String get aiTurnRunning => 'El ordenador está jugando su turno.';

  @override
  String aiTurnFailure(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'requestFailed': 'No se ha podido completar el turno del ordenador.',
      'responseIncompatible':
          'La respuesta del turno del ordenador no es compatible con este cliente.',
      'incomplete':
          'El ordenador no ha completado su turno dentro del límite seguro de órdenes.',
      'other': 'No se ha podido completar el turno del ordenador.',
    });
    return '$_temp0';
  }

  @override
  String get defaultPlayerName => 'Jugador';

  @override
  String get defaultAiName => 'Ordenador';

  @override
  String countryName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'poland': 'Polonia',
      'ukraine': 'Ucrania',
      'germany': 'Alemania',
      'france': 'Francia',
      'unitedKingdom': 'Reino Unido',
      'italy': 'Italia',
      'spain': 'España',
      'netherlands': 'Países Bajos',
      'sweden': 'Suecia',
      'russia': 'Rusia',
      'unitedStates': 'Estados Unidos',
      'canada': 'Canadá',
      'china': 'China',
      'korea': 'Corea',
      'japan': 'Japón',
      'portugal': 'Portugal',
      'india': 'India',
      'brazil': 'Brasil',
      'indonesia': 'Indonesia',
      'mexico': 'México',
      'turkey': 'Turquía',
      'saudiArabia': 'Arabia Saudí',
      'egypt': 'Egipto',
      'greece': 'Grecia',
      'other': 'País desconocido',
    });
    return '$_temp0';
  }

  @override
  String aiDifficultyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'easy': 'Fácil',
      'normal': 'Normal',
      'hard': 'Difícil',
      'veryHard': 'Muy difícil',
      'other': 'Dificultad desconocida',
    });
    return '$_temp0';
  }

  @override
  String aiPersonaName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'balanced': 'Equilibrada',
      'aggressive': 'Agresiva',
      'expansive': 'Expansionista',
      'economic': 'Económica',
      'scientific': 'Científica',
      'other': 'Personalidad desconocida',
    });
    return '$_temp0';
  }

  @override
  String get unknownRouteLabel => 'Página desconocida';

  @override
  String get pageUnavailable => 'Página no disponible';

  @override
  String unknownRouteMessage(String location) {
    return 'Página desconocida: $location';
  }

  @override
  String get missingRouteLocation => '(falta)';

  @override
  String mapSemanticsLabel(String mapId, int cols, int rows) {
    return 'Mapa $mapId, $cols por $rows hexágonos';
  }

  @override
  String get mapInputHint =>
      'Usa WASD o las flechas para desplazar la cámara, Intro para seleccionar, M para mover, I para inspeccionar, R para cambiar la vista del mapa, los corchetes para las acciones pendientes y Espacio para la siguiente acción o para terminar el turno. Usa Tab para enfocar los controles.';

  @override
  String get noHexSelected => 'Ningún hexágono seleccionado';

  @override
  String selectedHex(int col, int row) {
    return 'Hexágono seleccionado: $col, $row';
  }

  @override
  String get mapViewModeTooltip => 'Cambiar vista del mapa';

  @override
  String get mapViewGraphicUnavailable =>
      'La vista gráfica no está disponible para este mapa.';

  @override
  String get mapViewModeGraphic => 'Gráfica';

  @override
  String get mapViewModeTiles => 'Casillas';

  @override
  String hexLabel(int col, int row) {
    return 'Hexágono $col, $row';
  }

  @override
  String get selectionTerrain => 'Terreno';

  @override
  String unitLabel(String unitId) {
    return 'Unidad $unitId';
  }

  @override
  String routeSummary(int totalCost, int remaining) {
    return 'Ruta: $totalCost puntos de movimiento · $remaining restantes';
  }

  @override
  String get confirmMove => 'Confirmar movimiento';

  @override
  String moveTurnCost(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns turnos',
      one: '1 turno',
    );
    return '$_temp0';
  }

  @override
  String confirmMoveWithCost(String turnCost) {
    return 'Confirmar · $turnCost';
  }

  @override
  String get chooseHighlightedDestination => 'Elige un destino resaltado.';

  @override
  String get movingUnit => 'Moviendo la unidad';

  @override
  String unitActionLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'title': 'Acciones de unidad',
      'fortify': 'Fortificar',
      'skip': 'Omitir',
      'cancel': 'Cancelar acción',
      'executing': 'Ejecutando acción de unidad',
      'logisticsTitle': 'Logística',
      'logisticsLoading': 'Cargando opciones de logística',
      'logisticsEmpty':
          'No hay acciones de logística disponibles en este momento.',
      'autoExplore': 'Exploración automática',
      'merchantRoute': 'Asignar ruta comercial',
      'merchantTravel': 'Mover a una ciudad',
      'detachTroop': 'Separar tropa',
      'other': 'Acción de unidad',
    });
    return '$_temp0';
  }

  @override
  String unitActionFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed':
          'No se ha podido completar la solicitud de acción de unidad.',
      'responseIncompatible':
          'La respuesta de la acción de unidad no es compatible con este cliente.',
      'sessionUnavailable': 'La sesión de juego local no está disponible.',
      'stale':
          'El estado del juego ha cambiado. Revisa la unidad e inténtalo de nuevo.',
      'matchFinished': 'La partida ya ha terminado.',
      'unitUnavailable':
          'Esa unidad ya no está disponible para recibir órdenes.',
      'unitBusy':
          'Esa unidad está ocupada y no puede realizar esta acción ahora.',
      'internal':
          'No se ha podido aplicar la acción de unidad. Inténtalo de nuevo.',
      'logisticsRequestFailed':
          'No se ha podido completar la solicitud de logística.',
      'logisticsResponseIncompatible':
          'La respuesta de logística no es compatible con este cliente.',
      'logisticsOptionUnavailable':
          'Esa opción de logística ya no está disponible.',
      'combatFailureRequestFailed':
          'No se ha podido completar la solicitud de combate.',
      'combatFailureResponseIncompatible':
          'La respuesta de combate no es compatible con este cliente.',
      'combatFailureSessionUnavailable':
          'La sesión de juego local no está disponible.',
      'combatFailureTargetUnavailable':
          'No hay una vista previa de ataque disponible para ese objetivo.',
      'combatFailureStaleRevision':
          'El estado del juego ha cambiado. Revísalo e inténtalo de nuevo.',
      'combatFailureMatchFinished': 'La partida ya ha terminado.',
      'combatFailureAttackerNotFound':
          'La unidad atacante ya no está disponible.',
      'combatFailureAttackerNotControlled':
          'Este jugador no controla la unidad atacante.',
      'combatFailureAttackerUnavailable':
          'La unidad atacante no está disponible.',
      'combatFailureAttackerExhausted': 'La unidad atacante está agotada.',
      'combatFailureAttackerOutOfBounds':
          'La unidad atacante está fuera del mapa.',
      'combatFailureAttackerCannotAttack': 'Esa unidad no puede atacar.',
      'combatFailureAttackTargetNotVisible': 'El objetivo no es visible.',
      'combatFailureAttackTargetOutOfBounds':
          'El objetivo está fuera del mapa.',
      'combatFailureAttackTargetNotFound': 'No hay ningún objetivo allí.',
      'combatFailureAttackTargetNotEnemy': 'Ese objetivo no es un enemigo.',
      'combatFailureAttackTargetProtectedByTreaty':
          'Un tratado protege ese objetivo.',
      'combatFailureAttackTargetOutOfRange':
          'El objetivo está fuera de alcance.',
      'combatFailureAttackCityHasNoHealth': 'No se puede atacar esa ciudad.',
      'other': 'No se ha podido completar la acción de unidad.',
    });
    return '$_temp0';
  }

  @override
  String turnSummary(String kind, int turn, int submitted, int required) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'label': 'TURNO $turn',
      'progress': 'Listos: $submitted de $required',
      'other': 'TURNO $turn',
    });
    return '$_temp0';
  }

  @override
  String turnText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'statusActive': 'Tu turno',
      'statusFinished': 'Turno terminado',
      'statusSubmitted': 'Turno confirmado',
      'statusWaiting': 'Esperando',
      'statusPendingAction': 'Acción necesaria',
      'actionEnd': 'Terminar turno',
      'actionSubmit': 'Confirmar turno',
      'actionSubmitting': 'Confirmando turno',
      'actionEnding': 'Terminando el turno',
      'outcomeConquest': 'Victoria por conquista',
      'outcomeDomination': 'Victoria por dominación',
      'outcomeCultural': 'Victoria cultural',
      'outcomeScore': 'Victoria por puntuación',
      'outcomeResignation': 'Partida terminada por rendición',
      'outcomeDraw': 'Empate',
      'outcomeOngoing': 'Partida en curso',
      'activityTitle': 'Actividad',
      'activityArtifact': 'Actividad de artefactos',
      'activityCity': 'Actividad de ciudades',
      'activityResearch': 'Progreso de investigación',
      'activityObjective': 'Objetivo estratégico actualizado',
      'activityOutcome': 'Resultado de la partida actualizado',
      'activityCombat': 'Actividad de combate',
      'activityDiplomacy': 'Actividad diplomática',
      'activityUnit': 'Actividad de unidades',
      'activityTurn': 'Turno actualizado',
      'activityWorker': 'Trabajo del trabajador completado',
      'combatTitle': 'Combate',
      'combatLoading': 'Cargando vista previa del combate',
      'combatTarget': 'Objetivo',
      'combatDistance': 'Distancia',
      'combatOutgoing': 'Daño infligido',
      'combatRetaliation': 'Daño del contraataque',
      'combatNone': 'Ninguno',
      'combatCapture': 'Capturar ciudad',
      'combatDestroy': 'Destruir ciudad',
      'combatConfirm': 'Confirmar ataque',
      'combatExecuting': 'Resolviendo el combate',
      'combatResolved': 'Combate resuelto',
      'combatAttackerHp': 'Salud del atacante',
      'combatDefenderHp': 'Salud del defensor',
      'combatEventUnitAttacked': 'Unidad atacada',
      'combatEventCityAttacked': 'Ciudad atacada',
      'combatEventCombatResolved': 'Combate resuelto',
      'combatEventUnitGainedExperience': 'La unidad ha ganado experiencia',
      'combatEventUnitKilled': 'Unidad derrotada',
      'combatEventUnitRetreated': 'Unidad retirada',
      'combatEventCityCaptured': 'Ciudad capturada',
      'combatEventCityDestroyed': 'Ciudad destruida',
      'combatEventDiplomaticScoreChanged': 'Relación diplomática modificada',
      'other': 'Actividad del juego',
    });
    return '$_temp0';
  }

  @override
  String turnFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'No se ha podido completar la solicitud de turno.',
      'responseIncompatible':
          'La respuesta del turno no es compatible con este cliente.',
      'sessionUnavailable': 'La sesión de juego local no está disponible.',
      'stale_revision':
          'El estado del juego ha cambiado. Revísalo e inténtalo de nuevo.',
      'match_finished': 'La partida ya ha terminado.',
      'turn_player_not_controlled':
          'Este jugador no puede terminar el turno actual.',
      'turn_player_not_active': 'Este jugador no está activo.',
      'turn_scope_invalid': 'El ámbito del turno actual no es válido.',
      'turn_processor_unsupported':
          'Un proceso necesario para el turno no está disponible.',
      'turn_number_overflow':
          'El siguiente número de turno supera el límite permitido.',
      'state_revision_overflow': 'La revisión del juego no puede avanzar.',
      'other': 'No se ha podido completar el turno.',
    });
    return '$_temp0';
  }

  @override
  String get loadingMap => 'Cargando el mapa';

  @override
  String get mapLoadingFailed => 'Error al cargar el mapa';

  @override
  String get mapUnavailable => 'Mapa no disponible';

  @override
  String get mapAdapterUnavailable =>
      'El adaptador nativo del juego no está disponible en esta plataforma.';

  @override
  String get mapClientIncompatible =>
      'El adaptador nativo del juego no es compatible con este cliente.';

  @override
  String get mapLoadSuperseded =>
      'Una solicitud de mapa más reciente ha sustituido a esta.';

  @override
  String get mapLoadFailure => 'No se ha podido cargar el mapa.';

  @override
  String get movementRequestFailed =>
      'No se ha podido completar la solicitud de movimiento.';

  @override
  String get movementResponseIncompatible =>
      'La respuesta de movimiento no es compatible con este cliente.';

  @override
  String get movementSessionUnavailable =>
      'La sesión de juego local no está disponible.';

  @override
  String get moveRejectedStale =>
      'El estado del juego ha cambiado. Revisa la posición actual e inténtalo de nuevo.';

  @override
  String get moveRejectedUnitUnavailable =>
      'Esa unidad ya no está disponible para moverse.';

  @override
  String get moveRejectedUnitBusy =>
      'Esa unidad está ocupada y no puede moverse ahora.';

  @override
  String get moveRejectedTargetUnavailable => 'Ese destino no está disponible.';

  @override
  String get moveRejectedMovementInsufficient =>
      'La unidad no tiene suficientes puntos de movimiento restantes.';

  @override
  String get moveRejectedPathUnavailable =>
      'No hay ninguna ruta válida hacia ese destino.';

  @override
  String get moveRejectedInternal =>
      'No se ha podido aplicar el movimiento. Inténtalo de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get audioSettings => 'Audio';

  @override
  String get cameraSettings => 'Cámara';

  @override
  String get cameraSensitivity => 'Sensibilidad del zoom';

  @override
  String get animationSettings => 'Animaciones';

  @override
  String get showUnitMovementAnimations =>
      'Mostrar animaciones de movimiento de unidades';

  @override
  String get showUnitIdleAnimations =>
      'Mostrar animaciones de unidades en reposo';

  @override
  String get showRouteAnimations => 'Mostrar animaciones de rutas planificadas';

  @override
  String get showCombatAnimations => 'Mostrar animaciones de combate';

  @override
  String get cinematicCamera => 'Cámara cinematográfica';

  @override
  String get smoothCameraMovement => 'Movimiento suave de la cámara';

  @override
  String get mapSettings => 'Mapa';

  @override
  String get mapGrid => 'Bordes de hexágonos';

  @override
  String get mapGridDescription =>
      'Mostrar bordes negros alrededor de los hexágonos del mapa.';

  @override
  String get mapResourceIcons => 'Iconos de recursos';

  @override
  String get mapResourceIconsDescription =>
      'Mostrar los recursos disponibles en los hexágonos del mapa.';

  @override
  String get mapTerrainIcons => 'Iconos de terreno';

  @override
  String get mapTerrainIconsDescription =>
      'Mostrar las características del terreno de cada hexágono.';

  @override
  String get mapHeightBadges => 'Etiquetas de altura';

  @override
  String get mapHeightBadgesDescription =>
      'Mostrar la altura definida para los hexágonos elevados.';

  @override
  String get mapElevationWalls => 'Paredes de elevación';

  @override
  String get mapElevationWallsDescription =>
      'Mostrar la profundidad de los hexágonos elevados teniendo en cuenta sus vecinos.';

  @override
  String get accessibilitySettings => 'Accesibilidad';

  @override
  String get reducedMotion => 'Reducir movimiento';

  @override
  String get reducedMotionDescription =>
      'Evitar animaciones y transiciones que no sean esenciales.';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get highContrastDescription =>
      'Aumentar el contraste de la interfaz de la aplicación.';

  @override
  String get resetSettings => 'Restaurar valores predeterminados';

  @override
  String get objectivesTitle => 'Objetivos estratégicos';

  @override
  String get openObjectives => 'Abrir objetivos';

  @override
  String get closeObjectives => 'Cerrar objetivos';

  @override
  String get objectivesEmpty => 'Este mapa no tiene objetivos.';

  @override
  String objectiveControlProgress(String player, int turns, int required) {
    return 'Controlado por $player\nProgreso de control: $turns / $required';
  }

  @override
  String get objectiveControlUnknown => 'No se conoce quién lo controla';

  @override
  String get objectivesAuthoredRules =>
      'Controla estos lugares durante el número de turnos requerido.';

  @override
  String objectiveType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'ruins': 'Ruinas',
      'strategicPass': 'Paso estratégico',
      'holySite': 'Lugar sagrado',
      'legendaryResource': 'Recurso legendario',
      'other': 'Objetivo estratégico',
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
    return 'Hexágono $col, $row\nTurnos de control necesarios: $holdTurns · Puntos de victoria: $victoryPoints · Oro por turno: $goldPerTurn';
  }

  @override
  String get matchFinishedTitle => 'Partida terminada';

  @override
  String outcomeWinner(String playerId) {
    return 'Ganador: $playerId';
  }

  @override
  String get outcomeNoWinner => 'Sin ganador';

  @override
  String get outcomeFinalScore => 'Puntuación final';

  @override
  String outcomeScoreLine(String playerId, int score) {
    return '$playerId: $score';
  }

  @override
  String cityText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Ciudad',
      'foundingTitle': 'Fundar una ciudad',
      'loading': 'Cargando detalles de la ciudad',
      'owner': 'Propietario',
      'health': 'Salud',
      'population': 'Población',
      'territory': 'Territorio',
      'foundingSelection': 'Territorio inicial',
      'foundingConfirm': 'Confirmar fundación de la ciudad',
      'foundingCancel': 'Cancelar fundación',
      'executing': 'Aplicando acción de ciudad',
      'cityYield': 'Rendimiento',
      'food': 'Alimentos',
      'production': 'Producción',
      'gold': 'Oro',
      'defense': 'Defensa',
      'workedHexes': 'Hexágonos trabajados',
      'workedHexSelect': 'Gestionar hexágonos trabajados',
      'workedHexHint':
          'Selecciona un hexágono controlado y resaltado en el mapa.',
      'expansion': 'Expansión preferida',
      'expansionSelect': 'Elegir expansión',
      'expansionHint':
          'Selecciona un hexágono de expansión resaltado en el mapa.',
      'managementCancel': 'Terminar selección en el mapa',
      'foundingOpen': 'Planificar una ciudad',
      'other': 'Ciudad',
    });
    return '$_temp0';
  }

  @override
  String cityFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'No se ha podido completar la solicitud de ciudad.',
      'responseIncompatible':
          'La respuesta de ciudad no es compatible con este cliente.',
      'sessionUnavailable': 'La sesión de juego local no está disponible.',
      'staleRevision':
          'El estado del juego ha cambiado. Revisa la ciudad e inténtalo de nuevo.',
      'matchFinished': 'La partida ya ha terminado.',
      'cityFounderNotFound': 'La unidad fundadora ya no está disponible.',
      'cityFounderNotControlled':
          'Este jugador no controla la unidad fundadora.',
      'cityFounderBusy': 'La unidad fundadora está ocupada.',
      'cityFounderInvalid': 'Esa unidad no puede fundar una ciudad.',
      'cityFounderNoSettlers': 'La unidad fundadora no tiene colonos.',
      'citySiteInvalid': 'No se puede fundar una ciudad en ese lugar.',
      'cityCenterOccupied': 'El centro de la ciudad está ocupado.',
      'cityCenterClaimed': 'El centro de la ciudad ya ha sido reclamado.',
      'cityCenterTooClose':
          'El centro de la ciudad está demasiado cerca de otra ciudad.',
      'cityControlledHexesInvalid':
          'El territorio inicial seleccionado no es válido.',
      'cityNotFound': 'Esa ciudad ya no está disponible.',
      'cityNotControlled': 'Este jugador no controla esa ciudad.',
      'workedHexUnavailable': 'Ese hexágono trabajado no está disponible.',
      'workedHexLimitReached':
          'La ciudad ha alcanzado su límite de hexágonos trabajados.',
      'cityExpansionHexUnavailable':
          'Ese hexágono de expansión no está disponible.',
      'stateRevisionOverflow': 'El estado del juego no puede avanzar más.',
      'other': 'No se ha podido completar la solicitud de ciudad.',
    });
    return '$_temp0';
  }

  @override
  String workerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Trabajador',
      'loading': 'Cargando opciones del trabajador',
      'empty': 'No hay acciones de trabajador disponibles en este momento.',
      'executing': 'Aplicando acción de trabajador',
      'buildCharges': 'Cargas de construcción',
      'progress': 'Progreso',
      'assigned': 'Hexágono asignado',
      'openActions': 'Mejorar hexágono',
      'closeActions': 'Cancelar selección',
      'selectImprovement': 'Seleccionar',
      'confirmImprovement': 'Confirmar mejora',
      'cancelJob': 'Cancelar construcción',
      'assign': 'Asignar a un hexágono',
      'cancelAssignment': 'Cancelar asignación',
      'buildRoad': 'Construir camino',
      'automate': 'Automatizar',
      'automationEvidence': 'Criterios de planificación',
      'other': 'Trabajador',
    });
    return '$_temp0';
  }

  @override
  String workerFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'No se ha podido completar la solicitud del trabajador.',
      'responseIncompatible':
          'La respuesta del trabajador no es compatible con este cliente.',
      'sessionUnavailable': 'La sesión de juego local no está disponible.',
      'staleRevision':
          'El estado del juego ha cambiado. Revisa el trabajador e inténtalo de nuevo.',
      'matchFinished': 'La partida ya ha terminado.',
      'workerNotFound': 'El trabajador ya no está disponible.',
      'workerNotControlled': 'Este jugador no controla al trabajador.',
      'workerUnavailable': 'El trabajador no está disponible.',
      'workerNoMovementPoints': 'El trabajador no tiene puntos de movimiento.',
      'workerQueuedPathActive':
          'El trabajador tiene una orden de movimiento activa.',
      'workerImprovementNotSelected': 'Selecciona primero una mejora.',
      'workerActionNotControlled':
          'Este jugador no controla la acción pendiente del trabajador.',
      'workerImprovementUnavailable': 'Esa mejora no está disponible.',
      'workerJobNotActive':
          'El trabajador no tiene ninguna construcción activa.',
      'workerAssignmentUnavailable': 'No se puede asignar al trabajador aquí.',
      'workerAssignmentNotActive':
          'El trabajador no tiene ninguna asignación activa.',
      'workerRoadUnavailable': 'No se puede construir un camino aquí.',
      'roadConstructionExistingRoad': 'Ya existe un camino aquí.',
      'roadConstructionCity':
          'No se puede construir un camino en el centro de una ciudad.',
      'roadConstructionEnemyTerritory':
          'No se puede construir un camino en territorio enemigo.',
      'roadConstructionImpassableTerrain':
          'No se puede construir un camino en este terreno.',
      'workerAutomationNotActive':
          'La automatización del trabajador no está activa.',
      'workerAutomationNoTarget':
          'La automatización del trabajador no ha encontrado un objetivo.',
      'stateRevisionOverflow': 'El estado del juego no puede avanzar más.',
      'other': 'No se ha podido completar la solicitud del trabajador.',
    });
    return '$_temp0';
  }

  @override
  String productionText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Producción y recursos',
      'loading': 'Cargando opciones de producción',
      'executing': 'Actualizando la producción de la ciudad',
      'current': 'Producción actual',
      'invested': 'Invertido',
      'overflow': 'Excedente',
      'resources': 'Recursos estratégicos',
      'buildings': 'Edificios',
      'units': 'Unidades',
      'projects': 'Proyectos',
      'wonders': 'Maravillas',
      'specializations': 'Especializaciones',
      'rush': 'Acelerar producción',
      'cost': 'coste',
      'requires': 'requiere',
      'empty': 'No hay opciones disponibles en este momento.',
      'other': 'Producción',
    });
    return '$_temp0';
  }

  @override
  String productionFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'No se ha podido completar la solicitud de producción.',
      'responseIncompatible': 'La respuesta de producción no es compatible.',
      'sessionUnavailable': 'La sesión de juego local no está disponible.',
      'staleRevision':
          'La ciudad ha cambiado. Revisa la producción e inténtalo de nuevo.',
      'matchFinished': 'La partida ya ha terminado.',
      'cityNotFound': 'La ciudad ya no está disponible.',
      'cityNotControlled': 'Este jugador no controla la ciudad.',
      'buildingNotAvailable': 'Este edificio no está disponible.',
      'unitProductionInvalidResourceOption':
          'Esa opción de recursos no es válida.',
      'unitProductionNotAvailable': 'Esta unidad no está disponible.',
      'unitProductionRequiresResource': 'Selecciona una opción de recursos.',
      'unitProductionMissingStrategicResource': 'Faltan recursos necesarios.',
      'unitProductionRequiresCoast': 'Esta unidad requiere una ciudad costera.',
      'unitSupplyLimitReached':
          'Se ha alcanzado el límite de suministro de unidades.',
      'wonderNotAvailable': 'Esta maravilla no está disponible.',
      'citySpecializationLocked': 'Esta especialización está bloqueada.',
      'citySpecializationUnchanged': 'Esta especialización ya está activa.',
      'citySpecializationMissingBuilding': 'Falta un edificio necesario.',
      'productionQueueEmpty': 'La cola de producción está vacía.',
      'projectCannotBeRushed': 'No se puede acelerar un proyecto continuo.',
      'rushProductionUnavailable': 'No se puede acelerar la producción.',
      'stateRevisionOverflow': 'El estado del juego no puede avanzar más.',
      'other': 'No se ha podido completar la solicitud de producción.',
    });
    return '$_temp0';
  }

  @override
  String artifactText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Artefactos del mundo',
      'executing': 'Aplicando acción de artefacto',
      'startExcavation': 'Iniciar excavación',
      'storeInCity': 'Almacenar en ciudad',
      'trade': 'Comerciar con artefacto',
      'targetPlayer': 'Jugador destinatario',
      'offeredGold': 'Oro ofrecido',
      'onMap': 'En el mapa en',
      'carried': 'Transportado por',
      'stored': 'Almacenado en',
      'excavation': 'Excavación en',
      'turnsRemaining': 'turnos restantes',
      'other': 'Artefacto',
    });
    return '$_temp0';
  }

  @override
  String artifactName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ancientImperialCrown': 'Antigua corona imperial',
      'astronomersTablets': 'Tablillas del astrónomo',
      'prophetMask': 'Máscara del profeta',
      'heroSword': 'Espada del héroe',
      'merchantsSeal': 'Sello del mercader',
      'firstPeoplesChronicle': 'Crónica del primer pueblo',
      'templeReliquary': 'Relicario del templo',
      'queensMirror': 'Espejo de la reina',
      'other': 'Artefacto del mundo',
    });
    return '$_temp0';
  }

  @override
  String artifactOnMap(int col, int row) {
    return 'En el mapa en $col, $row';
  }

  @override
  String artifactCarriedBy(String unitName) {
    return 'Transportado por $unitName';
  }

  @override
  String artifactStoredIn(String cityName) {
    return 'Almacenado en $cityName';
  }

  @override
  String artifactExcavationAt(int col, int row, int remainingTurns) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingTurns,
      locale: localeName,
      other: '$remainingTurns turnos restantes',
      one: '1 turno restante',
    );
    return 'Excavación en $col, $row · $_temp0';
  }

  @override
  String artifactFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'No se ha podido completar la solicitud de artefacto.',
      'responseIncompatible': 'La respuesta de artefacto no es compatible.',
      'sessionUnavailable': 'La sesión de juego local no está disponible.',
      'staleRevision':
          'El estado del juego ha cambiado. Revisa el artefacto e inténtalo de nuevo.',
      'matchFinished': 'La partida ya ha terminado.',
      'unitNotFound': 'La unidad ya no está disponible.',
      'unitNotControlled': 'Este jugador no controla la unidad.',
      'unitUnavailable': 'La unidad no está disponible.',
      'unitAlreadyCarryingArtifact': 'La unidad ya transporta un artefacto.',
      'artifactNotFound': 'El artefacto ya no está disponible.',
      'unitNotCarryingArtifact': 'La unidad no transporta ningún artefacto.',
      'cityNotFound': 'La ciudad ya no está disponible.',
      'cityNotControlled': 'Este jugador no controla la ciudad.',
      'unitNotInCity': 'La unidad no está en esa ciudad.',
      'cityArtifactSlotFull':
          'El espacio para artefactos de la ciudad está lleno.',
      'artifactTradeActorUnavailable':
          'Este jugador no puede comerciar con artefactos.',
      'artifactTradeTargetInvalid': 'El jugador destinatario no es válido.',
      'artifactTradeGoldInvalid': 'La oferta de oro no es válida.',
      'artifactTradeBlockedByWar':
          'La guerra impide el comercio de artefactos.',
      'artifactTradeGoldUnavailable': 'El oro ofrecido no está disponible.',
      'offeredArtifactUnavailable': 'El artefacto ofrecido no está disponible.',
      'targetArtifactSlotUnavailable':
          'El destinatario no tiene espacio para un artefacto.',
      'stateRevisionOverflow': 'El estado del juego no puede avanzar más.',
      'other': 'No se ha podido completar la solicitud de artefacto.',
    });
    return '$_temp0';
  }

  @override
  String researchText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'recommendations': 'Recomendaciones',
      'title': 'Investigación',
      'open': 'Abrir investigación',
      'close': 'Cerrar investigación',
      'loading': 'Cargando opciones de investigación',
      'retry': 'Reintentar',
      'selecting': 'Seleccionando tecnología',
      'selectionRequired': 'Selecciona una tecnología para continuar',
      'sciencePerTurn': 'Ciencia por turno',
      'overflow': 'Ciencia almacenada',
      'active': 'Tecnología activa',
      'none': 'Ninguna',
      'cost': 'Coste',
      'progress': 'Progreso',
      'boost': 'Descuento por impulso',
      'prerequisites': 'Requisitos previos',
      'blockedBy': 'Bloqueada por',
      'unlocks': 'Desbloquea',
      'choose': 'Seleccionar',
      'tree': 'Árbol tecnológico',
      'catalog': 'Catálogo de investigación',
      'backToTree': 'Volver al árbol',
      'treeUnavailable': 'El diagrama de dependencias no está disponible.',
      'other': 'Investigación',
    });
    return '$_temp0';
  }

  @override
  String researchAvailability(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'unlocked': 'Investigada',
      'active': 'Activa',
      'available': 'Disponible',
      'lockedByPrerequisites': 'Requisitos previos necesarios',
      'lockedByTechnology': 'Bloqueada por tecnología',
      'other': 'No disponible',
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
          'No se ha podido completar la solicitud de investigación.',
      'responseIncompatible': 'La respuesta de investigación no es compatible.',
      'sessionUnavailable': 'La sesión de juego local no está disponible.',
      'staleRevision':
          'La investigación ha cambiado. Revisa las opciones e inténtalo de nuevo.',
      'technologyPlayerNotControlled':
          'Este jugador no puede seleccionar una investigación.',
      'technologyNotAvailable': 'Esta tecnología no está disponible.',
      'stateRevisionOverflow': 'El estado del juego no puede avanzar más.',
      'other': 'No se ha podido completar la solicitud de investigación.',
    });
    return '$_temp0';
  }

  @override
  String diplomacyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Diplomacia',
      'open': 'Abrir diplomacia',
      'close': 'Cerrar diplomacia',
      'noContacts': 'Sin contactos',
      'compose': 'Nueva acción',
      'target': 'Interlocutor',
      'action': 'Acción',
      'send': 'Enviar',
      'invalid': 'Revisa las condiciones del formulario.',
      'pending': 'Enviando acción diplomática',
      'relations': 'Relaciones',
      'proposals': 'Propuestas',
      'messages': 'Mensajes privados',
      'agreements': 'Acuerdos de recursos',
      'accept': 'Aceptar',
      'reject': 'Rechazar',
      'amount': 'Cantidad',
      'goldPerTurn': 'Oro por turno',
      'duration': 'Turnos',
      'resource': 'Recurso',
      'offered': 'Recurso ofrecido',
      'requested': 'Recurso solicitado',
      'topic': 'Tema',
      'other': 'Diplomacia',
    });
    return '$_temp0';
  }

  @override
  String diplomacyFailure(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requestFailed': 'No se ha podido completar la solicitud de diplomacia.',
      'responseIncompatible': 'La respuesta de diplomacia no es compatible.',
      'sessionUnavailable': 'La sesión de juego local no está disponible.',
      'staleRevision':
          'La diplomacia ha cambiado. Revisa el estado actual e inténtalo de nuevo.',
      'matchFinished': 'La partida ya ha terminado.',
      'diplomacyPlayerNotControlled':
          'Este jugador no puede realizar acciones diplomáticas.',
      'diplomacyTargetNotDiscovered': 'Este interlocutor no está disponible.',
      'diplomacyProposalNotAllowed': 'Esta propuesta no está permitida.',
      'diplomacyDuplicateProposal': 'Esta propuesta ya existe.',
      'diplomacyProposalNotFound': 'Esta propuesta ya no existe.',
      'diplomacyProposalPaymentUnavailable':
          'El pago de la propuesta no está disponible.',
      'diplomacyMessageCooldown':
          'Se ha enviado un mensaje similar hace muy poco.',
      'diplomacyDuplicateMessage': 'Este mensaje ya existe.',
      'diplomacyMessageNotFound': 'Este mensaje ya no existe.',
      'diplomacyMessageUnavailable': 'Este mensaje no se puede usar ahora.',
      'diplomacyTruceActive': 'Hay una tregua activa.',
      'diplomacyWarAlreadyActive': 'Ya hay una guerra activa.',
      'diplomacyInvalidGoldAmount': 'La cantidad de oro no es válida.',
      'diplomacyGoldGiftBlockedByRelation':
          'Esta relación impide los regalos de oro.',
      'diplomacyGoldUnavailable': 'El oro necesario no está disponible.',
      'diplomacyGoldGiftUnavailable': 'Este regalo de oro no está disponible.',
      'invalidResourceTradeTarget':
          'El destinatario del comercio de recursos no es válido.',
      'invalidResourceTradeResource': 'El recurso seleccionado no es válido.',
      'invalidResourceTradeTerms':
          'Las condiciones del comercio de recursos no son válidas.',
      'resourceTradeBlockedByWar':
          'La guerra impide este comercio de recursos.',
      'resourceTradeGoldUnavailable':
          'El oro para el comercio no está disponible.',
      'resourceTradeAlreadyActive': 'Este comercio de recursos ya está activo.',
      'invalidResourceTradeAgreementId':
          'El identificador del acuerdo no es válido.',
      'resourceTradeAgreementIdConflict':
          'El identificador del acuerdo entra en conflicto.',
      'resourceTradeExportUnavailable':
          'La exportación del recurso no está disponible.',
      'resourceTradeOfferUnavailable':
          'El recurso ofrecido no está disponible.',
      'resourceTradeRequestUnavailable':
          'El recurso solicitado no está disponible.',
      'stateRevisionOverflow': 'El estado del juego no puede avanzar más.',
      'other': 'No se ha podido completar la solicitud de diplomacia.',
    });
    return '$_temp0';
  }

  @override
  String presentationName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'farm': 'Granja',
      'riverFarm': 'Granja fluvial',
      'mine': 'Mina',
      'lumberMill': 'Aserradero',
      'pasture': 'Pastizal',
      'camp': 'Campamento',
      'quarry': 'Cantera',
      'fishingBoats': 'Barcos de pesca',
      'orchard': 'Huerto',
      'plantation': 'Plantación',
      'vineyard': 'Viñedo',
      'tradingPost': 'Puesto comercial',
      'prospectorCamp': 'Campamento de prospección',
      'horseRanch': 'Criadero de caballos',
      'pearlDivers': 'Buceadores de perlas',
      'coalShaft': 'Pozo de carbón',
      'oilWell': 'Pozo de petróleo',
      'bauxiteMine': 'Mina de bauxita',
      'uraniumMine': 'Mina de uranio',
      'wheat': 'Trigo',
      'fish': 'Pescado',
      'deer': 'Ciervo',
      'sheep': 'Oveja',
      'rice': 'Arroz',
      'cow': 'Vaca',
      'apple': 'Manzana',
      'banana': 'Plátano',
      'citrus': 'Cítricos',
      'gold': 'Oro',
      'silver': 'Plata',
      'gems': 'Gemas',
      'silk': 'Seda',
      'spices': 'Especias',
      'cotton': 'Algodón',
      'grapes': 'Uvas',
      'ivory': 'Marfil',
      'pearls': 'Perlas',
      'coffee': 'Café',
      'cocoa': 'Cacao',
      'tobacco': 'Tabaco',
      'sugar': 'Azúcar',
      'iron': 'Hierro',
      'coal': 'Carbón',
      'oil': 'Petróleo',
      'aluminium': 'Aluminio',
      'uranium': 'Uranio',
      'horses': 'Caballos',
      'marble': 'Mármol',
      'commander': 'Comandante',
      'warrior': 'Guerrero',
      'archer': 'Arquero',
      'settler': 'Colono',
      'worker': 'Trabajador',
      'merchant': 'Mercader',
      'scout': 'Explorador',
      'spearman': 'Lancero',
      'cavalry': 'Caballería',
      'catapult': 'Catapulta',
      'heavyInfantry': 'Infantería pesada',
      'fieldCannon': 'Cañón de campaña',
      'rifleman': 'Fusilero',
      'tank': 'Tanque',
      'scoutShip': 'Barco explorador',
      'warship': 'Buque de guerra',
      'reconPlane': 'Avión de reconocimiento',
      'building': 'Edificio',
      'improvement': 'Mejora',
      'resourceVisibility': 'Visibilidad de recursos',
      'unit': 'Unidad',
      'wonder': 'Maravilla',
      'friendly': 'Amistosa',
      'neutral': 'Neutral',
      'hostile': 'Hostil',
      'truce': 'Tregua',
      'war': 'Guerra',
      'warning': 'Advertencia',
      'complaint': 'Queja',
      'request': 'Petición',
      'praise': 'Elogio',
      'threat': 'Amenaza',
      'cooperation': 'Cooperación',
      'troopsNearCities': 'Tropas cerca de ciudades',
      'citiesTooClose': 'Ciudades demasiado cercanas',
      'blockedRoutes': 'Rutas bloqueadas',
      'withdrawScouts': 'Retirar exploradores',
      'avoidEscalation': 'Evitar una escalada',
      'commonEnemy': 'Enemigo común',
      'expansionProvocation': 'Provocación por expansión',
      'peacefulPraise': 'Elogio por conducta pacífica',
      'conciliatory': 'Conciliador',
      'evasive': 'Evasivo',
      'aggressive': 'Agresivo',
      'declareWar': 'Declarar la guerra',
      'goldGift': 'Regalo de oro',
      'friendshipProposal': 'Propuesta de amistad',
      'truceProposal': 'Propuesta de tregua',
      'message': 'Mensaje',
      'resourceTrade': 'Comercio de recursos',
      'resourceExchange': 'Intercambio de recursos',
      'granary': 'Granero',
      'workshop': 'Taller',
      'industry': 'Industria',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String technologyName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'agriculture': 'Agricultura',
      'woodworking': 'Trabajo de la madera',
      'mining': 'Minería',
      'animalHusbandry': 'Ganadería',
      'hunting': 'Caza',
      'fishing': 'Pesca',
      'craftsmanship': 'Artesanía',
      'trade': 'Comercio',
      'storage': 'Almacenamiento',
      'waterEngineering': 'Ingeniería hidráulica',
      'stoneworking': 'Trabajo de la piedra',
      'militaryOrganization': 'Organización militar',
      'advancedTrade': 'Comercio avanzado',
      'construction': 'Construcción',
      'navigation': 'Navegación',
      'irrigation': 'Riego',
      'banking': 'Banca',
      'engineering': 'Ingeniería',
      'metallurgy': 'Metalurgia',
      'horsebackRiding': 'Equitación',
      'ironWorking': 'Trabajo del hierro',
      'coalMining': 'Minería del carbón',
      'machinery': 'Maquinaria',
      'administration': 'Administración',
      'logistics': 'Logística',
      'shipbuilding': 'Construcción naval',
      'tactics': 'Táctica',
      'economy': 'Economía',
      'urbanization': 'Urbanización',
      'fortifications': 'Fortificaciones',
      'strategy': 'Estrategia',
      'specialization': 'Especialización',
      'writing': 'Escritura',
      'mathematics': 'Matemáticas',
      'medicine': 'Medicina',
      'civilService': 'Administración pública',
      'siegecraft': 'Técnicas de asedio',
      'cartography': 'Cartografía',
      'guilds': 'Gremios',
      'law': 'Derecho',
      'education': 'Educación',
      'urbanPlanning': 'Urbanismo',
      'navalDoctrine': 'Doctrina naval',
      'steel': 'Acero',
      'bureaucracy': 'Burocracia',
      'nationalism': 'Nacionalismo',
      'scientificMethod': 'Método científico',
      'steamPower': 'Máquina de vapor',
      'electricity': 'Electricidad',
      'combustion': 'Combustión',
      'flight': 'Aviación',
      'massProduction': 'Producción en masa',
      'radio': 'Radio',
      'nuclearPhysics': 'Física nuclear',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String cityContentName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'growth': 'Crecimiento',
      'industry': 'Industria',
      'commerce': 'Comercio',
      'science': 'Ciencia',
      'military': 'Militar',
      'wealth': 'Riqueza',
      'research': 'Investigación',
      'granary': 'Granero',
      'waterMill': 'Molino de agua',
      'workshop': 'Taller',
      'storehouse': 'Almacén',
      'housing': 'Viviendas',
      'merchantHall': 'Lonja de mercaderes',
      'stonemason': 'Cantero',
      'barracks': 'Cuartel',
      'marketplace': 'Mercado',
      'port': 'Puerto',
      'aqueduct': 'Acueducto',
      'forge': 'Forja',
      'stable': 'Establo',
      'bank': 'Banco',
      'buildersGuild': 'Gremio de constructores',
      'factory': 'Fábrica',
      'lighthouse': 'Faro',
      'trainingGrounds': 'Campo de entrenamiento',
      'townHall': 'Ayuntamiento',
      'monument': 'Monumento',
      'archive': 'Archivo',
      'academy': 'Academia',
      'university': 'Universidad',
      'observatory': 'Observatorio',
      'laboratory': 'Laboratorio',
      'reactor': 'Reactor',
      'courthouse': 'Palacio de justicia',
      'court': 'Corte',
      'governorsOffice': 'Oficina del gobernador',
      'surveyorsOffice': 'Oficina de topografía',
      'planningOffice': 'Oficina de planificación',
      'apothecary': 'Botica',
      'publicBaths': 'Baños públicos',
      'hospital': 'Hospital',
      'ministries': 'Ministerios',
      'walls': 'Murallas',
      'armory': 'Armería',
      'siegeWorkshop': 'Taller de asedio',
      'citadel': 'Ciudadela',
      'warCollege': 'Escuela de guerra',
      'conscriptionOffice': 'Oficina de reclutamiento',
      'borderFort': 'Fuerte fronterizo',
      'airfield': 'Aeródromo',
      'artisansGuild': 'Gremio de artesanos',
      'masterWorkshop': 'Taller maestro',
      'steelworks': 'Acería',
      'railDepot': 'Depósito ferroviario',
      'powerPlant': 'Central eléctrica',
      'assemblyPlant': 'Planta de montaje',
      'refinery': 'Refinería',
      'mapRoom': 'Sala de mapas',
      'shipyard': 'Astillero',
      'dryDock': 'Dique seco',
      'navalAcademy': 'Academia naval',
      'harborCustoms': 'Aduana portuaria',
      'museum': 'Museo',
      'parliament': 'Parlamento',
      'broadcastTower': 'Torre de radiodifusión',
      'worldFairGrounds': 'Recinto de la exposición universal',
      'greatLibrary': 'Gran Biblioteca',
      'hangingGardens': 'Jardines Colgantes',
      'greatWall': 'Gran Muralla',
      'petra': 'Petra',
      'centralBank': 'Banco Central',
      'imperialUniversity': 'Universidad Imperial',
      'grandCathedral': 'Gran Catedral',
      'motherFactory': 'Fábrica Matriz',
      'nationalObservatory': 'Observatorio Nacional',
      'svalbardSeedVault': 'Bóveda de Semillas de Svalbard',
      'grandExposition': 'Gran Exposición',
      'other': 'Contenido de ciudad desconocido',
    });
    return '$_temp0';
  }

  @override
  String diplomaticProposalName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'friendship': 'Amistad',
      'truce': 'Tregua',
      'other': 'Propuesta desconocida',
    });
    return '$_temp0';
  }

  @override
  String mapFeedbackText(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'roadCompleted': '+Camino',
      'unitKilled': 'KO',
      'unitRetreated': 'Retirada',
      'artifactExcavationStarted': 'Excavación',
      'artifactCarried': 'Artefacto recogido',
      'artifactStored': 'Artefacto almacenado',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String mapYieldShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'food': 'ALIM',
      'production': 'PROD',
      'gold': 'ORO',
      'defense': 'DEF',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get focusOwnUnitMovement =>
      'Centrar la cámara en el movimiento de mis unidades';

  @override
  String get followOwnUnitMovement =>
      'Seguir el movimiento de mis unidades con la cámara';

  @override
  String get focusForeignUnitMovement =>
      'Centrar la cámara en el movimiento de unidades enemigas';

  @override
  String get followForeignUnitMovement =>
      'Seguir el movimiento de unidades enemigas con la cámara';

  @override
  String get gameSoundsLabel => 'Sonidos del juego';

  @override
  String get soundVolumeLabel => 'Volumen de los sonidos';

  @override
  String get gameMusicLabel => 'Música del juego';

  @override
  String get musicVolumeLabel => 'Volumen de la música';

  @override
  String get natureSoundsLabel => 'Sonidos de la naturaleza';

  @override
  String get natureVolumeLabel => 'Volumen de la naturaleza';

  @override
  String hexInspectionKind(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite': 'Lugar ideal para una ciudad',
      'goodCitySite': 'Buen lugar para una ciudad',
      'fertileField': 'Campo fértil',
      'fertilePlains': 'Llanuras fértiles',
      'richPlain': 'Llanura rica',
      'strategicBorderland': 'Frontera estratégica',
      'strategicField': 'Campo estratégico',
      'defensivePosition': 'Posición defensiva',
      'fertileForest': 'Bosque fértil',
      'forestBackline': 'Retaguardia boscosa',
      'forestForge': 'Bosque industrial',
      'wildLand': 'Tierra salvaje',
      'richWilds': 'Tierras salvajes ricas',
      'exoticBackline': 'Retaguardia exótica',
      'difficultStrategicTerrain': 'Terreno estratégico difícil',
      'highGround': 'Terreno elevado',
      'riverHills': 'Colinas fluviales',
      'industrialStronghold': 'Bastión industrial',
      'richHills': 'Colinas ricas',
      'barrenLand': 'Tierra estéril',
      'oasis': 'Oasis',
      'tradeOasis': 'Oasis comercial',
      'desertDeposits': 'Yacimientos del desierto',
      'harshLand': 'Tierra inhóspita',
      'coldPastures': 'Pastos fríos',
      'resourceOutpost': 'Puesto de recursos',
      'hostileLand': 'Tierra hostil',
      'arcticDeposits': 'Yacimientos árticos',
      'coast': 'Costa',
      'fishingCoast': 'Costa pesquera',
      'richCoast': 'Costa rica',
      'riverPort': 'Puerto fluvial',
      'regionalPortHeart': 'Centro portuario regional',
      'openSea': 'Mar abierto',
      'naturalBarrier': 'Barrera natural',
      'promisingLand': 'Tierra prometedora',
      'weakLand': 'Tierra poco productiva',
      'ordinaryLand': 'Tierra común',
      'mapTile': 'Casilla del mapa',
      'other': 'Casilla del mapa',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionDescription(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'idealCitySite':
          'Una casilla de gran valor para asentarse, con alimentos, crecimiento y potencial de expansión.',
      'goodCitySite':
          'Terreno sólido para un centro urbano, con suficiente valor básico para favorecer el crecimiento inicial.',
      'fertileField':
          'Pradera regada por un río que favorece los alimentos, el crecimiento de la población y las mejoras de los trabajadores.',
      'fertilePlains':
          'Llanuras abiertas junto a un río, útiles para equilibrar alimentos y producción.',
      'richPlain':
          'Una casilla abierta valiosa con recursos de lujo o valor comercial que merece quedar dentro de las fronteras.',
      'strategicBorderland':
          'Buena tierra con valor estratégico, útil para expandirse antes de que la reclamen los rivales.',
      'strategicField':
          'Una casilla de llanura vinculada a recursos estratégicos o a la presión sobre la frontera.',
      'defensivePosition':
          'Terreno que refuerza el control defensivo y ayuda a proteger los accesos cercanos.',
      'fertileForest':
          'Un bosque junto a un río que combina potencial de crecimiento con cobertura natural.',
      'forestBackline':
          'Una casilla de bosque más segura que puede favorecer el crecimiento o las mejoras de caza.',
      'forestForge':
          'Bosque con recursos industriales, prometedor para la producción una vez mejorado.',
      'wildLand':
          'Terreno denso y difícil, útil solo con un plan claro de trabajo o expansión.',
      'richWilds':
          'Terreno salvaje con suficiente fertilidad o recursos para justificar un desarrollo cuidadoso.',
      'exoticBackline':
          'Una casilla de selva o humedal con recursos de lujo para la expansión y el comercio posteriores.',
      'difficultStrategicTerrain':
          'Terreno difícil con recursos estratégicos, potente más adelante pero incómodo al principio.',
      'highGround':
          'Colinas que favorecen la defensa y el control del mapa más que el crecimiento rápido.',
      'riverHills':
          'Colinas junto a un río que combinan defensa con un mayor potencial económico.',
      'industrialStronghold':
          'Colinas con recursos industriales, un objetivo de producción sólido para una ciudad.',
      'richHills':
          'Colinas con recursos valiosos, útiles para una expansión centrada en el oro o la producción.',
      'barrenLand':
          'Tierra seca con poco valor inmediato, salvo que tecnologías posteriores o las fronteras cambien el plan.',
      'oasis':
          'Desierto suavizado por el acceso a un río, que convierte tierra pobre en una casilla útil para crecer.',
      'tradeOasis':
          'Un enclave comercial en el desierto que puede adquirir valor con la mejora adecuada.',
      'desertDeposits':
          'Terreno pobre para asentarse con un yacimiento estratégico más importante en épocas posteriores.',
      'harshLand':
          'Tierra fría o agreste con una economía inicial limitada y desarrollo lento.',
      'coldPastures':
          'Terreno frío con suficientes pastos para sostener una ciudad fronteriza.',
      'resourceOutpost':
          'Tierra fría y remota que merece reclamarse principalmente por el recurso que alberga.',
      'hostileLand':
          'Terreno hostil con poco valor para asentarse y escasos rendimientos inmediatos.',
      'arcticDeposits':
          'Tierra nevada con recursos, difícil de aprovechar pero con posible importancia estratégica.',
      'coast':
          'Terreno costero que permite acceso naval y un crecimiento urbano flexible.',
      'fishingCoast':
          'Costa con valor alimentario, un buen motivo para trabajar o asentarse junto al agua.',
      'richCoast':
          'Recursos de lujo o valor comercial costero que merece la pena incluir en las fronteras de la ciudad.',
      'riverPort':
          'Una desembocadura con valor comercial y de movimiento para una ciudad costera.',
      'regionalPortHeart':
          'Un sólido centro costero donde se combinan el valor del río y los recursos.',
      'openSea':
          'Agua útil para barcos y exploración, pero no para asentamientos terrestres.',
      'naturalBarrier':
          'Terreno infranqueable que condiciona el movimiento y la defensa, más que la economía.',
      'promisingLand':
          'Una casilla generalmente útil con suficiente valor para inspeccionarla antes de seguir.',
      'weakLand':
          'Terreno de bajo rendimiento que rara vez merece tiempo de trabajo al principio.',
      'ordinaryLand':
          'Una casilla normal sin ventajas destacadas, útil cuando encaja en el plan de la ciudad.',
      'mapTile':
          'Una casilla sencilla del mapa sin información suficiente para una valoración clara.',
      'other':
          'Una casilla sencilla del mapa sin información suficiente para una valoración clara.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendation(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity': 'Buen lugar para desarrollar',
      'defendHere': 'Buena posición defensiva',
      'exploitEconomy': 'Merece aprovecharse',
      'avoid': 'Evitar sin un plan',
      'neutral': 'Inspeccionar antes de moverse',
      'other': 'Inspeccionar antes de moverse',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionRecommendationDetail(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'foundCity':
          'Si el terreno está libre de fronteras, considera fundar una ciudad o enviar aquí a un colono.',
      'defendHere':
          'Úsalo para posicionar unidades, proteger fronteras o cubrir ciudades cercanas.',
      'exploitEconomy':
          'Inclúyelo en tus fronteras y asigna un trabajador cuando la ciudad pueda beneficiarse.',
      'avoid':
          'Evítalo al principio, salvo que un recurso, una ruta o una necesidad militar cambien su valor.',
      'neutral':
          'Explora las casillas vecinas y compara recursos antes de asignar un trabajador o colono.',
      'other':
          'Explora las casillas vecinas y compara recursos antes de asignar un trabajador o colono.',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Inspección del hexágono',
      'close': 'Cerrar inspección',
      'loading': 'Inspeccionando hexágono…',
      'requestFailed':
          'No se ha podido inspeccionar el hexágono. Inténtalo de nuevo.',
      'responseIncompatible':
          'La respuesta de inspección del hexágono no es compatible.',
      'sessionUnavailable': 'La sesión de juego no está disponible.',
      'description': 'Descripción',
      'terrain': 'Terreno',
      'resources': 'Recursos',
      'none': 'Ninguno',
      'height': 'Altura',
      'improvements': 'Mejoras posibles',
      'noImprovements': 'No hay mejoras compatibles.',
      'fromStart': 'Disponible desde el principio',
      'unlocked': 'Tecnología desbloqueada',
      'locked': 'Tecnología necesaria',
      'riverBonus': 'Bonificación fluvial',
      'defenseBonus': 'Terreno defensivo',
      'outsideCity': 'Fuera de las fronteras controladas de la ciudad',
      'cityCenter': 'Centro de la ciudad',
      'alreadyImproved': 'Este hexágono ya está mejorado',
      'objective': 'Objetivo del mapa',
      'other': 'Inspección del hexágono',
    });
    return '$_temp0';
  }

  @override
  String hexInspectionCity(String city) {
    return 'Trabajado por $city';
  }

  @override
  String hexInspectionBuildTurns(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns turnos',
      one: '1 turno',
    );
    return 'Tiempo de construcción: $_temp0';
  }

  @override
  String hexInspectionTerrain(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'ocean': 'Océano',
      'coast': 'Costa',
      'lake': 'Lago',
      'plains': 'Llanuras',
      'grassland': 'Pradera',
      'desert': 'Desierto',
      'tundra': 'Tundra',
      'snow': 'Nieve',
      'mountain': 'Montaña',
      'hills': 'Colinas',
      'wetlands': 'Humedales',
      'jungle': 'Selva',
      'forest': 'Bosque',
      'river': 'Río',
      'other': 'Llanuras',
    });
    return '$_temp0';
  }

  @override
  String get gamepadSettings => 'Mando';

  @override
  String get gamepadEnabled => 'Entrada del mando';

  @override
  String get gamepadDeadzone => 'Zona muerta del mando';

  @override
  String get gamepadCameraSensitivity => 'Sensibilidad de la cámara con mando';

  @override
  String get gamepadInvertCameraY => 'Invertir eje Y de la cámara con mando';

  @override
  String get gamepadButtonBindings => 'Asignación de botones';

  @override
  String get gamepadAxisBindings => 'Asignación de ejes';

  @override
  String get gamepadResetBindings => 'Restablecer asignaciones';

  @override
  String get gamepadUnassigned => 'Sin asignar';

  @override
  String gamepadAssignedTo(String action) {
    return 'Asignado a: $action';
  }

  @override
  String get gamepadActionConfirm => 'Confirmar';

  @override
  String get gamepadActionCancel => 'Cancelar';

  @override
  String get gamepadActionMoveMode => 'Modo de movimiento';

  @override
  String get gamepadActionInspect => 'Inspeccionar hexágono';

  @override
  String get gamepadActionHudPrevious => 'Sección anterior de la interfaz';

  @override
  String get gamepadActionHudNext => 'Sección siguiente de la interfaz';

  @override
  String get gamepadActionPrevious => 'Acción pendiente anterior';

  @override
  String get gamepadActionNext => 'Acción pendiente siguiente';

  @override
  String get gamepadActionPrimary => 'Acción principal';

  @override
  String get gamepadActionUp => 'Cruceta arriba';

  @override
  String get gamepadActionDown => 'Cruceta abajo';

  @override
  String get gamepadActionLeft => 'Cruceta izquierda';

  @override
  String get gamepadActionRight => 'Cruceta derecha';

  @override
  String get gamepadActionZoomIn => 'Acercar';

  @override
  String get gamepadActionZoomOut => 'Alejar';

  @override
  String get gamepadActionCursorX => 'Cursor X';

  @override
  String get gamepadActionCursorY => 'Cursor Y';

  @override
  String get gamepadActionCameraX => 'Cámara X';

  @override
  String get gamepadActionCameraY => 'Cámara Y';

  @override
  String get gamepadControlHome => 'Inicio';

  @override
  String get gamepadControlTouchpad => 'Panel táctil';

  @override
  String get gamepadControlLeftStickX => 'Palanca izquierda X';

  @override
  String get gamepadControlLeftStickY => 'Palanca izquierda Y';

  @override
  String get gamepadControlRightStickX => 'Palanca derecha X';

  @override
  String get gamepadControlRightStickY => 'Palanca derecha Y';

  @override
  String get gamepadControlLeftTrigger => 'Gatillo izquierdo (LT)';

  @override
  String get gamepadControlRightTrigger => 'Gatillo derecho (RT)';

  @override
  String get keyboardSettings => 'Teclado';

  @override
  String get keyboardScope =>
      'Los atajos del mapa funcionan cuando el mapa tiene el foco del teclado. Haz clic en el mapa para devolverle el foco.';

  @override
  String get keyboardPanKeys => 'W / A / S / D o flechas';

  @override
  String get keyboardPan => 'Desplazar la cámara';

  @override
  String get keyboardSelect =>
      'Seleccionar el hexágono bajo el puntero o la selección actual';

  @override
  String get keyboardMove =>
      'Alternar la selección de destino de movimiento de la unidad seleccionada';

  @override
  String get keyboardInspect =>
      'Inspeccionar el hexágono bajo el puntero, el hexágono seleccionado o el centro de la vista';

  @override
  String get keyboardMapMode =>
      'Alternar entre la vista gráfica y la vista de casillas del mapa';

  @override
  String get keyboardPending =>
      'Acción pendiente anterior / siguiente del turno';

  @override
  String get keyboardSpace => 'Espacio';

  @override
  String get keyboardPrimary =>
      'Ir a la siguiente acción pendiente; terminar el turno cuando no quede ninguna';

  @override
  String get keyboardCancel =>
      'Cerrar el panel activo o cancelar la interacción actual';

  @override
  String get keyboardFocus => 'Enfocar el control siguiente / anterior';

  @override
  String get textSize => 'Tamaño del texto';

  @override
  String get textSizeDescription =>
      'Se aplica además del tamaño de texto del sistema.';

  @override
  String get textScaleStandard => 'Estándar (100%)';

  @override
  String get textScaleLarge => 'Grande (115%)';

  @override
  String get textScaleExtraLarge => 'Muy grande (130%)';

  @override
  String get languageSettings => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get windowSettingsTitle => 'Ventana';

  @override
  String get windowModeFullscreen => 'Pantalla completa';

  @override
  String get windowModeWindowed => 'En ventana';

  @override
  String get windowSettingsBusy => 'Cambiando el modo de ventana…';

  @override
  String windowSettingsFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'load':
          'No se han podido cargar las preferencias de ventana. Se ha solicitado el modo predeterminado.',
      'apply':
          'No se ha podido cambiar el modo de ventana. Vuelve a elegir un modo.',
      'save':
          'No se ha podido guardar la preferencia de ventana. Vuelve a elegir un modo.',
      'restore':
          'No se ha podido restaurar el modo de ventana anterior. Vuelve a elegir un modo.',
      'other': 'No se ha podido completar la operación de ventana.',
    });
    return '$_temp0';
  }

  @override
  String get automationSettings => 'Automatización';

  @override
  String get advanceActions => 'Pasar a la siguiente acción';

  @override
  String get advanceActionsDescription =>
      'Tras completar una acción, seleccionar la siguiente unidad, ciudad o investigación que requiera tu atención.';

  @override
  String get automaticEndTurn => 'Terminar turnos automáticamente';

  @override
  String get automaticEndTurnDescription =>
      'Terminar tu turno cuando no queden acciones. Las decisiones manuales y los paneles abiertos pausan la automatización.';

  @override
  String get performanceSettings => 'Rendimiento';

  @override
  String get showFps => 'Mostrar FPS';

  @override
  String get showFpsDescription =>
      'Mostrar los fotogramas por segundo en toda la aplicación.';

  @override
  String get showMapZoom => 'Mostrar zoom del mapa';

  @override
  String get showMapZoomDescription =>
      'Mostrar el zoom actual mientras el mapa está abierto.';

  @override
  String get aiSettings => 'IA';

  @override
  String get aiBatterySaver => 'Ahorro de batería de IA';

  @override
  String get aiBatterySaverDescription =>
      'Reduce la búsqueda táctica durante los turnos locales de la IA.';

  @override
  String get mapAppearanceSettings => 'Aspecto del mapa';

  @override
  String get mapMarkingsSettings => 'Marcadores del mapa';

  @override
  String get preferredMapViewMode => 'Vista predeterminada del mapa';

  @override
  String get preferredMapViewModeDescription =>
      'Se usa al abrir una partida o una repetición.';

  @override
  String get mapCitySites => 'Lugares para ciudades';

  @override
  String get mapCitySitesDescription =>
      'Mostrar posibles lugares para ciudades en terreno explorado.';

  @override
  String get mapCityGrowth => 'Expansión de ciudades';

  @override
  String get mapCityGrowthDescription =>
      'Mostrar casillas exploradas fuera del territorio de ciudades conocidas.';

  @override
  String resourceTurnsCompact(int turns) {
    return '${turns}T';
  }

  @override
  String resourceText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'gold': 'Oro',
      'science': 'Ciencia',
      'stability': 'Estabilidad',
      'resources': 'Recursos',
      'victory': 'Victoria',
      'turn': 'Turno',
      'close': 'Cerrar detalles',
      'treasury': 'Tesoro',
      'income': 'Ingresos',
      'cityIncome': 'Ingresos de ciudades',
      'projectIncome': 'Ingresos de proyectos',
      'upkeep': 'Mantenimiento de unidades',
      'netPerTurn': 'Por turno',
      'freeUnits': 'Unidades gratuitas',
      'paidUnits': 'Unidades de pago',
      'nextWorker': 'Mantenimiento del próximo trabajador',
      'activeResearch': 'Investigación activa',
      'overflow': 'Ciencia acumulada',
      'sources': 'Fuentes',
      'baseOrder': 'Orden básico',
      'buildings': 'Edificios',
      'luxuries': 'Bienes de lujo',
      'technologies': 'Tecnologías',
      'artifacts': 'Artefactos',
      'wonders': 'Maravillas',
      'cities': 'Ciudades',
      'population': 'Población',
      'cohesion': 'Cohesión',
      'conqueredCities': 'Ciudades conquistadas',
      'warWeariness': 'Desgaste de guerra',
      'hegemony': 'Impuesto de hegemonía',
      'relativeStanding': 'Posición relativa',
      'totalSources': 'Fuentes totales',
      'totalCosts': 'Costes totales',
      'stockpile': 'Reservas',
      'output': 'Producción por turno',
      'empty': 'Sin fuentes',
      'score': 'Puntuación',
      'conquest': 'Conquista',
      'domination': 'Dominación',
      'culture': 'Cultura',
      'holdTurns': 'Turnos mantenidos',
      'remainingTurns': 'Turnos restantes',
      'turnLimit': 'Límite de turnos',
      'submitted': 'Confirmados',
      'required': 'Confirmaciones requeridas',
      'content': 'Satisfecho',
      'stable': 'Estable',
      'strained': 'Tenso',
      'unrest': 'Disturbios',
      'warning': 'Advertencia',
      'negativeBalance': 'El tesoro tiene saldo negativo.',
      'deficitWithinThreeTurns':
          'Con los ingresos actuales, el tesoro será negativo en un plazo de tres turnos.',
      'shortage': 'Recursos insuficientes para las unidades desbloqueadas',
      'victoryCritical': 'Se acerca una condición de victoria.',
      'leader': 'Líder',
      'noVictory': 'Sin condición de victoria',
      'goalCompact': 'Objetivo',
      'scoreCapCompact': 'LÍMITE',
      'other': 'Recursos',
    });
    return '$_temp0';
  }

  @override
  String get automaticSave => 'Guardado automático';

  @override
  String playerText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Jugadores',
      'active': 'Activo',
      'finished': 'Turno terminado',
      'submitted': 'Confirmado',
      'waiting': 'En espera',
      'ended': 'Partida terminada',
      'privateStatus': 'El estado del turno es privado',
      'noContact': 'Sin contacto diplomático',
      'other': 'Jugadores',
    });
    return '$_temp0';
  }

  @override
  String historyText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'title': 'Partidas en línea terminadas',
      'loading': 'Cargando historial de partidas',
      'empty': 'Todavía no hay partidas terminadas.',
      'failed': 'No se pudo cargar el historial. Intenta actualizar.',
      'refresh': 'Actualizar',
      'previous': 'Página anterior',
      'next': 'Página siguiente',
      'turn': 'Último turno',
      'won': 'Has ganado',
      'lost': 'Has perdido',
      'resigned': 'Has abandonado',
      'removed': 'Se te ha expulsado de la partida',
      'other': 'Partidas en línea terminadas',
    });
    return '$_temp0';
  }

  @override
  String profileText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'title': 'Tu perfil',
      'description':
          'Cambiar el nombre conserva tu cuenta y tus partidas multijugador.',
      'save': 'Guardar nombre',
      'saved': 'Nombre guardado.',
      'taken': 'Este nombre ya está en uso.',
      'changed': 'La cuenta ha cambiado. Vuelve a cargar el perfil.',
      'other': 'Tu perfil',
    });
    return '$_temp0';
  }

  @override
  String get researchDiscoveryTitle => 'Investigación completada';

  @override
  String get showResearchDiscoveries => 'Mostrar descubrimientos tecnológicos';

  @override
  String get researchDiscoverySuppress => 'No volver a mostrar';

  @override
  String get researchDiscoveryMinimize => 'Minimizar';

  @override
  String get researchDiscoveryRestore => 'Restaurar descubrimiento';

  @override
  String get researchDiscoveryContinue => 'Continuar';

  @override
  String researchRecommendationRank(int rank) {
    return 'Recomendación $rank';
  }

  @override
  String researchRecommendationTurns(int turns) {
    return 'Turnos estimados: $turns';
  }

  @override
  String researchRecommendationReason(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'boost': 'Impulso de investigación',
      'workerYields': 'Rendimientos de trabajadores',
      'unlocks': 'Nuevos desbloqueos',
      'effects': 'Efectos tecnológicos',
      'nearCompletion': 'Cerca de completarse',
      'other': 'Recomendaciones',
    });
    return '$_temp0';
  }

  @override
  String technologyDescription(String technology) {
    String _temp0 = intl.Intl.selectLogic(technology, {
      'agriculture':
          'Abre la ruta básica de crecimiento. Las granjas y granjas fluviales permiten que la población crezca más rápido y estabilizan la primera ciudad.',
      'woodworking':
          'Desarrolla el lado productivo de la minería. Los aserraderos convierten los bosques en producción sin profundizar en la metalurgia.',
      'mining':
          'Abre la ruta de la industria y la infraestructura. Las minas son el primer gran salto en la producción urbana.',
      'animalHusbandry':
          'Fortalece el crecimiento mediante recursos animales. Los pastos construyen una economía alimentaria y preparan el camino hacia la equitación.',
      'hunting':
          'Abre la rama militar y de exploración. Proporciona campamentos y la primera unidad a distancia para la producción urbana.',
      'fishing':
          'Desarrolla ciudades cerca del agua. Los barcos pesqueros ayudan a las ciudades costeras a crecer más rápido y preparan el camino hacia el puerto.',
      'craftsmanship':
          'La primera mejora de producción urbana. El taller evita que edificios y unidades posteriores bloqueen la cola demasiado tiempo.',
      'trade':
          'El primer paso en la economía del oro. La lonja de mercaderes da a una ciudad una recompensa financiera sencilla tras elegir una rama de crecimiento.',
      'storage':
          'Estabiliza el crecimiento de la ciudad. El almacenamiento ayuda a mantener el ritmo de alimento y reduce el riesgo de estancamientos de desarrollo.',
      'waterEngineering':
          'Expande la ruta de crecimiento basada en agua. El molino de agua recompensa a las ciudades que controlan ríos.',
      'stoneworking':
          'Combina producción y defensa. Las canteras y el cantero fortalecen las ciudades en la rama de infraestructura.',
      'militaryOrganization':
          'Construye el primer núcleo militar de una ciudad. Los cuarteles fortalecen producción y defensa antes de que aparezcan bonificaciones militares posteriores.',
      'advancedTrade':
          'Desarrolla la economía tras el comercio. El mercado es un edificio de oro más fuerte y prepara el camino hacia la banca.',
      'construction':
          'Expande el territorio y la madurez urbana. Las viviendas aumentan el control de casillas y conducen a administración e ingeniería.',
      'navigation':
          'Abre una recompensa urbana para la costa. El puerto requiere acceso a costa u océano y recompensa las ciudades ribereñas con alimento y oro.',
      'irrigation':
          'Especializa el crecimiento basado en agua. El acueducto otorga una fuerte bonificación de alimento y control territorial adicional.',
      'banking':
          'Especializa la rama comercial. El banco convierte mercados anteriores en fuertes ingresos urbanos y desbloquea la economía más amplia.',
      'engineering':
          'Especialización de construcción. El gremio de constructores acelera la producción y aumenta el límite de casillas controladas.',
      'metallurgy':
          'Una fuerte recompensa industrial tras la cantería. La forja aumenta la producción y prepara el camino hacia el hierro y el carbón.',
      'horsebackRiding':
          'Una tecnología que vincula crecimiento y guerra. El establo apoya a las ciudades que invirtieron antes en animales y caza.',
      'ironWorking':
          'Un efecto de recurso industrial. Cada recurso de hierro controlado aumenta la producción de la ciudad.',
      'coalMining':
          'Un efecto de recurso industrial posterior. El carbón controlado aumenta la producción de la ciudad y apoya la ruta hacia la fábrica.',
      'machinery':
          'Una recompensa tardía de infraestructura. La fábrica da un gran aumento de producción a las ciudades que entraron en ingeniería.',
      'administration':
          'Vincula infraestructura y economía. Los ayuntamientos y monumentos fortalecen ciudades maduras y llevan a la urbanización.',
      'logistics':
          'Acelera la producción de unidades. Esta es la tecnología principal para jugadores que quieren desplegar ejércitos desde ciudades con más frecuencia.',
      'shipbuilding':
          'Desarrolla la subrama costera y de exploración. El faro requiere acceso costero y fortalece ciudades de ribera.',
      'tactics':
          'Especialización militar de ciudad. Los campos de entrenamiento añaden defensa y producción para centros militares.',
      'economy':
          'Una recompensa sistémica para la banca. Aumenta el oro generado por las economías urbanas.',
      'urbanization':
          'La dirección final para el crecimiento de grandes ciudades. Aumenta el límite de población cuando el sistema de población empieza a usar límites estrictos.',
      'fortifications':
          'Refuerza la defensa de la ciudad. Otorga una bonificación defensiva a la economía urbana, cuyo significado completo crece tras la expansión de combate y asedio.',
      'strategy':
          'La dirección militar final. Refuerza la efectividad del ejército como recompensa tardía tras la logística.',
      'specialization':
          'La recompensa cívica/económica final. Desbloquea especializaciones de ciudad, añade ciencia urbana y ayuda a terminar tecnologías tardías en partidas largas.',
      'writing':
          'El primer paso hacia ciencia, ley y administración. El archivo da a una ciudad una base permanente de investigación.',
      'mathematics':
          'Conecta la ciencia con la planificación territorial. La oficina de agrimensores ayuda a las ciudades a controlar fronteras con más eficacia.',
      'medicine':
          'Desarrolla salud y crecimiento a largo plazo en grandes ciudades mediante boticas, baños y hospitales.',
      'civilService':
          'Mejora la gestión de un gran imperio y desbloquea tribunales que estabilizan ciudades.',
      'siegecraft':
          'Abre la guerra de asedio. Las catapultas y los talleres de asedio rompen ciudades fortaleza.',
      'cartography':
          'Desarrolla exploración, mapas y costa. Otorga la sala de mapas y los primeros barcos exploradores.',
      'guilds':
          'Da a las ciudades productivas una etapa entre el taller y la industria.',
      'law': 'Introduce orden, políticas y gobierno civil mediante tribunales.',
      'education':
          'Construye la ruta científica completa para ciudades mediante academias y universidades.',
      'urbanPlanning':
          'Desarrolla grandes ciudades y control territorial mediante planificación espacial.',
      'navalDoctrine':
          'Convierte los puertos en centros de flotas, astilleros y proyección de fuerza marítima.',
      'steel':
          'Introduce industria pesada e infantería pesada para el frente posterior.',
      'bureaucracy':
          'Proporciona un gran objetivo cívico tras la administración: oficinas, ministerios, museos y parlamento.',
      'nationalism':
          'Combina defensa fronteriza, movilización e identidad imperial.',
      'scientificMethod':
          'Prepara la ciencia tardía, laboratorios, observatorios y proyectos tecnológicos.',
      'steamPower':
          'Abre el ferrocarril, logística más pesada e industria de vapor.',
      'electricity':
          'Introduce energía, infraestructura y alcance de información.',
      'combustion':
          'Da importancia al petróleo y desbloquea unidades modernas de primera línea.',
      'flight':
          'Introduce aviación, reconocimiento y proyección de fuerza sobre el frente.',
      'massProduction':
          'Desarrolla la producción industrial final, tanques y plantas de ensamblaje.',
      'radio':
          'Fortalece la comunicación, la visibilidad y la influencia del imperio mediante torres de radiodifusión.',
      'nuclearPhysics':
          'Abre el reactor, el uranio y proyectos tardíos de final de partida.',
      'other': '',
    });
    return '$_temp0';
  }
}
