part of 'multiplayer_screen.dart';

final class _LobbyPanel extends StatelessWidget {
  const _LobbyPanel({required this.controller, required this.state});

  final MultiplayerController controller;
  final MultiplayerLobby state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return ListView(
      padding: const EdgeInsets.all(AonwSpacing.lg),
      children: [
        _LobbyAccountPanel(controller: controller, state: state),
        const SizedBox(height: AonwSpacing.md),
        _MultiplayerCreateMatchPanel(controller: controller, busy: state.busy),
        const SizedBox(height: AonwSpacing.md),
        _JoinMatchPanel(controller: controller, busy: state.busy),
        _LobbyProgress(state: state),
        const SizedBox(height: AonwSpacing.lg),
        Text(l10n.yourMatches, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AonwSpacing.sm),
        if (state.matches.isEmpty)
          Text(l10n.noMultiplayerMatches)
        else
          for (final match in state.matches)
            _LobbyMatchCard(
              controller: controller,
              match: match,
              busy: state.busy,
            ),
      ],
    );
  }
}

final class _LobbyAccountPanel extends StatelessWidget {
  const _LobbyAccountPanel({required this.controller, required this.state});

  final MultiplayerController controller;
  final MultiplayerLobby state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return AonwPanel(
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
          Row(
            children: [
              TextButton.icon(
                onPressed: state.busy ? null : controller.refreshLobby,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refreshMatches),
              ),
              const Spacer(),
              TextButton(
                onPressed: state.busy ? null : controller.signOut,
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _MultiplayerCreateMatchPanel extends StatefulWidget {
  const _MultiplayerCreateMatchPanel({
    required this.controller,
    required this.busy,
  });

  final MultiplayerController controller;
  final bool busy;

  @override
  State<_MultiplayerCreateMatchPanel> createState() =>
      _MultiplayerCreateMatchPanelState();
}

final class _MultiplayerCreateMatchPanelState
    extends State<_MultiplayerCreateMatchPanel> {
  var _scenario = LocalGameCatalog.entries.first;
  var _country = LocalPlayerCountryView.poland;
  var _fogEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return AonwPanel(
      semanticLabel: l10n.multiplayerSetupTitle,
      maxWidth: 760,
      padding: const EdgeInsets.all(AonwSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.multiplayerSetupTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AonwSpacing.xs),
          Text(l10n.multiplayerSetupIntro),
          const SizedBox(height: AonwSpacing.lg),
          _civilizationSection(l10n),
          const SizedBox(height: AonwSpacing.md),
          _gameSetupSection(l10n),
          const SizedBox(height: AonwSpacing.md),
          _facts(l10n),
          const SizedBox(height: AonwSpacing.lg),
          FilledButton.icon(
            key: const ValueKey('multiplayer-create-match'),
            onPressed: widget.busy ? null : _createMatch,
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.continueToLobby),
          ),
        ],
      ),
    );
  }

  Widget _civilizationSection(AonwLocalizations l10n) => NewGameSection(
    keyName: 'multiplayer-civilization-section',
    title: l10n.chooseCivilizationTitle,
    icon: Icons.flag_outlined,
    child: DropdownButtonFormField<LocalPlayerCountryView>(
      key: ValueKey(('multiplayer-country', _country)),
      initialValue: _country,
      decoration: InputDecoration(labelText: l10n.humanCountryLabel),
      items: [
        for (final country in LocalPlayerCountryView.values)
          DropdownMenuItem(
            value: country,
            child: Text(l10n.countryName(country.name)),
          ),
      ],
      onChanged: widget.busy
          ? null
          : (value) => setState(() => _country = value!),
    ),
  );

  Widget _gameSetupSection(AonwLocalizations l10n) => NewGameSection(
    keyName: 'multiplayer-game-setup-section',
    title: l10n.gameSetupTitle,
    icon: Icons.tune,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<LocalGameCatalogEntryView>(
          key: ValueKey(('multiplayer-scenario', _scenario.id)),
          initialValue: _scenario,
          decoration: InputDecoration(labelText: l10n.scenarioLabel),
          items: [
            for (final entry in LocalGameCatalog.entries)
              DropdownMenuItem(
                value: entry,
                child: Text(l10n.localScenarioName(entry.id.name)),
              ),
          ],
          onChanged: widget.busy
              ? null
              : (value) => setState(() => _scenario = value!),
        ),
        const SizedBox(height: AonwSpacing.md),
        Text(l10n.turnModeTitle, style: Theme.of(context).textTheme.titleSmall),
        ListTile(
          key: const ValueKey('multiplayer-turn-mode'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sync_alt),
          title: Text(l10n.turnModeName(LocalTurnModeView.simultaneous.name)),
          subtitle: Text(l10n.multiplayerTurnModeDescription),
        ),
        SwitchListTile.adaptive(
          key: const ValueKey('multiplayer-fog-of-war'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.fogOfWarLabel),
          value: _fogEnabled,
          onChanged: widget.busy
              ? null
              : (value) => setState(() => _fogEnabled = value),
        ),
      ],
    ),
  );

  Widget _facts(AonwLocalizations l10n) => Column(
    children: [
      NewGameFact(
        title: l10n.mapSetupTitle,
        body: l10n.mapSetupDetails(
          l10n.localScenarioName(_scenario.id.name),
          _scenario.columns,
          _scenario.rows,
          _scenario.maximumPlayers,
        ),
        icon: Icons.map_outlined,
      ),
      const SizedBox(height: AonwSpacing.md),
      NewGameFact(
        title: l10n.victoryPathsTitle,
        body: l10n.victoryPathsBody,
        icon: Icons.emoji_events_outlined,
      ),
      const SizedBox(height: AonwSpacing.md),
      NewGameFact(
        title: l10n.settlementToEmpireTitle,
        body: l10n.settlementToEmpireBody,
        icon: Icons.account_balance_outlined,
      ),
    ],
  );

  void _createMatch() {
    widget.controller.createMatch(
      MultiplayerMatchSetupView(
        mapId: _scenario.mapId,
        creatorCountry: _country.name,
        fogEnabled: _fogEnabled,
      ),
    );
  }
}

final class _JoinMatchPanel extends StatefulWidget {
  const _JoinMatchPanel({required this.controller, required this.busy});

  final MultiplayerController controller;
  final bool busy;

  @override
  State<_JoinMatchPanel> createState() => _JoinMatchPanelState();
}

final class _JoinMatchPanelState extends State<_JoinMatchPanel> {
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
    return AonwPanel(
      semanticLabel: l10n.joinMultiplayerMatch,
      maxWidth: 760,
      padding: const EdgeInsets.all(AonwSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.joinMultiplayerMatch,
            style: Theme.of(context).textTheme.titleLarge,
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
              for (
                var number = 1;
                number <= LocalGameCatalog.maximumCivilizations;
                number++
              )
                DropdownMenuItem(
                  value: 'player-$number',
                  child: Text(l10n.playerSeatNumber(number)),
                ),
            ],
            onChanged: widget.busy
                ? null
                : (value) => setState(() => _playerId = value!),
          ),
          const SizedBox(height: AonwSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('multiplayer-join-match'),
            onPressed: widget.busy || _matchId.text.trim().isEmpty
                ? null
                : () => widget.controller.joinMatch(
                    matchId: _matchId.text,
                    playerId: _playerId,
                  ),
            icon: const Icon(Icons.login),
            label: Text(l10n.joinMultiplayerMatch),
          ),
        ],
      ),
    );
  }
}

final class _LobbyProgress extends StatelessWidget {
  const _LobbyProgress({required this.state});

  final MultiplayerLobby state;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.failureCode case final code?) ...[
        const SizedBox(height: AonwSpacing.sm),
        _FailureText(code: code),
      ],
      if (state.busy) ...[
        const SizedBox(height: AonwSpacing.md),
        AonwProgressIndicator(
          semanticLabel: context.aonwL10n.loadingMultiplayer,
        ),
      ],
    ],
  );
}
