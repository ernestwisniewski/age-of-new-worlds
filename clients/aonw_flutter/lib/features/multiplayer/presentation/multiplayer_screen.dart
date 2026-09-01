import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../l10n/l10n.dart';
import '../application/multiplayer_state.dart';
import '../read_model/multiplayer_view.dart';
import 'multiplayer_controller.dart';

part 'multiplayer_match_actions.dart';
part 'multiplayer_waiting_room.dart';

final class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({
    required this.controller,
    this.onOpenGame,
    super.key,
  });

  final MultiplayerController controller;
  final Future<void> Function(MultiplayerProjectionView projection)? onOpenGame;

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

final class _MultiplayerScreenState extends State<MultiplayerScreen> {
  var _openingGame = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.state is MultiplayerStarting) {
      widget.controller.initialize();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.aonwL10n.multiplayerTitle)),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) => switch (widget.controller.state) {
          MultiplayerStarting() || MultiplayerAuthenticating() => Center(
            child: AonwProgressIndicator(
              semanticLabel: context.aonwL10n.loadingMultiplayer,
            ),
          ),
          final MultiplayerSignedOut state => _AuthPanel(
            controller: widget.controller,
            failureCode: state.failureCode,
          ),
          final MultiplayerLobby state => _LobbyPanel(
            controller: widget.controller,
            state: state,
          ),
          final MultiplayerWaitingRoom state => _WaitingRoomPanel(
            controller: widget.controller,
            state: state,
          ),
          final MultiplayerInMatch state => _MatchPanel(
            controller: widget.controller,
            state: state,
            openingGame: _openingGame,
            onOpenGame: widget.onOpenGame == null
                ? null
                : () => _openGame(state.projection),
          ),
        },
      ),
    ),
  );

  Future<void> _openGame(MultiplayerProjectionView projection) async {
    final openGame = widget.onOpenGame;
    if (_openingGame || openGame == null) return;
    setState(() => _openingGame = true);
    try {
      await openGame(projection);
    } finally {
      if (mounted) setState(() => _openingGame = false);
    }
  }
}

final class _AuthPanel extends StatefulWidget {
  const _AuthPanel({required this.controller, required this.failureCode});

  final MultiplayerController controller;
  final String? failureCode;

  @override
  State<_AuthPanel> createState() => _AuthPanelState();
}

final class _AuthPanelState extends State<_AuthPanel> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  var _createAccount = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AonwSpacing.lg),
        child: AonwPanel(
          semanticLabel: l10n.multiplayerAuthenticationTitle,
          maxWidth: 440,
          padding: const EdgeInsets.all(AonwSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.multiplayerAuthenticationTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AonwSpacing.lg),
                TextFormField(
                  key: const ValueKey('multiplayer-email'),
                  controller: _email,
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.emailLabel),
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : l10n.invalidEmail,
                ),
                const SizedBox(height: AonwSpacing.sm),
                TextFormField(
                  key: const ValueKey('multiplayer-password'),
                  controller: _password,
                  autofillHints: const [AutofillHints.password],
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.passwordLabel),
                  validator: (value) => value != null && value.length >= 12
                      ? null
                      : l10n.invalidPassword,
                ),
                if (_createAccount) ...[
                  const SizedBox(height: AonwSpacing.sm),
                  TextFormField(
                    key: const ValueKey('multiplayer-display-name'),
                    controller: _displayName,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: l10n.displayNameLabel,
                    ),
                    validator: (value) =>
                        value != null && value.trim().isNotEmpty
                        ? null
                        : l10n.invalidDisplayName,
                  ),
                ],
                if (widget.failureCode case final code?) ...[
                  const SizedBox(height: AonwSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.multiplayerFailure(code),
                      key: const ValueKey('multiplayer-auth-failure'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AonwSpacing.lg),
                FilledButton(
                  key: const ValueKey('multiplayer-auth-submit'),
                  onPressed: _submit,
                  child: Text(
                    _createAccount ? l10n.createAccount : l10n.signIn,
                  ),
                ),
                TextButton(
                  key: const ValueKey('multiplayer-auth-mode'),
                  onPressed: () =>
                      setState(() => _createAccount = !_createAccount),
                  child: Text(
                    _createAccount
                        ? l10n.useExistingAccount
                        : l10n.createNewAccount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_createAccount) {
      await widget.controller.createAccount(
        email: _email.text,
        password: _password.text,
        displayName: _displayName.text,
      );
      return;
    }
    await widget.controller.signIn(
      email: _email.text,
      password: _password.text,
    );
  }
}

final class _LobbyPanel extends StatefulWidget {
  const _LobbyPanel({required this.controller, required this.state});

  final MultiplayerController controller;
  final MultiplayerLobby state;

  @override
  State<_LobbyPanel> createState() => _LobbyPanelState();
}

final class _LobbyPanelState extends State<_LobbyPanel> {
  final _matchId = TextEditingController();
  var _playerId = 'player-2';

  @override
  void dispose() {
    _matchId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final state = widget.state;
    return ListView(
      padding: const EdgeInsets.all(AonwSpacing.lg),
      children: [
        AonwPanel(
          semanticLabel: l10n.multiplayerLobbyTitle,
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.multiplayerLobbyTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AonwSpacing.xs),
              SelectableText(l10n.signedInAccount(state.account.userId)),
              const SizedBox(height: AonwSpacing.md),
              FilledButton.icon(
                key: const ValueKey('multiplayer-create-match'),
                onPressed: state.busy ? null : widget.controller.createMatch,
                icon: const Icon(Icons.add),
                label: Text(l10n.createMultiplayerMatch),
              ),
              const SizedBox(height: AonwSpacing.md),
              TextField(
                key: const ValueKey('multiplayer-match-id'),
                controller: _matchId,
                decoration: InputDecoration(labelText: l10n.matchIdLabel),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AonwSpacing.sm),
              DropdownButtonFormField<String>(
                key: ValueKey(('multiplayer-player-id', _playerId)),
                initialValue: _playerId,
                decoration: InputDecoration(labelText: l10n.playerSeatLabel),
                items: [
                  DropdownMenuItem(
                    value: 'player-1',
                    child: Text(l10n.playerSeatOne),
                  ),
                  DropdownMenuItem(
                    value: 'player-2',
                    child: Text(l10n.playerSeatTwo),
                  ),
                ],
                onChanged: state.busy
                    ? null
                    : (value) => setState(() => _playerId = value!),
              ),
              const SizedBox(height: AonwSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('multiplayer-join-match'),
                onPressed: state.busy || _matchId.text.trim().isEmpty
                    ? null
                    : () => widget.controller.joinMatch(
                        matchId: _matchId.text,
                        playerId: _playerId,
                      ),
                icon: const Icon(Icons.login),
                label: Text(l10n.joinMultiplayerMatch),
              ),
              if (state.failureCode case final code?) ...[
                const SizedBox(height: AonwSpacing.sm),
                _FailureText(code: code),
              ],
              if (state.busy) ...[
                const SizedBox(height: AonwSpacing.md),
                AonwProgressIndicator(semanticLabel: l10n.loadingMultiplayer),
              ],
              const SizedBox(height: AonwSpacing.lg),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: state.busy
                        ? null
                        : widget.controller.refreshLobby,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.refreshMatches),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: state.busy ? null : widget.controller.signOut,
                    child: Text(l10n.signOut),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AonwSpacing.lg),
        Text(l10n.yourMatches, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AonwSpacing.sm),
        if (state.matches.isEmpty)
          Text(l10n.noMultiplayerMatches)
        else
          for (final match in state.matches)
            _LobbyMatchCard(
              controller: widget.controller,
              match: match,
              busy: state.busy,
            ),
      ],
    );
  }
}

final class _MatchPanel extends StatelessWidget {
  const _MatchPanel({
    required this.controller,
    required this.state,
    required this.openingGame,
    this.onOpenGame,
  });

  final MultiplayerController controller;
  final MultiplayerInMatch state;
  final bool openingGame;
  final VoidCallback? onOpenGame;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final projection = state.projection;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AonwSpacing.lg),
        child: AonwPanel(
          semanticLabel: l10n.multiplayerMatchTitle,
          maxWidth: 620,
          padding: const EdgeInsets.all(AonwSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.multiplayerMatchTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AonwSpacing.sm),
              SelectableText(l10n.matchIdentifier(projection.matchId)),
              Text(l10n.playerIdentifier(projection.playerId)),
              Text(l10n.multiplayerTurn(projection.turn)),
              Text(
                l10n.multiplayerSubmissionProgress(
                  projection.submittedCount,
                  projection.requiredSubmissionCount,
                ),
              ),
              Text(l10n.visibleUnits(projection.visibleUnitCount)),
              Text(l10n.networkPhase(state.phase.name)),
              if (state.failureCode case final code?) ...[
                const SizedBox(height: AonwSpacing.sm),
                _FailureText(code: code),
              ],
              const SizedBox(height: AonwSpacing.lg),
              _MatchActions(
                controller: controller,
                state: state,
                openingGame: openingGame,
                onOpenGame: onOpenGame,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _FailureText extends StatelessWidget {
  const _FailureText({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      context.aonwL10n.multiplayerFailure(code),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
