import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../multiplayer/application/account_profile_port.dart';
import '../../multiplayer/application/multiplayer_state.dart';
import '../../multiplayer/presentation/account_profile_controller.dart';
import '../../multiplayer/presentation/multiplayer_controller.dart';

final class AccountProfileSettings extends StatefulWidget {
  const AccountProfileSettings({
    required this.account,
    this.onSignIn,
    super.key,
  });

  final MultiplayerController account;
  final VoidCallback? onSignIn;

  @override
  State<AccountProfileSettings> createState() => _AccountProfileSettingsState();
}

final class _AccountProfileSettingsState extends State<AccountProfileSettings> {
  late AccountProfileController _profile;
  final _name = TextEditingController();
  AccountProfileView? _displayed;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _accountId = _userId(widget.account.state);
    widget.account.addListener(_accountChanged);
    _profile = AccountProfileController(widget.account)..addListener(_changed);
  }

  @override
  void didUpdateWidget(AccountProfileSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.account, oldWidget.account)) return;
    oldWidget.account.removeListener(_accountChanged);
    _profile.dispose();
    _displayed = null;
    _name.clear();
    _connect();
  }

  void _accountChanged() {
    final next = _userId(widget.account.state);
    if (_accountId != null && next != _accountId) _profile.invalidate();
    _accountId = next;
  }

  void _changed() {
    if (!mounted) return;
    if (!identical(_displayed, _profile.profile)) {
      _displayed = _profile.profile;
      _name.text = _displayed?.displayName ?? '';
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.account.removeListener(_accountChanged);
    _profile.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: const ValueKey('account-profile-settings'),
    title: Text(context.aonwL10n.profileText('title')),
    onExpansionChanged: (open) {
      if (open && _profile.profile == null) unawaited(_profile.load());
    },
    childrenPadding: const EdgeInsets.all(AonwSpacing.md),
    children: [
      Text(context.aonwL10n.profileText('description')),
      const SizedBox(height: AonwSpacing.md),
      if (_profile.profile != null) ...[
        TextField(
          key: const ValueKey('profile-display-name'),
          controller: _name,
          enabled: !_profile.busy,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.aonwL10n.displayNameLabel,
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: AonwSpacing.sm),
        FilledButton(
          key: const ValueKey('save-profile'),
          onPressed: _profile.busy ? null : _save,
          child: Text(context.aonwL10n.profileText('save')),
        ),
      ],
      ..._feedback(context),
    ],
  );

  List<Widget> _feedback(BuildContext context) => [
    if (_profile.busy) const LinearProgressIndicator(),
    if (_showSignIn) _signIn(context),
    if (_profile.saved) _message(context.aonwL10n.profileText('saved')),
    if (_profile.failureCode case final failure?) ...[
      _message(_failure(context, failure)),
      _recovery(context, failure),
    ],
  ];

  bool get _showSignIn =>
      !_profile.busy &&
      _profile.profile == null &&
      _profile.failureCode == null &&
      widget.onSignIn != null;

  Widget _signIn(BuildContext context) => TextButton(
    onPressed: widget.onSignIn,
    child: Text(context.aonwL10n.signIn),
  );

  Widget _recovery(BuildContext context, String failure) {
    if (failure == 'authentication_required' && widget.onSignIn != null) {
      return _signIn(context);
    }
    return TextButton(
      onPressed: _profile.busy ? null : () => unawaited(_profile.load()),
      child: Text(context.aonwL10n.retry),
    );
  }

  void _save() => unawaited(_profile.save(_name.text));

  Widget _message(String text) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: AonwSpacing.sm),
      child: Text(text),
    ),
  );
}

String? _userId(MultiplayerState state) => switch (state) {
  MultiplayerLobby(:final account) ||
  MultiplayerWaitingRoom(:final account) ||
  MultiplayerInMatch(:final account) => account.userId,
  _ => null,
};

String _failure(BuildContext context, String code) => switch (code) {
  'invalid_display_name' => context.aonwL10n.invalidDisplayName,
  'display_name_taken' => context.aonwL10n.profileText('taken'),
  'profile_session_changed' => context.aonwL10n.profileText('changed'),
  _ => context.aonwL10n.multiplayerFailure(code),
};
