import 'dart:async';
import 'dart:math';

import '../read_model/multiplayer_view.dart';
import 'multiplayer_session_port.dart';
import 'multiplayer_state.dart';

typedef MultiplayerDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class MultiplayerCoordinator {
  MultiplayerCoordinator({
    required MultiplayerSessionPort session,
    required MultiplayerMatchDocumentSource documents,
    MultiplayerDiagnosticReporter diagnosticReporter = _ignoreDiagnostic,
    Random? secureRandom,
  }) : _session = session,
       _documents = documents,
       _diagnosticReporter = diagnosticReporter,
       _random = secureRandom ?? Random.secure();

  final MultiplayerSessionPort _session;
  final MultiplayerMatchDocumentSource _documents;
  final MultiplayerDiagnosticReporter _diagnosticReporter;
  final Random _random;
  final StreamController<MultiplayerState> _changes =
      StreamController<MultiplayerState>.broadcast(sync: true);
  MultiplayerState _state = const MultiplayerStarting();
  var _generation = 0;
  var _closed = false;

  MultiplayerState get state => _state;

  Stream<MultiplayerState> get changes => _changes.stream;

  Future<void> initialize() async {
    final generation = ++_generation;
    _setState(const MultiplayerStarting());
    try {
      final account = await _session.restoreAccount();
      if (!_isCurrent(generation)) return;
      if (account == null) {
        _setState(const MultiplayerSignedOut());
        return;
      }
      await _openLobby(account, generation);
    } on Object catch (error, stackTrace) {
      _report('multiplayer_restore_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(MultiplayerSignedOut(failureCode: _failureCode(error)));
      }
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _authenticate(
        () => _session.signIn(email: email.trim(), password: password),
      );

  Future<void> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) => _authenticate(
    () => _session.createAccount(
      email: email.trim(),
      password: password,
      displayName: displayName.trim(),
    ),
  );

  Future<void> _authenticate(
    Future<MultiplayerAccountView> Function() operation,
  ) async {
    if (_closed || _state is MultiplayerAuthenticating) return;
    final generation = ++_generation;
    _setState(const MultiplayerAuthenticating());
    try {
      final account = await operation();
      if (_isCurrent(generation)) await _openLobby(account, generation);
    } on Object catch (error, stackTrace) {
      _report('multiplayer_authentication_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(MultiplayerSignedOut(failureCode: _failureCode(error)));
      }
    }
  }

  Future<void> refreshLobby() async {
    final current = _state;
    if (current is! MultiplayerLobby || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final matches = await _session.listMatches();
      if (_isCurrent(generation)) {
        _setState(current.copyWith(matches: matches, busy: false));
      }
    } on Object catch (error, stackTrace) {
      _report('multiplayer_lobby_refresh_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(
          current.copyWith(busy: false, failureCode: _failureCode(error)),
        );
      }
    }
  }

  Future<void> createMatch() async {
    final current = _state;
    if (current is! MultiplayerLobby || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final projection = await _session.createMatch(await _documents.load());
      if (_isCurrent(generation)) {
        _setState(
          MultiplayerInMatch(
            account: current.account,
            phase: NetworkSessionPhase.ready,
            projection: projection,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      _report('multiplayer_match_create_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(
          current.copyWith(busy: false, failureCode: _failureCode(error)),
        );
      }
    }
  }

  Future<void> joinMatch({required String matchId, required String playerId}) =>
      _joinMatch(matchId.trim(), playerId.trim());

  Future<void> _joinMatch(String matchId, String playerId) async {
    final current = _state;
    if (current is! MultiplayerLobby || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final projection = await _session.joinMatch(
        matchId: matchId,
        playerId: playerId,
      );
      if (_isCurrent(generation)) {
        _setState(
          MultiplayerInMatch(
            account: current.account,
            phase: NetworkSessionPhase.ready,
            projection: projection,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      _report('multiplayer_match_join_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(
          current.copyWith(busy: false, failureCode: _failureCode(error)),
        );
      }
    }
  }

  Future<void> openMatch(MultiplayerMatchView match) async {
    final current = _state;
    if (current is! MultiplayerLobby || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final projection = await _session.resync(match.matchId);
      if (_isCurrent(generation)) {
        _setState(
          MultiplayerInMatch(
            account: current.account,
            phase: NetworkSessionPhase.ready,
            projection: projection,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      _report('multiplayer_match_open_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(
          current.copyWith(busy: false, failureCode: _failureCode(error)),
        );
      }
    }
  }

  Future<void> submitTurn() async {
    final current = _state;
    if (current is! MultiplayerInMatch ||
        current.phase != NetworkSessionPhase.ready ||
        current.commandPending ||
        !current.projection.canSubmitTurn) {
      return;
    }
    final generation = _generation;
    final commandId = _commandId();
    _setState(current.copyWith(commandPending: true, clearFailure: true));
    try {
      final outcome = await _session.submitTurn(
        matchId: current.projection.matchId,
        clientCommandId: commandId,
        expectedRevision: current.projection.revision,
      );
      _validateCommand(current.projection, outcome, commandId);
      if (_isCurrent(generation)) {
        _setState(
          current.copyWith(
            projection: outcome.projection,
            commandPending: false,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      _report('multiplayer_submit_failed', error, stackTrace);
      if (!_isCurrent(generation)) return;
      if (error case MultiplayerSessionException(retryable: true)) {
        await _recoverCommand(current, commandId, generation);
        return;
      }
      _setState(
        current.copyWith(
          phase: NetworkSessionPhase.failed,
          commandPending: false,
          failureCode: _failureCode(error),
        ),
      );
    }
  }

  Future<void> reconnect() async {
    final current = _state;
    if (current is! MultiplayerInMatch ||
        current.phase == NetworkSessionPhase.closed) {
      return;
    }
    await _recoverCommand(current, null, _generation);
  }

  Future<void> _recoverCommand(
    MultiplayerInMatch current,
    String? commandId,
    int generation,
  ) async {
    _setState(
      current.copyWith(
        phase: NetworkSessionPhase.reconnecting,
        commandPending: commandId != null,
        clearFailure: true,
      ),
    );
    try {
      await _session.reconnect();
      if (!_isCurrent(generation)) return;
      MultiplayerCommandView? retried;
      if (commandId != null) {
        retried = await _session.submitTurn(
          matchId: current.projection.matchId,
          clientCommandId: commandId,
          expectedRevision: current.projection.revision,
        );
        _validateCommand(current.projection, retried, commandId);
      }
      if (!_isCurrent(generation)) return;
      final base = retried?.projection ?? current.projection;
      _setState(
        current.copyWith(
          phase: NetworkSessionPhase.resyncing,
          projection: base,
          commandPending: commandId != null,
        ),
      );
      final synchronized = await _session.resync(base.matchId);
      _validateResync(base, synchronized);
      if (_isCurrent(generation)) {
        _setState(
          current.copyWith(
            phase: NetworkSessionPhase.ready,
            projection: synchronized,
            commandPending: false,
            clearFailure: true,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      _report('multiplayer_reconnect_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(
          current.copyWith(
            phase: NetworkSessionPhase.failed,
            commandPending: false,
            failureCode: _failureCode(error),
          ),
        );
      }
    }
  }

  Future<void> leaveMatch() async {
    final current = _state;
    if (current is! MultiplayerInMatch) return;
    final generation = ++_generation;
    _setState(current.copyWith(phase: NetworkSessionPhase.closed));
    try {
      await _openLobby(current.account, generation);
    } on Object catch (error, stackTrace) {
      _report('multiplayer_lobby_open_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(
          MultiplayerLobby(
            account: current.account,
            matches: const [],
            failureCode: _failureCode(error),
          ),
        );
      }
    }
  }

  Future<void> signOut() async {
    if (_closed) return;
    ++_generation;
    try {
      await _session.signOut();
    } on Object catch (error, stackTrace) {
      _report('multiplayer_sign_out_failed', error, stackTrace);
    }
    if (!_closed) _setState(const MultiplayerSignedOut());
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    ++_generation;
    await _session.close();
    await _changes.close();
  }

  Future<void> _openLobby(
    MultiplayerAccountView account,
    int generation,
  ) async {
    final matches = await _session.listMatches();
    if (_isCurrent(generation)) {
      _setState(MultiplayerLobby(account: account, matches: matches));
    }
  }

  static void _validateCommand(
    MultiplayerProjectionView before,
    MultiplayerCommandView command,
    String commandId,
  ) {
    if (command.clientCommandId != commandId ||
        command.projection.matchId != before.matchId ||
        command.projection.playerId != before.playerId ||
        command.initialEventOffset != before.eventOffset ||
        command.finalEventOffset < command.initialEventOffset ||
        command.projection.eventOffset != command.finalEventOffset ||
        command.projection.revision < before.revision ||
        (command.accepted &&
            command.projection.revision > before.revision + 1)) {
      throw const MultiplayerSessionException(
        code: 'invalid_command_sequence',
        message: 'The server command outcome is not contiguous.',
      );
    }
  }

  static void _validateResync(
    MultiplayerProjectionView before,
    MultiplayerProjectionView after,
  ) {
    if (after.matchId != before.matchId ||
        after.playerId != before.playerId ||
        after.revision < before.revision ||
        after.eventOffset < before.eventOffset) {
      throw const MultiplayerSessionException(
        code: 'invalid_resync_sequence',
        message: 'The server resync moved the session backwards.',
      );
    }
  }

  String _commandId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  bool _isCurrent(int generation) => !_closed && generation == _generation;

  void _setState(MultiplayerState state) {
    if (_closed) return;
    _state = state;
    _changes.add(state);
  }

  void _report(String code, Object error, StackTrace stackTrace) {
    _diagnosticReporter(code, error, stackTrace);
  }
}

String _failureCode(Object error) => switch (error) {
  MultiplayerSessionException(:final code) => code,
  _ => 'unexpected_failure',
};

void _ignoreDiagnostic(String code, Object error, StackTrace stackTrace) {}
